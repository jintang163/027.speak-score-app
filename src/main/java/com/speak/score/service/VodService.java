package com.speak.score.service;

import com.aliyuncs.DefaultAcsClient;
import com.aliyuncs.profile.DefaultProfile;
import com.aliyuncs.vod.model.v20170321.CreateUploadVideoRequest;
import com.aliyuncs.vod.model.v20170321.CreateUploadVideoResponse;
import com.aliyuncs.vod.model.v20170321.GetPlayInfoRequest;
import com.aliyuncs.vod.model.v20170321.GetPlayInfoResponse;
import com.aliyuncs.vod.model.v20170321.GetVideoInfoRequest;
import com.aliyuncs.vod.model.v20170321.GetVideoInfoResponse;
import com.aliyuncs.vod.model.v20170321.DeleteVideoRequest;
import com.speak.score.config.VodConfig;
import com.speak.score.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Slf4j
@Service
@RequiredArgsConstructor
public class VodService {

    private final VodConfig vodConfig;

    public String uploadVideo(MultipartFile file) {
        if (vodConfig.getAccessKeyId() == null || vodConfig.getAccessKeyId().isEmpty()) {
            log.warn("VOD accessKeyId is not configured, returning mock videoId");
            return "mock-video-" + System.currentTimeMillis();
        }

        DefaultAcsClient client = createClient();
        try {
            CreateUploadVideoRequest request = new CreateUploadVideoRequest();
            request.setTitle(file.getOriginalFilename());
            request.setFileName(file.getOriginalFilename());

            CreateUploadVideoResponse response = client.getAcsResponse(request);
            log.info("Video upload created in VOD, videoId: {}", response.getVideoId());
            return response.getVideoId();
        } catch (Exception e) {
            log.error("Failed to create video upload in VOD", e);
            throw new BusinessException("Failed to upload video: " + e.getMessage());
        }
    }

    public void triggerTranscode(String videoId) {
        if (vodConfig.getAccessKeyId() == null || vodConfig.getAccessKeyId().isEmpty()) {
            log.warn("VOD accessKeyId is not configured, skipping transcode for video: {}", videoId);
            return;
        }

        log.info("Transcode will be triggered automatically by VOD for video: {} with templateGroupId: {}",
                videoId, vodConfig.getTemplateGroupId());
    }

    public String getPlayUrl(String videoId) {
        if (vodConfig.getAccessKeyId() == null || vodConfig.getAccessKeyId().isEmpty()) {
            log.warn("VOD accessKeyId is not configured, returning mock play URL for video: {}", videoId);
            return "https://mock-vod.example.com/" + videoId + "/master.m3u8";
        }

        DefaultAcsClient client = createClient();
        try {
            GetPlayInfoRequest request = new GetPlayInfoRequest();
            request.setVideoId(videoId);

            GetPlayInfoResponse response = client.getAcsResponse(request);
            if (response.getPlayInfoList() != null
                    && response.getPlayInfoList().size() > 0
                    && response.getPlayInfoList().get(0).getPlayURL() != null) {
                return response.getPlayInfoList().get(0).getPlayURL();
            }
            throw new BusinessException("No play URL found for video: " + videoId);
        } catch (BusinessException e) {
            throw e;
        } catch (Exception e) {
            log.error("Failed to get play URL for video: {}", videoId, e);
            throw new BusinessException("Failed to get play URL: " + e.getMessage());
        }
    }

    public String getVideoStatus(String videoId) {
        if (vodConfig.getAccessKeyId() == null || vodConfig.getAccessKeyId().isEmpty()) {
            return "Normal";
        }

        DefaultAcsClient client = createClient();
        try {
            GetVideoInfoRequest request = new GetVideoInfoRequest();
            request.setVideoId(videoId);
            GetVideoInfoResponse response = client.getAcsResponse(request);
            if (response.getVideo() != null) {
                return response.getVideo().getStatus();
            }
            return "Unknown";
        } catch (Exception e) {
            log.error("Failed to get video status: {}", videoId, e);
            return "Unknown";
        }
    }

    public void deleteVideo(String videoId) {
        if (vodConfig.getAccessKeyId() == null || vodConfig.getAccessKeyId().isEmpty()) {
            log.warn("VOD accessKeyId is not configured, skipping delete for video: {}", videoId);
            return;
        }

        DefaultAcsClient client = createClient();
        try {
            DeleteVideoRequest request = new DeleteVideoRequest();
            request.setVideoIds(videoId);

            client.getAcsResponse(request);
            log.info("Video deleted from VOD: {}", videoId);
        } catch (Exception e) {
            log.error("Failed to delete video from VOD: {}", videoId, e);
            throw new BusinessException("Failed to delete video: " + e.getMessage());
        }
    }

    private DefaultAcsClient createClient() {
        DefaultProfile profile = DefaultProfile.getProfile(
                vodConfig.getRegionId(),
                vodConfig.getAccessKeyId(),
                vodConfig.getAccessKeySecret());
        return new DefaultAcsClient(profile);
    }
}
