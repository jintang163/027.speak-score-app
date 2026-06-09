package com.speak.score.controller;

import com.speak.score.dto.ApiResponse;
import com.speak.score.dto.UserInfoDTO;
import com.speak.score.entity.User;
import com.speak.score.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/teacher")
@RequiredArgsConstructor
@PreAuthorize("hasRole('TEACHER')")
public class TeacherController {

    private final UserService userService;

    @GetMapping("/students/class/{classId}")
    public ApiResponse<List<User>> getStudentsByClass(@PathVariable Long classId) {
        return ApiResponse.success(userService.getStudentsByClassId(classId));
    }

    @GetMapping("/students/{studentId}")
    public ApiResponse<UserInfoDTO> getStudentInfo(@PathVariable Long studentId) {
        return ApiResponse.success(userService.getUserInfo(studentId));
    }
}
