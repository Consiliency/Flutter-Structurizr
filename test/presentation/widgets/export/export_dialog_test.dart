import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart' hide Element, Container, View;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/view/model_view.dart';
import 'package:flutter_structurizr/infrastructure/export/export_manager.dart';
import 'package:flutter_structurizr/infrastructure/export/diagram_exporter.dart';
import 'package:flutter_structurizr/presentation/widgets/export/export_dialog.dart';

import 'mock_exporters.dart';

// Create a testable version of the export dialog
class TestableExportDialog extends StatelessWidget {
  final Workspace workspace;
  final String viewKey;
  final ModelView? currentView;
  final void Function(Uint8List, String)? onExportComplete;
  final String? title;
  final ExportManager exportManager;

  const TestableExportDialog({
    Key? key,
    required this.workspace,
    required this.viewKey,
    this.currentView,
    this.onExportComplete,
    this.title,
    required this.exportManager,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExportDialog(
      workspace: workspace,
      viewKey: viewKey,
      currentView: currentView,
      onExportComplete: onExportComplete,
      title: title,
    );
  }
}

void main() {
  late Workspace testWorkspace;
  late WorkspaceViews testViews;
  late ModelView testView;

  setUp(() {
    // Create test view
    testView = ModelView(
      key: 'test-view',
      title: 'Test View',
    );

    // Create test views
    testViews = WorkspaceViews(
      systemContextViews: [testView],
    );

    // Create a test workspace with basic components
    testWorkspace = Workspace(
      name: 'Test Workspace',
      description: 'Test workspace for export dialog testing',
      views: testViews,
    );
  });

  testWidgets('ExportDialog shows and has basic structure',
      (WidgetTester tester) async {
    // Build our widget
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => ExportDialog.show(
                context: context,
                workspace: testWorkspace,
                viewKey: 'test-view',
                currentView: testView,
              ),
              child: const Text('Show Export Dialog'),
            ),
          ),
        ),
      ),
    ));

    // Tap the button to show the dialog
    await tester.tap(find.text('Show Export Dialog'));
    await tester.pumpAndSettle();

    // Verify the dialog shows
    expect(find.text('Export Diagram'), findsOneWidget);

    // Verify basic structure
    expect(find.text('Export Options'), findsOneWidget);
    expect(find.text('Preview'), findsOneWidget);
    expect(find.text('Format:'), findsOneWidget);

    // Check format chips are present
    expect(find.text('PNG Image'), findsOneWidget);
    expect(find.text('SVG Image'), findsOneWidget);
    expect(find.text('PlantUML'), findsOneWidget);
    expect(find.text('Mermaid'), findsOneWidget);
    expect(find.text('DOT/Graphviz'), findsOneWidget);
    expect(find.text('DSL'), findsOneWidget);

    // Verify buttons at the bottom
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Export'), findsOneWidget);
  });

  testWidgets('ExportDialog updates preview on format change',
      (WidgetTester tester) async {
    // Create a mock export manager
    final mockExportManager = MockExportManager();

    // Build our widget with the mock export manager
    await tester.pumpWidget(MaterialApp(
      home: TestableExportDialog(
        workspace: testWorkspace,
        viewKey: 'test-view',
        currentView: testView,
        exportManager: mockExportManager,
      ),
    ));

    // Wait for initial preview to load
    await tester.pump();
    await tester.pumpAndSettle(
        const Duration(milliseconds: 600)); // Account for debounce

    // Verify we're showing the PNG preview initially
    expect(find.text('Preview not available for this format'), findsNothing);

    // Tap the SVG format option
    await tester.tap(find.text('SVG Image'));
    await tester.pump();

    // Wait for preview to update (account for debouncing)
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    // Verify that the SVG format preview is shown
    expect(find.text('SVG Preview'), findsOneWidget);

    // Tap a format that doesn't support preview
    await tester.tap(find.text('PlantUML'));
    await tester.pump();
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    // Verify that we show the "not available" message
    expect(find.text('Preview not available for this format'), findsOneWidget);
  });

  testWidgets('ExportDialog updates preview when options change',
      (WidgetTester tester) async {
    // Create a mock export manager
    final mockExportManager = MockExportManager();

    // Build our widget with the mock export manager
    await tester.pumpWidget(MaterialApp(
      home: TestableExportDialog(
        workspace: testWorkspace,
        viewKey: 'test-view',
        currentView: testView,
        exportManager: mockExportManager,
      ),
    ));

    // Wait for initial preview to load
    await tester.pump();
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    // Find sliders
    final widthSlider = find.byType(Slider).first;
    final heightSlider = find.byType(Slider).at(1);
    final scaleSlider = find.byType(Slider).at(2);

    // Adjust width slider
    await tester.drag(widthSlider, const Offset(20.0, 0.0));
    await tester.pump();
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    // Adjust height slider
    await tester.drag(heightSlider, const Offset(20.0, 0.0));
    await tester.pump();
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    // Adjust scale slider
    await tester.drag(scaleSlider, const Offset(20.0, 0.0));
    await tester.pump();
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    // Find and toggle checkboxes
    final includeTitleCheckbox = find.text('Include Title').first;
    await tester.tap(includeTitleCheckbox);
    await tester.pump();
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    final includeLegendCheckbox = find.text('Include Legend').first;
    await tester.tap(includeLegendCheckbox);
    await tester.pump();
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    // Toggle transparent background
    final transparentCheckbox = find.text('Transparent Background').first;
    await tester.tap(transparentCheckbox);
    await tester.pump();
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    // Each option change should have triggered a preview update
    // We can't directly check the preview content, but we can verify
    // that there was no error in generation
    expect(find.text('Failed to generate preview'), findsNothing);
  });

  testWidgets('ExportDialog handles memory efficient rendering toggle',
      (WidgetTester tester) async {
    // Create a mock export manager
    final mockExportManager = MockExportManager();

    // Build our widget with the mock export manager
    await tester.pumpWidget(MaterialApp(
      home: TestableExportDialog(
        workspace: testWorkspace,
        viewKey: 'test-view',
        currentView: testView,
        exportManager: mockExportManager,
      ),
    ));

    // Wait for initial load
    await tester.pump();
    await tester.pumpAndSettle();

    // Find and toggle the memory-efficient rendering checkbox
    final memoryEfficientCheckbox = find.text('Memory-Efficient Rendering');
    expect(memoryEfficientCheckbox, findsOneWidget);

    // Get the current state (should default to true)
    final checkboxListTile = tester.widget<CheckboxListTile>(find
        .byType(CheckboxListTile)
        .where((widget) =>
            (widget as CheckboxListTile).title is Text &&
            ((widget).title as Text).data == 'Memory-Efficient Rendering'));
    expect(checkboxListTile.value, isTrue);

    // Toggle it off
    await tester.tap(memoryEfficientCheckbox);
    await tester.pump();

    // Check that the state changed (should now be false)
    final updatedCheckboxListTile = tester.widget<CheckboxListTile>(find
        .byType(CheckboxListTile)
        .where((widget) =>
            (widget as CheckboxListTile).title is Text &&
            ((widget).title as Text).data == 'Memory-Efficient Rendering'));
    expect(updatedCheckboxListTile.value, isFalse);
  });

  testWidgets('ExportDialog shows progress during preview generation',
      (WidgetTester tester) async {
    // Create a mock export manager with delay
    final mockExportManager = MockExportManager(
      delayMilliseconds: 500, // Longer delay to ensure we see progress
    );

    // Build our widget with the mock export manager
    await tester.pumpWidget(MaterialApp(
      home: TestableExportDialog(
        workspace: testWorkspace,
        viewKey: 'test-view',
        currentView: testView,
        exportManager: mockExportManager,
      ),
    ));

    // Verify progress indicators are shown during generation
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Generating preview...'), findsOneWidget);

    // Wait for completion
    await tester.pumpAndSettle(const Duration(milliseconds: 600));
  });

  testWidgets('ExportDialog handles preview generation errors',
      (WidgetTester tester) async {
    // Create a mock export manager that errors
    final mockExportManager = MockExportManager(
      simulateError: true,
    );

    // Build our widget with the mock export manager
    await tester.pumpWidget(MaterialApp(
      home: TestableExportDialog(
        workspace: testWorkspace,
        viewKey: 'test-view',
        currentView: testView,
        exportManager: mockExportManager,
      ),
    ));

    // Wait for initial load and error to be shown
    await tester.pump();
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    // Verify error message is shown
    expect(find.textContaining('Failed to generate preview'), findsOneWidget);
  });

  testWidgets('ExportDialog shows and hides format-specific options',
      (WidgetTester tester) async {
    // Build our widget
    await tester.pumpWidget(MaterialApp(
      home: TestableExportDialog(
        workspace: testWorkspace,
        viewKey: 'test-view',
        currentView: testView,
        exportManager: MockExportManager(),
      ),
    ));

    // Wait for widget to load
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify PNG/SVG specific options are visible initially (PNG is default)
    expect(find.text('Width:'), findsOneWidget);
    expect(find.text('Height:'), findsOneWidget);
    expect(find.text('Scale:'), findsOneWidget);
    expect(find.text('Transparent Background'), findsOneWidget);

    // Switch to a text-based format
    await tester.tap(find.text('PlantUML'));
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify PNG/SVG specific options are now hidden
    expect(find.text('Width:'), findsNothing);
    expect(find.text('Height:'), findsNothing);
    expect(find.text('Scale:'), findsNothing);
    expect(find.text('Transparent Background'), findsNothing);

    // Common options should still be visible
    expect(find.text('Include Title'), findsOneWidget);
    expect(find.text('Include Legend'), findsOneWidget);
    expect(find.text('Include Metadata'), findsOneWidget);
  });

  testWidgets('ExportDialog toggle preview visibility',
      (WidgetTester tester) async {
    // Build our widget
    await tester.pumpWidget(MaterialApp(
      home: TestableExportDialog(
        workspace: testWorkspace,
        viewKey: 'test-view',
        currentView: testView,
        exportManager: MockExportManager(),
      ),
    ));

    // Wait for widget to load
    await tester.pump();
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    // Verify preview is shown initially
    expect(find.text('Preview'), findsOneWidget);
    expect(find.text('Show Preview'), findsOneWidget);

    // Find and toggle the show preview checkbox
    final showPreviewCheckbox = find.text('Show Preview');
    await tester.tap(showPreviewCheckbox);
    await tester.pump();
    await tester.pumpAndSettle();

    // Preview should still be visible as a widget, but content should be hidden
    expect(find.text('Preview'), findsOneWidget);

    // Toggle it back on
    await tester.tap(showPreviewCheckbox);
    await tester.pump();
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    // Verify preview content is shown again
    expect(find.text('Preview'), findsOneWidget);
    expect(find.text('Show Preview'), findsOneWidget);
  });
}
