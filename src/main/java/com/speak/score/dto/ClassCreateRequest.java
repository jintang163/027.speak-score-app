package com.speak.score.dto;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import lombok.Data;

@Data
public class ClassCreateRequest {

    @NotBlank(message = "className is required")
    private String className;

    @NotNull(message = "gradeId is required")
    private Long gradeId;

    @NotNull(message = "schoolId is required")
    private Long schoolId;

    private Long teacherId;
    private String academicYear;
}
