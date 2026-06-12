package com.speak.score.service;

import com.speak.score.config.RocketMQConfig;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.rocketmq.spring.core.RocketMQTemplate;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
@ConditionalOnProperty(name = "rocketmq.name-server")
public class RocketMQProducerService {

    private final RocketMQTemplate rocketMQTemplate;
    private final RocketMQConfig rocketMQConfig;

    public void sendScoringMessage(Long itemId, Long taskId, Long userId, String audioUrl, String referenceText) {
        String destination = rocketMQConfig.getTodoTaskTopic() + ":" + rocketMQConfig.getScoringTag();
        Map<String, Object> message = new HashMap<>();
        message.put("itemId", itemId);
        message.put("taskId", taskId);
        message.put("userId", userId);
        message.put("audioUrl", audioUrl);
        message.put("referenceText", referenceText);
        message.put("timestamp", System.currentTimeMillis());
        try {
            rocketMQTemplate.convertAndSend(destination, message);
            log.info("Sent scoring message: itemId={}, taskId={}, userId={}", itemId, taskId, userId);
        } catch (Exception e) {
            log.error("Failed to send scoring message: itemId={}, taskId={}", itemId, taskId, e);
        }
    }

    public void sendScoringRetryMessage(Long itemId, Long taskId, Long userId, String audioUrl, String referenceText, int retryCount) {
        String destination = rocketMQConfig.getTodoTaskTopic() + ":" + rocketMQConfig.getScoringRetryTag();
        Map<String, Object> message = new HashMap<>();
        message.put("itemId", itemId);
        message.put("taskId", taskId);
        message.put("userId", userId);
        message.put("audioUrl", audioUrl);
        message.put("referenceText", referenceText);
        message.put("retryCount", retryCount);
        message.put("timestamp", System.currentTimeMillis());
        try {
            rocketMQTemplate.syncSend(destination, message, 3000, 3);
            log.info("Sent scoring retry message: itemId={}, retryCount={}", itemId, retryCount);
        } catch (Exception e) {
            log.error("Failed to send scoring retry message: itemId={}, retryCount={}", itemId, retryCount, e);
        }
    }
}
