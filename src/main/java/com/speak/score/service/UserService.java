package com.speak.score.service;

import com.speak.score.dto.UserInfoDTO;
import com.speak.score.entity.*;
import com.speak.score.exception.BusinessException;
import com.speak.score.repository.ClassMemberRepository;
import com.speak.score.repository.ClassRepository;
import com.speak.score.repository.RoleRepository;
import com.speak.score.repository.SchoolMemberRepository;
import com.speak.score.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final SchoolMemberRepository schoolMemberRepository;
    private final ClassMemberRepository classMemberRepository;
    private final ClassRepository classRepository;
    private final PasswordEncoder passwordEncoder;

    @Transactional
    public User createUserWithPhone(String phone, String nickname, RoleEnum roleCode) {
        if (userRepository.existsByPhone(phone)) {
            throw new BusinessException("Phone number already registered");
        }

        User user = new User();
        user.setPhone(phone);
        user.setNickname(nickname);
        user.setPassword(passwordEncoder.encode(phone));

        Role role = roleRepository.findByRoleCode(roleCode)
                .orElseThrow(() -> new BusinessException("Role not found: " + roleCode));
        user.addRole(role);

        return userRepository.save(user);
    }

    @Transactional
    public User createUserWithWechat(String openid, String unionid, String nickname, String avatar) {
        if (userRepository.existsByWechatOpenid(openid)) {
            throw new BusinessException("WeChat account already registered");
        }

        User user = new User();
        user.setWechatOpenid(openid);
        user.setWechatUnionid(unionid);
        user.setNickname(nickname);
        user.setAvatar(avatar);
        user.setPassword(passwordEncoder.encode(openid));

        Role role = roleRepository.findByRoleCode(RoleEnum.STUDENT)
                .orElseThrow(() -> new BusinessException("Default role not found"));
        user.addRole(role);

        return userRepository.save(user);
    }

    public UserInfoDTO getUserInfo(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException("User not found"));

        return toUserInfoDTO(user);
    }

    @Transactional
    public User assignRole(Long userId, RoleEnum roleCode) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException("User not found"));

        Role role = roleRepository.findByRoleCode(roleCode)
                .orElseThrow(() -> new BusinessException("Role not found: " + roleCode));

        user.addRole(role);
        return userRepository.save(user);
    }

    @Transactional
    public User assignToSchool(Long userId, Long schoolId, RoleEnum roleCode) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException("User not found"));

        user.setSchool(new School());
        user.getSchool().setId(schoolId);

        SchoolMember member = new SchoolMember();
        member.setUser(user);
        member.setSchool(user.getSchool());
        member.setRoleCode(roleCode);
        member.setStatus(SchoolMember.JoinStatus.APPROVED.getCode());
        schoolMemberRepository.save(member);

        return userRepository.save(user);
    }

    @Transactional
    public User assignToClass(Long userId, Long classId, RoleEnum roleCode, String joinType) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException("User not found"));

        ClassEntity classEntity = classRepository.findById(classId)
                .orElseThrow(() -> new BusinessException("Class not found"));

        user.setClassEntity(classEntity);
        if (user.getSchool() == null) {
            user.setSchool(classEntity.getSchool());
        }

        ClassMember member = new ClassMember();
        member.setUser(user);
        member.setClassEntity(classEntity);
        member.setRoleCode(roleCode);
        member.setJoinType(joinType);
        member.setStatus(1);
        classMemberRepository.save(member);

        return userRepository.save(user);
    }

    public List<User> getStudentsByClassId(Long classId) {
        return userRepository.findByClassId(classId);
    }

    public List<User> getTeachersBySchoolId(Long schoolId) {
        return userRepository.findByRoleAndSchoolId(RoleEnum.TEACHER, schoolId);
    }

    private UserInfoDTO toUserInfoDTO(User user) {
        UserInfoDTO dto = new UserInfoDTO();
        dto.setId(user.getId());
        dto.setUsername(user.getUsername());
        dto.setNickname(user.getNickname());
        dto.setRealName(user.getRealName());
        dto.setAvatar(user.getAvatar());
        dto.setPhone(user.getPhone());
        dto.setGender(user.getGender());

        dto.setRoles(user.getRoles().stream()
                .map(role -> role.getRoleCode().name())
                .collect(Collectors.toList()));

        if (user.getSchool() != null) {
            dto.setSchoolId(user.getSchool().getId());
            dto.setSchoolName(user.getSchool().getSchoolName());
        }

        if (user.getClassEntity() != null) {
            dto.setClassId(user.getClassEntity().getId());
            dto.setClassName(user.getClassEntity().getClassName());
            if (user.getClassEntity().getGrade() != null) {
                dto.setGradeId(user.getClassEntity().getGrade().getId());
                dto.setGradeName(user.getClassEntity().getGrade().getGradeName());
            }
        }

        return dto;
    }
}
