import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supa/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Startup Integration Test', () {
    testWidgets('Verify app starts and shows initial screen', (
      WidgetTester tester,
    ) async {
      // 1. Start the app
      app.main();

      // 2. Wait for the app to settle (Splash screen duration + transitions)
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 3. Verify that we are on a screen (at least one scaffold exists)
      expect(find.byType(Scaffold), findsOneWidget);

      // 4. Look for common login screen elements to verify routing
      // Note: This might fail if the user is already logged in (persistence)
      // but in CI it's usually a fresh environment.
      // expect(find.text('Login'), findsWidgets);
    });
  });
}
