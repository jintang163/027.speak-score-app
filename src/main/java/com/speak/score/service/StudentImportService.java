package com.speak.score.service;

import com.alibaba.excel.EasyExcel;
import com.alibaba.excel.read.listener.PageReadListener;
import com.speak.score.dto.StudentExcelDTO;
import com.speak.score.entity.*;
import com.speak.score.exception.BusinessException;
import com.speak.score.repository.ClassMemberRepository;
import com.speak.score.repository.ClassRepository;
import com.speak.score.repository.RoleRepository;
import com.speak.score.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class StudentImportService {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final ClassRepository classRepository;
    private final ClassMemberRepository classMemberRepository;
    private final PasswordEncoder passwordEncoder;

    @Transactional
    public List<String> importStudents(MultipartFile file, Long classId) {
        ClassEntity classEntity = classRepository.findById(classId)
                .orElseThrow(() -> new BusinessException("Class not found"));

        Role studentRole = roleRepository.findByRoleCode(RoleEnum.STUDENT)
                .orElseThrow(() -> new BusinessException("Student role not found"));

        List<String> results = new ArrayList<>();

        try {
            EasyExcel.read(file.getInputStream(), StudentExcelDTO.class,
                    new PageReadListener<StudentExcelDTO>(dataList -> {
                        for (StudentExcelDTO dto : dataList) {
                            try {
                                importSingleStudent(dto, classEntity, studentRole, results);
                            } catch (Exception e) {
                                results.add("FAILED: " + dto.getRealName() + " - " + e.getMessage());
                                log.warn("Failed to import student: {}", dto.getRealName(), e);
                            }
                        }
                    })).sheet().doRead();
        } catch (IOException e) {
            throw new BusinessException("Failed to read Excel file: " + e.getMessage());
        }

        return results;
    }

    private void importSingleStudent(StudentExcelDTO dto, ClassEntity classEntity,
                                     Role studentRole, List<String> results) {
        if (dto.getPhone() != null && userRepository.existsByPhone(dto.getPhone())) {
            User existingUser = userRepository.findByPhone(dto.getPhone())
                    .orElseThrow(() -> new BusinessException("User not found"));
            java.util.Optional<ClassMember> existingMember =
                    classMemberRepository.findByClassIdAndUserId(classEntity.getId(), existingUser.getId());
            if (existingMember.isPresent()) {
                results.add("SKIPPED: " + dto.getRealName() + " - already in class");
            } else {
                ClassMember member = new ClassMember();
                member.setUser(existingUser);
                member.setClassEntity(classEntity);
                member.setRoleCode(RoleEnum.STUDENT);
                member.setJoinType("IMPORT");
                member.setStatus(1);
                classMemberRepository.save(member);

                existingUser.setClassEntity(classEntity);
                if (existingUser.getSchool() == null) {
                    existingUser.setSchool(classEntity.getSchool());
                }
                userRepository.save(existingUser);
                results.add("ADDED: " + dto.getRealName());
            }
            return;
        }

        User user = new User();
        user.setRealName(dto.getRealName());
        user.setNickname(dto.getRealName());
        user.setPhone(dto.getPhone());
        user.setGender(parseGender(dto.getGenderStr()));
        user.setUsername(dto.getStudentNo());
        user.setPassword(passwordEncoder.encode(dto.getPhone() != null ? dto.getPhone() : "123456"));
        user.addRole(studentRole);
        user.setClassEntity(classEntity);
        user.setSchool(classEntity.getSchool());

        userRepository.save(user);

        ClassMember member = new ClassMember();
        member.setUser(user);
        member.setClassEntity(classEntity);
        member.setRoleCode(RoleEnum.STUDENT);
        member.setJoinType("IMPORT");
        member.setStatus(1);
        classMemberRepository.save(member);

        results.add("CREATED: " + dto.getRealName());
    }

    private Integer parseGender(String genderStr) {
        if (genderStr == null) return null;
        switch (genderStr.trim()) {
            case "男":
            case "M":
            case "male":
                return 1;
            case "女":
            case "F":
            case "female":
                return 2;
            default:
                return 0;
        }
    }
}
