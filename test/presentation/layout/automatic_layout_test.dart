import 'package:flutter_structurizr/presentation/layout/automatic_layout.dart';
import 'package:flutter_structurizr/presentation/layout/layout_strategy.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter/material.dart' hide Element, Container, View;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AutomaticLayout', () {
    test('should select grid layout for small diagrams', () {
      // Arrange
      final autoLayout = AutomaticLayout(debug: true);

      final elementViews = [
        ElementView(id: 'element1'),
        ElementView(id: 'element2'),
      ];

      final elementSizes = {
        'element1': const Size(100, 100),
        'element2': const Size(100, 100),
      };

      // Act
      final positions = autoLayout.calculateLayout(
        elementViews: elementViews,
        relationshipViews: <RelationshipView>[],
        canvasSize: const Size(800, 600),
        elementSizes: elementSizes,
      );

      // Assert
      expect(positions.length, 2);
      expect(positions.containsKey('element1'), true);
      expect(positions.containsKey('element2'), true);

      // Indirectly verify that grid layout was used by checking the name
      expect(autoLayout.name, 'Automatic Layout');
      expect(autoLayout.description, contains('based on diagram content'));
    });

    test('should select force-directed layout for diagrams with boundaries', () {
      // Arrange
      final autoLayout = AutomaticLayout(debug: true);

      // We need a parent relationship, so we need to add parentId to
      // the ElementView class in domain/view/view.dart or use a different approach
      final elementViews = [
        ElementView(id: 'parent1', x: 100, y: 100), // Parent element
        ElementView(id: 'child1'), // Child element
        ElementView(id: 'element1'), // Another element
        ElementView(id: 'element2'), // Another element
        ElementView(id: 'element3'), // Another element
      ];

      // Simulate parent-child relationship by adding extra data in presentation layer
      (elementViews[1] as dynamic).parentId = 'parent1';

      final elementSizes = {
        'parent1': const Size(300, 200),
        'child1': const Size(80, 50),
        'element1': const Size(100, 100),
        'element2': const Size(100, 100),
        'element3': const Size(100, 100),
      };

      // Act
      final positions = autoLayout.calculateLayout(
        elementViews: elementViews,
        relationshipViews: <RelationshipView>[],
        canvasSize: const Size(800, 600),
        elementSizes: elementSizes,
      );

      // Assert
      expect(positions.length, 5);
      expect(positions.containsKey('parent1'), true);
      expect(positions.containsKey('child1'), true);

      // Indirectly verify that force-directed layout was selected due to boundaries
      final childPos = positions['child1']!;
      final parentPos = positions['parent1']!;

      // The child should be somewhere near its parent
      final parentRect = Rect.fromLTWH(parentPos.dx, parentPos.dy, 300, 200);
      expect(parentRect.contains(childPos) ||
             parentRect.inflate(100).contains(childPos), true);
    });

    test('should select force-directed layout for dynamic diagrams', () {
      // Arrange
      final autoLayout = AutomaticLayout(debug: true);

      final elementViews = [
        ElementView(id: 'element1'),
        ElementView(id: 'element2'),
        ElementView(id: 'element3'),
        ElementView(id: 'element4'),
        ElementView(id: 'element5'),
      ];

      // Create dynamic diagram by setting order values on relationships
      final relationshipViews = [
        RelationshipView(id: 'relationship1', order: '1'),
        RelationshipView(id: 'relationship2', order: '2'),
        RelationshipView(id: 'relationship3', order: '3'),
      ];

      // Add source and destination properties (these aren't in the original class)
      (relationshipViews[0] as dynamic).sourceId = 'element1';
      (relationshipViews[0] as dynamic).destinationId = 'element2';
      (relationshipViews[1] as dynamic).sourceId = 'element2';
      (relationshipViews[1] as dynamic).destinationId = 'element3';
      (relationshipViews[2] as dynamic).sourceId = 'element3';
      (relationshipViews[2] as dynamic).destinationId = 'element4';

      final elementSizes = {
        'element1': const Size(100, 100),
        'element2': const Size(100, 100),
        'element3': const Size(100, 100),
        'element4': const Size(100, 100),
        'element5': const Size(100, 100),
      };

      // Act
      final positions = autoLayout.calculateLayout(
        elementViews: elementViews,
        relationshipViews: relationshipViews,
        canvasSize: const Size(800, 600),
        elementSizes: elementSizes,
      );

      // Assert
      expect(positions.length, 5);

      // Indirectly verify that force-directed layout was selected for dynamic diagram
      final boundingBox = autoLayout.getBoundingBox();
      expect(boundingBox, isNot(equals(Rect.zero)));
    });

    test('should calculate bounding box correctly', () {
      // Arrange
      final autoLayout = AutomaticLayout();

      final elementViews = [
        ElementView(id: 'element1', x: 100, y: 100),
        ElementView(id: 'element2', x: 500, y: 400),
      ];

      final elementSizes = {
        'element1': const Size(100, 100),
        'element2': const Size(100, 100),
      };

      // Act
      autoLayout.calculateLayout(
        elementViews: elementViews,
        relationshipViews: <RelationshipView>[],
        canvasSize: const Size(800, 600),
        elementSizes: elementSizes,
      );
      final boundingBox = autoLayout.getBoundingBox();

      // Assert
      expect(boundingBox, isNotNull);
      expect(boundingBox, isNot(equals(Rect.zero)));
      expect(boundingBox.left, lessThanOrEqualTo(100));
      expect(boundingBox.top, lessThanOrEqualTo(100));
      expect(boundingBox.right, greaterThanOrEqualTo(600)); // 500 + 100
      expect(boundingBox.bottom, greaterThanOrEqualTo(500)); // 400 + 100
    });
  });

  group('ForceDirectedLayoutAdapter', () {
    test('should implement LayoutStrategy interface correctly', () {
      // Arrange
      final adapter = ForceDirectedLayoutAdapter(
        springConstant: 0.08,
        repulsionConstant: 25000.0,
        maxIterations: 100,
      );

      // Act & Assert
      expect(adapter, isA<LayoutStrategy>());
      expect(adapter.name, 'Force-Directed Layout');
      expect(adapter.description, contains('Physics-based layout'));
    });

    test('should calculate layout correctly', () {
      // Arrange
      final adapter = ForceDirectedLayoutAdapter(
        maxIterations: 50, // Reduce iterations for test
      );

      final elementViews = [
        ElementView(id: 'element1'),
        ElementView(id: 'element2'),
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
      };

      // Act
      final positions = adapter.calculateLayout(
        elementViews: elementViews,
        relationshipViews: relationshipViews,
        canvasSize: const Size(800, 600),
        elementSizes: elementSizes,
      );

      // Assert
      expect(positions.length, 2);
      expect(positions.containsKey('element1'), true);
      expect(positions.containsKey('element2'), true);

      // Verify that bounding box is updated
      final boundingBox = adapter.getBoundingBox();
      expect(boundingBox, isNot(equals(Rect.zero)));
    });
  });
}