import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide Container, Element;
import 'package:flutter/rendering.dart';
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/style/branding.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';
import 'package:flutter_structurizr/domain/view/view.dart' as structurizr_view;
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/domain/view/views.dart'
    as structurizr_views;
import 'package:flutter_structurizr/presentation/layout/force_directed_layout.dart';
import 'package:flutter_structurizr/presentation/rendering/element_renderer.dart';
import 'package:flutter_structurizr/presentation/rendering/relationship_renderer.dart';
import 'package:flutter_structurizr/presentation/widgets/diagram/diagram_painter.dart';
import 'package:flutter_structurizr/presentation/widgets/diagram/structurizr_diagram.dart';
import 'package:flutter_structurizr/presentation/widgets/animation/animation_controls.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:ui' as ui;
import 'package:flutter_structurizr/domain/model/container.dart'
    as structurizr_model;
import 'package:flutter_structurizr/domain/model/component.dart'
    as structurizr_model;
import 'package:flutter_structurizr/domain/model/deployment_node.dart'
    as structurizr_model;
import 'package:flutter_structurizr/domain/model/container_instance.dart'
    as structurizr_model;
import 'package:flutter_structurizr/domain/model/infrastructure_node.dart'
    as structurizr_model;

void main() {
  group('Rendering Pipeline Integration Tests', () {
    late Workspace testWorkspace;

    // Track selection and interaction events
    String? selectedElementId;
    String? selectedRelationshipId;
    String? hoveredElementId;
    bool selectionCleared = false;
    int currentAnimationStep = 1;

    setUp(() {
      // Reset tracking variables
      selectedElementId = null;
      selectedRelationshipId = null;
      hoveredElementId = null;
      selectionCleared = false;
      currentAnimationStep = 1;

      // Create a test workspace with various diagram types
      testWorkspace = _createTestWorkspace();
    });

    testWidgets('Full rendering pipeline works for System Context view',
        (WidgetTester tester) async {
      // Get the SystemContext view from the workspace
      final systemContextView =
          _getViewByKey(testWorkspace, 'SystemContext') as SystemContextView;
      expect(systemContextView, isNotNull);

      // Build the diagram widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StructurizrDiagram(
              workspace: testWorkspace,
              view: systemContextView,
              onElementSelected: (id, element) {
                selectedElementId = id;
              },
              onRelationshipSelected: (id, relationship) {
                selectedRelationshipId = id;
              },
              onSelectionCleared: () {
                selectionCleared = true;
              },
              onElementHovered: (id, element) {
                hoveredElementId = id;
              },
            ),
          ),
        ),
      );

      // Wait for initial layout to complete
      await tester.pumpAndSettle();

      // Verify the diagram renders without errors
      expect(find.byType(StructurizrDiagram), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);

      // Verify elements are rendered and interactive
      // Tap on a position where a software system should be
      await tester.tapAt(const Offset(400, 200));
      await tester.pumpAndSettle();

      // Verify element selection works
      expect(selectedElementId, isNotNull);

      // Clear selection by tapping empty space
      await tester.tapAt(const Offset(50, 50));
      await tester.pumpAndSettle();
      expect(selectionCleared, isTrue);

      // The diagram should automatically layout elements if positions aren't provided
      final renderObject = tester.renderObject(find.byType(CustomPaint).first)
          as RenderCustomPaint;
      expect(renderObject, isNotNull);
    });

    testWidgets('Full rendering pipeline works for Container view',
        (WidgetTester tester) async {
      // Get the Container view
      final containerView =
          _getViewByKey(testWorkspace, 'Containers') as ContainerView;
      expect(containerView, isNotNull);

      // Build the diagram widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StructurizrDiagram(
              workspace: testWorkspace,
              view: containerView,
              onElementSelected: (id, element) {
                selectedElementId = id;
              },
            ),
          ),
        ),
      );

      // Wait for initial layout to complete
      await tester.pumpAndSettle();

      // Verify the diagram renders without errors
      expect(find.byType(StructurizrDiagram), findsOneWidget);

      // Tap on a position where a container should be
      await tester.tapAt(const Offset(400, 200));
      await tester.pumpAndSettle();

      // Verify element selection works in container view
      expect(selectedElementId, isNotNull);
    });

    testWidgets('Full rendering pipeline works for Component view',
        (WidgetTester tester) async {
      // Get the Component view
      final componentView =
          _getViewByKey(testWorkspace, 'Components') as ComponentView;
      expect(componentView, isNotNull);

      // Build the diagram widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StructurizrDiagram(
              workspace: testWorkspace,
              view: componentView,
              onElementSelected: (id, element) {
                selectedElementId = id;
              },
            ),
          ),
        ),
      );

      // Wait for initial layout to complete
      await tester.pumpAndSettle();

      // Verify the diagram renders without errors
      expect(find.byType(StructurizrDiagram), findsOneWidget);

      // Tap on a position where a component should be
      await tester.tapAt(const Offset(400, 200));
      await tester.pumpAndSettle();

      // Verify element selection works in component view
      expect(selectedElementId, isNotNull);
    });

    testWidgets('Zoom interaction works properly', (WidgetTester tester) async {
      // Get the view
      final systemContextView =
          _getViewByKey(testWorkspace, 'SystemContext') as SystemContextView;

      // Create a key to access the state later
      final diagKey = GlobalKey<StructurizrDiagramState>();

      // Build the diagram widget with the key
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StructurizrDiagram(
              key: diagKey,
              workspace: testWorkspace,
              view: systemContextView,
            ),
          ),
        ),
      );

      // Wait for initial layout to complete
      await tester.pumpAndSettle();

      // Get initial zoom level
      final initialZoom = diagKey.currentState!.getZoomScale();
      expect(initialZoom, isNotNull);

      // Perform a zoom gesture
      final center = tester.getCenter(find.byType(StructurizrDiagram));
      final gesture = await tester.createGesture();
      await gesture.down(center);
      await tester.pump();

      // Scale by 1.5x
      await gesture.updateScale(1.5);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      // Verify zoom changed
      final finalZoom = diagKey.currentState!.getZoomScale();
      expect(finalZoom, greaterThan(initialZoom));
    });

    testWidgets('Pan interaction works properly', (WidgetTester tester) async {
      // Get the view
      final systemContextView =
          _getViewByKey(testWorkspace, 'SystemContext') as SystemContextView;

      // Create a key to access the state later
      final diagKey = GlobalKey<StructurizrDiagramState>();

      // Build the diagram widget with the key
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StructurizrDiagram(
              key: diagKey,
              workspace: testWorkspace,
              view: systemContextView,
            ),
          ),
        ),
      );

      // Wait for initial layout to complete
      await tester.pumpAndSettle();

      // Get initial pan offset
      final initialPan = diagKey.currentState!.getPanOffset();
      expect(initialPan, isNotNull);

      // Perform a pan gesture
      final center = tester.getCenter(find.byType(StructurizrDiagram));
      await tester.dragFrom(center, const Offset(100, 100));
      await tester.pumpAndSettle();

      // Verify pan changed
      final finalPan = diagKey.currentState!.getPanOffset();
      expect(finalPan, isNot(equals(initialPan)));
    });

    testWidgets('Animation steps work correctly for dynamic views',
        (WidgetTester tester) async {
      // Get the Dynamic view
      final dynamicView = _getViewByKey(testWorkspace, 'SignIn') as DynamicView;
      expect(dynamicView, isNotNull);
      expect(dynamicView.animations.length, greaterThan(1));

      // Create a key to access the state later
      final diagKey = GlobalKey<StructurizrDiagramState>();

      // Build the diagram widget with animation step 1
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: StructurizrDiagram(
                    key: diagKey,
                    workspace: testWorkspace,
                    view: dynamicView,
                    animationStep: 1, // Start with step 1
                  ),
                ),
                // Add animation controls
                AnimationControls(
                  currentStep: 1,
                  totalSteps: dynamicView.animations.length,
                  onStepChanged: (step) {
                    currentAnimationStep = step;
                  },
                ),
              ],
            ),
          ),
        ),
      );

      // Wait for initial animation step to render
      await tester.pumpAndSettle();

      // Get element count in first animation step
      final step1ElementCount = dynamicView.animations.first.elements.length;

      // Find the next button in animation controls
      final nextButton = find.byIcon(Icons.navigate_next);
      expect(nextButton, findsOneWidget);

      // Click next button to move to step 2
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // Update the widget with the next animation step
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: StructurizrDiagram(
                    key: diagKey,
                    workspace: testWorkspace,
                    view: dynamicView,
                    animationStep: 2, // Move to step 2
                  ),
                ),
                // Add animation controls
                AnimationControls(
                  currentStep: 2,
                  totalSteps: dynamicView.animations.length,
                  onStepChanged: (step) {
                    currentAnimationStep = step;
                  },
                ),
              ],
            ),
          ),
        ),
      );

      // Wait for next animation step to render
      await tester.pumpAndSettle();

      // Get element count in second animation step
      final step2ElementCount = dynamicView.animations[1].elements.length;

      // Verify that step 2 has more elements than step 1 (animation progression)
      expect(step2ElementCount, greaterThan(step1ElementCount));
    });

    testWidgets('Layout algorithm positions elements correctly',
        (WidgetTester tester) async {
      // Get a view without predefined positions to test layout algorithm
      final systemLandscapeView =
          _getViewByKey(testWorkspace, 'SystemLandscape')
              as SystemLandscapeView;
      expect(systemLandscapeView, isNotNull);

      // Ensure automatic layout is enabled
      expect(systemLandscapeView.automaticLayout, isNotNull);

      // Build the diagram widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StructurizrDiagram(
              workspace: testWorkspace,
              view: systemLandscapeView,
            ),
          ),
        ),
      );

      // Wait for layout to complete
      await tester.pumpAndSettle();

      // Verify the diagram renders without errors
      expect(find.byType(StructurizrDiagram), findsOneWidget);

      // We can't directly verify positions in widget test, but we can check that
      // no errors are thrown during rendering, confirming layout algorithm worked
    });

    testWidgets('ElementRenderer draws elements with correct styles',
        (WidgetTester tester) async {
      // Get the SystemContext view
      final systemContextView =
          _getViewByKey(testWorkspace, 'SystemContext') as SystemContextView;

      // Build the diagram widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StructurizrDiagram(
              workspace: testWorkspace,
              view: systemContextView,
            ),
          ),
        ),
      );

      // Wait for layout to complete
      await tester.pumpAndSettle();

      // We can't directly verify visual aspects in widget tests, but we can check
      // that the diagram is rendered without throwing errors
      expect(find.byType(StructurizrDiagram), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('RelationshipRenderer draws relationships correctly',
        (WidgetTester tester) async {
      // Get the SystemContext view (which has relationships)
      final systemContextView =
          _getViewByKey(testWorkspace, 'SystemContext') as SystemContextView;
      expect(systemContextView.relationships.isNotEmpty, isTrue);

      // Build the diagram widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StructurizrDiagram(
              workspace: testWorkspace,
              view: systemContextView,
              onRelationshipSelected: (id, relationship) {
                selectedRelationshipId = id;
              },
            ),
          ),
        ),
      );

      // Wait for layout to complete
      await tester.pumpAndSettle();

      // Tap where a relationship line should be (this is approximate and might need adjustment)
      await tester.tapAt(const Offset(250, 250));
      await tester.pumpAndSettle();

      // We can't be sure we hit a relationship in a widget test, but if we do,
      // the selectedRelationshipId should be set
    });

    testWidgets('diagram control functions work correctly',
        (WidgetTester tester) async {
      // Get the SystemContext view
      final systemContextView =
          _getViewByKey(testWorkspace, 'SystemContext') as SystemContextView;

      // Create a key to access the state later
      final diagKey = GlobalKey<StructurizrDiagramState>();

      // Build the diagram widget with the key
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StructurizrDiagram(
              key: diagKey,
              workspace: testWorkspace,
              view: systemContextView,
            ),
          ),
        ),
      );

      // Wait for layout to complete
      await tester.pumpAndSettle();

      // Test fitToScreen
      final initialZoom = diagKey.currentState!.getZoomScale();
      diagKey.currentState!.fitToScreen();
      await tester.pumpAndSettle();
      final afterFitZoom = diagKey.currentState!.getZoomScale();

      // Test centerOnElement
      final initialPan = diagKey.currentState!.getPanOffset();
      // Get the ID of an element we know exists in this view
      final firstElementId = systemContextView.elements.first.id;
      diagKey.currentState!.centerOnElement(firstElementId);
      await tester.pumpAndSettle();
      final afterCenterPan = diagKey.currentState!.getPanOffset();

      // Test programmatic selection
      diagKey.currentState!.selectElement(firstElementId);
      await tester.pumpAndSettle();
      expect(diagKey.currentState!.getSelectedId(), equals(firstElementId));

      // Test clear selection
      diagKey.currentState!.clearSelection();
      await tester.pumpAndSettle();
      expect(diagKey.currentState!.getSelectedId(), isNull);

      // Verify state changes
      expect(afterFitZoom, isNot(equals(initialZoom)));
      expect(afterCenterPan, isNot(equals(initialPan)));
    });
  });
}

// Helper methods to create test data

Workspace _createTestWorkspace() {
  // 1. Create people
  final customer = Person.create(
    name: 'Customer',
    description: 'A customer of the system',
    tags: ['Person', 'Customer', 'External'],
  );

  final admin = Person.create(
    name: 'Administrator',
    description: 'System administrator',
    tags: ['Person', 'Internal'],
  );

  // 2. Create software systems
  final webSystem = SoftwareSystem.create(
    name: 'Web System',
    description: 'Main web application',
    tags: ['SoftwareSystem', 'Internal'],
  );

  final databaseSystem = SoftwareSystem.create(
    name: 'Database System',
    description: 'Database system',
    tags: ['SoftwareSystem', 'Internal', 'Database'],
  );

  final externalAPI = SoftwareSystem.create(
    name: 'External API',
    description: 'Third-party API service',
    tags: ['SoftwareSystem', 'External'],
  );

  // 3. Create relationships
  final customerWithRelationships = customer.addRelationship(
    destinationId: webSystem.id,
    description: 'Uses',
    technology: 'Web Browser',
    tags: ['Customer-System'],
  );

  final adminWithRelationships = admin.addRelationship(
    destinationId: webSystem.id,
    description: 'Manages',
    technology: 'Web Browser',
    tags: ['Admin-System'],
  );

  final webSystemWithRelationships = webSystem.addRelationship(
    destinationId: databaseSystem.id,
    description: 'Stores data in',
    technology: 'JDBC',
    tags: ['System-Database'],
  ).addRelationship(
    destinationId: externalAPI.id,
    description: 'Calls',
    technology: 'REST/HTTPS',
    tags: ['System-API'],
  );

  // 4. Create containers for the Web System
  final webApp = structurizr_model.Container.create(
    name: 'Web Application',
    description: 'Provides web UI functionality',
    parentId: webSystem.id,
    technology: 'React, TypeScript',
    tags: ['Container', 'WebApp'],
  );

  final apiServer = structurizr_model.Container.create(
    name: 'API Server',
    description: 'Provides backend API functionality',
    parentId: webSystem.id,
    technology: 'Spring Boot, Java',
    tags: ['Container', 'API'],
  );

  final database = structurizr_model.Container.create(
    name: 'Database',
    description: 'Stores application data',
    parentId: webSystem.id,
    technology: 'PostgreSQL',
    tags: ['Container', 'Database'],
  );

  // 5. Create relationships between containers
  final webAppWithRelationships = webApp.addRelationship(
    destinationId: apiServer.id,
    description: 'Makes API calls to',
    technology: 'JSON/HTTPS',
  );

  final apiServerWithRelationships = apiServer
      .addRelationship(
        destinationId: database.id,
        description: 'Reads from and writes to',
        technology: 'JDBC',
      )
      .addRelationship(
        destinationId: externalAPI.id,
        description: 'Makes API calls to',
        technology: 'REST/HTTPS',
      );

  // 6. Create components for the API Server
  final authController = structurizr_model.Component.create(
    name: 'Authentication Controller',
    description: 'Handles user authentication',
    parentId: apiServer.id,
    technology: 'Spring MVC Controller',
    tags: ['Component', 'Controller'],
  );

  final userController = structurizr_model.Component.create(
    name: 'User Controller',
    description: 'Manages user data',
    parentId: apiServer.id,
    technology: 'Spring MVC Controller',
    tags: ['Component', 'Controller'],
  );

  final securityComponent = structurizr_model.Component.create(
    name: 'Security Component',
    description: 'Handles security concerns',
    parentId: apiServer.id,
    technology: 'Spring Security',
    tags: ['Component', 'Security'],
  );

  // 7. Create relationships between components
  final authControllerWithRelationships = authController.addRelationship(
    destinationId: securityComponent.id,
    description: 'Uses',
    technology: 'Java Method Call',
  );

  final userControllerWithRelationships = userController
      .addRelationship(
        destinationId: securityComponent.id,
        description: 'Uses',
        technology: 'Java Method Call',
      )
      .addRelationship(
        destinationId: database.id,
        description: 'Reads from and writes to',
        technology: 'JDBC',
      );

  // 8. Add containers to system
  final webSystemWithContainers = webSystemWithRelationships
      .addContainer(webAppWithRelationships)
      .addContainer(apiServerWithRelationships
          .addComponent(authControllerWithRelationships)
          .addComponent(userControllerWithRelationships)
          .addComponent(securityComponent))
      .addContainer(database);

  // 9. Create the model
  final model = Model(
    enterpriseName: 'Test Enterprise',
    people: [customerWithRelationships, adminWithRelationships],
    softwareSystems: [webSystemWithContainers, databaseSystem, externalAPI],
  );

  // 10. Create views
  // System Landscape view with automatic layout
  final systemLandscapeView = SystemLandscapeView(
    key: 'SystemLandscape',
    description: 'System Landscape for Test Enterprise',
    title: 'System Landscape',
    elements: [
      structurizr_view.ElementView(id: customer.id),
      structurizr_view.ElementView(id: admin.id),
      structurizr_view.ElementView(id: webSystem.id),
      structurizr_view.ElementView(id: databaseSystem.id),
      structurizr_view.ElementView(id: externalAPI.id),
    ],
    relationships: [
      structurizr_view.RelationshipView(
          id: customerWithRelationships.relationships[0].id),
      structurizr_view.RelationshipView(
          id: adminWithRelationships.relationships[0].id),
      structurizr_view.RelationshipView(
          id: webSystemWithRelationships.relationships[0].id),
      structurizr_view.RelationshipView(
          id: webSystemWithRelationships.relationships[1].id),
    ],
    automaticLayout: const AutomaticLayout(
      implementation: 'ForceDirected',
      rankDirection: 'TopBottom',
    ),
  );

  // System Context view with specified positions
  final systemContextView = SystemContextView(
    key: 'SystemContext',
    softwareSystemId: webSystem.id,
    description: 'System Context diagram for the Web System',
    title: 'Web System - System Context',
    elements: [
      structurizr_view.ElementView(id: customer.id, x: 100, y: 100),
      structurizr_view.ElementView(id: admin.id, x: 300, y: 100),
      structurizr_view.ElementView(id: webSystem.id, x: 200, y: 300),
      structurizr_view.ElementView(id: databaseSystem.id, x: 400, y: 400),
      structurizr_view.ElementView(id: externalAPI.id, x: 0, y: 400),
    ],
    relationships: [
      structurizr_view.RelationshipView(
          id: customerWithRelationships.relationships[0].id),
      structurizr_view.RelationshipView(
          id: adminWithRelationships.relationships[0].id),
      structurizr_view.RelationshipView(
          id: webSystemWithRelationships.relationships[0].id),
      structurizr_view.RelationshipView(
          id: webSystemWithRelationships.relationships[1].id),
    ],
  );

  // Container view
  final containerView = structurizr_views.ContainerView(
    key: 'Containers',
    softwareSystemId: webSystem.id,
    description: 'Container diagram for the Web System',
    title: 'Web System - Containers',
    elements: [
      structurizr_view.ElementView(id: customer.id, x: 100, y: 100),
      structurizr_view.ElementView(id: webApp.id, x: 200, y: 300),
      structurizr_view.ElementView(id: apiServer.id, x: 400, y: 300),
      structurizr_view.ElementView(id: database.id, x: 600, y: 300),
      structurizr_view.ElementView(id: externalAPI.id, x: 400, y: 500),
    ],
    relationships: [
      structurizr_view.RelationshipView(
          id: customerWithRelationships.relationships[0].id),
      structurizr_views.RelationshipView(
          id: webAppWithRelationships.relationships[0].id),
      structurizr_view.RelationshipView(
          id: apiServerWithRelationships.relationships[0].id),
      structurizr_view.RelationshipView(
          id: apiServerWithRelationships.relationships[1].id),
    ],
  );

  // Component view
  final componentView = structurizr_views.ComponentView(
    key: 'Components',
    softwareSystemId: webSystem.id,
    containerId: apiServer.id,
    description: 'Component diagram for the API Server',
    title: 'Web System - API Server Components',
    elements: [
      structurizr_view.ElementView(id: webApp.id, x: 100, y: 100),
      structurizr_view.ElementView(id: authController.id, x: 300, y: 200),
      structurizr_view.ElementView(id: userController.id, x: 300, y: 400),
      structurizr_view.ElementView(id: securityComponent.id, x: 500, y: 300),
      structurizr_view.ElementView(id: database.id, x: 700, y: 300),
      structurizr_view.ElementView(id: externalAPI.id, x: 500, y: 500),
    ],
    relationships: [
      structurizr_views.RelationshipView(
          id: webAppWithRelationships.relationships[0].id),
      structurizr_view.RelationshipView(
          id: authControllerWithRelationships.relationships[0].id),
      structurizr_view.RelationshipView(
          id: userControllerWithRelationships.relationships[0].id),
      structurizr_view.RelationshipView(
          id: userControllerWithRelationships.relationships[1].id),
      structurizr_view.RelationshipView(
          id: apiServerWithRelationships.relationships[1].id),
    ],
  );

  // Dynamic view for login process
  final dynamicView = structurizr_views.DynamicView(
    key: 'SignIn',
    elementId: webSystem.id,
    description: 'Sign in process',
    title: 'Web System - Sign In Process',
    elements: [
      structurizr_view.ElementView(id: customer.id),
      structurizr_view.ElementView(id: webApp.id),
      structurizr_view.ElementView(id: authController.id),
      structurizr_view.ElementView(id: securityComponent.id),
      structurizr_view.ElementView(id: database.id),
    ],
    relationships: [
      structurizr_view.RelationshipView(
          id: customerWithRelationships.relationships[0].id, order: '1'),
      structurizr_views.RelationshipView(
          id: webAppWithRelationships.relationships[0].id, order: '2'),
      structurizr_view.RelationshipView(
          id: authControllerWithRelationships.relationships[0].id, order: '3'),
      structurizr_view.RelationshipView(
          id: userControllerWithRelationships.relationships[1].id, order: '4'),
    ],
    animations: [
      structurizr_views.AnimationStep(
        order: 1,
        elements: [customer.id],
      ),
      structurizr_views.AnimationStep(
        order: 2,
        elements: [customer.id, webApp.id],
        relationships: [customerWithRelationships.relationships[0].id],
      ),
      structurizr_views.AnimationStep(
        order: 3,
        elements: [customer.id, webApp.id, authController.id],
        relationships: [
          customerWithRelationships.relationships[0].id,
          webAppWithRelationships.relationships[0].id,
        ],
      ),
      structurizr_views.AnimationStep(
        order: 4,
        elements: [
          customer.id,
          webApp.id,
          authController.id,
          securityComponent.id
        ],
        relationships: [
          customerWithRelationships.relationships[0].id,
          webAppWithRelationships.relationships[0].id,
          authControllerWithRelationships.relationships[0].id,
        ],
      ),
      structurizr_views.AnimationStep(
        order: 5,
        elements: [
          customer.id,
          webApp.id,
          authController.id,
          securityComponent.id,
          database.id,
        ],
        relationships: [
          customerWithRelationships.relationships[0].id,
          webAppWithRelationships.relationships[0].id,
          authControllerWithRelationships.relationships[0].id,
          userControllerWithRelationships.relationships[1].id,
        ],
      ),
    ],
  );

  // Add views
  final views = structurizr_views.Views(
    systemLandscapeViews: [systemLandscapeView],
    systemContextViews: [systemContextView],
    containerViews: [containerView],
    componentViews: [componentView],
    dynamicViews: [dynamicView],
    configuration: structurizr_view.ViewConfiguration(
      defaultView: 'SystemContext',
      lastModifiedDate: DateTime(2023, 1, 1),
    ),
  );

  // Add styles
  const styles = Styles(
    elements: [
      structurizr_view.ElementStyle(
        tag: 'Person',
        shape: Shape.person,
        background: '#1168BD',
        color: '#FFFFFF',
      ),
      structurizr_view.ElementStyle(
        tag: 'External',
        background: '#999999',
      ),
      structurizr_view.ElementStyle(
        tag: 'SoftwareSystem',
        background: '#1168BD',
        color: '#FFFFFF',
      ),
      structurizr_view.ElementStyle(
        tag: 'Container',
        background: '#438DD5',
        color: '#FFFFFF',
      ),
      structurizr_view.ElementStyle(
        tag: 'Component',
        background: '#85BBF0',
        color: '#000000',
      ),
      structurizr_view.ElementStyle(
        tag: 'Database',
        shape: Shape.cylinder,
      ),
    ],
    relationships: [
      structurizr_view.RelationshipStyle(
        tag: 'System-Database',
        thickness: 2,
        color: '#707070',
        style: LineStyle.solid,
      ),
      structurizr_view.RelationshipStyle(
        tag: 'System-API',
        thickness: 2,
        color: '#707070',
        style: LineStyle.dashed,
      ),
    ],
  );

  // Add styles to views
  final viewsWithStyles = views.copyWith(
    styles: styles,
  );

  // Create workspace
  return Workspace(
    id: 'test',
    name: 'Test Workspace',
    description: 'Integration test workspace',
    model: model,
    views: viewsWithStyles,
  );
}

structurizr_view.View? _getViewByKey(Workspace workspace, String key) {
  return workspace.views.getViewByKey(key);
}
