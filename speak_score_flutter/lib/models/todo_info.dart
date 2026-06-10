import 'package:flutter/material.dart';

class TodoTask {
  final int? id;
  final String? title;
  final String? description;
  final String? taskType;
  final String? priority;
  final String? status;
  final int? creatorId;
  final String? creatorName;
  final int? assigneeId;
  final String? assigneeName;
  final String? assigneeType;
  final int? assigneeClassId;
  final int? assigneeSchoolId;
  final String? deadline;
  final String? completedAt;
  final int? urgeCount;
  final String? lastUrgeAt;
  final int? remindBeforeMin;
  final bool? remindSent;
  final int? parentTaskId;
  final int? materialId;
  final String? materialTitle;
  final String? materialType;
  final String? referenceText;
  final List<TodoItem>? items;
  final String? createdAt;
  final int? completedCount;
  final int? pendingCount;
  final double? averageScore;

  const TodoTask({
    this.id,
    this.title,
    this.description,
    this.taskType,
    this.priority,
    this.status,
    this.creatorId,
    this.creatorName,
    this.assigneeId,
    this.assigneeName,
    this.assigneeType,
    this.assigneeClassId,
    this.assigneeSchoolId,
    this.deadline,
    this.completedAt,
    this.urgeCount,
    this.lastUrgeAt,
    this.remindBeforeMin,
    this.remindSent,
    this.parentTaskId,
    this.materialId,
    this.materialTitle,
    this.materialType,
    this.referenceText,
    this.items,
    this.createdAt,
    this.completedCount,
    this.pendingCount,
    this.averageScore,
  });

  factory TodoTask.fromJson(Map<String, dynamic> json) {
    return TodoTask(
      id: json['id'] as int?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      taskType: json['taskType'] as String?,
      priority: json['priority'] as String?,
      status: json['status'] as String?,
      creatorId: json['creatorId'] as int?,
      creatorName: json['creatorName'] as String?,
      assigneeId: json['assigneeId'] as int?,
      assigneeName: json['assigneeName'] as String?,
      assigneeType: json['assigneeType'] as String?,
      assigneeClassId: json['assigneeClassId'] as int?,
      assigneeSchoolId: json['assigneeSchoolId'] as int?,
      deadline: json['deadline'] as String?,
      completedAt: json['completedAt'] as String?,
      urgeCount: json['urgeCount'] as int?,
      lastUrgeAt: json['lastUrgeAt'] as String?,
      remindBeforeMin: json['remindBeforeMin'] as int?,
      remindSent: json['remindSent'] as bool?,
      parentTaskId: json['parentTaskId'] as int?,
      materialId: json['materialId'] as int?,
      materialTitle: json['materialTitle'] as String?,
      materialType: json['materialType'] as String?,
      referenceText: json['referenceText'] as String?,
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => TodoItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] as String?,
      completedCount: json['completedCount'] as int?,
      pendingCount: json['pendingCount'] as int?,
      averageScore: (json['averageScore'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'taskType': taskType,
        'priority': priority,
        'status': status,
        'creatorId': creatorId,
        'creatorName': creatorName,
        'assigneeId': assigneeId,
        'assigneeName': assigneeName,
        'assigneeType': assigneeType,
        'assigneeClassId': assigneeClassId,
        'assigneeSchoolId': assigneeSchoolId,
        'deadline': deadline,
        'completedAt': completedAt,
        'urgeCount': urgeCount,
        'lastUrgeAt': lastUrgeAt,
        'remindBeforeMin': remindBeforeMin,
        'remindSent': remindSent,
        'parentTaskId': parentTaskId,
        'materialId': materialId,
        'materialTitle': materialTitle,
        'materialType': materialType,
        'referenceText': referenceText,
        'items': items?.map((e) => e.toJson()).toList(),
        'createdAt': createdAt,
        'completedCount': completedCount,
        'pendingCount': pendingCount,
        'averageScore': averageScore,
      };

  String get taskTypeLabel {
    switch (taskType) {
      case 'FOLLOW_READ':
        return '跟读';
      case 'READ_ALOUD':
        return '朗读';
      case 'READING':
        return '阅读';
      case 'PRACTICE':
        return '练习';
      case 'REVIEW':
        return '复习';
      default:
        return '通用';
    }
  }

  IconData get taskTypeIcon {
    switch (taskType) {
      case 'FOLLOW_READ':
        return Icons.record_voice_over;
      case 'READ_ALOUD':
        return Icons.mic;
      case 'READING':
        return Icons.menu_book;
      case 'PRACTICE':
        return Icons.fitness_center;
      case 'REVIEW':
        return Icons.replay;
      default:
        return Icons.assignment;
    }
  }

  String get priorityLabel {
    switch (priority) {
      case 'LOW':
        return '低';
      case 'NORMAL':
        return '普通';
      case 'HIGH':
        return '高';
      case 'URGENT':
        return '紧急';
      default:
        return '普通';
    }
  }

  Color get priorityColor {
    switch (priority) {
      case 'URGENT':
        return Colors.red;
      case 'HIGH':
        return Colors.orange;
      case 'LOW':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'PENDING':
        return '待办';
      case 'IN_PROGRESS':
        return '进行中';
      case 'COMPLETED':
        return '已完成';
      case 'CANCELLED':
        return '已取消';
      default:
        return '未知';
    }
  }

  bool get isOverdue {
    if (deadline == null || status == 'COMPLETED' || status == 'CANCELLED') {
      return false;
    }
    return DateTime.tryParse(deadline!)?.isBefore(DateTime.now()) ?? false;
  }

  double get completionRate {
    final total = (completedCount ?? 0) + (pendingCount ?? 0);
    if (total == 0) return 0;
    return (completedCount ?? 0) / total;
  }
}

class TodoItem {
  final int? id;
  final int? taskId;
  final int? userId;
  final String? userName;
  final String? status;
  final String? feedback;
  final double? score;
  final String? audioUrl;
  final int? duration;
  final String? completedAt;
  final String? createdAt;
  final double? teacherScore;
  final String? teacherFeedback;
  final String? teacherAudioUrl;
  final bool? needsManualReview;
  final int? retryCount;

  const TodoItem({
    this.id,
    this.taskId,
    this.userId,
    this.userName,
    this.status,
    this.feedback,
    this.score,
    this.audioUrl,
    this.duration,
    this.completedAt,
    this.createdAt,
    this.teacherScore,
    this.teacherFeedback,
    this.teacherAudioUrl,
    this.needsManualReview,
    this.retryCount,
  });

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'] as int?,
      taskId: json['taskId'] as int?,
      userId: json['userId'] as int?,
      userName: json['userName'] as String?,
      status: json['status'] as String?,
      feedback: json['feedback'] as String?,
      score: (json['score'] as num?)?.toDouble(),
      audioUrl: json['audioUrl'] as String?,
      duration: json['duration'] as int?,
      completedAt: json['completedAt'] as String?,
      createdAt: json['createdAt'] as String?,
      teacherScore: (json['teacherScore'] as num?)?.toDouble(),
      teacherFeedback: json['teacherFeedback'] as String?,
      teacherAudioUrl: json['teacherAudioUrl'] as String?,
      needsManualReview: json['needsManualReview'] as bool?,
      retryCount: json['retryCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'taskId': taskId,
        'userId': userId,
        'userName': userName,
        'status': status,
        'feedback': feedback,
        'score': score,
        'audioUrl': audioUrl,
        'duration': duration,
        'completedAt': completedAt,
        'createdAt': createdAt,
        'teacherScore': teacherScore,
        'teacherFeedback': teacherFeedback,
        'teacherAudioUrl': teacherAudioUrl,
        'needsManualReview': needsManualReview,
        'retryCount': retryCount,
      };
}

class TodoTaskProgress {
  final int? taskId;
  final String? title;
  final String? taskType;
  final String? status;
  final String? deadline;
  final int? totalStudents;
  final int? completedCount;
  final int? pendingCount;
  final double? averageScore;
  final double? completionRate;

  const TodoTaskProgress({
    this.taskId,
    this.title,
    this.taskType,
    this.status,
    this.deadline,
    this.totalStudents,
    this.completedCount,
    this.pendingCount,
    this.averageScore,
    this.completionRate,
  });

  factory TodoTaskProgress.fromJson(Map<String, dynamic> json) {
    return TodoTaskProgress(
      taskId: json['taskId'] as int?,
      title: json['title'] as String?,
      taskType: json['taskType'] as String?,
      status: json['status'] as String?,
      deadline: json['deadline'] as String?,
      totalStudents: json['totalStudents'] as int?,
      completedCount: json['completedCount'] as int?,
      pendingCount: json['pendingCount'] as int?,
      averageScore: (json['averageScore'] as num?)?.toDouble(),
      completionRate: (json['completionRate'] as num?)?.toDouble(),
    );
  }

  String get taskTypeLabel {
    switch (taskType) {
      case 'FOLLOW_READ':
        return '跟读';
      case 'READ_ALOUD':
        return '朗读';
      case 'READING':
        return '阅读';
      case 'PRACTICE':
        return '练习';
      case 'REVIEW':
        return '复习';
      default:
        return '通用';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'PENDING':
        return '进行中';
      case 'IN_PROGRESS':
        return '进行中';
      case 'COMPLETED':
        return '已结束';
      case 'CANCELLED':
        return '已取消';
      default:
        return '未知';
    }
  }
}

class SchoolTaskStats {
  final int? schoolId;
  final String? schoolName;
  final int? totalTasks;
  final int? activeTasks;
  final int? completedTasks;
  final int? totalCheckins;
  final double? averageScore;
  final double? completionRate;

  const SchoolTaskStats({
    this.schoolId,
    this.schoolName,
    this.totalTasks,
    this.activeTasks,
    this.completedTasks,
    this.totalCheckins,
    this.averageScore,
    this.completionRate,
  });

  factory SchoolTaskStats.fromJson(Map<String, dynamic> json) {
    return SchoolTaskStats(
      schoolId: json['schoolId'] as int?,
      schoolName: json['schoolName'] as String?,
      totalTasks: json['totalTasks'] as int?,
      activeTasks: json['activeTasks'] as int?,
      completedTasks: json['completedTasks'] as int?,
      totalCheckins: json['totalCheckins'] as int?,
      averageScore: (json['averageScore'] as num?)?.toDouble(),
      completionRate: (json['completionRate'] as num?)?.toDouble(),
    );
  }
}

class NotifyMessage {
  final int? id;
  final String? title;
  final String? content;
  final String? msgType;
  final String? channel;
  final int? senderId;
  final String? senderName;
  final int? receiverId;
  final int? relatedId;
  final String? relatedType;
  final bool? isRead;
  final String? readAt;
  final String? createdAt;

  const NotifyMessage({
    this.id,
    this.title,
    this.content,
    this.msgType,
    this.channel,
    this.senderId,
    this.senderName,
    this.receiverId,
    this.relatedId,
    this.relatedType,
    this.isRead,
    this.readAt,
    this.createdAt,
  });

  factory NotifyMessage.fromJson(Map<String, dynamic> json) {
    return NotifyMessage(
      id: json['id'] as int?,
      title: json['title'] as String?,
      content: json['content'] as String?,
      msgType: json['msgType'] as String?,
      channel: json['channel'] as String?,
      senderId: json['senderId'] as int?,
      senderName: json['senderName'] as String?,
      receiverId: json['receiverId'] as int?,
      relatedId: json['relatedId'] as int?,
      relatedType: json['relatedType'] as String?,
      isRead: json['isRead'] as bool?,
      readAt: json['readAt'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'msgType': msgType,
        'channel': channel,
        'senderId': senderId,
        'senderName': senderName,
        'receiverId': receiverId,
        'relatedId': relatedId,
        'relatedType': relatedType,
        'isRead': isRead,
        'readAt': readAt,
        'createdAt': createdAt,
      };

  IconData get msgTypeIcon {
    switch (msgType) {
      case 'TODO':
        return Icons.assignment;
      case 'REMINDER':
        return Icons.alarm;
      case 'URGE':
        return Icons.notifications_active;
      case 'SYSTEM':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }
}
