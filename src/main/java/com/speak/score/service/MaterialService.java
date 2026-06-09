package com.speak.score.service;

import com.speak.score.dto.MaterialDTO;
import com.speak.score.dto.MaterialSearchRequest;
import com.speak.score.dto.MaterialUpdateRequest;
import com.speak.score.dto.MaterialUploadRequest;
import com.speak.score.dto.ReviewActionRequest;
import com.speak.score.dto.TagDTO;
import com.speak.score.dto.VodUploadAuthDTO;
import com.speak.score.entity.Material;
import com.speak.score.entity.MaterialTag;
import com.speak.score.entity.MaterialType;
import com.speak.score.entity.ReviewLog;
import com.speak.score.entity.ReviewStatus;
import com.speak.score.entity.RoleEnum;
import com.speak.score.entity.TranscodeStatus;
import com.speak.score.entity.User;
import com.speak.score.exception.BusinessException;
import com.speak.score.repository.MaterialRepository;
import com.speak.score.repository.MaterialTagRepository;
import com.speak.score.repository.ReviewLogRepository;
import com.speak.score.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class MaterialService {

    private static final long VIDEO_MAX_SIZE = 500L * 1024 * 1024;
    private static final long OTHER_MAX_SIZE = 50L * 1024 * 1024;

    private final MaterialRepository materialRepository;
    private final MaterialTagRepository materialTagRepository;
    private final ReviewLogRepository reviewLogRepository;
    private final OssService ossService;
    private final VodService vodService;
    private final ContentReviewService contentReviewService;
    private final UserRepository userRepository;

    @Transactional
    public MaterialDTO uploadMaterial(Long userId, MaterialUploadRequest request, MultipartFile file) {
        MaterialType materialType;
        try {
            materialType = MaterialType.valueOf(request.getMaterialType());
        } catch (IllegalArgumentException e) {
            throw new BusinessException("Invalid material type: " + request.getMaterialType());
        }

        long maxSize = materialType == MaterialType.VIDEO ? VIDEO_MAX_SIZE : OTHER_MAX_SIZE;
        if (file.getSize() > maxSize) {
            throw new BusinessException("File size exceeds the limit of " + (maxSize / 1024 / 1024) + "MB");
        }

        String directory = "materials/" + materialType.name().toLowerCase();
        String fileUrl = ossService.uploadFile(file, directory);

        String videoId = null;
        TranscodeStatus transcodeStatus = TranscodeStatus.NONE;

        if (materialType == MaterialType.VIDEO) {
            VodUploadAuthDTO uploadAuth = vodService.createUploadVideo(
                    request.getTitle(), file.getOriginalFilename());
            videoId = uploadAuth.getVideoId();
            transcodeStatus = TranscodeStatus.PENDING;
        }

        ContentReviewService.ReviewResult reviewResult = contentReviewService.reviewContent(fileUrl, materialType.name());

        Material material = new Material();
        material.setTitle(request.getTitle());
        material.setDescription(request.getDescription());
        material.setMaterialType(materialType);
        material.setFileUrl(fileUrl);
        material.setFileSize(file.getSize());
        material.setFileName(file.getOriginalFilename());
        material.setMimeType(file.getContentType());
        material.setScope(request.getScope());
        material.setUploaderId(userId);
        material.setSchoolId(request.getSchoolId());
        material.setClassId(request.getClassId());
        material.setGradeLevel(request.getGradeLevel());
        material.setVideoId(videoId);
        material.setTranscodeStatus(transcodeStatus);

        if (!reviewResult.isApproved()) {
            material.setReviewStatus(ReviewStatus.REJECTED);
            material.setReviewComment(reviewResult.getReason());
        }

        if (request.getTagIds() != null && !request.getTagIds().isEmpty()) {
            List<MaterialTag> tags = materialTagRepository.findAllById(request.getTagIds());
            material.setTags(tags);
        }

        Material savedMaterial = materialRepository.save(material);
        log.info("Material uploaded: id={}, type={}, uploaderId={}, videoId={}",
                savedMaterial.getId(), materialType, userId, videoId);
        return MaterialDTO.fromEntity(savedMaterial);
    }

    public VodUploadAuthDTO getVideoUploadAuth(Long materialId) {
        Material material = materialRepository.findById(materialId)
                .orElseThrow(() -> new BusinessException("Material not found"));
        if (material.getMaterialType() != MaterialType.VIDEO) {
            throw new BusinessException("Material is not a video type");
        }
        if (material.getVideoId() == null || material.getVideoId().isEmpty()) {
            throw new BusinessException("Video has not been registered with VOD");
        }
        return vodService.refreshUploadVideo(material.getVideoId());
    }

    @Transactional
    public MaterialDTO updateMaterial(Long materialId, Long userId, MaterialUpdateRequest request) {
        Material material = materialRepository.findById(materialId)
                .orElseThrow(() -> new BusinessException("Material not found"));

        if (!material.getUploaderId().equals(userId)) {
            throw new BusinessException("Only the uploader can update this material");
        }

        if (request.getTitle() != null) {
            material.setTitle(request.getTitle());
        }
        if (request.getDescription() != null) {
            material.setDescription(request.getDescription());
        }
        if (request.getScope() != null) {
            material.setScope(request.getScope());
        }
        if (request.getGradeLevel() != null) {
            material.setGradeLevel(request.getGradeLevel());
        }
        if (request.getTagIds() != null) {
            List<MaterialTag> tags = materialTagRepository.findAllById(request.getTagIds());
            material.setTags(tags);
        }

        Material savedMaterial = materialRepository.save(material);
        return MaterialDTO.fromEntity(savedMaterial);
    }

    @Transactional
    public void deleteMaterial(Long materialId, Long userId) {
        Material material = materialRepository.findById(materialId)
                .orElseThrow(() -> new BusinessException("Material not found"));

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException("User not found"));

        boolean isOwner = material.getUploaderId().equals(userId);
        boolean isEduOffice = user.getRoles().stream()
                .anyMatch(r -> r.getRoleCode() == RoleEnum.EDU_OFFICE);

        if (!isOwner && !isEduOffice) {
            throw new BusinessException("You do not have permission to delete this material");
        }

        material.setDeleted(true);
        materialRepository.save(material);

        try {
            ossService.deleteFile(material.getFileUrl());
        } catch (Exception e) {
            log.warn("Failed to delete file from OSS: {}", material.getFileUrl(), e);
        }

        if (material.getMaterialType() == MaterialType.VIDEO && material.getVideoId() != null) {
            try {
                vodService.deleteVideo(material.getVideoId());
            } catch (Exception e) {
                log.warn("Failed to delete video from VOD: {}", material.getVideoId(), e);
            }
        }
    }

    @Transactional
    public MaterialDTO getMaterialDetail(Long materialId) {
        Material material = materialRepository.findById(materialId)
                .orElseThrow(() -> new BusinessException("Material not found"));

        material.setViewCount(material.getViewCount() + 1);
        Material savedMaterial = materialRepository.save(material);
        return MaterialDTO.fromEntity(savedMaterial);
    }

    public Page<MaterialDTO> searchMaterials(MaterialSearchRequest request, Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException("User not found"));

        boolean isStudent = user.getRoles().stream()
                .anyMatch(r -> r.getRoleCode() == RoleEnum.STUDENT);

        Pageable pageable = PageRequest.of(request.getPage(), request.getSize(),
                Sort.by(Sort.Direction.DESC, "createdAt"));

        ReviewStatus reviewStatus;
        if (isStudent) {
            reviewStatus = ReviewStatus.APPROVED;
        } else {
            reviewStatus = resolveReviewStatus(request.getReviewStatus());
        }

        Page<Material> materialPage;

        if (request.getTagId() != null) {
            materialPage = materialRepository.findByTagIdAndReviewStatus(request.getTagId(), reviewStatus, pageable);
        } else if (request.getKeyword() != null && !request.getKeyword().isEmpty()) {
            materialPage = materialRepository.findByTitleContainingAndReviewStatusAndDeletedFalse(
                    request.getKeyword(), reviewStatus, pageable);
        } else if (request.getMaterialType() != null && !request.getMaterialType().isEmpty()) {
            MaterialType type = MaterialType.valueOf(request.getMaterialType());
            materialPage = materialRepository.findByMaterialTypeAndReviewStatusAndDeletedFalse(type, reviewStatus, pageable);
        } else {
            Long schoolId = request.getSchoolId() != null ? request.getSchoolId() : getSchoolIdFromUser(user);
            materialPage = materialRepository.findBySchoolIdAndReviewStatusAndDeletedFalse(schoolId, reviewStatus, pageable);
        }

        return materialPage.map(MaterialDTO::fromEntity);
    }

    private Long getSchoolIdFromUser(User user) {
        if (user.getSchool() != null) {
            return user.getSchool().getId();
        }
        throw new BusinessException("School ID is required for search");
    }

    private ReviewStatus resolveReviewStatus(String reviewStatusStr) {
        if (reviewStatusStr != null && !reviewStatusStr.isEmpty()) {
            try {
                return ReviewStatus.valueOf(reviewStatusStr);
            } catch (IllegalArgumentException e) {
                throw new BusinessException("Invalid review status: " + reviewStatusStr);
            }
        }
        return ReviewStatus.APPROVED;
    }

    @Transactional
    public MaterialDTO reviewMaterial(Long materialId, Long reviewerId, ReviewActionRequest request) {
        Material material = materialRepository.findById(materialId)
                .orElseThrow(() -> new BusinessException("Material not found"));

        if (material.getReviewStatus() != ReviewStatus.PENDING) {
            throw new BusinessException("Material is not in PENDING review status");
        }

        String action = request.getAction().toUpperCase();
        if ("APPROVE".equals(action)) {
            material.setReviewStatus(ReviewStatus.APPROVED);
        } else if ("REJECT".equals(action)) {
            material.setReviewStatus(ReviewStatus.REJECTED);
        } else {
            throw new BusinessException("Invalid review action: " + request.getAction());
        }

        material.setReviewerId(reviewerId);
        material.setReviewComment(request.getComment());

        ReviewLog reviewLog = new ReviewLog();
        reviewLog.setMaterialId(materialId);
        reviewLog.setReviewerId(reviewerId);
        reviewLog.setAction(action);
        reviewLog.setComment(request.getComment());
        reviewLogRepository.save(reviewLog);

        Material savedMaterial = materialRepository.save(material);
        return MaterialDTO.fromEntity(savedMaterial);
    }

    public List<TagDTO> getAllTags() {
        return materialTagRepository.findByDeletedFalse().stream()
                .map(TagDTO::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional
    public TagDTO createTag(String tagName) {
        MaterialTag existingTag = materialTagRepository.findByTagNameAndDeletedFalse(tagName).orElse(null);
        if (existingTag != null) {
            return TagDTO.fromEntity(existingTag);
        }

        MaterialTag tag = new MaterialTag();
        tag.setTagName(tagName);
        tag.setTagType("CUSTOM");
        MaterialTag savedTag = materialTagRepository.save(tag);
        return TagDTO.fromEntity(savedTag);
    }

    public Page<MaterialDTO> getPendingReviewMaterials(Long schoolId, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Material> materialPage = materialRepository.findBySchoolIdAndReviewStatusAndDeletedFalse(
                schoolId, ReviewStatus.PENDING, pageable);
        return materialPage.map(MaterialDTO::fromEntity);
    }

    @Transactional
    public String getVideoPlayUrl(Long materialId) {
        Material material = materialRepository.findById(materialId)
                .orElseThrow(() -> new BusinessException("Material not found"));

        if (material.getMaterialType() != MaterialType.VIDEO) {
            throw new BusinessException("Material is not a video type");
        }

        if (material.getHlsUrl() != null && !material.getHlsUrl().isEmpty()) {
            return material.getHlsUrl();
        }

        if (material.getVideoId() != null) {
            String playUrl = vodService.getPlayUrl(material.getVideoId());
            material.setHlsUrl(playUrl);
            materialRepository.save(material);
            return playUrl;
        }

        throw new BusinessException("Video has not been processed yet");
    }
}
