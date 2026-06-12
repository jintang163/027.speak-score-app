package com.speak.score.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.speak.score.config.SpeechEvaluationConfig;
import com.speak.score.dto.SpeechScoreResult;
import com.speak.score.entity.MsgType;
import com.speak.score.entity.SpeechScoreDetail;
import com.speak.score.entity.TodoItem;
import com.speak.score.entity.TodoItemStatus;
import com.speak.score.repository.SpeechScoreDetailRepository;
import com.speak.score.repository.TodoItemRepository;
import lombok.extern.slf4j.Slf4j;
import org.apache.rocketmq.spring.annotation.RocketMQMessageListener;
import org.apache.rocketmq.spring.core.RocketMQListener;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;

@Slf4j
@Component
@ConditionalOnProperty(name = "rocketmq.name-server")
@RocketMQMessageListener(
        topic = "${rocketmq.todo-task-topic:todo-task-topic}",
        selectorExpression = "scoring || scoring_retry",
        consumerGroup = "speak-score-scoring-consumer"
)
public class ScoringConsumer implements RocketMQListener<Map<String, Object>> {

    @Autowired(required = false)
    private TodoItemRepository todoItemRepository;

    @Autowired(required = false)
    private SpeechEvaluationService speechEvaluationService;

    @Autowired(required = false)
    private SpeechScoreDetailRepository speechScoreDetailRepository;

    @Autowired(required = false)
    private RocketMQProducerService rocketMQProducerService;

    @Autowired(required = false)
    private StringRedisTemplate stringRedisTemplate;

    @Autowired(required = false)
    private NotificationService notificationService;

    @Autowired(required = false)
    private SpeechEvaluationConfig speechEvaluationConfig;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public void onMessage(Map<String, Object> message) {
        Long itemId = null;
        try {
            itemId = toLong(message.get("itemId"));
            Long taskId = toLong(message.get("taskId"));
            Long userId = toLong(message.get("userId"));
            String audioUrl = (String) message.get("audioUrl");
            String referenceText = (String) message.get("referenceText");
            Integer messageRetryCount = message.get("retryCount") != null ? toInt(message.get("retryCount")) : 0;

            log.info("Scoring request received: itemId={}, taskId={}, userId={}, retryCount={}", itemId, taskId, userId, messageRetryCount);

            if (todoItemRepository == null || speechEvaluationService == null) {
                log.warn("Required services not available for scoring, skipping: itemId={}", itemId);
                return;
            }

            if (!checkRateLimit()) {
                log.warn("Rate limit exceeded for scoring, sending retry: itemId={}", itemId);
                sendRetry(itemId, taskId, userId, audioUrl, referenceText, messageRetryCount);
                return;
            }

            TodoItem item = todoItemRepository.findById(itemId).orElse(null);
            if (item == null) {
                log.error("TodoItem not found: itemId={}", itemId);
                return;
            }

            SpeechScoreResult result = speechEvaluationService.evaluate(audioUrl, referenceText);

            if (result.isSuccess()) {
                handleScoringSuccess(item, result);
                sendScoreNotification(userId, itemId, taskId, result.getOverallScore());
            } else {
                log.warn("Scoring failed for itemId={}: {}", itemId, result.getErrorMessage());
                handleScoringFailure(item, itemId, taskId, userId, audioUrl, referenceText, messageRetryCount);
            }
        } catch (Exception e) {
            log.error("Failed to process scoring message: itemId={}", itemId, e);
            handleScoringException(itemId, message, e);
        }
    }

    private boolean checkRateLimit() {
        if (stringRedisTemplate == null || speechEvaluationConfig == null) {
            return true;
        }
        try {
            String key = speechEvaluationConfig.getRateLimitKeyPrefix() + System.currentTimeMillis() / 60000;
            Long count = stringRedisTemplate.opsForValue().increment(key);
            if (count != null && count == 1) {
                stringRedisTemplate.expire(key, 60, TimeUnit.SECONDS);
            }
            return count == null || count <= speechEvaluationConfig.getRateLimitPerMinute();
        } catch (Exception e) {
            log.warn("Rate limit check failed, allowing request", e);
            return true;
        }
    }

    private void handleScoringSuccess(TodoItem item, SpeechScoreResult result) throws JsonProcessingException {
        if (speechScoreDetailRepository != null) {
            SpeechScoreDetail detail = new SpeechScoreDetail();
            detail.setItemId(item.getId());
            detail.setOverallScore(result.getOverallScore());
            detail.setPronunciationScore(result.getPronunciationScore());
            detail.setFluencyScore(result.getFluencyScore());
            detail.setCompletenessScore(result.getCompletenessScore());
            detail.setAccuracyScore(result.getAccuracyScore());
            detail.setErrorWordsJson(objectMapper.writeValueAsString(result.getErrorWords()));
            detail.setScoredAt(LocalDateTime.now());
            detail.setScoringProvider(speechEvaluationService.getProvider());
            speechScoreDetailRepository.save(detail);
        }

        item.setScore(result.getOverallScore());
        item.setStatus(TodoItemStatus.COMPLETED);
        item.setRetryCount(item.getRetryCount() != null ? item.getRetryCount() + 1 : 1);
        todoItemRepository.save(item);

        log.info("Scoring success for itemId={}, score={}", item.getId(), result.getOverallScore());
    }

    private void handleScoringFailure(TodoItem item, Long itemId, Long taskId, Long userId,
                                       String audioUrl, String referenceText, int currentRetryCount) {
        int newRetryCount = (item.getRetryCount() != null ? item.getRetryCount() : 0) + 1;
        item.setRetryCount(newRetryCount);

        int maxRetry = speechEvaluationConfig != null ? speechEvaluationConfig.getMaxRetry() : 3;
        if (newRetryCount < maxRetry) {
            todoItemRepository.save(item);
            sendRetry(itemId, taskId, userId, audioUrl, referenceText, newRetryCount);
        } else {
            item.setStatus(TodoItemStatus.NEEDS_REVIEW);
            item.setNeedsManualReview(true);
            todoItemRepository.save(item);
            log.info("Max retry reached for itemId={}, marked as NEEDS_REVIEW", itemId);
        }
    }

    private void handleScoringException(Long itemId, Map<String, Object> message, Exception e) {
        if (itemId == null || todoItemRepository == null) {
            return;
        }
        try {
            TodoItem item = todoItemRepository.findById(itemId).orElse(null);
            if (item == null) {
                return;
            }
            Long taskId = toLong(message.get("taskId"));
            Long userId = toLong(message.get("userId"));
            String audioUrl = (String) message.get("audioUrl");
            String referenceText = (String) message.get("referenceText");
            Integer messageRetryCount = message.get("retryCount") != null ? toInt(message.get("retryCount")) : 0;
            handleScoringFailure(item, itemId, taskId, userId, audioUrl, referenceText, messageRetryCount);
        } catch (Exception ex) {
            log.error("Failed to handle scoring exception: itemId={}", itemId, ex);
        }
    }

    private void sendRetry(Long itemId, Long taskId, Long userId, String audioUrl, String referenceText, int retryCount) {
        if (rocketMQProducerService != null) {
            rocketMQProducerService.sendScoringRetryMessage(itemId, taskId, userId, audioUrl, referenceText, retryCount);
        }
    }

    private void sendScoreNotification(Long userId, Long itemId, Long taskId, Double score) {
        if (notificationService != null && userId != null) {
            try {
                String content = "作业已批改，得分：" + (score != null ? Math.round(score) : "N/A");
                Map<String, Object> extraData = new HashMap<>();
                extraData.put("score", score);
                extraData.put("itemId", itemId);
                notificationService.sendNotification(
                        null, userId,
                        "打卡评分完成",
                        content,
                        MsgType.SCORE,
                        taskId,
                        "TODO_TASK",
                        extraData
                );
            } catch (Exception e) {
                log.warn("Failed to send score notification for itemId={}", itemId, e);
            }
        }
    }

    private Long toLong(Object value) {
        if (value == null) return null;
        if (value instanceof Long) return (Long) value;
        if (value instanceof Number) return ((Number) value).longValue();
        return Long.parseLong(value.toString());
    }

    private Integer toInt(Object value) {
        if (value == null) return 0;
        if (value instanceof Integer) return (Integer) value;
        if (value instanceof Number) return ((Number) value).intValue();
        return Integer.parseInt(value.toString());
    }
}
