package com.speak.score.dto;

import com.speak.score.entity.WeComConfig;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.format.DateTimeFormatter;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class WeComConfigDTO {
    private Long id;
    private Long schoolId;
    private String schoolName;
    private String webhookUrl;
    private String secret;
    private String configName;
    private String reportType;
    private Boolean enabled;
    private String createdAt;

    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    public static WeComConfigDTO fromEntity(WeComConfig entity) {
        if (entity == null) return null;
        WeComConfigDTO dto = new WeComConfigDTO();
        dto.setId(entity.getId());
        dto.setSchoolId(entity.getSchoolId());
        dto.setWebhookUrl(entity.getWebhookUrl());
        dto.setSecret(entity.getSecret());
        dto.setConfigName(entity.getConfigName());
        dto.setReportType(entity.getReportType());
        dto.setEnabled(entity.getEnabled());
        dto.setCreatedAt(entity.getCreatedAt() != null ? entity.getCreatedAt().format(FORMATTER) : null);
        return dto;
    }
}
