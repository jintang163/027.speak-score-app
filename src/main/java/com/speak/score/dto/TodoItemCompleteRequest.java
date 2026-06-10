package com.speak.score.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class TodoItemCompleteRequest {

    private String feedback;
    private Double score;
    private String status = "COMPLETED";
}
