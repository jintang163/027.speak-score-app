package com.speak.score.repository;

import com.speak.score.entity.ReviewLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ReviewLogRepository extends JpaRepository<ReviewLog, Long> {

    List<ReviewLog> findByMaterialIdAndDeletedFalse(Long materialId);

    List<ReviewLog> findByReviewerIdAndDeletedFalse(Long reviewerId);
}
