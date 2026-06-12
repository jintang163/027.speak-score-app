package com.speak.score.repository;

import com.speak.score.entity.ParentStudent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ParentStudentRepository extends JpaRepository<ParentStudent, Long> {

    List<ParentStudent> findByParentIdAndDeletedFalse(Long parentId);

    List<ParentStudent> findByStudentIdAndDeletedFalse(Long studentId);

    Optional<ParentStudent> findByParentIdAndStudentIdAndDeletedFalse(Long parentId, Long studentId);

    boolean existsByParentIdAndStudentIdAndDeletedFalse(Long parentId, Long studentId);

    List<ParentStudent> findByStudentIdInAndDeletedFalse(List<Long> studentIds);
}
