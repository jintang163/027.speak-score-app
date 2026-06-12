package com.speak.score.repository;

import com.speak.score.entity.MsgType;
import com.speak.score.entity.NotifyMessage;
import com.speak.score.entity.SendStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface NotifyMessageRepository extends JpaRepository<NotifyMessage, Long> {

    List<NotifyMessage> findByReceiverIdAndIsReadFalseAndDeletedFalse(Long receiverId);

    Page<NotifyMessage> findByReceiverIdAndDeletedFalse(Long receiverId, Pageable pageable);

    Page<NotifyMessage> findByReceiverIdAndMsgTypeAndDeletedFalse(Long receiverId, MsgType msgType, Pageable pageable);

    long countByReceiverIdAndIsReadFalseAndDeletedFalse(Long receiverId);

    long countByReceiverIdAndMsgTypeAndIsReadFalseAndDeletedFalse(Long receiverId, MsgType msgType);

    List<NotifyMessage> findByReceiverIdAndMsgTypeAndIsReadFalseAndDeletedFalse(Long receiverId, MsgType msgType);

    List<NotifyMessage> findBySendStatusInAndDeletedFalse(List<SendStatus> statuses);

    List<NotifyMessage> findBySendStatusAndNextRetryAtBeforeAndDeletedFalse(SendStatus sendStatus, LocalDateTime nextRetryAt);

    List<NotifyMessage> findByChannelAndSendStatusInAndDeletedFalse(String channel, List<SendStatus> statuses);

    List<NotifyMessage> findBySendStatusInAndNextRetryAtBeforeAndDeletedFalse(List<SendStatus> statuses, LocalDateTime nextRetryAt);
}
