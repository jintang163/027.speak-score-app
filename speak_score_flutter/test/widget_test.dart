import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:speak_score_flutter/main.dart';
import 'package:speak_score_flutter/services/auth_service.dart';
import 'package:speak_score_flutter/screens/login_screen.dart';

void main() {
  group('SpeakScoreApp', () {
    testWidgets('renders MaterialApp with SpeakScoreApp widget', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthService()),
          ],
          child: const SpeakScoreApp(),
        ),
      );

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(AuthWrapper), findsOneWidget);
    });

    testWidgets('AuthWrapper shows LoginScreen when not authenticated', (tester) async {
      final authService = AuthService();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authService),
          ],
          child: const SpeakScoreApp(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('AuthWrapper shows loading indicator while loading', (tester) async {
      final authService = AuthService();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authService),
          ],
          child: const AuthWrapper(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
