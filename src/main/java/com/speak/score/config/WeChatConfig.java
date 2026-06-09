package com.speak.score.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Data
@Configuration
@ConfigurationProperties(prefix = "wechat.mini-app")
public class WeChatConfig {

    private String appId;
    private String appSecret;
    private String code2sessionUrl;
}
