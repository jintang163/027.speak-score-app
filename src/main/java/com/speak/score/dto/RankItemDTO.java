package com.speak.score.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class RankItemDTO {

    private Long userId;
    private String userName;
    private String avatar;
    private Double score;
    private Integer rank;
    private Integer taskCount;
    private Double averageScore;

    private List<Double> recentScores;
}
