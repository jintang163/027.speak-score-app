package com.speak.score.config;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.JavaMailSenderImpl;

import java.util.Properties;

@Configuration
@RequiredArgsConstructor
public class MailConfig {

    private final NotificationConfig notificationConfig;

    @Bean
    public JavaMailSender javaMailSender() {
        NotificationConfig.Email emailConfig = notificationConfig.getEmail();
        JavaMailSenderImpl mailSender = new JavaMailSenderImpl();
        mailSender.setHost(emailConfig.getHost());
        mailSender.setPort(Integer.parseInt(emailConfig.getPort()));
        mailSender.setUsername(emailConfig.getUsername());
        mailSender.setPassword(emailConfig.getPassword());

        Properties props = mailSender.getJavaMailProperties();
        props.put("mail.transport.protocol", "smtp");
        props.put("mail.smtp.auth", "true");
        props.put("mail.smtp.starttls.enable", "true");
        if (emailConfig.isSsl()) {
            props.put("mail.smtp.ssl.enable", "true");
        }
        props.put("mail.debug", "false");

        return mailSender;
    }
}
