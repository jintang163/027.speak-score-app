package com.speak.score.controller;

import com.speak.score.dto.*;
import com.speak.score.service.AuthService;
import javax.validation.Valid;
import lombok.RequiredArgsConstructor;
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

    @PostMapping("/refresh")
    public ApiResponse<TokenResponse> refreshToken(@RequestParam String refreshToken) {
        TokenResponse response = authService.refreshToken(refreshToken);
        return ApiResponse.success(response);
    }
}
