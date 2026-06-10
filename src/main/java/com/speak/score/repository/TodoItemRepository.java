package com.speak.score.repository;

import com.speak.score.entity.TodoItem;
import com.speak.score.entity.TodoItemStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface TodoItemRepository extends JpaRepository<TodoItem, Long> {

    List<TodoItem> findByTaskIdAndDeletedFalse(Long taskId);

    List<TodoItem> findByUserIdAndStatusAndDeletedFalse(Long userId, TodoItemStatus status);

    Optional<TodoItem> findByTaskIdAndUserIdAndDeletedFalse(Long taskId, Long userId);

    long countByTaskIdAndStatusAndDeletedFalse(Long taskId, TodoItemStatus status);

    List<TodoItem> findByTaskIdAndStatusAndDeletedFalse(Long taskId, TodoItemStatus status);

    List<TodoItem> findByTaskIdInAndDeletedFalse(List<Long> taskIds);

    Double findAverageScoreByTaskIdAndStatusAndDeletedFalse(Long taskId, TodoItemStatus status);

    @Query("SELECT ti.taskId FROM TodoItem ti WHERE ti.userId = :userId AND ti.deleted = false")
    Page<Long> findTaskIdsByUserIdAndDeletedFalse(@Param("userId") Long userId, Pageable pageable);

    @Query("SELECT ti.taskId FROM TodoItem ti WHERE ti.userId = :userId AND ti.status = :status AND ti.deleted = false")
    Page<Long> findTaskIdsByUserIdAndStatusAndDeletedFalse(@Param("userId") Long userId, @Param("status") TodoItemStatus status, Pageable pageable);
}
