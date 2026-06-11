package com.speak.score.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class StudentCalendarDTO {

    private Long studentId;
    private String studentName;
    private Integer totalDays;
    private Integer checkedDays;
    private Integer missedDays;
    private Integer highScoreDays;
    private Double averageScore;
    private Double completionRate;
    private List<StudentCalendarDayDTO> days;
}
