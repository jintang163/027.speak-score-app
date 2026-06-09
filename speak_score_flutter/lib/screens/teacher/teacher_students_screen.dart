import 'package:flutter/material.dart';
import 'package:speak_score_flutter/models/user_info.dart';
import 'package:speak_score_flutter/services/organization_service.dart';

class TeacherStudentsScreen extends StatefulWidget {
  const TeacherStudentsScreen({super.key});

  @override
  State<TeacherStudentsScreen> createState() => _TeacherStudentsScreenState();
}

class _TeacherStudentsScreenState extends State<TeacherStudentsScreen> {
  final OrganizationService _orgService = OrganizationService();
  List<ClassInfo> _classes = [];
  ClassInfo? _selectedClass;
  List<Map<String, dynamic>> _students = [];
  bool _isLoadingClasses = false;
  bool _isLoadingStudents = false;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoadingClasses = true);
    try {
      final authService = await _getAuthService();
      final schoolId = authService?.userInfo?.schoolId;
      if (schoolId == null) {
        if (mounted) setState(() => _isLoadingClasses = false);
        return;
      }
      final classes = await _orgService.getClassesBySchool(schoolId);
      if (mounted) {
        setState(() {
          _classes = classes;
          _isLoadingClasses = false;
          if (classes.isNotEmpty) {
            _selectedClass = classes.first;
            _loadStudents();
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingClasses = false);
    }
  }

  Future<dynamic> _getAuthService() async {
    return null;
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoadingStudents = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _students = [];
        _isLoadingStudents = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildClassSelector(),
        Expanded(
          child: _isLoadingStudents
              ? const Center(child: CircularProgressIndicator())
              : _buildStudentList(),
        ),
      ],
    );
  }

  Widget _buildClassSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.blue.withValues(alpha: 0.05),
      child: DropdownButtonFormField<ClassInfo>(
        value: _selectedClass,
        decoration: const InputDecoration(
          labelText: '选择班级',
          prefixIcon: Icon(Icons.class_),
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        items: _classes.map((cls) {
          return DropdownMenuItem(
            value: cls,
            child: Text(cls.className ?? ''),
          );
        }).toList(),
        onChanged: (cls) {
          setState(() => _selectedClass = cls);
          _loadStudents();
        },
        hint: _isLoadingClasses
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('请选择班级'),
      ),
    );
  }

  Widget _buildStudentList() {
    if (_students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              '暂无学生',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
            const SizedBox(height: 8),
            Text(
              '导入或添加学生到班级',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStudents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _students.length,
        itemBuilder: (context, index) {
          final student = _students[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.withValues(alpha: 0.1),
                child: Text(
                  (student['name'] as String? ?? '?')[0],
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
              title: Text(student['name'] ?? ''),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (student['phone'] != null)
                    Text(student['phone'], style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  Text(
                    '完成任务: ${student['taskCount'] ?? 0}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('学生详情功能开发中')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
