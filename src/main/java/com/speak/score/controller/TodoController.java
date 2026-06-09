package com.speak.score.controller;

import com.speak.score.dto.*;
import com.speak.score.service.TodoService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;

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
}
