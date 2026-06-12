package com.speak.score.dto;

import com.speak.score.entity.NotifyMessage;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.time.format.DateTimeFormatter;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class NotifyMessageDTO {

    private Long id;
    private String title;
    private String content;
    private String msgType;
    private String channel;
    private Long senderId;
    private String senderName;
    private Long receiverId;
    private Long relatedId;
    private String relatedType;
    private Boolean isRead;
    private String readAt;
    private String createdAt;
    private String sendStatus;
    private Integer retryCount;
    private String sentAt;
    private String extraData;

    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    public static NotifyMessageDTO fromEntity(NotifyMessage m) {
        if (m == null) {
            return null;
        }
        NotifyMessageDTO dto = new NotifyMessageDTO();
        dto.setId(m.getId());
        dto.setTitle(m.getTitle());
        dto.setContent(m.getContent());
        dto.setMsgType(m.getMsgType() != null ? m.getMsgType().name() : null);
        dto.setChannel(m.getChannel() != null ? m.getChannel().name() : null);
        dto.setSenderId(m.getSenderId());
        dto.setSenderName(null);
        dto.setReceiverId(m.getReceiverId());
        dto.setRelatedId(m.getRelatedId());
        dto.setRelatedType(m.getRelatedType());
        dto.setIsRead(m.getIsRead());
        dto.setReadAt(m.getReadAt() != null ? m.getReadAt().format(FORMATTER) : null);
        dto.setCreatedAt(m.getCreatedAt() != null ? m.getCreatedAt().format(FORMATTER) : null);
        dto.setSendStatus(m.getSendStatus() != null ? m.getSendStatus().name() : null);
        dto.setRetryCount(m.getRetryCount());
        dto.setSentAt(m.getSentAt() != null ? m.getSentAt().format(FORMATTER) : null);
        dto.setExtraData(m.getExtraData());
        return dto;
    }
}
