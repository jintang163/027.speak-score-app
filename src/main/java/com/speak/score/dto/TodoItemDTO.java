package com.speak.score.dto;

import com.speak.score.entity.TodoItem;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.time.format.DateTimeFormatter;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class TodoItemDTO {

    private Long id;
    private Long taskId;
    private Long userId;
    private String userName;
    private String status;
    private String feedback;
    private Double score;
    private String audioUrl;
    private Integer duration;
    private String completedAt;
    private String createdAt;
    private Double teacherScore;
    private String teacherFeedback;
    private String teacherAudioUrl;
    private String teacherName;
    private String teacherReviewedAt;
    private Boolean needsManualReview;
    private Integer retryCount;

    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    public static TodoItemDTO fromEntity(TodoItem item) {
        if (item == null) {
            return null;
        }
        TodoItemDTO dto = new TodoItemDTO();
        dto.setId(item.getId());
        dto.setTaskId(item.getTaskId());
        dto.setUserId(item.getUserId());
        dto.setUserName(null);
        dto.setStatus(item.getStatus() != null ? item.getStatus().name() : null);
        dto.setFeedback(item.getFeedback());
        dto.setScore(item.getScore());
        dto.setAudioUrl(item.getAudioUrl());
        dto.setDuration(item.getDuration());
        dto.setCompletedAt(item.getCompletedAt() != null ? item.getCompletedAt().format(FORMATTER) : null);
        dto.setCreatedAt(item.getCreatedAt() != null ? item.getCreatedAt().format(FORMATTER) : null);
        dto.setTeacherScore(item.getTeacherScore());
        dto.setTeacherFeedback(item.getTeacherFeedback());
        dto.setTeacherAudioUrl(item.getTeacherAudioUrl());
        dto.setTeacherName(null);
        dto.setTeacherReviewedAt(item.getTeacherReviewedAt() != null ? item.getTeacherReviewedAt().format(FORMATTER) : null);
        dto.setNeedsManualReview(item.getNeedsManualReview());
        dto.setRetryCount(item.getRetryCount());
        return dto;
    }
}
