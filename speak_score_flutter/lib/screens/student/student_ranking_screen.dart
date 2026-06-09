import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speak_score_flutter/services/auth_service.dart';

class StudentRankingScreen extends StatefulWidget {
  const StudentRankingScreen({super.key});

  @override
  State<StudentRankingScreen> createState() => _StudentRankingScreenState();
}

class _StudentRankingScreenState extends State<StudentRankingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _classRankings = [];
  List<Map<String, dynamic>> _schoolRankings = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRankings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRankings() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _classRankings = [];
        _schoolRankings = [];
        _isLoading = false;
      });
    }
  }

  Widget _buildRankList(List<Map<String, dynamic>> rankings, int? currentUserId) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
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
        padding: const EdgeInsets.all(16),
        itemCount: rankings.length,
        itemBuilder: (context, index) {
          final item = rankings[index];
          final rank = item['rank'] ?? (index + 1);
          final isCurrentUser = item['userId'] == currentUserId;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: isCurrentUser ? Colors.blue.withValues(alpha: 0.05) : null,
            child: ListTile(
              leading: _buildRankBadge(rank),
              title: Text(
                item['name'] ?? '',
                style: TextStyle(
                  fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                  color: isCurrentUser ? Colors.blue : null,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item['score']?.toString() ?? '--',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isCurrentUser ? Colors.blue : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('分', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  if (item['trend'] != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      item['trend'] == 'up'
                          ? Icons.trending_up
                          : item['trend'] == 'down'
                              ? Icons.trending_down
                              : Icons.trending_flat,
                      size: 18,
                      color: item['trend'] == 'up'
                          ? Colors.green
                          : item['trend'] == 'down'
                              ? Colors.red
                              : Colors.grey,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color bgColor;
    Color textColor;
    if (rank == 1) {
      bgColor = Colors.amber;
      textColor = Colors.white;
    } else if (rank == 2) {
      bgColor = Colors.grey[400]!;
      textColor = Colors.white;
    } else if (rank == 3) {
      bgColor = Colors.brown[300]!;
      textColor = Colors.white;
    } else {
      bgColor = Colors.grey[200]!;
      textColor = Colors.grey[600]!;
    }

    return CircleAvatar(
      backgroundColor: bgColor,
      radius: 18,
      child: Text(
        '$rank',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: rank <= 3 ? 14 : 13,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthService>().userInfo?.id;

    return Column(
      children: [
        Container(
          color: Colors.blue,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: '班级排行'),
              Tab(text: '校级排行'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRankList(_classRankings, currentUserId),
              _buildRankList(_schoolRankings, currentUserId),
            ],
          ),
        ),
      ],
    );
  }
}
