import 'package:flutter/material.dart';
import 'package:speak_score_flutter/models/user_info.dart';
import 'package:speak_score_flutter/services/parent_service.dart';

class ParentBindScreen extends StatefulWidget {
  const ParentBindScreen({super.key});

  @override
  State<ParentBindScreen> createState() => _ParentBindScreenState();
}

class _ParentBindScreenState extends State<ParentBindScreen> {
  final ParentService _parentService = ParentService();
  List<ParentStudent> _children = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() => _isLoading = true);
    final children = await _parentService.getMyChildren();
    if (mounted) {
      setState(() {
        _children = children;
        _isLoading = false;
      });
    }
  }

  Future<void> _showBindDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => const _BindChildDialog(),
    );

    if (result != null && mounted) {
      try {
        final child = await _parentService.bindChild(
          phone: result['phone'] as String,
          relation: result['relation'] as String?,
        );
        if (child != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('绑定成功'), backgroundColor: Colors.green),
            );
          }
          _loadChildren();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('绑定失败：${e.toString().replaceAll('Exception: ', '')}')),
          );
        }
      }
    }
  }

  Future<void> _handleUnbind(ParentStudent child) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('解除绑定'),
        content: Text('确定要解除与「${child.studentName ?? '孩子'}」的绑定吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && child.studentId != null) {
      final success = await _parentService.unbindChild(child.studentId!);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已解除绑定')),
        );
        _loadChildren();
      }
    }
  }

  Future<void> _handleSetPrimary(ParentStudent child, bool isPrimary) async {
    if (child.studentId == null) return;
    final success = await _parentService.setPrimary(child.studentId!, isPrimary);
    if (success) {
      _loadChildren();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('家长绑定'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadChildren,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  if (_children.isEmpty)
                    _buildEmptyState()
                  else
                    ..._children.map((child) => _buildChildCard(child)),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showBindDialog,
        icon: const Icon(Icons.add),
        label: const Text('添加孩子'),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.family_restroom, color: Colors.blue, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '我的孩子',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '已绑定 ${_children.length} 个孩子',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          children: [
            Icon(Icons.person_add_disabled, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '还没有绑定的孩子',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              '点击右下角按钮添加孩子，实时查看孩子的学习动态',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildCard(ParentStudent child) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  child: Text(
                    (child.studentName ?? '?')[0],
                    style: const TextStyle(fontSize: 20, color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            child.studentName ?? '未知',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (child.isPrimary == true) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '主联系人',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.amber,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (child.relation != null)
                        Text(
                          '关系：${child.relation}',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      if (child.schoolName != null || child.className != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            [child.schoolName, child.className]
                                .where((e) => e != null)
                                .join(' · '),
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    switch (value) {
                      case 'primary':
                        _handleSetPrimary(child, !(child.isPrimary ?? false));
                        break;
                      case 'unbind':
                        _handleUnbind(child);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'primary',
                      child: Text(child.isPrimary == true ? '取消主联系人' : '设为主联系人'),
                    ),
                    const PopupMenuItem(
                      value: 'unbind',
                      child: Text('解除绑定', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        '/parent/child/calendar',
                        arguments: child.studentId,
                      );
                    },
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: const Text('作业日历'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        '/parent/child/progress',
                        arguments: child.studentId,
                      );
                    },
                    icon: const Icon(Icons.show_chart, size: 18),
                    label: const Text('学习进度'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BindChildDialog extends StatefulWidget {
  const _BindChildDialog();

  @override
  State<_BindChildDialog> createState() => _BindChildDialogState();
}

class _BindChildDialogState extends State<_BindChildDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _relationController = TextEditingController(text: '爸爸');
  bool _isSubmitting = false;

  final List<String> _relationOptions = const ['爸爸', '妈妈', '爷爷', '奶奶', '外公', '外婆', '其他'];

  @override
  void dispose() {
    _phoneController.dispose();
    _relationController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSubmitting = true);
      Navigator.of(context).pop({
        'phone': _phoneController.text.trim(),
        'relation': _relationController.text,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('绑定孩子'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '请输入孩子账号的手机号进行绑定',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: '孩子手机号',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入手机号';
                }
                if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value)) {
                  return '请输入正确的手机号';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _relationController.text,
              decoration: const InputDecoration(
                labelText: '与孩子关系',
                prefixIcon: Icon(Icons.family_restroom),
                border: OutlineInputBorder(),
              ),
              items: _relationOptions
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  _relationController.text = value;
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('绑定'),
        ),
      ],
    );
  }
}
