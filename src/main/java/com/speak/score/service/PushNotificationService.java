package com.speak.score.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.speak.score.config.PushConfig;
import com.speak.score.entity.UserDevice;
import com.speak.score.repository.UserDeviceRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@ConditionalOnProperty(name = "push.getui.enabled", havingValue = "true")
public class PushNotificationService {

    private final PushConfig pushConfig;
    private final UserDeviceRepository userDeviceRepository;
    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    private volatile String authToken;
    private volatile long tokenExpireTime = 0;

    public void pushToUsers(List<Long> userIds, String title, String content, Long taskId) {
        if (!pushConfig.isEnabled()) {
            log.warn("Push notification is disabled");
            return;
        }
        try {
            List<UserDevice> devices = userDeviceRepository
                    .findByUserIdInAndDeviceTypeAndDeletedFalse(userIds, "GETUI");
            if (devices.isEmpty()) {
                log.warn("No Getui clientIds found for userIds: {}", userIds);
                return;
            }

            List<String> clientIds = devices.stream()
                    .map(UserDevice::getDeviceToken)
                    .distinct()
                    .collect(Collectors.toList());

            String token = ensureAuthToken();
            if (token == null) {
                log.error("Failed to get Getui auth token, aborting push");
                return;
            }

            doPushSingle(token, clientIds, title, content, taskId);
        } catch (Exception e) {
            log.error("Failed to push notification to users", e);
        }
    }

    public void pushToAll(String title, String content, Long taskId) {
        if (!pushConfig.isEnabled()) {
            log.warn("Push notification is disabled");
            return;
        }
        try {
            String token = ensureAuthToken();
            if (token == null) {
                log.error("Failed to get Getui auth token, aborting push");
                return;
            }

            doPushAll(token, title, content, taskId);
        } catch (Exception e) {
            log.error("Failed to push notification to all", e);
        }
    }

    private String ensureAuthToken() {
        if (authToken != null && System.currentTimeMillis() < tokenExpireTime) {
            return authToken;
        }
        return refreshAuthToken();
    }

    private String refreshAuthToken() {
        try {
            long timestamp = System.currentTimeMillis();
            String raw = pushConfig.getAppKey() + timestamp + pushConfig.getMasterSecret();
            String sign = sha256(raw);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            Map<String, Object> body = new HashMap<>();
            body.put("sign", sign);
            body.put("timestamp", timestamp);
            body.put("appkey", pushConfig.getAppKey());

            HttpEntity<Map<String, Object>> request = new HttpEntity<>(body, headers);
            ResponseEntity<String> response = restTemplate.exchange(
                    "https://restapi.getui.com/v2/" + pushConfig.getAppId() + "/auth",
                    HttpMethod.POST, request, String.class);

            JsonNode root = objectMapper.readTree(response.getBody());
            if ("0".equals(root.path("code").asText())) {
                authToken = root.path("data").path("token").asText();
                tokenExpireTime = System.currentTimeMillis() + 23 * 60 * 60 * 1000L;
                log.info("Getui auth token refreshed successfully");
                return authToken;
            } else {
                log.error("Getui auth failed: code={}, msg={}",
                        root.path("code").asText(), root.path("msg").asText());
                return null;
            }
        } catch (Exception e) {
            log.error("Failed to refresh Getui auth token", e);
            return null;
        }
    }

    private void doPushSingle(String token, List<String> clientIds, String title, String content, Long taskId) {
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("token", token);

            Map<String, Object> pushMessage = new HashMap<>();
            Map<String, Object> notification = new HashMap<>();
            notification.put("title", title);
            notification.put("body", content);
            notification.put("click_type", "intent");
            notification.put("intent", "speakscore://task/detail?taskId=" + taskId);
            pushMessage.put("notification", notification);

            Map<String, Object> audience = new HashMap<>();
            audience.put("cid", clientIds);
            pushMessage.put("audience", audience);

            Map<String, Object> request = new HashMap<>();
            request.put("request_id", UUID.randomUUID().toString());
            request.put("push_message", pushMessage);

            HttpEntity<Map<String, Object>> httpEntity = new HttpEntity<>(request, headers);
            ResponseEntity<String> response = restTemplate.exchange(
                    "https://restapi.getui.com/v2/" + pushConfig.getAppId() + "/push/single/cid",
                    HttpMethod.POST, httpEntity, String.class);

            JsonNode root = objectMapper.readTree(response.getBody());
            if ("0".equals(root.path("code").asText())) {
                log.info("Getui push success: taskId={}, clientCount={}", taskId, clientIds.size());
            } else {
                log.error("Getui push failed: code={}, msg={}",
                        root.path("code").asText(), root.path("msg").asText());
            }
        } catch (Exception e) {
            log.error("Failed to push via Getui single cid", e);
        }
    }

    private void doPushAll(String token, String title, String content, Long taskId) {
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("token", token);

            Map<String, Object> pushMessage = new HashMap<>();
            Map<String, Object> notification = new HashMap<>();
            notification.put("title", title);
            notification.put("body", content);
            notification.put("click_type", "intent");
            notification.put("intent", "speakscore://task/detail?taskId=" + taskId);
            pushMessage.put("notification", notification);

            Map<String, Object> request = new HashMap<>();
            request.put("request_id", UUID.randomUUID().toString());
            request.put("push_message", pushMessage);

            HttpEntity<Map<String, Object>> httpEntity = new HttpEntity<>(request, headers);
            ResponseEntity<String> response = restTemplate.exchange(
                    "https://restapi.getui.com/v2/" + pushConfig.getAppId() + "/push/all",
                    HttpMethod.POST, httpEntity, String.class);

            JsonNode root = objectMapper.readTree(response.getBody());
            if ("0".equals(root.path("code").asText())) {
                log.info("Getui push-all success: taskId={}", taskId);
            } else {
                log.error("Getui push-all failed: code={}, msg={}",
                        root.path("code").asText(), root.path("msg").asText());
            }
        } catch (Exception e) {
            log.error("Failed to push via Getui all", e);
        }
    }

    private String sha256(String input) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(input.getBytes(StandardCharsets.UTF_8));
            StringBuilder hexString = new StringBuilder();
            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) hexString.append('0');
                hexString.append(hex);
            }
            return hexString.toString();
        } catch (Exception e) {
            throw new RuntimeException("SHA-256 not available", e);
        }
    }
}
