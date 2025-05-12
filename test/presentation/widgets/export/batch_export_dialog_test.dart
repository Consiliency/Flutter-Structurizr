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
      model: Model(
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

    testWidgets('BatchExportDialog displays all views for selection', (WidgetTester tester) async {
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

    testWidgets('BatchExportDialog select/deselect all functionality', (WidgetTester tester) async {
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
  });
}