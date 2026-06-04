// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:android_shortcuts/main.dart';

void main() {
  testWidgets('App loads and displays title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Note: This test might need Hive initialization or repository mocking
    // depending on how deep the smoke test needs to go.
    // For now, we wrap in ProviderScope as required by the new architecture.
    await tester.pumpWidget(
      const ProviderScope(
        child: TaskFlowApp(),
      ),
    );

    // Verify that the app title is displayed.
    expect(find.text('TaskFlow'), findsOneWidget);
  });
}
