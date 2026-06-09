package com.speak.score.repository;

import com.speak.score.entity.SchoolMember;
import com.speak.score.entity.RoleEnum;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SchoolMemberRepository extends JpaRepository<SchoolMember, Long> {

    @Query("SELECT sm FROM SchoolMember sm WHERE sm.school.id = :schoolId AND sm.deleted = false")
    List<SchoolMember> findBySchoolId(Long schoolId);

    @Query("SELECT sm FROM SchoolMember sm WHERE sm.user.id = :userId AND sm.deleted = false")
    List<SchoolMember> findByUserId(Long userId);

    @Query("SELECT sm FROM SchoolMember sm WHERE sm.school.id = :schoolId AND sm.user.id = :userId AND sm.deleted = false")
    Optional<SchoolMember> findBySchoolIdAndUserId(Long schoolId, Long userId);

    @Query("SELECT sm FROM SchoolMember sm WHERE sm.school.id = :schoolId AND sm.roleCode = :roleCode AND sm.status = :status AND sm.deleted = false")
    List<SchoolMember> findBySchoolIdAndRoleCodeAndStatus(Long schoolId, RoleEnum roleCode, Integer status);
}
