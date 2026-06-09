package com.speak.score.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.persistence.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "notify_channel_config")
public class NotifyChannelConfig extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Enumerated(EnumType.STRING)
    @Column(name = "channel", nullable = false, length = 20)
    private NotifyChannel channel;

    @Column(name = "channel_value", length = 200)
    private String channelValue;

    @Column(name = "enabled", nullable = false)
    private Boolean enabled = true;
}
