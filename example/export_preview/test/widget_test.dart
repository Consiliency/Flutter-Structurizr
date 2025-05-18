// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:export_preview_example/main.dart';

void main() {
  testWidgets('App shows export dialog button', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ExportPreviewExampleApp());

    // Verify that the app title and button are shown.
    expect(find.text('Export Preview Example'), findsOneWidget);
    expect(find.text('Show Export Dialog'), findsOneWidget);
  });
  
  testWidgets('Dialog shows export options', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ExportPreviewExampleApp());

    // Tap the button to show the dialog
    await tester.tap(find.text('Show Export Dialog'));
    await tester.pumpAndSettle();
    
    // Verify the dialog appears
    expect(find.text('Export Diagram'), findsOneWidget);
    expect(find.text('Export Options'), findsOneWidget);
    expect(find.text('Format:'), findsOneWidget);
  });
}
