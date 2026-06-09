package com.speak.score.service;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.speak.score.config.WeChatConfig;
import com.speak.score.dto.*;
import com.speak.score.entity.*;
import com.speak.score.exception.BusinessException;
import com.speak.score.repository.ClassRepository;
import com.speak.score.repository.RoleRepository;
import com.speak.score.repository.SmsCodeRepository;
import com.speak.score.repository.UserRepository;
import com.speak.score.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import java.util.Date;
import java.util.List;
import java.util.Random;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private static final String SMS_RATE_LIMIT_PREFIX = "sms:rate:";
    private static final String SMS_CODE_CACHE_PREFIX = "sms:code:";
    private static final String TOKEN_BLACKLIST_PREFIX = "token:blacklist:";
    private static final String WECHAT_SESSION_PREFIX = "wechat:session:";
    private static final long SMS_CODE_TTL_MINUTES = 5;
    private static final long SMS_RATE_LIMIT_SECONDS = 60;

    private final UserRepository userRepository;
    private final SmsCodeRepository smsCodeRepository;
    private final UserService userService;
    private final ClassRepository classRepository;
    private final RoleRepository roleRepository;
    private final JwtTokenProvider jwtTokenProvider;
    private final RedisTemplate<String, Object> redisTemplate;
    private final WeChatConfig weChatConfig;

    @Value("${jwt.access-token-expiration}")
    private long accessTokenExpiration;

    public void sendSmsCode(String phone) {
        String rateLimitKey = SMS_RATE_LIMIT_PREFIX + phone;
        if (Boolean.TRUE.equals(redisTemplate.hasKey(rateLimitKey))) {
            throw new BusinessException(429, "Please wait before requesting another code");
        }

        String code = generateSmsCode();

        redisTemplate.opsForValue().set(SMS_CODE_CACHE_PREFIX + phone, code,
                SMS_CODE_TTL_MINUTES, TimeUnit.MINUTES);
        redisTemplate.opsForValue().set(rateLimitKey, "1",
                SMS_RATE_LIMIT_SECONDS, TimeUnit.SECONDS);

        SmsCode smsCode = new SmsCode();
        smsCode.setPhone(phone);
        smsCode.setCode(code);
        smsCode.setExpired(false);
        smsCode.setUsed(false);
        smsCodeRepository.save(smsCode);

        log.info("SMS code sent to phone: {} (mock mode)", phone);
    }

    @Transactional
    public TokenResponse loginByPhone(String phone, String code) {
        validateSmsCode(phone, code);

        User user = userRepository.findByPhone(phone)
                .orElseThrow(() -> new BusinessException("User not found, please register first"));

        if (!user.getEnabled()) {
            throw new BusinessException("Account is disabled");
        }

        return buildTokenResponse(user, false);
    }

    @Transactional
    public TokenResponse loginByWechat(String code) {
        WechatSessionResult session = code2Session(code);
        if (session == null || session.getOpenid() == null) {
            throw new BusinessException("WeChat login failed");
        }

        if (session.getErrcode() != null && session.getErrcode() != 0) {
            throw new BusinessException("WeChat login failed: " + session.getErrmsg());
        }

        boolean isNewUser = false;
        User user = userRepository.findByWechatOpenid(session.getOpenid())
                .orElse(null);

        if (user == null) {
            user = userService.createUserWithWechat(
                    session.getOpenid(), session.getUnionid(), "微信用户", null);
            isNewUser = true;
        } else if (!user.getEnabled()) {
            throw new BusinessException("Account is disabled");
        }

        if (session.getSessionKey() != null) {
            redisTemplate.opsForValue().set(
                    WECHAT_SESSION_PREFIX + session.getOpenid(),
                    session.getSessionKey(), 30, TimeUnit.MINUTES);
        }

        return buildTokenResponse(user, isNewUser);
    }

    @Transactional
    public TokenResponse wechatRegister(Long userId, WechatRegisterRequest request) {
        validateSmsCode(request.getPhone(), request.getSmsCode());

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException("User not found"));

        if (request.getWechatCode() != null && !request.getWechatCode().trim().isEmpty()) {
            WechatSessionResult session = code2Session(request.getWechatCode());
            if (session == null || !user.getWechatOpenid().equals(session.getOpenid())) {
                throw new BusinessException("WeChat verification failed");
            }
        }

        if (userRepository.existsByPhone(request.getPhone())) {
            throw new BusinessException("Phone number already registered");
        }

        user.setPhone(request.getPhone());
        if (request.getNickname() != null && !request.getNickname().trim().isEmpty()) {
            user.setNickname(request.getNickname());
        }

        RoleEnum roleCode = RoleEnum.valueOf(request.getRoleCode());
        Role role = roleRepository.findByRoleCode(roleCode)
                .orElseThrow(() -> new BusinessException("Role not found: " + roleCode));
        user.addRole(role);

        if (request.getSchoolId() != null) {
            userService.assignToSchool(user.getId(), request.getSchoolId(), roleCode);
        }

        if (request.getClassCode() != null && !request.getClassCode().trim().isEmpty()) {
            ClassEntity classEntity = classRepository.findByClassCode(request.getClassCode())
                    .orElseThrow(() -> new BusinessException("Class code not found"));

            user.setClassEntity(classEntity);
            user.setSchool(classEntity.getSchool());

            ClassMember member = new ClassMember();
            member.setUser(user);
            member.setClassEntity(classEntity);
            member.setRoleCode(roleCode);
            member.setJoinType("CODE");
            member.setStatus(roleCode == RoleEnum.STUDENT ? 0 : 1);
        } else if (request.getClassId() != null) {
            userService.assignToClass(user.getId(), request.getClassId(), roleCode, "SELECT");
        }

        userRepository.save(user);

        return buildTokenResponse(user, false);
    }

    @Transactional
    public TokenResponse register(RegisterRequest request) {
        validateSmsCode(request.getPhone(), request.getCode());

        if (userRepository.existsByPhone(request.getPhone())) {
            throw new BusinessException("Phone number already registered");
        }

        RoleEnum roleCode = RoleEnum.valueOf(request.getRoleCode());

        User user = userService.createUserWithPhone(
                request.getPhone(), request.getNickname(), roleCode);

        if (request.getSchoolId() != null) {
            userService.assignToSchool(user.getId(), request.getSchoolId(), roleCode);
        }

        if (request.getClassCode() != null && !request.getClassCode().trim().isEmpty()) {
            ClassEntity classEntity = classRepository.findByClassCode(request.getClassCode())
                    .orElseThrow(() -> new BusinessException("Class code not found"));

            user.setClassEntity(classEntity);
            user.setSchool(classEntity.getSchool());

            ClassMember member = new ClassMember();
            member.setUser(user);
            member.setClassEntity(classEntity);
            member.setRoleCode(roleCode);
            member.setJoinType("CODE");
            member.setStatus(roleCode == RoleEnum.STUDENT ? 0 : 1);
        } else if (request.getClassId() != null) {
            userService.assignToClass(user.getId(), request.getClassId(), roleCode, "SELECT");
        }

        return buildTokenResponse(userRepository.save(user), true);
    }

    public void logout(String accessToken) {
        Date expiration = jwtTokenProvider.getExpirationFromToken(accessToken);
        long remainingSeconds = (expiration.getTime() - System.currentTimeMillis()) / 1000;

        if (remainingSeconds > 0) {
            redisTemplate.opsForValue().set(
                    TOKEN_BLACKLIST_PREFIX + accessToken,
                    "1", remainingSeconds, TimeUnit.SECONDS);
        }
    }

    public boolean isTokenBlacklisted(String token) {
        return Boolean.TRUE.equals(redisTemplate.hasKey(TOKEN_BLACKLIST_PREFIX + token));
    }

    public TokenResponse refreshToken(String refreshToken) {
        if (!jwtTokenProvider.validateToken(refreshToken)) {
            throw new BusinessException(401, "Invalid refresh token");
        }

        if (!jwtTokenProvider.isRefreshToken(refreshToken)) {
            throw new BusinessException(401, "Not a refresh token");
        }

        Long userId = jwtTokenProvider.getUserIdFromToken(refreshToken);
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException("User not found"));

        if (!user.getEnabled()) {
            throw new BusinessException("Account is disabled");
        }

        return buildTokenResponse(user, false);
    }

    private void validateSmsCode(String phone, String code) {
        String cacheKey = SMS_CODE_CACHE_PREFIX + phone;
        Object cachedCode = redisTemplate.opsForValue().get(cacheKey);

        if (cachedCode == null || !cachedCode.toString().equals(code)) {
            throw new BusinessException("Invalid or expired SMS code");
        }

        redisTemplate.delete(cacheKey);
    }

    private TokenResponse buildTokenResponse(User user, boolean isNewUser) {
        List<String> roles = user.getRoles().stream()
                .map(role -> role.getRoleCode().name())
                .collect(Collectors.toList());

        String accessToken = jwtTokenProvider.generateAccessToken(user.getId(), user.getPhone(), roles);
        String refreshToken = jwtTokenProvider.generateRefreshToken(user.getId());

        UserInfoDTO userInfo = userService.getUserInfo(user.getId());

        return new TokenResponse(accessToken, refreshToken, accessTokenExpiration, userInfo, isNewUser);
    }

    private String generateSmsCode() {
        Random random = new Random();
        return String.format("%06d", random.nextInt(1000000));
    }

    private WechatSessionResult code2Session(String code) {
        try {
            String url = String.format(weChatConfig.getCode2sessionUrl(),
                    weChatConfig.getAppId(), weChatConfig.getAppSecret(), code);
            RestTemplate restTemplate = new RestTemplate();
            return restTemplate.getForObject(url, WechatSessionResult.class);
        } catch (Exception e) {
            log.error("WeChat code2Session failed", e);
            return null;
        }
    }

    @lombok.Data
    private static class WechatSessionResult {
        private String openid;
        @JsonProperty("session_key")
        private String sessionKey;
        private String unionid;
        private Integer errcode;
        private String errmsg;
    }
}
