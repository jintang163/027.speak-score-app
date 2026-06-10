package com.speak.score.service;

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
        selectorExpression = "push",
        consumerGroup = "speak-score-push-consumer"
)
public class PushConsumer implements RocketMQListener<Map<String, Object>> {

    @Autowired(required = false)
    private PushNotificationService pushNotificationService;

    @Override
    public void onMessage(Map<String, Object> message) {
        try {
            Long taskId = toLong(message.get("taskId"));
            String title = (String) message.get("title");
            String content = (String) message.get("content");
            @SuppressWarnings("unchecked")
            List<Long> receiverIds = (List<Long>) message.get("receiverIds");

            if (pushNotificationService == null) {
                log.warn("PushNotificationService not available, skipping push for taskId={}", taskId);
                return;
            }

            if (receiverIds == null || receiverIds.isEmpty()) {
                pushNotificationService.pushToAll(title, content, taskId);
            } else {
                pushNotificationService.pushToUsers(receiverIds, title, content, taskId);
            }
        } catch (Exception e) {
            log.error("Failed to process push notification", e);
        }
    }

    private Long toLong(Object value) {
        if (value == null) return null;
        if (value instanceof Long) return (Long) value;
        if (value instanceof Number) return ((Number) value).longValue();
        return Long.parseLong(value.toString());
    }
}
