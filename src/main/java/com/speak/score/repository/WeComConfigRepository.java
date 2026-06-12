package com.speak.score.repository;

import com.speak.score.entity.WeComConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface WeComConfigRepository extends JpaRepository<WeComConfig, Long> {

    List<WeComConfig> findBySchoolIdAndDeletedFalse(Long schoolId);

    List<WeComConfig> findBySchoolIdAndReportTypeAndEnabledTrueAndDeletedFalse(Long schoolId, String reportType);

    List<WeComConfig> findByEnabledTrueAndDeletedFalse();
}
