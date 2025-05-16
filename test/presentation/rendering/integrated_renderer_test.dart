import 'dart:ui';

import 'package:flutter/material.dart' hide Container, Element;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/presentation/rendering/base_renderer.dart';
import 'package:flutter_structurizr/presentation/rendering/boundaries/boundary_renderer.dart';
import 'package:flutter_structurizr/presentation/rendering/elements/component_renderer.dart';
import 'package:flutter_structurizr/presentation/rendering/elements/container_renderer.dart';
import 'package:flutter_structurizr/presentation/rendering/elements/person_renderer.dart';
import 'package:flutter_structurizr/presentation/rendering/relationships/relationship_renderer.dart';
import 'package:flutter_structurizr/presentation/widgets/diagram/diagram_painter.dart';

import 'mock_canvas.dart';

void main() {
  group('Integrated Renderer Tests', () {
    late DiagramPainter painter;
    late MockCanvas mockCanvas;
    late BoundaryRenderer boundaryRenderer;
    late ComponentRenderer componentRenderer;
    late ContainerRenderer containerRenderer;
    late PersonRenderer personRenderer;
    late RelationshipRenderer relationshipRenderer;
    
    late SoftwareSystem softwareSystem;
    late Container container1;
    late Container container2;
    late Component component1;
    late Component component2;
    late Person user;
    
    late List<ElementView> elementViews;
    late List<RelationshipView> relationshipViews;
    late Styles styles;
    
    setUp(() {
      mockCanvas = MockCanvas();
      boundaryRenderer = BoundaryRenderer();
      componentRenderer = ComponentRenderer();
      containerRenderer = ContainerRenderer();
      personRenderer = PersonRenderer();
      relationshipRenderer = RelationshipRenderer();
      
      // Create model
      softwareSystem = SoftwareSystem.create(
        id: 'sys1',
        name: 'System',
        description: 'A software system',
      );
      
      container1 = Container.create(
        id: 'cont1',
        name: 'Container 1',
        description: 'First container',
        parentId: softwareSystem.id,
      );
      
      container2 = Container.create(
        id: 'cont2',
        name: 'Container 2',
        description: 'Second container',
        parentId: softwareSystem.id,
      );
      
      component1 = Component.create(
        id: 'comp1',
        name: 'Component 1',
        description: 'First component',
        parentId: container1.id,
      );
      
      component2 = Component.create(
        id: 'comp2',
        name: 'Component 2',
        description: 'Second component',
        parentId: container2.id,
      );
      
      user = Person.create(
        id: 'user1',
        name: 'User',
        description: 'A user of the system',
      );
      
      // Create relationships
      final relationship1 = Relationship(
        id: 'rel1',
        sourceId: user.id,
        destinationId: softwareSystem.id,
        description: 'Uses',
      );
      
      final relationship2 = Relationship(
        id: 'rel2',
        sourceId: container1.id,
        destinationId: container2.id,
        description: 'Sends data to',
      );
      
      final relationship3 = Relationship(
        id: 'rel3',
        sourceId: component1.id,
        destinationId: component2.id,
        description: 'Calls API',
      );
      
      // Create views
      elementViews = [
        ElementView(id: softwareSystem.id, x: 300, y: 100, width: 450, height: 300),
        ElementView(id: container1.id, x: 350, y: 150, width: 150, height: 200),
        ElementView(id: container2.id, x: 550, y: 150, width: 150, height: 200),
        ElementView(id: component1.id, x: 370, y: 200, width: 100, height: 80),
        ElementView(id: component2.id, x: 570, y: 200, width: 100, height: 80),
        ElementView(id: user.id, x: 100, y: 150, width: 100, height: 120),
      ];
      
      relationshipViews = [
        RelationshipView(id: relationship1.id),
        RelationshipView(id: relationship2.id),
        RelationshipView(id: relationship3.id),
      ];
      
      // Set up styles
      styles = Styles(
        elements: [
          ElementStyle(tag: 'Person', shape: Shape.person, background: Colors.lightBlue),
          ElementStyle(tag: 'Software System', shape: Shape.box, background: Colors.lightGreen),
          ElementStyle(tag: 'Container', shape: Shape.box, background: Colors.orange),
          ElementStyle(tag: 'Component', shape: Shape.component, background: Colors.amber),
        ],
        relationships: [
          RelationshipStyle(tag: 'Relationship', routing: StyleRouting.orthogonal, thickness: 1, color: Colors.black),
        ],
      );
      
      // Create map of element by ID
      final elementsById = <String, ModelElement>{
        softwareSystem.id: softwareSystem,
        container1.id: container1,
        container2.id: container2,
        component1.id: component1,
        component2.id: component2,
        user.id: user,
      };
      
      // Create map of relationship by ID
      final relationshipsById = <String, Relationship>{
        relationship1.id: relationship1,
        relationship2.id: relationship2,
        relationship3.id: relationship3,
      };
      
      // Create map of element view by ID
      final elementViewsById = <String, ElementView>{};
      for (final view in elementViews) {
        elementViewsById[view.id] = view;
      }
      
      // Create map of relationship view by ID
      final relationshipViewsById = <String, RelationshipView>{};
      for (final view in relationshipViews) {
        relationshipViewsById[view.id] = view;
      }
      
      // Set up element bounds cache for relationship renderer
      final elementBoundsCache = <String, Rect>{};
      for (final elementView in elementViews) {
        final element = elementsById[elementView.id]!;
        final style = styles.findStyleForElement(element);
        final bounds = getRendererForElement(element).calculateElementBounds(
          element: element,
          elementView: elementView,
          style: style,
        );
        elementBoundsCache[elementView.id] = bounds;
      }
      
      relationshipRenderer.setElementBoundsCache(elementBoundsCache);
      
      painter = DiagramPainter(
        elements: elementsById,
        relationships: relationshipsById,
        elementViews: elementViewsById,
        relationshipViews: relationshipViewsById,
        styles: styles,
        selectedElementIds: {},
        selectedRelationshipIds: {},
        hoveredElementId: null,
        hoveredRelationshipId: null,
      );
    });
    
    BaseRenderer getRendererForElement(ModelElement element) {
      if (element is Person) {
        return personRenderer;
      } else if (element is Component) {
        return componentRenderer;
      } else if (element is Container) {
        return containerRenderer;
      } else if (element is SoftwareSystem) {
        return boundaryRenderer;
      } else {
        return boundaryRenderer;
      }
    }
    
    test('complete rendering pipeline works for all elements and relationships', () {
      // Get bounds from element views
      final bounds = elementViews.map((view) {
        final element = view.id == softwareSystem.id ? softwareSystem :
                       view.id == container1.id ? container1 :
                       view.id == container2.id ? container2 :
                       view.id == component1.id ? component1 :
                       view.id == component2.id ? component2 :
                       user;
                       
        final style = styles.findStyleForElement(element);
        final renderer = getRendererForElement(element);
        
        return renderer.calculateElementBounds(
          element: element,
          elementView: view,
          style: style,
        );
      }).toList();
      
      // Render all elements
      for (int i = 0; i < elementViews.length; i++) {
        final view = elementViews[i];
        final element = view.id == softwareSystem.id ? softwareSystem :
                       view.id == container1.id ? container1 :
                       view.id == container2.id ? container2 :
                       view.id == component1.id ? component1 :
                       view.id == component2.id ? component2 :
                       user;
                       
        final style = styles.findStyleForElement(element);
        final renderer = getRendererForElement(element);
        
        renderer.renderElement(
          canvas: mockCanvas,
          element: element,
          elementView: view,
          style: style,
          selected: false,
        );
      }
      
      // Verify that elements were drawn
      expect(mockCanvas.drawnRects.isNotEmpty || mockCanvas.drawnRRects.isNotEmpty || mockCanvas.drawnPaths.isNotEmpty, 
        isTrue, reason: 'Elements should be drawn');
      
      // Clear canvas
      mockCanvas.clear();
      
      // Render all relationships
      for (int i = 0; i < relationshipViews.length; i++) {
        final view = relationshipViews[i];
        final relationship = view.id == 'rel1' ? relationshipsById['rel1']! :
                            view.id == 'rel2' ? relationshipsById['rel2']! :
                            relationshipsById['rel3']!;
        
        final style = styles.findStyleForRelationship(relationship);
        final sourceRect = bounds[elementViews.indexWhere((e) => e.id == relationship.sourceId)];
        final targetRect = bounds[elementViews.indexWhere((e) => e.id == relationship.destinationId)];
        
        relationshipRenderer.renderRelationship(
          canvas: mockCanvas,
          relationship: relationship,
          relationshipView: view,
          style: style,
          sourceRect: sourceRect,
          targetRect: targetRect,
          selected: false,
        );
      }
      
      // Verify that relationships were drawn
      expect(mockCanvas.drawnPaths.isNotEmpty, isTrue, reason: 'Relationships should be drawn');
    });
    
    test('hover and selection visual feedback works correctly', () {
      // Get element and style
      final element = user;
      final elementView = elementViews.firstWhere((view) => view.id == element.id);
      final style = styles.findStyleForElement(element);
      final renderer = getRendererForElement(element);
      
      // Test rendering in normal state
      mockCanvas.clear();
      renderer.renderElement(
        canvas: mockCanvas,
        element: element,
        elementView: elementView,
        style: style,
        selected: false,
        hovered: false,
      );
      
      final normalDrawCount = mockCanvas.drawnPaths.length;
      
      // Test rendering in hovered state
      mockCanvas.clear();
      renderer.renderElement(
        canvas: mockCanvas,
        element: element,
        elementView: elementView,
        style: style,
        selected: false,
        hovered: true,
      );
      
      final hoveredDrawCount = mockCanvas.drawnPaths.length;
      
      // Test rendering in selected state
      mockCanvas.clear();
      renderer.renderElement(
        canvas: mockCanvas,
        element: element,
        elementView: elementView,
        style: style,
        selected: true,
        hovered: false,
      );
      
      final selectedDrawCount = mockCanvas.drawnPaths.length;
      
      // Selected and hovered states should result in more drawing operations
      expect(hoveredDrawCount, greaterThan(normalDrawCount), 
        reason: 'Hovered state should add visual feedback');
      expect(selectedDrawCount, greaterThan(normalDrawCount), 
        reason: 'Selected state should add visual feedback');
    });
    
    test('multi-selection works correctly', () {
      // Create diagram painter with multiple selections
      final customPainter = DiagramPainter(
        elements: {
          softwareSystem.id: softwareSystem,
          container1.id: container1,
          container2.id: container2,
          component1.id: component1,
          component2.id: component2,
          user.id: user,
        },
        relationships: relationshipsById,
        elementViews: {
          for (final view in elementViews) view.id: view
        },
        relationshipViews: {
          for (final view in relationshipViews) view.id: view
        },
        styles: styles,
        selectedElementIds: {container1.id, container2.id}, // Multiple elements selected
        selectedRelationshipIds: {'rel2'}, // One relationship selected
        hoveredElementId: null,
        hoveredRelationshipId: null,
      );
      
      // Create a size to paint in
      const size = Size(1000, 800);
      
      // Create a picture recorder
      final pictureRecorder = PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      
      // Paint the diagram
      customPainter.paint(canvas, size);
      
      // We can't directly test the output, but we can make sure it executes without errors
      final picture = pictureRecorder.endRecording();
      expect(picture, isNotNull);
    });
    
    test('complex diagram layout with nested boundaries renders correctly', () {
      // Create a hierarchical diagram structure
      final enterprise = BasicElement.create(
        id: 'enterprise',
        name: 'Enterprise Boundary',
        type: 'Enterprise',
        tags: ['Enterprise'],
      );
      
      final system1 = SoftwareSystem.create(
        id: 'sys1',
        name: 'System 1',
        description: 'First system',
      );
      
      final system2 = SoftwareSystem.create(
        id: 'sys2',
        name: 'System 2',
        description: 'Second system',
      );
      
      final container1 = Container.create(
        id: 'cont1',
        name: 'Container 1',
        description: 'First container',
        parentId: system1.id,
      );
      
      final container2 = Container.create(
        id: 'cont2',
        name: 'Container 2',
        description: 'Second container',
        parentId: system1.id,
      );
      
      final user = Person.create(
        id: 'user',
        name: 'User',
        description: 'A user',
      );
      
      // Create hierarchical element views with proper nesting
      final elementViews = [
        ElementView(id: enterprise.id, x: 0, y: 0, width: 800, height: 600),
        ElementView(id: system1.id, x: 50, y: 100, width: 500, height: 400),
        ElementView(id: system2.id, x: 600, y: 100, width: 150, height: 200),
        ElementView(id: container1.id, x: 100, y: 200, width: 150, height: 150),
        ElementView(id: container2.id, x: 300, y: 200, width: 150, height: 150),
        ElementView(id: user.id, x: 350, y: 50, width: 100, height: 100),
      ];
      
      // Create relationships
      final relationship1 = Relationship(
        id: 'rel1',
        sourceId: user.id,
        destinationId: system1.id,
        description: 'Uses',
      );
      
      final relationship2 = Relationship(
        id: 'rel2',
        sourceId: user.id,
        destinationId: system2.id,
        description: 'Also uses',
      );
      
      final relationship3 = Relationship(
        id: 'rel3',
        sourceId: container1.id,
        destinationId: container2.id,
        description: 'Communicates with',
      );
      
      final relationshipViews = [
        RelationshipView(id: relationship1.id),
        RelationshipView(id: relationship2.id),
        RelationshipView(id: relationship3.id),
      ];
      
      // Create maps by ID
      final elementsById = <String, ModelElement>{
        enterprise.id: enterprise,
        system1.id: system1,
        system2.id: system2,
        container1.id: container1,
        container2.id: container2,
        user.id: user,
      };
      
      final relationshipsById = <String, Relationship>{
        relationship1.id: relationship1,
        relationship2.id: relationship2,
        relationship3.id: relationship3,
      };
      
      final elementViewsById = <String, ElementView>{};
      for (final view in elementViews) {
        elementViewsById[view.id] = view;
      }
      
      final relationshipViewsById = <String, RelationshipView>{};
      for (final view in relationshipViews) {
        relationshipViewsById[view.id] = view;
      }
      
      // Set up containment hierarchy
      final containment = <String, List<String>>{
        enterprise.id: [system1.id, system2.id, user.id],
        system1.id: [container1.id, container2.id],
      };
      
      // Set up element bounds cache for relationship renderer
      final elementBoundsCache = <String, Rect>{};
      for (final elementView in elementViews) {
        final element = elementsById[elementView.id]!;
        final style = styles.findStyleForElement(element);
        final bounds = getRendererForElement(element).calculateElementBounds(
          element: element,
          elementView: elementView,
          style: style,
        );
        elementBoundsCache[elementView.id] = bounds;
      }
      
      relationshipRenderer.setElementBoundsCache(elementBoundsCache);
      
      // Create painters for the nested elements
      // (We need to render bottom-up)
      
      // 1. Render container elements
      for (final containerId in [container1.id, container2.id]) {
        final container = elementsById[containerId] as Container;
        final view = elementViewsById[containerId]!;
        final style = styles.findStyleForElement(container);
        
        mockCanvas.clear();
        containerRenderer.renderElement(
          canvas: mockCanvas,
          element: container,
          elementView: view,
          style: style,
          selected: false,
        );
      }
      
      // Verify container elements were drawn
      expect(mockCanvas.drawnRects.isNotEmpty || mockCanvas.drawnRRects.isNotEmpty, 
        isTrue, reason: 'Container elements should be drawn');
      
      // 2. Render system boundaries
      for (final systemId in [system1.id, system2.id]) {
        final system = elementsById[systemId] as SoftwareSystem;
        final view = elementViewsById[systemId]!;
        final style = styles.findStyleForElement(system);
        final childIds = containment[systemId] ?? [];
        final childRects = childIds.map((id) => elementBoundsCache[id]!).toList();
        
        mockCanvas.clear();
        boundaryRenderer.renderBoundary(
          canvas: mockCanvas,
          element: system,
          bounds: elementBoundsCache[systemId]!,
          style: style,
          childRects: childRects,
          nestingLevel: 1, // Nested 1 level deep
          parentType: 'Enterprise',
        );
      }
      
      // Verify system boundaries were drawn
      expect(mockCanvas.drawnRRects.isNotEmpty, 
        isTrue, reason: 'System boundaries should be drawn');
      
      // 3. Render enterprise boundary
      final style = styles.findStyleForElement(enterprise);
      final childIds = containment[enterprise.id] ?? [];
      final childRects = childIds.map((id) => elementBoundsCache[id]!).toList();
      
      mockCanvas.clear();
      boundaryRenderer.renderBoundary(
        canvas: mockCanvas,
        element: enterprise,
        bounds: elementBoundsCache[enterprise.id]!,
        style: style,
        childRects: childRects,
        nestingLevel: 0, // Top level
      );
      
      // Verify enterprise boundary was drawn
      expect(mockCanvas.drawnRRects.isNotEmpty, 
        isTrue, reason: 'Enterprise boundary should be drawn');
      
      // 4. Render person
      mockCanvas.clear();
      personRenderer.renderElement(
        canvas: mockCanvas,
        element: user,
        elementView: elementViewsById[user.id]!,
        style: styles.findStyleForElement(user),
        selected: false,
      );
      
      // Verify person was drawn
      expect(mockCanvas.drawnPaths.isNotEmpty, 
        isTrue, reason: 'Person should be drawn');
      
      // 5. Render relationships
      mockCanvas.clear();
      for (final relationshipId in relationshipsById.keys) {
        final relationship = relationshipsById[relationshipId]!;
        final view = relationshipViewsById[relationshipId]!;
        final style = styles.findStyleForRelationship(relationship);
        final sourceRect = elementBoundsCache[relationship.sourceId]!;
        final targetRect = elementBoundsCache[relationship.destinationId]!;
        
        relationshipRenderer.renderRelationship(
          canvas: mockCanvas,
          relationship: relationship,
          relationshipView: view,
          style: style,
          sourceRect: sourceRect,
          targetRect: targetRect,
          selected: false,
        );
      }
      
      // Verify relationships were drawn
      expect(mockCanvas.drawnPaths.isNotEmpty, 
        isTrue, reason: 'Relationships should be drawn');
    });
  });
}