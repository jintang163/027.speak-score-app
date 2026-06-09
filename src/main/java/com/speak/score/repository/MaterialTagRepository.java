package com.speak.score.repository;

import com.speak.score.entity.MaterialTag;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface MaterialTagRepository extends JpaRepository<MaterialTag, Long> {

    Optional<MaterialTag> findByTagNameAndDeletedFalse(String tagName);

    List<MaterialTag> findByTagTypeAndDeletedFalse(String tagType);

    List<MaterialTag> findByDeletedFalse();
}
