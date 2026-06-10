package com.speak.score.controller;

import com.speak.score.dto.ApiResponse;
import com.speak.score.dto.JoinClassRequest;
import com.speak.score.dto.UserInfoDTO;
import com.speak.score.entity.UserDevice;
import com.speak.score.repository.UserDeviceRepository;
import com.speak.score.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/user")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;
    private final UserDeviceRepository userDeviceRepository;

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

    @PostMapping("/device/register")
    public ApiResponse<Void> registerDevice(Authentication authentication,
                                            @RequestBody Map<String, String> request) {
        Long userId = (Long) authentication.getPrincipal();
        String deviceType = request.getOrDefault("deviceType", "GETUI");
        String deviceToken = request.get("deviceToken");
        String platform = request.get("platform");
        String bundleId = request.get("bundleId");

        if (deviceToken == null || deviceToken.isEmpty()) {
            return ApiResponse.error(400, "deviceToken is required");
        }

        Optional<UserDevice> existing = userDeviceRepository
                .findByUserIdAndDeviceTypeAndDeletedFalse(userId, deviceType);

        UserDevice device = existing.orElseGet(UserDevice::new);
        device.setUserId(userId);
        device.setDeviceType(deviceType);
        device.setDeviceToken(deviceToken);
        device.setPlatform(platform);
        device.setBundleId(bundleId);
        userDeviceRepository.save(device);

        return ApiResponse.success();
    }
}
