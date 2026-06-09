package com.speak.score.dto;

import javax.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class JoinClassRequest {

    @NotBlank(message = "classCode is required")
    private String classCode;
}
