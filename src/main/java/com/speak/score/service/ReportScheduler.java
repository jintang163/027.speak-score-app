package com.speak.score.service;

import com.speak.score.config.NotificationConfig;
import com.speak.score.dto.ClassReportDTO;
import com.speak.score.dto.SchoolTaskStatsDTO;
import com.speak.score.dto.ScoreDistributionDTO;
import com.speak.score.entity.*;
import com.speak.score.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.temporal.TemporalAdjusters;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Component
@RequiredArgsConstructor
public class ReportScheduler {

    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd");

    private final ReportService reportService;
    private final TodoService todoService;
    private final NotificationService notificationService;
    private final NotificationConfig notificationConfig;

    private final ClassRepository classRepository;
    private final SchoolRepository schoolRepository;
    private final UserRepository userRepository;
    private final WeComConfigRepository weComConfigRepository;
    private final ClassMemberRepository classMemberRepository;
    private final ParentStudentRepository parentStudentRepository;

    @Scheduled(cron = "${notification.weCom.weeklyReportCron:0 0 18 ? * MON}")
    @Transactional
    public void generateWeeklyReports() {
        log.info("Starting weekly report generation...");
        long start = System.currentTimeMillis();

        LocalDate today = LocalDate.now();
        LocalDate lastMonday = today.with(TemporalAdjusters.previous(DayOfWeek.MONDAY));
        LocalDate lastSunday = lastMonday.plusDays(6);
        String period = lastMonday.format(DATE_FORMATTER) + " ~ " + lastSunday.format(DATE_FORMATTER);

        List<ClassEntity> classes = classRepository.findAll().stream()
                .filter(c -> !Boolean.TRUE.equals(c.getDeleted()))
                .collect(Collectors.toList());

        int successCount = 0;
        for (ClassEntity classEntity : classes) {
            try {
                ClassReportDTO report = reportService.getClassReport(
                        classEntity.getId(), lastMonday, lastSunday);

                String markdown = buildWeeklyMarkdown(report, period);
                String title = "【" + classEntity.getClassName() + "】班级周报 - " + period;

                List<Long> receiverIds = collectStudentAndParentIds(classEntity.getId());

                if (!receiverIds.isEmpty()) {
                    notificationService.sendBatchNotification(
                            null, receiverIds, title, markdown,
                            MsgType.WEEKLY_REPORT, classEntity.getId(), "CLASS_REPORT");
                }

                if (classEntity.getSchool() != null) {
                    notificationService.sendWeComMarkdown(
                            classEntity.getSchool().getId(), "WEEKLY", markdown);
                }

                successCount++;
            } catch (Exception e) {
                log.error("Failed to generate weekly report for class: {}", classEntity.getId(), e);
            }
        }

        long cost = System.currentTimeMillis() - start;
        log.info("Weekly report generation completed: {}/{} classes in {}ms",
                successCount, classes.size(), cost);
    }

    @Scheduled(cron = "${notification.weCom.dailyReportCron:0 0 18 * * ?}")
    @Transactional
    public void generateDailyReports() {
        LocalDate yesterday = LocalDate.now().minusDays(1);
        generateDailyReports(yesterday);
    }

    @Transactional
    public void generateDailyReports(LocalDate date) {
        log.info("Starting daily report generation for date: {}...", date);
        long start = System.currentTimeMillis();

        String dateStr = date.format(DATE_FORMATTER);
        LocalDate startDate = date;
        LocalDate endDate = date;

        List<School> schools = schoolRepository.findAllActive();

        int successCount = 0;
        for (School school : schools) {
            try {
                SchoolTaskStatsDTO stats = todoService.getSchoolTaskStats(school.getId(), startDate, endDate);
                stats.setSchoolName(school.getSchoolName());

                String markdown = buildDailyMarkdown(stats, dateStr);

                notificationService.sendWeComMarkdown(
                        school.getId(), "DAILY", markdown);

                successCount++;
            } catch (Exception e) {
                log.error("Failed to generate daily report for school: {}", school.getId(), e);
            }
        }

        long cost = System.currentTimeMillis() - start;
        log.info("Daily report generation completed: {}/{} schools in {}ms",
                successCount, schools.size(), cost);
    }

    private String buildWeeklyMarkdown(ClassReportDTO report, String period) {
        StringBuilder sb = new StringBuilder();
        sb.append("## 📊 ").append(report.getClassName()).append(" 班级周报\n\n");
        sb.append("**统计周期：** ").append(period).append("\n\n");
        sb.append("---\n\n");
        sb.append("### 📈 学习概览\n\n");
        sb.append("- 📝 任务数：**").append(report.getTotalTasks()).append("**\n");
        sb.append("- ✅ 完成率：**").append(String.format("%.2f", report.getCompletionRate())).append("%**\n");
        sb.append("- 📊 平均分：**")
                .append(report.getAverageScore() != null ? String.format("%.2f", report.getAverageScore()) : "-")
                .append("**\n\n");
        sb.append("### 🎯 分数分布\n\n");

        List<ScoreDistributionDTO> distribution = report.getScoreDistribution();
        if (distribution != null && !distribution.isEmpty()) {
            for (ScoreDistributionDTO d : distribution) {
                sb.append("- **").append(d.getLevel()).append("** (")
                        .append(d.getRange()).append(")：")
                        .append(d.getCount()).append("人 (")
                        .append(String.format("%.2f", d.getPercentage())).append("%)\n");
            }
        }

        return sb.toString();
    }

    private String buildDailyMarkdown(SchoolTaskStatsDTO stats, String dateStr) {
        StringBuilder sb = new StringBuilder();
        sb.append("## 🏫 ").append(stats.getSchoolName()).append(" 校级日报\n\n");
        sb.append("**统计日期：** ").append(dateStr).append("\n\n");
        sb.append("---\n\n");
        sb.append("### 📈 任务概览\n\n");
        sb.append("- 📝 总任务数：**").append(stats.getTotalTasks()).append("**\n");
        sb.append("- 🔄 进行中：**").append(stats.getActiveTasks()).append("**\n");
        sb.append("- ✅ 已完成：**").append(stats.getCompletedTasks()).append("**\n");
        sb.append("- 📚 总打卡次数：**").append(stats.getTotalCheckins()).append("**\n");
        sb.append("- 📊 完成率：**").append(String.format("%.2f", stats.getCompletionRate())).append("%**\n");
        sb.append("- 🎯 平均分数：**")
                .append(stats.getAverageScore() != null ? String.format("%.2f", stats.getAverageScore()) : "-")
                .append("**\n");

        return sb.toString();
    }

    private List<Long> collectStudentAndParentIds(Long classId) {
        List<Long> result = new ArrayList<>();

        List<ClassMember> studentMembers = classMemberRepository
                .findByClassIdAndRoleCodeAndStatusAndDeletedFalse(classId, RoleEnum.STUDENT);

        List<Long> studentIds = studentMembers.stream()
                .map(m -> m.getUser().getId())
                .distinct()
                .collect(Collectors.toList());

        result.addAll(studentIds);

        if (!studentIds.isEmpty()) {
            List<ParentStudent> parentRelations = parentStudentRepository
                    .findByStudentIdInAndDeletedFalse(studentIds);

            List<Long> parentIds = parentRelations.stream()
                    .map(ParentStudent::getParentId)
                    .distinct()
                    .collect(Collectors.toList());

            result.addAll(parentIds);
        }

        return result.stream().distinct().collect(Collectors.toList());
    }
}
