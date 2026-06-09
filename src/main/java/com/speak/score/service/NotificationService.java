package com.speak.score.service;

import com.speak.score.config.NotificationConfig;
import com.speak.score.dto.NotifyMessageDTO;
import com.speak.score.entity.MsgType;
import com.speak.score.entity.NotifyChannel;
import com.speak.score.entity.NotifyChannelConfig;
import com.speak.score.entity.NotifyMessage;
import com.speak.score.exception.BusinessException;
import com.speak.score.repository.NotifyChannelConfigRepository;
import com.speak.score.repository.NotifyMessageRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotifyMessageRepository notifyMessageRepository;
    private final NotifyChannelConfigRepository notifyChannelConfigRepository;
    private final NotificationConfig notificationConfig;

    public void sendNotification(Long senderId, Long receiverId, String title, String content,
                                 MsgType msgType, Long relatedId, String relatedType) {
        List<NotifyChannelConfig> enabledChannels =
                notifyChannelConfigRepository.findByUserIdAndEnabledTrueAndDeletedFalse(receiverId);

        NotifyMessage inAppMsg = new NotifyMessage();
        inAppMsg.setTitle(title);
        inAppMsg.setContent(content);
        inAppMsg.setMsgType(msgType);
        inAppMsg.setChannel(NotifyChannel.IN_APP);
        inAppMsg.setSenderId(senderId);
        inAppMsg.setReceiverId(receiverId);
        inAppMsg.setRelatedId(relatedId);
        inAppMsg.setRelatedType(relatedType);
        inAppMsg.setIsRead(false);
        notifyMessageRepository.save(inAppMsg);

        for (NotifyChannelConfig channelConfig : enabledChannels) {
            if (channelConfig.getChannel() == NotifyChannel.EMAIL) {
                sendEmail(channelConfig.getChannelValue(), title, content);
            } else if (channelConfig.getChannel() == NotifyChannel.DINGTALK) {
                sendDingTalk(channelConfig.getChannelValue(), content);
            } else if (channelConfig.getChannel() == NotifyChannel.WECHAT) {
                sendWeChat(channelConfig.getChannelValue(), notificationConfig.getWeChat().getTemplateId(), null);
            }
        }
    }

    public void sendBatchNotification(Long senderId, List<Long> receiverIds, String title, String content,
                                      MsgType msgType, Long relatedId, String relatedType) {
        for (Long receiverId : receiverIds) {
            sendNotification(senderId, receiverId, title, content, msgType, relatedId, relatedType);
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
        log.info("Sending WeChat template message");
    }

    public long getUnreadCount(Long userId) {
        return notifyMessageRepository.countByReceiverIdAndIsReadFalseAndDeletedFalse(userId);
    }

    public Page<NotifyMessageDTO> getMessages(Long userId, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<NotifyMessage> messagePage = notifyMessageRepository.findByReceiverIdAndDeletedFalse(userId, pageable);
        return messagePage.map(NotifyMessageDTO::fromEntity);
    }

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
