package com.speak.score.controller;

import com.speak.score.dto.ApiResponse;
import com.speak.score.dto.WeComConfigDTO;
import com.speak.score.dto.WeComConfigRequest;
import com.speak.score.entity.WeComConfig;
import com.speak.score.repository.WeComConfigRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/wecom/config")
@RequiredArgsConstructor
public class WeComConfigController {

    private final WeComConfigRepository weComConfigRepository;

    @GetMapping("/school/{schoolId}")
    public ApiResponse<List<WeComConfigDTO>> getBySchoolId(@PathVariable Long schoolId) {
        List<WeComConfig> configs = weComConfigRepository.findBySchoolIdAndDeletedFalse(schoolId);
        List<WeComConfigDTO> dtos = configs.stream()
                .map(WeComConfigDTO::fromEntity)
                .collect(Collectors.toList());
        return ApiResponse.success(dtos);
    }

    @PostMapping
    public ApiResponse<WeComConfigDTO> create(
            @Valid @RequestBody WeComConfigRequest request,
            Authentication auth) {
        Long userId = (Long) auth.getPrincipal();

        WeComConfig config = new WeComConfig();
        config.setSchoolId(request.getSchoolId());
        config.setWebhookUrl(request.getWebhookUrl());
        config.setSecret(request.getSecret());
        config.setConfigName(request.getConfigName());
        config.setReportType(request.getReportType());
        config.setEnabled(request.getEnabled());
        config.setCreatedBy(userId);

        WeComConfig saved = weComConfigRepository.save(config);
        return ApiResponse.success(WeComConfigDTO.fromEntity(saved));
    }

    @PutMapping("/{id}")
    public ApiResponse<WeComConfigDTO> update(
            @PathVariable Long id,
            @Valid @RequestBody WeComConfigRequest request) {
        WeComConfig config = weComConfigRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("配置不存在"));

        config.setSchoolId(request.getSchoolId());
        config.setWebhookUrl(request.getWebhookUrl());
        config.setSecret(request.getSecret());
        config.setConfigName(request.getConfigName());
        config.setReportType(request.getReportType());
        config.setEnabled(request.getEnabled());

        WeComConfig saved = weComConfigRepository.save(config);
        return ApiResponse.success(WeComConfigDTO.fromEntity(saved));
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@PathVariable Long id) {
        WeComConfig config = weComConfigRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("配置不存在"));
        config.setDeleted(true);
        weComConfigRepository.save(config);
        return ApiResponse.success();
    }
}
