import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speak_score_flutter/models/todo_info.dart';
import 'package:speak_score_flutter/screens/todo/checkin_screen.dart';
import 'package:speak_score_flutter/screens/todo/score_detail_screen.dart';
import 'package:speak_score_flutter/screens/todo/teacher_review_screen.dart';
import 'package:speak_score_flutter/services/auth_service.dart';
import 'package:speak_score_flutter/services/todo_service.dart';

class TodoDetailScreen extends StatefulWidget {
  final int todoId;

  const TodoDetailScreen({super.key, required this.todoId});

  @override
  State<TodoDetailScreen> createState() => _TodoDetailScreenState();
}

class _TodoDetailScreenState extends State<TodoDetailScreen> {
  final _todoService = TodoService();
  final _feedbackController = TextEditingController();

  TodoTask? _todo;
  bool _isLoading = true;
  bool _isCompleting = false;
  bool _isUrging = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    try {
      final detail = await _todoService.getTodoDetail(widget.todoId);
      if (mounted) {
        setState(() {
          _todo = detail;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('加载待办详情失败');
      }
    }
  }

  bool get _isAssignee {
    final userId = context.read<AuthService>().userInfo?.id;
    return _todo?.assigneeId != null && _todo!.assigneeId == userId;
  }

  TodoItem? get _myItem {
    final userId = context.read<AuthService>().userInfo?.id;
    if (userId == null || _todo?.items == null) return null;
    for (final item in _todo!.items!) {
      if (item.userId == userId) return item;
    }
    return null;
  }

  bool get _isParticipant {
    return _myItem != null;
  }

  bool get _isCreator {
    final userId = context.read<AuthService>().userInfo?.id;
    return _todo?.creatorId != null && _todo!.creatorId == userId;
  }

  Future<void> _completeTodo() async {
    final feedback = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('完成待办'),
        content: TextField(
          controller: _feedbackController,
          decoration: const InputDecoration(
            labelText: '完成反馈（可选）',
            border: OutlineInputBorder(),
            hintText: '输入完成反馈...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.of(ctx)
                .pop(_feedbackController.text.trim().isEmpty
                    ? null
                    : _feedbackController.text.trim()),
            child: const Text('确认完成'),
          ),
        ],
      ),
    );

    if (feedback == null) return;

    setState(() => _isCompleting = true);
    try {
      final success = await _todoService.completeTodoItem(
        widget.todoId,
        feedback: feedback,
      );
      if (mounted) {
        setState(() => _isCompleting = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('已完成'), backgroundColor: Colors.green),
          );
          _feedbackController.clear();
          _loadDetail();
        } else {
          _showError('完成操作失败');
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isCompleting = false);
        _showError('完成操作失败');
      }
    }
  }

  Future<void> _urgeTodo() async {
    setState(() => _isUrging = true);
    try {
      final success = await _todoService.urgeTodo(widget.todoId);
      if (mounted) {
        setState(() => _isUrging = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('已催办'), backgroundColor: Colors.green),
          );
          _loadDetail();
        } else {
          _showError('催办失败');
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isUrging = false);
        _showError('催办失败');
      }
    }
  }

  Future<void> _navigateToCheckin() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CheckinScreen(
          taskId: widget.todoId,
          referenceText: _todo?.referenceText,
          materialTitle: _todo?.materialTitle,
        ),
      ),
    );
    if (result == true && mounted) {
      _loadDetail();
    }
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
        title: Text(_todo?.title ?? '待办详情'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _todo == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('加载失败',
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey[500])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDetail,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoSection(),
                        const SizedBox(height: 16),
                        if (_todo!.items != null &&
                            _todo!.items!.isNotEmpty)
                          _buildItemsSection(),
                        const SizedBox(height: 16),
                        _buildActionSection(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildInfoSection() {
    final t = _todo!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.title ?? '',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildPriorityBadge(t.priority),
              ],
            ),
            const SizedBox(height: 8),
            if (t.description != null && t.description!.isNotEmpty) ...[
              Text(t.description!,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700])),
              const SizedBox(height: 12),
            ],
            const Divider(height: 24),
            _buildInfoRow(Icons.flag, '状态', t.statusLabel),
            _buildInfoRow(Icons.access_time, '截止时间',
                t.deadline != null ? _formatDateTime(t.deadline!) : '无'),
            _buildInfoRow(Icons.person, '创建者', t.creatorName ?? '-'),
            _buildInfoRow(Icons.assignment_ind, '负责人',
                t.assigneeName ?? '-'),
            _buildInfoRow(Icons.category, '类型', t.taskType ?? '-'),
            _buildInfoRow(
                Icons.schedule, '创建时间', t.createdAt ?? '-'),
            if (t.completedAt != null)
              _buildInfoRow(
                  Icons.check_circle, '完成时间', t.completedAt!),
            if (t.urgeCount != null && t.urgeCount! > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.notifications_active,
                        size: 16, color: Colors.orange),
                    const SizedBox(width: 6),
                    Text(
                      '已催办 ${t.urgeCount} 次',
                      style: const TextStyle(
                          color: Colors.orange, fontSize: 13),
                    ),
                    if (t.lastUrgeAt != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '最近: ${_formatDateTime(t.lastUrgeAt!)}',
                        style: TextStyle(
                            color: Colors.orange[300], fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (t.isOverdue) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning, size: 16, color: Colors.red),
                    const SizedBox(width: 6),
                    const Text('已逾期',
                        style:
                            TextStyle(color: Colors.red, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '执行人列表',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ..._todo!.items!.map((item) => _buildItemCard(item)),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToScoreDetail(TodoItem item) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ScoreDetailScreen(
          itemId: item.id!,
          audioUrl: item.audioUrl,
          referenceText: _todo?.referenceText,
          item: item,
        ),
      ),
    );
  }

  Future<void> _navigateToTeacherReview(TodoItem item) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TeacherReviewScreen(
          itemId: item.id!,
          studentAudioUrl: item.audioUrl,
          referenceText: _todo?.referenceText,
          item: item,
        ),
      ),
    );
    if (result == true && mounted) {
      _loadDetail();
    }
  }

  Widget _buildItemCard(TodoItem item) {
    Color statusColor;
    String statusLabel;
    switch (item.status) {
      case 'COMPLETED':
        statusColor = Colors.green;
        statusLabel = '已完成';
      case 'PENDING_SCORE':
        statusColor = Colors.orange;
        statusLabel = '待评分';
      case 'NEEDS_REVIEW':
        statusColor = Colors.red;
        statusLabel = '待批改';
      case 'CANCELLED':
        statusColor = Colors.grey;
        statusLabel = '已取消';
      case 'IN_PROGRESS':
        statusColor = Colors.blue;
        statusLabel = '进行中';
      default:
        statusColor = Colors.orange;
        statusLabel = '待办';
    }

    final canViewScore =
        item.status == 'COMPLETED' || item.status == 'PENDING_SCORE';
    final canReview = item.status == 'NEEDS_REVIEW' && _isCreator;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canViewScore
              ? () => _navigateToScoreDetail(item)
              : canReview
                  ? () => _navigateToTeacherReview(item)
                  : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: statusColor.withValues(alpha: 0.1),
                  child: Icon(
                    item.status == 'COMPLETED'
                        ? Icons.check
                        : Icons.person_outline,
                    size: 16,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(item.userName ?? '-',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500)),
                          if (item.status == 'NEEDS_REVIEW') ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('待批改',
                                  style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ],
                      ),
                      if (item.score != null)
                        Text('AI评分: ${item.score!.toStringAsFixed(0)}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.amber[700])),
                      if (item.teacherScore != null)
                        Text(
                            '教师评分: ${item.teacherScore!.toStringAsFixed(0)}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.purple[700])),
                      if (item.feedback != null && item.feedback!.isNotEmpty)
                        Text(item.feedback!,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
                if (canViewScore || canReview) ...[
                  const SizedBox(width: 4),
                  Icon(
                    canReview ? Icons.rate_review : Icons.visibility,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionSection() {
    final myItem = _myItem;
    final canComplete = _isParticipant &&
        myItem?.status != 'COMPLETED' &&
        myItem?.status != 'REJECTED' &&
        myItem?.status != 'PENDING_SCORE' &&
        _todo?.status != 'COMPLETED' &&
        _todo?.status != 'CANCELLED';
    final canUrge = _isCreator &&
        _todo?.status != 'COMPLETED' &&
        _todo?.status != 'CANCELLED';
    final canCheckin = _isParticipant &&
        myItem?.status == 'PENDING' &&
        (_todo?.taskType == 'FOLLOW_READ' || _todo?.taskType == 'READ_ALOUD');

    if (!canComplete && !canUrge && !canCheckin) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (canCheckin)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _navigateToCheckin,
                  icon: const Icon(Icons.mic),
                  label: const Text('开始打卡'),
                  style:
                      FilledButton.styleFrom(backgroundColor: Colors.green),
                ),
              ),
            if (canCheckin && (canComplete || canUrge))
              const SizedBox(height: 12),
            Row(
              children: [
                if (canComplete)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isCompleting ? null : _completeTodo,
                      icon: _isCompleting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check),
                      label: const Text('完成'),
                      style:
                          FilledButton.styleFrom(backgroundColor: Colors.green),
                    ),
                  ),
                if (canComplete && canUrge) const SizedBox(width: 12),
                if (canUrge)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isUrging ? null : _urgeTodo,
                      icon: _isUrging
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.notifications_active,
                              color: Colors.orange),
                      label: const Text('催办',
                          style: TextStyle(color: Colors.orange)),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.orange)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const Spacer(),
          Flexible(
              child: Text(value,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(String? priority) {
    final color = _todo?.priorityColor ?? Colors.blue;
    final label = _todo?.priorityLabel ?? '普通';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  String _formatDateTime(String dateTime) {
    final dt = DateTime.tryParse(dateTime);
    if (dt == null) return dateTime;
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
