package com.speak.score.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class MaterialSearchRequest {

    private String keyword;
    private String materialType;
    private Long tagId;
    private Long schoolId;
    private Long classId;
    private Integer gradeLevel;
    private String scope;
    private String reviewStatus;
    private int page = 0;
    private int size = 20;
}
