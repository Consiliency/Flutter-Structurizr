import 'package:flutter_structurizr/presentation/layout/force_directed_layout.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter/material.dart' hide Element, Container, View;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ForceDirectedLayout', () {
    test('should position elements with appropriate distances', () {
      // Arrange
      final layout = ForceDirectedLayout(
        springConstant: 0.05,
        repulsionConstant: 20000.0,
        maxIterations: 100, // Reduce iterations for test performance
      );

      final elementViews = [
        ElementView(id: 'element1'),
        ElementView(id: 'element2'),
        ElementView(id: 'element3'),
      ];

      final relationshipViews = [
        RelationshipView(id: 'relationship1'),
      ];

      // Add source and destination properties (these aren't in the original class)
      (relationshipViews[0] as dynamic).sourceId = 'element1';
      (relationshipViews[0] as dynamic).destinationId = 'element2';

      final elementSizes = {
        'element1': const Size(100, 100),
        'element2': const Size(100, 100),
        'element3': const Size(100, 100),
      };

      // Act
      final positions = layout.calculateLayout(
        elementViews: elementViews,
        relationshipViews: relationshipViews,
        canvasSize: const Size(800, 600),
        elementSizes: elementSizes,
      );

      // Assert
      expect(positions.length, 3);
      expect(positions.containsKey('element1'), true);
      expect(positions.containsKey('element2'), true);
      expect(positions.containsKey('element3'), true);

      // Connected elements should be closer together than unconnected elements
      final distance12 = (positions['element1']! - positions['element2']!).distance;
      final distance13 = (positions['element1']! - positions['element3']!).distance;
      final distance23 = (positions['element2']! - positions['element3']!).distance;

      // Due to the spring force, element1 and element2 should be closer
      // than either of them to element3
      expect(distance12 < distance13 || distance12 < distance23, true);
    });

    test('should respect existing positions when provided', () {
      // Arrange
      final layout = ForceDirectedLayout(
        maxIterations: 50, // Reduce iterations for test performance
      );

      final initialPosition = Offset(200, 300);
      final elementViews = [
        ElementView(id: 'element1', x: initialPosition.dx.toInt(), y: initialPosition.dy.toInt()),
        ElementView(id: 'element2'),
      ];

      final relationshipViews = <RelationshipView>[];

      final elementSizes = {
        'element1': const Size(100, 100),
        'element2': const Size(100, 100),
      };

      // Act
      final positions = layout.calculateLayout(
        elementViews: elementViews,
        relationshipViews: relationshipViews,
        canvasSize: const Size(800, 600),
        elementSizes: elementSizes,
      );

      // Assert
      expect(positions.length, 2);
      expect(positions.containsKey('element1'), true);

      // The position should have been moved due to forces but shouldn't be extremely far
      // from the initial position
      final finalPosition = positions['element1']!;
      const maxDelta = 200.0; // Allow some movement due to forces

      expect((finalPosition - initialPosition).distance < maxDelta, true);
    });

    test('should handle boundary containment', () {
      // Arrange
      final layout = ForceDirectedLayout(
        boundaryForce: 2.0, // Strong boundary force
        maxIterations: 100,
      );

      final elementViews = [
        ElementView(id: 'boundary1', x: 100, y: 100), // Parent element (boundary)
        ElementView(id: 'child1', x: 500, y: 500), // Child element
      ];

      // Add parent-child relationship
      (elementViews[1] as dynamic).parentId = 'boundary1';

      final elementSizes = {
        'boundary1': const Size(300, 200),
        'child1': const Size(80, 50),
      };

      // Act
      final positions = layout.calculateLayout(
        elementViews: elementViews,
        relationshipViews: <RelationshipView>[],
        canvasSize: const Size(800, 600),
        elementSizes: elementSizes,
      );

      // Assert
      expect(positions.length, 2);

      final boundaryPos = positions['boundary1']!;
      final childPos = positions['child1']!;

      // Create boundary rectangle (with padding)
      const padding = 40.0;
      final boundaryRect = Rect.fromLTWH(
        boundaryPos.dx + padding,
        boundaryPos.dy + padding,
        300 - 2 * padding,
        200 - 2 * padding,
      );

      // Create child rectangle
      final childRect = Rect.fromLTWH(
        childPos.dx,
        childPos.dy,
        80,
        50,
      );

      // Child should be contained within or partially within the boundary
      final childCenter = childRect.center;

      // The boundary force should have moved the child closer to the boundary.
      // At minimum, the center of the child should be within the boundary.
      expect(boundaryRect.contains(childCenter), true);
    });

    test('should calculate bounding box correctly', () {
      // Arrange
      final layout = ForceDirectedLayout(
        maxIterations: 50,
      );

      final elementViews = [
        ElementView(id: 'element1', x: 100, y: 100),
        ElementView(id: 'element2', x: 300, y: 400),
      ];

      final elementSizes = {
        'element1': const Size(100, 100),
        'element2': const Size(150, 80),
      };

      // Act
      layout.calculateLayout(
        elementViews: elementViews,
        relationshipViews: <RelationshipView>[],
        canvasSize: const Size(800, 600),
        elementSizes: elementSizes,
      );
      final boundingBox = layout.calculateBoundingBox();

      // Assert
      expect(boundingBox, isNotNull);
      expect(boundingBox, isNot(Rect.zero));
      expect(boundingBox.left, lessThanOrEqualTo(100));
      expect(boundingBox.top, lessThanOrEqualTo(100));
      expect(boundingBox.right, greaterThanOrEqualTo(450)); // 300 + 150
      expect(boundingBox.bottom, greaterThanOrEqualTo(480)); // 400 + 80
    });
  });

  group('ForceDirectedLayoutOptimizer', () {
    test('should perform multi-phase layout', () {
      // Arrange
      final layout = ForceDirectedLayout();

      final elementViews = [
        ElementView(id: 'element1'),
        ElementView(id: 'element2'),
      ];

      final relationshipViews = [
        RelationshipView(id: 'relationship1'),
      ];

      // Add source and destination properties
      (relationshipViews[0] as dynamic).sourceId = 'element1';
      (relationshipViews[0] as dynamic).destinationId = 'element2';

      final elementSizes = {
        'element1': const Size(100, 100),
        'element2': const Size(100, 100),
      };

      // Act
      final positions = ForceDirectedLayoutOptimizer.multiPhaseLayout(
        layout: layout,
        elementViews: elementViews,
        relationshipViews: relationshipViews,
        canvasSize: const Size(800, 600),
        elementSizes: elementSizes,
      );

      // Assert
      expect(positions.length, 2);
      expect(positions.containsKey('element1'), true);
      expect(positions.containsKey('element2'), true);

      // Connected elements should be positioned reasonably close to each other
      final distance = (positions['element1']! - positions['element2']!).distance;

      // Typically elements would be positioned roughly 200-300 apart with default settings
      expect(distance, lessThan(400));
    });
  });
}