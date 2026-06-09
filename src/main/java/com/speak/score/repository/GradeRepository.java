package com.speak.score.repository;

import com.speak.score.entity.Grade;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface GradeRepository extends JpaRepository<Grade, Long> {

    @Query("SELECT g FROM Grade g WHERE g.school.id = :schoolId AND g.deleted = false")
    List<Grade> findBySchoolId(Long schoolId);
}
