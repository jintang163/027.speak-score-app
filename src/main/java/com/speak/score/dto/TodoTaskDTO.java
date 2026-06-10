package com.speak.score.dto;

import com.speak.score.entity.TodoTask;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.time.format.DateTimeFormatter;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class TodoTaskDTO {

    private Long id;
    private String title;
    private String description;
    private String taskType;
    private String priority;
    private String status;
    private Long creatorId;
    private String creatorName;
    private Long assigneeId;
    private String assigneeName;
    private String assigneeType;
    private Long assigneeClassId;
    private Long assigneeSchoolId;
    private String deadline;
    private String completedAt;
    private Integer urgeCount;
    private String lastUrgeAt;
    private Integer remindBeforeMin;
    private Boolean remindSent;
    private Long parentTaskId;
    private Long materialId;
    private String materialTitle;
    private String materialType;
    private String referenceText;
    private List<TodoItemDTO> items;
    private String createdAt;

    private Integer completedCount;
    private Integer pendingCount;
    private Double averageScore;

    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    public static TodoTaskDTO fromEntity(TodoTask t) {
        if (t == null) {
            return null;
        }
        TodoTaskDTO dto = new TodoTaskDTO();
        dto.setId(t.getId());
        dto.setTitle(t.getTitle());
        dto.setDescription(t.getDescription());
        dto.setTaskType(t.getTaskType() != null ? t.getTaskType().name() : null);
        dto.setPriority(t.getPriority() != null ? t.getPriority().name() : null);
        dto.setStatus(t.getStatus() != null ? t.getStatus().name() : null);
        dto.setCreatorId(t.getCreatorId());
        dto.setCreatorName(null);
        dto.setAssigneeId(t.getAssigneeId());
        dto.setAssigneeName(null);
        dto.setAssigneeType(t.getAssigneeType());
        dto.setAssigneeClassId(t.getAssigneeClassId());
        dto.setAssigneeSchoolId(t.getAssigneeSchoolId());
        dto.setDeadline(t.getDeadline() != null ? t.getDeadline().format(FORMATTER) : null);
        dto.setCompletedAt(t.getCompletedAt() != null ? t.getCompletedAt().format(FORMATTER) : null);
        dto.setUrgeCount(t.getUrgeCount());
        dto.setLastUrgeAt(t.getLastUrgeAt() != null ? t.getLastUrgeAt().format(FORMATTER) : null);
        dto.setRemindBeforeMin(t.getRemindBeforeMin());
        dto.setRemindSent(t.getRemindSent());
        dto.setParentTaskId(t.getParentTaskId());
        dto.setMaterialId(t.getMaterialId());
        dto.setMaterialTitle(null);
        dto.setMaterialType(null);
        dto.setReferenceText(t.getReferenceText());
        dto.setItems(Collections.<TodoItemDTO>emptyList());
        dto.setCreatedAt(t.getCreatedAt() != null ? t.getCreatedAt().format(FORMATTER) : null);
        dto.setCompletedCount(null);
        dto.setPendingCount(null);
        dto.setAverageScore(null);
        return dto;
    }
}
