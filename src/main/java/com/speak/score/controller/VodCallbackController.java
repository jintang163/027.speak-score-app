package com.speak.score.controller;

import com.speak.score.dto.ApiResponse;
import com.speak.score.entity.Material;
import com.speak.score.entity.TranscodeStatus;
import com.speak.score.repository.MaterialRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/vod/callback")
@RequiredArgsConstructor
public class VodCallbackController {

    private final MaterialRepository materialRepository;

    @PostMapping("/transcode")
    public ApiResponse<String> transcodeCallback(
            @RequestHeader(value = "Aliyun-Vod-Signature", required = false) String signature,
            @RequestBody String body) {
        log.info("VOD transcode callback received, body length: {}", body != null ? body.length() : 0);

        String videoId = extractValue(body, "VideoId");
        String status = extractValue(body, "Status");
        String eventType = extractValue(body, "EventType");

        log.info("VOD callback: videoId={}, status={}, eventType={}", videoId, status, eventType);

        if (videoId == null || videoId.isEmpty()) {
            log.warn("VOD callback missing VideoId");
            return ApiResponse.success("ignored");
        }

        List<Material> materials = materialRepository.findByVideoIdAndDeletedFalse(videoId);
        if (materials == null || materials.isEmpty()) {
            log.warn("No material found for videoId: {}", videoId);
            return ApiResponse.success("no material found");
        }

        for (Material material : materials) {
            if ("TranscodeSuccess".equals(status) || "TranscodeComplete".equals(status)) {
                material.setTranscodeStatus(TranscodeStatus.DONE);
                log.info("Video transcode completed, materialId={}, videoId={}", material.getId(), videoId);
            } else if ("TranscodeFail".equals(status)) {
                material.setTranscodeStatus(TranscodeStatus.FAILED);
                log.warn("Video transcode failed, materialId={}, videoId={}", material.getId(), videoId);
            } else if ("UploadByURLComplete".equals(eventType) || "FileUploadComplete".equals(eventType)) {
                material.setTranscodeStatus(TranscodeStatus.PROCESSING);
                log.info("Video upload completed, starting transcode, materialId={}", material.getId());
            }
            materialRepository.save(material);
        }

        return ApiResponse.success("ok");
    }

    private String extractValue(String body, String key) {
        if (body == null || key == null) return null;
        String jsonKey = "\"" + key + "\"";
        int idx = body.indexOf(jsonKey);
        if (idx >= 0) {
            int colonIdx = body.indexOf(":", idx + jsonKey.length());
            if (colonIdx >= 0) {
                int valueStart = body.indexOf("\"", colonIdx + 1);
                if (valueStart >= 0) {
                    int valueEnd = body.indexOf("\"", valueStart + 1);
                    if (valueEnd >= 0) {
                        return body.substring(valueStart + 1, valueEnd);
                    }
                }
                int commaIdx = body.indexOf(",", colonIdx + 1);
                int braceIdx = body.indexOf("}", colonIdx + 1);
                int endIdx = -1;
                if (commaIdx >= 0 && braceIdx >= 0) {
                    endIdx = Math.min(commaIdx, braceIdx);
                } else if (commaIdx >= 0) {
                    endIdx = commaIdx;
                } else if (braceIdx >= 0) {
                    endIdx = braceIdx;
                }
                if (endIdx > colonIdx) {
                    return body.substring(colonIdx + 1, endIdx).trim();
                }
            }
        }
        return null;
    }
}
