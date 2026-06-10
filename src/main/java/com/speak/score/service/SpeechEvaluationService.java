package com.speak.score.service;

import com.speak.score.dto.SpeechScoreResult;

public interface SpeechEvaluationService {
    SpeechScoreResult evaluate(String audioUrl, String referenceText);
    String getProvider();
}
