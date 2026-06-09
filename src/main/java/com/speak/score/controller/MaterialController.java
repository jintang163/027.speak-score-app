package com.speak.score.controller;

import com.speak.score.dto.ApiResponse;
import com.speak.score.dto.MaterialDTO;
import com.speak.score.dto.MaterialSearchRequest;
import com.speak.score.dto.MaterialUpdateRequest;
import com.speak.score.dto.MaterialUploadRequest;
import com.speak.score.dto.ReviewActionRequest;
import com.speak.score.dto.TagCreateRequest;
import com.speak.score.dto.TagDTO;
import com.speak.score.service.MaterialService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.MediaType;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import javax.validation.Valid;
import java.util.List;

@RestController
@RequestMapping("/materials")
@RequiredArgsConstructor
public class MaterialController {

    private final MaterialService materialService;

    @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasAnyRole('TEACHER', 'EDU_OFFICE')")
    public ApiResponse<MaterialDTO> uploadMaterial(
            @RequestPart("file") MultipartFile file,
            @RequestPart("request") MaterialUploadRequest request,
            Authentication auth) {
        Long userId = (Long) auth.getPrincipal();
        return ApiResponse.success(materialService.uploadMaterial(userId, request, file));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('TEACHER', 'EDU_OFFICE')")
    public ApiResponse<MaterialDTO> updateMaterial(
            @PathVariable("id") Long materialId,
            @RequestBody MaterialUpdateRequest request,
            Authentication auth) {
        Long userId = (Long) auth.getPrincipal();
        return ApiResponse.success(materialService.updateMaterial(materialId, userId, request));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('TEACHER', 'EDU_OFFICE')")
    public ApiResponse<Void> deleteMaterial(@PathVariable("id") Long materialId, Authentication auth) {
        Long userId = (Long) auth.getPrincipal();
        materialService.deleteMaterial(materialId, userId);
        return ApiResponse.success();
    }

    @GetMapping("/{id}")
    public ApiResponse<MaterialDTO> getMaterialDetail(@PathVariable("id") Long materialId, Authentication auth) {
        return ApiResponse.success(materialService.getMaterialDetail(materialId));
    }

    @GetMapping("/search")
    public ApiResponse<Page<MaterialDTO>> searchMaterials(MaterialSearchRequest request, Authentication auth) {
        Long userId = (Long) auth.getPrincipal();
        return ApiResponse.success(materialService.searchMaterials(request, userId));
    }

    @PostMapping("/{id}/review")
    @PreAuthorize("hasRole('EDU_OFFICE')")
    public ApiResponse<MaterialDTO> reviewMaterial(
            @PathVariable("id") Long materialId,
            @RequestBody ReviewActionRequest request,
            Authentication auth) {
        Long userId = (Long) auth.getPrincipal();
        return ApiResponse.success(materialService.reviewMaterial(materialId, userId, request));
    }

    @GetMapping("/tags")
    public ApiResponse<List<TagDTO>> getAllTags() {
        return ApiResponse.success(materialService.getAllTags());
    }

    @PostMapping("/tags")
    @PreAuthorize("hasAnyRole('TEACHER', 'EDU_OFFICE')")
    public ApiResponse<TagDTO> createTag(@Valid @RequestBody TagCreateRequest request, Authentication auth) {
        return ApiResponse.success(materialService.createTag(request.getTagName()));
    }

    @GetMapping("/pending-review")
    @PreAuthorize("hasRole('EDU_OFFICE')")
    public ApiResponse<Page<MaterialDTO>> getPendingReviewMaterials(
            @RequestParam Long schoolId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            Authentication auth) {
        return ApiResponse.success(materialService.getPendingReviewMaterials(schoolId, page, size));
    }

    @GetMapping("/{id}/play-url")
    public ApiResponse<String> getVideoPlayUrl(@PathVariable("id") Long materialId, Authentication auth) {
        return ApiResponse.success(materialService.getVideoPlayUrl(materialId));
    }
}
