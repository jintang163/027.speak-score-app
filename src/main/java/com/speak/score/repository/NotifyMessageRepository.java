package com.speak.score.repository;

import com.speak.score.entity.MsgType;
import com.speak.score.entity.NotifyMessage;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface NotifyMessageRepository extends JpaRepository<NotifyMessage, Long> {

    List<NotifyMessage> findByReceiverIdAndIsReadFalseAndDeletedFalse(Long receiverId);

    Page<NotifyMessage> findByReceiverIdAndDeletedFalse(Long receiverId, Pageable pageable);

    long countByReceiverIdAndIsReadFalseAndDeletedFalse(Long receiverId);

    List<NotifyMessage> findByReceiverIdAndMsgTypeAndIsReadFalseAndDeletedFalse(Long receiverId, MsgType msgType);
}
