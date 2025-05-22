import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:export_preview_example/main.dart';

void main() {
  testWidgets('Export preview example app loads correctly',
      (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const ExportPreviewExampleApp());

    // Verify the app title is shown
    expect(find.text('Export Preview Example'), findsOneWidget);

    // Find the button to show the export dialog
    final buttonFinder = find.text('Show Export Dialog');
    expect(buttonFinder, findsOneWidget);
  });

  testWidgets('Dialog opens when button is pressed',
      (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const ExportPreviewExampleApp());

    // Find and tap the button
    await tester.tap(find.text('Show Export Dialog'));

    // Pump a few frames to allow the dialog to appear
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify a dialog is shown with the correct title
    expect(find.text('Export Diagram'), findsOneWidget);
  });

  testWidgets('Export dialog shows format options',
      (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const ExportPreviewExampleApp());

    // Open the dialog
    await tester.tap(find.text('Show Export Dialog'));
    await tester.pumpAndSettle();

    // Verify format options are shown
    expect(find.text('Format:'), findsOneWidget);
    expect(find.text('PNG Image'), findsOneWidget);
    expect(find.text('SVG Image'), findsOneWidget);
    expect(find.text('PlantUML'), findsOneWidget);
    expect(find.text('Mermaid'), findsOneWidget);
    expect(find.text('DOT/Graphviz'), findsOneWidget);
    expect(find.text('DSL'), findsOneWidget);
  });

  testWidgets('Export dialog shows preview section',
      (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const ExportPreviewExampleApp());

    // Open the dialog
    await tester.tap(find.text('Show Export Dialog'));
    await tester.pumpAndSettle(
        const Duration(seconds: 2)); // Wait for preview generation

    // Verify preview section is shown
    expect(find.text('Preview'), findsOneWidget);
  });

  testWidgets('Format selection changes preview', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const ExportPreviewExampleApp());

    // Open the dialog
    await tester.tap(find.text('Show Export Dialog'));
    await tester
        .pumpAndSettle(const Duration(seconds: 2)); // Wait for initial preview

    // Initially PNG should be selected
    final pngChip = find.widgetWithText(ChoiceChip, 'PNG Image');
    expect((tester.widget(pngChip) as ChoiceChip).selected, isTrue);

    // Select SVG format
    await tester.tap(find.text('SVG Image'));
    await tester.pumpAndSettle(
        const Duration(seconds: 2)); // Wait for preview to update

    // Now SVG should be selected
    final svgChip = find.widgetWithText(ChoiceChip, 'SVG Image');
    expect((tester.widget(svgChip) as ChoiceChip).selected, isTrue);
    expect((tester.widget(pngChip) as ChoiceChip).selected, isFalse);
  });

  testWidgets('Transparent background option works',
      (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const ExportPreviewExampleApp());

    // Open the dialog
    await tester.tap(find.text('Show Export Dialog'));
    await tester
        .pumpAndSettle(const Duration(seconds: 2)); // Wait for initial preview

    // Find the transparent background checkbox
    final transparentCheckbox =
        find.widgetWithText(CheckboxListTile, 'Transparent Background');
    expect(transparentCheckbox, findsOneWidget);

    // By default, it should be unchecked
    CheckboxListTile checkboxWidget =
        tester.widget(transparentCheckbox) as CheckboxListTile;
    expect(checkboxWidget.value, isFalse);

    // Toggle the checkbox
    await tester.tap(transparentCheckbox);
    await tester.pumpAndSettle(
        const Duration(seconds: 2)); // Wait for preview to update

    // Verify it's now checked
    checkboxWidget = tester.widget(transparentCheckbox) as CheckboxListTile;
    expect(checkboxWidget.value, isTrue);
  });

  testWidgets('Export button triggers export process',
      (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const ExportPreviewExampleApp());

    // Open the dialog
    await tester.tap(find.text('Show Export Dialog'));
    await tester
        .pumpAndSettle(const Duration(seconds: 2)); // Wait for initial preview

    // Find and tap the export button
    await tester.tap(find.widgetWithText(ElevatedButton, 'Export'));
    await tester.pump(); // Pump once to start the export process

    // Verify export progress is shown
    expect(find.text('Starting export...'), findsOneWidget);

    // Progress indicator should be visible
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    // Export button should show a progress indicator
    expect(
        find.descendant(
          of: find.byType(ElevatedButton),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget);
  });

  testWidgets('SvgPreviewWidget displays metadata correctly',
      (WidgetTester tester) async {
    // Create a test SVG string
    const testSvg = '''
<svg width="400" height="300" xmlns="http://www.w3.org/2000/svg">
  <rect x="0" y="0" width="400" height="300" fill="white" />
  <circle cx="200" cy="150" r="50" fill="blue" />
</svg>
''';

    // Build the widget
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              height: 300,
              child: SvgPreviewWidget(
                svgContent: testSvg,
                transparentBackground: false,
              ),
            ),
          ),
        ),
      ),
    );

    // Wait for widget to build
    await tester.pumpAndSettle();

    // Verify metadata is displayed
    expect(find.text('Size: 400 × 300'), findsOneWidget);
    expect(find.text('Elements: 2'), findsOneWidget); // 1 rect + 1 circle
  });

  testWidgets('CheckerboardBackground is shown when transparent is enabled',
      (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const ExportPreviewExampleApp());

    // Open the dialog
    await tester.tap(find.text('Show Export Dialog'));
    await tester
        .pumpAndSettle(const Duration(seconds: 2)); // Wait for initial preview

    // Initially, no CheckerboardBackground should be used
    expect(find.byType(CheckerboardBackground), findsNothing);

    // Enable transparent background
    await tester
        .tap(find.widgetWithText(CheckboxListTile, 'Transparent Background'));
    await tester.pumpAndSettle(
        const Duration(seconds: 2)); // Wait for preview to update

    // Now, CheckerboardBackground should be used
    expect(find.byType(CheckerboardBackground), findsWidgets);
  });

  testWidgets('Text-based formats show code preview',
      (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const ExportPreviewExampleApp());

    // Open the dialog
    await tester.tap(find.text('Show Export Dialog'));
    await tester
        .pumpAndSettle(const Duration(seconds: 2)); // Wait for initial preview

    // Select PlantUML format
    await tester.tap(find.text('PlantUML'));
    await tester.pumpAndSettle(
        const Duration(seconds: 2)); // Wait for preview to update

    // Verify text preview shows up with correct title
    expect(find.text('PLANTUML Preview'), findsOneWidget);

    // Check that it contains some PlantUML content
    expect(find.textContaining('@startuml'), findsOneWidget);
  });
}
