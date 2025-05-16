import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/keyboard_shortcuts_help.dart';

void main() {
  group('KeyboardShortcutsHelp', () {
    testWidgets('renders keyboard shortcuts dialog in light mode', (WidgetTester tester) async {
      // Render the dialog
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KeyboardShortcutsHelp(isDarkMode: false),
          ),
        ),
      );

      // Verify the dialog title
      expect(find.text('Keyboard Shortcuts'), findsOneWidget);
      
      // Verify section headers
      expect(find.text('Navigation'), findsOneWidget);
      expect(find.text('View Controls'), findsOneWidget);
      
      // Verify some specific shortcuts
      expect(find.text('Previous section/decision'), findsOneWidget);
      expect(find.text('Next section/decision'), findsOneWidget);
      expect(find.text('Back in history'), findsOneWidget);
      expect(find.text('Toggle between documentation and decisions'), findsOneWidget);
      expect(find.text('Show decision graph'), findsOneWidget);
      expect(find.text('Toggle fullscreen content view'), findsOneWidget);
      expect(find.text('Show this help dialog'), findsOneWidget);
      
      // Verify close button
      expect(find.text('Close'), findsOneWidget);
      
      // Verify it has light mode colors
      final shortcutsHelp = tester.widget<KeyboardShortcutsHelp>(find.byType(KeyboardShortcutsHelp));
      expect(shortcutsHelp.isDarkMode, false);
    });

    testWidgets('renders keyboard shortcuts dialog in dark mode', (WidgetTester tester) async {
      // Render the dialog in dark mode
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KeyboardShortcutsHelp(isDarkMode: true),
          ),
        ),
      );

      // Verify the dialog title
      expect(find.text('Keyboard Shortcuts'), findsOneWidget);
      
      // Verify dialog is rendered with dark mode styling
      // We can't directly check colors in the test environment, but we can verify
      // structure and that the dark mode prop was passed correctly
      final dialogContent = tester.widget<KeyboardShortcutsHelp>(
        find.byType(KeyboardShortcutsHelp)
      );
      expect(dialogContent.isDarkMode, true);
    });

    testWidgets('closes when Close button is tapped', (WidgetTester tester) async {
      // Need to use a dialog route to test dismissal
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const KeyboardShortcutsHelp(),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );
      
      // Open the dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();
      
      // Verify dialog is showing
      expect(find.byType(KeyboardShortcutsHelp), findsOneWidget);
      
      // Tap close button
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      
      // Verify dialog is closed
      expect(find.byType(KeyboardShortcutsHelp), findsNothing);
    });
    
    testWidgets('contains all expected keyboard shortcuts', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KeyboardShortcutsHelp(),
          ),
        ),
      );
      
      // Navigation shortcuts
      expect(find.text('↑'), findsOneWidget);
      expect(find.text('↓'), findsOneWidget);
      expect(find.text('Alt + ←'), findsOneWidget);
      expect(find.text('Alt + →'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('End'), findsOneWidget);
      expect(find.text('Alt + 1-9'), findsOneWidget);
      
      // View control shortcuts
      expect(find.text('Ctrl + D'), findsOneWidget);
      expect(find.text('Ctrl + G'), findsOneWidget);
      expect(find.text('Ctrl + T'), findsOneWidget);
      expect(find.text('Ctrl + S'), findsOneWidget);
      expect(find.text('Ctrl + F'), findsOneWidget);
      expect(find.text('Ctrl + ?'), findsOneWidget);
      
      // Make sure all descriptions are present
      expect(find.text('Previous section/decision'), findsOneWidget);
      expect(find.text('Next section/decision'), findsOneWidget);
      expect(find.text('Back in history'), findsOneWidget);
      expect(find.text('Forward in history'), findsOneWidget);
      expect(find.text('Go to first section/decision'), findsOneWidget);
      expect(find.text('Go to last section/decision'), findsOneWidget);
      expect(find.text('Go to specific section/decision by index'), findsOneWidget);
      expect(find.text('Toggle between documentation and decisions'), findsOneWidget);
      expect(find.text('Show decision graph'), findsOneWidget);
      expect(find.text('Show decision timeline'), findsOneWidget);
      expect(find.text('Show search'), findsOneWidget);
      expect(find.text('Toggle fullscreen content view'), findsOneWidget);
      expect(find.text('Show this help dialog'), findsOneWidget);
    });
  });
}