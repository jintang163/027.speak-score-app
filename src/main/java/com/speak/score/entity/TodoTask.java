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
@Table(name = "todo_task")
public class TodoTask extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "title", nullable = false)
    private String title;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(name = "task_type", nullable = false, length = 20)
    private TodoTaskType taskType;

    @Enumerated(EnumType.STRING)
    @Column(name = "priority", nullable = false, length = 20)
    private TodoPriority priority = TodoPriority.NORMAL;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    private TodoStatus status = TodoStatus.PENDING;

    @Column(name = "creator_id")
    private Long creatorId;

    @Column(name = "assignee_id")
    private Long assigneeId;

    @Column(name = "assignee_type", length = 20)
    private String assigneeType = "USER";

    @Column(name = "assignee_class_id")
    private Long assigneeClassId;

    @Column(name = "assignee_school_id")
    private Long assigneeSchoolId;

    @Column(name = "deadline")
    private LocalDateTime deadline;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @Column(name = "urge_count", nullable = false)
    private Integer urgeCount = 0;

    @Column(name = "last_urge_at")
    private LocalDateTime lastUrgeAt;

    @Column(name = "remind_before_min", nullable = false)
    private Integer remindBeforeMin = 30;

    @Column(name = "remind_sent", nullable = false)
    private Boolean remindSent = false;

    @Column(name = "parent_task_id")
    private Long parentTaskId;

    @Column(name = "material_id")
    private Long materialId;

    @Column(name = "reference_text", columnDefinition = "TEXT")
    private String referenceText;
}
