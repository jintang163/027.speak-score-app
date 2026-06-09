import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speak_score_flutter/services/auth_service.dart';
import 'package:speak_score_flutter/services/organization_service.dart';
import 'package:speak_score_flutter/models/user_info.dart';

class EduOfficeSchoolScreen extends StatefulWidget {
  const EduOfficeSchoolScreen({super.key});

  @override
  State<EduOfficeSchoolScreen> createState() => _EduOfficeSchoolScreenState();
}

class _EduOfficeSchoolScreenState extends State<EduOfficeSchoolScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final OrganizationService _orgService = OrganizationService();
  List<Grade> _grades = [];
  List<ClassInfo> _classes = [];
  List<UserInfo> _teachers = [];
  bool _isLoadingGrades = false;
  bool _isLoadingClasses = false;
  bool _isLoadingTeachers = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    _loadGrades();
    _loadClasses();
  }

  Future<void> _loadGrades() async {
    setState(() => _isLoadingGrades = true);
    try {
      final schoolId = context.read<AuthService>().userInfo?.schoolId;
      if (schoolId == null) {
        if (mounted) setState(() => _isLoadingGrades = false);
        return;
      }
      final grades = await _orgService.getGradesBySchool(schoolId);
      if (mounted) {
        setState(() {
          _grades = grades;
          _isLoadingGrades = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingGrades = false);
    }
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoadingClasses = true);
    try {
      final schoolId = context.read<AuthService>().userInfo?.schoolId;
      if (schoolId == null) {
        if (mounted) setState(() => _isLoadingClasses = false);
        return;
      }
      final classes = await _orgService.getClassesBySchool(schoolId);
      if (mounted) {
        setState(() {
          _classes = classes;
          _isLoadingClasses = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingClasses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userInfo = context.watch<AuthService>().userInfo;

    return Column(
      children: [
        _buildSchoolInfoCard(userInfo),
        Container(
          color: Colors.purple,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: '年级管理'),
              Tab(text: '班级管理'),
              Tab(text: '教师管理'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildGradeList(),
              _buildClassList(),
              _buildTeacherList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSchoolInfoCard(UserInfo? userInfo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.purple.withValues(alpha: 0.1),
      child: Row(
        children: [
          const Icon(Icons.school, size: 40, color: Colors.purple),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userInfo?.schoolName ?? '未绑定学校',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_grades.length}个年级 · ${_classes.length}个班级',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeList() {
    if (_isLoadingGrades) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_grades.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.grade_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              '暂无年级',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGrades,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _grades.length,
        itemBuilder: (context, index) {
          final grade = _grades[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.purple.withValues(alpha: 0.1),
                child: Text(
                  '${grade.gradeLevel ?? index + 1}',
                  style: const TextStyle(color: Colors.purple),
                ),
              ),
              title: Text(grade.gradeName ?? ''),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('年级详情功能开发中')),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildClassList() {
    if (_isLoadingClasses) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_classes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.class_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              '暂无班级',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadClasses,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _classes.length,
        itemBuilder: (context, index) {
          final cls = _classes[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange.withValues(alpha: 0.1),
                child: const Icon(Icons.class_, color: Colors.orange),
              ),
              title: Text(cls.className ?? ''),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cls.gradeName != null)
                    Text(cls.gradeName!, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  Text(
                    '${cls.studentCount ?? 0}名学生 · 班主任: ${cls.teacherName ?? "未分配"}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('班级详情功能开发中')),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTeacherList() {
    if (_isLoadingTeachers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_teachers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              '暂无教师',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
            const SizedBox(height: 8),
            Text(
              '教师数据将在此显示',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _teachers.length,
      itemBuilder: (context, index) {
        final teacher = _teachers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.withValues(alpha: 0.1),
              child: Text(
                (teacher.nickname ?? teacher.realName ?? '?')[0],
                style: const TextStyle(color: Colors.blue),
              ),
            ),
            title: Text(teacher.nickname ?? teacher.realName ?? ''),
            subtitle: Text(teacher.phone ?? ''),
            trailing: IconButton(
              icon: const Icon(Icons.assignment_ind),
              tooltip: '分配班级',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('分配班级功能开发中')),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
