import 'package:flutter/material.dart' hide Element, Container, View;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/presentation/widgets/diagram/structurizr_diagram.dart';
import 'package:flutter_structurizr/presentation/widgets/element_explorer.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/container.dart'
    as structurizr_model;

void main() {
  group('ElementExplorer and StructurizrDiagram Integration', () {
    // Create a more reliable test workspace with sample elements
    late Workspace workspace;
    late View view;
    late String personId, systemId, apiId, databaseId;

    // Helper function to create test data properly
    void setupTestData() {
      // Create a person
      final person = Person.create(
        name: 'User',
        description: 'A user of the system',
        tags: ['External'],
      );
      personId = person.id;

      // Create a software system
      final system = SoftwareSystem.create(
        name: 'Software System',
        description: 'Main system',
        tags: ['Internal'],
      );
      systemId = system.id;

      // Create containers
      final api = structurizr_model.Container.create(
        name: 'API Container',
        description: 'API for the system',
        tags: ['Container'],
        parentId: system.id,
      );
      apiId = api.id;

      final database = structurizr_model.Container.create(
        name: 'Database',
        description: 'Database for the system',
        tags: ['Container', 'Database'],
        parentId: system.id,
      );
      databaseId = database.id;

      // Create model without relationships first
      final model = Model(
        people: [person],
        softwareSystems: [
          system.copyWith(
            containers: [api, database],
          ),
        ],
      );

      // Now get the elements from the model to establish relationships
      final personFromModel = model.getElementById(personId) as Person;
      final apiFromModel =
          model.getElementById(apiId) as structurizr_model.Container;
      final databaseFromModel =
          model.getElementById(databaseId) as structurizr_model.Container;

      // Add relationships
      final personWithRel = personFromModel.addRelationship(
        destinationId: apiId,
        description: 'Uses',
      );

      final apiWithRel = apiFromModel.addRelationship(
        destinationId: databaseId,
        description: 'Reads from and writes to',
      );

      // Get the relationships IDs for use in the view
      final personToApiRelId = personWithRel.getRelationshipsTo(apiId).first.id;
      final apiToDatabaseRelId =
          apiWithRel.getRelationshipsTo(databaseId).first.id;

      // Update model with elements that have relationships
      final updatedModel = model.copyWith(
        people: [personWithRel],
        softwareSystems: [
          model.getSoftwareSystemById(systemId)!.copyWith(
            containers: [apiWithRel, databaseFromModel],
          ),
        ],
      );

      // Create workspace with the updated model
      workspace = Workspace(
        id: 42,
        name: 'Test Workspace',
        description: 'Test workspace for UI integration',
        model: updatedModel,
      );

      // Create a container view
      view = ContainerView(
        key: 'Containers',
        softwareSystemId: systemId,
        description: 'Container view of the system',
        elements: [
          ElementView(id: personId),
          ElementView(id: systemId),
          ElementView(id: apiId),
          ElementView(id: databaseId),
        ],
        relationships: [
          RelationshipView(id: personToApiRelId),
          RelationshipView(id: apiToDatabaseRelId),
        ],
      );
    }

    setUp(() {
      // Initialize test data before each test
      setupTestData();
    });

    testWidgets('integrates ElementExplorer with StructurizrDiagram',
        (WidgetTester tester) async {
      // Track selected element
      String? selectedElementId;
      String? diagramSelectedElementId;

      // Setup state management for synchronizing selection
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Row(
                  children: [
                    // ElementExplorer on the left
                    SizedBox(
                      width: 250,
                      child: ElementExplorer(
                        workspace: workspace,
                        selectedView: view,
                        selectedElementId: selectedElementId,
                        onElementSelected: (id, element) {
                          setState(() {
                            selectedElementId = id;
                            diagramSelectedElementId = id;
                          });
                        },
                        config: const ElementExplorerConfig(
                          initiallyExpanded: true,
                        ),
                      ),
                    ),
                    // StructurizrDiagram on the right
                    Expanded(
                      child: StructurizrDiagram(
                        workspace: workspace,
                        view: view,
                        selectedElementId: diagramSelectedElementId,
                        onElementSelected: (id, element) {
                          setState(() {
                            selectedElementId = id;
                            diagramSelectedElementId = id;
                          });
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Allow initial layout to complete
      await tester.pumpAndSettle();

      // Verify both components are rendered
      expect(find.byType(ElementExplorer), findsOneWidget);
      expect(find.byType(StructurizrDiagram), findsOneWidget);

      // Verify elements are shown in the explorer
      expect(find.text('User'), findsOneWidget);
      expect(find.text('Software System'), findsOneWidget);
      expect(find.text('API Container'), findsOneWidget);
      expect(find.text('Database'), findsOneWidget);

      // Test selection from explorer to diagram
      // Find the User element in the explorer and tap it
      await tester.tap(find.text('User'));
      await tester.pumpAndSettle();

      // Verify selection state was updated
      expect(selectedElementId, equals(personId));
      expect(diagramSelectedElementId, equals(personId));

      // Now clear selection by tapping elsewhere
      // Find a blank area in the diagram and tap it
      final diagramFinder = find.byType(StructurizrDiagram);
      final diagramCenter = tester.getCenter(diagramFinder);
      await tester.tapAt(diagramCenter);
      await tester.pumpAndSettle();

      // Verify selection was cleared
      expect(selectedElementId, isNull);
      expect(diagramSelectedElementId, isNull);

      // Test filtering in explorer
      // Find the search field and type "database"
      await tester.enterText(find.byType(TextField), 'database');
      await tester.pumpAndSettle();

      // Verify filtering works - only Database should be visible
      expect(find.text('Database'), findsOneWidget);
      expect(find.text('User'), findsNothing);
      expect(find.text('API Container'), findsNothing);

      // Clear filter and verify all elements are visible again
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      expect(find.text('User'), findsOneWidget);
      expect(find.text('Software System'), findsOneWidget);
      expect(find.text('API Container'), findsOneWidget);
      expect(find.text('Database'), findsOneWidget);
    });

    testWidgets('ElementExplorer shows correct element types with icons',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElementExplorer(
              workspace: workspace,
              selectedView: view,
              config: const ElementExplorerConfig(
                initiallyExpanded: true,
                showElementTypes: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for element types with their corresponding icons
      expect(find.text('Person'), findsOneWidget);
      expect(find.text('Software System'), findsOneWidget);
      expect(find.text('Container'), findsAtLeastNWidgets(2)); // Two containers

      // Verify person icon
      expect(find.byIcon(Icons.person), findsOneWidget);

      // Verify system icon
      expect(find.byIcon(Icons.computer), findsOneWidget);

      // Verify container icons
      expect(find.byIcon(Icons.apps), findsAtLeastNWidgets(2));
    });

    testWidgets('ElementExplorer enables context menu when configured',
        (WidgetTester tester) async {
      bool menuItemSelected = false;
      String? selectedItemId;
      String? selectedMenuId;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElementExplorer(
              workspace: workspace,
              selectedView: view,
              config: const ElementExplorerConfig(
                initiallyExpanded: true,
                enableContextMenu: true,
                contextMenuItems: [
                  ElementContextMenuItem(
                    id: 'view_details',
                    label: 'View Details',
                    icon: Icons.info_outline,
                  ),
                  ElementContextMenuItem(
                    id: 'edit_properties',
                    label: 'Edit Properties',
                    icon: Icons.edit,
                  ),
                ],
              ),
              onContextMenuItemSelected: (menuItemId, elementId, element) {
                menuItemSelected = true;
                selectedMenuId = menuItemId;
                selectedItemId = elementId;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Can't directly test right-click menu in widget tests
      // But we can verify the presence of GestureDetector with right-click recognition

      // Find the element we want to right-click
      final personElement = find.text('User').first;

      // Check if the GestureDetector exists
      // Find ancestor GestureDetector of the text widget
      final gestureDetector = find.ancestor(
        of: personElement,
        matching: find.byType(GestureDetector),
      );

      expect(gestureDetector, findsOneWidget);

      // We can't actually trigger the context menu in widget tests,
      // so we verify the widget is configured correctly for context menus
      final detector = tester.widget<GestureDetector>(gestureDetector);
      expect(detector.onSecondaryTap, isNotNull);
    });
  });
}
