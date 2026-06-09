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
import com.aliyuncs.vod.model.v20170321.RefreshUploadVideoRequest;
import com.aliyuncs.vod.model.v20170321.RefreshUploadVideoResponse;
import com.speak.score.config.VodConfig;
import com.speak.score.dto.VodUploadAuthDTO;
import com.speak.score.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@RequiredArgsConstructor
public class VodService {

    private final VodConfig vodConfig;

    public VodUploadAuthDTO createUploadVideo(String title, String fileName) {
        if (vodConfig.getAccessKeyId() == null || vodConfig.getAccessKeyId().isEmpty()) {
            log.warn("VOD accessKeyId is not configured, returning mock upload auth");
            VodUploadAuthDTO dto = new VodUploadAuthDTO();
            dto.setVideoId("mock-video-" + System.currentTimeMillis());
            dto.setUploadAuth("mock-upload-auth");
            dto.setUploadAddress("mock-upload-address");
            dto.setRequestId("mock-request-id");
            return dto;
        }

        DefaultAcsClient client = createClient();
        try {
            CreateUploadVideoRequest request = new CreateUploadVideoRequest();
            request.setTitle(title);
            request.setFileName(fileName);
            if (vodConfig.getTemplateGroupId() != null && !vodConfig.getTemplateGroupId().isEmpty()) {
                request.setTemplateGroupId(vodConfig.getTemplateGroupId());
            }
            if (vodConfig.getStorageLocation() != null && !vodConfig.getStorageLocation().isEmpty()) {
                request.setStorageLocation(vodConfig.getStorageLocation());
            }

            CreateUploadVideoResponse response = client.getAcsResponse(request);
            log.info("VOD upload auth created: videoId={}, requestId={}",
                    response.getVideoId(), response.getRequestId());

            VodUploadAuthDTO dto = new VodUploadAuthDTO();
            dto.setVideoId(response.getVideoId());
            dto.setUploadAuth(response.getUploadAuth());
            dto.setUploadAddress(response.getUploadAddress());
            dto.setRequestId(response.getRequestId());
            return dto;
        } catch (Exception e) {
            log.error("Failed to create VOD upload auth", e);
            throw new BusinessException("Failed to create video upload credential: " + e.getMessage());
        }
    }

    public VodUploadAuthDTO refreshUploadVideo(String videoId) {
        if (vodConfig.getAccessKeyId() == null || vodConfig.getAccessKeyId().isEmpty()) {
            VodUploadAuthDTO dto = new VodUploadAuthDTO();
            dto.setVideoId(videoId);
            dto.setUploadAuth("mock-refresh-auth");
            dto.setUploadAddress("mock-refresh-address");
            return dto;
        }

        DefaultAcsClient client = createClient();
        try {
            RefreshUploadVideoRequest request = new RefreshUploadVideoRequest();
            request.setVideoId(videoId);

            RefreshUploadVideoResponse response = client.getAcsResponse(request);
            log.info("VOD upload auth refreshed: videoId={}", videoId);

            VodUploadAuthDTO dto = new VodUploadAuthDTO();
            dto.setVideoId(response.getVideoId());
            dto.setUploadAuth(response.getUploadAuth());
            dto.setUploadAddress(response.getUploadAddress());
            dto.setRequestId(response.getRequestId());
            return dto;
        } catch (Exception e) {
            log.error("Failed to refresh VOD upload auth for video: {}", videoId, e);
            throw new BusinessException("Failed to refresh upload credential: " + e.getMessage());
        }
    }

    public String getPlayUrl(String videoId) {
        if (vodConfig.getAccessKeyId() == null || vodConfig.getAccessKeyId().isEmpty()) {
            return "https://mock-vod.example.com/" + videoId + "/master.m3u8";
        }

        DefaultAcsClient client = createClient();
        try {
            GetPlayInfoRequest request = new GetPlayInfoRequest();
            request.setVideoId(videoId);

            GetPlayInfoResponse response = client.getAcsResponse(request);
            if (response.getPlayInfoList() != null
                    && response.getPlayInfoList().size() > 0) {
                for (GetPlayInfoResponse.PlayInfo playInfo : response.getPlayInfoList()) {
                    if (playInfo.getPlayURL() != null
                            && playInfo.getFormat() != null
                            && playInfo.getFormat().contains("m3u8")) {
                        return playInfo.getPlayURL();
                    }
                }
                if (response.getPlayInfoList().get(0).getPlayURL() != null) {
                    return response.getPlayInfoList().get(0).getPlayURL();
                }
            }
            throw new BusinessException("No play URL found for video: " + videoId);
        } catch (BusinessException e) {
            throw e;
        } catch (Exception e) {
            log.error("Failed to get play URL for video: {}", videoId, e);
            throw new BusinessException("Failed to get play URL: " + e.getMessage());
        }
    }

    public VideoInfo getVideoInfo(String videoId) {
        if (vodConfig.getAccessKeyId() == null || vodConfig.getAccessKeyId().isEmpty()) {
            VideoInfo info = new VideoInfo();
            info.setVideoId(videoId);
            info.setStatus("Normal");
            info.setDuration(0.0f);
            return info;
        }

        DefaultAcsClient client = createClient();
        try {
            GetVideoInfoRequest request = new GetVideoInfoRequest();
            request.setVideoId(videoId);
            GetVideoInfoResponse response = client.getAcsResponse(request);

            VideoInfo info = new VideoInfo();
            info.setVideoId(videoId);
            if (response.getVideo() != null) {
                info.setStatus(response.getVideo().getStatus());
                info.setDuration(response.getVideo().getDuration());
                info.setCoverURL(response.getVideo().getCoverURL());
                if ("Normal".equals(response.getVideo().getStatus())) {
                    info.setTranscodeStatus("TranscodeSuccess");
                } else if ("Processing".equals(response.getVideo().getStatus())) {
                    info.setTranscodeStatus("Transcoding");
                } else if ("UploadFail".equals(response.getVideo().getStatus())) {
                    info.setTranscodeStatus("TranscodeFail");
                }
            }
            return info;
        } catch (Exception e) {
            log.error("Failed to get video info: {}", videoId, e);
            VideoInfo info = new VideoInfo();
            info.setVideoId(videoId);
            info.setStatus("Unknown");
            return info;
        }
    }

    public void deleteVideo(String videoId) {
        if (vodConfig.getAccessKeyId() == null || vodConfig.getAccessKeyId().isEmpty()) {
            log.warn("VOD not configured, skipping delete for video: {}", videoId);
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

    public static class VideoInfo {
        private String videoId;
        private String status;
        private Float duration;
        private String coverURL;
        private String transcodeStatus;

        public String getVideoId() { return videoId; }
        public void setVideoId(String videoId) { this.videoId = videoId; }
        public String getStatus() { return status; }
        public void setStatus(String status) { this.status = status; }
        public Float getDuration() { return duration; }
        public void setDuration(Float duration) { this.duration = duration; }
        public String getCoverURL() { return coverURL; }
        public void setCoverURL(String coverURL) { this.coverURL = coverURL; }
        public String getTranscodeStatus() { return transcodeStatus; }
        public void setTranscodeStatus(String transcodeStatus) { this.transcodeStatus = transcodeStatus; }
    }
}
