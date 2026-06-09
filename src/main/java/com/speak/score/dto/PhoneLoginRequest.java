package com.speak.score.dto;

import javax.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class PhoneLoginRequest {

    @NotBlank(message = "phone is required")
    private String phone;

    @NotBlank(message = "code is required")
    private String code;
}
