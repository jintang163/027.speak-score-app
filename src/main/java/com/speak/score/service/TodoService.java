package com.speak.score.service;

import com.speak.score.dto.*;
import com.speak.score.entity.*;
import com.speak.score.exception.BusinessException;
import com.speak.score.repository.ClassMemberRepository;
import com.speak.score.repository.TodoItemRepository;
import com.speak.score.repository.TodoTaskRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
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
    private final NotificationService notificationService;

    @Transactional
    public TodoTaskDTO createTodo(Long creatorId, TodoCreateRequest request) {
        TodoTask task = new TodoTask();
        task.setTitle(request.getTitle());
        task.setDescription(request.getDescription());
        task.setTaskType(TodoTaskType.valueOf(request.getTaskType()));
        task.setPriority(TodoPriority.valueOf(request.getPriority()));
        task.setCreatorId(creatorId);
        task.setAssigneeId(request.getAssigneeId());
        task.setAssigneeType(request.getAssigneeType());
        task.setAssigneeClassId(request.getAssigneeClassId());
        task.setAssigneeSchoolId(request.getAssigneeSchoolId());
        task.setDeadline(request.getDeadline());
        task.setRemindBeforeMin(request.getRemindBeforeMin());
        task.setParentTaskId(request.getParentTaskId());
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
                    "您有一个新的待办任务：" + request.getTitle(),
                    request.getDescription(),
                    MsgType.TODO, savedTask.getId(), "TODO_TASK"
            );
        }

        return TodoTaskDTO.fromEntity(savedTask);
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
        return TodoTaskDTO.fromEntity(savedTask);
    }

    @Transactional
    public TodoItemDTO completeTodoItem(Long taskId, Long userId, TodoItemCompleteRequest request) {
        TodoItem item = todoItemRepository.findByTaskIdAndUserIdAndDeletedFalse(taskId, userId)
                .orElseThrow(() -> new BusinessException("Todo item not found"));

        TodoItemStatus newStatus = TodoItemStatus.valueOf(request.getStatus());
        item.setStatus(newStatus);
        item.setFeedback(request.getFeedback());
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
                "用户已完成任务：" + task.getTitle(),
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
                    "催办提醒：请尽快完成任务「" + task.getTitle() + "」",
                    request.getMessage(),
                    MsgType.URGE, taskId, "TODO_TASK"
            );
        }

        return TodoTaskDTO.fromEntity(savedTask);
    }

    public Page<TodoTaskDTO> getMyTodos(Long userId, String status, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<TodoTask> taskPage;
        if (status != null && !status.isEmpty()) {
            TodoStatus todoStatus = TodoStatus.valueOf(status);
            taskPage = todoTaskRepository.findByAssigneeIdAndStatusAndDeletedFalse(userId, todoStatus, pageable);
        } else {
            taskPage = todoTaskRepository.findByAssigneeIdAndDeletedFalse(userId, pageable);
        }
        return taskPage.map(TodoTaskDTO::fromEntity);
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
        return taskPage.map(TodoTaskDTO::fromEntity);
    }

    public TodoTaskDTO getTodoDetail(Long taskId) {
        TodoTask task = todoTaskRepository.findById(taskId)
                .orElseThrow(() -> new BusinessException("Task not found"));
        TodoTaskDTO dto = TodoTaskDTO.fromEntity(task);

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
                    "任务「" + task.getTitle() + "」已取消",
                    null,
                    MsgType.SYSTEM, taskId, "TODO_TASK"
            );
        }
    }
}
