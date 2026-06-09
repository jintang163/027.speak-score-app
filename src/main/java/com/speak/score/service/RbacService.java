package com.speak.score.service;

import com.speak.score.entity.Permission;
import com.speak.score.entity.Role;
import com.speak.score.entity.RoleEnum;
import com.speak.score.entity.RolePermission;
import com.speak.score.exception.BusinessException;
import com.speak.score.repository.PermissionRepository;
import com.speak.score.repository.RolePermissionRepository;
import com.speak.score.repository.RoleRepository;
import com.speak.score.security.RbacPermissionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class RbacService {

    private final RoleRepository roleRepository;
    private final PermissionRepository permissionRepository;
    private final RolePermissionRepository rolePermissionRepository;
    private final RbacPermissionService rbacPermissionService;

    @Transactional
    public void initRolesAndPermissions() {
        for (RoleEnum roleEnum : RoleEnum.values()) {
            roleRepository.findByRoleCode(roleEnum).orElseGet(() -> {
                Role role = new Role();
                role.setRoleCode(roleEnum);
                role.setRoleName(getRoleDisplayName(roleEnum));
                role.setDescription(getRoleDescription(roleEnum));
                return roleRepository.save(role);
            });
        }

        initStudentPermissions();
        initTeacherPermissions();
        initEduOfficePermissions();

        rbacPermissionService.evictAllPermissionCache();
    }

    private void initStudentPermissions() {
        Role studentRole = roleRepository.findByRoleCode(RoleEnum.STUDENT)
                .orElseThrow(() -> new BusinessException("Student role not found"));
        String[] permissions = {
                "task:view", "task:submit", "recording:create", "recording:view_own",
                "score:view_own", "ranking:view_class", "ranking:view_school",
                "profile:view", "profile:update", "class:join"
        };
        assignPermissionsToRole(studentRole, permissions);
    }

    private void initTeacherPermissions() {
        Role teacherRole = roleRepository.findByRoleCode(RoleEnum.TEACHER)
                .orElseThrow(() -> new BusinessException("Teacher role not found"));
        String[] permissions = {
                "task:view", "task:create", "task:update", "task:delete", "task:publish",
                "recording:view_class", "recording:review", "score:view_class",
                "ranking:view_class", "ranking:view_school",
                "student:view_class", "student:manage", "student:import",
                "class:view", "class:manage_members",
                "profile:view", "profile:update",
                "video:upload", "video:manage", "message:send"
        };
        assignPermissionsToRole(teacherRole, permissions);
    }

    private void initEduOfficePermissions() {
        Role eduOfficeRole = roleRepository.findByRoleCode(RoleEnum.EDU_OFFICE)
                .orElseThrow(() -> new BusinessException("EduOffice role not found"));
        String[] permissions = {
                "task:view", "task:create", "task:update", "task:delete", "task:publish",
                "recording:view_all", "recording:review", "score:view_all",
                "ranking:view_class", "ranking:view_school", "ranking:manage",
                "student:view_all", "student:manage",
                "teacher:view_all", "teacher:manage",
                "class:view", "class:create", "class:update", "class:manage_members",
                "grade:view", "grade:create", "grade:update",
                "school:view", "school:create", "school:update",
                "profile:view", "profile:update",
                "video:upload", "video:manage", "video:approve",
                "message:send", "message:manage",
                "permission:manage"
        };
        assignPermissionsToRole(eduOfficeRole, permissions);
    }

    private void assignPermissionsToRole(Role role, String[] permissionCodes) {
        for (String code : permissionCodes) {
            Permission permission = permissionRepository.findByPermissionCode(code)
                    .orElseGet(() -> {
                        Permission p = new Permission();
                        p.setPermissionCode(code);
                        p.setPermissionName(code.replace(":", " "));
                        p.setResourceType("API");
                        return permissionRepository.save(p);
                    });

            boolean exists = rolePermissionRepository.findByRoleId(role.getId()).stream()
                    .anyMatch(rp -> rp.getPermission().getId().equals(permission.getId()));

            if (!exists) {
                RolePermission rp = new RolePermission();
                rp.setRole(role);
                rp.setPermission(permission);
                rolePermissionRepository.save(rp);
            }
        }
    }

    private String getRoleDisplayName(RoleEnum roleEnum) {
        switch (roleEnum) {
            case STUDENT: return "学生";
            case TEACHER: return "老师";
            case EDU_OFFICE: return "教办";
            default: return roleEnum.name();
        }
    }

    private String getRoleDescription(RoleEnum roleEnum) {
        switch (roleEnum) {
            case STUDENT: return "学生角色，可跟读打卡、查看成绩和排行";
            case TEACHER: return "老师角色，可下发任务、管理本班学生、查看班级成绩";
            case EDU_OFFICE: return "教办角色，可管理全校年级班级、教师、查看全校数据";
            default: return "";
        }
    }
}
