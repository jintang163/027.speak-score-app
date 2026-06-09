import 'package:flutter/material.dart';
import 'package:speak_score_flutter/models/todo_info.dart';
import 'package:speak_score_flutter/screens/todo/todo_detail_screen.dart';
import 'package:speak_score_flutter/screens/todo/todo_create_screen.dart';
import 'package:speak_score_flutter/services/todo_service.dart';

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen>
    with SingleTickerProviderStateMixin {
  final _todoService = TodoService();
  late final TabController _tabController;

  List<TodoTask> _todos = [];
  bool _isLoading = false;

  static const List<String> _tabLabels = ['全部', '待办', '已完成'];
  static const List<String?> _tabStatusMap = [null, 'PENDING', 'COMPLETED'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadTodos();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _loadTodos();
    }
  }

  Future<void> _loadTodos() async {
    setState(() => _isLoading = true);
    try {
      final status = _tabStatusMap[_tabController.index];
      final results = await _todoService.getMyTodos(status: status);
      if (mounted) {
        setState(() {
          _todos = results;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('加载待办列表失败，请稍后重试');
      }
    }
  }

  void _navigateToDetail(TodoTask todo) {
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (_) => TodoDetailScreen(todoId: todo.id!),
    ))
        .then((_) => _loadTodos());
  }

  void _navigateToCreate() {
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (_) => const TodoCreateScreen(),
    ))
        .then((result) {
      if (result == true) _loadTodos();
    });
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
        title: const Text('我的待办'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabLabels.map((label) => Tab(text: label)).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _todos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('暂无待办',
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey[500])),
                      const SizedBox(height: 8),
                      Text('点击右下角按钮创建新待办',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey[400])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTodos,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _todos.length,
                    itemBuilder: (context, index) {
                      final todo = _todos[index];
                      return _TodoCard(
                        todo: todo,
                        onTap: () => _navigateToDetail(todo),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreate,
        child: const Icon(Icons.add_task),
      ),
    );
  }
}

class _TodoCard extends StatelessWidget {
  final TodoTask todo;
  final VoidCallback onTap;

  const _TodoCard({required this.todo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final overdue = todo.isOverdue;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: overdue
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.red, width: 1.5),
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
                  Expanded(
                    child: Text(
                      todo.title ?? '',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildPriorityBadge(),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 16,
                      color: overdue ? Colors.red : Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    todo.deadline != null
                        ? _formatDeadline(todo.deadline!)
                        : '无截止时间',
                    style: TextStyle(
                      fontSize: 13,
                      color: overdue ? Colors.red : Colors.grey[500],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildStatusBadge(),
                  if (todo.urgeCount != null && todo.urgeCount! > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.notifications_active,
                              size: 12, color: Colors.orange),
                          const SizedBox(width: 2),
                          Text(
                            '催${todo.urgeCount}次',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.orange),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              if (overdue) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.warning, size: 14, color: Colors.red[400]),
                    const SizedBox(width: 4),
                    Text('已逾期',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[400],
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge() {
    final color = todo.priorityColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        todo.priorityLabel,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    switch (todo.status) {
      case 'COMPLETED':
        color = Colors.green;
      case 'CANCELLED':
        color = Colors.grey;
      case 'IN_PROGRESS':
        color = Colors.blue;
      default:
        color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        todo.statusLabel,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _formatDeadline(String deadline) {
    final dt = DateTime.tryParse(deadline);
    if (dt == null) return deadline;
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
