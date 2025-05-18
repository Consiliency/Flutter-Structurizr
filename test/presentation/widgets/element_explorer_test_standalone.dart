import 'package:flutter/material.dart' hide Container, View;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/model/model.dart'
    as structurizr_model;
import 'package:flutter_structurizr/domain/model/workspace.dart'
    as structurizr_model;
import 'package:flutter_structurizr/presentation/widgets/element_explorer.dart';
import 'package:logging/logging.dart';
import 'package:flutter_structurizr/domain/model/container.dart'
    as structurizr_model;
import 'package:flutter_structurizr/domain/model/element.dart'
    as structurizr_model;

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print(
        '[\u001b[32m\u001b[1m\u001b[40m\u001b[0m${record.level.name}] ${record.loggerName}: ${record.message}');
  });

  group('ElementExplorer', () {
    // Create test model with sample elements
    final person = structurizr_model.Person.create(
      name: 'User',
      description: 'A user of the system',
      tags: ['Person', 'External'],
    );

    final system = structurizr_model.SoftwareSystem.create(
      name: 'Software System',
      description: 'Main system',
      tags: ['SoftwareSystem', 'Internal'],
    );

    // Create the containers
    final api = structurizr_model.Container.create(
      name: 'API Container',
      parentId: system.id,
      description: 'API for the system',
      tags: ['Container'],
    );

    final database = structurizr_model.Container.create(
      name: 'Database',
      parentId: system.id,
      description: 'Database for the system',
      tags: ['Container', 'Database'],
    );

    // Add containers to the system
    final systemWithContainers = system.copyWith(
      containers: [api, database],
    );

    // Create a model with the elements
    final model = structurizr_model.Model(
      people: [person],
      softwareSystems: [systemWithContainers],
    );

    // Create a workspace with the model
    final workspace = structurizr_model.Workspace(
      id: 42,
      name: 'Test Workspace',
      description: 'Test workspace for unit tests',
      model: model,
    );

    testWidgets('renders without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElementExplorer(
              workspace: workspace,
            ),
          ),
        ),
      );

      // Just verify it renders without errors
      expect(find.byType(ElementExplorer), findsOneWidget);
    });

    testWidgets('shows all elements when initiallyExpanded is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElementExplorer(
              workspace: workspace,
              config: const ElementExplorerConfig(
                initiallyExpanded: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify all elements are displayed with initiallyExpanded = true
      expect(find.text('User'), findsOneWidget);
      expect(find.text('Software System'), findsOneWidget);
      expect(find.text('API Container'), findsOneWidget);
      expect(find.text('Database'), findsOneWidget);
    });

    testWidgets('filters elements based on search text',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElementExplorer(
              workspace: workspace,
              config: const ElementExplorerConfig(
                initiallyExpanded: true,
                showSearchBox: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test search functionality
      await tester.enterText(find.byType(TextField), 'database');
      await tester.pumpAndSettle();

      // Only Database should be visible now
      expect(find.text('Database'), findsOneWidget);
      expect(find.text('User'), findsNothing);
      expect(find.text('API Container'), findsNothing);

      // Clear search
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      // All elements should be visible again since we have initiallyExpanded=true
      expect(find.text('User'), findsOneWidget);
      expect(find.text('Software System'), findsOneWidget);
      expect(find.text('API Container'), findsOneWidget);
      expect(find.text('Database'), findsOneWidget);
    });

    testWidgets('calls onElementSelected when an element is clicked',
        (WidgetTester tester) async {
      String? selectedElementId;
      structurizr_model.Element? selectedElement;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElementExplorer(
              workspace: workspace,
              config: const ElementExplorerConfig(
                initiallyExpanded: true,
              ),
              onElementSelected: (id, element) {
                selectedElementId = id;
                selectedElement = element;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Click on Database element
      await tester.tap(find.text('Database'));
      await tester.pumpAndSettle();

      // Verify callback was called with the correct element
      expect(selectedElementId, equals(database.id));
      expect(selectedElement?.name, equals('Database'));
    });
  });
}
