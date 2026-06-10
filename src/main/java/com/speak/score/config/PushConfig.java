package com.speak.score.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Data
@Configuration
@ConfigurationProperties(prefix = "push.getui")
public class PushConfig {

    private boolean enabled = false;
    private String appId;
    private String appKey;
    private String masterSecret;
    private String packageName;
}
