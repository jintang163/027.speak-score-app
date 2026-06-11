import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:speak_score_flutter/models/report_info.dart';

class ScoreDistributionPieChart extends StatelessWidget {
  final List<ScoreDistribution> distributions;

  const ScoreDistributionPieChart({
    super.key,
    required this.distributions,
  });

  @override
  Widget build(BuildContext context) {
    if (distributions.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    final colors = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.red,
    ];

    return Row(
      children: [
        Expanded(
          flex: 1,
          child: SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: distributions.asMap().entries.map((entry) {
                  final i = entry.key;
                  final d = entry.value;
                  final color = colors[i % colors.length];
                  final isZero = (d.count ?? 0) == 0;
                  return PieChartSectionData(
                    color: isZero ? Colors.grey[200]! : color,
                    value: (d.percentage ?? 0).toDouble(),
                    title: '${d.percentage?.toStringAsFixed(1) ?? 0}%',
                    radius: 60,
                    titleStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isZero ? Colors.grey : Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: distributions.asMap().entries.map((entry) {
              final i = entry.key;
              final d = entry.value;
              final color = colors[i % colors.length];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        d.level ?? '',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      '${d.count ?? 0}人',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class ScoreDistributionBarChart extends StatelessWidget {
  final List<ScoreDistribution> distributions;

  const ScoreDistributionBarChart({
    super.key,
    required this.distributions,
  });

  @override
  Widget build(BuildContext context) {
    if (distributions.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    final colors = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.red,
    ];

    final maxCount = distributions
        .map((d) => d.count ?? 0)
        .fold<int>(0, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (maxCount * 1.2).toDouble(),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final d = distributions[group.x.toInt()];
                return BarTooltipItem(
                  '${d.level}\n${d.count}人',
                  const TextStyle(color: Colors.white),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final d = distributions[value.toInt()];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      d.level ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: distributions.asMap().entries.map((entry) {
            final i = entry.key;
            final d = entry.value;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: (d.count ?? 0).toDouble(),
                  color: colors[i % colors.length],
                  width: 24,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class ProgressLineChart extends StatelessWidget {
  final List<StudentProgress> progressData;
  final Color? lineColor;

  const ProgressLineChart({
    super.key,
    required this.progressData,
    this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    if (progressData.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < progressData.length; i++) {
      final score = progressData[i].averageScore;
      if (score != null) {
        spots.add(FlSpot(i.toDouble(), score));
      }
    }

    if (spots.isEmpty) {
      return const Center(child: Text('暂无评分数据'));
    }

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final chartMinY = (minY - 10).clamp(0.0, 100.0);
    final chartMaxY = (maxY + 10).clamp(0.0, 100.0);

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[200]!,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval:
                    (progressData.length / 5).clamp(1, progressData.length).toDouble(),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= progressData.length) {
                    return const SizedBox.shrink();
                  }
                  final date = progressData[index].date ?? '';
                  final parts = date.split('-');
                  final displayDate =
                      parts.length >= 3 ? '${parts[1]}/${parts[2]}' : date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      displayDate,
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 20,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (progressData.length - 1).toDouble(),
          minY: chartMinY,
          maxY: chartMaxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: lineColor ?? Colors.blue,
              barWidth: 3,
              isStrokeCapRound: true,
              belowBarData: BarAreaData(
                show: true,
                color: (lineColor ?? Colors.blue).withOpacity(0.1),
              ),
              dotData: const FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }
}

class ClassComparisonBarChart extends StatelessWidget {
  final List<ClassComparison> classData;
  final bool showAverageScore;

  const ClassComparisonBarChart({
    super.key,
    required this.classData,
    this.showAverageScore = true,
  });

  @override
  Widget build(BuildContext context) {
    if (classData.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    final maxValue = showAverageScore
        ? classData
            .map((c) => c.averageScore ?? 0)
            .fold<double>(0, (a, b) => a > b ? a : b)
        : classData
            .map((c) => c.completionRate ?? 0)
            .fold<double>(0, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: showAverageScore ? 100 : maxValue * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final c = classData[group.x.toInt()];
                final value = showAverageScore
                    ? '${c.averageScore?.toStringAsFixed(1) ?? 0}分'
                    : '${c.completionRate?.toStringAsFixed(1) ?? 0}%';
                return BarTooltipItem(
                  '${c.className}\n$value',
                  const TextStyle(color: Colors.white, fontSize: 11),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= classData.length) {
                    return const SizedBox.shrink();
                  }
                  final name = classData[index].className ?? '';
                  final displayName =
                      name.length > 4 ? '${name.substring(0, 4)}...' : name;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      displayName,
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: showAverageScore ? 20 : null,
                getTitlesWidget: (value, meta) {
                  return Text(
                    showAverageScore
                        ? '${value.toInt()}分'
                        : '${value.toInt()}%',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: classData.asMap().entries.map((entry) {
            final i = entry.key;
            final c = entry.value;
            final value =
                showAverageScore ? (c.averageScore ?? 0) : (c.completionRate ?? 0);
            final color =
                showAverageScore ? _getScoreColor(value) : _getRateColor(value);
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: value,
                  color: color,
                  width: 20,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 70) return Colors.blue;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  Color _getRateColor(double rate) {
    if (rate >= 80) return Colors.green;
    if (rate >= 50) return Colors.blue;
    if (rate >= 30) return Colors.orange;
    return Colors.red;
  }
}
