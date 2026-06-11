package com.speak.score.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class RankingDTO {

    private String rankType;
    private String period;
    private Integer totalCount;
    private List<RankItemDTO> rankings;
    private RankItemDTO myRank;
}
