package com.speak.score.repository;

import com.speak.score.entity.NotifyChannel;
import com.speak.score.entity.NotifyChannelConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface NotifyChannelConfigRepository extends JpaRepository<NotifyChannelConfig, Long> {

    List<NotifyChannelConfig> findByUserIdAndEnabledTrueAndDeletedFalse(Long userId);

    Optional<NotifyChannelConfig> findByUserIdAndChannelAndDeletedFalse(Long userId, NotifyChannel channel);
}
