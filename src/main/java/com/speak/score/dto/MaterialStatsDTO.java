package com.speak.score.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class MaterialStatsDTO {
    private String materialType;
    private Long count;
    private Long totalSize;
}
