package com.speak.score.repository;

import com.speak.score.entity.ClassMember;
import com.speak.score.entity.RoleEnum;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ClassMemberRepository extends JpaRepository<ClassMember, Long> {

    @Query("SELECT cm FROM ClassMember cm WHERE cm.classEntity.id = :classId AND cm.deleted = false")
    List<ClassMember> findByClassId(Long classId);

    @Query("SELECT cm FROM ClassMember cm WHERE cm.user.id = :userId AND cm.deleted = false")
    List<ClassMember> findByUserId(Long userId);

    @Query("SELECT cm FROM ClassMember cm WHERE cm.classEntity.id = :classId AND cm.user.id = :userId AND cm.deleted = false")
    Optional<ClassMember> findByClassIdAndUserId(Long classId, Long userId);

    @Query("SELECT cm FROM ClassMember cm WHERE cm.classEntity.id = :classId AND cm.roleCode = :roleCode AND cm.status = 1 AND cm.deleted = false")
    List<ClassMember> findApprovedByClassIdAndRoleCode(@Param("classId") Long classId, @Param("roleCode") RoleEnum roleCode);

    @Query("SELECT COUNT(cm) FROM ClassMember cm WHERE cm.classEntity.id = :classId AND cm.roleCode = :roleCode AND cm.status = 1 AND cm.deleted = false")
    long countByClassIdAndRoleCodeAndStatusAndDeletedFalse(@Param("classId") Long classId, @Param("roleCode") RoleEnum roleCode);

    @Query("SELECT cm FROM ClassMember cm WHERE cm.classEntity.id = :classId AND cm.roleCode = :roleCode AND cm.status = 1 AND cm.deleted = false")
    List<ClassMember> findByClassIdAndRoleCodeAndStatusAndDeletedFalse(@Param("classId") Long classId, @Param("roleCode") RoleEnum roleCode);
}
