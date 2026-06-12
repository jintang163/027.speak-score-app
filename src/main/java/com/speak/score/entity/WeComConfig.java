package com.speak.score.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.persistence.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "wecom_config")
public class WeComConfig extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "school_id", nullable = false)
    private Long schoolId;

    @Column(name = "webhook_url", nullable = false, length = 500)
    private String webhookUrl;

    @Column(name = "secret", length = 200)
    private String secret;

    @Column(name = "config_name", nullable = false, length = 100)
    private String configName;

    @Column(name = "report_type", nullable = false, length = 50)
    private String reportType = "DAILY";

    @Column(name = "enabled", nullable = false)
    private Boolean enabled = true;

    @Column(name = "created_by")
    private Long createdBy;
}
