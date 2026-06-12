package com.speak.score.controller;

import com.speak.score.dto.ApiResponse;
import com.speak.score.dto.ParentStudentBindRequest;
import com.speak.score.dto.ParentStudentDTO;
import com.speak.score.dto.StudentCalendarDTO;
import com.speak.score.dto.StudentProgressSeriesDTO;
import com.speak.score.exception.BusinessException;
import com.speak.score.service.ParentStudentService;
import com.speak.score.service.ReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/parent")
@RequiredArgsConstructor
public class ParentController {

    private final ParentStudentService parentStudentService;
    private final ReportService reportService;

    @PostMapping("/bind")
    public ApiResponse<ParentStudentDTO> bindChild(
            @Valid @RequestBody ParentStudentBindRequest request,
            Authentication auth) {
        Long parentId = (Long) auth.getPrincipal();
        return ApiResponse.success(parentStudentService.bindParent(parentId, request));
    }

    @DeleteMapping("/unbind/{studentId}")
    public ApiResponse<Void> unbindChild(
            @PathVariable Long studentId,
            Authentication auth) {
        Long parentId = (Long) auth.getPrincipal();
        parentStudentService.unbindParent(parentId, studentId);
        return ApiResponse.success();
    }

    @PutMapping("/primary/{studentId}")
    public ApiResponse<Void> setPrimary(
            @PathVariable Long studentId,
            @RequestParam Boolean isPrimary,
            Authentication auth) {
        Long parentId = (Long) auth.getPrincipal();
        parentStudentService.updatePrimary(parentId, studentId, isPrimary);
        return ApiResponse.success();
    }

    @GetMapping("/children")
    public ApiResponse<List<ParentStudentDTO>> getMyChildren(Authentication auth) {
        Long parentId = (Long) auth.getPrincipal();
        return ApiResponse.success(parentStudentService.getMyChildren(parentId));
    }

    @GetMapping("/student/{studentId}/parents")
    @PreAuthorize("hasAnyRole('TEACHER', 'EDU_OFFICE')")
    public ApiResponse<List<ParentStudentDTO>> getStudentParents(@PathVariable Long studentId) {
        return ApiResponse.success(parentStudentService.getStudentParents(studentId));
    }

    @GetMapping("/child/{studentId}/calendar")
    public ApiResponse<StudentCalendarDTO> getChildCalendar(
            @PathVariable Long studentId,
            @RequestParam @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate startDate,
            @RequestParam @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate endDate,
            Authentication auth) {
        Long parentId = (Long) auth.getPrincipal();
        validateParentChildAccess(parentId, studentId);
        return ApiResponse.success(reportService.getStudentCalendar(studentId, startDate, endDate));
    }

    @GetMapping("/child/{studentId}/progress")
    public ApiResponse<StudentProgressSeriesDTO> getChildProgress(
            @PathVariable Long studentId,
            @RequestParam @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate startDate,
            @RequestParam @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate endDate,
            Authentication auth) {
        Long parentId = (Long) auth.getPrincipal();
        validateParentChildAccess(parentId, studentId);
        return ApiResponse.success(reportService.getStudentProgress(studentId, startDate, endDate));
    }

    private void validateParentChildAccess(Long parentId, Long studentId) {
        List<ParentStudentDTO> children = parentStudentService.getMyChildren(parentId);
        boolean hasAccess = children.stream()
                .anyMatch(c -> c.getStudentId().equals(studentId));
        if (!hasAccess) {
            throw new BusinessException("无权访问该学生数据");
        }
    }
}
