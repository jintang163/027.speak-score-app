import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:speak_score_flutter/models/report_info.dart';
import 'package:speak_score_flutter/services/report_service.dart';
import 'package:speak_score_flutter/services/auth_service.dart';
import 'package:speak_score_flutter/screens/todo/score_detail_screen.dart';

class StudentCalendarScreen extends StatefulWidget {
  const StudentCalendarScreen({super.key});

  @override
  State<StudentCalendarScreen> createState() => _StudentCalendarScreenState();
}

class _StudentCalendarScreenState extends State<StudentCalendarScreen> {
  final ReportService _reportService = ReportService();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  StudentCalendar? _calendarData;
  bool _isLoading = true;
  Map<DateTime, StudentCalendarDay> _dayMap = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadCalendarData();
  }

  Future<void> _loadCalendarData() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0);

      final data = await _reportService.getStudentCalendar(
        startDate: startDate,
        endDate: endDate,
      );

      if (mounted && data != null) {
        final dayMap = <DateTime, StudentCalendarDay>{};
        for (final day in data.days ?? []) {
          if (day.date != null) {
            final date = DateTime.parse(day.date!);
            final key = DateTime(date.year, date.month, date.day);
            dayMap[key] = day;
          }
        }

        setState(() {
          _calendarData = data;
          _dayMap = dayMap;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onMonthChanged(DateTime focusedDay) async {
    setState(() {
      _focusedDay = focusedDay;
      _isLoading = true;
    });

    try {
      final startDate = DateTime(focusedDay.year, focusedDay.month, 1);
      final endDate = DateTime(focusedDay.year, focusedDay.month + 1, 0);

      final data = await _reportService.getStudentCalendar(
        startDate: startDate,
        endDate: endDate,
      );

      if (mounted && data != null) {
        final dayMap = <DateTime, StudentCalendarDay>{};
        for (final day in data.days ?? []) {
          if (day.date != null) {
            final date = DateTime.parse(day.date!);
            final key = DateTime(date.year, date.month, date.day);
            dayMap[key] = day;
          }
        }

        setState(() {
          _calendarData = data;
          _dayMap = dayMap;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

    final dayKey = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    final dayData = _dayMap[dayKey];

    if (dayData != null && dayData.itemId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ScoreDetailScreen(
            itemId: dayData.itemId!,
            audioUrl: null,
            referenceText: null,
            item: null,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userInfo = context.watch<AuthService>().userInfo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('作业日历'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildStatsCard(),
                _buildCalendar(),
                if (_selectedDay != null) _buildDayDetail(),
              ],
            ),
    );
  }

  Widget _buildStatsCard() {
    final data = _calendarData;
    if (data == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.blue.withOpacity(0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            '已打卡',
            '${data.checkedDays ?? 0}',
            Colors.green,
            Icons.check_circle,
          ),
          _buildStatItem(
            '缺卡',
            '${data.missedDays ?? 0}',
            Colors.red,
            Icons.cancel,
          ),
          _buildStatItem(
            '高分',
            '${data.highScoreDays ?? 0}',
            Colors.amber,
            Icons.star,
          ),
          _buildStatItem(
            '平均分',
            data.averageScore?.toStringAsFixed(1) ?? '-',
            Colors.blue,
            Icons.grade,
            isText: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    Color color,
    IconData icon, {
    bool isText = false,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: _onDaySelected,
      onPageChanged: _onMonthChanged,
      onFormatChanged: (format) {
        setState(() => _calendarFormat = format);
      },
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        selectedDecoration: const BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
        markerDecoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
      ),
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) {
          final dayKey = DateTime(day.year, day.month, day.day);
          final dayData = _dayMap[dayKey];

          if (dayData == null || dayData.status == 'NONE') {
            return Center(
              child: Text(
                '${day.day}',
                style: TextStyle(color: Colors.grey[400]),
              ),
            );
          }

          final status = dayData.status;
          final isHighScore = status == 'HIGH_SCORE';
          final isCompleted = status == 'COMPLETED' || isHighScore;
          final isMissed = status == 'MISSED';
          final isPending = status == 'PENDING';

          Color bgColor = Colors.transparent;
          Color textColor = Colors.black87;

          if (isCompleted) {
            bgColor = Colors.green.withOpacity(0.2);
            textColor = Colors.green[700]!;
          } else if (isMissed) {
            bgColor = Colors.red.withOpacity(0.2);
            textColor = Colors.red[700]!;
          } else if (isPending) {
            bgColor = Colors.orange.withOpacity(0.1);
            textColor = Colors.orange[700]!;
          }

          return Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (isHighScore)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Icon(
                      Icons.star,
                      size: 12,
                      color: Colors.amber[700],
                    ),
                  ),
                if (isPending)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Icon(
                      Icons.schedule,
                      size: 12,
                      color: Colors.orange[700],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
    );
  }

  Widget _buildDayDetail() {
    final dayKey = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
    );
    final dayData = _dayMap[dayKey];

    if (dayData == null || dayData.status == 'NONE') {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy, size: 60, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                '当日无作业任务',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    final status = dayData.status;
    final isHighScore = status == 'HIGH_SCORE';
    final isCompleted = status == 'COMPLETED' || isHighScore;
    final isMissed = status == 'MISSED';
    final isPending = status == 'PENDING';

    IconData statusIcon;
    Color statusColor;
    String statusText;

    if (isCompleted) {
      statusIcon = Icons.check_circle;
      statusColor = Colors.green;
      statusText = isHighScore ? '优秀完成 ⭐' : '已完成';
    } else if (isMissed) {
      statusIcon = Icons.cancel;
      statusColor = Colors.red;
      statusText = '已缺卡';
    } else {
      statusIcon = Icons.schedule;
      statusColor = Colors.orange;
      statusText = '待完成';
    }

    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      statusIcon,
                      color: statusColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_selectedDay!.year}年${_selectedDay!.month}月${_selectedDay!.day}日',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 13,
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        '任务数',
                        '${dayData.taskCount ?? 0}',
                        Icons.assignment,
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        '完成数',
                        '${dayData.completedCount ?? 0}',
                        Icons.check,
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        '得分',
                        dayData.score?.toStringAsFixed(1) ?? '-',
                        Icons.star,
                        Colors.amber,
                      ),
                    ),
                  ],
                ),
                if (isCompleted && dayData.itemId != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ScoreDetailScreen(
                              itemId: dayData.itemId!,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('查看详情'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
