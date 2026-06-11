import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speak_score_flutter/models/report_info.dart';
import 'package:speak_score_flutter/services/report_service.dart';
import 'package:speak_score_flutter/services/auth_service.dart';
import 'package:speak_score_flutter/widgets/chart_widgets.dart';
import 'package:speak_score_flutter/screens/teacher/student_progress_screen.dart';

class TeacherClassReportScreen extends StatefulWidget {
  final int? classId;
  final String? className;

  const TeacherClassReportScreen({super.key, this.classId, this.className});

  @override
  State<TeacherClassReportScreen> createState() => _TeacherClassReportScreenState();
}

class _TeacherClassReportScreenState extends State<TeacherClassReportScreen>
    with SingleTickerProviderStateMixin {
  final ReportService _reportService = ReportService();
  late TabController _tabController;

  ClassReport? _classReport;
  bool _isLoading = true;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  bool _showPieChart = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReport();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    try {
      final classId = widget.classId?.toString() ??
          context.read<AuthService>().userInfo?.classId?.toString() ??
          '';

      if (classId.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final data = await _reportService.getClassReport(
        classId: int.parse(classId),
        startDate: _startDate,
        endDate: _endDate,
      );

      if (mounted) {
        setState(() {
          _classReport = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
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
      _loadReport();
    }
  }

  Future<void> _exportExcel() async {
    try {
      final classId = widget.classId?.toString() ??
          context.read<AuthService>().userInfo?.classId?.toString() ??
          '';

      if (classId.isEmpty) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正在导出...')),
      );

      final filePath = await _reportService.exportClassReport(
        classId: int.parse(classId),
        startDate: _startDate,
        endDate: _endDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出成功：${filePath ?? ''}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败：$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _sendEmail() async {
    final emailController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('发送报表到邮箱'),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: '邮箱地址',
            hintText: '请输入接收报表的邮箱',
            prefixIcon: Icon(Icons.email),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('发送'),
          ),
        ],
      ),
    );

    if (confirmed == true && emailController.text.trim().isNotEmpty) {
      try {
        final classId = widget.classId?.toString() ??
            context.read<AuthService>().userInfo?.classId?.toString() ??
            '';

        if (classId.isEmpty) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('正在发送邮件...')),
        );

        final success = await _reportService.sendReportByEmail(
          classId: int.parse(classId),
          email: emailController.text.trim(),
          startDate: _startDate,
          endDate: _endDate,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success == true ? '发送成功' : '发送失败'),
              backgroundColor: success == true ? Colors.green : Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('发送失败：$e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final className = widget.className ??
        context.watch<AuthService>().userInfo?.className ??
        '班级报表';

    return Scaffold(
      appBar: AppBar(
        title: Text('$className - 成绩统计'),
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
          : _classReport == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bar_chart, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        '暂无报表数据',
                        style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildDateRangeCard(),
                      const SizedBox(height: 16),
                      _buildStatsGrid(),
                      const SizedBox(height: 16),
                      _buildChartSection(),
                      const SizedBox(height: 16),
                      _buildActionButtons(),
                      const SizedBox(height: 16),
                      _buildStudentProgressEntry(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDateRangeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '统计周期：${_formatDate(_startDate)} ~ ${_formatDate(_endDate)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            TextButton(
              onPressed: _selectDateRange,
              child: const Text('更换'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final report = _classReport!;
    final avgScore = report.averageScore ?? 0.0;
    final completionRate = report.completionRate ?? 0.0;
    final totalStudents = report.totalStudents ?? 0;
    final totalTasks = report.totalTasks ?? 0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(
          '平均分',
          avgScore.toStringAsFixed(1),
          Icons.grade,
          Colors.blue,
          subtitle: '满分100分',
        ),
        _buildStatCard(
          '完成率',
          '${completionRate.toStringAsFixed(1)}%',
          Icons.check_circle,
          Colors.green,
          subtitle: '${report.completedTasks ?? 0}/$totalTasks 任务',
        ),
        _buildStatCard(
          '学生人数',
          '$totalStudents',
          Icons.people,
          Colors.purple,
          subtitle: '班级总人数',
        ),
        _buildStatCard(
          '任务总数',
          '$totalTasks',
          Icons.assignment,
          Colors.orange,
          subtitle: '统计周期内',
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection() {
    final distribution = _classReport?.scoreDistribution ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '分数分布',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('饼图')),
                    ButtonSegment(value: false, label: Text('柱状图')),
                  ],
                  selected: {_showPieChart},
                  onSelectionChanged: (selected) {
                    setState(() => _showPieChart = selected.first);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: _showPieChart
                  ? ScoreDistributionPieChart(distributions: distribution)
                  : ScoreDistributionBarChart(distributions: distribution),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _exportExcel,
            icon: const Icon(Icons.download),
            label: const Text('导出Excel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: _sendEmail,
            icon: const Icon(Icons.email),
            label: const Text('发送邮件'),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentProgressEntry() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.trending_up, color: Colors.blue),
        title: const Text('学生进步曲线'),
        subtitle: const Text('查看学生成绩变化趋势'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const StudentProgressScreen(),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}
