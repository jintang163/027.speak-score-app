import 'package:flutter/material.dart';

class StudentCalendarDay {
  final String? date;
  final String? status;
  final double? score;
  final int? taskCount;
  final int? completedCount;
  final int? itemId;

  const StudentCalendarDay({
    this.date,
    this.status,
    this.score,
    this.taskCount,
    this.completedCount,
    this.itemId,
  });

  factory StudentCalendarDay.fromJson(Map<String, dynamic> json) {
    return StudentCalendarDay(
      date: json['date'] as String?,
      status: json['status'] as String?,
      score: (json['score'] as num?)?.toDouble(),
      taskCount: json['taskCount'] as int?,
      completedCount: json['completedCount'] as int?,
      itemId: json['itemId'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'status': status,
        'score': score,
        'taskCount': taskCount,
        'completedCount': completedCount,
        'itemId': itemId,
      };
}

class StudentCalendar {
  final int? studentId;
  final String? studentName;
  final int? totalDays;
  final int? checkedDays;
  final int? missedDays;
  final int? highScoreDays;
  final double? averageScore;
  final double? completionRate;
  final List<StudentCalendarDay>? days;

  const StudentCalendar({
    this.studentId,
    this.studentName,
    this.totalDays,
    this.checkedDays,
    this.missedDays,
    this.highScoreDays,
    this.averageScore,
    this.completionRate,
    this.days,
  });

  factory StudentCalendar.fromJson(Map<String, dynamic> json) {
    return StudentCalendar(
      studentId: json['studentId'] as int?,
      studentName: json['studentName'] as String?,
      totalDays: json['totalDays'] as int?,
      checkedDays: json['checkedDays'] as int?,
      missedDays: json['missedDays'] as int?,
      highScoreDays: json['highScoreDays'] as int?,
      averageScore: (json['averageScore'] as num?)?.toDouble(),
      completionRate: (json['completionRate'] as num?)?.toDouble(),
      days: (json['days'] as List<dynamic>?)
          ?.map((e) => StudentCalendarDay.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'studentName': studentName,
        'totalDays': totalDays,
        'checkedDays': checkedDays,
        'missedDays': missedDays,
        'highScoreDays': highScoreDays,
        'averageScore': averageScore,
        'completionRate': completionRate,
        'days': days?.map((e) => e.toJson()).toList(),
      };
}

class ScoreDistribution {
  final String? level;
  final String? range;
  final int? count;
  final double? percentage;

  const ScoreDistribution({
    this.level,
    this.range,
    this.count,
    this.percentage,
  });

  factory ScoreDistribution.fromJson(Map<String, dynamic> json) {
    return ScoreDistribution(
      level: json['level'] as String?,
      range: json['range'] as String?,
      count: json['count'] as int?,
      percentage: (json['percentage'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'level': level,
        'range': range,
        'count': count,
        'percentage': percentage,
      };
}

class ClassReport {
  final int? classId;
  final String? className;
  final int? totalStudents;
  final int? totalTasks;
  final int? completedTasks;
  final double? averageScore;
  final double? completionRate;
  final List<ScoreDistribution>? scoreDistribution;

  const ClassReport({
    this.classId,
    this.className,
    this.totalStudents,
    this.totalTasks,
    this.completedTasks,
    this.averageScore,
    this.completionRate,
    this.scoreDistribution,
  });

  factory ClassReport.fromJson(Map<String, dynamic> json) {
    return ClassReport(
      classId: json['classId'] as int?,
      className: json['className'] as String?,
      totalStudents: json['totalStudents'] as int?,
      totalTasks: json['totalTasks'] as int?,
      completedTasks: json['completedTasks'] as int?,
      averageScore: (json['averageScore'] as num?)?.toDouble(),
      completionRate: (json['completionRate'] as num?)?.toDouble(),
      scoreDistribution: (json['scoreDistribution'] as List<dynamic>?)
          ?.map((e) => ScoreDistribution.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'classId': classId,
        'className': className,
        'totalStudents': totalStudents,
        'totalTasks': totalTasks,
        'completedTasks': completedTasks,
        'averageScore': averageScore,
        'completionRate': completionRate,
        'scoreDistribution': scoreDistribution?.map((e) => e.toJson()).toList(),
      };
}

class StudentProgress {
  final String? date;
  final double? averageScore;
  final int? taskCount;
  final int? completedCount;

  const StudentProgress({
    this.date,
    this.averageScore,
    this.taskCount,
    this.completedCount,
  });

  factory StudentProgress.fromJson(Map<String, dynamic> json) {
    return StudentProgress(
      date: json['date'] as String?,
      averageScore: (json['averageScore'] as num?)?.toDouble(),
      taskCount: json['taskCount'] as int?,
      completedCount: json['completedCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'averageScore': averageScore,
        'taskCount': taskCount,
        'completedCount': completedCount,
      };
}

class StudentProgressSeries {
  final int? studentId;
  final String? studentName;
  final List<StudentProgress>? progress;

  const StudentProgressSeries({
    this.studentId,
    this.studentName,
    this.progress,
  });

  factory StudentProgressSeries.fromJson(Map<String, dynamic> json) {
    return StudentProgressSeries(
      studentId: json['studentId'] as int?,
      studentName: json['studentName'] as String?,
      progress: (json['progress'] as List<dynamic>?)
          ?.map((e) => StudentProgress.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'studentName': studentName,
        'progress': progress?.map((e) => e.toJson()).toList(),
      };
}

class ClassComparison {
  final int? classId;
  final String? className;
  final String? gradeName;
  final int? studentCount;
  final double? averageScore;
  final double? completionRate;
  final int? totalTasks;

  const ClassComparison({
    this.classId,
    this.className,
    this.gradeName,
    this.studentCount,
    this.averageScore,
    this.completionRate,
    this.totalTasks,
  });

  factory ClassComparison.fromJson(Map<String, dynamic> json) {
    return ClassComparison(
      classId: json['classId'] as int?,
      className: json['className'] as String?,
      gradeName: json['gradeName'] as String?,
      studentCount: json['studentCount'] as int?,
      averageScore: (json['averageScore'] as num?)?.toDouble(),
      completionRate: (json['completionRate'] as num?)?.toDouble(),
      totalTasks: json['totalTasks'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'classId': classId,
        'className': className,
        'gradeName': gradeName,
        'studentCount': studentCount,
        'averageScore': averageScore,
        'completionRate': completionRate,
        'totalTasks': totalTasks,
      };
}
