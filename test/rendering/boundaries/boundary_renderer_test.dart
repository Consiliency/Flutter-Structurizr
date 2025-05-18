import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/presentation/rendering/boundaries/boundary_renderer.dart';
import 'package:logging/logging.dart';

final logger = Logger('TestLogger');

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    logger.info(
        '[\u001b[32m\u001b[1m\u001b[40m\u001b[0m${record.level.name}] ${record.loggerName}: ${record.message}');
  });

  group('BoundaryRenderer', () {
    late BoundaryRenderer renderer;
    late MockCanvas mockCanvas;

    setUp(() {
      renderer = BoundaryRenderer();
      mockCanvas = MockCanvas();
    });

    test(
        'calculateElementBounds returns correct bounds with explicit dimensions',
        () {
      const elementView = ElementView(
        id: 'test',
        x: 10,
        y: 20,
        width: 200,
        height: 150,
      );

      const style = ElementStyle();
      final element = BasicElement.create(
        name: 'Test Boundary',
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

    test(
        'calculateElementBounds returns default bounds when dimensions not specified',
        () {
      const elementView = ElementView(
        id: 'test',
        x: 10,
        y: 20,
      );

      const style = ElementStyle();
      final element = BasicElement.create(
        name: 'Test Boundary',
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

    test('calculateBoundaryFromContainedElements returns correct bounds', () {
      final containedElements = [
        const ElementView(id: 'e1', x: 50, y: 50, width: 100, height: 80),
        const ElementView(id: 'e2', x: 200, y: 100, width: 120, height: 90),
      ];

      const padding = 20.0;
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

    test('hitTestElement returns true when point is inside boundary', () {
      const elementView = ElementView(
        id: 'test',
        x: 10,
        y: 20,
        width: 200,
        height: 150,
      );

      const style = ElementStyle();
      final element = BasicElement.create(
        name: 'Test Boundary',
        type: 'Enterprise',
      );

      const point = Offset(100, 100); // Inside the boundary

      final result = renderer.hitTestElement(
        point: point,
        element: element,
        elementView: elementView,
        style: style,
      );

      expect(result, true);
    });

    test('hitTestElement returns false when point is outside boundary', () {
      const elementView = ElementView(
        id: 'test',
        x: 10,
        y: 20,
        width: 200,
        height: 150,
      );

      const style = ElementStyle();
      final element = BasicElement.create(
        name: 'Test Boundary',
        type: 'Enterprise',
      );

      const point = Offset(500, 500); // Outside the boundary

      final result = renderer.hitTestElement(
        point: point,
        element: element,
        elementView: elementView,
        style: style,
      );

      expect(result, false);
    });
  });
}

// Simple mock Canvas for testing
class MockCanvas implements Canvas {
  final List<Rect> drawnRects = [];
  final List<RRect> drawnRRects = [];
  final List<Path> drawnPaths = [];

  @override
  void drawRect(Rect rect, Paint paint) {
    drawnRects.add(rect);
  }

  @override
  void drawRRect(RRect rrect, Paint paint) {
    drawnRRects.add(rrect);
  }

  @override
  void drawPath(Path path, Paint paint) {
    drawnPaths.add(path);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Handle all other Canvas methods
    return null;
  }
}
