package com.speak.score.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SpeechScoreResult {
    private Double overallScore;
    private Double pronunciationScore;
    private Double fluencyScore;
    private Double completenessScore;
    private Double accuracyScore;
    private List<ErrorWord> errorWords;
    private boolean success;
    private String errorMessage;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ErrorWord {
        private String word;
        private Double score;
        private String errorType;
        private Integer startIndex;
        private Integer endIndex;
    }
}
