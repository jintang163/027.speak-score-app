package com.speak.score.repository;

import com.speak.score.entity.RoleEnum;
import com.speak.score.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByPhone(String phone);

    Optional<User> findByWechatOpenid(String openid);

    @Query("SELECT u FROM User u JOIN u.roles r WHERE r.roleCode = :roleCode AND u.deleted = false")
    List<User> findByRole(@Param("roleCode") RoleEnum roleCode);

    @Query("SELECT u FROM User u WHERE u.classEntity.id = :classId AND u.deleted = false")
    List<User> findByClassId(@Param("classId") Long classId);

    @Query("SELECT u FROM User u WHERE u.school.id = :schoolId AND u.deleted = false")
    List<User> findBySchoolId(@Param("schoolId") Long schoolId);

    @Query("SELECT u FROM User u JOIN u.roles r WHERE r.roleCode = :roleCode AND u.school.id = :schoolId AND u.deleted = false")
    List<User> findByRoleAndSchoolId(@Param("roleCode") RoleEnum roleCode, @Param("schoolId") Long schoolId);

    boolean existsByPhone(String phone);

    boolean existsByWechatOpenid(String openid);
}
