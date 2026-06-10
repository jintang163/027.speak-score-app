package com.speak.score.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class TodoTaskProgressDTO {

    private Long taskId;
    private String title;
    private String taskType;
    private String status;
    private String deadline;
    private Integer totalStudents;
    private Integer completedCount;
    private Integer pendingCount;
    private Double averageScore;
    private Double completionRate;
}
