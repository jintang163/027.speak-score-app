package com.speak.score.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Data
@Component
@ConfigurationProperties(prefix = "speech.scoring")
public class SpeechEvaluationConfig {
    private String provider = "mock";
    private String tencentSecretId;
    private String tencentSecretKey;
    private String tencentRegion = "ap-beijing";
    private String iflytekAppId;
    private String iflytekSecretKey;
    private String iflytekApiUrl;
    private int maxRetry = 3;
    private long rateLimitPerMinute = 60;
    private String rateLimitKeyPrefix = "speech_rate_limit:";
    private String scoringCachePrefix = "speech_score:";
    private long cacheTtlMinutes = 60;
    private int connectTimeoutMs = 5000;
    private int readTimeoutMs = 30000;
}
