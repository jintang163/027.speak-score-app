import 'package:flutter/material.dart';
import 'package:speak_score_flutter/models/todo_info.dart';
import 'package:speak_score_flutter/services/todo_service.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  final _todoService = TodoService();

  List<NotifyMessage> _notifications = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final results = await _todoService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = results;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('加载消息失败，请稍后重试');
      }
    }
  }

  Future<void> _markAllAsRead() async {
    final success = await _todoService.markAllAsRead();
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('已全部标记为已读'), backgroundColor: Colors.green),
        );
        _loadNotifications();
      } else {
        _showError('操作失败');
      }
    }
  }

  Future<void> _onNotificationTap(NotifyMessage msg) async {
    if (msg.isRead != true) {
      await _todoService.markAsRead(msg.id!);
      _loadNotifications();
    }
    _showDetailDialog(msg);
  }

  void _showDetailDialog(NotifyMessage msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(msg.msgTypeIcon, size: 20, color: Colors.blue),
            const SizedBox(width: 8),
            Flexible(
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
            if (msg.senderName != null) ...[
              Text('发送人: ${msg.senderName}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              const SizedBox(height: 8),
            ],
            Text(msg.content ?? '', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            Text(
              msg.createdAt != null ? _formatDateTime(msg.createdAt!) : '',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('消息通知'),
        actions: [
          TextButton.icon(
            onPressed: _markAllAsRead,
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text('全部已读'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none,
                          size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('暂无消息',
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey[500])),
                      const SizedBox(height: 8),
                      Text('还没有收到任何通知',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey[400])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final msg = _notifications[index];
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
              side: BorderSide(
                  color: Colors.blue.withValues(alpha: 0.3), width: 1.5),
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
                  color: (isUnread ? Colors.blue : Colors.grey)
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  message.msgTypeIcon,
                  size: 20,
                  color: isUnread ? Colors.blue : Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            message.title ?? '',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isUnread
                                  ? FontWeight.w600
                                  : FontWeight.normal,
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
                          fontWeight: isUnread
                              ? FontWeight.w400
                              : FontWeight.normal),
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
