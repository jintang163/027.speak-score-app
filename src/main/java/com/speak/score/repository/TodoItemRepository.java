package com.speak.score.repository;

import com.speak.score.entity.TodoItem;
import com.speak.score.entity.TodoItemStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
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

    Optional<TodoItem> findByTaskIdAndUserIdAndStatusAndDeletedFalse(Long taskId, Long userId, TodoItemStatus status);

    List<TodoItem> findByUserIdAndDeletedFalseOrderByCompletedAtDesc(Long userId);

    @Query("SELECT ti FROM TodoItem ti WHERE ti.userId = :userId AND ti.completedAt IS NOT NULL " +
            "AND ti.completedAt >= :startTime AND ti.completedAt <= :endTime AND ti.deleted = false " +
            "ORDER BY ti.completedAt ASC")
    List<TodoItem> findByUserIdAndCompletedAtBetweenAndDeletedFalse(
            @Param("userId") Long userId,
            @Param("startTime") LocalDateTime startTime,
            @Param("endTime") LocalDateTime endTime);

    @Query("SELECT ti FROM TodoItem ti WHERE ti.taskId IN :taskIds AND ti.status = :status AND ti.deleted = false")
    List<TodoItem> findByTaskIdInAndStatusAndDeletedFalse(
            @Param("taskIds") List<Long> taskIds,
            @Param("status") TodoItemStatus status);

    @Query("SELECT COUNT(DISTINCT ti.userId) FROM TodoItem ti WHERE ti.taskId IN :taskIds AND ti.status = :status AND ti.deleted = false")
    long countDistinctUserIdByTaskIdInAndStatusAndDeletedFalse(
            @Param("taskIds") List<Long> taskIds,
            @Param("status") TodoItemStatus status);

    @Query("SELECT AVG(ti.score) FROM TodoItem ti WHERE ti.taskId IN :taskIds AND ti.status = :status " +
            "AND ti.score IS NOT NULL AND ti.deleted = false")
    Double findAverageScoreByTaskIdInAndStatusAndDeletedFalse(
            @Param("taskIds") List<Long> taskIds,
            @Param("status") TodoItemStatus status);

    @Query("SELECT MAX(ti.score) FROM TodoItem ti WHERE ti.taskId IN :taskIds AND ti.status = :status " +
            "AND ti.score IS NOT NULL AND ti.deleted = false")
    Double findMaxScoreByTaskIdInAndStatusAndDeletedFalse(
            @Param("taskIds") List<Long> taskIds,
            @Param("status") TodoItemStatus status);

    @Query("SELECT MIN(ti.score) FROM TodoItem ti WHERE ti.taskId IN :taskIds AND ti.status = :status " +
            "AND ti.score IS NOT NULL AND ti.deleted = false")
    Double findMinScoreByTaskIdInAndStatusAndDeletedFalse(
            @Param("taskIds") List<Long> taskIds,
            @Param("status") TodoItemStatus status);

    @Query("SELECT ti.userId, AVG(ti.score) FROM TodoItem ti WHERE ti.taskId IN :taskIds " +
            "AND ti.status = :status AND ti.score IS NOT NULL AND ti.deleted = false " +
            "GROUP BY ti.userId")
    List<Object[]> findAverageScoreByTaskIdInAndStatusGroupByUserId(
            @Param("taskIds") List<Long> taskIds,
            @Param("status") TodoItemStatus status);

    @Query("SELECT ti.userId, ti.score, ti.completedAt FROM TodoItem ti " +
            "WHERE ti.userId = :userId AND ti.status = :status AND ti.score IS NOT NULL " +
            "AND ti.completedAt IS NOT NULL AND ti.deleted = false " +
            "ORDER BY ti.completedAt ASC")
    List<Object[]> findScoreHistoryByUserIdAndStatus(
            @Param("userId") Long userId,
            @Param("status") TodoItemStatus status);

    @Query("SELECT ti.userId, AVG(ti.score), MAX(ti.score), MIN(ti.score), COUNT(ti) " +
            "FROM TodoItem ti WHERE ti.taskId IN :taskIds AND ti.status = :status " +
            "AND ti.deleted = false GROUP BY ti.userId")
    List<Object[]> findStudentStatsByTaskIdInAndStatus(
            @Param("taskIds") List<Long> taskIds,
            @Param("status") TodoItemStatus status);

    @Query("SELECT COUNT(DISTINCT ti.userId) FROM TodoItem ti " +
            "WHERE ti.taskId IN :taskIds AND ti.deleted = false")
    long countDistinctUsersByTaskIdIn(@Param("taskIds") List<Long> taskIds);

    @Query("SELECT ti FROM TodoItem ti WHERE ti.taskId IN :taskIds " +
            "AND ti.completedAt IS NOT NULL AND ti.completedAt >= :startTime " +
            "AND ti.completedAt <= :endTime AND ti.deleted = false")
    List<TodoItem> findByTaskIdInAndCompletedAtBetweenAndDeletedFalse(
            @Param("taskIds") List<Long> taskIds,
            @Param("startTime") LocalDateTime startTime,
            @Param("endTime") LocalDateTime endTime);

    @Query("SELECT ti FROM TodoItem ti WHERE ti.taskId IN :taskIds " +
            "AND ti.createdAt >= :startTime AND ti.createdAt <= :endTime " +
            "AND ti.deleted = false")
    List<TodoItem> findByTaskIdInAndCreatedAtBetweenAndDeletedFalse(
            @Param("taskIds") List<Long> taskIds,
            @Param("startTime") LocalDateTime startTime,
            @Param("endTime") LocalDateTime endTime);
}
