import 'package:flutter/material.dart';
import 'package:speak_score_flutter/models/todo_info.dart';
import 'package:speak_score_flutter/services/todo_service.dart';

class TaskProgressScreen extends StatefulWidget {
  final int taskId;

  const TaskProgressScreen({super.key, required this.taskId});

  @override
  State<TaskProgressScreen> createState() => _TaskProgressScreenState();
}

class _TaskProgressScreenState extends State<TaskProgressScreen> {
  final TodoService _todoService = TodoService();
  TodoTaskProgress? _progress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);
    try {
      final progress = await _todoService.getTaskProgress(widget.taskId);
      if (mounted) {
        setState(() {
          _progress = progress;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('任务进度'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _progress == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('无法加载任务进度',
                          style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 16),
                      FilledButton(
                          onPressed: _loadProgress, child: const Text('重试')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProgress,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildTaskHeader(),
                      const SizedBox(height: 16),
                      _buildProgressOverview(),
                      const SizedBox(height: 16),
                      _buildCompletionChart(),
                      const SizedBox(height: 16),
                      _buildScoreDistribution(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildTaskHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _progress!.taskType == 'FOLLOW_READ'
                      ? Icons.record_voice_over
                      : _progress!.taskType == 'READ_ALOUD'
                          ? Icons.mic
                          : Icons.assignment,
                  color: Colors.blue,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _progress!.title ?? '',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _progress!.taskTypeLabel,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.blue),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _progress!.status == 'COMPLETED'
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _progress!.status == 'COMPLETED' ? '已结束' : '进行中',
                              style: TextStyle(
                                fontSize: 12,
                                color: _progress!.status == 'COMPLETED'
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_progress!.deadline != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '截止: ${_formatDeadline(_progress!.deadline!)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressOverview() {
    final completed = _progress!.completedCount ?? 0;
    final pending = _progress!.pendingCount ?? 0;
    final total = _progress!.totalStudents ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('完成概览',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildOverviewItem(
                    '总人数', total, Colors.purple, Icons.people),
                const SizedBox(width: 12),
                _buildOverviewItem(
                    '已打卡', completed, Colors.green, Icons.check_circle),
                const SizedBox(width: 12),
                _buildOverviewItem(
                    '未打卡', pending, Colors.orange, Icons.pending),
                const SizedBox(width: 12),
                _buildOverviewItem(
                  '平均分',
                  _progress!.averageScore != null
                      ? _progress!.averageScore!.toStringAsFixed(1)
                      : '-',
                  Colors.blue,
                  Icons.star,
                  isText: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewItem(
      String label, dynamic value, Color color, IconData icon,
      {bool isText = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              isText ? value.toString() : '$value',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionChart() {
    final rate = _progress!.completionRate;
    final completed = _progress!.completedCount ?? 0;
    final total = _progress!.totalStudents ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('完成率',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: rate / 100,
                      minHeight: 20,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        rate >= 80
                            ? Colors.green
                            : rate >= 50
                                ? Colors.orange
                                : Colors.red,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${rate.toStringAsFixed(1)}%',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$completed / $total 人已完成',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreDistribution() {
    final avg = _progress!.averageScore;
    if (avg == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('评分统计',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Center(
                child: Text('暂无评分数据',
                    style: TextStyle(color: Colors.grey[500])),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('评分统计',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  avg.toStringAsFixed(1),
                  style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue),
                ),
                const SizedBox(width: 8),
                const Text('/ 100',
                    style: TextStyle(
                        fontSize: 18, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildScoreLevel('优秀', '≥90', Colors.green),
                _buildScoreLevel('良好', '70-89', Colors.blue),
                _buildScoreLevel('一般', '50-69', Colors.orange),
                _buildScoreLevel('待提升', '<50', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreLevel(String label, String range, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500, color: color)),
          Text(range, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        ],
      ),
    );
  }

  String _formatDeadline(String deadline) {
    try {
      final dt = DateTime.parse(deadline);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return deadline;
    }
  }
}
