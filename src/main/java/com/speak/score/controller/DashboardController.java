package com.speak.score.controller;

import com.speak.score.dto.*;
import com.speak.score.repository.*;
import com.speak.score.entity.*;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/dashboard")
@RequiredArgsConstructor
public class DashboardController {

    private final UserRepository userRepository;
    private final SchoolRepository schoolRepository;
    private final ClassRepository classRepository;
    private final MaterialRepository materialRepository;

    @GetMapping("/stats")
    @PreAuthorize("hasAnyRole('EDU_OFFICE')")
    public ApiResponse<DashboardStatsDTO> getStats() {
        DashboardStatsDTO stats = new DashboardStatsDTO();
        stats.setTotalUsers(userRepository.count());
        stats.setTotalSchools(schoolRepository.count());
        stats.setTotalClasses(classRepository.count());
        stats.setTotalMaterials(materialRepository.count());

        LocalDateTime todayStart = LocalDate.now().atStartOfDay();
        LocalDateTime todayEnd = LocalDate.now().atTime(LocalTime.MAX);

        stats.setPendingReviewCount((long) materialRepository
                .findByReviewStatusAndDeletedFalse(ReviewStatus.PENDING, PageRequest.of(0, 1))
                .getTotalElements());

        return ApiResponse.success(stats);
    }

    @GetMapping("/material-trend")
    @PreAuthorize("hasAnyRole('EDU_OFFICE')")
    public ApiResponse<List<TrendDataDTO>> getMaterialTrend(
            @RequestParam(defaultValue = "7") int days) {
        List<TrendDataDTO> trend = new ArrayList<>();
        LocalDate today = LocalDate.now();
        for (int i = days - 1; i >= 0; i--) {
            LocalDate date = today.minusDays(i);
            LocalDateTime start = date.atStartOfDay();
            LocalDateTime end = date.atTime(LocalTime.MAX);
            long count = materialRepository.countByCreatedAtBetweenAndDeletedFalse(start, end);
            TrendDataDTO point = new TrendDataDTO();
            point.setDate(date.toString());
            point.setCount(count);
            trend.add(point);
        }
        return ApiResponse.success(trend);
    }
}
