package com.speak.score.dto;

import lombok.Data;

@Data
public class WeComConfigRequest {
    private Long schoolId;
    private String webhookUrl;
    private String secret;
    private String configName;
    private String reportType;
    private Boolean enabled;
}
