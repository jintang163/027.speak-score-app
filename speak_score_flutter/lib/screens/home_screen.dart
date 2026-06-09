import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speak_score_flutter/services/auth_service.dart';
import 'package:speak_score_flutter/services/home_service.dart';
import 'package:speak_score_flutter/models/user_info.dart';
import 'package:speak_score_flutter/screens/student/student_task_screen.dart';
import 'package:speak_score_flutter/screens/student/student_record_screen.dart';
import 'package:speak_score_flutter/screens/student/student_ranking_screen.dart';
import 'package:speak_score_flutter/screens/student/student_profile_screen.dart';
import 'package:speak_score_flutter/screens/teacher/teacher_task_screen.dart';
import 'package:speak_score_flutter/screens/teacher/teacher_students_screen.dart';
import 'package:speak_score_flutter/screens/teacher/teacher_ranking_screen.dart';
import 'package:speak_score_flutter/screens/teacher/teacher_profile_screen.dart';
import 'package:speak_score_flutter/screens/edu_office/edu_office_school_screen.dart';
import 'package:speak_score_flutter/screens/edu_office/edu_office_ranking_screen.dart';
import 'package:speak_score_flutter/screens/edu_office/edu_office_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  HomeMenu? _homeMenu;
  bool _isLoadingMenu = true;

  String get _primaryRole {
    final roles = context.read<AuthService>().userInfo?.roles;
    if (roles == null || roles.isEmpty) return 'STUDENT';
    if (roles.contains('EDU_OFFICE')) return 'EDU_OFFICE';
    if (roles.contains('TEACHER')) return 'TEACHER';
    return 'STUDENT';
  }

  String get _roleLabel {
    switch (_primaryRole) {
      case 'TEACHER':
        return '老师';
      case 'EDU_OFFICE':
        return '教办';
      default:
        return '学生';
    }
  }

  Color get _roleBadgeColor {
    switch (_primaryRole) {
      case 'TEACHER':
        return Colors.orange;
      case 'EDU_OFFICE':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  List<BottomNavigationBarItem> get _navItems {
    switch (_primaryRole) {
      case 'TEACHER':
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: '任务',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: '学生',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: '排行',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '我的',
          ),
        ];
      case 'EDU_OFFICE':
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: '学校',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: '排行',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '我的',
          ),
        ];
      default:
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: '任务',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mic),
            label: '录音',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: '排行',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '我的',
          ),
        ];
    }
  }

  List<Widget> get _tabScreens {
    switch (_primaryRole) {
      case 'TEACHER':
        return const [
          TeacherTaskScreen(),
          TeacherStudentsScreen(),
          TeacherRankingScreen(),
          TeacherProfileScreen(),
        ];
      case 'EDU_OFFICE':
        return const [
          EduOfficeSchoolScreen(),
          EduOfficeRankingScreen(),
          EduOfficeProfileScreen(),
        ];
      default:
        return const [
          StudentTaskScreen(),
          StudentRecordScreen(),
          StudentRankingScreen(),
          StudentProfileScreen(),
        ];
    }
  }

  String? get _fabLabel {
    switch (_primaryRole) {
      case 'TEACHER':
        return '发布任务';
      case 'EDU_OFFICE':
        return '发送通知';
      default:
        return '开始打卡';
    }
  }

  IconData get _fabIcon {
    switch (_primaryRole) {
      case 'TEACHER':
        return Icons.add_circle;
      case 'EDU_OFFICE':
        return Icons.notifications_active;
      default:
        return Icons.fiber_manual_record;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMenus();
  }

  Future<void> _loadMenus() async {
    try {
      final homeService = HomeService();
      final menu = await homeService.getHomeMenus();
      if (mounted) {
        setState(() {
          _homeMenu = menu;
          _isLoadingMenu = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingMenu = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthService>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userInfo = context.watch<AuthService>().userInfo;
    final screens = _tabScreens;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Text(
                userInfo?.schoolName ?? '口语评分',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _roleBadgeColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _roleLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      drawer: _buildDrawer(userInfo),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${_fabLabel!}功能开发中')),
                );
              },
              icon: Icon(_fabIcon),
              label: Text(_fabLabel!),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: _navItems,
      ),
    );
  }

  Widget _buildDrawer(UserInfo? userInfo) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Colors.blue),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                (userInfo?.nickname ?? userInfo?.realName ?? '?')[0],
                style: const TextStyle(fontSize: 32, color: Colors.blue),
              ),
            ),
            accountName: Text(userInfo?.nickname ?? userInfo?.realName ?? '用户'),
            accountEmail: Text(userInfo?.schoolName ?? ''),
          ),
          ListTile(
            leading: const Icon(Icons.school),
            title: Text(userInfo?.schoolName ?? '未绑定学校'),
            enabled: false,
          ),
          if (userInfo?.className != null)
            ListTile(
              leading: const Icon(Icons.class_),
              title: Text(userInfo!.className!),
              enabled: false,
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('设置'),
            onTap: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('设置功能开发中')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('关于'),
            onTap: () {
              Navigator.of(context).pop();
              showAboutDialog(
                context: context,
                applicationName: '口语评分',
                applicationVersion: '1.0.0',
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('退出登录', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.of(context).pop();
              _handleLogout();
            },
          ),
        ],
      ),
    );
  }
}
