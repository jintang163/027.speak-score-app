package com.speak.score.repository;

import com.speak.score.entity.SmsCode;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface SmsCodeRepository extends JpaRepository<SmsCode, Long> {

    @Query("SELECT s FROM SmsCode s WHERE s.phone = :phone AND s.used = false AND s.expired = false ORDER BY s.createdAt DESC LIMIT 1")
    Optional<SmsCode> findLatestValidByPhone(String phone);
}
