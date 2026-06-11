
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speak_score_flutter/models/ranking.dart';
import 'package:speak_score_flutter/services/auth_service.dart';
import 'package:speak_score_flutter/services/ranking_service.dart';

class TeacherRankingScreen extends StatefulWidget {
  const TeacherRankingScreen({super.key});

  @override
  State<TeacherRankingScreen> createState() => _TeacherRankingScreenState();
}

class _TeacherRankingScreenState extends State<TeacherRankingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RankingService _rankingService = RankingService();

  String _selectedPeriod = 'total';
  int? _selectedClassId;
  String? _selectedClassName;

  RankingData? _classRanking;
  List<ClassRankItem> _classAverageRankings = [];
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _periods = const ['total', 'weekly', 'daily'];
  final Map<String, String> _periodLabels = const {
    'total': '总榜',
    'weekly': '周榜',
    'daily': '日榜',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initDefaultClass();
  }

  void _initDefaultClass() {
    final authService = context.read<AuthService>();
    final classId = authService.userInfo?.classId;
    final className = authService.userInfo?.className;
    if (classId != null) {
      _selectedClassId = classId;
      _selectedClassName = className;
    }
    _loadRankings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRankings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = context.read<AuthService>();
      final schoolId = authService.userInfo?.schoolId;

      if (_selectedClassId != null) {
        final classRanking = await _rankingService.getClassRanking(
          classId: _selectedClassId!,
          period: _selectedPeriod,
        );
        if (mounted) {
          setState(() {
            _classRanking = classRanking;
          });
        }
      }

      if (schoolId != null) {
        final classRankings = await _rankingService.getClassAverageRanking(
          schoolId: schoolId,
          period: _selectedPeriod,
        );
        if (mounted) {
          setState(() {
            _classAverageRankings = classRankings;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _changePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    _loadRankings();
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          if (_selectedClassName != null) ...[
            Expanded(
              child: Text(
                '班级：$_selectedClassName',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ),
          ] else
            const Spacer(),
          ..._periods.map((period) {
            final isSelected = _selectedPeriod == period;
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: InkWell(
                onTap: () => _changePeriod(period),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _periodLabels[period] ?? period,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildStudentRankList() {
    final rankings = _classRanking?.rankings ?? [];

    if (_isLoading && rankings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && rankings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRankings,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (rankings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              '暂无排行数据',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRankings,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: rankings.length,
        itemBuilder: (context, index) {
          final item = rankings[index];
          return _buildStudentRankItem(item);
        },
      ),
    );
  }

  Widget _buildStudentRankItem(RankItem item) {
    return InkWell(
      onTap: () => _showStudentDetail(item),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Row(
          children: [
            _buildRankBadge(item.rank),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 20,
              backgroundImage: item.avatar != null && item.avatar!.isNotEmpty
                  ? NetworkImage(item.avatar!)
                  : null,
              child: item.avatar == null || item.avatar!.isEmpty
                  ? Text(
                      item.userName.isNotEmpty ? item.userName[0] : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    )
                  : null,
              backgroundColor: Colors.grey[400],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '完成 ${item.taskCount} 次 · 平均 ${item.averageScore.toStringAsFixed(1)} 分',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.score.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '分',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassRankList() {
    if (_isLoading && _classAverageRankings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _classAverageRankings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRankings,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_classAverageRankings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              '暂无班级排行数据',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRankings,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: _classAverageRankings.length,
        itemBuilder: (context, index) {
          final item = _classAverageRankings[index];
          final isMyClass = item.classId == _selectedClassId;
          return _buildClassRankItem(item, isMyClass);
        },
      ),
    );
  }

  Widget _buildClassRankItem(ClassRankItem item, bool isMyClass) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMyClass ? Colors.blue.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: isMyClass
            ? Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 1)
            : Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        children: [
          _buildRankBadge(item.rank),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.className,
                  style: TextStyle(
                    fontWeight: isMyClass ? FontWeight.bold : FontWeight.w500,
                    color: isMyClass ? Colors.blue : Colors.black87,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.gradeName ?? ''} · ${item.studentCount} 名学生',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.averageScore.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isMyClass ? Colors.blue : Colors.black87,
                ),
              ),
              Text(
                '平均分',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color bgColor;
    Color textColor;
    IconData? icon;

    if (rank == 1) {
      bgColor = Colors.amber;
      textColor = Colors.white;
      icon = Icons.emoji_events;
    } else if (rank == 2) {
      bgColor = Colors.grey[400]!;
      textColor = Colors.white;
    } else if (rank == 3) {
      bgColor = Colors.brown[300]!;
      textColor = Colors.white;
    } else {
      bgColor = Colors.grey[100]!;
      textColor = Colors.grey[600]!;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: icon != null
          ? Icon(icon, color: textColor, size: 18)
          : Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: rank <= 3 ? 14 : 13,
                ),
              ),
            ),
    );
  }

  void _showStudentDetail(RankItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _StudentDetailSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('排行榜'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: '学生排行'),
            Tab(text: '班级排行'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildPeriodSelector(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStudentRankList(),
                _buildClassRankList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentDetailSheet extends StatelessWidget {
  final RankItem item;

  const _StudentDetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: item.avatar != null && item.avatar!.isNotEmpty
                        ? NetworkImage(item.avatar!)
                        : null,
                    child: item.avatar == null || item.avatar!.isEmpty
                        ? Text(
                            item.userName.isNotEmpty ? item.userName[0] : '?',
                            style: const TextStyle(color: Colors.white, fontSize: 28),
                          )
                        : null,
                    backgroundColor: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item.userName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events, color: Colors.amber[600], size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '第 ${item.rank} 名',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.amber[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('总分', item.score.toStringAsFixed(1), Colors.blue),
                  _buildStatItem('平均分', item.averageScore.toStringAsFixed(1), Colors.green),
                  _buildStatItem('完成次数', '${item.taskCount}', Colors.orange),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '最近三次得分',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (item.recentScores == null || item.recentScores!.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '暂无得分记录',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ),
                    )
                  else
                    Row(
                      children: item.recentScores!.asMap().entries.map((entry) {
                        final index = entry.key;
                        final score = entry.value;
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.only(
                              right: index < item.recentScores!.length - 1 ? 8 : 0,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: _getScoreColor(score).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  score.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: _getScoreColor(score),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '第${item.recentScores!.length - index}次',
                                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}
