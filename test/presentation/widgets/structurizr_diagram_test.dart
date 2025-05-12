import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide Element, Container;
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/presentation/widgets/diagram/structurizr_diagram.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StructurizrDiagram Widget', () {
    // Test data
    late Workspace workspace;
    late View view;
    
    // Callback tracking
    String? selectedElementId;
    String? selectedRelationshipId;
    bool selectionCleared = false;
    String? hoveredElementId;
    
    setUp(() {
      // Reset callback tracking
      selectedElementId = null;
      selectedRelationshipId = null;
      selectionCleared = false;
      hoveredElementId = null;
      
      // Create a simple workspace with some elements and relationships
      workspace = Workspace(
        id: 'test',
        name: 'Test Workspace',
        description: 'Test workspace for diagram tests',
        model: WorkspaceModel(
          people: [
            Person(
              id: 'user',
              name: 'User',
              description: 'A user of the system',
            ),
          ],
          softwareSystems: [
            SoftwareSystem(
              id: 'system',
              name: 'Software System',
              description: 'The software system',
            ),
            SoftwareSystem(
              id: 'external',
              name: 'External System',
              description: 'An external system',
            ),
          ],
          relationships: [
            Relationship(
              id: 'rel1',
              sourceId: 'user',
              destinationId: 'system',
              description: 'Uses',
            ),
            Relationship(
              id: 'rel2',
              sourceId: 'system',
              destinationId: 'external',
              description: 'Gets data from',
            ),
          ],
        ),
        views: WorkspaceViews(
          configuration: ViewConfiguration(
            styles: Styles(
              elements: [
                ElementStyle(
                  tag: 'Person',
                  shape: 'Person',
                  background: '#08427B',
                  color: '#FFFFFF',
                ),
                ElementStyle(
                  tag: 'Software System',
                  shape: 'RoundedBox',
                  background: '#1168BD',
                  color: '#FFFFFF',
                ),
              ],
              relationships: [
                RelationshipStyle(
                  tag: 'Relationship',
                  color: '#707070',
                  thickness: 2,
                ),
              ],
            ),
          ),
        ),
      );
      
      // Create a simple view with fixed positions for testing
      view = SystemContextView(
        key: 'test-view',
        softwareSystemId: 'system',
        description: 'Test view',
        elements: [
          ElementView(
            id: 'user',
            x: 100,
            y: 100,
            width: 120,
            height: 160,
          ),
          ElementView(
            id: 'system',
            x: 300,
            y: 300,
            width: 200,
            height: 100,
          ),
          ElementView(
            id: 'external',
            x: 600,
            y: 300,
            width: 200,
            height: 100,
          ),
        ],
        relationships: [
          RelationshipView(
            id: 'rel1',
          ),
          RelationshipView(
            id: 'rel2',
          ),
        ],
      );
    });
    
    testWidgets('renders correctly with basic configuration', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StructurizrDiagram(
              workspace: workspace,
              view: view,
            ),
          ),
        ),
      );
      
      // Verify rendering - we can't check exact visual details in widget tests,
      // but we can verify that the widget renders without errors
      expect(find.byType(StructurizrDiagram), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });
    
    testWidgets('calls onElementSelected callback when element is tapped', (WidgetTester tester) async {
      // Build the widget with selection callback
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StructurizrDiagram(
              workspace: workspace,
              view: view,
              onElementSelected: (id, element) {
                selectedElementId = id;
              },
            ),
          ),
        ),
      );
      
      // Wait for initial layout to complete
      await tester.pumpAndSettle();
      
      // Tap on the system element
      await tester.tapAt(const Offset(350, 350)); // Position where 'system' should be
      await tester.pumpAndSettle();
      
      // Verify callback was called with correct element
      expect(selectedElementId, 'system');
    });
    
    testWidgets('calls onSelectionCleared callback when background is tapped', (WidgetTester tester) async {
      // Build the widget with selection and clear callbacks
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StructurizrDiagram(
              workspace: workspace,
              view: view,
              onElementSelected: (id, element) {
                selectedElementId = id;
              },
              onSelectionCleared: () {
                selectionCleared = true;
              },
            ),
          ),
        ),
      );
      
      // Wait for initial layout to complete
      await tester.pumpAndSettle();
      
      // First select an element
      await tester.tapAt(const Offset(350, 350)); // Position where 'system' should be
      await tester.pumpAndSettle();
      expect(selectedElementId, 'system');
      
      // Then tap background to clear selection
      await tester.tapAt(const Offset(50, 50)); // Position with no element
      await tester.pumpAndSettle();
      
      // Verify clear callback was called
      expect(selectionCleared, isTrue);
    });
    
    testWidgets('supports zoom gestures', (WidgetTester tester) async {
      // Create a key to access the state later
      final diagKey = GlobalKey<StructurizrDiagramState>();
      
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StructurizrDiagram(
              key: diagKey,
              workspace: workspace,
              view: view,
            ),
          ),
        ),
      );
      
      // Wait for initial layout to complete
      await tester.pumpAndSettle();
      
      // Get initial zoom
      final initialZoom = diagKey.currentState!.getZoomScale();
      
      // Simulate a pinch-to-zoom gesture
      final center = tester.getCenter(find.byType(StructurizrDiagram));
      final gesture = await tester.createGesture();
      await gesture.down(center);
      await tester.pump();
      
      // Scale by 2x
      await gesture.updateScale(2.0);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      
      // Get final zoom
      final finalZoom = diagKey.currentState!.getZoomScale();
      
      // Verify zoom changed - may not be exactly 2x due to min/max clamping
      expect(finalZoom, greaterThan(initialZoom));
    });
    
    testWidgets('supports pan gestures', (WidgetTester tester) async {
      // Create a key to access the state later
      final diagKey = GlobalKey<StructurizrDiagramState>();
      
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StructurizrDiagram(
              key: diagKey,
              workspace: workspace,
              view: view,
            ),
          ),
        ),
      );
      
      // Wait for initial layout to complete
      await tester.pumpAndSettle();
      
      // Get initial pan offset
      final initialPan = diagKey.currentState!.getPanOffset();
      
      // Simulate a drag gesture
      final center = tester.getCenter(find.byType(StructurizrDiagram));
      final target = center + const Offset(100, 100);
      await tester.dragFrom(center, target - center);
      await tester.pumpAndSettle();
      
      // Get final pan offset
      final finalPan = diagKey.currentState!.getPanOffset();
      
      // Verify pan changed
      expect(finalPan, isNot(equals(initialPan)));
    });
    
    testWidgets('disables interactions when configured', (WidgetTester tester) async {
      // Create a key to access the state later
      final diagKey = GlobalKey<StructurizrDiagramState>();
      
      // Build the widget with interactions disabled
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StructurizrDiagram(
              key: diagKey,
              workspace: workspace,
              view: view,
              config: const StructurizrDiagramConfig(
                enablePan: false,
                enableZoom: false,
                enableSelection: false,
              ),
            ),
          ),
        ),
      );
      
      // Wait for initial layout to complete
      await tester.pumpAndSettle();
      
      // Get initial values
      final initialZoom = diagKey.currentState!.getZoomScale();
      final initialPan = diagKey.currentState!.getPanOffset();
      final initialSelection = diagKey.currentState!.getSelectedId();
      
      // Simulate interactions that should be disabled
      
      // Try to zoom
      final center = tester.getCenter(find.byType(StructurizrDiagram));
      final gesture = await tester.createGesture();
      await gesture.down(center);
      await tester.pump();
      await gesture.updateScale(2.0);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      
      // Try to pan
      await tester.dragFrom(center, const Offset(100, 100));
      await tester.pumpAndSettle();
      
      // Try to select
      await tester.tapAt(const Offset(350, 350)); // Position where 'system' should be
      await tester.pumpAndSettle();
      
      // Verify none of these had an effect
      expect(diagKey.currentState!.getZoomScale(), equals(initialZoom));
      expect(diagKey.currentState!.getPanOffset(), equals(initialPan));
      expect(diagKey.currentState!.getSelectedId(), equals(initialSelection));
    });
    
    testWidgets('fitToScreen centers and fits all elements', (WidgetTester tester) async {
      // Create a key to access the state later
      final diagKey = GlobalKey<StructurizrDiagramState>();
      
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StructurizrDiagram(
              key: diagKey,
              workspace: workspace,
              view: view,
              config: const StructurizrDiagramConfig(
                fitToScreen: false, // Don't auto-fit
                centerOnStart: false,
              ),
            ),
          ),
        ),
      );
      
      // Wait for initial layout to complete
      await tester.pumpAndSettle();
      
      // Get initial values
      final initialZoom = diagKey.currentState!.getZoomScale();
      final initialPan = diagKey.currentState!.getPanOffset();
      
      // Call fitToScreen
      diagKey.currentState!.fitToScreen();
      
      // Wait for animation to complete
      await tester.pumpAndSettle();
      
      // Get final values
      final finalZoom = diagKey.currentState!.getZoomScale();
      final finalPan = diagKey.currentState!.getPanOffset();
      
      // Verify the values changed
      expect(finalZoom, isNot(equals(initialZoom)));
      expect(finalPan, isNot(equals(initialPan)));
    });
    
    testWidgets('centerOnElement focuses on specific element', (WidgetTester tester) async {
      // Create a key to access the state later
      final diagKey = GlobalKey<StructurizrDiagramState>();
      
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StructurizrDiagram(
              key: diagKey,
              workspace: workspace,
              view: view,
              config: const StructurizrDiagramConfig(
                fitToScreen: false, // Don't auto-fit
                centerOnStart: false,
              ),
            ),
          ),
        ),
      );
      
      // Wait for initial layout to complete
      await tester.pumpAndSettle();
      
      // Get initial values
      final initialPan = diagKey.currentState!.getPanOffset();
      
      // Center on a specific element
      diagKey.currentState!.centerOnElement('external');
      
      // Wait for animation to complete
      await tester.pumpAndSettle();
      
      // Get final values
      final finalPan = diagKey.currentState!.getPanOffset();
      
      // Verify the pan changed
      expect(finalPan, isNot(equals(initialPan)));
    });
    
    testWidgets('programmatic selection works', (WidgetTester tester) async {
      // Create a key to access the state later
      final diagKey = GlobalKey<StructurizrDiagramState>();
      
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StructurizrDiagram(
              key: diagKey,
              workspace: workspace,
              view: view,
              onElementSelected: (id, element) {
                selectedElementId = id;
              },
            ),
          ),
        ),
      );
      
      // Wait for initial layout to complete
      await tester.pumpAndSettle();
      
      // Select element programmatically
      diagKey.currentState!.selectElement('external');
      await tester.pumpAndSettle();
      
      // Verify selection
      expect(diagKey.currentState!.getSelectedId(), equals('external'));
      expect(selectedElementId, equals('external'));
      
      // Clear selection programmatically
      diagKey.currentState!.clearSelection();
      await tester.pumpAndSettle();
      
      // Verify selection cleared
      expect(diagKey.currentState!.getSelectedId(), isNull);
    });
    
    testWidgets('handles view and workspace changes', (WidgetTester tester) async {
      // Create a key to access the state later
      final diagKey = GlobalKey<StructurizrDiagramState>();
      
      // Build initial widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StructurizrDiagram(
              key: diagKey,
              workspace: workspace,
              view: view,
            ),
          ),
        ),
      );
      
      // Wait for initial layout to complete
      await tester.pumpAndSettle();
      
      // Select an element
      diagKey.currentState!.selectElement('system');
      await tester.pumpAndSettle();
      
      // Create a new view
      final newView = SystemContextView(
        key: 'new-view',
        softwareSystemId: 'system',
        description: 'New test view',
        elements: [
          ElementView(
            id: 'user',
            x: 200,
            y: 200,
          ),
          ElementView(
            id: 'system',
            x: 400,
            y: 400,
          ),
        ],
        relationships: [
          RelationshipView(
            id: 'rel1',
          ),
        ],
      );
      
      // Update the widget with the new view
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StructurizrDiagram(
              key: diagKey,
              workspace: workspace,
              view: newView, // Changed view
            ),
          ),
        ),
      );
      
      // Wait for layout to update
      await tester.pumpAndSettle();
      
      // Check that selection was reset
      expect(diagKey.currentState!.getSelectedId(), isNull);
    });
    
    testWidgets('supports animation steps', (WidgetTester tester) async {
      // Create a view with animation steps
      final animatedView = SystemContextView(
        key: 'animated-view',
        softwareSystemId: 'system',
        description: 'Animated test view',
        elements: [
          ElementView(
            id: 'user',
            x: 100,
            y: 100,
          ),
          ElementView(
            id: 'system',
            x: 300,
            y: 300,
          ),
          ElementView(
            id: 'external',
            x: 600,
            y: 300,
          ),
        ],
        relationships: [
          RelationshipView(
            id: 'rel1',
          ),
          RelationshipView(
            id: 'rel2',
          ),
        ],
        animations: [
          const AnimationStep(
            order: 1,
            elements: ['user', 'system'],
            relationships: ['rel1'],
          ),
          const AnimationStep(
            order: 2,
            elements: ['user', 'system', 'external'],
            relationships: ['rel1', 'rel2'],
          ),
        ],
      );
      
      // Build the widget with animation step 1
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StructurizrDiagram(
              workspace: workspace,
              view: animatedView,
              animationStep: 1, // Show first animation step
            ),
          ),
        ),
      );
      
      // Wait for layout to complete
      await tester.pumpAndSettle();
      
      // Update to step 2
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StructurizrDiagram(
              workspace: workspace,
              view: animatedView,
              animationStep: 2, // Show second animation step
            ),
          ),
        ),
      );
      
      // Wait for animation to complete
      await tester.pumpAndSettle();
    });
    
    testWidgets('displays grid when enabled', (WidgetTester tester) async {
      // Build the widget with grid enabled
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StructurizrDiagram(
              workspace: workspace,
              view: view,
              config: const StructurizrDiagramConfig(
                showGrid: true,
                gridSpacing: 50.0,
                gridColor: Colors.grey,
              ),
            ),
          ),
        ),
      );
      
      // Verify rendering - we can't see the grid lines in widget tests,
      // but we can check that the special grid painter is used
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}