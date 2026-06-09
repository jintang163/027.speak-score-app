package com.speak.score.service;

import com.aliyun.oss.OSS;
import com.aliyun.oss.OSSClientBuilder;
import com.aliyun.oss.model.ObjectMetadata;
import com.speak.score.config.OssConfig;
import com.speak.score.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.net.URL;
import java.util.Date;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class OssService {

    private final OssConfig ossConfig;

    public String uploadFile(MultipartFile file, String directory) {
        OSS ossClient = null;
        try {
            ossClient = new OSSClientBuilder().build(
                    ossConfig.getEndpoint(),
                    ossConfig.getAccessKeyId(),
                    ossConfig.getAccessKeySecret());

            String originalFilename = file.getOriginalFilename();
            String key = directory + "/" + UUID.randomUUID().toString() + "_" + originalFilename;

            ObjectMetadata metadata = new ObjectMetadata();
            metadata.setContentType(file.getContentType());
            metadata.setContentLength(file.getSize());

            ossClient.putObject(ossConfig.getBucketName(), key, file.getInputStream(), metadata);

            String url = ossConfig.getCustomDomain() + "/" + key;
            log.info("File uploaded to OSS: {}", url);
            return url;
        } catch (Exception e) {
            log.error("Failed to upload file to OSS", e);
            throw new BusinessException("Failed to upload file: " + e.getMessage());
        } finally {
            if (ossClient != null) {
                ossClient.shutdown();
            }
        }
    }

    public void deleteFile(String fileUrl) {
        OSS ossClient = null;
        try {
            ossClient = new OSSClientBuilder().build(
                    ossConfig.getEndpoint(),
                    ossConfig.getAccessKeyId(),
                    ossConfig.getAccessKeySecret());

            String key = extractKeyFromUrl(fileUrl);
            ossClient.deleteObject(ossConfig.getBucketName(), key);
            log.info("File deleted from OSS: {}", key);
        } catch (Exception e) {
            log.error("Failed to delete file from OSS", e);
            throw new BusinessException("Failed to delete file: " + e.getMessage());
        } finally {
            if (ossClient != null) {
                ossClient.shutdown();
            }
        }
    }

    public String generatePresignedUrl(String fileUrl, int expirationMinutes) {
        OSS ossClient = null;
        try {
            ossClient = new OSSClientBuilder().build(
                    ossConfig.getEndpoint(),
                    ossConfig.getAccessKeyId(),
                    ossConfig.getAccessKeySecret());

            String key = extractKeyFromUrl(fileUrl);
            Date expiration = new Date(System.currentTimeMillis() + (long) expirationMinutes * 60 * 1000);
            URL url = ossClient.generatePresignedUrl(ossConfig.getBucketName(), key, expiration);
            return url.toString();
        } catch (Exception e) {
            log.error("Failed to generate presigned URL", e);
            throw new BusinessException("Failed to generate presigned URL: " + e.getMessage());
        } finally {
            if (ossClient != null) {
                ossClient.shutdown();
            }
        }
    }

    private String extractKeyFromUrl(String fileUrl) {
        String domain = ossConfig.getCustomDomain();
        if (fileUrl != null && fileUrl.startsWith(domain)) {
            return fileUrl.substring(domain.length() + 1);
        }
        throw new BusinessException("Invalid file URL");
    }
}
