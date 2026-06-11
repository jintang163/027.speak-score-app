package com.speak.score.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class RankingScheduler {

    private final RankingService rankingService;

    @Scheduled(cron = "0 0 2 * * ?")
    public void refreshAllRankings() {
        log.info("Starting scheduled ranking refresh...");
        long start = System.currentTimeMillis();
        try {
            rankingService.refreshAllRankings();
            long cost = System.currentTimeMillis() - start;
            log.info("Scheduled ranking refresh completed in {}ms", cost);
        } catch (Exception e) {
            log.error("Scheduled ranking refresh failed", e);
        }
    }
}
