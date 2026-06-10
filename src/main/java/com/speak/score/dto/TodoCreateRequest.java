package com.speak.score.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class TodoCreateRequest {

    @NotBlank(message = "title is required")
    private String title;

    private String description;

    @NotBlank(message = "taskType is required")
    private String taskType;

    private String priority = "NORMAL";

    private Long assigneeId;

    private String assigneeType = "USER";

    private Long assigneeClassId;

    private Long assigneeSchoolId;

    @NotNull(message = "deadline is required")
    private LocalDateTime deadline;

    private Integer remindBeforeMin = 30;

    private Long parentTaskId;

    private Long materialId;

    private String referenceText;
}
