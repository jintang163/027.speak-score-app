package com.speak.score.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class GradeDTO {

    private Long id;
    private String gradeName;
    private String gradeCode;
    private Integer gradeLevel;
    private Long schoolId;
    private String schoolName;
}
