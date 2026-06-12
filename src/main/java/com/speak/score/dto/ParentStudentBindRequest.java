package com.speak.score.dto;

import lombok.Data;

@Data
public class ParentStudentBindRequest {
    private Long studentId;
    private String relation;
    private Boolean isPrimary;
    private String studentName;
    private String studentPhone;
}
