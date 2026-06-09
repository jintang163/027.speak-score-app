package com.speak.score.dto;

import javax.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class SmsCodeRequest {

    @NotBlank(message = "phone is required")
    private String phone;
}
