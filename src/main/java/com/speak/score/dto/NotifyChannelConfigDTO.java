package com.speak.score.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class NotifyChannelConfigDTO {

    private Long id;
    private Long userId;
    private String channel;
    private String channelValue;
    private Boolean enabled;
}
