package com.speak.score.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class MaterialUpdateRequest {

    private String title;
    private String description;
    private List<Long> tagIds;
    private String scope;
    private Integer gradeLevel;
}
