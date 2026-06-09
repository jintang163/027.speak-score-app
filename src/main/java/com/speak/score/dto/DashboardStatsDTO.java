package com.speak.score.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class DashboardStatsDTO {
    private Long totalUsers;
    private Long totalStudents;
    private Long totalTeachers;
    private Long totalSchools;
    private Long totalClasses;
    private Long totalMaterials;
    private Long totalVideos;
    private Long pendingReviewCount;
    private Long todayUploads;
    private Long todayActiveUsers;
}
