import 'package:flutter/material.dart' hide Container, Element, Border;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/presentation/rendering/boundaries/boundary_renderer.dart';

import 'mock_canvas.dart';

void main() {
  group('BoundaryRenderer - Performance Tests', () {
    late BoundaryRenderer renderer;
    late MockCanvas mockCanvas;

    setUp(() {
      renderer = BoundaryRenderer();
      mockCanvas = MockCanvas();
    });

    test('handles large number of contained elements efficiently', () {
      // Create a large number of contained elements
      final List<ElementView> containedElements = [];

      // Generate 100 elements in a grid pattern
      for (int i = 0; i < 10; i++) {
        for (int j = 0; j < 10; j++) {
          containedElements.add(ElementView(
            id: 'e${i}_${j}',
            x: 50 + i * 120,
            y: 50 + j * 100,
            width: 100,
            height: 80,
          ));
        }
      }

      const padding = 20.0;

      // Measure performance
      final stopwatch = Stopwatch()..start();

      final bounds = renderer.calculateBoundaryFromContainedElements(
        containedElements,
        padding,
      );

      stopwatch.stop();

      // Check that calculation completed and produced valid bounds
      expect(bounds.width, greaterThan(0));
      expect(bounds.height, greaterThan(0));

      // Verify bounds encompass all elements
      const expectedMinX = 50 - padding;
      const expectedMinY = 50 - padding;
      const expectedMaxX =
          50 + 9 * 120 + 100 + padding; // Last element right edge + padding
      const expectedMaxY =
          50 + 9 * 100 + 80 + padding; // Last element bottom edge + padding

      expect(bounds.left, lessThanOrEqualTo(expectedMinX));
      expect(bounds.top, lessThanOrEqualTo(expectedMinY));
      expect(bounds.right, greaterThanOrEqualTo(expectedMaxX));
      expect(bounds.bottom, greaterThanOrEqualTo(expectedMaxY));
    });

    test('handles deeply nested boundaries efficiently', () {
      // Create a deep nesting structure
      const int nestingDepth = 5; // 5 levels of nesting

      // Create elements for each nesting level
      final List<ModelElement> elements = [];
      final Map<String, ElementView> elementViews = {};
      final Map<String, List<String>> hierarchy = {};

      for (int i = 0; i < nestingDepth; i++) {
        final id = 'level$i';

        elements.add(BasicElement.create(
          id: id,
          name: 'Level $i Boundary',
          type: i == 0 ? 'Enterprise' : 'SoftwareSystem',
          tags: [i == 0 ? 'Enterprise' : 'System'],
        ));

        elementViews[id] = ElementView(
          id: id,
          x: i * 50,
          y: i * 50,
          width: 500 - i * 100,
          height: 400 - i * 80,
        );

        // Set up hierarchy (each level contains the next)
        if (i < nestingDepth - 1) {
          hierarchy[id] = ['level${i + 1}'];
        } else {
          hierarchy[id] = [];
        }
      }

      const styles = Styles();

      // Measure performance for calculating the outermost boundary
      final stopwatch = Stopwatch()..start();

      final result = renderer.calculateNestedBoundaryHierarchy(
        elementViews,
        hierarchy,
        'level0', // Start from outermost
        styles,
        elements,
      );

      stopwatch.stop();

      // Check that calculation completed and produced valid bounds
      expect(result.width, greaterThan(0));
      expect(result.height, greaterThan(0));

      // The result should encompass all nested elements
      expect(result.left, lessThanOrEqualTo(0)); // Outermost left
      expect(result.top, lessThanOrEqualTo(0)); // Outermost top
      expect(result.right, greaterThanOrEqualTo(500)); // Outermost right
      expect(result.bottom, greaterThanOrEqualTo(400)); // Outermost bottom
    });

    test('complex boundary rendering with all features performs adequately',
        () {
      // Create a boundary with all styling features enabled
      final element = BasicElement.create(
        name: 'Complex Boundary',
        type: 'SoftwareSystem',
        description:
            'This is a complex boundary with lots of styling features enabled',
      );

      const elementView = ElementView(
        id: 'boundary1',
        x: 10,
        y: 20,
        width: 300,
        height: 250,
      );

      // Create complex style with many features
      final style = const ElementStyle(
        background: Colors.lightBlue,
        stroke: Colors.blue,
        opacity: 70,
        shape: Shape.roundedBox,
        border: Border.dashed,
        fontSize: 14,
        color: Colors.black,
        description: true,
        labelPosition: LabelPosition.top,
        icon: true,
      );

      // Create some child rectangles
      final List<Rect> childRects = [
        const Rect.fromLTWH(50, 70, 100, 80),
        const Rect.fromLTWH(180, 70, 100, 80),
        const Rect.fromLTWH(50, 170, 100, 80),
        const Rect.fromLTWH(180, 170, 100, 80),
      ];

      // Measure rendering performance
      final stopwatch = Stopwatch()..start();

      mockCanvas.clear();
      renderer.renderBoundary(
        canvas: mockCanvas,
        element: element,
        bounds: const Rect.fromLTWH(10, 20, 300, 250),
        style: style,
        childRects: childRects,
        nestingLevel: 0,
      );

      stopwatch.stop();

      // Check that rendering completed successfully
      expect(mockCanvas.drawnRRects.isNotEmpty, isTrue);
      expect(mockCanvas.drawnPaths.isNotEmpty, isTrue);
    });
  });
}
