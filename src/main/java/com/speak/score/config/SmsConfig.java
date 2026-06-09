package com.speak.score.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Data
@Configuration
@ConfigurationProperties(prefix = "sms")
public class SmsConfig {

    private String provider;
    private String accessKey;
    private String accessSecret;
    private String signName;
    private String templateCode;
}
