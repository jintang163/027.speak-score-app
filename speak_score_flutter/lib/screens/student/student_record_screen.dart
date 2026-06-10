import 'package:flutter/material.dart';
import 'package:speak_score_flutter/models/todo_info.dart';
import 'package:speak_score_flutter/screens/todo/score_detail_screen.dart';
import 'package:speak_score_flutter/services/todo_service.dart';

class StudentRecordScreen extends StatefulWidget {
  const StudentRecordScreen({super.key});

  @override
  State<StudentRecordScreen> createState() => _StudentRecordScreenState();
}

class _StudentRecordScreenState extends State<StudentRecordScreen> {
  final _todoService = TodoService();
  List<TodoTask> _completedTasks = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await _todoService.getMyTodos(status: 'COMPLETED');
      final pendingScoreTasks = await _todoService.getMyTodos(status: 'PENDING_SCORE');
      if (mounted) {
        setState(() {
          _completedTasks = [...pendingScoreTasks, ...tasks];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return '--';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}分${s}秒';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return dateStr;
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'COMPLETED':
        return Colors.green;
      case 'PENDING_SCORE':
        return Colors.orange;
      case 'NEEDS_REVIEW':
        return Colors.red;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'COMPLETED':
        return '已评分';
      case 'PENDING_SCORE':
        return '待评分';
      case 'NEEDS_REVIEW':
        return '待批改';
      case 'REJECTED':
        return '已退回';
      default:
        return '未知';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_completedTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic_none_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              '暂无录音',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
            const SizedBox(height: 8),
            Text(
              '完成打卡任务后录音会显示在这里',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    Future<void> _navigateToScoreDetail(TodoTask task) async {
      final item = task.items?.isNotEmpty == true ? task.items!.first : null;
      if (item?.id == null) return;
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ScoreDetailScreen(
            itemId: item!.id!,
            audioUrl: item.audioUrl,
            referenceText: task.referenceText,
            item: item,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecords,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _completedTasks.length,
        itemBuilder: (context, index) {
          final task = _completedTasks[index];
          final item = task.items?.isNotEmpty == true ? task.items!.first : null;
          final canViewDetail = item?.id != null &&
              (task.status == 'COMPLETED' ||
                  task.status == 'PENDING_SCORE' ||
                  task.status == 'NEEDS_REVIEW');
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: canViewDetail ? () => _navigateToScoreDetail(task) : null,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(task.taskTypeIcon, size: 20, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              task.title ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color:
                                  _statusColor(task.status).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _statusLabel(task.status),
                              style: TextStyle(
                                color: _statusColor(task.status),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.timer, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            _formatDuration(item?.duration),
                            style:
                                TextStyle(color: Colors.grey[500], fontSize: 13),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.star, size: 14, color: Colors.amber[700]),
                          const SizedBox(width: 4),
                          Text(
                            (item?.teacherScore ?? item?.score ?? task.averageScore)
                                    ?.toStringAsFixed(1) ??
                                '--',
                            style: TextStyle(
                              color: Colors.amber[700],
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatDate(item?.completedAt ?? task.completedAt),
                            style:
                                TextStyle(color: Colors.grey[400], fontSize: 12),
                          ),
                          if (canViewDetail) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: Colors.grey[400],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
