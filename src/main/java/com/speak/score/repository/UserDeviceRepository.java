package com.speak.score.repository;

import com.speak.score.entity.UserDevice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserDeviceRepository extends JpaRepository<UserDevice, Long> {

    Optional<UserDevice> findByUserIdAndDeviceTypeAndDeletedFalse(Long userId, String deviceType);

    List<UserDevice> findByUserIdInAndDeviceTypeAndDeletedFalse(List<Long> userIds, String deviceType);

    List<UserDevice> findByDeviceTypeAndDeletedFalse(String deviceType);

    List<UserDevice> findByUserIdAndDeletedFalse(Long userId);
}
