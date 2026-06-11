package com.speak.score.service;

import com.speak.score.dto.ClassRankDTO;
import com.speak.score.dto.RankItemDTO;
import com.speak.score.entity.*;
import com.speak.score.exception.BusinessException;
import com.speak.score.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.ZSetOperations;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.temporal.TemporalAdjusters;
import java.util.*;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class RankingService {

    private final TodoItemRepository todoItemRepository;
    private final TodoTaskRepository todoTaskRepository;
    private final UserRepository userRepository;
    private final ClassRepository classRepository;
    private final ClassMemberRepository classMemberRepository;
    private final SchoolRepository schoolRepository;

    private final RedisTemplate<String, Object> redisTemplate;

    private static final String RANK_KEY_PREFIX = "speak:rank:";
    private static final String CLASS_RANK_KEY_PREFIX = "speak:rank:class:";
    private static final long RANK_EXPIRE_HOURS = 26;

    public enum RankPeriod {
        DAILY("daily"),
        WEEKLY("weekly"),
        TOTAL("total");

        private final String code;

        RankPeriod(String code) {
            this.code = code;
        }

        public String getCode() {
            return code;
        }
    }

    public enum RankType {
        STUDENT_TOTAL("student_total"),
        STUDENT_AVERAGE("student_average"),
        CLASS_AVERAGE("class_average");

        private final String code;

        RankType(String code) {
            this.code = code;
        }

        public String getCode() {
            return code;
        }
    }

    private String getStudentRankKey(Long classId, RankPeriod period, RankType type) {
        return RANK_KEY_PREFIX + "class:" + classId + ":" + period.getCode() + ":" + type.getCode();
    }

    private String getSchoolStudentRankKey(Long schoolId, RankPeriod period, RankType type) {
        return RANK_KEY_PREFIX + "school:" + schoolId + ":" + period.getCode() + ":" + type.getCode();
    }

    private String getClassRankKey(Long schoolId, RankPeriod period) {
        return CLASS_RANK_KEY_PREFIX + "school:" + schoolId + ":" + period.getCode();
    }

    private LocalDateTime getPeriodStart(RankPeriod period) {
        LocalDate today = LocalDate.now();
        switch (period) {
            case DAILY:
                return today.atStartOfDay();
            case WEEKLY:
                return today.with(TemporalAdjusters.previousOrSame(java.time.DayOfWeek.MONDAY)).atStartOfDay();
            case TOTAL:
                return LocalDateTime.of(2020, 1, 1, 0, 0);
            default:
                return today.atStartOfDay();
        }
    }

    @Transactional
    public void refreshClassStudentRanking(Long classId) {
        log.info("Refreshing student ranking for class: {}", classId);

        for (RankPeriod period : RankPeriod.values()) {
            refreshClassStudentRankingByPeriod(classId, period, RankType.STUDENT_TOTAL);
            refreshClassStudentRankingByPeriod(classId, period, RankType.STUDENT_AVERAGE);
        }

        log.info("Completed refreshing student ranking for class: {}", classId);
    }

    private void refreshClassStudentRankingByPeriod(Long classId, RankPeriod period, RankType type) {
        LocalDateTime startTime = getPeriodStart(period);
        LocalDateTime endTime = LocalDateTime.now();

        List<ClassMember> members = classMemberRepository
                .findByClassIdAndRoleCodeAndStatusAndDeletedFalse(classId, RoleEnum.STUDENT);

        if (members.isEmpty()) {
            return;
        }

        List<Long> userIds = members.stream()
                .map(m -> m.getUser().getId())
                .collect(Collectors.toList());

        List<TodoTask> tasks = todoTaskRepository.findByAssigneeClassIdAndDeletedFalse(classId);
        List<Long> taskIds = tasks.stream()
                .filter(t -> t.getCreatedAt() != null &&
                        !t.getCreatedAt().isBefore(startTime) &&
                        !t.getCreatedAt().isAfter(endTime))
                .map(TodoTask::getId)
                .collect(Collectors.toList());

        String key = getStudentRankKey(classId, period, type);
        redisTemplate.delete(key);

        if (taskIds.isEmpty()) {
            setRankExpire(key);
            return;
        }

        List<Object[]> studentStats = todoItemRepository
                .findStudentStatsByTaskIdInAndStatus(taskIds, TodoItemStatus.COMPLETED);

        Map<Long, Object[]> statsMap = new HashMap<>();
        for (Object[] row : studentStats) {
            Long userId = (Long) row[0];
            statsMap.put(userId, row);
        }

        ZSetOperations<String, Object> zSetOps = redisTemplate.opsForZSet();

        for (Long userId : userIds) {
            Object[] stats = statsMap.get(userId);
            double score = 0.0;
            if (stats != null) {
                if (type == RankType.STUDENT_TOTAL) {
                    Double avgScore = (Double) stats[1];
                    Long count = (Long) stats[4];
                    score = avgScore != null ? avgScore * (count != null ? count.doubleValue() : 0) : 0.0;
                } else {
                    Double avgScore = (Double) stats[1];
                    score = avgScore != null ? avgScore : 0.0;
                }
            }
            if (score > 0) {
                zSetOps.add(key, String.valueOf(userId), score);
            }
        }

        setRankExpire(key);
        log.info("Refreshed ranking: key={}, count={}", key, zSetOps.size(key));
    }

    @Transactional
    public void refreshSchoolRanking(Long schoolId) {
        log.info("Refreshing school ranking for school: {}", schoolId);

        List<ClassEntity> classes = classRepository.findBySchoolId(schoolId);
        for (ClassEntity cls : classes) {
            refreshClassStudentRanking(cls.getId());
        }

        for (RankPeriod period : RankPeriod.values()) {
            refreshSchoolStudentRanking(schoolId, period, RankType.STUDENT_TOTAL);
            refreshSchoolStudentRanking(schoolId, period, RankType.STUDENT_AVERAGE);
            refreshClassAverageRanking(schoolId, period);
        }

        log.info("Completed refreshing school ranking for school: {}", schoolId);
    }

    private void refreshSchoolStudentRanking(Long schoolId, RankPeriod period, RankType type) {
        List<ClassEntity> classes = classRepository.findBySchoolId(schoolId);
        String key = getSchoolStudentRankKey(schoolId, period, type);
        redisTemplate.delete(key);

        ZSetOperations<String, Object> zSetOps = redisTemplate.opsForZSet();

        for (ClassEntity cls : classes) {
            String classKey = getStudentRankKey(cls.getId(), period, type);
            Set<Object> members = zSetOps.reverseRange(classKey, 0, -1);
            if (members != null) {
                for (Object member : members) {
                    Double score = zSetOps.score(classKey, member);
                    if (score != null && score > 0) {
                        zSetOps.add(key, member, score);
                    }
                }
            }
        }

        setRankExpire(key);
        log.info("Refreshed school student ranking: key={}, count={}", key, zSetOps.size(key));
    }

    private void refreshClassAverageRanking(Long schoolId, RankPeriod period) {
        List<ClassEntity> classes = classRepository.findBySchoolId(schoolId);
        String key = getClassRankKey(schoolId, period);
        redisTemplate.delete(key);

        ZSetOperations<String, Object> zSetOps = redisTemplate.opsForZSet();

        for (ClassEntity cls : classes) {
            String studentKey = getStudentRankKey(cls.getId(), period, RankType.STUDENT_AVERAGE);
            Set<Object> members = zSetOps.reverseRange(studentKey, 0, -1);

            if (members == null || members.isEmpty()) {
                continue;
            }

            double totalScore = 0.0;
            int count = 0;
            for (Object member : members) {
                Double score = zSetOps.score(studentKey, member);
                if (score != null && score > 0) {
                    totalScore += score;
                    count++;
                }
            }

            if (count > 0) {
                double avgScore = totalScore / count;
                zSetOps.add(key, String.valueOf(cls.getId()), avgScore);
            }
        }

        setRankExpire(key);
        log.info("Refreshed class average ranking: key={}, count={}", key, zSetOps.size(key));
    }

    private void setRankExpire(String key) {
        redisTemplate.expire(key, RANK_EXPIRE_HOURS, TimeUnit.HOURS);
    }

    public List<RankItemDTO> getClassStudentRanking(
            Long classId, RankPeriod period, RankType type, int topN) {

        String key = getStudentRankKey(classId, period, type);
        return getRankingFromRedis(key, topN);
    }

    public RankItemDTO getMyClassRank(Long classId, Long userId, RankPeriod period, RankType type) {
        String key = getStudentRankKey(classId, period, type);
        return getMyRankFromRedis(key, userId);
    }

    public List<RankItemDTO> getSchoolStudentRanking(
            Long schoolId, RankPeriod period, RankType type, int topN) {

        String key = getSchoolStudentRankKey(schoolId, period, type);
        return getRankingFromRedis(key, topN);
    }

    public RankItemDTO getMySchoolRank(Long schoolId, Long userId, RankPeriod period, RankType type) {
        String key = getSchoolStudentRankKey(schoolId, period, type);
        return getMyRankFromRedis(key, userId);
    }

    public List<ClassRankDTO> getClassAverageRanking(Long schoolId, RankPeriod period, int topN) {
        String key = getClassRankKey(schoolId, period);

        ZSetOperations<String, Object> zSetOps = redisTemplate.opsForZSet();
        Set<ZSetOperations.TypedTuple<Object>> tuples = zSetOps.reverseRangeWithScores(key, 0, topN - 1);

        if (tuples == null || tuples.isEmpty()) {
            return Collections.emptyList();
        }

        List<ClassRankDTO> result = new ArrayList<>();
        int rank = 1;
        for (ZSetOperations.TypedTuple<Object> tuple : tuples) {
            String classIdStr = (String) tuple.getValue();
            Long classId = Long.parseLong(classIdStr);
            Double score = tuple.getScore();

            ClassEntity cls = classRepository.findById(classId).orElse(null);
            if (cls == null) continue;

            ClassRankDTO dto = new ClassRankDTO();
            dto.setClassId(classId);
            dto.setClassName(cls.getClassName());
            if (cls.getGrade() != null) {
                dto.setGradeName(cls.getGrade().getGradeName());
            }
            dto.setAverageScore(score != null ? Math.round(score * 100.0) / 100.0 : 0.0);
            dto.setRank(rank++);

            long studentCount = classMemberRepository
                    .countByClassIdAndRoleCodeAndStatusAndDeletedFalse(classId, RoleEnum.STUDENT);
            dto.setStudentCount((int) studentCount);

            result.add(dto);
        }

        return result;
    }

    private List<RankItemDTO> getRankingFromRedis(String key, int topN) {
        ZSetOperations<String, Object> zSetOps = redisTemplate.opsForZSet();
        Set<ZSetOperations.TypedTuple<Object>> tuples = zSetOps.reverseRangeWithScores(key, 0, topN - 1);

        if (tuples == null || tuples.isEmpty()) {
            return Collections.emptyList();
        }

        List<RankItemDTO> result = new ArrayList<>();
        int rank = 1;
        for (ZSetOperations.TypedTuple<Object> tuple : tuples) {
            String userIdStr = (String) tuple.getValue();
            Long userId = Long.parseLong(userIdStr);
            Double score = tuple.getScore();

            RankItemDTO dto = buildRankItem(userId, score, rank++);
            result.add(dto);
        }

        return result;
    }

    private RankItemDTO getMyRankFromRedis(String key, Long userId) {
        ZSetOperations<String, Object> zSetOps = redisTemplate.opsForZSet();
        Long rank = zSetOps.reverseRank(key, String.valueOf(userId));
        Double score = zSetOps.score(key, String.valueOf(userId));

        if (rank == null || score == null) {
            RankItemDTO dto = new RankItemDTO();
            dto.setUserId(userId);
            User user = userRepository.findById(userId).orElse(null);
            if (user != null) {
                dto.setUserName(user.getRealName() != null ? user.getRealName() : user.getNickname());
                dto.setAvatar(user.getAvatar());
            }
            dto.setScore(0.0);
            dto.setRank(-1);
            return dto;
        }

        return buildRankItem(userId, score, rank.intValue() + 1);
    }

    private RankItemDTO buildRankItem(Long userId, Double score, int rank) {
        RankItemDTO dto = new RankItemDTO();
        dto.setUserId(userId);
        dto.setScore(score != null ? Math.round(score * 100.0) / 100.0 : 0.0);
        dto.setRank(rank);

        User user = userRepository.findById(userId).orElse(null);
        if (user != null) {
            dto.setUserName(user.getRealName() != null ? user.getRealName() : user.getNickname());
            dto.setAvatar(user.getAvatar());
        }

        List<Double> recentScores = getRecentScores(userId, 3);
        dto.setRecentScores(recentScores);

        long taskCount = getCompletedTaskCount(userId);
        dto.setTaskCount((int) taskCount);

        if (taskCount > 0 && score != null) {
            dto.setAverageScore(Math.round(score / taskCount * 100.0) / 100.0);
        } else {
            dto.setAverageScore(0.0);
        }

        return dto;
    }

    private List<Double> getRecentScores(Long userId, int limit) {
        List<TodoItem> items = todoItemRepository
                .findByUserIdAndDeletedFalseOrderByCompletedAtDesc(userId);

        return items.stream()
                .filter(item -> item.getStatus() == TodoItemStatus.COMPLETED && item.getScore() != null)
                .limit(limit)
                .map(TodoItem::getScore)
                .collect(Collectors.toList());
    }

    private long getCompletedTaskCount(Long userId) {
        return todoItemRepository.findByUserIdAndStatusAndDeletedFalse(userId, TodoItemStatus.COMPLETED)
                .size();
    }

    public RankItemDTO getStudentDetail(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException("用户不存在"));

        RankItemDTO dto = new RankItemDTO();
        dto.setUserId(userId);
        dto.setUserName(user.getRealName() != null ? user.getRealName() : user.getNickname());
        dto.setAvatar(user.getAvatar());

        List<Double> recentScores = getRecentScores(userId, 3);
        dto.setRecentScores(recentScores);

        List<TodoItem> completedItems = todoItemRepository
                .findByUserIdAndStatusAndDeletedFalse(userId, TodoItemStatus.COMPLETED);

        dto.setTaskCount(completedItems.size());

        if (!completedItems.isEmpty()) {
            double avgScore = completedItems.stream()
                    .filter(item -> item.getScore() != null)
                    .mapToDouble(TodoItem::getScore)
                    .average()
                    .orElse(0.0);
            double totalScore = completedItems.stream()
                    .filter(item -> item.getScore() != null)
                    .mapToDouble(TodoItem::getScore)
                    .sum();
            dto.setAverageScore(Math.round(avgScore * 100.0) / 100.0);
            dto.setScore(Math.round(totalScore * 100.0) / 100.0);
        } else {
            dto.setAverageScore(0.0);
            dto.setScore(0.0);
        }

        return dto;
    }

    public void refreshAllRankings() {
        log.info("Starting full ranking refresh...");
        List<School> schools = schoolRepository.findAll();
        for (School school : schools) {
            try {
                refreshSchoolRanking(school.getId());
            } catch (Exception e) {
                log.error("Failed to refresh ranking for school: {}", school.getId(), e);
            }
        }
        log.info("Completed full ranking refresh");
    }
}
