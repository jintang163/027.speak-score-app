package com.speak.score.controller;

import com.speak.score.dto.ApiResponse;
import com.speak.score.dto.HomeMenuDTO;
import com.speak.score.entity.RoleEnum;
import com.speak.score.entity.User;
import com.speak.score.exception.BusinessException;
import com.speak.score.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/home")
@RequiredArgsConstructor
public class HomeController {

    private final UserRepository userRepository;

    @GetMapping("/menus")
    public ApiResponse<HomeMenuDTO> getHomeMenus(Authentication authentication) {
        Long userId = (Long) authentication.getPrincipal();
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException("User not found"));

        RoleEnum primaryRole = user.getRoles().stream()
                .map(r -> r.getRoleCode())
                .findFirst()
                .orElse(RoleEnum.STUDENT);

        HomeMenuDTO menuDTO = new HomeMenuDTO();
        menuDTO.setRole(primaryRole);
        menuDTO.setMenus(getMenusByRole(primaryRole));

        return ApiResponse.success(menuDTO);
    }

    private List<HomeMenuDTO.MenuItem> getMenusByRole(RoleEnum role) {
        List<HomeMenuDTO.MenuItem> menus = new ArrayList<>();

        switch (role) {
            case STUDENT:
                menus.add(new HomeMenuDTO.MenuItem("task", "跟读任务", "book", "/student/task"));
                menus.add(new HomeMenuDTO.MenuItem("record", "我的录音", "mic", "/student/record"));
                menus.add(new HomeMenuDTO.MenuItem("ranking", "排行榜", "trophy", "/student/ranking"));
                menus.add(new HomeMenuDTO.MenuItem("resource", "学习资料", "video", "/student/resource"));
                menus.add(new HomeMenuDTO.MenuItem("profile", "我的", "person", "/student/profile"));
                break;
            case TEACHER:
                menus.add(new HomeMenuDTO.MenuItem("task", "任务管理", "book", "/teacher/task"));
                menus.add(new HomeMenuDTO.MenuItem("students", "学生管理", "people", "/teacher/students"));
                menus.add(new HomeMenuDTO.MenuItem("material", "资料管理", "video_library", "/teacher/material"));
                menus.add(new HomeMenuDTO.MenuItem("ranking", "成绩排行", "trophy", "/teacher/ranking"));
                menus.add(new HomeMenuDTO.MenuItem("resource", "资料管理", "video", "/teacher/resource"));
                menus.add(new HomeMenuDTO.MenuItem("message", "消息通知", "notifications", "/teacher/message"));
                menus.add(new HomeMenuDTO.MenuItem("profile", "我的", "person", "/teacher/profile"));
                break;
            case EDU_OFFICE:
                menus.add(new HomeMenuDTO.MenuItem("school", "学校管理", "school", "/edu-office/school"));
                menus.add(new HomeMenuDTO.MenuItem("material", "资料审核", "video_library", "/edu-office/material"));
                menus.add(new HomeMenuDTO.MenuItem("teachers", "教师管理", "people", "/edu-office/teachers"));
                menus.add(new HomeMenuDTO.MenuItem("classes", "班级管理", "grid", "/edu-office/classes"));
                menus.add(new HomeMenuDTO.MenuItem("ranking", "全校排行", "trophy", "/edu-office/ranking"));
                menus.add(new HomeMenuDTO.MenuItem("message", "消息推送", "notifications", "/edu-office/message"));
                menus.add(new HomeMenuDTO.MenuItem("profile", "我的", "person", "/edu-office/profile"));
                break;
        }

        return menus;
    }
}
