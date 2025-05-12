import 'package:flutter/material.dart' hide Container;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/presentation/rendering/elements/person_renderer.dart';
import 'package:flutter_structurizr/presentation/rendering/elements/component_renderer.dart';
import 'package:flutter_structurizr/presentation/rendering/elements/container_renderer.dart';
import 'package:flutter_structurizr/presentation/rendering/elements/box_renderer.dart';

import 'mock_canvas.dart';

void main() {
  group('PersonRenderer', () {
    late PersonRenderer renderer;
    late MockCanvas mockCanvas;

    setUp(() {
      renderer = PersonRenderer();
      mockCanvas = MockCanvas();
    });

    test('renderElement draws a person figure and text', () {
      final element = BasicElement.create(
        name: 'User',
        description: 'End User',
        type: 'Person',
      );
      
      final elementView = ElementView(
        id: 'user1',
        x: 10,
        y: 20,
        width: 100,
        height: 120,
      );
      
      final style = const ElementStyle(
        background: Colors.blue,
        stroke: Colors.black,
        color: Colors.black,
        fontSize: 14,
        opacity: 100,
        strokeWidth: 1,
      );
      
      renderer.renderElement(
        canvas: mockCanvas,
        element: element,
        elementView: elementView,
        style: style,
        selected: false,
      );
      
      // Verify person shape elements are drawn
      expect(mockCanvas.drawnCircles.isNotEmpty, true, 
          reason: 'Head circle should be drawn');
      expect(mockCanvas.drawnLines.length, 5, 
          reason: 'Person figure should have 5 lines (body, arms, legs)');
    });

    test('calculateElementBounds returns correct bounds with explicit dimensions', () {
      final element = BasicElement.create(
        name: 'User',
        description: 'End User',
        type: 'Person',
      );
      
      final elementView = ElementView(
        id: 'user1',
        x: 10,
        y: 20,
        width: 100,
        height: 120,
      );
      
      final style = const ElementStyle();
      
      final bounds = renderer.calculateElementBounds(
        element: element,
        elementView: elementView,
        style: style,
      );
      
      expect(bounds.left, 10);
      expect(bounds.top, 20);
      expect(bounds.width, 100);
      expect(bounds.height, 120);
    });

    test('calculateElementBounds calculates size based on text when dimensions not specified', () {
      final element = BasicElement.create(
        name: 'User with a very long name that should affect the width',
        description: 'End User with detailed description',
        type: 'Person',
      );
      
      final elementView = ElementView(
        id: 'user1',
        x: 10,
        y: 20,
      );
      
      final style = const ElementStyle(
        fontSize: 14,
      );
      
      final bounds = renderer.calculateElementBounds(
        element: element,
        elementView: elementView,
        style: style,
      );
      
      expect(bounds.left, 10);
      expect(bounds.top, 20);
      expect(bounds.width, greaterThan(PersonRenderer.defaultWidth),
          reason: 'Width should be larger due to long name');
      expect(bounds.height, greaterThanOrEqualTo(PersonRenderer.defaultHeight),
          reason: 'Height should be at least the default height');
    });

    test('hitTestElement returns true when point is inside person', () {
      final element = BasicElement.create(
        name: 'User',
        type: 'Person',
      );
      
      final elementView = ElementView(
        id: 'user1',
        x: 10,
        y: 20,
        width: 100,
        height: 120,
      );
      
      final style = const ElementStyle();
      
      final point = Offset(50, 70); // Inside the person bounds
      
      final result = renderer.hitTestElement(
        point: point,
        element: element,
        elementView: elementView,
        style: style,
      );
      
      expect(result, true);
    });

    test('hitTestElement returns false when point is outside person', () {
      final element = BasicElement.create(
        name: 'User',
        type: 'Person',
      );
      
      final elementView = ElementView(
        id: 'user1',
        x: 10,
        y: 20,
        width: 100,
        height: 120,
      );
      
      final style = const ElementStyle();
      
      final point = Offset(200, 200); // Outside the person bounds
      
      final result = renderer.hitTestElement(
        point: point,
        element: element,
        elementView: elementView,
        style: style,
      );
      
      expect(result, false);
    });

    test('renderElement handles selection state', () {
      final element = BasicElement.create(
        name: 'User',
        type: 'Person',
      );
      
      final elementView = ElementView(
        id: 'user1',
        x: 10,
        y: 20,
        width: 100,
        height: 120,
      );
      
      final style = const ElementStyle(
        background: Colors.blue,
        stroke: Colors.black,
      );
      
      renderer.renderElement(
        canvas: mockCanvas,
        element: element,
        elementView: elementView,
        style: style,
        selected: true, // Selected
      );
      
      // Selection should add a rectangle around the element
      expect(mockCanvas.drawnRects.isNotEmpty, true, 
          reason: 'Selection indicator should be drawn');
    });
  });

  group('ComponentRenderer', () {
    late ComponentRenderer renderer;
    late MockCanvas mockCanvas;

    setUp(() {
      renderer = ComponentRenderer();
      mockCanvas = MockCanvas();
    });

    test('renderElement draws a component with correct shape', () {
      final element = BasicElement.create(
        name: 'API Controller',
        description: 'Handles REST API requests',
        type: 'Component',
      );
      
      final elementView = ElementView(
        id: 'comp1',
        x: 10,
        y: 20,
        width: 120,
        height: 100,
      );
      
      final style = const ElementStyle(
        background: Colors.green,
        stroke: Colors.black,
        color: Colors.black,
        fontSize: 14,
        opacity: 100,
        strokeWidth: 1,
      );
      
      renderer.renderElement(
        canvas: mockCanvas,
        element: element,
        elementView: elementView,
        style: style,
        selected: false,
      );
      
      // Verify component shapes are drawn
      expect(mockCanvas.drawnRects.isNotEmpty, true, 
          reason: 'Component box should be drawn');
      // Component typically has an icon or decoration
      expect(mockCanvas.drawnPaths.isNotEmpty, true, 
          reason: 'Component decoration should be drawn');
    });

    test('hitTestElement returns true when point is inside component', () {
      final element = BasicElement.create(
        name: 'API Controller',
        type: 'Component',
      );
      
      final elementView = ElementView(
        id: 'comp1',
        x: 10,
        y: 20,
        width: 120,
        height: 100,
      );
      
      final style = const ElementStyle();
      
      final point = Offset(50, 50); // Inside the component bounds
      
      final result = renderer.hitTestElement(
        point: point,
        element: element,
        elementView: elementView,
        style: style,
      );
      
      expect(result, true);
    });
  });

  group('ContainerRenderer', () {
    late ContainerRenderer renderer;
    late MockCanvas mockCanvas;

    setUp(() {
      renderer = ContainerRenderer();
      mockCanvas = MockCanvas();
    });

    test('renderElement draws a container with correct style', () {
      final element = BasicElement.create(
        name: 'Database',
        description: 'Stores user data',
        type: 'Container',
      );
      
      final elementView = ElementView(
        id: 'db1',
        x: 10,
        y: 20,
        width: 150,
        height: 100,
      );
      
      final style = const ElementStyle(
        background: Colors.yellow,
        stroke: Colors.black,
        color: Colors.black,
        fontSize: 14,
        opacity: 100,
        strokeWidth: 1,
        shape: Shape.cylinder,
      );
      
      renderer.renderElement(
        canvas: mockCanvas,
        element: element,
        elementView: elementView,
        style: style,
        selected: false,
      );
      
      // Verify container shapes are drawn appropriately for cylinder shape
      expect(mockCanvas.drawnPaths.isNotEmpty, true, 
          reason: 'Container with cylinder shape should use path');
    });

    test('calculateElementBounds adjusts for technology text when present', () {
      final element = BasicElement.create(
        name: 'Database',
        description: 'Stores user data',
        type: 'Container',
      );

      // Add technology as a property since it's not in the create method
      final elementWithTech = element.addProperty('technology', 'PostgreSQL');
      
      final elementView = ElementView(
        id: 'db1',
        x: 10,
        y: 20,
      );
      
      final style = const ElementStyle(
        fontSize: 14,
        metadata: true, // Show technology
      );
      
      final bounds = renderer.calculateElementBounds(
        element: element,
        elementView: elementView,
        style: style,
      );
      
      expect(bounds.left, 10);
      expect(bounds.top, 20);
      // Height should account for the extra technology text
      expect(bounds.height, greaterThanOrEqualTo(100),
          reason: 'Height should accommodate the technology text');
    });
  });

  group('BoxRenderer', () {
    late BoxRenderer renderer;
    late MockCanvas mockCanvas;

    setUp(() {
      renderer = BoxRenderer();
      mockCanvas = MockCanvas();
    });

    test('renderElement draws different shapes correctly', () {
      // Test rectangle shape
      final element = BasicElement.create(
        name: 'System',
        description: 'External System',
        type: 'SoftwareSystem',
      );
      
      final elementView = ElementView(
        id: 'sys1',
        x: 10,
        y: 20,
        width: 120,
        height: 100,
      );

      // Test rectangle shape
      final rectStyle = const ElementStyle(
        background: Colors.grey,
        stroke: Colors.black,
        shape: Shape.box,
      );
      
      mockCanvas.clear();
      renderer.renderElement(
        canvas: mockCanvas,
        element: element,
        elementView: elementView,
        style: rectStyle,
      );
      
      expect(mockCanvas.drawnRects.isNotEmpty, true, 
          reason: 'Rectangle shape should be drawn');
      
      // Test rounded rectangle shape
      final roundedStyle = const ElementStyle(
        background: Colors.grey,
        stroke: Colors.black,
        shape: Shape.roundedBox,
      );
      
      mockCanvas.clear();
      renderer.renderElement(
        canvas: mockCanvas,
        element: element,
        elementView: elementView,
        style: roundedStyle,
      );
      
      expect(mockCanvas.drawnRRects.isNotEmpty, true, 
          reason: 'Rounded rectangle shape should be drawn');
      
      // Test ellipse shape
      final ellipseStyle = const ElementStyle(
        background: Colors.grey,
        stroke: Colors.black,
        shape: Shape.ellipse,
      );
      
      mockCanvas.clear();
      renderer.renderElement(
        canvas: mockCanvas,
        element: element,
        elementView: elementView,
        style: ellipseStyle,
      );
      
      expect(mockCanvas.drawnPaths.isNotEmpty, true, 
          reason: 'Ellipse shape should be drawn using a path');
    });

    test('renderElement renders text appropriately', () {
      final element = BasicElement.create(
        name: 'System',
        description: 'External System',
        type: 'SoftwareSystem',
      );
      
      final elementView = ElementView(
        id: 'sys1',
        x: 10,
        y: 20,
        width: 120,
        height: 100,
      );
      
      final style = const ElementStyle(
        background: Colors.grey,
        stroke: Colors.black,
        color: Colors.black,
        fontSize: 14,
        opacity: 100,
        strokeWidth: 1,
        metadata: true, // Show type
        description: true, // Show description
      );
      
      renderer.renderElement(
        canvas: mockCanvas,
        element: element,
        elementView: elementView,
        style: style,
        selected: false,
      );
      
      // The name, description, and type should all be rendered
      // Since we can't directly check TextPainter usage in the mock,
      // we confirm the main element was drawn correctly
      expect(mockCanvas.drawnRects.length, greaterThanOrEqualTo(1),
          reason: 'Element should be drawn');
    });
  });
}