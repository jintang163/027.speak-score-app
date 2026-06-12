package com.speak.score.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.speak.score.config.NotificationConfig;
import com.speak.score.entity.WeComConfig;
import com.speak.score.repository.WeComConfigRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.*;

@Slf4j
@Service
@RequiredArgsConstructor
@ConditionalOnProperty(name = "notification.wecom.enabled", havingValue = "true")
public class WeComBotService {

    private final WeComConfigRepository weComConfigRepository;
    private final NotificationConfig notificationConfig;
    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    public void sendTextToSchoolBySchoolId(Long schoolId, String content) {
        List<WeComConfig> configs = weComConfigRepository
                .findBySchoolIdAndReportTypeAndEnabledTrueAndDeletedFalse(schoolId, "DAILY");
        for (WeComConfig config : configs) {
            sendText(config, content);
        }
    }

    public void sendMarkdownToSchool(Long schoolId, String reportType, String markdownContent) {
        List<WeComConfig> configs = weComConfigRepository
                .findBySchoolIdAndReportTypeAndEnabledTrueAndDeletedFalse(schoolId, reportType);
        for (WeComConfig config : configs) {
            sendMarkdown(config, markdownContent);
        }
    }

    public void sendText(WeComConfig config, String content) {
        try {
            Map<String, Object> body = new HashMap<>();
            body.put("msgtype", "text");
            Map<String, String> text = new HashMap<>();
            text.put("content", content);
            body.put("text", text);

            String webhookUrl = buildWebhookUrl(config);
            doPost(webhookUrl, body);
            log.info("WeCom text message sent to config: {}", config.getConfigName());
        } catch (Exception e) {
            log.error("Failed to send WeCom text message to config: {}", config.getConfigName(), e);
        }
    }

    public void sendMarkdown(WeComConfig config, String content) {
        try {
            Map<String, Object> body = new HashMap<>();
            body.put("msgtype", "markdown");
            Map<String, String> markdown = new HashMap<>();
            markdown.put("content", content);
            body.put("markdown", markdown);

            String webhookUrl = buildWebhookUrl(config);
            doPost(webhookUrl, body);
            log.info("WeCom markdown message sent to config: {}", config.getConfigName());
        } catch (Exception e) {
            log.error("Failed to send WeCom markdown message to config: {}", config.getConfigName(), e);
        }
    }

    public void sendNews(WeComConfig config, String title, String description, String url, String picUrl) {
        try {
            Map<String, Object> body = new HashMap<>();
            body.put("msgtype", "news");

            Map<String, Object> news = new HashMap<>();
            List<Map<String, String>> articles = new ArrayList<>();

            Map<String, String> article = new HashMap<>();
            article.put("title", title);
            article.put("description", description);
            article.put("url", url);
            article.put("picurl", picUrl);
            articles.add(article);
            news.put("articles", articles);
            body.put("news", news);

            String webhookUrl = buildWebhookUrl(config);
            doPost(webhookUrl, body);
            log.info("WeCom news message sent to config: {}", config.getConfigName());
        } catch (Exception e) {
            log.error("Failed to send WeCom news message to config: {}", config.getConfigName(), e);
        }
    }

    private String buildWebhookUrl(WeComConfig config) {
        String url = config.getWebhookUrl();
        if (config.getSecret() != null && !config.getSecret().isEmpty()) {
            try {
                long timestamp = System.currentTimeMillis() / 1000;
                String sign = generateSign(timestamp, config.getSecret());
                url = url + "&timestamp=" + timestamp + "&sign=" + sign;
            } catch (Exception e) {
                log.warn("Failed to generate WeCom sign", e);
            }
        }
        return url;
    }

    private String generateSign(long timestamp, String secret) throws Exception {
        String stringToSign = timestamp + "\n" + secret;
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
        byte[] signData = mac.doFinal(stringToSign.getBytes(StandardCharsets.UTF_8));
        return URLEncoder.encode(Base64.getEncoder().encodeToString(signData), StandardCharsets.UTF_8);
    }

    private void doPost(String url, Map<String, Object> body) {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<Map<String, Object>> request = new HttpEntity<>(body, headers);
        ResponseEntity<String> response = restTemplate.exchange(
                url, HttpMethod.POST, request, String.class);
        log.debug("WeCom response: {}", response.getBody());
    }
}
