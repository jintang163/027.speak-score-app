package com.speak.score.dto;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import lombok.Data;

@Data
public class RegisterRequest {

    @NotBlank(message = "phone is required")
    private String phone;

    @NotBlank(message = "code is required")
    private String code;

    @NotBlank(message = "nickname is required")
    private String nickname;

    private String realName;

    @NotNull(message = "roleCode is required")
    private String roleCode;

    private Long schoolId;

    private Long gradeId;

    private Long classId;

    private String classCode;
}
