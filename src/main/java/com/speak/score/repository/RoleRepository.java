package com.speak.score.repository;

import com.speak.score.entity.Role;
import com.speak.score.entity.RoleEnum;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface RoleRepository extends JpaRepository<Role, Long> {

    Optional<Role> findByRoleCode(RoleEnum roleCode);
}
