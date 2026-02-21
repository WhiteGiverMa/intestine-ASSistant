import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/main.dart';
import 'package:frontend_flutter/providers/theme_provider.dart';
import 'package:frontend_flutter/providers/auth_provider.dart';

void main() {
  group('MyApp Tests', () {
    testWidgets('MyApp renders correctly', (WidgetTester tester) async {
      final themeProvider = ThemeProvider();
      final authProvider = AuthProvider();
      await themeProvider.initialize();
      await authProvider.initialize();
      await tester.pumpWidget(MyApp(
        themeProvider: themeProvider,
        authProvider: authProvider,
      ));

      expect(find.text('肠道健康助手'), findsWidgets);

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('HomePage displays welcome section', (WidgetTester tester) async {
      final themeProvider = ThemeProvider();
      final authProvider = AuthProvider();
      await themeProvider.initialize();
      await authProvider.initialize();
      await tester.pumpWidget(MyApp(
        themeProvider: themeProvider,
        authProvider: authProvider,
      ));

      expect(find.text('记录您的肠道健康'), findsOneWidget);

      expect(find.text('简单记录，智能分析，守护您的肠道健康'), findsOneWidget);
    });

    testWidgets('HomePage displays menu items', (WidgetTester tester) async {
      final themeProvider = ThemeProvider();
      final authProvider = AuthProvider();
      await themeProvider.initialize();
      await authProvider.initialize();
      await tester.pumpWidget(MyApp(
        themeProvider: themeProvider,
        authProvider: authProvider,
      ));

      expect(find.text('记录排便'), findsOneWidget);
      expect(find.text('AI 分析'), findsOneWidget);
    });

    testWidgets('HomePage displays Bristol chart', (WidgetTester tester) async {
      final themeProvider = ThemeProvider();
      final authProvider = AuthProvider();
      await themeProvider.initialize();
      await authProvider.initialize();
      await tester.pumpWidget(MyApp(
        themeProvider: themeProvider,
        authProvider: authProvider,
      ));

      expect(find.text('布里斯托大便分类法'), findsOneWidget);
    });

    testWidgets('HomePage displays bottom navigation', (WidgetTester tester) async {
      final themeProvider = ThemeProvider();
      final authProvider = AuthProvider();
      await themeProvider.initialize();
      await authProvider.initialize();
      await tester.pumpWidget(MyApp(
        themeProvider: themeProvider,
        authProvider: authProvider,
      ));

      expect(find.text('首页'), findsOneWidget);
      expect(find.text('数据'), findsOneWidget);
      expect(find.text('分析'), findsOneWidget);
      expect(find.text('设置'), findsOneWidget);
    });

    testWidgets('Unauthenticated user sees login/register buttons', (WidgetTester tester) async {
      final themeProvider = ThemeProvider();
      final authProvider = AuthProvider();
      await themeProvider.initialize();
      await authProvider.initialize();
      await tester.pumpWidget(MyApp(
        themeProvider: themeProvider,
        authProvider: authProvider,
      ));
      await tester.pumpAndSettle();

      expect(find.text('登录'), findsOneWidget);
      expect(find.text('注册'), findsOneWidget);
    });
  });
}
