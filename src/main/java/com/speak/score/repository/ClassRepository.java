package com.speak.score.repository;

import com.speak.score.entity.ClassEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ClassRepository extends JpaRepository<ClassEntity, Long> {

    Optional<ClassEntity> findByClassCode(String classCode);

    @Query("SELECT c FROM ClassEntity c WHERE c.grade.id = :gradeId AND c.deleted = false")
    List<ClassEntity> findByGradeId(Long gradeId);

    @Query("SELECT c FROM ClassEntity c WHERE c.school.id = :schoolId AND c.deleted = false")
    List<ClassEntity> findBySchoolId(Long schoolId);

    @Query("SELECT c FROM ClassEntity c WHERE c.teacher.id = :teacherId AND c.deleted = false")
    List<ClassEntity> findByTeacherId(Long teacherId);
}
