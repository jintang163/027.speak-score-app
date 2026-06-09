package com.speak.score.controller;

import com.speak.score.dto.ApiResponse;
import com.speak.score.dto.JoinClassRequest;
import com.speak.score.dto.UserInfoDTO;
import com.speak.score.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/user")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping("/me")
    public ApiResponse<UserInfoDTO> getCurrentUser(Authentication authentication) {
        Long userId = (Long) authentication.getPrincipal();
        UserInfoDTO userInfo = userService.getUserInfo(userId);
        return ApiResponse.success(userInfo);
    }

    @GetMapping("/{userId}")
    public ApiResponse<UserInfoDTO> getUserInfo(@PathVariable Long userId) {
        UserInfoDTO userInfo = userService.getUserInfo(userId);
        return ApiResponse.success(userInfo);
    }

    @PostMapping("/join-class")
    public ApiResponse<Void> joinClass(Authentication authentication,
                                       @RequestBody JoinClassRequest request) {
        Long userId = (Long) authentication.getPrincipal();
        userService.assignToClass(userId,
                Long.parseLong(request.getClassCode()), com.speak.score.entity.RoleEnum.STUDENT, "CODE");
        return ApiResponse.success();
    }
}
