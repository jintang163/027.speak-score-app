import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speak_score_flutter/models/report_info.dart';
import 'package:speak_score_flutter/models/user_info.dart';
import 'package:speak_score_flutter/services/report_service.dart';
import 'package:speak_score_flutter/services/organization_service.dart';
import 'package:speak_score_flutter/services/auth_service.dart';
import 'package:speak_score_flutter/widgets/chart_widgets.dart';

class StudentProgressScreen extends StatefulWidget {
  final int? classId;
  final String? className;
  final int? studentId;

  const StudentProgressScreen({super.key, this.classId, this.className, this.studentId});

  @override
  State<StudentProgressScreen> createState() => _StudentProgressScreenState();
}

class _StudentProgressScreenState extends State<StudentProgressScreen> {
  final ReportService _reportService = ReportService();
  final OrganizationService _orgService = OrganizationService();

  List<UserInfo> _students = [];
  UserInfo? _selectedStudent;
  StudentProgressSeries? _progressData;
  bool _isLoading = true;
  bool _isLoadingProgress = false;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  bool get _isParentView => widget.studentId != null;

  @override
  void initState() {
    super.initState();
    if (_isParentView) {
      _loadParentStudent();
    } else {
      _loadStudents();
    }
  }

  Future<void> _loadParentStudent() async {
    setState(() => _isLoading = true);
    try {
      _selectedStudent = UserInfo(
        id: widget.studentId,
        realName: '孩子',
      );
      if (mounted) {
        setState(() => _isLoading = false);
        _loadProgress();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      final classId = widget.classId ??
          context.read<AuthService>().userInfo?.classId;

      if (classId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final students = await _orgService.getStudentsByClass(classId);

      if (mounted) {
        setState(() {
          _students = students;
          _isLoading = false;
          if (students.isNotEmpty) {
            _selectedStudent = students.first;
            _loadProgress();
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProgress() async {
    if (_selectedStudent == null && !_isParentView) return;

    setState(() => _isLoadingProgress = true);
    try {
      final targetStudentId = _isParentView ? widget.studentId : _selectedStudent!.id;
      final data = await _reportService.getStudentProgress(
        studentId: targetStudentId,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (mounted) {
        setState(() {
          _progressData = data;
          _isLoadingProgress = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingProgress = false);
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadProgress();
    }
  }

  void _onStudentSelected(UserInfo? student) {
    if (student == null) return;
    setState(() => _selectedStudent = student);
    _loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    final className = widget.className ??
        context.watch<AuthService>().userInfo?.className ??
        '';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isParentView ? '学习进步曲线' : '$className 学生进步曲线'),
        actions: [
          IconButton(
            onPressed: _selectDateRange,
            icon: const Icon(Icons.date_range),
            tooltip: '选择时间范围',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty && !_isParentView
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        '暂无学生数据',
                        style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    if (!_isParentView) _buildStudentSelector(),
                    _buildDateRangeBar(),
                    Expanded(
                      child: _isLoadingProgress
                          ? const Center(child: CircularProgressIndicator())
                          : _buildProgressChart(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildStudentSelector() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _students.length,
        itemBuilder: (context, index) {
          final student = _students[index];
          final isSelected = _selectedStudent?.id == student.id;
          return GestureDetector(
            onTap: () => _onStudentSelected(student),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey[300]!,
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor:
                          isSelected ? Colors.white : Colors.blue[100],
                      child: Text(
                        student.realName?.substring(0, 1) ?? '?',
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.blue : Colors.blue[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      student.realName ?? '未知',
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateRangeBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[50],
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
          const SizedBox(width: 6),
          Text(
            '${_formatDate(_startDate)} ~ ${_formatDate(_endDate)}',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
          const Spacer(),
          TextButton(
            onPressed: _selectDateRange,
            child: const Text('更换时间', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChart() {
    final progress = _progressData?.progress ?? [];

    if (progress.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              '该时间段内无成绩数据',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    final scores = progress
        .where((p) => p.averageScore != null)
        .map((p) => p.averageScore!)
        .toList();

    double? avgScore;
    if (scores.isNotEmpty) {
      avgScore = scores.reduce((a, b) => a + b) / scores.length;
    } else {
      avgScore = null;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${_selectedStudent?.realName ?? ''} 的成绩趋势',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      _buildSummaryChip('平均分', avgScore, Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: ProgressLineChart(progressData: progress),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildStatsCards(),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String label, double? value, Color color) {
    if (value == null || value.isNaN) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: ${value.toStringAsFixed(1)}',
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildStatsCards() {
    final progress = _progressData?.progress ?? [];
    if (progress.isEmpty) return const SizedBox.shrink();

    final scores = progress
        .where((p) => p.averageScore != null)
        .map((p) => p.averageScore!)
        .toList();

    if (scores.isEmpty) return const SizedBox.shrink();

    final maxScore = scores.reduce((a, b) => a > b ? a : b);
    final minScore = scores.reduce((a, b) => a < b ? a : b);
    final avgScore = scores.reduce((a, b) => a + b) / scores.length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            '最高分',
            maxScore.toStringAsFixed(1),
            Icons.trending_up,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '最低分',
            minScore.toStringAsFixed(1),
            Icons.trending_down,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '平均分',
            avgScore.toStringAsFixed(1),
            Icons.grade,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}
