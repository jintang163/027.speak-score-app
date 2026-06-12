package com.speak.score.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ParentStudentDTO {
    private Long id;
    private Long parentId;
    private String parentName;
    private String parentPhone;
    private Long studentId;
    private String studentName;
    private String studentPhone;
    private String relation;
    private Boolean isPrimary;
    private Integer status;
    private String className;
    private String schoolName;
}
