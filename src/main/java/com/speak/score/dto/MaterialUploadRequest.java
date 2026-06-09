package com.speak.score.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import javax.validation.constraints.NotBlank;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class MaterialUploadRequest {

    @NotBlank(message = "title is required")
    private String title;

    private String description;

    @NotBlank(message = "materialType is required")
    private String materialType;

    private List<Long> tagIds;

    private String scope = "SCHOOL";

    private Long schoolId;

    private Long classId;

    private Integer gradeLevel;
}
