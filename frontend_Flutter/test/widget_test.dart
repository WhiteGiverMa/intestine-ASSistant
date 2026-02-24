import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/main.dart';

void main() {
  group('App Tests', () {
    testWidgets('AppInitializer renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const AppInitializer());

      expect(find.byType(AppInitializer), findsOneWidget);
    });

    testWidgets('SplashPage displays during initialization', (WidgetTester tester) async {
      await tester.pumpWidget(const AppInitializer());

      expect(find.text('肠道健康助手'), findsOneWidget);
      expect(find.text('Intestine ASSistant'), findsOneWidget);
    });
  });
}
