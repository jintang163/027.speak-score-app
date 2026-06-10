package com.speak.score.service;

import com.speak.score.config.NotificationConfig;
import com.speak.score.config.WeChatConfig;
import com.speak.score.entity.User;
import com.speak.score.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import me.chanjar.weixin.common.error.WxErrorException;
import me.chanjar.weixin.mp.api.WxMpService;
import me.chanjar.weixin.mp.api.impl.WxMpServiceImpl;
import me.chanjar.weixin.mp.bean.template.WxMpSubscribeMessage;
import me.chanjar.weixin.mp.config.impl.WxMpDefaultConfigImpl;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

import javax.annotation.PostConstruct;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@ConditionalOnProperty(name = "notification.wechat.enabled", havingValue = "true")
public class WeChatSubscribeMessageService {

    private final WeChatConfig weChatConfig;
    private final NotificationConfig notificationConfig;
    private final UserRepository userRepository;

    private WxMpService wxMpService;

    @PostConstruct
    public void init() {
        WxMpDefaultConfigImpl config = new WxMpDefaultConfigImpl();
        config.setAppId(weChatConfig.getAppId());
        config.setSecret(weChatConfig.getAppSecret());
        wxMpService = new WxMpServiceImpl();
        wxMpService.setWxMpConfigStorage(config);
    }

    public void sendSubscribeMessage(String openid, String templateId,
                                     Map<String, String> data, String page) {
        try {
            WxMpSubscribeMessage message = WxMpSubscribeMessage.builder()
                    .toUser(openid)
                    .templateId(templateId)
                    .page(page)
                    .build();

            for (Map.Entry<String, String> entry : data.entrySet()) {
                message.addData(new WxMpSubscribeMessage.Data(entry.getKey(), entry.getValue(), "#000000"));
            }

            wxMpService.getMsgService().sendSubscribeMsg(message);
            log.info("WeChat subscribe message sent to openid={}", openid);
        } catch (WxErrorException e) {
            log.error("Failed to send WeChat subscribe message to openid={}, errcode={}, errmsg={}",
                    openid, e.getError().getErrorCode(), e.getError().getErrorMsg());
        }
    }

    public void sendBatchSubscribeMessage(List<String> openids, String templateId,
                                          Map<String, String> data, String page) {
        for (String openid : openids) {
            sendSubscribeMessage(openid, templateId, data, page);
        }
    }

    public void sendSubscribeMessageToUsers(List<Long> userIds, String templateId,
                                            Map<String, String> data, String page) {
        List<User> users = userRepository.findAllById(userIds).stream()
                .filter(u -> !u.getDeleted())
                .filter(u -> u.getWechatOpenid() != null && !u.getWechatOpenid().isEmpty())
                .collect(Collectors.toList());

        if (users.isEmpty()) {
            log.warn("No users with WeChat openid found for userIds: {}", userIds);
            return;
        }

        List<String> openids = users.stream()
                .map(User::getWechatOpenid)
                .collect(Collectors.toList());
        log.info("Sending WeChat subscribe message to {} users with openid", openids.size());
        sendBatchSubscribeMessage(openids, templateId, data, page);
    }

    public Map<String, String> buildTaskNotificationData(String title, String content, String remark) {
        Map<String, String> data = new LinkedHashMap<>();
        data.put("thing1", truncate(title, 20));
        data.put("thing2", truncate(content != null ? content : "您有新的打卡任务", 20));
        data.put("thing3", truncate(remark, 20));
        return data;
    }

    private String truncate(String text, int maxLen) {
        if (text == null) return "";
        return text.length() > maxLen ? text.substring(0, maxLen) : text;
    }
}
