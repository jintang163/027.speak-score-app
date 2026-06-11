package com.speak.score.controller;

import com.speak.score.dto.*;
import com.speak.score.service.ReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/reports")
@RequiredArgsConstructor
public class ReportController {

    private final ReportService reportService;

    @GetMapping("/student/calendar")
    public ApiResponse<StudentCalendarDTO> getStudentCalendar(
            @RequestParam(required = false) Long studentId,
            @RequestParam @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate startDate,
            @RequestParam @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate endDate,
            Authentication auth) {
        Long userId = studentId != null ? studentId : (Long) auth.getPrincipal();
        return ApiResponse.success(reportService.getStudentCalendar(userId, startDate, endDate));
    }

    @GetMapping("/student/progress")
    public ApiResponse<StudentProgressSeriesDTO> getStudentProgress(
            @RequestParam(required = false) Long studentId,
            @RequestParam @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate startDate,
            @RequestParam @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate endDate,
            Authentication auth) {
        Long userId = studentId != null ? studentId : (Long) auth.getPrincipal();
        return ApiResponse.success(reportService.getStudentProgress(userId, startDate, endDate));
    }

    @GetMapping("/class/{classId}/overview")
    @PreAuthorize("hasAnyRole('TEACHER', 'EDU_OFFICE')")
    public ApiResponse<ClassReportDTO> getClassReport(
            @PathVariable Long classId,
            @RequestParam @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate startDate,
            @RequestParam @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate endDate) {
        return ApiResponse.success(reportService.getClassReport(classId, startDate, endDate));
    }

    @GetMapping("/school/{schoolId}/class-comparison")
    @PreAuthorize("hasRole('EDU_OFFICE')")
    public ApiResponse<List<ClassComparisonDTO>> getClassComparison(
            @PathVariable Long schoolId,
            @RequestParam(required = false) Long gradeId,
            @RequestParam @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate startDate,
            @RequestParam @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate endDate) {
        return ApiResponse.success(reportService.getClassComparison(schoolId, gradeId, startDate, endDate));
    }

    @GetMapping("/class/{classId}/export")
    @PreAuthorize("hasAnyRole('TEACHER', 'EDU_OFFICE')")
    public ResponseEntity<byte[]> exportClassReport(
            @PathVariable Long classId,
            @RequestParam @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate startDate,
            @RequestParam @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate endDate) {
        byte[] excelData = reportService.exportClassReport(classId, startDate, endDate);

        String fileName = "homework_report_" + classId + "_" + startDate + "_" + endDate + ".xlsx";

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.parseMediaType(
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"));
        headers.setContentDispositionFormData("attachment", fileName);
        headers.setContentLength(excelData.length);

        return ResponseEntity.ok()
                .headers(headers)
                .body(excelData);
    }

    @PostMapping("/class/{classId}/send-email")
    @PreAuthorize("hasAnyRole('TEACHER', 'EDU_OFFICE')")
    public ApiResponse<Boolean> sendReportByEmail(
            @PathVariable Long classId,
            @RequestParam String email,
            @RequestParam @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate startDate,
            @RequestParam @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate endDate) {
        boolean result = reportService.sendReportByEmail(classId, email, startDate, endDate);
        return ApiResponse.success(result);
    }
}
