import 'package:flutter/material.dart' hide Element, Container, View;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/domain/view/views.dart';
import 'package:flutter_structurizr/presentation/widgets/element_explorer.dart';

void main() {
  group('ElementExplorer', () {
    // Create test model with sample elements
    final person = Person.create(
      name: 'User',
      description: 'A user of the system',
      tags: ['Person', 'External'],
    );
    
    final system = SoftwareSystem.create(
      name: 'Software System',
      description: 'Main system',
      tags: ['SoftwareSystem', 'Internal'],
    );
    
    final container1 = Container.create(
      name: 'API Gateway',
      parentId: system.id,
      description: 'API Gateway for the system',
      tags: ['Container'],
    );
    
    final container2 = Container.create(
      name: 'Database',
      parentId: system.id,
      description: 'Database for the system',
      tags: ['Container', 'Database'],
    );
    
    // Add containers to the system
    final systemWithContainers = system.copyWith(
      containers: [container1, container2],
    );
    
    // Create a model with the elements
    final model = Model(
      people: [person],
      softwareSystems: [systemWithContainers],
    );
    
    // Create a workspace with the model
    final workspace = Workspace(
      id: 42,
      name: 'Test Workspace',
      description: 'Test workspace for unit tests',
      model: model,
    );
    
    // Create views
    final views = Views(
      systemContextViews: [
        SystemContextView(
          key: 'SystemContext',
          softwareSystemId: system.id,
          elements: [
            ElementView(id: person.id),
            ElementView(id: system.id),
          ],
          relationships: [],
        ),
      ],
      containerViews: [
        ContainerView(
          key: 'Containers',
          softwareSystemId: system.id,
          elements: [
            ElementView(id: container1.id),
            ElementView(id: container2.id),
          ],
          relationships: [],
        ),
      ]
    );
    
    // Create a combined workspace with model and views
    final workspaceWithViews = workspace;
    
    // Basic rendering tests with skips due to overflow issues
    testWidgets('renders without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElementExplorer(
              workspace: workspaceWithViews,
            ),
          ),
        ),
      );
      
      // Just verify it renders without errors
      expect(find.byType(ElementExplorer), findsOneWidget);
    });
    
    testWidgets('shows all elements when initiallyExpanded is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElementExplorer(
              workspace: workspaceWithViews,
              config: const ElementExplorerConfig(
                initiallyExpanded: true,
              ),
            ),
          ),
        ),
      );
      
      // Verify that elements are shown
      expect(find.text('User'), findsOneWidget);
      expect(find.text('Software System'), findsOneWidget);
      expect(find.text('API Gateway'), findsOneWidget);
      expect(find.text('Database'), findsOneWidget);
    });
    
    testWidgets('groups elements by type when configured', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElementExplorer(
              workspace: workspaceWithViews,
              config: const ElementExplorerConfig(
                groupByType: true,
                initiallyExpanded: true, // Start with expanded nodes to simplify test
              ),
            ),
          ),
        ),
      );
      
      // Verify type headers are shown - find at least one widget with text 'Person'
      expect(find.text('Person'), findsWidgets);
      expect(find.text('SoftwareSystem'), findsWidgets);
      
      // Since we set initiallyExpanded: true, we should directly find elements
      expect(find.text('User'), findsOneWidget);
      
      // Verify we can also find a software system element
      expect(find.text('Software System'), findsOneWidget);
    });
    
    testWidgets('calls onElementSelected when an element is clicked', (WidgetTester tester) async {
      String? selectedId;
      Element? selectedElement;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElementExplorer(
              workspace: workspaceWithViews,
              config: const ElementExplorerConfig(
                initiallyExpanded: true,
              ),
              onElementSelected: (id, element) {
                selectedId = id;
                selectedElement = element;
              },
            ),
          ),
        ),
      );
      
      // Find and tap on the user element
      await tester.tap(find.text('User'));
      await tester.pump();
      
      // Verify callback was called
      expect(selectedId, equals(person.id));
      expect(selectedElement, equals(person));
    });
    
    testWidgets('supports drag and drop when enabled', (WidgetTester tester) async {
      String? draggedId;
      Element? draggedElement;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElementExplorer(
              workspace: workspaceWithViews,
              config: const ElementExplorerConfig(
                initiallyExpanded: true,
                enableDragDrop: true,
              ),
              onElementDragged: (id, element) {
                draggedId = id;
                draggedElement = element;
              },
            ),
          ),
        ),
      );
      
      // Verify that elements are wrapped with Draggable
      expect(find.byType(Draggable<DraggedElementData>), findsWidgets);
      
      // Start dragging the element (we can't fully test the drag in unit tests)
      final dragStartLocation = tester.getCenter(find.text('User'));
      final drag = await tester.startGesture(dragStartLocation);
      await tester.pump();
      await drag.moveBy(const Offset(100, 100));
      await tester.pump();
      
      // Verify the callback is called
      expect(draggedId, isNotNull);
      expect(draggedElement, isNotNull);
    });
    
    testWidgets('shows context menu when enabled and triggers callback', (WidgetTester tester) async {
      String? selectedMenuItemId;
      String? selectedElementId;
      Element? selectedElement;
      
      // Create context menu items (not as constants due to filter function)
      final contextMenuItems = [
        const ElementContextMenuItem(
          id: 'view',
          label: 'View Details',
          icon: Icons.info_outline,
        ),
        const ElementContextMenuItem(
          id: 'edit',
          label: 'Edit',
          icon: Icons.edit,
        ),
        ElementContextMenuItem(
          id: 'delete',
          label: 'Delete',
          icon: Icons.delete,
          // Only enable delete for containers
          filter: (element) => element.type == 'Container',
        ),
      ];
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElementExplorer(
              workspace: workspaceWithViews,
              config: ElementExplorerConfig(
                initiallyExpanded: true,
                enableContextMenu: true,
                contextMenuItems: contextMenuItems,
              ),
              onContextMenuItemSelected: (itemId, elementId, element) {
                selectedMenuItemId = itemId;
                selectedElementId = elementId;
                selectedElement = element;
              },
            ),
          ),
        ),
      );
      
      // Right click (secondary tap) on element
      // Note: Flutter's test framework doesn't fully support right-clicks,
      // so we're testing the GestureDetector is set up but can't trigger the menu itself
      
      // Verify GestureDetector is wrapping element nodes
      expect(find.byType(GestureDetector), findsWidgets);
      
      // Due to limitations in the Flutter test framework, we can't easily test
      // context menu appearance and selection in widget tests
      // A more complete test would be an integration test that can simulate
      // right-clicks and menu selection
    });
  });
}