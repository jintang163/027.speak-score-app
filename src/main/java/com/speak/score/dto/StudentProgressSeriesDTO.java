package com.speak.score.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class StudentProgressSeriesDTO {

    private Long studentId;
    private String studentName;
    private List<StudentProgressDTO> progress;
}
