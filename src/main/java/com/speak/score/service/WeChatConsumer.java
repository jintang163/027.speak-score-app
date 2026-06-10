package com.speak.score.service;

import com.speak.score.config.NotificationConfig;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.rocketmq.spring.annotation.RocketMQMessageListener;
import org.apache.rocketmq.spring.core.RocketMQListener;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;

@Slf4j
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(name = "rocketmq.name-server")
@RocketMQMessageListener(
        topic = "${rocketmq.todo-task-topic:todo-task-topic}",
        selectorExpression = "wechat",
        consumerGroup = "speak-score-wechat-consumer"
)
public class WeChatConsumer implements RocketMQListener<Map<String, Object>> {

    private final NotificationConfig notificationConfig;

    @Autowired(required = false)
    private WeChatSubscribeMessageService weChatSubscribeMessageService;

    @Override
    public void onMessage(Map<String, Object> message) {
        try {
            Long taskId = toLong(message.get("taskId"));
            String title = (String) message.get("title");
            String content = (String) message.get("content");
            @SuppressWarnings("unchecked")
            List<Long> receiverIds = (List<Long>) message.get("receiverIds");

            if (!notificationConfig.getWeChat().isEnabled()) {
                log.warn("WeChat notification is disabled, skipping");
                return;
            }

            if (weChatSubscribeMessageService == null) {
                log.warn("WeChatSubscribeMessageService not available, skipping for taskId={}", taskId);
                return;
            }

            String templateId = notificationConfig.getWeChat().getTemplateId();
            Map<String, String> data = weChatSubscribeMessageService
                    .buildTaskNotificationData(title, content, "请尽快完成");
            String page = "pages/task/detail?taskId=" + taskId;

            if (receiverIds != null && !receiverIds.isEmpty()) {
                weChatSubscribeMessageService.sendSubscribeMessageToUsers(receiverIds, templateId, data, page);
            } else {
                log.info("No receiverIds for wechat message taskId={}, skipping", taskId);
            }
        } catch (Exception e) {
            log.error("Failed to process WeChat subscribe message", e);
        }
    }

    private Long toLong(Object value) {
        if (value == null) return null;
        if (value instanceof Long) return (Long) value;
        if (value instanceof Number) return ((Number) value).longValue();
        return Long.parseLong(value.toString());
    }
}
