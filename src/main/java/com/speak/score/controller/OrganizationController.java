package com.speak.score.controller;

import com.speak.score.dto.*;
import com.speak.score.entity.ClassMember;
import com.speak.score.entity.ClassEntity;
import com.speak.score.entity.Grade;
import com.speak.score.entity.School;
import com.speak.score.service.OrganizationService;
import com.speak.score.service.StudentImportService;
import javax.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/org")
@RequiredArgsConstructor
public class OrganizationController {

    private final OrganizationService organizationService;
    private final StudentImportService studentImportService;

    @PostMapping("/schools")
    @PreAuthorize("hasRole('EDU_OFFICE')")
    public ApiResponse<School> createSchool(@Valid @RequestBody SchoolCreateRequest request) {
        return ApiResponse.success(organizationService.createSchool(request));
    }

    @GetMapping("/schools")
    public ApiResponse<List<SchoolDTO>> getAllSchools() {
        return ApiResponse.success(organizationService.getAllSchools());
    }

    @GetMapping("/schools/region")
    public ApiResponse<List<SchoolDTO>> getSchoolsByRegion(
            @RequestParam String province, @RequestParam String city) {
        return ApiResponse.success(organizationService.getSchoolsByRegion(province, city));
    }

    @PostMapping("/grades")
    @PreAuthorize("hasAnyRole('EDU_OFFICE', 'TEACHER')")
    public ApiResponse<Grade> createGrade(@Valid @RequestBody GradeCreateRequest request) {
        return ApiResponse.success(organizationService.createGrade(request));
    }

    @GetMapping("/grades/school/{schoolId}")
    public ApiResponse<List<GradeDTO>> getGradesBySchoolId(@PathVariable Long schoolId) {
        return ApiResponse.success(organizationService.getGradesBySchoolId(schoolId));
    }

    @PostMapping("/classes")
    @PreAuthorize("hasAnyRole('EDU_OFFICE', 'TEACHER')")
    public ApiResponse<ClassEntity> createClass(@Valid @RequestBody ClassCreateRequest request) {
        return ApiResponse.success(organizationService.createClass(request));
    }

    @GetMapping("/classes/grade/{gradeId}")
    public ApiResponse<List<ClassDTO>> getClassesByGradeId(@PathVariable Long gradeId) {
        return ApiResponse.success(organizationService.getClassesByGradeId(gradeId));
    }

    @GetMapping("/classes/school/{schoolId}")
    public ApiResponse<List<ClassDTO>> getClassesBySchoolId(@PathVariable Long schoolId) {
        return ApiResponse.success(organizationService.getClassesBySchoolId(schoolId));
    }

    @PostMapping("/classes/join")
    public ApiResponse<Void> joinClass(Authentication authentication,
                                       @RequestBody JoinClassRequest request) {
        Long userId = (Long) authentication.getPrincipal();
        organizationService.joinClassByCode(userId, request.getClassCode());
        return ApiResponse.success();
    }

    @GetMapping("/classes/{classId}/pending-members")
    @PreAuthorize("hasAnyRole('TEACHER', 'EDU_OFFICE')")
    public ApiResponse<List<ClassMember>> getPendingMembers(@PathVariable Long classId) {
        return ApiResponse.success(organizationService.getPendingMembers(classId));
    }

    @PostMapping("/classes/members/{memberId}/approve")
    @PreAuthorize("hasAnyRole('TEACHER', 'EDU_OFFICE')")
    public ApiResponse<Void> approveMember(@PathVariable Long memberId) {
        organizationService.approveClassMember(memberId);
        return ApiResponse.success();
    }

    @PostMapping("/classes/members/{memberId}/reject")
    @PreAuthorize("hasAnyRole('TEACHER', 'EDU_OFFICE')")
    public ApiResponse<Void> rejectMember(@PathVariable Long memberId) {
        organizationService.rejectClassMember(memberId);
        return ApiResponse.success();
    }

    @PostMapping("/classes/{classId}/assign-teacher")
    @PreAuthorize("hasRole('EDU_OFFICE')")
    public ApiResponse<Void> assignTeacher(@PathVariable Long classId,
                                           @RequestParam Long teacherId) {
        organizationService.assignTeacherToClass(classId, teacherId);
        return ApiResponse.success();
    }

    @PostMapping("/classes/{classId}/import-students")
    @PreAuthorize("hasAnyRole('TEACHER', 'EDU_OFFICE')")
    public ApiResponse<List<String>> importStudents(@PathVariable Long classId,
                                                     @RequestParam("file") MultipartFile file) {
        List<String> results = studentImportService.importStudents(file, classId);
        return ApiResponse.success(results);
    }
}
