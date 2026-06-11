package com.speak.score.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ClassComparisonDTO {

    private Long classId;
    private String className;
    private String gradeName;
    private Integer studentCount;
    private Double averageScore;
    private Double completionRate;
    private Integer totalTasks;
}
