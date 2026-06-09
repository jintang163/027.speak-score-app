package com.speak.score.repository;

import com.speak.score.entity.RoleEnum;
import com.speak.score.entity.RolePermission;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RolePermissionRepository extends JpaRepository<RolePermission, Long> {

    @Query("SELECT rp FROM RolePermission rp WHERE rp.role.roleCode = :roleCode AND rp.deleted = false")
    List<RolePermission> findByRole_RoleCode(RoleEnum roleCode);

    @Query("SELECT rp FROM RolePermission rp WHERE rp.role.id = :roleId AND rp.deleted = false")
    List<RolePermission> findByRoleId(Long roleId);
}
