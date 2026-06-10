import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speak_score_flutter/models/material_info.dart';
import 'package:speak_score_flutter/models/user_info.dart';
import 'package:speak_score_flutter/services/auth_service.dart';
import 'package:speak_score_flutter/services/material_service.dart';
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
  final _referenceTextController = TextEditingController();
  final _todoService = TodoService();
  final _orgService = OrganizationService();
  final _materialService = MaterialService();

  String _taskType = 'FOLLOW_READ';
  String _priority = 'NORMAL';
  String _assigneeType = 'CLASS';
  int? _classId;
  int _remindBeforeMin = 30;
  DateTime? _deadlineDate;
  TimeOfDay? _deadlineTime;
  int? _materialId;
  String? _materialTitle;

  List<ClassInfo> _classes = [];
  List<MaterialInfo> _materials = [];
  bool _isLoadingClasses = false;
  bool _isLoadingMaterials = false;
  bool _isSubmitting = false;

  static const List<MapEntry<String, String>> _taskTypeOptions = [
    MapEntry('FOLLOW_READ', '跟读'),
    MapEntry('READ_ALOUD', '朗读'),
    MapEntry('READING', '阅读'),
    MapEntry('PRACTICE', '练习'),
    MapEntry('GENERAL', '通用'),
  ];

  static const List<MapEntry<String, String>> _priorityOptions = [
    MapEntry('LOW', '低'),
    MapEntry('NORMAL', '普通'),
    MapEntry('HIGH', '高'),
    MapEntry('URGENT', '紧急'),
  ];

  static const List<MapEntry<String, String>> _assigneeTypeOptions = [
    MapEntry('CLASS', '班级'),
    MapEntry('INDIVIDUAL', '个人'),
  ];

  @override
  void initState() {
    super.initState();
    _loadClasses();
    _loadMaterials();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _referenceTextController.dispose();
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

  Future<void> _loadMaterials() async {
    setState(() => _isLoadingMaterials = true);
    try {
      final authService = context.read<AuthService>();
      final schoolId = authService.userInfo?.schoolId;
      if (schoolId != null) {
        final materials = await _materialService.searchMaterials(
          schoolId: schoolId,
          page: 0,
          size: 50,
        );
        if (mounted) {
          setState(() {
            _materials = materials;
            _isLoadingMaterials = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingMaterials = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMaterials = false);
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

  Future<void> _pickMaterial() async {
    final selected = await showDialog<MaterialInfo>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('选择学习资料'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: _isLoadingMaterials
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _materials.length,
                  itemBuilder: (context, index) {
                    final material = _materials[index];
                    return ListTile(
                      leading: Icon(material.typeIcon, color: Colors.blue),
                      title: Text(material.title ?? ''),
                      subtitle: Text(
                        '${material.typeLabel} · ${material.fileSizeLabel}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      onTap: () => Navigator.of(ctx).pop(material),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('取消')),
          if (_materialId != null)
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(MaterialInfo(id: -1)),
              child: const Text('清除选择')),
        ],
      ),
    );

    if (selected != null) {
      setState(() {
        if (selected.id == -1) {
          _materialId = null;
          _materialTitle = null;
        } else {
          _materialId = selected.id;
          _materialTitle = selected.title;
        }
      });
    }
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
    if (_taskType == 'FOLLOW_READ' &&
        _referenceTextController.text.trim().isEmpty) {
      _showError('跟读任务必须提供参考文本');
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
        'assigneeType': _assigneeType == 'CLASS' ? 'CLASS' : 'USER',
        'assigneeSchoolId': authService.userInfo?.schoolId,
        'remindBeforeMin': _remindBeforeMin,
        'materialId': _materialId,
        'referenceText': _taskType == 'FOLLOW_READ'
            ? _referenceTextController.text.trim()
            : null,
      };

      if (_assigneeType == 'CLASS') {
        request['assigneeClassId'] = _classId;
      }

      final result = await _todoService.createTodo(request);
      if (mounted) {
        setState(() => _isSubmitting = false);
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('发布成功'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop(true);
        } else {
          _showError('发布失败，请稍后重试');
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showError('发布失败，请稍后重试');
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
        title: const Text('发布打卡任务'),
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
                  labelText: '任务名称 *',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                  hintText: '请输入任务名称',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入任务名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '任务描述',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                  hintText: '请输入任务描述（可选）',
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
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getTaskTypeIcon(entry.key),
                          size: 14,
                          color: isSelected ? Colors.white : Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(entry.value),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _taskType = entry.key);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              if (_taskType == 'FOLLOW_READ') ...[
                TextFormField(
                  controller: _referenceTextController,
                  decoration: const InputDecoration(
                    labelText: '参考文本 *',
                    prefixIcon: Icon(Icons.text_fields),
                    border: OutlineInputBorder(),
                    hintText: '请输入跟读参考文本',
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (_taskType == 'FOLLOW_READ' &&
                        (value == null || value.trim().isEmpty)) {
                      return '跟读任务必须提供参考文本';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
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
                leading: const Icon(Icons.attach_file),
                title: Text(_materialTitle ?? '关联学习资料'),
                subtitle: _materialTitle != null
                    ? Text('已选择', style: TextStyle(fontSize: 12, color: Colors.green[600]))
                    : Text('选择视频或文本资料（可选）',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickMaterial,
              ),
              const Divider(),
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
                        _classId = null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
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
                          labelText: '选择班级 *',
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
                      : const Text('发布任务', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTaskTypeIcon(String type) {
    switch (type) {
      case 'FOLLOW_READ':
        return Icons.record_voice_over;
      case 'READ_ALOUD':
        return Icons.mic;
      case 'READING':
        return Icons.menu_book;
      case 'PRACTICE':
        return Icons.fitness_center;
      default:
        return Icons.assignment;
    }
  }
}
