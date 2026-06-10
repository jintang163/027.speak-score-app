import 'package:flutter/material.dart';
import 'package:speak_score_flutter/models/todo_info.dart';
import 'package:speak_score_flutter/screens/teacher/task_progress_screen.dart';
import 'package:speak_score_flutter/screens/todo/todo_create_screen.dart';
import 'package:speak_score_flutter/screens/todo/todo_detail_screen.dart';
import 'package:speak_score_flutter/services/todo_service.dart';

class TeacherTaskScreen extends StatefulWidget {
  const TeacherTaskScreen({super.key});

  @override
  State<TeacherTaskScreen> createState() => _TeacherTaskScreenState();
}

class _TeacherTaskScreenState extends State<TeacherTaskScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TodoService _todoService = TodoService();

  List<TodoTask> _allTasks = [];
  List<TodoTask> _activeTasks = [];
  List<TodoTask> _completedTasks = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final all = await _todoService.getCreatedTodos();
      final active = await _todoService.getCreatedTodos(status: 'PENDING');
      final completed = await _todoService.getCreatedTodos(status: 'COMPLETED');
      if (mounted) {
        setState(() {
          _allTasks = all;
          _activeTasks = active;
          _completedTasks = completed;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToCreate() {
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (_) => const TodoCreateScreen(),
    ))
        .then((result) {
      if (result == true) _loadTasks();
    });
  }

  void _navigateToDetail(TodoTask task) {
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (_) => TodoDetailScreen(todoId: task.id!),
    ))
        .then((_) => _loadTasks());
  }

  void _navigateToProgress(TodoTask task) {
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (_) => TaskProgressScreen(taskId: task.id!),
    ))
        .then((_) => _loadTasks());
  }

  Future<void> _copyTask(TodoTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('复制任务'),
        content: Text('确定要复制任务「${task.title}」吗？复制后的任务截止时间默认为明天。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确定复制'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _todoService.copyTask(task.id!);
      if (mounted) {
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('复制成功'), backgroundColor: Colors.green),
          );
          _loadTasks();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('复制失败'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.blue,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: '全部'),
              Tab(text: '进行中'),
              Tab(text: '已结束'),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTaskList(_allTasks),
                    _buildTaskList(_activeTasks),
                    _buildTaskList(_completedTasks),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildTaskList(List<TodoTask> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              '暂无打卡任务',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
            const SizedBox(height: 8),
            Text(
              '点击下方按钮发布新任务',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return _TaskCard(
            task: task,
            onTap: () => _navigateToDetail(task),
            onProgress: () => _navigateToProgress(task),
            onCopy: () => _copyTask(task),
          );
        },
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TodoTask task;
  final VoidCallback onTap;
  final VoidCallback onProgress;
  final VoidCallback onCopy;

  const _TaskCard({required this.task, required this.onTap, required this.onProgress, required this.onCopy});

  Color _statusColor(String? status) {
    switch (status) {
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.grey;
      case 'IN_PROGRESS':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'COMPLETED':
        return '已结束';
      case 'CANCELLED':
        return '已取消';
      case 'IN_PROGRESS':
        return '进行中';
      default:
        return '进行中';
    }
  }

  String _formatDeadline(String? deadline) {
    if (deadline == null) return '';
    final dt = DateTime.tryParse(deadline);
    if (dt == null) return deadline;
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = task.completedCount ?? 0;
    final pendingCount = task.pendingCount ?? 0;
    final total = completedCount + pendingCount;
    final completionRate = total > 0 ? completedCount / total : 0.0;
    final avgScore = task.averageScore;
    final isOverdue = task.isOverdue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: isOverdue
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.red, width: 1),
            )
          : RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(task.taskTypeIcon, size: 20, color: Colors.blue),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title ?? '',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                task.taskTypeLabel,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.blue),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.access_time,
                                size: 14,
                                color: isOverdue ? Colors.red : Colors.grey[500]),
                            const SizedBox(width: 2),
                            Text(
                              _formatDeadline(task.deadline),
                              style: TextStyle(
                                fontSize: 12,
                                color: isOverdue ? Colors.red : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(task.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _statusLabel(task.status),
                      style: TextStyle(
                        color: _statusColor(task.status),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              if (task.materialTitle != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.attach_file, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        task.materialTitle!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('完成率',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600])),
                            const SizedBox(width: 4),
                            Text(
                              '${(completionRate * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: completionRate.clamp(0.0, 1.0),
                            backgroundColor: Colors.grey[200],
                            color: Colors.green,
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$completedCount/$total 已打卡',
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (avgScore != null)
                    Column(
                      children: [
                        Text('平均分',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            avgScore.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  if (avgScore == null && pendingCount > 0)
                    Column(
                      children: [
                        Text('未打卡',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$pendingCount',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              if (task.status != 'COMPLETED' && task.status != 'CANCELLED')
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        onPressed: onProgress,
                        icon: const Icon(Icons.bar_chart, size: 16),
                        label: const Text('查看进度', style: TextStyle(fontSize: 13)),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: onCopy,
                        icon: const Icon(Icons.content_copy, size: 16),
                        label: const Text('复制任务', style: TextStyle(fontSize: 13)),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
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
}
