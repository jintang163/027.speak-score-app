package com.speak.score.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Data
@Configuration
@ConfigurationProperties(prefix = "rocketmq")
public class RocketMQConfig {

    private String nameServer = "localhost:9876";
    private String producerGroup = "speak-score-producer";
    private String todoTaskTopic = "todo-task-topic";
    private String todoTaskTag = "todo-task";
    private String pushTag = "push";
    private String wechatTag = "wechat";
    private String scoringTag = "scoring";
}
