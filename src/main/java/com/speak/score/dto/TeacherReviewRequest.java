package com.speak.score.dto;

import lombok.Data;

import javax.validation.constraints.Max;
import javax.validation.constraints.Min;

@Data
public class TeacherReviewRequest {
    @Min(0)
    @Max(100)
    private Double score;
    private String feedback;
}
