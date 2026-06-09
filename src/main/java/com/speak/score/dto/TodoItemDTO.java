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
    private String completedAt;
    private String createdAt;

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
        dto.setCompletedAt(item.getCompletedAt() != null ? item.getCompletedAt().format(FORMATTER) : null);
        dto.setCreatedAt(item.getCreatedAt() != null ? item.getCreatedAt().format(FORMATTER) : null);
        return dto;
    }
}
