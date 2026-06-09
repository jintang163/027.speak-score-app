package com.speak.score.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import javax.validation.constraints.NotBlank;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class NotifyChannelConfigRequest {

    @NotBlank(message = "channel is required")
    private String channel;

    @NotBlank(message = "channelValue is required")
    private String channelValue;

    private Boolean enabled = true;
}
