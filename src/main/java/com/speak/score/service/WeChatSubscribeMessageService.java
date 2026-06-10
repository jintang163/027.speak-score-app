package com.speak.score.service;

import com.speak.score.config.WeChatConfig;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
@ConditionalOnProperty(name = "notification.wechat.enabled", havingValue = "true")
public class WeChatSubscribeMessageService {

    private final WeChatConfig weChatConfig;

    public void sendSubscribeMessage(String openid, String templateId, Map<String, String> data, String page) {
        try {
            log.info("Sending WeChat subscribe message to openid={}, templateId={}", openid, templateId);
        } catch (Exception e) {
            log.error("Failed to send WeChat subscribe message", e);
        }
    }

    public void sendBatchSubscribeMessage(java.util.List<String> openids, String templateId, Map<String, String> data, String page) {
        for (String openid : openids) {
            sendSubscribeMessage(openid, templateId, data, page);
        }
    }
}
