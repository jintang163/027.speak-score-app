import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speak_score_flutter/models/user_info.dart';
import 'package:speak_score_flutter/services/organization_service.dart';

class OrgFormData {
  final String roleCode;
  final int schoolId;
  final String classCode;

  const OrgFormData({
    required this.roleCode,
    required this.schoolId,
    required this.classCode,
  });
}

class SmsSendButton extends StatefulWidget {
  final Future<bool> Function() onSend;
  final bool enabled;

  const SmsSendButton({
    super.key,
    required this.onSend,
    this.enabled = true,
  });

  @override
  State<SmsSendButton> createState() => _SmsSendButtonState();
}

class _SmsSendButtonState extends State<SmsSendButton> {
  int _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final success = await widget.onSend();
    if (success && mounted) {
      setState(() => _countdown = 60);
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _countdown--;
          if (_countdown <= 0) {
            timer.cancel();
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCountingDown = _countdown > 0;
    return SizedBox(
      width: 130,
      height: 48,
      child: OutlinedButton(
        onPressed: (isCountingDown || !widget.enabled) ? null : _handleSend,
        child: Text(
          isCountingDown ? '重新获取(${_countdown}s)' : '获取验证码',
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }
}

class OrganizationFormSection extends StatefulWidget {
  const OrganizationFormSection({super.key});

  @override
  State<OrganizationFormSection> createState() =>
      OrganizationFormSectionState();
}

class OrganizationFormSectionState extends State<OrganizationFormSection> {
  final OrganizationService _orgService = OrganizationService();

  String? _selectedRoleCode;
  School? _selectedSchool;
  Grade? _selectedGrade;
  ClassInfo? _selectedClass;

  List<School> _schools = [];
  List<Grade> _grades = [];
  List<ClassInfo> _classes = [];

  bool _isLoadingSchools = false;
  bool _isLoadingGrades = false;
  bool _isLoadingClasses = false;

  final _classCodeController = TextEditingController();

  static const List<MapEntry<String, String>> _roles = [
    MapEntry('STUDENT', '学生'),
    MapEntry('TEACHER', '老师'),
    MapEntry('ADMIN', '教办'),
  ];

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  @override
  void dispose() {
    _classCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadSchools() async {
    setState(() => _isLoadingSchools = true);
    try {
      final schools = await _orgService.getSchools();
      if (mounted) {
        setState(() {
          _schools = schools;
          _isLoadingSchools = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingSchools = false);
      }
    }
  }

  Future<void> _onSchoolChanged(School? school) async {
    setState(() {
      _selectedSchool = school;
      _selectedGrade = null;
      _selectedClass = null;
      _grades = [];
      _classes = [];
      _isLoadingGrades = true;
    });

    if (school?.id == null) {
      setState(() => _isLoadingGrades = false);
      return;
    }

    try {
      final grades = await _orgService.getGradesBySchool(school!.id!);
      if (mounted) {
        setState(() {
          _grades = grades;
          _isLoadingGrades = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingGrades = false);
      }
    }
  }

  Future<void> _onGradeChanged(Grade? grade) async {
    setState(() {
      _selectedGrade = grade;
      _selectedClass = null;
      _classes = [];
      _isLoadingClasses = true;
    });

    if (grade?.id == null) {
      setState(() => _isLoadingClasses = false);
      return;
    }

    try {
      final classes = await _orgService.getClassesByGrade(grade!.id!);
      if (mounted) {
        setState(() {
          _classes = classes;
          _isLoadingClasses = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingClasses = false);
      }
    }
  }

  OrgFormData? validate() {
    if (_selectedRoleCode == null) {
      _showError('请选择角色');
      return null;
    }
    if (_selectedSchool == null || _selectedSchool!.id == null) {
      _showError('请选择学校');
      return null;
    }

    final manualClassCode = _classCodeController.text.trim();
    if (manualClassCode.isNotEmpty) {
      return OrgFormData(
        roleCode: _selectedRoleCode!,
        schoolId: _selectedSchool!.id!,
        classCode: manualClassCode,
      );
    }

    if (_selectedClass == null || _selectedClass!.classCode == null) {
      _showError('请选择班级或输入班级码');
      return null;
    }

    return OrgFormData(
      roleCode: _selectedRoleCode!,
      schoolId: _selectedSchool!.id!,
      classCode: _selectedClass!.classCode!,
    );
  }

  String? get selectedRoleCode => _selectedRoleCode;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '选择角色',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _roles.map((role) {
            final isSelected = _selectedRoleCode == role.key;
            return ChoiceChip(
              label: Text(role.value),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedRoleCode = isSelected ? null : role.key;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<School>(
          value: _selectedSchool,
          decoration: const InputDecoration(
            labelText: '学校',
            prefixIcon: Icon(Icons.school),
            border: OutlineInputBorder(),
          ),
          items: _schools.map((school) {
            return DropdownMenuItem(
              value: school,
              child: Text(school.schoolName ?? ''),
            );
          }).toList(),
          onChanged: _isLoadingSchools ? null : _onSchoolChanged,
          hint: _isLoadingSchools
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('请选择学校'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<Grade>(
          value: _selectedGrade,
          decoration: InputDecoration(
            labelText: '年级',
            prefixIcon: const Icon(Icons.grade),
            border: const OutlineInputBorder(),
          ),
          items: _grades.map((grade) {
            return DropdownMenuItem(
              value: grade,
              child: Text(grade.gradeName ?? ''),
            );
          }).toList(),
          onChanged: _isLoadingGrades ? null : _onGradeChanged,
          hint: _isLoadingGrades
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('请选择年级'),
          disabledHint: _selectedSchool == null
              ? const Text('请先选择学校')
              : const Text('暂无年级'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<ClassInfo>(
          value: _selectedClass,
          decoration: const InputDecoration(
            labelText: '班级',
            prefixIcon: Icon(Icons.class_),
            border: OutlineInputBorder(),
          ),
          items: _classes.map((cls) {
            return DropdownMenuItem(
              value: cls,
              child: Text(cls.className ?? ''),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedClass = value);
          },
          hint: _isLoadingClasses
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('请选择班级'),
          disabledHint: _selectedGrade == null
              ? const Text('请先选择年级')
              : const Text('暂无班级'),
        ),
        const SizedBox(height: 16),
        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('或', style: TextStyle(color: Colors.grey)),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _classCodeController,
          decoration: const InputDecoration(
            labelText: '班级码加入',
            prefixIcon: Icon(Icons.qr_code),
            border: OutlineInputBorder(),
            hintText: '输入班级码直接加入',
          ),
        ),
      ],
    );
  }
}
