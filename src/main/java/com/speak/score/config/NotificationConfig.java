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
    private Reminder reminder = new Reminder();

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
    }

    @Data
    public static class Reminder {
        private String cron = "0 */5 * * * *";
        private int advanceMinutes = 30;
    }
}
