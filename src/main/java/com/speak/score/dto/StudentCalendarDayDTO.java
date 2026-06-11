package com.speak.score.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class StudentCalendarDayDTO {

    private String date;
    private String status;
    private Double score;
    private Integer taskCount;
    private Integer completedCount;
    private Long itemId;
}
