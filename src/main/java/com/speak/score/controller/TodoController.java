package com.speak.score.controller;

import com.speak.score.dto.*;
import com.speak.score.service.TodoService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import javax.validation.Valid;
import java.util.List;

@RestController
@RequestMapping("/todos")
@RequiredArgsConstructor
public class TodoController {

    private final TodoService todoService;

    @PostMapping
    @PreAuthorize("hasAnyRole('TEACHER', 'EDU_OFFICE')")
    public ApiResponse<TodoTaskDTO> createTodo(
            @Valid @RequestBody TodoCreateRequest request,
            Authentication auth) {
        Long userId = (Long) auth.getPrincipal();
        return ApiResponse.success(todoService.createTodo(userId, request));
    }

    @PutMapping("/{id}")
    public ApiResponse<TodoTaskDTO> updateTodo(
            @PathVariable("id") Long taskId,
            @RequestBody TodoUpdateRequest request,
            Authentication auth) {
        Long userId = (Long) auth.getPrincipal();
        return ApiResponse.success(todoService.updateTodo(taskId, userId, request));
    }

    @PostMapping("/{id}/copy")
    @PreAuthorize("hasAnyRole('TEACHER', 'EDU_OFFICE')")
    public ApiResponse<TodoTaskDTO> copyTodo(
            @PathVariable("id") Long taskId,
            Authentication auth) {
        Long userId = (Long) auth.getPrincipal();
        return ApiResponse.success(todoService.copyTask(taskId, userId));
    }

    @PostMapping("/{id}/urge")
    @PreAuthorize("hasAnyRole('TEACHER', 'EDU_OFFICE')")
    public ApiResponse<TodoTaskDTO> urgeTodo(
            @PathVariable("id") Long taskId,
            @RequestBody UrgeRequest request,
            Authentication auth) {
        Long userId = (Long) auth.getPrincipal();
        return ApiResponse.success(todoService.urgeTodo(taskId, userId, request));
    }

    @PostMapping("/{id}/complete")
    public ApiResponse<TodoItemDTO> completeTodoItem(
            @PathVariable("id") Long taskId,
            @RequestBody TodoItemCompleteRequest request,
            Authentication auth) {
        Long userId = (Long) auth.getPrincipal();
        return ApiResponse.success(todoService.completeTodoItem(taskId, userId, request));
    }

    @PostMapping("/{id}/checkin")
    public ApiResponse<TodoItemDTO> checkin(
            @PathVariable("id") Long taskId,
            @RequestParam("audioFile") MultipartFile audioFile,
            @RequestParam(value = "duration", required = false) Integer duration,
            Authentication auth) {
        Long userId = (Long) auth.getPrincipal();
        return ApiResponse.success(todoService.submitCheckin(taskId, userId, audioFile, duration));
    }

    @GetMapping("/my")
    public ApiResponse<Page<TodoTaskDTO>> getMyTodos(
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            Authentication auth) {
        Long userId = (Long) auth.getPrincipal();
        return ApiResponse.success(todoService.getMyTodos(userId, status, page, size));
    }

    @GetMapping("/created")
    @PreAuthorize("hasAnyRole('TEACHER', 'EDU_OFFICE')")
    public ApiResponse<Page<TodoTaskDTO>> getCreatedTodos(
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            Authentication auth) {
        Long userId = (Long) auth.getPrincipal();
        return ApiResponse.success(todoService.getCreatedTodos(userId, status, page, size));
    }

    @GetMapping("/{id}")
    public ApiResponse<TodoTaskDTO> getTodoDetail(
            @PathVariable("id") Long taskId,
            Authentication auth) {
        return ApiResponse.success(todoService.getTodoDetail(taskId));
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> cancelTodo(
            @PathVariable("id") Long taskId,
            Authentication auth) {
        Long userId = (Long) auth.getPrincipal();
        todoService.cancelTodo(taskId, userId);
        return ApiResponse.success();
    }

    @GetMapping("/{id}/progress")
    @PreAuthorize("hasAnyRole('TEACHER', 'EDU_OFFICE')")
    public ApiResponse<TodoTaskProgressDTO> getTaskProgress(
            @PathVariable("id") Long taskId,
            Authentication auth) {
        return ApiResponse.success(todoService.getTaskProgress(taskId));
    }

    @GetMapping("/class-progress")
    @PreAuthorize("hasAnyRole('TEACHER', 'EDU_OFFICE')")
    public ApiResponse<List<TodoTaskProgressDTO>> getTaskProgressByClass(
            @RequestParam(required = false) Long classId,
            Authentication auth) {
        Long userId = (Long) auth.getPrincipal();
        return ApiResponse.success(todoService.getTaskProgressByClass(userId, classId));
    }

    @GetMapping("/school-stats/{schoolId}")
    @PreAuthorize("hasRole('EDU_OFFICE')")
    public ApiResponse<SchoolTaskStatsDTO> getSchoolTaskStats(
            @PathVariable Long schoolId,
            Authentication auth) {
        return ApiResponse.success(todoService.getSchoolTaskStats(schoolId));
    }

    @PostMapping("/item/{itemId}/review")
    @PreAuthorize("hasAnyRole('TEACHER', 'EDU_OFFICE')")
    public ApiResponse<TodoItemDTO> teacherReview(
            @PathVariable("itemId") Long itemId,
            @RequestParam(required = false) Double score,
            @RequestParam(required = false) String feedback,
            @RequestParam(value = "audioFile", required = false) MultipartFile audioFile,
            Authentication auth) {
        Long teacherId = (Long) auth.getPrincipal();
        return ApiResponse.success(todoService.teacherReview(itemId, teacherId, score, feedback, audioFile));
    }

    @GetMapping("/item/{itemId}/score")
    public ApiResponse<SpeechScoreResult> getScoreDetail(
            @PathVariable("itemId") Long itemId,
            Authentication auth) {
        return ApiResponse.success(todoService.getScoreDetail(itemId));
    }
}
