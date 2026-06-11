package com.speak.score.controller;

import com.speak.score.dto.ApiResponse;
import com.speak.score.dto.ClassRankDTO;
import com.speak.score.dto.RankItemDTO;
import com.speak.score.dto.RankingDTO;
import com.speak.score.entity.*;
import com.speak.score.repository.ClassMemberRepository;
import com.speak.score.repository.UserRepository;
import com.speak.score.service.RankingService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/rankings")
@RequiredArgsConstructor
@Api(tags = "排行榜")
public class RankingController {

    private final RankingService rankingService;
    private final UserRepository userRepository;
    private final ClassMemberRepository classMemberRepository;

    @GetMapping("/class/{classId}")
    @ApiOperation("获取班级学生排行榜")
    public ApiResponse<RankingDTO> getClassRanking(
            @PathVariable Long classId,
            @RequestParam(defaultValue = "total") String period,
            @RequestParam(defaultValue = "student_total") String type,
            @RequestParam(defaultValue = "20") int topN,
            Authentication auth) {

        Long currentUserId = (Long) auth.getPrincipal();
        validateClassAccess(currentUserId, classId);

        RankingService.RankPeriod rankPeriod = parsePeriod(period);
        RankingService.RankType rankType = parseType(type);

        List<RankItemDTO> rankings = rankingService.getClassStudentRanking(classId, rankPeriod, rankType, topN);
        RankItemDTO myRank = rankingService.getMyClassRank(classId, currentUserId, rankPeriod, rankType);

        RankingDTO result = new RankingDTO();
        result.setRankType(rankType.getCode());
        result.setPeriod(rankPeriod.getCode());
        result.setRankings(rankings);
        result.setMyRank(myRank);

        return ApiResponse.success(result);
    }

    @GetMapping("/school/{schoolId}/students")
    @ApiOperation("获取学校学生排行榜")
    public ApiResponse<RankingDTO> getSchoolStudentRanking(
            @PathVariable Long schoolId,
            @RequestParam(defaultValue = "total") String period,
            @RequestParam(defaultValue = "student_total") String type,
            @RequestParam(defaultValue = "50") int topN,
            Authentication auth) {

        Long currentUserId = (Long) auth.getPrincipal();
        validateSchoolAccess(currentUserId, schoolId);

        RankingService.RankPeriod rankPeriod = parsePeriod(period);
        RankingService.RankType rankType = parseType(type);

        List<RankItemDTO> rankings = rankingService.getSchoolStudentRanking(schoolId, rankPeriod, rankType, topN);
        RankItemDTO myRank = rankingService.getMySchoolRank(schoolId, currentUserId, rankPeriod, rankType);

        RankingDTO result = new RankingDTO();
        result.setRankType(rankType.getCode());
        result.setPeriod(rankPeriod.getCode());
        result.setRankings(rankings);
        result.setMyRank(myRank);

        return ApiResponse.success(result);
    }

    @GetMapping("/school/{schoolId}/classes")
    @ApiOperation("获取学校班级平均分排行榜")
    public ApiResponse<List<ClassRankDTO>> getClassAverageRanking(
            @PathVariable Long schoolId,
            @RequestParam(defaultValue = "total") String period,
            @RequestParam(defaultValue = "20") int topN,
            Authentication auth) {

        Long currentUserId = (Long) auth.getPrincipal();
        validateSchoolAccess(currentUserId, schoolId);

        RankingService.RankPeriod rankPeriod = parsePeriod(period);

        List<ClassRankDTO> rankings = rankingService.getClassAverageRanking(schoolId, rankPeriod, topN);
        return ApiResponse.success(rankings);
    }

    @GetMapping("/student/{userId}")
    @ApiOperation("获取学生排行榜详情")
    public ApiResponse<RankItemDTO> getStudentDetail(
            @PathVariable Long userId,
            Authentication auth) {

        Long currentUserId = (Long) auth.getPrincipal();
        validateStudentViewAccess(currentUserId, userId);

        RankItemDTO detail = rankingService.getStudentDetail(userId);
        return ApiResponse.success(detail);
    }

    @PostMapping("/refresh")
    @ApiOperation("手动刷新排行榜（管理员用）")
    public ApiResponse<Boolean> refreshRankings(Authentication auth) {
        rankingService.refreshAllRankings();
        return ApiResponse.success(true);
    }

    private RankingService.RankPeriod parsePeriod(String period) {
        try {
            return RankingService.RankPeriod.valueOf(period.toUpperCase());
        } catch (IllegalArgumentException e) {
            return RankingService.RankPeriod.TOTAL;
        }
    }

    private RankingService.RankType parseType(String type) {
        try {
            return RankingService.RankType.valueOf(type.toUpperCase());
        } catch (IllegalArgumentException e) {
            return RankingService.RankType.STUDENT_TOTAL;
        }
    }

    private void validateClassAccess(Long currentUserId, Long classId) {
        User user = userRepository.findById(currentUserId)
                .orElseThrow(() -> new com.speak.score.exception.BusinessException("用户不存在"));

        boolean isEduOffice = user.getRoles().stream()
                .anyMatch(r -> RoleEnum.EDU_OFFICE.name().equals(r.getRoleCode()));
        if (isEduOffice) {
            return;
        }

        boolean isTeacher = user.getRoles().stream()
                .anyMatch(r -> RoleEnum.TEACHER.name().equals(r.getRoleCode()));
        if (isTeacher) {
            List<ClassMember> teacherClasses = classMemberRepository
                    .findByUserId(currentUserId);
            boolean hasAccess = teacherClasses.stream()
                    .anyMatch(cm -> cm.getClassEntity().getId().equals(classId) &&
                            cm.getRoleCode() == RoleEnum.TEACHER &&
                            cm.getStatus() == 1 && !cm.getDeleted());
            if (!hasAccess) {
                throw new com.speak.score.exception.BusinessException("无权访问该班级数据");
            }
            return;
        }

        if (user.getClassEntity() != null && user.getClassEntity().getId().equals(classId)) {
            return;
        }

        throw new com.speak.score.exception.BusinessException("无权访问该班级数据");
    }

    private void validateSchoolAccess(Long currentUserId, Long schoolId) {
        User user = userRepository.findById(currentUserId)
                .orElseThrow(() -> new com.speak.score.exception.BusinessException("用户不存在"));

        boolean isEduOffice = user.getRoles().stream()
                .anyMatch(r -> RoleEnum.EDU_OFFICE.name().equals(r.getRoleCode()));
        if (isEduOffice) {
            return;
        }

        if (user.getSchool() != null && user.getSchool().getId().equals(schoolId)) {
            return;
        }

        throw new com.speak.score.exception.BusinessException("无权访问该学校数据");
    }

    private void validateStudentViewAccess(Long currentUserId, Long targetUserId) {
        if (currentUserId.equals(targetUserId)) {
            return;
        }

        User user = userRepository.findById(currentUserId)
                .orElseThrow(() -> new com.speak.score.exception.BusinessException("用户不存在"));

        boolean isTeacher = user.getRoles().stream()
                .anyMatch(r -> RoleEnum.TEACHER.name().equals(r.getRoleCode()));
        boolean isEduOffice = user.getRoles().stream()
                .anyMatch(r -> RoleEnum.EDU_OFFICE.name().equals(r.getRoleCode()));

        if (isEduOffice) {
            return;
        }

        if (isTeacher) {
            User targetUser = userRepository.findById(targetUserId)
                    .orElseThrow(() -> new com.speak.score.exception.BusinessException("目标用户不存在"));
            if (targetUser.getClassEntity() != null && user.getClassEntity() != null &&
                    targetUser.getClassEntity().getId().equals(user.getClassEntity().getId())) {
                return;
            }
        }

        throw new com.speak.score.exception.BusinessException("无权查看该学生数据");
    }
}
