package com.speak.score.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.speak.score.config.NotificationConfig;
import com.speak.score.dto.NotifyMessageDTO;
import com.speak.score.entity.*;
import com.speak.score.exception.BusinessException;
import com.speak.score.repository.NotifyChannelConfigRepository;
import com.speak.score.repository.NotifyMessageRepository;
import com.speak.score.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotifyMessageRepository notifyMessageRepository;
    private final NotifyChannelConfigRepository notifyChannelConfigRepository;
    private final NotificationConfig notificationConfig;
    private final UserRepository userRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Autowired(required = false)
    private PushNotificationService pushNotificationService;

    @Autowired(required = false)
    private WeChatSubscribeMessageService weChatSubscribeMessageService;

    @Autowired(required = false)
    private WeComBotService weComBotService;

    public void sendNotification(Long senderId, Long receiverId, String title, String content,
                                 MsgType msgType, Long relatedId, String relatedType) {
        sendNotification(senderId, receiverId, title, content, msgType, relatedId, relatedType, null);
    }

    @Transactional
    public void sendNotification(Long senderId, Long receiverId, String title, String content,
                                 MsgType msgType, Long relatedId, String relatedType, Map<String, Object> extraData) {
        NotifyMessage inAppMsg = createInAppMessage(senderId, receiverId, title, content, msgType, relatedId, relatedType, extraData);
        notifyMessageRepository.save(inAppMsg);

        sendViaPushChannel(senderId, receiverId, title, content, msgType, relatedId, relatedType, extraData);
        sendViaWeChat(senderId, receiverId, title, content, msgType, relatedId, extraData);
    }

    public void sendBatchNotification(Long senderId, List<Long> receiverIds, String title, String content,
                                      MsgType msgType, Long relatedId, String relatedType) {
        sendBatchNotification(senderId, receiverIds, title, content, msgType, relatedId, relatedType, null);
    }

    @Transactional
    public void sendBatchNotification(Long senderId, List<Long> receiverIds, String title, String content,
                                      MsgType msgType, Long relatedId, String relatedType,
                                      Map<String, Object> extraData) {
        if (receiverIds == null || receiverIds.isEmpty()) {
            return;
        }

        LocalDateTime now = LocalDateTime.now();
        List<NotifyMessage> messages = new ArrayList<>();
        for (Long receiverId : receiverIds) {
            NotifyMessage msg = createInAppMessage(senderId, receiverId, title, content, msgType, relatedId, relatedType, extraData);
            msg.setCreatedAt(now);
            msg.setUpdatedAt(now);
            messages.add(msg);
        }
        notifyMessageRepository.saveAll(messages);

        sendBatchViaPushChannel(senderId, receiverIds, title, content, msgType, relatedId, relatedType, extraData);
        sendBatchViaWeChat(senderId, receiverIds, title, content, msgType, relatedId, extraData);
    }

    private NotifyMessage createInAppMessage(Long senderId, Long receiverId, String title, String content,
                                             MsgType msgType, Long relatedId, String relatedType,
                                             Map<String, Object> extraData) {
        NotifyMessage msg = new NotifyMessage();
        msg.setTitle(title);
        msg.setContent(content);
        msg.setMsgType(msgType);
        msg.setChannel(NotifyChannel.IN_APP);
        msg.setSenderId(senderId);
        msg.setReceiverId(receiverId);
        msg.setRelatedId(relatedId);
        msg.setRelatedType(relatedType);
        msg.setIsRead(false);
        msg.setSendStatus(SendStatus.SENT);
        msg.setSentAt(LocalDateTime.now());
        msg.setRetryCount(0);
        msg.setMaxRetry(notificationConfig.getRetry().getMaxRetry());
        if (extraData != null && !extraData.isEmpty()) {
            try {
                msg.setExtraData(objectMapper.writeValueAsString(extraData));
            } catch (Exception e) {
                log.warn("Failed to serialize extraData", e);
            }
        }
        return msg;
    }

    private void sendViaPushChannel(Long senderId, Long receiverId, String title, String content,
                                    MsgType msgType, Long relatedId, String relatedType, Map<String, Object> extraData) {
        NotifyChannel channel = NotifyChannel.APP_PUSH;
        NotifyMessage pushMsg = createChannelMessage(senderId, receiverId, title, content, msgType, relatedId, relatedType, extraData, channel);
        if (pushNotificationService == null) {
            log.warn("PushNotificationService not available, mark as failed for retry: user={}", receiverId);
            pushMsg.setSendStatus(SendStatus.FAILED);
            pushMsg.setLastError("PushNotificationService not available");
            pushMsg.setNextRetryAt(LocalDateTime.now().plusMinutes(notificationConfig.getRetry().getInitialDelayMinutes()));
            notifyMessageRepository.save(pushMsg);
            return;
        }
        try {
            pushNotificationService.pushToUsers(Collections.singletonList(receiverId), title, content, relatedId);
            pushMsg.setSendStatus(SendStatus.SENT);
            pushMsg.setSentAt(LocalDateTime.now());
            log.info("Push notification sent to user: {}, channel: {}", receiverId, channel);
        } catch (Exception e) {
            log.error("Failed to send push notification to user: {}, channel: {}", receiverId, channel, e);
            pushMsg.setSendStatus(SendStatus.FAILED);
            pushMsg.setLastError(e.getMessage() != null ? e.getMessage() : e.getClass().getSimpleName());
            pushMsg.setNextRetryAt(LocalDateTime.now().plusMinutes(notificationConfig.getRetry().getInitialDelayMinutes()));
        }
        notifyMessageRepository.save(pushMsg);
    }

    private void sendBatchViaPushChannel(Long senderId, List<Long> receiverIds, String title, String content,
                                         MsgType msgType, Long relatedId, String relatedType, Map<String, Object> extraData) {
        if (receiverIds == null || receiverIds.isEmpty()) {
            return;
        }
        NotifyChannel channel = NotifyChannel.APP_PUSH;
        LocalDateTime now = LocalDateTime.now();
        List<NotifyMessage> messages = new ArrayList<>();

        if (pushNotificationService == null) {
            log.warn("PushNotificationService not available, mark batch as failed for retry: count={}", receiverIds.size());
            for (Long receiverId : receiverIds) {
                NotifyMessage msg = createChannelMessage(senderId, receiverId, title, content, msgType, relatedId, relatedType, extraData, channel);
                msg.setCreatedAt(now);
                msg.setUpdatedAt(now);
                msg.setSendStatus(SendStatus.FAILED);
                msg.setLastError("PushNotificationService not available");
                msg.setNextRetryAt(now.plusMinutes(notificationConfig.getRetry().getInitialDelayMinutes()));
                messages.add(msg);
            }
            notifyMessageRepository.saveAll(messages);
            return;
        }

        boolean success = false;
        String errorMsg = null;
        try {
            pushNotificationService.pushToUsers(receiverIds, title, content, relatedId);
            success = true;
            log.info("Batch push notification sent to {} users, channel: {}", receiverIds.size(), channel);
        } catch (Exception e) {
            log.error("Failed to send batch push notification, channel: {}", channel, e);
            errorMsg = e.getMessage() != null ? e.getMessage() : e.getClass().getSimpleName();
        }

        for (Long receiverId : receiverIds) {
            NotifyMessage msg = createChannelMessage(senderId, receiverId, title, content, msgType, relatedId, relatedType, extraData, channel);
            msg.setCreatedAt(now);
            msg.setUpdatedAt(now);
            if (success) {
                msg.setSendStatus(SendStatus.SENT);
                msg.setSentAt(now);
            } else {
                msg.setSendStatus(SendStatus.FAILED);
                msg.setLastError(errorMsg);
                msg.setNextRetryAt(now.plusMinutes(notificationConfig.getRetry().getInitialDelayMinutes()));
            }
            messages.add(msg);
        }
        notifyMessageRepository.saveAll(messages);
    }

    private void sendViaWeChat(Long senderId, Long receiverId, String title, String content,
                               MsgType msgType, Long relatedId, Map<String, Object> extraData) {
        NotifyChannel channel = NotifyChannel.WECHAT;
        NotifyMessage wechatMsg = createChannelMessage(senderId, receiverId, title, content, msgType, relatedId, null, extraData, channel);

        if (weChatSubscribeMessageService == null) {
            log.warn("WeChatSubscribeMessageService not available, mark as failed for retry: user={}", receiverId);
            wechatMsg.setSendStatus(SendStatus.FAILED);
            wechatMsg.setLastError("WeChatSubscribeMessageService not available");
            wechatMsg.setNextRetryAt(LocalDateTime.now().plusMinutes(notificationConfig.getRetry().getInitialDelayMinutes()));
            notifyMessageRepository.save(wechatMsg);
            return;
        }
        String templateId = getWeChatTemplateId(msgType);
        if (templateId == null || templateId.isEmpty()) {
            log.warn("WeChat templateId not found for msgType={}, mark as failed for retry: user={}", msgType, receiverId);
            wechatMsg.setSendStatus(SendStatus.FAILED);
            wechatMsg.setLastError("Template not found for type: " + msgType);
            wechatMsg.setNextRetryAt(LocalDateTime.now().plusMinutes(notificationConfig.getRetry().getInitialDelayMinutes()));
            notifyMessageRepository.save(wechatMsg);
            return;
        }
        try {
            Map<String, String> data = weChatSubscribeMessageService.buildTaskNotificationData(
                    title, content, "请打开App查看详情");
            String page = relatedId != null ? "pages/todo/detail?id=" + relatedId : null;
            weChatSubscribeMessageService.sendSubscribeMessageToUsers(
                    Collections.singletonList(receiverId), templateId, data, page);
            wechatMsg.setSendStatus(SendStatus.SENT);
            wechatMsg.setSentAt(LocalDateTime.now());
            log.info("WeChat subscribe message sent to user: {}", receiverId);
        } catch (Exception e) {
            log.error("Failed to send WeChat message to user: {}", receiverId, e);
            wechatMsg.setSendStatus(SendStatus.FAILED);
            wechatMsg.setLastError(e.getMessage());
            wechatMsg.setNextRetryAt(LocalDateTime.now().plusMinutes(notificationConfig.getRetry().getInitialDelayMinutes()));
        }
        notifyMessageRepository.save(wechatMsg);
    }

    private void sendBatchViaWeChat(Long senderId, List<Long> receiverIds, String title, String content,
                                    MsgType msgType, Long relatedId, Map<String, Object> extraData) {
        if (receiverIds == null || receiverIds.isEmpty()) {
            return;
        }
        NotifyChannel channel = NotifyChannel.WECHAT;
        LocalDateTime now = LocalDateTime.now();
        List<NotifyMessage> messages = new ArrayList<>();

        String templateId = getWeChatTemplateId(msgType);
        String failReason = null;

        if (weChatSubscribeMessageService == null) {
            failReason = "WeChatSubscribeMessageService not available";
        } else if (templateId == null || templateId.isEmpty()) {
            failReason = "Template not found for type: " + msgType;
        }

        if (failReason != null) {
            log.warn("{} , mark batch as failed for retry: count={}", failReason, receiverIds.size());
            for (Long receiverId : receiverIds) {
                NotifyMessage msg = createChannelMessage(senderId, receiverId, title, content, msgType, relatedId, null, extraData, channel);
                msg.setCreatedAt(now);
                msg.setUpdatedAt(now);
                msg.setSendStatus(SendStatus.FAILED);
                msg.setLastError(failReason);
                msg.setNextRetryAt(now.plusMinutes(notificationConfig.getRetry().getInitialDelayMinutes()));
                messages.add(msg);
            }
            notifyMessageRepository.saveAll(messages);
            return;
        }

        boolean success = false;
        String errorMsg = null;
        try {
            Map<String, String> data = weChatSubscribeMessageService.buildTaskNotificationData(
                    title, content, "请打开App查看详情");
            String page = relatedId != null ? "pages/todo/detail?id=" + relatedId : null;
            weChatSubscribeMessageService.sendSubscribeMessageToUsers(receiverIds, templateId, data, page);
            success = true;
            log.info("Batch WeChat subscribe message sent to {} users", receiverIds.size());
        } catch (Exception e) {
            log.error("Failed to send batch WeChat message", e);
            errorMsg = e.getMessage();
        }

        for (Long receiverId : receiverIds) {
            NotifyMessage msg = createChannelMessage(senderId, receiverId, title, content, msgType, relatedId, null, extraData, channel);
            msg.setCreatedAt(now);
            msg.setUpdatedAt(now);
            if (success) {
                msg.setSendStatus(SendStatus.SENT);
                msg.setSentAt(now);
            } else {
                msg.setSendStatus(SendStatus.FAILED);
                msg.setLastError(errorMsg);
                msg.setNextRetryAt(now.plusMinutes(notificationConfig.getRetry().getInitialDelayMinutes()));
            }
            messages.add(msg);
        }
        notifyMessageRepository.saveAll(messages);
    }

    private NotifyMessage createChannelMessage(Long senderId, Long receiverId, String title, String content,
                                               MsgType msgType, Long relatedId, String relatedType,
                                               Map<String, Object> extraData, NotifyChannel channel) {
        NotifyMessage msg = new NotifyMessage();
        msg.setTitle(title);
        msg.setContent(content);
        msg.setMsgType(msgType);
        msg.setChannel(channel);
        msg.setSenderId(senderId);
        msg.setReceiverId(receiverId);
        msg.setRelatedId(relatedId);
        msg.setRelatedType(relatedType);
        msg.setIsRead(false);
        msg.setSendStatus(SendStatus.PENDING);
        msg.setRetryCount(0);
        msg.setMaxRetry(notificationConfig.getRetry().getMaxRetry());
        if (extraData != null && !extraData.isEmpty()) {
            try {
                msg.setExtraData(objectMapper.writeValueAsString(extraData));
            } catch (Exception e) {
                log.warn("Failed to serialize extraData", e);
            }
        }
        return msg;
    }

    private String getWeChatTemplateId(MsgType msgType) {
        if (msgType == null) {
            return notificationConfig.getWeChat().getTemplateId();
        }
        switch (msgType) {
            case SCORE:
                return notificationConfig.getWeChat().getScoreTemplateId();
            case PARENT_REPORT:
            case WEEKLY_REPORT:
            case DAILY_REPORT:
                return notificationConfig.getWeChat().getReportTemplateId();
            case TODO:
            case REMINDER:
            case URGE:
            default:
                String taskTpl = notificationConfig.getWeChat().getTaskTemplateId();
                return taskTpl != null ? taskTpl : notificationConfig.getWeChat().getTemplateId();
        }
    }

    public void sendEmail(String to, String title, String content) {
        if (!notificationConfig.getEmail().isEnabled()) {
            log.warn("Email notification is disabled");
            return;
        }
        log.info("Sending email to: {} with title: {}", to, title);
    }

    public void sendDingTalk(String webhook, String content) {
        if (!notificationConfig.getDingTalk().isEnabled()) {
            log.warn("DingTalk notification is disabled");
            return;
        }
        log.info("Sending DingTalk message");
    }

    public void sendWeChat(String openid, String templateId, Map<String, String> data) {
        if (!notificationConfig.getWeChat().isEnabled()) {
            log.warn("WeChat notification is disabled");
            return;
        }
        if (weChatSubscribeMessageService != null) {
            weChatSubscribeMessageService.sendSubscribeMessage(openid, templateId, data, null);
        }
    }

    public void sendWeComMarkdown(Long schoolId, String reportType, String markdownContent) {
        if (!notificationConfig.getWeCom().isEnabled() || weComBotService == null) {
            log.warn("WeCom notification is disabled");
            return;
        }
        weComBotService.sendMarkdownToSchool(schoolId, reportType, markdownContent);
    }

    public long getUnreadCount(Long userId) {
        return notifyMessageRepository.countByReceiverIdAndIsReadFalseAndDeletedFalse(userId);
    }

    public Map<String, Long> getUnreadCountByType(Long userId) {
        Map<String, Long> result = new HashMap<>();
        for (MsgType type : MsgType.values()) {
            long count = notifyMessageRepository.countByReceiverIdAndMsgTypeAndIsReadFalseAndDeletedFalse(userId, type);
            result.put(type.name(), count);
        }
        return result;
    }

    public Page<NotifyMessageDTO> getMessages(Long userId, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<NotifyMessage> messagePage = notifyMessageRepository.findByReceiverIdAndDeletedFalse(userId, pageable);
        return messagePage.map(this::enrichDTO);
    }

    public Page<NotifyMessageDTO> getMessagesByType(Long userId, MsgType msgType, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<NotifyMessage> messagePage = notifyMessageRepository.findByReceiverIdAndMsgTypeAndDeletedFalse(userId, msgType, pageable);
        return messagePage.map(this::enrichDTO);
    }

    private NotifyMessageDTO enrichDTO(NotifyMessage m) {
        NotifyMessageDTO dto = NotifyMessageDTO.fromEntity(m);
        if (m.getSenderId() != null) {
            userRepository.findById(m.getSenderId()).ifPresent(u -> {
                String name = u.getRealName() != null ? u.getRealName() : u.getNickname();
                dto.setSenderName(name);
            });
        }
        return dto;
    }

    @Transactional
    public void markAsRead(Long messageId, Long userId) {
        NotifyMessage message = notifyMessageRepository.findById(messageId)
                .orElseThrow(() -> new BusinessException("Message not found"));
        if (!message.getReceiverId().equals(userId)) {
            throw new BusinessException("You can only mark your own messages as read");
        }
        message.setIsRead(true);
        message.setReadAt(LocalDateTime.now());
        notifyMessageRepository.save(message);
    }

    @Transactional
    public void markAllAsRead(Long userId) {
        List<NotifyMessage> unreadMessages =
                notifyMessageRepository.findByReceiverIdAndIsReadFalseAndDeletedFalse(userId);
        LocalDateTime now = LocalDateTime.now();
        for (NotifyMessage message : unreadMessages) {
            message.setIsRead(true);
            message.setReadAt(now);
        }
        notifyMessageRepository.saveAll(unreadMessages);
    }
}
