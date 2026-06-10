package com.speak.score.repository;

import com.speak.score.entity.SpeechScoreDetail;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SpeechScoreDetailRepository extends JpaRepository<SpeechScoreDetail, Long> {

    Optional<SpeechScoreDetail> findTopByItemIdOrderByScoredAtDesc(Long itemId);

    List<SpeechScoreDetail> findByItemIdOrderByScoredAtDesc(Long itemId);
}
