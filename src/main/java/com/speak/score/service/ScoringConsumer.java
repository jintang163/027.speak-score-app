package com.speak.score.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.rocketmq.spring.annotation.RocketMQMessageListener;
import org.apache.rocketmq.spring.core.RocketMQListener;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.util.Map;

@Slf4j
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(name = "rocketmq.name-server")
@RocketMQMessageListener(
        topic = "${rocketmq.todo-task-topic:todo-task-topic}",
        selectorExpression = "scoring",
        consumerGroup = "speak-score-scoring-consumer"
)
public class ScoringConsumer implements RocketMQListener<Map<String, Object>> {

    @Override
    public void onMessage(Map<String, Object> message) {
        try {
            Long itemId = toLong(message.get("itemId"));
            Long taskId = toLong(message.get("taskId"));
            Long userId = toLong(message.get("userId"));
            String audioUrl = (String) message.get("audioUrl");
            String referenceText = (String) message.get("referenceText");

            log.info("Scoring request received: itemId={}, taskId={}, userId={}, audioUrl={}", itemId, taskId, userId, audioUrl);
            log.info("Scoring request received, will integrate with speech scoring engine later");
        } catch (Exception e) {
            log.error("Failed to process scoring message", e);
        }
    }

    private Long toLong(Object value) {
        if (value == null) return null;
        if (value instanceof Long) return (Long) value;
        if (value instanceof Number) return ((Number) value).longValue();
        return Long.parseLong(value.toString());
    }
}
