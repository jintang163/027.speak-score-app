package com.speak.score.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ClassReportDTO {

    private Long classId;
    private String className;
    private Integer totalStudents;
    private Integer totalTasks;
    private Integer completedTasks;
    private Double averageScore;
    private Double completionRate;
    private List<ScoreDistributionDTO> scoreDistribution;
}
