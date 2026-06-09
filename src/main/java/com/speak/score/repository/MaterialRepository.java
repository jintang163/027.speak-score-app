package com.speak.score.repository;

import com.speak.score.entity.Material;
import com.speak.score.entity.MaterialType;
import com.speak.score.entity.ReviewStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MaterialRepository extends JpaRepository<Material, Long> {

    List<Material> findByUploaderIdAndDeletedFalse(Long uploaderId);

    List<Material> findBySchoolIdAndReviewStatusAndDeletedFalse(Long schoolId, ReviewStatus status);

    Page<Material> findByMaterialTypeAndReviewStatusAndDeletedFalse(MaterialType type, ReviewStatus status, Pageable pageable);

    Page<Material> findBySchoolIdAndReviewStatusAndDeletedFalse(Long schoolId, ReviewStatus status, Pageable pageable);

    Page<Material> findByTitleContainingAndReviewStatusAndDeletedFalse(String keyword, ReviewStatus status, Pageable pageable);

    @Query("SELECT m FROM Material m JOIN m.tags t WHERE t.id = :tagId AND m.reviewStatus = :status AND m.deleted = false")
    Page<Material> findByTagIdAndReviewStatus(@Param("tagId") Long tagId, @Param("status") ReviewStatus status, Pageable pageable);
}
