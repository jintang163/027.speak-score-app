package com.speak.score.service;

import com.alibaba.excel.EasyExcel;
import com.speak.score.config.NotificationConfig;
import com.speak.score.dto.*;
import com.speak.score.entity.*;
import com.speak.score.exception.BusinessException;
import com.speak.score.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.mail.internet.MimeMessage;
import java.io.ByteArrayOutputStream;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class ReportService {

    private final TodoTaskRepository todoTaskRepository;
    private final TodoItemRepository todoItemRepository;
    private final UserRepository userRepository;
    private final ClassRepository classRepository;
    private final ClassMemberRepository classMemberRepository;
    private final GradeRepository gradeRepository;
    private final SchoolRepository schoolRepository;
    private final NotificationConfig notificationConfig;
    private final JavaMailSender javaMailSender;

    public void validateStudentAccess(Long currentUserId, Long targetStudentId) {
        if (currentUserId.equals(targetStudentId)) {
            return;
        }

        User currentUser = userRepository.findById(currentUserId)
                .orElseThrow(() -> new BusinessException("用户不存在"));

        boolean isTeacher = currentUser.getRoles().stream()
                .anyMatch(r -> r.getRoleCode() == RoleEnum.TEACHER);
        boolean isEduOffice = currentUser.getRoles().stream()
                .anyMatch(r -> r.getRoleCode() == RoleEnum.EDU_OFFICE);

        if (isEduOffice) {
            return;
        }

        if (isTeacher) {
            List<ClassEntity> teacherClasses = classRepository.findByTeacherId(currentUserId);
            List<Long> classIds = teacherClasses.stream()
                    .map(ClassEntity::getId)
                    .collect(Collectors.toList());

            if (classIds.isEmpty()) {
                throw new BusinessException("无权访问该学生数据");
            }

            boolean isStudentInClass = classMemberRepository.existsByClassIdInAndUserIdAndRoleCodeAndDeletedFalse(
                    classIds, targetStudentId, RoleEnum.STUDENT);

            if (!isStudentInClass) {
                throw new BusinessException("无权访问该学生数据");
            }
            return;
        }

        throw new BusinessException("无权访问该学生数据");
    }

    public void validateClassAccess(Long currentUserId, Long classId) {
        User currentUser = userRepository.findById(currentUserId)
                .orElseThrow(() -> new BusinessException("用户不存在"));

        boolean isEduOffice = currentUser.getRoles().stream()
                .anyMatch(r -> r.getRoleCode() == RoleEnum.EDU_OFFICE);

        if (isEduOffice) {
            return;
        }

        boolean isTeacher = currentUser.getRoles().stream()
                .anyMatch(r -> r.getRoleCode() == RoleEnum.TEACHER);

        if (isTeacher) {
            List<ClassEntity> teacherClasses = classRepository.findByTeacherId(currentUserId);
            boolean hasAccess = teacherClasses.stream()
                    .anyMatch(c -> c.getId().equals(classId));

            if (!hasAccess) {
                throw new BusinessException("无权访问该班级数据");
            }
            return;
        }

        throw new BusinessException("无权访问该班级数据");
    }

    public StudentCalendarDTO getStudentCalendar(Long studentId, LocalDate startDate, LocalDate endDate) {
        User student = userRepository.findById(studentId)
                .orElseThrow(() -> new BusinessException("学生不存在"));

        LocalDateTime startTime = startDate.atStartOfDay();
        LocalDateTime endTime = endDate.atTime(LocalTime.MAX);

        List<TodoItem> allItems = todoItemRepository.findByUserIdAndDeletedFalseOrderByCompletedAtDesc(studentId);

        List<Long> taskIds = allItems.stream()
                .map(TodoItem::getTaskId)
                .filter(Objects::nonNull)
                .distinct()
                .collect(Collectors.toList());

        Map<Long, TodoTask> taskMap = new HashMap<>();
        if (!taskIds.isEmpty()) {
            List<TodoTask> tasks = todoTaskRepository.findAllById(taskIds);
            for (TodoTask task : tasks) {
                taskMap.put(task.getId(), task);
            }
        }

        Map<LocalDate, List<TodoItem>> itemsByDeadline = new HashMap<>();
        for (TodoItem item : allItems) {
            TodoTask task = taskMap.get(item.getTaskId());
            if (task == null || task.getDeadline() == null) {
                continue;
            }
            LocalDate deadlineDate = task.getDeadline().toLocalDate();
            if (deadlineDate.isBefore(startDate) || deadlineDate.isAfter(endDate)) {
                continue;
            }
            itemsByDeadline.computeIfAbsent(deadlineDate, k -> new ArrayList<>()).add(item);
        }

        List<StudentCalendarDayDTO> dayList = new ArrayList<>();
        int checkedDays = 0;
        int highScoreDays = 0;
        int missedDays = 0;
        double totalScore = 0;
        int scoredDays = 0;

        LocalDate today = LocalDate.now();

        for (LocalDate date = startDate; !date.isAfter(endDate); date = date.plusDays(1)) {
            StudentCalendarDayDTO dayDTO = new StudentCalendarDayDTO();
            dayDTO.setDate(date.toString());

            List<TodoItem> dayItems = itemsByDeadline.getOrDefault(date, Collections.emptyList());
            int taskCount = dayItems.size();
            long completedCount = dayItems.stream()
                    .filter(item -> item.getStatus() == TodoItemStatus.COMPLETED)
                    .count();

            dayDTO.setTaskCount(taskCount);
            dayDTO.setCompletedCount((int) completedCount);

            if (taskCount > 0) {
                if (completedCount == taskCount) {
                    checkedDays++;
                    TodoItem firstCompleted = dayItems.stream()
                            .filter(item -> item.getStatus() == TodoItemStatus.COMPLETED)
                            .findFirst()
                            .orElse(null);
                    if (firstCompleted != null) {
                        dayDTO.setItemId(firstCompleted.getId());
                    }

                    Double avgScore = dayItems.stream()
                            .filter(item -> item.getScore() != null)
                            .mapToDouble(TodoItem::getScore)
                            .average()
                            .orElse(0.0);

                    dayDTO.setScore(avgScore > 0 ? Math.round(avgScore * 100.0) / 100.0 : null);

                    if (avgScore >= 90) {
                        highScoreDays++;
                        dayDTO.setStatus("HIGH_SCORE");
                    } else {
                        dayDTO.setStatus("COMPLETED");
                    }

                    if (avgScore > 0) {
                        totalScore += avgScore;
                        scoredDays++;
                    }
                } else if (date.isBefore(today)) {
                    missedDays++;
                    dayDTO.setStatus("MISSED");
                } else {
                    dayDTO.setStatus("PENDING");
                }
            } else {
                dayDTO.setStatus("NONE");
            }

            dayList.add(dayDTO);
        }

        int totalDays = (int) (endDate.toEpochDay() - startDate.toEpochDay() + 1);

        StudentCalendarDTO result = new StudentCalendarDTO();
        result.setStudentId(studentId);
        result.setStudentName(student.getRealName() != null ? student.getRealName() : student.getNickname());
        result.setTotalDays(totalDays);
        result.setCheckedDays(checkedDays);
        result.setMissedDays(missedDays);
        result.setHighScoreDays(highScoreDays);
        result.setAverageScore(scoredDays > 0 ? Math.round(totalScore / scoredDays * 100.0) / 100.0 : null);
        result.setCompletionRate(totalDays > 0 ? Math.round(checkedDays * 10000.0 / totalDays) / 100.0 : 0.0);
        result.setDays(dayList);

        return result;
    }

    public ClassReportDTO getClassReport(Long classId, LocalDate startDate, LocalDate endDate) {
        ClassEntity classEntity = classRepository.findById(classId)
                .orElseThrow(() -> new BusinessException("班级不存在"));

        LocalDateTime startTime = startDate.atStartOfDay();
        LocalDateTime endTime = endDate.atTime(LocalTime.MAX);

        List<TodoTask> tasks = todoTaskRepository.findByAssigneeClassIdAndDeletedFalse(classId);
        List<Long> taskIds = tasks.stream()
                .filter(t -> t.getCreatedAt() != null &&
                        !t.getCreatedAt().isBefore(startTime) &&
                        !t.getCreatedAt().isAfter(endTime))
                .map(TodoTask::getId)
                .collect(Collectors.toList());

        long totalStudents = classMemberRepository.countByClassIdAndRoleCodeAndStatusAndDeletedFalse(
                classId, RoleEnum.STUDENT);

        long completedStudents = taskIds.isEmpty() ? 0 :
                todoItemRepository.countDistinctUserIdByTaskIdInAndStatusAndDeletedFalse(
                        taskIds, TodoItemStatus.COMPLETED);

        Double avgScore = taskIds.isEmpty() ? null :
                todoItemRepository.findAverageScoreByTaskIdInAndStatusAndDeletedFalse(
                        taskIds, TodoItemStatus.COMPLETED);

        List<ScoreDistributionDTO> distribution = buildScoreDistribution(taskIds);

        ClassReportDTO result = new ClassReportDTO();
        result.setClassId(classId);
        result.setClassName(classEntity.getClassName());
        result.setTotalStudents((int) totalStudents);
        result.setTotalTasks(taskIds.size());
        result.setCompletedTasks((int) tasks.stream()
                .filter(t -> t.getStatus() == TodoStatus.COMPLETED)
                .count());
        result.setAverageScore(avgScore != null ? Math.round(avgScore * 100.0) / 100.0 : null);
        result.setCompletionRate(totalStudents > 0 ?
                Math.round(completedStudents * 10000.0 / totalStudents) / 100.0 : 0.0);
        result.setScoreDistribution(distribution);

        return result;
    }

    private List<ScoreDistributionDTO> buildScoreDistribution(List<Long> taskIds) {
        List<ScoreDistributionDTO> distribution = new ArrayList<>();

        if (taskIds.isEmpty()) {
            distribution.add(new ScoreDistributionDTO("优秀", "≥90", 0, 0.0));
            distribution.add(new ScoreDistributionDTO("良好", "70-89", 0, 0.0));
            distribution.add(new ScoreDistributionDTO("一般", "50-69", 0, 0.0));
            distribution.add(new ScoreDistributionDTO("待提升", "<50", 0, 0.0));
            return distribution;
        }

        List<Object[]> studentScores = todoItemRepository
                .findAverageScoreByTaskIdInAndStatusGroupByUserId(taskIds, TodoItemStatus.COMPLETED);

        int excellent = 0, good = 0, average = 0, poor = 0;
        int total = studentScores.size();

        for (Object[] row : studentScores) {
            Double score = (Double) row[1];
            if (score == null) continue;
            if (score >= 90) excellent++;
            else if (score >= 70) good++;
            else if (score >= 50) average++;
            else poor++;
        }

        distribution.add(new ScoreDistributionDTO("优秀", "≥90", excellent,
                total > 0 ? Math.round(excellent * 10000.0 / total) / 100.0 : 0.0));
        distribution.add(new ScoreDistributionDTO("良好", "70-89", good,
                total > 0 ? Math.round(good * 10000.0 / total) / 100.0 : 0.0));
        distribution.add(new ScoreDistributionDTO("一般", "50-69", average,
                total > 0 ? Math.round(average * 10000.0 / total) / 100.0 : 0.0));
        distribution.add(new ScoreDistributionDTO("待提升", "<50", poor,
                total > 0 ? Math.round(poor * 10000.0 / total) / 100.0 : 0.0));

        return distribution;
    }

    public StudentProgressSeriesDTO getStudentProgress(Long studentId, LocalDate startDate, LocalDate endDate) {
        User student = userRepository.findById(studentId)
                .orElseThrow(() -> new BusinessException("学生不存在"));

        LocalDateTime startTime = startDate.atStartOfDay();
        LocalDateTime endTime = endDate.atTime(LocalTime.MAX);

        List<TodoItem> items = todoItemRepository
                .findByUserIdAndCompletedAtBetweenAndDeletedFalse(studentId, startTime, endTime);

        Map<LocalDate, List<TodoItem>> itemsByDate = items.stream()
                .filter(item -> item.getCompletedAt() != null && item.getScore() != null)
                .collect(Collectors.groupingBy(item -> item.getCompletedAt().toLocalDate()));

        List<StudentProgressDTO> progressList = new ArrayList<>();
        for (LocalDate date = startDate; !date.isAfter(endDate); date = date.plusDays(1)) {
            List<TodoItem> dayItems = itemsByDate.getOrDefault(date, Collections.emptyList());
            StudentProgressDTO dto = new StudentProgressDTO();
            dto.setDate(date.toString());
            dto.setTaskCount(dayItems.size());

            long completedCount = dayItems.stream()
                    .filter(item -> item.getStatus() == TodoItemStatus.COMPLETED)
                    .count();
            dto.setCompletedCount((int) completedCount);

            OptionalDouble avgScore = dayItems.stream()
                    .filter(item -> item.getScore() != null)
                    .mapToDouble(TodoItem::getScore)
                    .average();

            dto.setAverageScore(avgScore.isPresent() ?
                    Math.round(avgScore.getAsDouble() * 100.0) / 100.0 : null);

            progressList.add(dto);
        }

        StudentProgressSeriesDTO result = new StudentProgressSeriesDTO();
        result.setStudentId(studentId);
        result.setStudentName(student.getRealName() != null ? student.getRealName() : student.getNickname());
        result.setProgress(progressList);

        return result;
    }

    public List<ClassComparisonDTO> getClassComparison(Long schoolId, Long gradeId, LocalDate startDate, LocalDate endDate) {
        schoolRepository.findById(schoolId)
                .orElseThrow(() -> new BusinessException("学校不存在"));

        List<ClassEntity> classes;
        if (gradeId != null) {
            classes = classRepository.findByGradeId(gradeId);
        } else {
            classes = classRepository.findBySchoolId(schoolId);
        }

        List<ClassComparisonDTO> result = new ArrayList<>();
        for (ClassEntity cls : classes) {
            ClassReportDTO classReport = getClassReport(cls.getId(), startDate, endDate);

            ClassComparisonDTO dto = new ClassComparisonDTO();
            dto.setClassId(cls.getId());
            dto.setClassName(cls.getClassName());

            if (cls.getGrade() != null) {
                dto.setGradeName(cls.getGrade().getGradeName());
            }

            dto.setStudentCount(classReport.getTotalStudents());
            dto.setAverageScore(classReport.getAverageScore());
            dto.setCompletionRate(classReport.getCompletionRate());
            dto.setTotalTasks(classReport.getTotalTasks());

            result.add(dto);
        }

        result.sort(Comparator.comparing(ClassComparisonDTO::getAverageScore,
                Comparator.nullsLast(Comparator.reverseOrder())));

        return result;
    }

    public byte[] exportClassReport(Long classId, LocalDate startDate, LocalDate endDate) {
        ClassEntity classEntity = classRepository.findById(classId)
                .orElseThrow(() -> new BusinessException("班级不存在"));

        LocalDateTime startTime = startDate.atStartOfDay();
        LocalDateTime endTime = endDate.atTime(LocalTime.MAX);

        List<TodoTask> tasks = todoTaskRepository.findByAssigneeClassIdAndDeletedFalse(classId);
        List<Long> taskIds = tasks.stream()
                .filter(t -> t.getCreatedAt() != null &&
                        !t.getCreatedAt().isBefore(startTime) &&
                        !t.getCreatedAt().isAfter(endTime))
                .map(TodoTask::getId)
                .collect(Collectors.toList());

        List<ClassMember> members = classMemberRepository
                .findByClassIdAndRoleCodeAndStatusAndDeletedFalse(classId, RoleEnum.STUDENT);

        String period = startDate.format(DateTimeFormatter.ofPattern("yyyy-MM-dd")) +
                " ~ " + endDate.format(DateTimeFormatter.ofPattern("yyyy-MM-dd"));

        List<HomeworkReportExcelDTO> excelData = new ArrayList<>();

        if (taskIds.isEmpty()) {
            for (ClassMember member : members) {
                User user = member.getUser();
                HomeworkReportExcelDTO dto = new HomeworkReportExcelDTO();
                dto.setStudentName(user.getRealName() != null ? user.getRealName() : user.getNickname());
                dto.setStudentNo(user.getUsername());
                dto.setClassName(classEntity.getClassName());
                dto.setTotalTasks(0);
                dto.setCompletedTasks(0);
                dto.setPendingTasks(0);
                dto.setCompletionRate("0%");
                dto.setAverageScore("-");
                dto.setHighestScore("-");
                dto.setLowestScore("-");
                dto.setPeriod(period);
                excelData.add(dto);
            }
        } else {
            Map<Long, Object[]> studentStatsMap = new HashMap<>();
            List<Object[]> studentStats = todoItemRepository
                    .findStudentStatsByTaskIdInAndStatus(taskIds, TodoItemStatus.COMPLETED);
            for (Object[] row : studentStats) {
                Long userId = (Long) row[0];
                studentStatsMap.put(userId, row);
            }

            Map<Long, Long> completedTasksMap = new HashMap<>();
            for (Long taskId : taskIds) {
                List<TodoItem> completedItems = todoItemRepository
                        .findByTaskIdAndStatusAndDeletedFalse(taskId, TodoItemStatus.COMPLETED);
                for (TodoItem item : completedItems) {
                    completedTasksMap.merge(item.getUserId(), 1L, Long::sum);
                }
            }

            for (ClassMember member : members) {
                User user = member.getUser();
                Long userId = user.getId();

                HomeworkReportExcelDTO dto = new HomeworkReportExcelDTO();
                dto.setStudentName(user.getRealName() != null ? user.getRealName() : user.getNickname());
                dto.setStudentNo(user.getUsername());
                dto.setClassName(classEntity.getClassName());
                dto.setTotalTasks(taskIds.size());

                long completed = completedTasksMap.getOrDefault(userId, 0L);
                dto.setCompletedTasks((int) completed);
                dto.setPendingTasks(taskIds.size() - (int) completed);
                dto.setCompletionRate(
                        taskIds.size() > 0 ?
                                Math.round(completed * 10000.0 / taskIds.size()) / 100.0 + "%" :
                                "0%");

                Object[] stats = studentStatsMap.get(userId);
                if (stats != null) {
                    Double avgScore = (Double) stats[1];
                    Double maxScore = (Double) stats[2];
                    Double minScore = (Double) stats[3];
                    dto.setAverageScore(avgScore != null ?
                            String.format("%.1f", avgScore) : "-");
                    dto.setHighestScore(maxScore != null ?
                            String.format("%.1f", maxScore) : "-");
                    dto.setLowestScore(minScore != null ?
                            String.format("%.1f", minScore) : "-");
                } else {
                    dto.setAverageScore("-");
                    dto.setHighestScore("-");
                    dto.setLowestScore("-");
                }

                dto.setPeriod(period);
                excelData.add(dto);
            }
        }

        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        EasyExcel.write(outputStream, HomeworkReportExcelDTO.class)
                .sheet("作业报告")
                .doWrite(excelData);

        return outputStream.toByteArray();
    }

    @Transactional
    public boolean sendReportByEmail(Long classId, String toEmail, LocalDate startDate, LocalDate endDate) {
        if (!notificationConfig.getEmail().isEnabled()) {
            log.warn("Email notification is disabled");
            throw new BusinessException("邮件功能未启用");
        }

        ClassEntity classEntity = classRepository.findById(classId)
                .orElseThrow(() -> new BusinessException("班级不存在"));

        byte[] excelData = exportClassReport(classId, startDate, endDate);

        String period = startDate.format(DateTimeFormatter.ofPattern("yyyy-MM-dd")) +
                " ~ " + endDate.format(DateTimeFormatter.ofPattern("yyyy-MM-dd"));

        String subject = "【" + classEntity.getClassName() + "】作业成绩报表 - " + period;
        String body = "您好，\n\n附件是" + classEntity.getClassName() + "在 " + period + " 期间的作业成绩报表，请查收。\n\n"
                + "此邮件由系统自动发送，请勿直接回复。";

        try {
            MimeMessage message = javaMailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
            helper.setFrom(notificationConfig.getEmail().getFrom());
            helper.setTo(toEmail);
            helper.setSubject(subject);
            helper.setText(body);

            String fileName = "作业报告_" + classEntity.getClassName() + "_" +
                    startDate.format(DateTimeFormatter.ofPattern("yyyyMMdd")) + "_" +
                    endDate.format(DateTimeFormatter.ofPattern("yyyyMMdd")) + ".xlsx";

            helper.addAttachment(fileName,
                    new org.springframework.core.io.ByteArrayResource(excelData));

            javaMailSender.send(message);
            log.info("Report email sent to: {}", toEmail);
            return true;
        } catch (Exception e) {
            log.error("Failed to send report email to: {}", toEmail, e);
            throw new BusinessException("邮件发送失败: " + e.getMessage());
        }
    }
}
