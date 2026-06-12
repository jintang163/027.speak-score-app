package com.speak.score.controller;

import com.speak.score.dto.ApiResponse;
import com.speak.score.dto.NotifyChannelConfigDTO;
import com.speak.score.dto.NotifyChannelConfigRequest;
import com.speak.score.dto.NotifyMessageDTO;
import com.speak.score.entity.MsgType;
import com.speak.score.entity.NotifyChannel;
import com.speak.score.entity.NotifyChannelConfig;
import com.speak.score.repository.NotifyChannelConfigRepository;
import com.speak.score.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;
    private final NotifyChannelConfigRepository notifyChannelConfigRepository;

    @GetMapping
    public ApiResponse<Page<NotifyMessageDTO>> getMessages(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String msgType,
            Authentication auth) {
        Long userId = (Long) auth.getPrincipal();
        if (msgType != null && !msgType.isEmpty()) {
            return ApiResponse.success(notificationService.getMessagesByType(
                    userId, MsgType.valueOf(msgType), page, size));
        }
        return ApiResponse.success(notificationService.getMessages(userId, page, size));
    }

    @GetMapping("/unread-count")
    public ApiResponse<Long> getUnreadCount(Authentication auth) {
        Long userId = (Long) auth.getPrincipal();
        return ApiResponse.success(notificationService.getUnreadCount(userId));
    }

    @GetMapping("/unread-count-by-type")
    public ApiResponse<Map<String, Long>> getUnreadCountByType(Authentication auth) {
        Long userId = (Long) auth.getPrincipal();
        return ApiResponse.success(notificationService.getUnreadCountByType(userId));
    }

    @PutMapping("/{id}/read")
    public ApiResponse<Void> markAsRead(
            @PathVariable("id") Long messageId,
            Authentication auth) {
        Long userId = (Long) auth.getPrincipal();
        notificationService.markAsRead(messageId, userId);
        return ApiResponse.success();
    }

    @PutMapping("/read-all")
    public ApiResponse<Void> markAllAsRead(Authentication auth) {
        Long userId = (Long) auth.getPrincipal();
        notificationService.markAllAsRead(userId);
        return ApiResponse.success();
    }

    @GetMapping("/channels")
    public ApiResponse<List<NotifyChannelConfigDTO>> getChannels(Authentication auth) {
        Long userId = (Long) auth.getPrincipal();
        List<NotifyChannelConfig> configs =
                notifyChannelConfigRepository.findByUserIdAndEnabledTrueAndDeletedFalse(userId);
        List<NotifyChannelConfigDTO> dtos = configs.stream()
                .map(this::toChannelConfigDTO)
                .collect(Collectors.toList());
        return ApiResponse.success(dtos);
    }

    @PostMapping("/channels")
    public ApiResponse<NotifyChannelConfigDTO> saveChannel(
            @Valid @RequestBody NotifyChannelConfigRequest request,
            Authentication auth) {
        Long userId = (Long) auth.getPrincipal();

        NotifyChannelConfig config = notifyChannelConfigRepository
                .findByUserIdAndChannelAndDeletedFalse(userId, NotifyChannel.valueOf(request.getChannel()))
                .orElse(new NotifyChannelConfig());

        config.setUserId(userId);
        config.setChannel(NotifyChannel.valueOf(request.getChannel()));
        config.setChannelValue(request.getChannelValue());
        config.setEnabled(request.getEnabled());

        NotifyChannelConfig saved = notifyChannelConfigRepository.save(config);
        return ApiResponse.success(toChannelConfigDTO(saved));
    }

    private NotifyChannelConfigDTO toChannelConfigDTO(NotifyChannelConfig config) {
        NotifyChannelConfigDTO dto = new NotifyChannelConfigDTO();
        dto.setId(config.getId());
        dto.setUserId(config.getUserId());
        dto.setChannel(config.getChannel() != null ? config.getChannel().name() : null);
        dto.setChannelValue(config.getChannelValue());
        dto.setEnabled(config.getEnabled());
        return dto;
    }
}
