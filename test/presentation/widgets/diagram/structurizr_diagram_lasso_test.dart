import 'package:flutter/material.dart' hide Element, Container, View;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/presentation/widgets/diagram/structurizr_diagram.dart';

void main() {
  late Workspace testWorkspace;
  late ElementView testElementView1;
  late ElementView testElementView2;

  setUp(() {
    // Create a simple workspace with two elements
    final model = Model();

    // Add a person
    final person = Person(
      id: 'person1',
      name: 'Test Person',
      description: 'A test person',
    );
    model.addPerson(person);

    // Add a software system
    final system = SoftwareSystem(
      id: 'system1',
      name: 'Test System',
      description: 'A test system',
    );
    model.addSoftwareSystem(system);

    // Create relationship
    const relationship = Relationship(
      id: 'rel1',
      sourceId: 'person1',
      destinationId: 'system1',
      description: 'Uses',
    );
    model.addRelationship(relationship);

    // Create a workspace
    testWorkspace = Workspace(
      name: 'Test Workspace',
      description: 'Test workspace for diagram tests',
      model: model,
    );

    // Create a system context view
    testElementView1 = const ElementView(
      id: 'person1',
      x: 100,
      y: 100,
      width: 200,
      height: 100,
    );

    testElementView2 = const ElementView(
      id: 'system1',
      x: 400,
      y: 100,
      width: 200,
      height: 100,
    );
  });

  testWidgets('Lasso selection should select elements',
      (WidgetTester tester) async {
    // Create a simple view with two elements
    final view = SystemContextView(
      key: 'test',
      softwareSystemId: 'system1',
      elements: [testElementView1, testElementView2],
      relationships: [
        const RelationshipView(id: 'rel1'),
      ],
    );

    // Track selected elements
    String? selectedElementId;
    Set<String> selectedElementIds = {};
    Set<String> selectedRelationshipIds = {};

    // Build the diagram widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: StructurizrDiagram(
              workspace: testWorkspace,
              view: view,
              isEditable: true,
              onElementSelected: (id, element) {
                selectedElementId = id;
              },
              onMultipleItemsSelected: (elementIds, relationshipIds) {
                selectedElementIds = elementIds;
                selectedRelationshipIds = relationshipIds;
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Start a lasso selection that should include the first element
    const startPoint = Offset(50, 50);
    final dragPoints = [
      const Offset(150, 50),
      const Offset(250, 150),
      const Offset(50, 150),
    ];

    // Perform the lasso selection
    await tester.dragFrom(startPoint, dragPoints[0] - startPoint);
    await tester.pumpAndSettle();
    await tester.dragFrom(dragPoints[0], dragPoints[1] - dragPoints[0]);
    await tester.pumpAndSettle();
    await tester.dragFrom(dragPoints[1], dragPoints[2] - dragPoints[1]);
    await tester.pumpAndSettle();
    await tester.dragFrom(dragPoints[2], startPoint - dragPoints[2]);
    await tester.pumpAndSettle();

    // The first element should be selected
    expect(selectedElementIds.contains('person1'), true);
    expect(selectedElementIds.contains('system1'), false);
  });

  testWidgets('Multiple selection with lasso should update selection state',
      (WidgetTester tester) async {
    // Create a simple view with two elements
    final view = SystemContextView(
      key: 'test',
      softwareSystemId: 'system1',
      elements: [testElementView1, testElementView2],
      relationships: [
        const RelationshipView(id: 'rel1'),
      ],
    );

    // Track selected elements
    String? selectedElementId;
    Set<String> selectedElementIds = {};
    Set<String> selectedRelationshipIds = {};

    // Build the diagram widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: StructurizrDiagram(
              workspace: testWorkspace,
              view: view,
              isEditable: true,
              onElementSelected: (id, element) {
                selectedElementId = id;
              },
              onMultipleItemsSelected: (elementIds, relationshipIds) {
                selectedElementIds = elementIds;
                selectedRelationshipIds = relationshipIds;
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Do a tap to select the first element
    await tester.tap(find.byType(StructurizrDiagram), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Start a lasso selection that should include both elements
    const startPoint = Offset(50, 50);
    const endPoint = Offset(600, 250);

    // Perform the lasso selection
    await tester.dragFrom(startPoint, endPoint - startPoint);
    await tester.pumpAndSettle();

    // Both elements should be selected
    expect(selectedElementIds.contains('person1'), true);
    expect(selectedElementIds.contains('system1'), true);

    // The relationship should also be selected
    expect(selectedRelationshipIds.contains('rel1'), true);
  });

  testWidgets('Lasso selection with keyboard modifiers combines selections',
      (WidgetTester tester) async {
    // Create a simple view with two elements
    final view = SystemContextView(
      key: 'test',
      softwareSystemId: 'system1',
      elements: [testElementView1, testElementView2],
      relationships: [
        const RelationshipView(id: 'rel1'),
      ],
    );

    // Track selected elements
    String? selectedElementId;
    Set<String> selectedElementIds = {};
    Set<String> selectedRelationshipIds = {};

    // Build the diagram widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: StructurizrDiagram(
              workspace: testWorkspace,
              view: view,
              isEditable: true,
              onElementSelected: (id, element) {
                selectedElementId = id;
              },
              onMultipleItemsSelected: (elementIds, relationshipIds) {
                selectedElementIds = elementIds;
                selectedRelationshipIds = relationshipIds;
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Select first element with click
    await tester.tap(find.byType(StructurizrDiagram).first,
        warnIfMissed: false);
    await tester.pumpAndSettle();

    // First selection should contain only person1
    expect(selectedElementId, 'person1');

    // Now perform a lasso selection with Shift key to add to selection
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);

    // Start a lasso selection that should include only the second element
    const startPoint = Offset(350, 50);
    const endPoint = Offset(600, 250);

    // Perform the lasso selection
    await tester.dragFrom(startPoint, endPoint - startPoint);
    await tester.pumpAndSettle();

    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    await tester.pumpAndSettle();

    // Both elements should be selected
    expect(selectedElementIds.contains('person1'), true);
    expect(selectedElementIds.contains('system1'), true);
  });

  testWidgets('Lasso selection for relationships only',
      (WidgetTester tester) async {
    // Create a simple view with two elements
    final view = SystemContextView(
      key: 'test',
      softwareSystemId: 'system1',
      elements: [testElementView1, testElementView2],
      relationships: [
        const RelationshipView(id: 'rel1'),
      ],
    );

    // Track selected elements
    String? selectedElementId;
    Set<String> selectedElementIds = {};
    Set<String> selectedRelationshipIds = {};

    // Build the diagram widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: StructurizrDiagram(
              workspace: testWorkspace,
              view: view,
              isEditable: true,
              onElementSelected: (id, element) {
                selectedElementId = id;
              },
              onMultipleItemsSelected: (elementIds, relationshipIds) {
                selectedElementIds = elementIds;
                selectedRelationshipIds = relationshipIds;
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Draw a lasso around only the relationship line (between elements)
    const startPoint = Offset(200, 50);
    final dragPoints = [
      const Offset(300, 50),
      const Offset(300, 150),
      const Offset(200, 150),
    ];

    // Perform the lasso selection
    await tester.dragFrom(startPoint, dragPoints[0] - startPoint);
    await tester.pumpAndSettle();
    await tester.dragFrom(dragPoints[0], dragPoints[1] - dragPoints[0]);
    await tester.pumpAndSettle();
    await tester.dragFrom(dragPoints[1], dragPoints[2] - dragPoints[1]);
    await tester.pumpAndSettle();
    await tester.dragFrom(dragPoints[2], startPoint - dragPoints[2]);
    await tester.pumpAndSettle();

    // The relationship should be selected, but not elements
    expect(selectedElementIds.isEmpty, true);
    expect(selectedRelationshipIds.contains('rel1'), true);
  });

  testWidgets('Lasso selection performance with many elements',
      (WidgetTester tester) async {
    // Create a view with many elements in a grid
    final elements = <ElementView>[];
    final relationships = <RelationshipView>[];

    // Create grid of 5x5 elements
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 5; j++) {
        final id = 'element_${i}_${j}';
        elements.add(ElementView(
          id: id,
          x: 100 + i * 150,
          y: 100 + j * 150,
          width: 100,
          height: 80,
        ));
      }
    }

    // Add first row to selection
    elements.add(testElementView1);
    elements.add(testElementView2);

    // Create a simple view
    final view = SystemContextView(
      key: 'test',
      softwareSystemId: 'system1',
      elements: elements,
      relationships: [
        const RelationshipView(id: 'rel1'),
      ],
    );

    // Track selected elements
    Set<String> selectedElementIds = {};
    Set<String> selectedRelationshipIds = {};

    // Build the diagram widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1000,
            height: 1000,
            child: StructurizrDiagram(
              workspace: testWorkspace,
              view: view,
              isEditable: true,
              onMultipleItemsSelected: (elementIds, relationshipIds) {
                selectedElementIds = elementIds;
                selectedRelationshipIds = relationshipIds;
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Start a lasso selection covering the entire diagram
    const startPoint = Offset(50, 50);
    const endPoint = Offset(950, 950);

    // Perform the lasso selection
    final stopwatch = Stopwatch()..start();

    await tester.dragFrom(startPoint, endPoint - startPoint);
    await tester.pumpAndSettle();

    stopwatch.stop();

    // All elements should be selected
    expect(selectedElementIds.length, equals(elements.length));

    // Verify the performance was reasonable (test will continue regardless but we record this for information)
    print(
        'Lasso selection with ${elements.length} elements took ${stopwatch.elapsedMilliseconds}ms');
  });
}
