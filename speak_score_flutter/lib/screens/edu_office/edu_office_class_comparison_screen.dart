import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speak_score_flutter/models/report_info.dart';
import 'package:speak_score_flutter/models/user_info.dart';
import 'package:speak_score_flutter/services/report_service.dart';
import 'package:speak_score_flutter/services/organization_service.dart';
import 'package:speak_score_flutter/services/auth_service.dart';
import 'package:speak_score_flutter/widgets/chart_widgets.dart';

class EduOfficeClassComparisonScreen extends StatefulWidget {
  const EduOfficeClassComparisonScreen({super.key});

  @override
  State<EduOfficeClassComparisonScreen> createState() =>
      _EduOfficeClassComparisonScreenState();
}

class _EduOfficeClassComparisonScreenState
    extends State<EduOfficeClassComparisonScreen> {
  final ReportService _reportService = ReportService();
  final OrganizationService _orgService = OrganizationService();

  List<Grade> _grades = [];
  Grade? _selectedGrade;
  List<ClassComparison> _classComparisons = [];
  bool _isLoadingGrades = true;
  bool _isLoadingData = false;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  bool _showScoreChart = true;

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    setState(() => _isLoadingGrades = true);
    try {
      final schoolId = context.read<AuthService>().userInfo?.schoolId;
      if (schoolId == null) {
        setState(() => _isLoadingGrades = false);
        return;
      }

      final grades = await _orgService.getGradesBySchool(schoolId);

      if (mounted) {
        setState(() {
          _grades = grades;
          _isLoadingGrades = false;
          if (grades.isNotEmpty) {
            _selectedGrade = grades.first;
            _loadComparisonData();
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingGrades = false);
    }
  }

  Future<void> _loadComparisonData() async {
    setState(() => _isLoadingData = true);
    try {
      final schoolId = context.read<AuthService>().userInfo?.schoolId;
      if (schoolId == null) {
        setState(() => _isLoadingData = false);
        return;
      }

      final data = await _reportService.getClassComparison(
        schoolId: schoolId,
        gradeId: _selectedGrade?.id,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (mounted) {
        setState(() {
          _classComparisons = data ?? [];
          _isLoadingData = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingData = false);
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
      _loadComparisonData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final schoolName = context.watch<AuthService>().userInfo?.schoolName ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('班级成绩对比'),
        actions: [
          IconButton(
            onPressed: _selectDateRange,
            icon: const Icon(Icons.date_range),
            tooltip: '选择时间范围',
          ),
        ],
      ),
      body: _isLoadingGrades
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilters(),
                Expanded(
                  child: _isLoadingData
                      ? const Center(child: CircularProgressIndicator())
                      : _buildContent(),
                ),
              ],
            ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey[50],
      child: Row(
        children: [
          Expanded(
            child: _buildGradeDropdown(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${_formatDate(_startDate)} ~ ${_formatDate(_endDate)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeDropdown() {
    if (_grades.isEmpty) {
      return const Text('暂无年级数据', style: TextStyle(fontSize: 13));
    }

    return DropdownButtonFormField<Grade>(
      value: _selectedGrade,
      decoration: InputDecoration(
        labelText: '选择年级',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: [
        const DropdownMenuItem<Grade>(
        value: null,
        child: Text('全部年级'),
      ),
        ..._grades.map((grade) => DropdownMenuItem<Grade>(
          value: grade,
          child: Text(grade.gradeName ?? ''),
        ),
      ],
      onChanged: (value) {
        setState(() => _selectedGrade = value);
        _loadComparisonData();
      },
    );
  }

  Widget _buildContent() {
    if (_classComparisons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              '暂无对比数据',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildChartSection(),
          const SizedBox(height: 16),
          _buildClassList(),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
              const Text(
                '班级对比图表',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('平均分')),
                  ButtonSegment(value: false, label: Text('完成率')),
                ],
                selected: {_showScoreChart},
                onSelectionChanged: (selected) {
                  setState(() => _showScoreChart = selected.first);
                },
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 280,
              child: ClassComparisonBarChart(
                classData: _classComparisons,
                showAverageScore: _showScoreChart,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassList() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '班级详情列表',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          ..._classComparisons.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _buildClassItem(item, index + 1);
          }),
        ],
      ),
    );
  }

  Widget _buildClassItem(ClassComparison item, int rank) {
    final avgScore = item.averageScore ?? 0.0;
    final completionRate = item.completionRate ?? 0.0;

    Color rankColor;
    IconData rankIcon;
    if (rank == 1) {
      rankColor = Colors.amber;
      rankIcon = Icons.emoji_events;
    } else if (rank == 2) {
      rankColor = Colors.grey;
      rankIcon = Icons.workspace_premium;
    } else if (rank == 3) {
      rankColor = Colors.brown;
      rankIcon = Icons.military_tech;
    } else {
      rankColor = Colors.grey[400]!;
      rankIcon = Icons.looks;
    }

    return ListTile(
      leading: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: rankColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(rankIcon, color: rankColor, size: 20),
    ),
      title: Text(
        item.className ?? '',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
          '${item.gradeName ?? ''} · ${item.studentCount ?? 0}人',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
    ),
    trailing: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${avgScore.toStringAsFixed(1)}分',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '完成率 ${completionRate.toStringAsFixed(1)}%',
          style: TextStyle(fontSize: 11, color: Colors.green[700]),
        ),
      ],
    ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}
