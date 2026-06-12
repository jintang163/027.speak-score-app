package com.speak.score.service;

import com.speak.score.config.NotificationConfig;
import com.speak.score.entity.MsgType;
import com.speak.score.entity.TodoItem;
import com.speak.score.entity.TodoItemStatus;
import com.speak.score.entity.TodoStatus;
import com.speak.score.entity.TodoTask;
import com.speak.score.repository.ParentStudentRepository;
import com.speak.score.repository.TodoItemRepository;
import com.speak.score.repository.TodoTaskRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
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
    private final ParentStudentRepository parentStudentRepository;

    @Scheduled(cron = "${notification.reminder.cron}")
    @Transactional
    public void checkTimeoutReminders() {
        int defaultAdvanceMinutes = notificationConfig.getReminder().getAdvanceMinutes();
        LocalDateTime now = LocalDateTime.now();

        List<TodoTask> allTasks = todoTaskRepository
                .findByStatusAndRemindSentFalseAndDeletedFalse(TodoStatus.PENDING);

        int reminderCount = 0;
        for (TodoTask task : allTasks) {
            if (task.getDeadline() == null) {
                continue;
            }

            int advanceMinutes = task.getRemindBeforeMin() != null && task.getRemindBeforeMin() > 0
                    ? task.getRemindBeforeMin()
                    : defaultAdvanceMinutes;

            LocalDateTime remindTime = now.plusMinutes(advanceMinutes);
            if (task.getDeadline().isAfter(remindTime)) {
                continue;
            }

            task.setRemindSent(true);
            todoTaskRepository.save(task);

            List<TodoItem> pendingItems =
                    todoItemRepository.findByTaskIdAndStatusAndDeletedFalse(task.getId(), TodoItemStatus.PENDING);

            String deadlineStr = task.getDeadline().format(FORMATTER);
            List<Long> allReceiverIds = new ArrayList<>();

            for (TodoItem item : pendingItems) {
                allReceiverIds.add(item.getUserId());
                parentStudentRepository.findByStudentIdAndDeletedFalse(item.getUserId())
                        .forEach(ps -> allReceiverIds.add(ps.getParentId()));
            }

            if (!allReceiverIds.isEmpty()) {
                notificationService.sendBatchNotification(
                        task.getCreatorId(), allReceiverIds,
                        "任务即将截止：请尽快完成「" + task.getTitle() + "」，截止时间：" + deadlineStr,
                        "距离截止时间还有约 " + advanceMinutes + " 分钟，请抓紧时间完成打卡。",
                        MsgType.REMINDER, task.getId(), "TODO_TASK"
                );
                reminderCount += allReceiverIds.size();
            }
        }

        log.info("Sent {} deadline reminders for {} tasks", reminderCount, allTasks.size());
    }
}
