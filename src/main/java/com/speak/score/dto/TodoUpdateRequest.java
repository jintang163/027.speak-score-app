package com.speak.score.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class TodoUpdateRequest {

    private String title;

    private String description;

    private String priority;

    private String status;

    private LocalDateTime deadline;

    private Integer remindBeforeMin;
}
