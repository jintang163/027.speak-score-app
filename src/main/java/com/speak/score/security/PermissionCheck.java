package com.speak.score.security;

import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.stereotype.Component;

@Component("permissionCheck")
@RequiredArgsConstructor
public class PermissionCheck {

    private final RbacPermissionService rbacPermissionService;

    public boolean hasPermission(Authentication authentication, String permissionCode) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return false;
        }

        for (GrantedAuthority authority : authentication.getAuthorities()) {
            String roleCode = authority.getAuthority().replace("ROLE_", "");
            if (rbacPermissionService.hasPermission(roleCode, permissionCode)) {
                return true;
            }
        }
        return false;
    }
}
