package com.speak.score.service;

import com.speak.score.config.NotificationConfig;
import com.speak.score.entity.NotifyChannel;
import com.speak.score.entity.NotifyMessage;
import com.speak.score.entity.SendStatus;
import com.speak.score.repository.NotifyMessageRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Map;

@Slf4j
@Component
public class NotificationRetryScheduler {

    private final NotificationConfig notificationConfig;
    private final NotifyMessageRepository notifyMessageRepository;

    @Autowired(required = false)
    private PushNotificationService pushNotificationService;

    @Autowired(required = false)
    private WeChatSubscribeMessageService weChatSubscribeMessageService;

    public NotificationRetryScheduler(NotificationConfig notificationConfig,
                                      NotifyMessageRepository notifyMessageRepository) {
        this.notificationConfig = notificationConfig;
        this.notifyMessageRepository = notifyMessageRepository;
    }

    @Scheduled(cron = "${notification.retry.cron}")
    @Transactional
    public void retryFailedNotifications() {
        NotificationConfig.Retry retryConfig = notificationConfig.getRetry();
        if (!retryConfig.isEnabled()) {
            return;
        }

        LocalDateTime now = LocalDateTime.now();
        List<NotifyMessage> messages = notifyMessageRepository
                .findBySendStatusInAndNextRetryAtBeforeAndDeletedFalse(
                        Arrays.asList(SendStatus.FAILED, SendStatus.RETRYING), now);

        if (messages.isEmpty()) {
            return;
        }

        int successCount = 0;
        int retryCount = 0;
        int failCount = 0;

        for (NotifyMessage message : messages) {
            boolean success = false;
            String errorMsg = null;

            try {
                success = retrySend(message);
            } catch (Exception e) {
                errorMsg = e.getMessage();
                log.error("Retry notification failed for id={}, channel={}",
                        message.getId(), message.getChannel(), e);
            }

            message.setRetryCount(message.getRetryCount() + 1);

            if (success) {
                message.setSendStatus(SendStatus.SENT);
                message.setSentAt(now);
                message.setLastError(null);
                message.setNextRetryAt(null);
                successCount++;
            } else {
                if (message.getRetryCount() < message.getMaxRetry()) {
                    message.setSendStatus(SendStatus.RETRYING);
                    long delayMinutes = calculateDelayMinutes(
                            retryConfig.getInitialDelayMinutes(),
                            retryConfig.getBackoffMultiplier(),
                            message.getRetryCount());
                    message.setNextRetryAt(now.plusMinutes(delayMinutes));
                    if (errorMsg != null) {
                        message.setLastError(errorMsg);
                    }
                    retryCount++;
                } else {
                    message.setSendStatus(SendStatus.FAILED);
                    message.setNextRetryAt(null);
                    if (errorMsg != null) {
                        message.setLastError(errorMsg);
                    }
                    failCount++;
                }
            }

            notifyMessageRepository.save(message);
        }

        log.info("Notification retry completed: total={}, success={}, retrying={}, failed={}",
                messages.size(), successCount, retryCount, failCount);
    }

    private boolean retrySend(NotifyMessage message) {
        NotifyChannel channel = message.getChannel();
        List<Long> userIds = Collections.singletonList(message.getReceiverId());

        if (channel == NotifyChannel.APP_PUSH) {
            if (pushNotificationService == null) {
                throw new RuntimeException("PushNotificationService is not available");
            }
            pushNotificationService.pushToUsers(userIds, message.getTitle(), message.getContent(), message.getRelatedId());
            return true;
        } else if (channel == NotifyChannel.WECHAT) {
            if (weChatSubscribeMessageService == null) {
                throw new RuntimeException("WeChatSubscribeMessageService is not available");
            }
            String templateId = getWeChatTemplateId(message);
            Map<String, String> data = weChatSubscribeMessageService.buildTaskNotificationData(
                    message.getTitle(), message.getContent(), "请打开App查看详情");
            String page = message.getRelatedId() != null ? "pages/todo/detail?id=" + message.getRelatedId() : null;
            weChatSubscribeMessageService.sendSubscribeMessageToUsers(userIds, templateId, data, page);
            return true;
        } else {
            throw new RuntimeException("Unsupported channel for retry: " + channel);
        }
    }

    private String getWeChatTemplateId(NotifyMessage message) {
        NotificationConfig.WeChat weChatConfig = notificationConfig.getWeChat();
        if (message.getMsgType() == null) {
            return weChatConfig.getTemplateId();
        }
        switch (message.getMsgType()) {
            case SCORE:
                return weChatConfig.getScoreTemplateId();
            case PARENT_REPORT:
            case WEEKLY_REPORT:
            case DAILY_REPORT:
                return weChatConfig.getReportTemplateId();
            case TODO:
            case REMINDER:
            case URGE:
            default:
                String taskTpl = weChatConfig.getTaskTemplateId();
                return taskTpl != null ? taskTpl : weChatConfig.getTemplateId();
        }
    }

    private long calculateDelayMinutes(int initialDelayMinutes, int backoffMultiplier, int retryCount) {
        return (long) (initialDelayMinutes * Math.pow(backoffMultiplier, retryCount));
    }
}
