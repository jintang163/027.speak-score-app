package com.speak.score.repository;

import com.speak.score.entity.TodoStatus;
import com.speak.score.entity.TodoTask;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface TodoTaskRepository extends JpaRepository<TodoTask, Long> {

    List<TodoTask> findByCreatorIdAndDeletedFalse(Long creatorId);

    List<TodoTask> findByAssigneeIdAndStatusAndDeletedFalse(Long assigneeId, TodoStatus status);

    Page<TodoTask> findByAssigneeIdAndDeletedFalse(Long assigneeId, Pageable pageable);

    Page<TodoTask> findByCreatorIdAndDeletedFalse(Long creatorId, Pageable pageable);

    List<TodoTask> findByStatusAndDeadlineBeforeAndRemindSentFalseAndDeletedFalse(TodoStatus status, LocalDateTime deadline);

    List<TodoTask> findByAssigneeClassIdAndDeletedFalse(Long classId);

    Page<TodoTask> findByAssigneeIdAndStatusAndDeletedFalse(Long assigneeId, TodoStatus status, Pageable pageable);

    Page<TodoTask> findByCreatorIdAndStatusAndDeletedFalse(Long creatorId, TodoStatus status, Pageable pageable);

    List<TodoTask> findByAssigneeSchoolIdAndDeletedFalse(Long schoolId);

    Page<TodoTask> findByAssigneeSchoolIdAndDeletedFalse(Long schoolId, Pageable pageable);

    Page<TodoTask> findByCreatorIdAndAssigneeClassIdAndDeletedFalse(Long creatorId, Long classId, Pageable pageable);
}
