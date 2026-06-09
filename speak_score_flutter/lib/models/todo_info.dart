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
  final List<TodoItem>? items;
  final String? createdAt;

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
    this.items,
    this.createdAt,
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
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => TodoItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] as String?,
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
        'items': items?.map((e) => e.toJson()).toList(),
        'createdAt': createdAt,
      };

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
}

class TodoItem {
  final int? id;
  final int? taskId;
  final int? userId;
  final String? userName;
  final String? status;
  final String? feedback;
  final String? completedAt;
  final String? createdAt;

  const TodoItem({
    this.id,
    this.taskId,
    this.userId,
    this.userName,
    this.status,
    this.feedback,
    this.completedAt,
    this.createdAt,
  });

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'] as int?,
      taskId: json['taskId'] as int?,
      userId: json['userId'] as int?,
      userName: json['userName'] as String?,
      status: json['status'] as String?,
      feedback: json['feedback'] as String?,
      completedAt: json['completedAt'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'taskId': taskId,
        'userId': userId,
        'userName': userName,
        'status': status,
        'feedback': feedback,
        'completedAt': completedAt,
        'createdAt': createdAt,
      };
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
