package com.speak.score.dto;

import com.speak.score.entity.Material;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.time.format.DateTimeFormatter;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class MaterialDTO {

    private Long id;
    private String title;
    private String description;
    private String materialType;
    private String fileUrl;
    private Long fileSize;
    private String fileName;
    private String mimeType;
    private String coverUrl;
    private Integer duration;
    private String hlsUrl;
    private String videoId;
    private String transcodeStatus;
    private String reviewStatus;
    private String reviewComment;
    private String scope;
    private Long uploaderId;
    private String uploaderName;
    private Long schoolId;
    private String schoolName;
    private Long classId;
    private String className;
    private Integer gradeLevel;
    private Integer viewCount;
    private Integer downloadCount;
    private List<TagDTO> tags;
    private String createdAt;

    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    public static MaterialDTO fromEntity(Material m) {
        if (m == null) {
            return null;
        }
        MaterialDTO dto = new MaterialDTO();
        dto.setId(m.getId());
        dto.setTitle(m.getTitle());
        dto.setDescription(m.getDescription());
        dto.setMaterialType(m.getMaterialType() != null ? m.getMaterialType().name() : null);
        dto.setFileUrl(m.getFileUrl());
        dto.setFileSize(m.getFileSize());
        dto.setFileName(m.getFileName());
        dto.setMimeType(m.getMimeType());
        dto.setCoverUrl(m.getCoverUrl());
        dto.setDuration(m.getDuration());
        dto.setHlsUrl(m.getHlsUrl());
        dto.setVideoId(m.getVideoId());
        dto.setTranscodeStatus(m.getTranscodeStatus() != null ? m.getTranscodeStatus().name() : null);
        dto.setReviewStatus(m.getReviewStatus() != null ? m.getReviewStatus().name() : null);
        dto.setReviewComment(m.getReviewComment());
        dto.setScope(m.getScope());
        dto.setUploaderId(m.getUploaderId());
        dto.setSchoolId(m.getSchoolId());
        dto.setClassId(m.getClassId());
        dto.setGradeLevel(m.getGradeLevel());
        dto.setViewCount(m.getViewCount());
        dto.setDownloadCount(m.getDownloadCount());
        dto.setTags(m.getTags() != null
                ? m.getTags().stream().map(TagDTO::fromEntity).collect(Collectors.toList())
                : Collections.<TagDTO>emptyList());
        dto.setCreatedAt(m.getCreatedAt() != null ? m.getCreatedAt().format(FORMATTER) : null);
        return dto;
    }
}
