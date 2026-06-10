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

    public void sendTodoTaskMessage(Long taskId, String title, String action) {
        String destination = rocketMQConfig.getTodoTaskTopic() + ":" + rocketMQConfig.getTodoTaskTag();
        Map<String, Object> message = new HashMap<>();
        message.put("taskId", taskId);
        message.put("title", title);
        message.put("action", action);
        message.put("timestamp", System.currentTimeMillis());
        try {
            rocketMQTemplate.convertAndSend(destination, message);
            log.info("Sent todo task message: taskId={}, action={}", taskId, action);
        } catch (Exception e) {
            log.error("Failed to send todo task message: taskId={}, action={}", taskId, action, e);
        }
    }

    public void sendPushMessage(Long taskId, String title, String content, java.util.List<Long> receiverIds) {
        String destination = rocketMQConfig.getTodoTaskTopic() + ":" + rocketMQConfig.getPushTag();
        Map<String, Object> message = new HashMap<>();
        message.put("taskId", taskId);
        message.put("title", title);
        message.put("content", content);
        message.put("receiverIds", receiverIds);
        message.put("timestamp", System.currentTimeMillis());
        try {
            rocketMQTemplate.convertAndSend(destination, message);
            log.info("Sent push message: taskId={}, receiverCount={}", taskId, receiverIds.size());
        } catch (Exception e) {
            log.error("Failed to send push message: taskId={}", taskId, e);
        }
    }

    public void sendWechatMessage(Long taskId, String title, String content, java.util.List<Long> receiverIds) {
        String destination = rocketMQConfig.getTodoTaskTopic() + ":" + rocketMQConfig.getWechatTag();
        Map<String, Object> message = new HashMap<>();
        message.put("taskId", taskId);
        message.put("title", title);
        message.put("content", content);
        message.put("receiverIds", receiverIds);
        message.put("timestamp", System.currentTimeMillis());
        try {
            rocketMQTemplate.convertAndSend(destination, message);
            log.info("Sent wechat message: taskId={}, receiverCount={}", taskId, receiverIds.size());
        } catch (Exception e) {
            log.error("Failed to send wechat message: taskId={}", taskId, e);
        }
    }

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
}
