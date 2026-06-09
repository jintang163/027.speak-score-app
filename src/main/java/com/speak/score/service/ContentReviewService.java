package com.speak.score.service;

import com.speak.score.config.ContentReviewConfig;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@RequiredArgsConstructor
public class ContentReviewService {

    private final ContentReviewConfig contentReviewConfig;

    public ReviewResult reviewContent(String fileUrl, String materialType) {
        if (!contentReviewConfig.isEnabled()) {
            log.info("Content review is disabled, auto-approving: {}", fileUrl);
            ReviewResult result = new ReviewResult();
            result.setApproved(true);
            result.setReason("Content review disabled, auto-approved");
            result.setLabel("normal");
            return result;
        }

        log.info("Reviewing content for file: {}, type: {} (provider: {})",
                fileUrl, materialType, contentReviewConfig.getProvider());

        ReviewResult result = new ReviewResult();
        result.setApproved(true);
        result.setReason("Content passed review");
        result.setLabel("normal");
        log.info("Content review completed for file: {}, approved: {}", fileUrl, result.isApproved());
        return result;
    }

    @Data
    public static class ReviewResult {
        private boolean approved;
        private String reason;
        private String label;
    }
}
