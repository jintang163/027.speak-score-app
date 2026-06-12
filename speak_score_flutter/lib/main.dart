import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/push_service.dart';
import 'services/offline_sync_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/student/student_calendar_screen.dart';
import 'screens/teacher/student_progress_screen.dart';
import 'screens/parent/parent_bind_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: const SpeakScoreApp(),
    ),
  );
}

class SpeakScoreApp extends StatefulWidget {
  const SpeakScoreApp({super.key});

  @override
  State<SpeakScoreApp> createState() => _SpeakScoreAppState();
}

class _SpeakScoreAppState extends State<SpeakScoreApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthService>().loadFromStorage().then((_) {
        if (context.read<AuthService>().isAuthenticated) {
          PushService().init();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '口语评分',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          primary: Colors.blue,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      home: const AuthWrapper(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/parent/bind':
            return MaterialPageRoute(builder: (_) => const ParentBindScreen());
          case '/parent/child/calendar':
            final studentId = settings.arguments as int?;
            return MaterialPageRoute(
              builder: (_) => StudentCalendarScreen(studentId: studentId),
            );
          case '/parent/child/progress':
            final studentId = settings.arguments as int?;
            return MaterialPageRoute(
              builder: (_) => StudentProgressScreen(studentId: studentId),
            );
          default:
            return null;
        }
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _pushInited = false;
  bool _offlineSyncInited = false;

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    if (authService.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (authService.isAuthenticated && !_pushInited) {
      _pushInited = true;
      PushService().init();
    }

    if (authService.isAuthenticated && !_offlineSyncInited) {
      _offlineSyncInited = true;
      OfflineSyncService().init();
    }

    if (!authService.isAuthenticated) {
      _pushInited = false;
      _offlineSyncInited = false;
    }

    if (authService.isAuthenticated) {
      return const HomeScreen();
    }

    return const LoginScreen();
  }
}
