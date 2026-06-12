import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:speak_score_flutter/models/todo_info.dart';
import 'package:speak_score_flutter/services/todo_service.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen>
    with SingleTickerProviderStateMixin {
  final _todoService = TodoService();

  final List<Map<String, dynamic>> _tabs = const [
    {'key': null, 'label': '全部', 'icon': Icons.all_inbox},
    {'key': 'TODO', 'label': '任务', 'icon': Icons.assignment},
    {'key': 'SCORE', 'label': '评分', 'icon': Icons.grade},
    {'key': 'PARENT_REPORT', 'label': '孩子动态', 'icon': Icons.family_restroom},
    {'key': 'WEEKLY_REPORT', 'label': '周报', 'icon': Icons.calendar_view_week},
    {'key': 'REMINDER', 'label': '提醒', 'icon': Icons.alarm},
  ];

  late TabController _tabController;
  final Map<String, List<NotifyMessage>> _messages = {};
  final Map<String, bool> _loading = {};
  final Map<String, bool> _hasMore = {};
  final Map<String, int> _currentPage = {};
  Map<String, int> _unreadByType = {};
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChange);
    for (var tab in _tabs) {
      final key = tab['key'] as String? ?? 'ALL';
      _messages[key] = [];
      _loading[key] = false;
      _hasMore[key] = true;
      _currentPage[key] = 0;
    }
    _loadUnreadCounts();
    _loadNotifications(reset: true);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChange() {
    if (_tabController.indexIsChanging) return;
    final key = _tabs[_tabController.index]['key'] as String? ?? 'ALL';
    if (_messages[key]!.isEmpty && !_loading[key]!) {
      _loadNotifications(reset: true);
    }
  }

  Future<void> _loadUnreadCounts() async {
    try {
      final counts = await _todoService.getUnreadCountByType();
      if (mounted) {
        setState(() => _unreadByType = counts);
      }
    } catch (_) {}
  }

  Future<void> _loadNotifications({bool reset = false}) async {
    final key = _tabs[_tabController.index]['key'] as String? ?? 'ALL';
    if (_loading[key]!) return;
    if (reset) {
      _currentPage[key] = 0;
      _hasMore[key] = true;
      _messages[key] = [];
    }
    if (!_hasMore[key]!) return;

    setState(() => _loading[key] = true);
    try {
      final msgType = _tabs[_tabController.index]['key'] as String?;
      final results = await _todoService.getNotifications(
        msgType: msgType,
        page: _currentPage[key]!,
        size: _pageSize,
      );
      if (mounted) {
        setState(() {
          _messages[key]!.addAll(results);
          _currentPage[key] = _currentPage[key]! + 1;
          _hasMore[key] = results.length == _pageSize;
          _loading[key] = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading[key] = false);
        _showError('加载消息失败，请稍后重试');
      }
    }
  }

  Future<void> _markAllAsRead() async {
    final success = await _todoService.markAllAsRead();
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已全部标记为已读'), backgroundColor: Colors.green),
        );
        _loadUnreadCounts();
        setState(() {
          for (var key in _messages.keys) {
            for (var msg in _messages[key]!) {
              msg = msg.copyWith(isRead: true);
            }
          }
        });
        final key = _tabs[_tabController.index]['key'] as String? ?? 'ALL';
        _messages[key] = _messages[key]!.map((m) => m.copyWith(isRead: true)).toList();
      } else {
        _showError('操作失败');
      }
    }
  }

  Future<void> _onNotificationTap(NotifyMessage msg) async {
    if (msg.isRead != true) {
      await _todoService.markAsRead(msg.id!);
      _loadUnreadCounts();
      final key = _tabs[_tabController.index]['key'] as String? ?? 'ALL';
      final index = _messages[key]!.indexWhere((m) => m.id == msg.id);
      if (index != -1) {
        setState(() {
          _messages[key]![index] = msg.copyWith(isRead: true);
        });
      }
    }
    _handleNavigation(msg);
  }

  void _handleNavigation(NotifyMessage msg) {
    if (msg.relatedType == 'TODO_TASK' && msg.relatedId != null) {
      Navigator.of(context).pushNamed('/todo/detail', arguments: msg.relatedId);
      return;
    }
    _showDetailDialog(msg);
  }

  void _showDetailDialog(NotifyMessage msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(msg.msgTypeIcon, size: 20, color: msg.msgTypeColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(msg.title ?? '通知',
                  style: const TextStyle(fontSize: 16),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: msg.msgTypeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(msg.msgTypeLabel,
                  style: TextStyle(fontSize: 12, color: msg.msgTypeColor)),
            ),
            const SizedBox(height: 12),
            if (msg.senderName != null) ...[
              Text('发送人: ${msg.senderName}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              const SizedBox(height: 8),
            ],
            Text(msg.content ?? '', style: const TextStyle(fontSize: 14)),
            if (msg.extraData != null && msg.extraData!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildExtraDataWidget(msg.extraData!),
            ],
            const SizedBox(height: 12),
            Text(
              msg.createdAt != null ? _formatDateTime(msg.createdAt!) : '',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
        actions: [
          if (msg.relatedType == 'TODO_TASK' && msg.relatedId != null)
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _handleNavigation(msg);
              },
              child: const Text('查看详情'),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildExtraDataWidget(String extraData) {
    try {
      final Map<String, dynamic> data = jsonDecode(extraData);
      final score = data['score'];
      final studentName = data['studentName'];
      final status = data['status'];
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (studentName != null)
              Text('学生：$studentName', style: const TextStyle(fontSize: 13)),
            if (status != null) ...[
              const SizedBox(height: 4),
              Text('状态：$status', style: const TextStyle(fontSize: 13)),
            ],
            if (score != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text('得分：', style: TextStyle(fontSize: 13)),
                  Text(
                    score is num ? score.toStringAsFixed(1) : score.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: (score is num && score >= 90)
                          ? Colors.green
                          : (score is num && score >= 60)
                              ? Colors.blue
                              : Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('消息通知'),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: _tabs.map((tab) {
              final key = tab['key'] as String? ?? 'ALL';
              final unread = key == 'ALL'
                  ? _unreadByType.values.fold<int>(0, (s, v) => s + v)
                  : (_unreadByType[tab['key']] ?? 0);
              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(tab['icon'] as IconData, size: 16),
                    const SizedBox(width: 4),
                    Text(tab['label'] as String),
                    if (unread > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(minWidth: 18),
                        child: Text(
                          unread > 99 ? '99+' : '$unread',
                          style: const TextStyle(fontSize: 10, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('全部已读'),
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: _tabs.map((tab) {
            final key = tab['key'] as String? ?? 'ALL';
            return _buildNotificationList(key);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNotificationList(String key) {
    final list = _messages[key] ?? [];
    final isLoading = _loading[key] ?? false;
    final hasMore = _hasMore[key] ?? false;

    if (list.isEmpty && isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('暂无消息', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
            const SizedBox(height: 8),
            Text('还没有收到任何通知', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadNotifications(reset: true),
      child: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (!isLoading &&
              hasMore &&
              scrollInfo is ScrollEndNotification &&
              scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
            _loadNotifications();
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length + (hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == list.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final msg = list[index];
            return _NotificationCard(
              message: msg,
              onTap: () => _onNotificationTap(msg),
            );
          },
        ),
      ),
    );
  }

  String _formatDateTime(String dateTime) {
    final dt = DateTime.tryParse(dateTime);
    if (dt == null) return dateTime;
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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
  final String? sendStatus;
  final int? retryCount;
  final String? sentAt;
  final String? extraData;

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
    this.sendStatus,
    this.retryCount,
    this.sentAt,
    this.extraData,
  });

  NotifyMessage copyWith({
    int? id,
    String? title,
    String? content,
    String? msgType,
    String? channel,
    int? senderId,
    String? senderName,
    int? receiverId,
    int? relatedId,
    String? relatedType,
    bool? isRead,
    String? readAt,
    String? createdAt,
    String? sendStatus,
    int? retryCount,
    String? sentAt,
    String? extraData,
  }) {
    return NotifyMessage(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      msgType: msgType ?? this.msgType,
      channel: channel ?? this.channel,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      receiverId: receiverId ?? this.receiverId,
      relatedId: relatedId ?? this.relatedId,
      relatedType: relatedType ?? this.relatedType,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      sendStatus: sendStatus ?? this.sendStatus,
      retryCount: retryCount ?? this.retryCount,
      sentAt: sentAt ?? this.sentAt,
      extraData: extraData ?? this.extraData,
    );
  }

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
      sendStatus: json['sendStatus'] as String?,
      retryCount: json['retryCount'] as int?,
      sentAt: json['sentAt'] as String?,
      extraData: json['extraData'] as String?,
    );
  }

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
      case 'SCORE':
        return Icons.grade;
      case 'PARENT_REPORT':
        return Icons.family_restroom;
      case 'WEEKLY_REPORT':
        return Icons.calendar_view_week;
      case 'DAILY_REPORT':
        return Icons.today;
      default:
        return Icons.notifications;
    }
  }

  String get msgTypeLabel {
    switch (msgType) {
      case 'TODO':
        return '任务';
      case 'REMINDER':
        return '提醒';
      case 'URGE':
        return '催办';
      case 'SYSTEM':
        return '系统';
      case 'SCORE':
        return '评分';
      case 'PARENT_REPORT':
        return '孩子动态';
      case 'WEEKLY_REPORT':
        return '周报';
      case 'DAILY_REPORT':
        return '日报';
      default:
        return '通知';
    }
  }

  Color get msgTypeColor {
    switch (msgType) {
      case 'TODO':
        return Colors.blue;
      case 'REMINDER':
        return Colors.orange;
      case 'URGE':
        return Colors.red;
      case 'SYSTEM':
        return Colors.grey;
      case 'SCORE':
        return Colors.green;
      case 'PARENT_REPORT':
        return Colors.purple;
      case 'WEEKLY_REPORT':
        return Colors.teal;
      case 'DAILY_REPORT':
        return Colors.indigo;
      default:
        return Colors.blue;
    }
  }
}

class _NotificationCard extends StatelessWidget {
  final NotifyMessage message;
  final VoidCallback onTap;

  const _NotificationCard({required this.message, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUnread = message.isRead != true;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: isUnread
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: message.msgTypeColor.withValues(alpha: 0.3), width: 1.5),
            )
          : RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isUnread ? message.msgTypeColor : Colors.grey).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  message.msgTypeIcon,
                  size: 20,
                  color: isUnread ? message.msgTypeColor : Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: message.msgTypeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            message.msgTypeLabel,
                            style: TextStyle(
                              fontSize: 10,
                              color: message.msgTypeColor,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            message.title ?? '',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message.content ?? '',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: isUnread ? FontWeight.w400 : FontWeight.normal),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message.createdAt != null
                          ? _formatDateTime(message.createdAt!)
                          : '',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(String dateTime) {
    final dt = DateTime.tryParse(dateTime);
    if (dt == null) return dateTime;
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
