package com.speak.score.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Data
@Configuration
@ConfigurationProperties(prefix = "notification")
public class NotificationConfig {

    private Email email = new Email();
    private DingTalk dingTalk = new DingTalk();
    private WeChat weChat = new WeChat();
    private WeCom weCom = new WeCom();
    private Reminder reminder = new Reminder();
    private Retry retry = new Retry();

    @Data
    public static class Email {
        private boolean enabled = false;
        private String host;
        private String port;
        private String username;
        private String password;
        private String from;
        private boolean ssl = false;
    }

    @Data
    public static class DingTalk {
        private boolean enabled = false;
        private String webhook;
        private String secret;
    }

    @Data
    public static class WeChat {
        private boolean enabled = false;
        private String templateId;
        private String taskTemplateId;
        private String scoreTemplateId;
        private String reportTemplateId;
    }

    @Data
    public static class WeCom {
        private boolean enabled = false;
        private String dailyReportCron = "0 0 18 * * ?";
        private String weeklyReportCron = "0 0 18 ? * MON";
    }

    @Data
    public static class Reminder {
        private String cron = "0 */5 * * * *";
        private int advanceMinutes = 120;
    }

    @Data
    public static class Retry {
        private boolean enabled = true;
        private String cron = "0 */10 * * * *";
        private int maxRetry = 3;
        private int initialDelayMinutes = 1;
        private int backoffMultiplier = 2;
    }
}
