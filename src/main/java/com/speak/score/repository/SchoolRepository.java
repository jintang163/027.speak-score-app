package com.speak.score.repository;

import com.speak.score.entity.School;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SchoolRepository extends JpaRepository<School, Long> {

    Optional<School> findBySchoolCode(String schoolCode);

    @Query("SELECT s FROM School s WHERE s.deleted = false AND s.status = 1")
    List<School> findAllActive();

    @Query("SELECT s FROM School s WHERE s.province = :province AND s.city = :city AND s.deleted = false AND s.status = 1")
    List<School> findByProvinceAndCity(String province, String city);
}
