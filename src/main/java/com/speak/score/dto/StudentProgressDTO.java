package com.speak.score.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class StudentProgressDTO {

    private String date;
    private Double averageScore;
    private Integer taskCount;
    private Integer completedCount;
}
