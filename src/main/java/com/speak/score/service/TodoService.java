package com.speak.score.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.speak.score.dto.*;
import com.speak.score.entity.*;
import com.speak.score.exception.BusinessException;
import com.speak.score.repository.ClassMemberRepository;
import com.speak.score.repository.MaterialRepository;
import com.speak.score.repository.SpeechScoreDetailRepository;
import com.speak.score.repository.TodoItemRepository;
import com.speak.score.repository.TodoTaskRepository;
import com.speak.score.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class TodoService {

    private final TodoTaskRepository todoTaskRepository;
    private final TodoItemRepository todoItemRepository;
    private final ClassMemberRepository classMemberRepository;
    private final MaterialRepository materialRepository;
    private final NotificationService notificationService;
    private final OssService ossService;
    private final SpeechScoreDetailRepository speechScoreDetailRepository;
    private final UserRepository userRepository;
    private final ParentStudentRepository parentStudentRepository;

    @Autowired(required = false)
    private RocketMQProducerService rocketMQProducerService;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Transactional
    public TodoTaskDTO createTodo(Long creatorId, TodoCreateRequest request) {
        TodoTaskType taskType = TodoTaskType.valueOf(request.getTaskType());
        if ((taskType == TodoTaskType.FOLLOW_READ) && (request.getReferenceText() == null || request.getReferenceText().isEmpty())) {
            throw new BusinessException("跟读任务必须提供参考文本");
        }

        TodoTask task = new TodoTask();
        task.setTitle(request.getTitle());
        task.setDescription(request.getDescription());
        task.setTaskType(taskType);
        task.setPriority(TodoPriority.valueOf(request.getPriority()));
        task.setCreatorId(creatorId);
        task.setAssigneeId(request.getAssigneeId());
        task.setAssigneeType(request.getAssigneeType());
        task.setAssigneeClassId(request.getAssigneeClassId());
        task.setAssigneeSchoolId(request.getAssigneeSchoolId());
        task.setDeadline(request.getDeadline());
        task.setRemindBeforeMin(request.getRemindBeforeMin());
        task.setParentTaskId(request.getParentTaskId());
        task.setMaterialId(request.getMaterialId());
        task.setReferenceText(request.getReferenceText());
        task.setStatus(TodoStatus.PENDING);
        task.setUrgeCount(0);
        task.setRemindSent(false);

        List<Long> assigneeIds = new ArrayList<>();

        if ("CLASS".equals(request.getAssigneeType()) && request.getAssigneeClassId() != null) {
            List<ClassMember> members =
                    classMemberRepository.findByClassId(request.getAssigneeClassId());
            for (ClassMember member : members) {
                assigneeIds.add(member.getUser().getId());
            }
        } else if ("SCHOOL".equals(request.getAssigneeType())) {
            log.warn("School-wide todo assignment may create too many items, skipping item creation");
        } else if ("USER".equals(request.getAssigneeType()) && request.getAssigneeId() != null) {
            assigneeIds.add(request.getAssigneeId());
        }

        TodoTask savedTask = todoTaskRepository.save(task);

        for (Long assigneeId : assigneeIds) {
            TodoItem item = new TodoItem();
            item.setTaskId(savedTask.getId());
            item.setUserId(assigneeId);
            item.setStatus(TodoItemStatus.PENDING);
            todoItemRepository.save(item);
        }

        if (!assigneeIds.isEmpty()) {
            notificationService.sendBatchNotification(
                    creatorId, assigneeIds,
                    "您有一个新的打卡任务：" + request.getTitle(),
                    request.getDescription(),
                    MsgType.TODO, savedTask.getId(), "TODO_TASK"
            );
        }

        return enrichTaskDTO(savedTask);
    }

    @Transactional
    public TodoTaskDTO updateTodo(Long taskId, Long userId, TodoUpdateRequest request) {
        TodoTask task = todoTaskRepository.findById(taskId)
                .orElseThrow(() -> new BusinessException("Task not found"));
        if (!task.getCreatorId().equals(userId)) {
            throw new BusinessException("Only the creator can update this task");
        }
        if (request.getTitle() != null) {
            task.setTitle(request.getTitle());
        }
        if (request.getDescription() != null) {
            task.setDescription(request.getDescription());
        }
        if (request.getPriority() != null) {
            task.setPriority(TodoPriority.valueOf(request.getPriority()));
        }
        if (request.getStatus() != null) {
            task.setStatus(TodoStatus.valueOf(request.getStatus()));
        }
        if (request.getDeadline() != null) {
            task.setDeadline(request.getDeadline());
        }
        if (request.getRemindBeforeMin() != null) {
            task.setRemindBeforeMin(request.getRemindBeforeMin());
        }
        TodoTask savedTask = todoTaskRepository.save(task);
        return enrichTaskDTO(savedTask);
    }

    @Transactional
    public TodoItemDTO submitCheckin(Long taskId, Long userId, MultipartFile audioFile, Integer duration) {
        TodoItem item = todoItemRepository.findByTaskIdAndUserIdAndStatusAndDeletedFalse(taskId, userId, TodoItemStatus.PENDING)
                .orElseThrow(() -> new BusinessException("待完成的打卡项不存在"));

        String audioUrl = ossService.uploadFile(audioFile, "checkin-audio");

        item.setAudioUrl(audioUrl);
        item.setDuration(duration);
        item.setStatus(TodoItemStatus.PENDING_SCORE);
        item.setCompletedAt(LocalDateTime.now());
        TodoItem savedItem = todoItemRepository.save(item);

        TodoTask task = todoTaskRepository.findById(taskId)
                .orElseThrow(() -> new BusinessException("Task not found"));

        try {
            if (rocketMQProducerService != null) {
                rocketMQProducerService.sendScoringMessage(
                        savedItem.getId(), taskId, userId, audioUrl, task.getReferenceText());
            }
        } catch (Exception e) {
            log.error("Failed to send scoring message for item: {}", savedItem.getId(), e);
        }

        notificationService.sendNotification(
                userId, task.getCreatorId(),
                "学生已提交打卡：" + task.getTitle(),
                null,
                MsgType.TODO, taskId, "TODO_TASK"
        );

        notifyParentsOfCheckin(userId, task.getTitle(), "已提交打卡，等待评分", taskId, null);

        return TodoItemDTO.fromEntity(savedItem);
    }

    @Transactional
    public TodoItemDTO completeTodoItem(Long taskId, Long userId, TodoItemCompleteRequest request) {
        TodoItem item = todoItemRepository.findByTaskIdAndUserIdAndDeletedFalse(taskId, userId)
                .orElseThrow(() -> new BusinessException("Todo item not found"));

        TodoItemStatus newStatus = TodoItemStatus.valueOf(request.getStatus());
        item.setStatus(newStatus);
        item.setFeedback(request.getFeedback());
        item.setScore(request.getScore());
        item.setCompletedAt(LocalDateTime.now());
        TodoItem savedItem = todoItemRepository.save(item);

        TodoTask task = todoTaskRepository.findById(taskId)
                .orElseThrow(() -> new BusinessException("Task not found"));

        long totalItems = todoItemRepository.countByTaskIdAndStatusAndDeletedFalse(taskId, TodoItemStatus.PENDING)
                + todoItemRepository.countByTaskIdAndStatusAndDeletedFalse(taskId, TodoItemStatus.COMPLETED)
                + todoItemRepository.countByTaskIdAndStatusAndDeletedFalse(taskId, TodoItemStatus.REJECTED);
        long completedItems = todoItemRepository.countByTaskIdAndStatusAndDeletedFalse(taskId, TodoItemStatus.COMPLETED)
                + todoItemRepository.countByTaskIdAndStatusAndDeletedFalse(taskId, TodoItemStatus.REJECTED);

        if (totalItems > 0 && totalItems == completedItems) {
            task.setStatus(TodoStatus.COMPLETED);
            task.setCompletedAt(LocalDateTime.now());
            todoTaskRepository.save(task);
        }

        notificationService.sendNotification(
                userId, task.getCreatorId(),
                "用户已完成打卡任务：" + task.getTitle(),
                item.getFeedback(),
                MsgType.TODO, taskId, "TODO_TASK"
        );

        notifyParentsOfCheckin(userId, task.getTitle(), "已完成打卡", taskId, item.getScore());

        return TodoItemDTO.fromEntity(savedItem);
    }

    @Transactional
    public TodoTaskDTO urgeTodo(Long taskId, Long userId, UrgeRequest request) {
        TodoTask task = todoTaskRepository.findById(taskId)
                .orElseThrow(() -> new BusinessException("Task not found"));
        if (!task.getCreatorId().equals(userId)) {
            throw new BusinessException("Only the creator can urge this task");
        }

        task.setUrgeCount(task.getUrgeCount() + 1);
        task.setLastUrgeAt(LocalDateTime.now());
        TodoTask savedTask = todoTaskRepository.save(task);

        List<TodoItem> pendingItems =
                todoItemRepository.findByTaskIdAndStatusAndDeletedFalse(taskId, TodoItemStatus.PENDING);
        for (TodoItem item : pendingItems) {
            notificationService.sendNotification(
                    userId, item.getUserId(),
                    "催办提醒：请尽快完成打卡任务「" + task.getTitle() + "」",
                    request.getMessage(),
                    MsgType.URGE, taskId, "TODO_TASK"
            );
        }

        return enrichTaskDTO(savedTask);
    }

    public Page<TodoTaskDTO> getMyTodos(Long userId, String status, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Long> taskIds;
        if (status != null && !status.isEmpty()) {
            TodoItemStatus itemStatus = TodoItemStatus.valueOf(status);
            taskIds = todoItemRepository.findTaskIdsByUserIdAndStatusAndDeletedFalse(userId, itemStatus, pageable);
        } else {
            taskIds = todoItemRepository.findTaskIdsByUserIdAndDeletedFalse(userId, pageable);
        }

        if (taskIds.isEmpty()) {
            return Page.empty(pageable);
        }

        List<TodoTask> tasks = todoTaskRepository.findAllById(taskIds.getContent());
        List<TodoTaskDTO> dtos = tasks.stream()
                .map(this::enrichTaskDTO)
                .collect(Collectors.toList());

        return new org.springframework.data.domain.PageImpl<>(dtos, pageable, taskIds.getTotalElements());
    }

    public Page<TodoTaskDTO> getCreatedTodos(Long userId, String status, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<TodoTask> taskPage;
        if (status != null && !status.isEmpty()) {
            TodoStatus todoStatus = TodoStatus.valueOf(status);
            taskPage = todoTaskRepository.findByCreatorIdAndStatusAndDeletedFalse(userId, todoStatus, pageable);
        } else {
            taskPage = todoTaskRepository.findByCreatorIdAndDeletedFalse(userId, pageable);
        }
        return taskPage.map(this::enrichTaskDTO);
    }

    public TodoTaskDTO getTodoDetail(Long taskId) {
        TodoTask task = todoTaskRepository.findById(taskId)
                .orElseThrow(() -> new BusinessException("Task not found"));
        TodoTaskDTO dto = enrichTaskDTO(task);

        List<TodoItem> items = todoItemRepository.findByTaskIdAndDeletedFalse(taskId);
        dto.setItems(items.stream()
                .map(TodoItemDTO::fromEntity)
                .collect(Collectors.toList()));

        return dto;
    }

    @Transactional
    public void cancelTodo(Long taskId, Long userId) {
        TodoTask task = todoTaskRepository.findById(taskId)
                .orElseThrow(() -> new BusinessException("Task not found"));
        if (!task.getCreatorId().equals(userId)) {
            throw new BusinessException("Only the creator can cancel this task");
        }

        task.setStatus(TodoStatus.CANCELLED);
        todoTaskRepository.save(task);

        List<TodoItem> pendingItems =
                todoItemRepository.findByTaskIdAndStatusAndDeletedFalse(taskId, TodoItemStatus.PENDING);
        for (TodoItem item : pendingItems) {
            notificationService.sendNotification(
                    userId, item.getUserId(),
                    "打卡任务「" + task.getTitle() + "」已取消",
                    null,
                    MsgType.SYSTEM, taskId, "TODO_TASK"
            );
        }
    }

    @Transactional
    public TodoTaskDTO copyTask(Long sourceTaskId, Long creatorId) {
        TodoTask source = todoTaskRepository.findById(sourceTaskId)
                .orElseThrow(() -> new BusinessException("Source task not found"));

        TodoTask newTask = new TodoTask();
        newTask.setTitle(source.getTitle());
        newTask.setDescription(source.getDescription());
        newTask.setTaskType(source.getTaskType());
        newTask.setPriority(source.getPriority());
        newTask.setCreatorId(creatorId);
        newTask.setAssigneeType(source.getAssigneeType());
        newTask.setAssigneeClassId(source.getAssigneeClassId());
        newTask.setAssigneeSchoolId(source.getAssigneeSchoolId());
        newTask.setMaterialId(source.getMaterialId());
        newTask.setReferenceText(source.getReferenceText());
        newTask.setRemindBeforeMin(source.getRemindBeforeMin());
        newTask.setParentTaskId(source.getId());
        newTask.setStatus(TodoStatus.PENDING);
        newTask.setUrgeCount(0);
        newTask.setRemindSent(false);
        newTask.setDeadline(LocalDateTime.now().plusDays(1));

        List<Long> assigneeIds = new ArrayList<>();

        if ("CLASS".equals(source.getAssigneeType()) && source.getAssigneeClassId() != null) {
            List<ClassMember> members =
                    classMemberRepository.findByClassId(source.getAssigneeClassId());
            for (ClassMember member : members) {
                assigneeIds.add(member.getUser().getId());
            }
        } else if ("USER".equals(source.getAssigneeType()) && source.getAssigneeId() != null) {
            assigneeIds.add(source.getAssigneeId());
        }

        TodoTask savedTask = todoTaskRepository.save(newTask);

        for (Long assigneeId : assigneeIds) {
            TodoItem item = new TodoItem();
            item.setTaskId(savedTask.getId());
            item.setUserId(assigneeId);
            item.setStatus(TodoItemStatus.PENDING);
            todoItemRepository.save(item);
        }

        if (!assigneeIds.isEmpty()) {
            notificationService.sendBatchNotification(
                    creatorId, assigneeIds,
                    "您有一个新的打卡任务：" + newTask.getTitle(),
                    newTask.getDescription(),
                    MsgType.TODO, savedTask.getId(), "TODO_TASK"
            );
        }

        return enrichTaskDTO(savedTask);
    }

    public TodoTaskProgressDTO getTaskProgress(Long taskId) {
        TodoTask task = todoTaskRepository.findById(taskId)
                .orElseThrow(() -> new BusinessException("Task not found"));

        long completedCount = todoItemRepository.countByTaskIdAndStatusAndDeletedFalse(taskId, TodoItemStatus.COMPLETED);
        long pendingCount = todoItemRepository.countByTaskIdAndStatusAndDeletedFalse(taskId, TodoItemStatus.PENDING);
        int total = (int) (completedCount + pendingCount);
        Double avgScore = todoItemRepository.findAverageScoreByTaskIdAndStatusAndDeletedFalse(taskId, TodoItemStatus.COMPLETED);

        TodoTaskProgressDTO dto = new TodoTaskProgressDTO();
        dto.setTaskId(task.getId());
        dto.setTitle(task.getTitle());
        dto.setTaskType(task.getTaskType() != null ? task.getTaskType().name() : null);
        dto.setStatus(task.getStatus() != null ? task.getStatus().name() : null);
        dto.setDeadline(task.getDeadline() != null ? task.getDeadline().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")) : null);
        dto.setTotalStudents(total);
        dto.setCompletedCount((int) completedCount);
        dto.setPendingCount((int) pendingCount);
        dto.setAverageScore(avgScore != null ? Math.round(avgScore * 100.0) / 100.0 : null);
        dto.setCompletionRate(total > 0 ? Math.round(completedCount * 10000.0 / total) / 100.0 : 0.0);
        return dto;
    }

    public List<TodoTaskProgressDTO> getTaskProgressByClass(Long creatorId, Long classId) {
        List<TodoTask> tasks;
        if (classId != null) {
            tasks = todoTaskRepository.findByAssigneeClassIdAndDeletedFalse(classId);
        } else {
            tasks = todoTaskRepository.findByCreatorIdAndDeletedFalse(creatorId);
        }
        return tasks.stream().map(task -> {
            long completedCount = todoItemRepository.countByTaskIdAndStatusAndDeletedFalse(task.getId(), TodoItemStatus.COMPLETED);
            long pendingCount = todoItemRepository.countByTaskIdAndStatusAndDeletedFalse(task.getId(), TodoItemStatus.PENDING);
            int total = (int) (completedCount + pendingCount);
            Double avgScore = todoItemRepository.findAverageScoreByTaskIdAndStatusAndDeletedFalse(task.getId(), TodoItemStatus.COMPLETED);

            TodoTaskProgressDTO dto = new TodoTaskProgressDTO();
            dto.setTaskId(task.getId());
            dto.setTitle(task.getTitle());
            dto.setTaskType(task.getTaskType() != null ? task.getTaskType().name() : null);
            dto.setStatus(task.getStatus() != null ? task.getStatus().name() : null);
            dto.setDeadline(task.getDeadline() != null ? task.getDeadline().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")) : null);
            dto.setTotalStudents(total);
            dto.setCompletedCount((int) completedCount);
            dto.setPendingCount((int) pendingCount);
            dto.setAverageScore(avgScore != null ? Math.round(avgScore * 100.0) / 100.0 : null);
            dto.setCompletionRate(total > 0 ? Math.round(completedCount * 10000.0 / total) / 100.0 : 0.0);
            return dto;
        }).collect(Collectors.toList());
    }

    public SchoolTaskStatsDTO getSchoolTaskStats(Long schoolId) {
        return getSchoolTaskStats(schoolId, null, null);
    }

    public SchoolTaskStatsDTO getSchoolTaskStats(Long schoolId, LocalDate startDate, LocalDate endDate) {
        List<TodoTask> tasks;
        if (startDate != null && endDate != null) {
            LocalDateTime startTime = startDate.atStartOfDay();
            LocalDateTime endTime = endDate.atTime(23, 59, 59);
            tasks = todoTaskRepository.findByAssigneeSchoolIdAndCreatedAtBetweenAndDeletedFalse(schoolId, startTime, endTime);
        } else {
            tasks = todoTaskRepository.findByAssigneeSchoolIdAndDeletedFalse(schoolId);
        }

        long totalTasks = tasks.size();
        long activeTasks = tasks.stream().filter(t -> t.getStatus() == TodoStatus.PENDING || t.getStatus() == TodoStatus.IN_PROGRESS).count();
        long completedTasks = tasks.stream().filter(t -> t.getStatus() == TodoStatus.COMPLETED).count();

        List<Long> taskIds = tasks.stream().map(TodoTask::getId).collect(Collectors.toList());
        long totalCheckins = 0;
        double totalScore = 0;
        long scoredCount = 0;
        long totalItems = 0;
        long completedItems = 0;

        if (!taskIds.isEmpty()) {
            List<TodoItem> allItems;
            if (startDate != null && endDate != null) {
                LocalDateTime startTime = startDate.atStartOfDay();
                LocalDateTime endTime = endDate.atTime(23, 59, 59);
                allItems = todoItemRepository.findByTaskIdInAndCreatedAtBetweenAndDeletedFalse(taskIds, startTime, endTime);
            } else {
                allItems = todoItemRepository.findByTaskIdInAndDeletedFalse(taskIds);
            }
            totalItems = allItems.size();
            for (TodoItem item : allItems) {
                if (item.getStatus() == TodoItemStatus.COMPLETED) {
                    completedItems++;
                    if (item.getScore() != null) {
                        totalScore += item.getScore();
                        scoredCount++;
                    }
                }
            }
            totalCheckins = completedItems;
        }

        SchoolTaskStatsDTO dto = new SchoolTaskStatsDTO();
        dto.setSchoolId(schoolId);
        dto.setTotalTasks(totalTasks);
        dto.setActiveTasks(activeTasks);
        dto.setCompletedTasks(completedTasks);
        dto.setTotalCheckins(totalCheckins);
        dto.setAverageScore(scoredCount > 0 ? Math.round(totalScore / scoredCount * 100.0) / 100.0 : null);
        dto.setCompletionRate(totalItems > 0 ? Math.round(completedItems * 10000.0 / totalItems) / 100.0 : 0.0);
        return dto;
    }

    private TodoTaskDTO enrichTaskDTO(TodoTask task) {
        TodoTaskDTO dto = TodoTaskDTO.fromEntity(task);

        if (task.getMaterialId() != null) {
            materialRepository.findById(task.getMaterialId()).ifPresent(material -> {
                dto.setMaterialTitle(material.getTitle());
                dto.setMaterialType(material.getMaterialType() != null ? material.getMaterialType().name() : null);
            });
        }

        long completedCount = todoItemRepository.countByTaskIdAndStatusAndDeletedFalse(task.getId(), TodoItemStatus.COMPLETED);
        long pendingCount = todoItemRepository.countByTaskIdAndStatusAndDeletedFalse(task.getId(), TodoItemStatus.PENDING);
        Double avgScore = todoItemRepository.findAverageScoreByTaskIdAndStatusAndDeletedFalse(task.getId(), TodoItemStatus.COMPLETED);
        dto.setCompletedCount((int) completedCount);
        dto.setPendingCount((int) pendingCount);
        dto.setAverageScore(avgScore != null ? Math.round(avgScore * 100.0) / 100.0 : null);

        return dto;
    }

    @Transactional
    public TodoItemDTO teacherReview(Long itemId, Long teacherId, Double score, String feedback, MultipartFile audioFile) {
        TodoItem item = todoItemRepository.findById(itemId)
                .orElseThrow(() -> new BusinessException("Todo item not found"));

        if (item.getStatus() != TodoItemStatus.NEEDS_REVIEW
                && item.getStatus() != TodoItemStatus.COMPLETED
                && item.getStatus() != TodoItemStatus.PENDING_SCORE) {
            throw new BusinessException("当前状态不允许教师评阅");
        }

        if (audioFile != null && !audioFile.isEmpty()) {
            String teacherAudioUrl = ossService.uploadFile(audioFile, "teacher-review-audio");
            item.setTeacherAudioUrl(teacherAudioUrl);
        }

        item.setTeacherScore(score);
        item.setTeacherFeedback(feedback);
        item.setTeacherId(teacherId);
        item.setTeacherReviewedAt(LocalDateTime.now());
        if (score != null) {
            item.setScore(score);
        }
        item.setStatus(TodoItemStatus.COMPLETED);
        item.setNeedsManualReview(false);

        TodoItem savedItem = todoItemRepository.save(item);

        TodoTask task = todoTaskRepository.findById(savedItem.getTaskId()).orElse(null);
        if (task != null) {
            notificationService.sendNotification(
                    teacherId, savedItem.getUserId(),
                    "教师已评阅您的打卡：" + task.getTitle(),
                    feedback,
                    MsgType.SCORE, savedItem.getTaskId(), "TODO_TASK"
            );

            notifyParentsOfCheckin(savedItem.getUserId(), task.getTitle(),
                    "教师已评阅，得分：" + (score != null ? String.format("%.1f", score) : "暂无"),
                    savedItem.getTaskId(), score);
        }

        return TodoItemDTO.fromEntity(savedItem);
    }

    public SpeechScoreResult getScoreDetail(Long itemId) {
        SpeechScoreDetail detail = speechScoreDetailRepository.findTopByItemIdOrderByScoredAtDesc(itemId)
                .orElse(null);

        if (detail == null) {
            SpeechScoreResult result = new SpeechScoreResult();
            result.setSuccess(false);
            result.setErrorMessage("暂无评分详情");
            return result;
        }

        SpeechScoreResult result = new SpeechScoreResult();
        result.setOverallScore(detail.getOverallScore());
        result.setPronunciationScore(detail.getPronunciationScore());
        result.setFluencyScore(detail.getFluencyScore());
        result.setCompletenessScore(detail.getCompletenessScore());
        result.setAccuracyScore(detail.getAccuracyScore());
        result.setSuccess(true);

        if (detail.getErrorWordsJson() != null && !detail.getErrorWordsJson().isEmpty()) {
            try {
                List<SpeechScoreResult.ErrorWord> errorWords = objectMapper.readValue(
                        detail.getErrorWordsJson(),
                        new TypeReference<List<SpeechScoreResult.ErrorWord>>() {}
                );
                result.setErrorWords(errorWords);
            } catch (Exception e) {
                log.warn("Failed to parse error words JSON for itemId: {}", itemId, e);
                result.setErrorWords(Collections.emptyList());
            }
        } else {
            result.setErrorWords(Collections.emptyList());
        }

        return result;
    }

    public TodoItemDTO getItemDetail(Long itemId) {
        TodoItem item = todoItemRepository.findById(itemId)
                .orElseThrow(() -> new BusinessException("打卡记录不存在"));

        TodoItemDTO dto = TodoItemDTO.fromEntity(item);

        if (item.getTaskId() != null) {
            todoTaskRepository.findById(item.getTaskId()).ifPresent(task -> {
                dto.setTaskTitle(task.getTitle());
                dto.setReferenceText(task.getReferenceText());
            });
        }

        if (item.getUserId() != null) {
            userRepository.findById(item.getUserId()).ifPresent(user -> {
                dto.setUserName(user.getRealName() != null ? user.getRealName() : user.getNickname());
            });
        }

        if (item.getTeacherId() != null) {
            userRepository.findById(item.getTeacherId()).ifPresent(user -> {
                dto.setTeacherName(user.getRealName() != null ? user.getRealName() : user.getNickname());
            });
        }

        return dto;
    }

    private void notifyParentsOfCheckin(Long studentId, String taskTitle, String statusText, Long taskId, Double score) {
        try {
            List<Long> parentIds = parentStudentRepository.findByStudentIdAndDeletedFalse(studentId)
                    .stream()
                    .map(ps -> ps.getParentId())
                    .collect(Collectors.toList());

            if (parentIds.isEmpty()) {
                return;
            }

            User student = userRepository.findById(studentId).orElse(null);
            String studentName = student != null
                    ? (student.getRealName() != null ? student.getRealName() : student.getNickname())
                    : "孩子";

            String title = "孩子打卡动态：" + studentName;
            StringBuilder content = new StringBuilder();
            content.append(studentName).append(" ").append(statusText);
            content.append("\n任务：").append(taskTitle);
            if (score != null) {
                content.append("\n得分：").append(String.format("%.1f", score));
            }

            Map<String, Object> extraData = new HashMap<>();
            extraData.put("studentId", studentId);
            extraData.put("studentName", studentName);
            extraData.put("taskId", taskId);
            extraData.put("score", score);
            extraData.put("status", statusText);

            notificationService.sendBatchNotification(
                    studentId, parentIds,
                    title, content.toString(),
                    MsgType.PARENT_REPORT, taskId, "TODO_TASK",
                    extraData
            );
        } catch (Exception e) {
            log.error("Failed to notify parents for student: {}", studentId, e);
        }
    }
}
