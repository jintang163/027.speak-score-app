package com.speak.score.dto;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import lombok.Data;

@Data
public class GradeCreateRequest {

    @NotBlank(message = "gradeName is required")
    private String gradeName;

    private String gradeCode;

    private Integer gradeLevel;

    @NotNull(message = "schoolId is required")
    private Long schoolId;
}
