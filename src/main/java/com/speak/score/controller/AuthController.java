package com.speak.score.controller;

import com.speak.score.dto.*;
import com.speak.score.service.AuthService;
import javax.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/sms-code")
    public ApiResponse<Void> sendSmsCode(@Valid @RequestBody SmsCodeRequest request) {
        authService.sendSmsCode(request.getPhone());
        return ApiResponse.success();
    }

    @PostMapping("/phone-login")
    public ApiResponse<TokenResponse> loginByPhone(@Valid @RequestBody PhoneLoginRequest request) {
        TokenResponse response = authService.loginByPhone(request.getPhone(), request.getCode());
        return ApiResponse.success(response);
    }

    @PostMapping("/wechat-login")
    public ApiResponse<TokenResponse> loginByWechat(@Valid @RequestBody WechatLoginRequest request) {
        TokenResponse response = authService.loginByWechat(request.getCode());
        return ApiResponse.success(response);
    }

    @PostMapping("/register")
    public ApiResponse<TokenResponse> register(@Valid @RequestBody RegisterRequest request) {
        TokenResponse response = authService.register(request);
        return ApiResponse.success(response);
    }

    @PostMapping("/wechat-register")
    public ApiResponse<TokenResponse> wechatRegister(@Valid @RequestBody WechatRegisterRequest request) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        Long userId = (Long) authentication.getPrincipal();
        TokenResponse response = authService.wechatRegister(userId, request);
        return ApiResponse.success(response);
    }

    @PostMapping("/logout")
    public ApiResponse<Void> logout(@RequestHeader("Authorization") String authorization) {
        if (authorization != null && authorization.startsWith("Bearer ")) {
            String accessToken = authorization.substring(7);
            authService.logout(accessToken);
        }
        return ApiResponse.success();
    }

    @PostMapping("/refresh")
    public ApiResponse<TokenResponse> refreshToken(@RequestParam String refreshToken) {
        TokenResponse response = authService.refreshToken(refreshToken);
        return ApiResponse.success(response);
    }
}
