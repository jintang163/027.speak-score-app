package com.speak.score.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.rocketmq.spring.annotation.RocketMQMessageListener;
import org.apache.rocketmq.spring.core.RocketMQListener;
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
        selectorExpression = "todo-task",
        consumerGroup = "speak-score-todo-consumer"
)
public class TodoTaskConsumer implements RocketMQListener<Map<String, Object>> {

    private final NotificationService notificationService;

    @Override
    public void onMessage(Map<String, Object> message) {
        try {
            Long taskId = toLong(message.get("taskId"));
            String title = (String) message.get("title");
            String action = (String) message.get("action");
            log.info("Received todo task message: taskId={}, action={}", taskId, action);
        } catch (Exception e) {
            log.error("Failed to process todo task message", e);
        }
    }

    private Long toLong(Object value) {
        if (value == null) return null;
        if (value instanceof Long) return (Long) value;
        if (value instanceof Number) return ((Number) value).longValue();
        return Long.parseLong(value.toString());
    }
}
