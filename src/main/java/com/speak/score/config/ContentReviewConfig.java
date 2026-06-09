package com.speak.score.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Data
@Configuration
@ConfigurationProperties(prefix = "content-review")
public class ContentReviewConfig {

    private boolean enabled = true;
    private String provider = "aliyun";
    private String accessKeyId;
    private String accessKeySecret;
    private String endpoint;
}
