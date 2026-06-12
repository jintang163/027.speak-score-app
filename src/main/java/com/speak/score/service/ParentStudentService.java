package com.speak.score.service;

import com.speak.score.dto.ParentStudentBindRequest;
import com.speak.score.dto.ParentStudentDTO;
import com.speak.score.entity.*;
import com.speak.score.exception.BusinessException;
import com.speak.score.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class ParentStudentService {

    private final ParentStudentRepository parentStudentRepository;
    private final UserRepository userRepository;
    private final ClassRepository classRepository;
    private final SchoolRepository schoolRepository;
    private final RbacService rbacService;

    @Transactional
    public ParentStudentDTO bindParent(Long parentId, ParentStudentBindRequest request) {
        User parent = userRepository.findById(parentId)
                .orElseThrow(() -> new BusinessException("家长用户不存在"));

        User student;
        if (request.getStudentId() != null) {
            student = userRepository.findById(request.getStudentId())
                    .orElseThrow(() -> new BusinessException("学生不存在"));
        } else if (request.getStudentPhone() != null && !request.getStudentPhone().isEmpty()) {
            student = userRepository.findByPhoneAndDeletedFalse(request.getStudentPhone())
                    .orElseThrow(() -> new BusinessException("未找到该手机号的学生"));
            boolean isStudent = student.getRoles().stream()
                    .anyMatch(r -> r.getRoleCode() == RoleEnum.STUDENT);
            if (!isStudent) {
                throw new BusinessException("该用户不是学生");
            }
        } else {
            throw new BusinessException("请提供学生ID或手机号");
        }

        if (parentStudentRepository.existsByParentIdAndStudentIdAndDeletedFalse(parentId, student.getId())) {
            throw new BusinessException("已绑定该学生，无需重复绑定");
        }

        rbacService.ensureRole(parentId, RoleEnum.PARENT);

        ParentStudent ps = new ParentStudent();
        ps.setParentId(parentId);
        ps.setStudentId(student.getId());
        ps.setRelation(request.getRelation());
        ps.setIsPrimary(request.getIsPrimary() != null ? request.getIsPrimary() : false);
        ps.setStatus(1);

        if (Boolean.TRUE.equals(ps.getIsPrimary())) {
            List<ParentStudent> existing = parentStudentRepository.findByParentIdAndDeletedFalse(parentId);
            for (ParentStudent e : existing) {
                e.setIsPrimary(false);
            }
            parentStudentRepository.saveAll(existing);
        }

        ParentStudent saved = parentStudentRepository.save(ps);
        log.info("Parent {} bound to student {}", parentId, student.getId());
        return toDTO(saved);
    }

    @Transactional
    public void unbindParent(Long parentId, Long studentId) {
        ParentStudent ps = parentStudentRepository
                .findByParentIdAndStudentIdAndDeletedFalse(parentId, studentId)
                .orElseThrow(() -> new BusinessException("绑定关系不存在"));
        ps.setDeleted(true);
        parentStudentRepository.save(ps);
        log.info("Parent {} unbound from student {}", parentId, studentId);
    }

    @Transactional
    public void updatePrimary(Long parentId, Long studentId, Boolean isPrimary) {
        ParentStudent ps = parentStudentRepository
                .findByParentIdAndStudentIdAndDeletedFalse(parentId, studentId)
                .orElseThrow(() -> new BusinessException("绑定关系不存在"));

        if (Boolean.TRUE.equals(isPrimary)) {
            List<ParentStudent> existing = parentStudentRepository.findByParentIdAndDeletedFalse(parentId);
            for (ParentStudent e : existing) {
                e.setIsPrimary(false);
            }
            parentStudentRepository.saveAll(existing);
        }
        ps.setIsPrimary(isPrimary);
        parentStudentRepository.save(ps);
    }

    public List<ParentStudentDTO> getMyChildren(Long parentId) {
        List<ParentStudent> list = parentStudentRepository.findByParentIdAndDeletedFalse(parentId);
        return list.stream().map(this::toDTO).collect(Collectors.toList());
    }

    public List<ParentStudentDTO> getStudentParents(Long studentId) {
        List<ParentStudent> list = parentStudentRepository.findByStudentIdAndDeletedFalse(studentId);
        return list.stream().map(this::toDTO).collect(Collectors.toList());
    }

    public List<Long> getParentIdsByStudentId(Long studentId) {
        List<ParentStudent> list = parentStudentRepository.findByStudentIdAndDeletedFalse(studentId);
        return list.stream().map(ParentStudent::getParentId).collect(Collectors.toList());
    }

    public List<Long> getParentIdsByStudentIds(List<Long> studentIds) {
        if (studentIds == null || studentIds.isEmpty()) {
            return new ArrayList<>();
        }
        List<ParentStudent> list = parentStudentRepository.findByStudentIdInAndDeletedFalse(studentIds);
        return list.stream().map(ParentStudent::getParentId).distinct().collect(Collectors.toList());
    }

    private ParentStudentDTO toDTO(ParentStudent ps) {
        ParentStudentDTO dto = new ParentStudentDTO();
        dto.setId(ps.getId());
        dto.setParentId(ps.getParentId());
        dto.setStudentId(ps.getStudentId());
        dto.setRelation(ps.getRelation());
        dto.setIsPrimary(ps.getIsPrimary());
        dto.setStatus(ps.getStatus());

        userRepository.findById(ps.getParentId()).ifPresent(p -> {
            dto.setParentName(p.getRealName() != null ? p.getRealName() : p.getNickname());
            dto.setParentPhone(p.getPhone());
        });

        userRepository.findById(ps.getStudentId()).ifPresent(s -> {
            dto.setStudentName(s.getRealName() != null ? s.getRealName() : s.getNickname());
            dto.setStudentPhone(s.getPhone());
            if (s.getClassEntity() != null) {
                classRepository.findById(s.getClassEntity().getId()).ifPresent(c -> {
                    dto.setClassName(c.getClassName());
                    if (c.getSchoolId() != null) {
                        schoolRepository.findById(c.getSchoolId()).ifPresent(sch ->
                                dto.setSchoolName(sch.getSchoolName()));
                    }
                });
            }
        });

        return dto;
    }
}
