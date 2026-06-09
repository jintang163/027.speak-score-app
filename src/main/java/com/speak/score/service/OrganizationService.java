package com.speak.score.service;

import com.speak.score.dto.*;
import com.speak.score.entity.*;
import com.speak.score.exception.BusinessException;
import com.speak.score.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class OrganizationService {

    private final SchoolRepository schoolRepository;
    private final GradeRepository gradeRepository;
    private final ClassRepository classRepository;
    private final ClassMemberRepository classMemberRepository;
    private final UserRepository userRepository;

    @Transactional
    public School createSchool(SchoolCreateRequest request) {
        if (request.getSchoolCode() != null) {
            schoolRepository.findBySchoolCode(request.getSchoolCode()).ifPresent(s -> {
                throw new BusinessException("School code already exists");
            });
        }

        School school = new School();
        school.setSchoolName(request.getSchoolName());
        school.setSchoolCode(request.getSchoolCode() != null ? request.getSchoolCode() :
                "SCH" + System.currentTimeMillis());
        school.setProvince(request.getProvince());
        school.setCity(request.getCity());
        school.setDistrict(request.getDistrict());
        school.setAddress(request.getAddress());
        school.setContactPhone(request.getContactPhone());
        school.setLogo(request.getLogo());
        school.setStatus(1);

        return schoolRepository.save(school);
    }

    public List<SchoolDTO> getAllSchools() {
        return schoolRepository.findAllActive().stream()
                .map(this::toSchoolDTO)
                .collect(Collectors.toList());
    }

    public List<SchoolDTO> getSchoolsByRegion(String province, String city) {
        return schoolRepository.findByProvinceAndCity(province, city).stream()
                .map(this::toSchoolDTO)
                .collect(Collectors.toList());
    }

    @Transactional
    public Grade createGrade(GradeCreateRequest request) {
        School school = schoolRepository.findById(request.getSchoolId())
                .orElseThrow(() -> new BusinessException("School not found"));

        Grade grade = new Grade();
        grade.setGradeName(request.getGradeName());
        grade.setGradeCode(request.getGradeCode());
        grade.setGradeLevel(request.getGradeLevel());
        grade.setSchool(school);

        return gradeRepository.save(grade);
    }

    public List<GradeDTO> getGradesBySchoolId(Long schoolId) {
        return gradeRepository.findBySchoolId(schoolId).stream()
                .map(this::toGradeDTO)
                .collect(Collectors.toList());
    }

    @Transactional
    public ClassEntity createClass(ClassCreateRequest request) {
        Grade grade = gradeRepository.findById(request.getGradeId())
                .orElseThrow(() -> new BusinessException("Grade not found"));

        School school = schoolRepository.findById(request.getSchoolId())
                .orElseThrow(() -> new BusinessException("School not found"));

        ClassEntity classEntity = new ClassEntity();
        classEntity.setClassName(request.getClassName());
        classEntity.setClassCode(generateClassCode());
        classEntity.setGrade(grade);
        classEntity.setSchool(school);
        classEntity.setAcademicYear(request.getAcademicYear());
        classEntity.setStatus(1);

        if (request.getTeacherId() != null) {
            User teacher = userRepository.findById(request.getTeacherId())
                    .orElseThrow(() -> new BusinessException("Teacher not found"));
            classEntity.setTeacher(teacher);
        }

        return classRepository.save(classEntity);
    }

    public List<ClassDTO> getClassesByGradeId(Long gradeId) {
        return classRepository.findByGradeId(gradeId).stream()
                .map(this::toClassDTO)
                .collect(Collectors.toList());
    }

    public List<ClassDTO> getClassesBySchoolId(Long schoolId) {
        return classRepository.findBySchoolId(schoolId).stream()
                .map(this::toClassDTO)
                .collect(Collectors.toList());
    }

    @Transactional
    public ClassMember joinClassByCode(Long userId, String classCode) {
        ClassEntity classEntity = classRepository.findByClassCode(classCode)
                .orElseThrow(() -> new BusinessException("Class code not found"));

        classMemberRepository.findByClassIdAndUserId(classEntity.getId(), userId)
                .ifPresent(m -> {
                    throw new BusinessException("Already a member of this class");
                });

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException("User not found"));

        ClassMember member = new ClassMember();
        member.setUser(user);
        member.setClassEntity(classEntity);
        member.setRoleCode(RoleEnum.STUDENT);
        member.setJoinType("CODE");
        member.setStatus(0);

        return classMemberRepository.save(member);
    }

    @Transactional
    public void approveClassMember(Long memberId) {
        ClassMember member = classMemberRepository.findById(memberId)
                .orElseThrow(() -> new BusinessException("Member record not found"));

        member.setStatus(1);
        classMemberRepository.save(member);

        User user = member.getUser();
        user.setClassEntity(member.getClassEntity());
        if (user.getSchool() == null) {
            user.setSchool(member.getClassEntity().getSchool());
        }
        userRepository.save(user);
    }

    @Transactional
    public void rejectClassMember(Long memberId) {
        ClassMember member = classMemberRepository.findById(memberId)
                .orElseThrow(() -> new BusinessException("Member record not found"));

        member.setStatus(2);
        classMemberRepository.save(member);
    }

    public List<ClassMember> getPendingMembers(Long classId) {
        return classMemberRepository.findByClassId(classId).stream()
                .filter(m -> m.getStatus() == 0)
                .collect(Collectors.toList());
    }

    @Transactional
    public void assignTeacherToClass(Long classId, Long teacherId) {
        ClassEntity classEntity = classRepository.findById(classId)
                .orElseThrow(() -> new BusinessException("Class not found"));

        User teacher = userRepository.findById(teacherId)
                .orElseThrow(() -> new BusinessException("Teacher not found"));

        classEntity.setTeacher(teacher);
        classRepository.save(classEntity);
    }

    private String generateClassCode() {
        return UUID.randomUUID().toString().substring(0, 8).toUpperCase();
    }

    private SchoolDTO toSchoolDTO(School school) {
        return new SchoolDTO(
                school.getId(),
                school.getSchoolName(),
                school.getSchoolCode(),
                school.getProvince(),
                school.getCity(),
                school.getDistrict(),
                school.getAddress(),
                school.getContactPhone(),
                school.getLogo(),
                school.getStatus()
        );
    }

    private GradeDTO toGradeDTO(Grade grade) {
        return new GradeDTO(
                grade.getId(),
                grade.getGradeName(),
                grade.getGradeCode(),
                grade.getGradeLevel(),
                grade.getSchool().getId(),
                grade.getSchool().getSchoolName()
        );
    }

    private ClassDTO toClassDTO(ClassEntity classEntity) {
        int studentCount = classMemberRepository.findApprovedByClassIdAndRoleCode(
                classEntity.getId(), RoleEnum.STUDENT).size();

        return new ClassDTO(
                classEntity.getId(),
                classEntity.getClassName(),
                classEntity.getClassCode(),
                classEntity.getGrade() != null ? classEntity.getGrade().getId() : null,
                classEntity.getGrade() != null ? classEntity.getGrade().getGradeName() : null,
                classEntity.getSchool() != null ? classEntity.getSchool().getId() : null,
                classEntity.getSchool() != null ? classEntity.getSchool().getSchoolName() : null,
                classEntity.getTeacher() != null ? classEntity.getTeacher().getId() : null,
                classEntity.getTeacher() != null ? classEntity.getTeacher().getRealName() : null,
                classEntity.getAcademicYear(),
                classEntity.getStatus(),
                studentCount
        );
    }
}
