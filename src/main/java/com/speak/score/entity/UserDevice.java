package com.speak.score.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.persistence.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "user_device", uniqueConstraints = {
        @UniqueConstraint(columnNames = {"user_id", "device_type"})
})
public class UserDevice extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "device_type", nullable = false, length = 20)
    private String deviceType;

    @Column(name = "device_token", nullable = false, length = 200)
    private String deviceToken;

    @Column(name = "platform", length = 20)
    private String platform;

    @Column(name = "bundle_id", length = 100)
    private String bundleId;
}
