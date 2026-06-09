package com.speak.score.security;

import com.speak.score.entity.Permission;
import com.speak.score.entity.Role;
import com.speak.score.entity.RolePermission;
import com.speak.score.repository.RolePermissionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

@Slf4j
@Component
@RequiredArgsConstructor
public class RbacPermissionService {

    private static final String PERMISSION_CACHE_PREFIX = "rbac:role:permissions:";
    private static final long CACHE_TTL_HOURS = 24;

    private final RolePermissionRepository rolePermissionRepository;
    private final RedisTemplate<String, Object> redisTemplate;

    @SuppressWarnings("unchecked")
    public List<String> getPermissionsByRoleCode(String roleCode) {
        String cacheKey = PERMISSION_CACHE_PREFIX + roleCode;

        List<String> cached = (List<String>) redisTemplate.opsForValue().get(cacheKey);
        if (cached != null) {
            return cached;
        }

        List<RolePermission> rolePermissions = rolePermissionRepository.findByRole_RoleCode(
                com.speak.score.entity.RoleEnum.valueOf(roleCode));

        List<String> permissions = rolePermissions.stream()
                .map(RolePermission::getPermission)
                .map(Permission::getPermissionCode)
                .collect(Collectors.toList());

        redisTemplate.opsForValue().set(cacheKey, permissions, CACHE_TTL_HOURS, TimeUnit.HOURS);
        log.debug("Cached permissions for role: {}", roleCode);

        return permissions;
    }

    public boolean hasPermission(String roleCode, String permissionCode) {
        List<String> permissions = getPermissionsByRoleCode(roleCode);
        return permissions.contains(permissionCode);
    }

    public void evictRolePermissionCache(String roleCode) {
        String cacheKey = PERMISSION_CACHE_PREFIX + roleCode;
        redisTemplate.delete(cacheKey);
        log.debug("Evicted permission cache for role: {}", roleCode);
    }

    public void evictAllPermissionCache() {
        var keys = redisTemplate.keys(PERMISSION_CACHE_PREFIX + "*");
        if (keys != null && !keys.isEmpty()) {
            redisTemplate.delete(keys);
            log.debug("Evicted all permission cache");
        }
    }
}
