package com.speak.score.controller;

import com.speak.score.dto.ApiResponse;
import com.speak.score.dto.UserInfoDTO;
import com.speak.score.entity.User;
import com.speak.score.service.RbacService;
import com.speak.score.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/edu-office")
@RequiredArgsConstructor
@PreAuthorize("hasRole('EDU_OFFICE')")
public class EduOfficeController {

    private final UserService userService;
    private final RbacService rbacService;

    @GetMapping("/teachers/school/{schoolId}")
    public ApiResponse<List<User>> getTeachersBySchool(@PathVariable Long schoolId) {
        return ApiResponse.success(userService.getTeachersBySchoolId(schoolId));
    }

    @GetMapping("/students/{studentId}")
    public ApiResponse<UserInfoDTO> getStudentInfo(@PathVariable Long studentId) {
        return ApiResponse.success(userService.getUserInfo(studentId));
    }

    @PostMapping("/init-rbac")
    public ApiResponse<Void> initRbac() {
        rbacService.initRolesAndPermissions();
        return ApiResponse.success();
    }
}
