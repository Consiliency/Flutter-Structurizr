import 'package:flutter/material.dart' hide Container, Element, Border;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/presentation/rendering/boundaries/boundary_renderer.dart';

import 'mock_canvas.dart';

void main() {
  group('BoundaryRenderer', () {
    late BoundaryRenderer renderer;
    late MockCanvas mockCanvas;

    setUp(() {
      renderer = BoundaryRenderer();
      mockCanvas = MockCanvas();
    });

    test('calculateElementBounds returns correct bounds with explicit dimensions', () {
      final elementView = ElementView(
        id: 'boundary1',
        x: 10,
        y: 20,
        width: 200,
        height: 150,
      );
      
      final style = const ElementStyle();
      final element = BasicElement.create(
        name: 'Enterprise Boundary',
        type: 'Enterprise',
      );
      
      final bounds = renderer.calculateElementBounds(
        element: element,
        elementView: elementView,
        style: style,
      );
      
      expect(bounds.left, 10);
      expect(bounds.top, 20);
      expect(bounds.width, 200);
      expect(bounds.height, 150);
    });

    test('calculateElementBounds returns default bounds when dimensions not specified', () {
      final elementView = ElementView(
        id: 'boundary1',
        x: 10,
        y: 20,
      );
      
      final style = const ElementStyle();
      final element = BasicElement.create(
        name: 'Enterprise Boundary',
        type: 'Enterprise',
      );
      
      final bounds = renderer.calculateElementBounds(
        element: element,
        elementView: elementView,
        style: style,
      );
      
      expect(bounds.left, 10);
      expect(bounds.top, 20);
      // Default width and height are used
      expect(bounds.width, equals(style.width?.toDouble() ?? 200));
      expect(bounds.height, equals(style.height?.toDouble() ?? 150));
    });

    test('calculateBoundaryFromContainedElements returns correct bounds', () {
      final containedElements = [
        ElementView(id: 'e1', x: 50, y: 50, width: 100, height: 80),
        ElementView(id: 'e2', x: 200, y: 100, width: 120, height: 90),
      ];
      
      final padding = 20.0;
      final bounds = renderer.calculateBoundaryFromContainedElements(
        containedElements,
        padding,
      );
      
      // Min coords: (50, 50), Max coords: (320, 190)
      // With padding: (30, 30) to (340, 210)
      expect(bounds.left, 30);
      expect(bounds.top, 30);
      expect(bounds.right, 340);
      expect(bounds.bottom, 210);
    });

    test('calculateBoundaryFromContainedElements handles empty list', () {
      final containedElements = <ElementView>[];
      
      final padding = 20.0;
      final bounds = renderer.calculateBoundaryFromContainedElements(
        containedElements,
        padding,
      );
      
      // Default size is returned
      expect(bounds.width, 200);
      expect(bounds.height, 150);
    });

    test('hitTestElement returns true when point is inside boundary', () {
      final elementView = ElementView(
        id: 'boundary1',
        x: 10,
        y: 20,
        width: 200,
        height: 150,
      );
      
      final style = const ElementStyle();
      final element = BasicElement.create(
        name: 'Enterprise Boundary',
        type: 'Enterprise',
      );
      
      final point = Offset(100, 100); // Inside the boundary
      
      final result = renderer.hitTestElement(
        point: point,
        element: element,
        elementView: elementView,
        style: style,
      );
      
      expect(result, true);
    });

    test('hitTestElement returns false when point is outside boundary', () {
      final elementView = ElementView(
        id: 'boundary1',
        x: 10,
        y: 20,
        width: 200,
        height: 150,
      );
      
      final style = const ElementStyle();
      final element = BasicElement.create(
        name: 'Enterprise Boundary',
        type: 'Enterprise',
      );
      
      final point = Offset(500, 500); // Outside the boundary
      
      final result = renderer.hitTestElement(
        point: point,
        element: element,
        elementView: elementView,
        style: style,
      );
      
      expect(result, false);
    });

    test('renderElement draws enterprise boundary correctly', () {
      final elementView = ElementView(
        id: 'boundary1',
        x: 10,
        y: 20,
        width: 200,
        height: 150,
      );
      
      final style = const ElementStyle(
        background: Colors.lightBlue,
        stroke: Colors.blue,
        opacity: 50,
      );
      
      final element = BasicElement.create(
        name: 'Enterprise Boundary',
        type: 'Enterprise',
      );
      
      renderer.renderElement(
        canvas: mockCanvas,
        element: element,
        elementView: elementView,
        style: style,
        selected: false,
      );
      
      // Enterprise boundary is typically drawn as a rounded rectangle
      expect(mockCanvas.drawnRRects.isNotEmpty, true, 
          reason: 'Enterprise boundary should be drawn as a rounded rectangle');
    });

    test('renderElement draws software system boundary correctly', () {
      final elementView = ElementView(
        id: 'boundary1',
        x: 10,
        y: 20,
        width: 200,
        height: 150,
      );
      
      final style = const ElementStyle(
        background: Colors.lightBlue,
        stroke: Colors.blue,
        opacity: 50,
        shape: Shape.box,
      );
      
      final element = SoftwareSystem.create(
        name: 'System Boundary',
      );
      
      renderer.renderElement(
        canvas: mockCanvas,
        element: element,
        elementView: elementView,
        style: style,
        selected: false,
      );
      
      // System boundaries are typically drawn as rectangles
      expect(mockCanvas.drawnRects.isNotEmpty, true, 
          reason: 'System boundary should be drawn as a rectangle when shape is box');
    });

    test('renderElement draws container boundary correctly', () {
      final elementView = ElementView(
        id: 'boundary1',
        x: 10,
        y: 20,
        width: 200,
        height: 150,
      );
      
      final style = const ElementStyle(
        background: Colors.lightBlue,
        stroke: Colors.blue,
        opacity: 50,
        shape: Shape.roundedBox,
      );
      
      final softwareSystem = SoftwareSystem.create(name: 'System');
      final element = Container.create(
        name: 'Container Boundary',
        parentId: softwareSystem.id,
      );
      
      renderer.renderElement(
        canvas: mockCanvas,
        element: element,
        elementView: elementView,
        style: style,
        selected: false,
      );
      
      // Container boundaries with rounded shape are drawn as rounded rectangles
      expect(mockCanvas.drawnRRects.isNotEmpty, true, 
          reason: 'Container boundary with roundedBox shape should be drawn as a rounded rectangle');
    });

    test('renderElement draws dashed boundary correctly', () {
      final elementView = ElementView(
        id: 'boundary1',
        x: 10,
        y: 20,
        width: 200,
        height: 150,
      );
      
      final style = const ElementStyle(
        background: Colors.lightBlue,
        stroke: Colors.blue,
        opacity: 50,
        border: Border.dashed,
      );
      
      final element = BasicElement.create(
        name: 'Dashed Boundary',
        type: 'Enterprise',
      );
      
      renderer.renderElement(
        canvas: mockCanvas,
        element: element,
        elementView: elementView,
        style: style,
        selected: false,
      );
      
      // Dashed boundary is drawn using paths
      expect(mockCanvas.drawnPaths.isNotEmpty, true, 
          reason: 'Dashed boundary should be drawn using paths');
    });

    test('renderElement draws dotted boundary correctly', () {
      final elementView = ElementView(
        id: 'boundary1',
        x: 10,
        y: 20,
        width: 200,
        height: 150,
      );
      
      final style = const ElementStyle(
        background: Colors.lightBlue,
        stroke: Colors.blue,
        opacity: 50,
        border: Border.dotted,
      );
      
      final element = BasicElement.create(
        name: 'Dotted Boundary',
        type: 'Enterprise',
      );
      
      renderer.renderElement(
        canvas: mockCanvas,
        element: element,
        elementView: elementView,
        style: style,
        selected: false,
      );
      
      // Dotted boundary is drawn using paths
      expect(mockCanvas.drawnPaths.isNotEmpty, true, 
          reason: 'Dotted boundary should be drawn using paths');
    });

    test('renderElement handles selection state', () {
      final elementView = ElementView(
        id: 'boundary1',
        x: 10,
        y: 20,
        width: 200,
        height: 150,
      );
      
      final style = const ElementStyle(
        background: Colors.lightBlue,
        stroke: Colors.blue,
        opacity: 50,
      );
      
      final element = BasicElement.create(
        name: 'Enterprise Boundary',
        type: 'Enterprise',
      );
      
      renderer.renderElement(
        canvas: mockCanvas,
        element: element,
        elementView: elementView,
        style: style,
        selected: true, // Selected
      );
      
      // Selection indicator should be drawn
      // For rounded boundary, we expect two RRects to be drawn - one for boundary, one for selection
      expect(mockCanvas.drawnRRects.length, greaterThanOrEqualTo(2), 
          reason: 'Selected boundary should draw selection indicator');
    });

    test('renderElement draws boundary label', () {
      final elementView = ElementView(
        id: 'boundary1',
        x: 10,
        y: 20,
        width: 200,
        height: 150,
      );
      
      final style = const ElementStyle(
        background: Colors.lightBlue,
        stroke: Colors.blue,
        fontSize: 14,
        color: Colors.black,
      );
      
      final element = BasicElement.create(
        name: 'Enterprise Boundary',
        type: 'Enterprise',
      );
      
      renderer.renderElement(
        canvas: mockCanvas,
        element: element,
        elementView: elementView,
        style: style,
        selected: false,
      );
      
      // Boundaries typically have a label drawn as a rounded rectangle
      expect(mockCanvas.drawnRRects.length, greaterThanOrEqualTo(2), 
          reason: 'Boundary should have both the boundary and label background drawn');
    });
  });
}