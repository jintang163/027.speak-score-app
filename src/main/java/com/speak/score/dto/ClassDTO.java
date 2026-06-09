package com.speak.score.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ClassDTO {

    private Long id;
    private String className;
    private String classCode;
    private Long gradeId;
    private String gradeName;
    private Long schoolId;
    private String schoolName;
    private Long teacherId;
    private String teacherName;
    private String academicYear;
    private Integer status;
    private Integer studentCount;
}
