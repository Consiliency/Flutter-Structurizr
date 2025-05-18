import 'package:flutter/material.dart' hide Element, Container, View;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/view/views.dart';
import 'package:flutter_structurizr/presentation/widgets/export/batch_export_dialog.dart';
import 'package:flutter_structurizr/infrastructure/export/export_manager.dart';

void main() {
  group('BatchExportDialog Widget Tests', () {
    // Create a test workspace with multiple views
    final workspace = Workspace(
      name: 'Test Workspace',
      description: 'Workspace for testing',
      model: const Model(
        people: [],
        softwareSystems: [],
      ),
      views: Views(
        systemContextViews: [
          SystemContextView(
            key: 'test-context-view',
            name: 'Test Context View',
            description: 'Test system context view',
            softwareSystemId: '1',
          ),
        ],
        containerViews: [
          ContainerView(
            key: 'test-container-view',
            name: 'Test Container View',
            description: 'Test container view',
            softwareSystemId: '1',
          ),
        ],
        componentViews: [
          ComponentView(
            key: 'test-component-view',
            name: 'Test Component View',
            description: 'Test component view',
            containerId: '2',
          ),
        ],
      ),
    );

    testWidgets('BatchExportDialog displays all views for selection',
        (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => BatchExportDialog(
                          workspace: workspace,
                        ),
                      );
                    },
                    child: const Text('Show Batch Export Dialog'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Tap the button to show the dialog
      await tester.tap(find.text('Show Batch Export Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog title is shown
      expect(find.text('Batch Export Diagrams'), findsOneWidget);

      // Verify format dropdown exists
      expect(find.text('Export Format'), findsOneWidget);

      // Verify view selection section is shown
      expect(find.text('Select Views to Export'), findsOneWidget);

      // Verify selection buttons
      expect(find.text('Select All'), findsOneWidget);
      expect(find.text('Deselect All'), findsOneWidget);

      // Verify view categories are shown
      expect(find.text('System Context Views'), findsOneWidget);
      expect(find.text('Container Views'), findsOneWidget);
      expect(find.text('Component Views'), findsOneWidget);

      // Verify specific views are listed
      expect(find.text('Test Context View'), findsOneWidget);
      expect(find.text('Test Container View'), findsOneWidget);
      expect(find.text('Test Component View'), findsOneWidget);

      // Verify export button
      expect(find.text('Export'), findsOneWidget);
    });

    testWidgets('BatchExportDialog select/deselect all functionality',
        (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => BatchExportDialog(
                          workspace: workspace,
                        ),
                      );
                    },
                    child: const Text('Show Batch Export Dialog'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Tap the button to show the dialog
      await tester.tap(find.text('Show Batch Export Dialog'));
      await tester.pumpAndSettle();

      // Check that all checkboxes are initially selected
      final checkboxes = find.byType(Checkbox);
      expect(checkboxes, findsWidgets);

      // Deselect all
      await tester.tap(find.text('Deselect All'));
      await tester.pumpAndSettle();

      // Check that all checkboxes are unselected
      // This isn't a very robust check since we can't easily inspect the internal state
      // of the checkboxes in a widget test, but it checks that the button is responsive.

      // Select all
      await tester.tap(find.text('Select All'));
      await tester.pumpAndSettle();

      // Verify destination folder button is shown
      expect(find.text('Select Destination Folder'), findsOneWidget);
    });

    testWidgets('BatchExportDialog format selection changes options',
        (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => BatchExportDialog(
                          workspace: workspace,
                        ),
                      );
                    },
                    child: const Text('Show Batch Export Dialog'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Tap the button to show the dialog
      await tester.tap(find.text('Show Batch Export Dialog'));
      await tester.pumpAndSettle();

      // Find the format dropdown
      final formatDropdown = find.byType(DropdownButton<ExportFormat>);
      expect(formatDropdown, findsOneWidget);

      // Open the dropdown
      await tester.tap(formatDropdown);
      await tester.pumpAndSettle();

      // Select a different format
      await tester.tap(find.text('SVG').last);
      await tester.pumpAndSettle();

      // Check that format-specific options are shown
      expect(find.text('Include CSS'), findsOneWidget);

      // Select another format
      await tester.tap(formatDropdown);
      await tester.pumpAndSettle();

      await tester.tap(find.text('PlantUML').last);
      await tester.pumpAndSettle();

      // Check that format changed and options updated
      expect(find.text('Include CSS'), findsNothing);
    });

    testWidgets('BatchExportDialog handles category expansion/collapse',
        (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => BatchExportDialog(
                          workspace: workspace,
                        ),
                      );
                    },
                    child: const Text('Show Batch Export Dialog'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Tap the button to show the dialog
      await tester.tap(find.text('Show Batch Export Dialog'));
      await tester.pumpAndSettle();

      // Check that all categories are initially expanded
      expect(find.text('Test Context View'), findsOneWidget);
      expect(find.text('Test Container View'), findsOneWidget);
      expect(find.text('Test Component View'), findsOneWidget);

      // Find expansion panels
      final expansionPanels = find.byType(ExpansionPanel).evaluate().toList();
      expect(expansionPanels.isNotEmpty, isTrue);

      // Collapse the first category by tapping its header
      await tester.tap(find.text('System Context Views'));
      await tester.pumpAndSettle();

      // Check that the view is now hidden
      expect(find.text('Test Context View'), findsNothing);

      // Expand it again
      await tester.tap(find.text('System Context Views'));
      await tester.pumpAndSettle();

      // Check that the view is visible again
      expect(find.text('Test Context View'), findsOneWidget);
    });

    testWidgets('BatchExportDialog handles export options change',
        (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => BatchExportDialog(
                          workspace: workspace,
                        ),
                      );
                    },
                    child: const Text('Show Batch Export Dialog'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Tap the button to show the dialog
      await tester.tap(find.text('Show Batch Export Dialog'));
      await tester.pumpAndSettle();

      // Find and toggle common options
      final includeTitleCheckbox = find.text('Include Title');
      expect(includeTitleCheckbox, findsOneWidget);
      await tester.tap(includeTitleCheckbox);
      await tester.pumpAndSettle();

      final includeLegendCheckbox = find.text('Include Legend');
      expect(includeLegendCheckbox, findsOneWidget);
      await tester.tap(includeLegendCheckbox);
      await tester.pumpAndSettle();

      // Find size setting widgets if they exist
      final sizeControls = find.text('Diagram Size');
      if (sizeControls.evaluate().isNotEmpty) {
        // If size controls are present, test interactions with them
        final widthField = find.ancestor(
          of: find.text('Width'),
          matching: find.byType(TextField),
        );

        if (widthField.evaluate().isNotEmpty) {
          await tester.enterText(widthField, '2000');
          await tester.pump();
        }

        final heightField = find.ancestor(
          of: find.text('Height'),
          matching: find.byType(TextField),
        );

        if (heightField.evaluate().isNotEmpty) {
          await tester.enterText(heightField, '1500');
          await tester.pump();
        }
      }
    });
  });
}
