package com.speak.score.service;

import com.speak.score.config.SpeechEvaluationConfig;
import com.speak.score.dto.SpeechScoreResult;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;

@Slf4j
@Service
@RequiredArgsConstructor
@ConditionalOnProperty(name = "speech.scoring.provider", havingValue = "mock", matchIfMissing = true)
public class MockSpeechEvaluationService implements SpeechEvaluationService {

    private final SpeechEvaluationConfig config;
    private final Random random = new Random();

    @Override
    public SpeechScoreResult evaluate(String audioUrl, String referenceText) {
        log.info("Mock speech evaluation started: audioUrl={}, referenceText length={}", audioUrl,
                referenceText != null ? referenceText.length() : 0);

        try {
            Thread.sleep(200);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }

        double overallScore = 50 + random.nextDouble() * 50;
        double pronunciationScore = 50 + random.nextDouble() * 50;
        double fluencyScore = 50 + random.nextDouble() * 50;
        double completenessScore = 50 + random.nextDouble() * 50;
        double accuracyScore = 50 + random.nextDouble() * 50;

        List<SpeechScoreResult.ErrorWord> errorWords = new ArrayList<>();
        if (referenceText != null && !referenceText.trim().isEmpty()) {
            String[] words = referenceText.trim().split("\\s+");
            int errorWordCount = Math.min(words.length, 1 + random.nextInt(3));
            for (int i = 0; i < errorWordCount; i++) {
                int wordIndex = random.nextInt(words.length);
                String word = words[wordIndex];
                double wordScore = 30 + random.nextDouble() * 40;
                String[] errorTypes = {"mispronunciation", "omission", "insertion", "stress"};
                String errorType = errorTypes[random.nextInt(errorTypes.length)];
                int startIndex = referenceText.indexOf(word, wordIndex > 0 ? wordIndex : 0);
                if (startIndex < 0) {
                    startIndex = 0;
                }
                int endIndex = startIndex + word.length();

                SpeechScoreResult.ErrorWord errorWord = new SpeechScoreResult.ErrorWord();
                errorWord.setWord(word);
                errorWord.setScore(wordScore);
                errorWord.setErrorType(errorType);
                errorWord.setStartIndex(startIndex);
                errorWord.setEndIndex(endIndex);
                errorWords.add(errorWord);
            }
        }

        SpeechScoreResult result = new SpeechScoreResult();
        result.setOverallScore(Math.round(overallScore * 100.0) / 100.0);
        result.setPronunciationScore(Math.round(pronunciationScore * 100.0) / 100.0);
        result.setFluencyScore(Math.round(fluencyScore * 100.0) / 100.0);
        result.setCompletenessScore(Math.round(completenessScore * 100.0) / 100.0);
        result.setAccuracyScore(Math.round(accuracyScore * 100.0) / 100.0);
        result.setErrorWords(errorWords);
        result.setSuccess(true);

        log.info("Mock speech evaluation completed: overallScore={}", result.getOverallScore());
        return result;
    }

    @Override
    public String getProvider() {
        return config.getProvider();
    }
}
