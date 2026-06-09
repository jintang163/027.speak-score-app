package com.speak.score.dto;

import javax.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class WechatRegisterRequest {

    private String wechatCode;

    @NotBlank(message = "phone is required")
    private String phone;

    @NotBlank(message = "smsCode is required")
    private String smsCode;

    private String nickname;

    @NotBlank(message = "roleCode is required")
    private String roleCode;

    private Long schoolId;
    private Long classId;
    private String classCode;
}
