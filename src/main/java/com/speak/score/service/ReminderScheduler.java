package com.speak.score.service;

import com.speak.score.config.NotificationConfig;
import com.speak.score.entity.MsgType;
import com.speak.score.entity.TodoItem;
import com.speak.score.entity.TodoItemStatus;
import com.speak.score.entity.TodoStatus;
import com.speak.score.entity.TodoTask;
import com.speak.score.repository.TodoItemRepository;
import com.speak.score.repository.TodoTaskRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Slf4j
@Component
@RequiredArgsConstructor
public class ReminderScheduler {

    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private final TodoTaskRepository todoTaskRepository;
    private final TodoItemRepository todoItemRepository;
    private final NotificationService notificationService;
    private final NotificationConfig notificationConfig;

    @Scheduled(cron = "${notification.reminder.cron}")
    @Transactional
    public void checkTimeoutReminders() {
        int advanceMinutes = notificationConfig.getReminder().getAdvanceMinutes();
        LocalDateTime remindTime = LocalDateTime.now().plusMinutes(advanceMinutes);

        List<TodoTask> tasks = todoTaskRepository
                .findByStatusAndDeadlineBeforeAndRemindSentFalseAndDeletedFalse(TodoStatus.PENDING, remindTime);

        int reminderCount = 0;
        for (TodoTask task : tasks) {
            task.setRemindSent(true);
            todoTaskRepository.save(task);

            List<TodoItem> pendingItems =
                    todoItemRepository.findByTaskIdAndStatusAndDeletedFalse(task.getId(), TodoItemStatus.PENDING);

            String deadlineStr = task.getDeadline() != null ? task.getDeadline().format(FORMATTER) : "无";
            for (TodoItem item : pendingItems) {
                notificationService.sendNotification(
                        task.getCreatorId(), item.getUserId(),
                        "任务即将超时：请尽快完成「" + task.getTitle() + "」，截止时间：" + deadlineStr,
                        null,
                        MsgType.REMINDER, task.getId(), "TODO_TASK"
                );
                reminderCount++;
            }
        }

        log.info("Sent {} timeout reminders for {} tasks", reminderCount, tasks.size());
    }
}
