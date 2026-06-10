package com.speak.score.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.persistence.*;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "speech_score_detail")
public class SpeechScoreDetail extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "item_id", nullable = false)
    private Long itemId;

    @Column(name = "overall_score")
    private Double overallScore;

    @Column(name = "pronunciation_score")
    private Double pronunciationScore;

    @Column(name = "fluency_score")
    private Double fluencyScore;

    @Column(name = "completeness_score")
    private Double completenessScore;

    @Column(name = "accuracy_score")
    private Double accuracyScore;

    @Column(name = "error_words_json", columnDefinition = "TEXT")
    private String errorWordsJson;

    @Column(name = "scored_at")
    private LocalDateTime scoredAt;

    @Column(name = "scoring_provider", length = 20)
    private String scoringProvider;
}
