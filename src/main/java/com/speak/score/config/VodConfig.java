package com.speak.score.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Data
@Configuration
@ConfigurationProperties(prefix = "vod")
public class VodConfig {

    private String regionId;
    private String accessKeyId;
    private String accessKeySecret;
    private String templateGroupId;
    private String storageLocation;
}
