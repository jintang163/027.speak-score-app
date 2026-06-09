import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speak_score_flutter/models/user_info.dart';
import 'package:speak_score_flutter/services/auth_service.dart';
import 'package:speak_score_flutter/services/organization_service.dart';
import 'package:speak_score_flutter/services/todo_service.dart';

class TodoCreateScreen extends StatefulWidget {
  const TodoCreateScreen({super.key});

  @override
  State<TodoCreateScreen> createState() => _TodoCreateScreenState();
}

class _TodoCreateScreenState extends State<TodoCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _todoService = TodoService();
  final _orgService = OrganizationService();

  String _taskType = 'HOMEWORK';
  String _priority = 'NORMAL';
  String _assigneeType = 'INDIVIDUAL';
  int? _assigneeId;
  int? _classId;
  int _remindBeforeMin = 30;
  DateTime? _deadlineDate;
  TimeOfDay? _deadlineTime;

  List<ClassInfo> _classes = [];
  bool _isLoadingClasses = false;
  bool _isSubmitting = false;

  static const List<MapEntry<String, String>> _taskTypeOptions = [
    MapEntry('HOMEWORK', '作业'),
    MapEntry('PRACTICE', '练习'),
    MapEntry('EXAM_PREP', '备考'),
    MapEntry('OTHER', '其他'),
  ];

  static const List<MapEntry<String, String>> _priorityOptions = [
    MapEntry('LOW', '低'),
    MapEntry('NORMAL', '普通'),
    MapEntry('HIGH', '高'),
    MapEntry('URGENT', '紧急'),
  ];

  static const List<MapEntry<String, String>> _assigneeTypeOptions = [
    MapEntry('INDIVIDUAL', '个人'),
    MapEntry('CLASS', '班级'),
  ];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoadingClasses = true);
    try {
      final authService = context.read<AuthService>();
      final schoolId = authService.userInfo?.schoolId;
      if (schoolId != null) {
        final classes = await _orgService.getClassesBySchool(schoolId);
        if (mounted) {
          setState(() {
            _classes = classes;
            _isLoadingClasses = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingClasses = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingClasses = false);
    }
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deadlineDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _deadlineTime ?? TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      _deadlineDate = date;
      _deadlineTime = time;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_deadlineDate == null || _deadlineTime == null) {
      _showError('请选择截止时间');
      return;
    }
    if (_assigneeType == 'CLASS' && _classId == null) {
      _showError('请选择班级');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final deadline = DateTime(
        _deadlineDate!.year,
        _deadlineDate!.month,
        _deadlineDate!.day,
        _deadlineTime!.hour,
        _deadlineTime!.minute,
      );

      final authService = context.read<AuthService>();
      final request = <String, dynamic>{
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'taskType': _taskType,
        'priority': _priority,
        'deadline': deadline.toIso8601String(),
        'assigneeType': _assigneeType,
        'assigneeSchoolId': authService.userInfo?.schoolId,
        'remindBeforeMin': _remindBeforeMin,
      };

      if (_assigneeType == 'INDIVIDUAL') {
        request['assigneeId'] = _assigneeId;
      } else {
        request['assigneeClassId'] = _classId;
      }

      final result = await _todoService.createTodo(request);
      if (mounted) {
        setState(() => _isSubmitting = false);
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('创建成功'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop(true);
        } else {
          _showError('创建失败，请稍后重试');
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showError('创建失败，请稍后重试');
      }
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
        title: const Text('创建待办'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '标题 *',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                  hintText: '请输入待办标题',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入标题';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '描述',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                  hintText: '请输入待办描述（可选）',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const Text('任务类型',
                  style:
                      TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _taskTypeOptions.map((entry) {
                  final isSelected = _taskType == entry.key;
                  return ChoiceChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _taskType = entry.key);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('优先级',
                  style:
                      TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _priorityOptions.map((entry) {
                  final isSelected = _priority == entry.key;
                  return ChoiceChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _priority = entry.key);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: const Text('截止时间'),
                subtitle: _deadlineDate != null && _deadlineTime != null
                    ? Text(
                        '${_deadlineDate!.year}-${_deadlineDate!.month.toString().padLeft(2, '0')}-${_deadlineDate!.day.toString().padLeft(2, '0')} ${_deadlineTime!.hour.toString().padLeft(2, '0')}:${_deadlineTime!.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 13))
                    : Text('请选择截止时间',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey[500])),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickDeadline,
              ),
              const Divider(),
              const SizedBox(height: 8),
              const Text('指派类型',
                  style:
                      TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _assigneeTypeOptions.map((entry) {
                  final isSelected = _assigneeType == entry.key;
                  return ChoiceChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _assigneeType = entry.key;
                        _assigneeId = null;
                        _classId = null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              if (_assigneeType == 'INDIVIDUAL')
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '指派用户ID',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                    hintText: '请输入用户ID',
                  ),
                  onChanged: (value) {
                    _assigneeId = int.tryParse(value);
                  },
                ),
              if (_assigneeType == 'CLASS')
                _isLoadingClasses
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : DropdownButtonFormField<int>(
                        value: _classId,
                        decoration: const InputDecoration(
                          labelText: '选择班级',
                          prefixIcon: Icon(Icons.class_),
                          border: OutlineInputBorder(),
                        ),
                        items: _classes
                            .map((cls) => DropdownMenuItem<int>(
                                  value: cls.id,
                                  child: Text(cls.className ?? ''),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() => _classId = value);
                        },
                        hint: const Text('请选择班级'),
                      ),
              const SizedBox(height: 16),
              Text('提前提醒: $_remindBeforeMin 分钟',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              Slider(
                value: _remindBeforeMin.toDouble(),
                min: 5,
                max: 120,
                divisions: 23,
                label: '$_remindBeforeMin 分钟',
                onChanged: (value) {
                  setState(() => _remindBeforeMin = value.toInt());
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('创建', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
