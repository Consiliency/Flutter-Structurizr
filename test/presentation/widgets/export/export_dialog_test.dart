import 'package:flutter/material.dart' hide Element, Container, View;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/view/views.dart';
import 'package:flutter_structurizr/presentation/widgets/export/export_dialog.dart';
import 'package:flutter_structurizr/infrastructure/export/export_manager.dart';

void main() {
  group('ExportDialog Widget Tests', () {
    // Create a test workspace with a single view
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
            key: 'test-view',
            name: 'Test View',
            description: 'Test system context view',
            softwareSystemId: '1',
          ),
        ],
      ),
    );

    testWidgets('ExportDialog shows all format options', (WidgetTester tester) async {
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
                        builder: (context) => ExportDialog(
                          workspace: workspace,
                          viewKey: 'test-view',
                          title: 'Test View',
                        ),
                      );
                    },
                    child: const Text('Show Export Dialog'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Tap the button to show the dialog
      await tester.tap(find.text('Show Export Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog title is shown
      expect(find.text('Export Diagram'), findsOneWidget);

      // Verify format dropdown exists
      expect(find.text('Export Format'), findsOneWidget);

      // Verify PNG is the default format
      expect(find.text('PNG Image'), findsOneWidget);

      // Verify checkbox options
      expect(find.text('Include Legend'), findsOneWidget);
      expect(find.text('Include Title'), findsOneWidget);
      expect(find.text('Include Metadata'), findsOneWidget);
      expect(find.text('Transparent Background'), findsOneWidget);
      expect(find.text('Use Memory-Efficient Rendering'), findsOneWidget);

      // Verify export button
      expect(find.text('Export'), findsOneWidget);
    });

    testWidgets('ExportDialog changes options based on format', (WidgetTester tester) async {
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
                        builder: (context) => ExportDialog(
                          workspace: workspace,
                          viewKey: 'test-view',
                          title: 'Test View',
                        ),
                      );
                    },
                    child: const Text('Show Export Dialog'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Tap the button to show the dialog
      await tester.tap(find.text('Show Export Dialog'));
      await tester.pumpAndSettle();

      // Find the dropdown
      final dropdownFinder = find.byType(DropdownButtonFormField<ExportFormat>);
      expect(dropdownFinder, findsOneWidget);

      // Tap the dropdown
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      // Select SVG format
      await tester.tap(find.text('SVG Vector Image').last);
      await tester.pumpAndSettle();

      // Verify width/height options are still visible for SVG
      expect(find.text('Width (px)'), findsOneWidget);
      expect(find.text('Height (px)'), findsOneWidget);

      // Verify transparent background option is gone
      expect(find.text('Transparent Background'), findsNothing);

      // Tap the dropdown again
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      // Select PlantUML format
      await tester.tap(find.text('PlantUML Diagram').last);
      await tester.pumpAndSettle();

      // Verify width/height options are gone for PlantUML
      expect(find.text('Width (px)'), findsNothing);
      expect(find.text('Height (px)'), findsNothing);
    });
  });
}