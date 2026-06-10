package com.speak.score.service;

import com.speak.score.config.PushConfig;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
@ConditionalOnProperty(name = "push.getui.enabled", havingValue = "true")
public class PushNotificationService {

    private final PushConfig pushConfig;

    public void pushToUsers(List<String> clientIds, String title, String content, Long taskId) {
        if (!pushConfig.isEnabled()) {
            log.warn("Push notification is disabled");
            return;
        }
        try {
            log.info("Pushing notification to {} clients, title={}, taskId={}", clientIds.size(), title, taskId);
        } catch (Exception e) {
            log.error("Failed to push notification", e);
        }
    }

    public void pushToAll(String title, String content, Long taskId) {
        if (!pushConfig.isEnabled()) {
            log.warn("Push notification is disabled");
            return;
        }
        try {
            log.info("Pushing notification to all, title={}, taskId={}", title, taskId);
        } catch (Exception e) {
            log.error("Failed to push notification to all", e);
        }
    }
}
