package com.speak.score.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ClassRankDTO {

    private Long classId;
    private String className;
    private String gradeName;
    private Double averageScore;
    private Integer rank;
    private Integer studentCount;
    private Integer completedTaskCount;
}
