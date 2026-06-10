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
@Table(name = "todo_item")
public class TodoItem extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "task_id", nullable = false)
    private Long taskId;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    private TodoItemStatus status = TodoItemStatus.PENDING;

    @Column(name = "feedback", length = 500)
    private String feedback;

    @Column(name = "score")
    private Double score;

    @Column(name = "audio_url", length = 500)
    private String audioUrl;

    @Column(name = "duration")
    private Integer duration;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @Column(name = "teacher_score")
    private Double teacherScore;

    @Column(name = "teacher_feedback", length = 1000)
    private String teacherFeedback;

    @Column(name = "teacher_audio_url", length = 500)
    private String teacherAudioUrl;

    @Column(name = "teacher_id")
    private Long teacherId;

    @Column(name = "teacher_reviewed_at")
    private LocalDateTime teacherReviewedAt;

    @Column(name = "needs_manual_review")
    private Boolean needsManualReview = false;

    @Column(name = "retry_count")
    private Integer retryCount = 0;
}
