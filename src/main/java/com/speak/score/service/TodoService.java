package com.speak.score.service;

import com.speak.score.dto.*;
import com.speak.score.entity.*;
import com.speak.score.exception.BusinessException;
import com.speak.score.repository.ClassMemberRepository;
import com.speak.score.repository.MaterialRepository;
import com.speak.score.repository.TodoItemRepository;
import com.speak.score.repository.TodoTaskRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
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

    @Autowired(required = false)
    private RocketMQProducerService rocketMQProducerService;

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

            sendAsyncNotifications(savedTask, assigneeIds);
        }

        return enrichTaskDTO(savedTask);
    }

    private void sendAsyncNotifications(TodoTask task, List<Long> assigneeIds) {
        try {
            if (rocketMQProducerService != null) {
                rocketMQProducerService.sendTodoTaskMessage(task.getId(), task.getTitle(), "CREATE");
                rocketMQProducerService.sendPushMessage(task.getId(), "新打卡任务", task.getTitle(), assigneeIds);
                rocketMQProducerService.sendWechatMessage(task.getId(), "新打卡任务", task.getTitle(), assigneeIds);
            }
        } catch (Exception e) {
            log.error("Failed to send async notifications for task: {}", task.getId(), e);
        }
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

            sendAsyncNotifications(savedTask, assigneeIds);
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
        List<TodoTask> tasks = todoTaskRepository.findByAssigneeSchoolIdAndDeletedFalse(schoolId);
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
            List<TodoItem> allItems = todoItemRepository.findByTaskIdInAndDeletedFalse(taskIds);
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
}
