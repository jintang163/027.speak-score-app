package com.speak.score.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SchoolTaskStatsDTO {

    private Long schoolId;
    private String schoolName;
    private Long totalTasks;
    private Long activeTasks;
    private Long completedTasks;
    private Long totalCheckins;
    private Double averageScore;
    private Double completionRate;
}
