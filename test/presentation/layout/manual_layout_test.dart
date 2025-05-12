import 'package:flutter_structurizr/presentation/layout/grid_layout.dart';
import 'package:flutter_structurizr/presentation/layout/layout_strategy.dart';
import 'package:flutter_structurizr/presentation/layout/manual_layout.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter/material.dart' hide Element, Container, View;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ManualLayout', () {
    test('should preserve manually set element positions', () {
      // Arrange
      final manualPositions = {
        'element1': const Offset(100, 200),
        'element2': const Offset(400, 300),
      };

      final fallbackStrategy = GridLayout();

      final layout = ManualLayout(
        fallbackStrategy: fallbackStrategy,
        manualPositions: manualPositions,
      );

      final elementViews = [
        ElementView(id: 'element1'), // Intentionally null x,y to test that manual positions take precedence
        ElementView(id: 'element2'),
      ];

      final elementSizes = {
        'element1': const Size(100, 100),
        'element2': const Size(100, 100),
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
      expect(positions['element1'], equals(manualPositions['element1']));
      expect(positions['element2'], equals(manualPositions['element2']));
    });

    test('should update positions from element views when available', () {
      // Arrange
      final manualPositions = {
        'element1': const Offset(100, 200),
      };

      final fallbackStrategy = GridLayout();

      final layout = ManualLayout(
        fallbackStrategy: fallbackStrategy,
        manualPositions: manualPositions,
      );

      final elementViewPosition = const Offset(300, 400);
      final elementViews = [
        ElementView(id: 'element1', x: elementViewPosition.dx.toInt(), y: elementViewPosition.dy.toInt()),
      ];

      final elementSizes = {
        'element1': const Size(100, 100),
      };

      // Act
      final positions = layout.calculateLayout(
        elementViews: elementViews,
        relationshipViews: <RelationshipView>[],
        canvasSize: const Size(800, 600),
        elementSizes: elementSizes,
      );

      // Assert
      expect(positions.length, 1);
      // Element view position should take precedence over manual position
      expect(positions['element1'], equals(elementViewPosition));
    });

    test('should use fallback strategy for elements without positions', () {
      // Arrange
      final manualPositions = {
        'element1': const Offset(100, 200),
      };

      final fallbackStrategy = GridLayout();

      final layout = ManualLayout(
        fallbackStrategy: fallbackStrategy,
        manualPositions: manualPositions,
        applyFallbackForMissing: true,
      );

      final elementViews = [
        ElementView(id: 'element1'),
        ElementView(id: 'element2'), // No manual position for this one
      ];

      final elementSizes = {
        'element1': const Size(100, 100),
        'element2': const Size(100, 100),
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
      expect(positions['element1'], equals(manualPositions['element1']));
      expect(positions.containsKey('element2'), true);
      expect(positions['element2'], isNot(equals(manualPositions['element1'])));
    });

    test('should not use fallback strategy when disabled', () {
      // Arrange
      final manualPositions = {
        'element1': const Offset(100, 200),
      };

      final fallbackStrategy = GridLayout();

      final layout = ManualLayout(
        fallbackStrategy: fallbackStrategy,
        manualPositions: manualPositions,
        applyFallbackForMissing: false, // Disable fallback
      );

      final elementViews = [
        ElementView(id: 'element1'),
        ElementView(id: 'element2'), // No manual position for this one
      ];

      final elementSizes = {
        'element1': const Size(100, 100),
        'element2': const Size(100, 100),
      };

      // Act
      final positions = layout.calculateLayout(
        elementViews: elementViews,
        relationshipViews: <RelationshipView>[],
        canvasSize: const Size(800, 600),
        elementSizes: elementSizes,
      );

      // Assert
      expect(positions.length, 1); // Only one element has a position
      expect(positions['element1'], equals(manualPositions['element1']));
      expect(positions.containsKey('element2'), false); // No position for element2
    });

    test('fromElementViews should create layout correctly', () {
      // Arrange
      final elementViews = [
        ElementView(id: 'element1', x: 100, y: 200),
        ElementView(id: 'element2', x: 300, y: 400),
      ];

      final fallbackStrategy = GridLayout();

      // Act
      final layout = ManualLayout.fromElementViews(
        elementViews,
        fallbackStrategy,
      );

      // Assert - positions should be extracted from element views
      final positions = layout.calculateLayout(
        elementViews: elementViews,
        relationshipViews: <RelationshipView>[],
        canvasSize: const Size(800, 600),
        elementSizes: {
          'element1': const Size(100, 100),
          'element2': const Size(100, 100),
        },
      );

      expect(positions.length, 2);
      expect(positions['element1'], equals(const Offset(100, 200)));
      expect(positions['element2'], equals(const Offset(300, 400)));
    });

    test('should calculate bounding box correctly', () {
      // Arrange
      final manualPositions = {
        'element1': const Offset(100, 200),
        'element2': const Offset(400, 300),
      };

      final layout = ManualLayout(
        fallbackStrategy: GridLayout(),
        manualPositions: manualPositions,
      );

      final elementSizes = {
        'element1': const Size(100, 100),
        'element2': const Size(150, 120),
      };

      // Act
      layout.calculateLayout(
        elementViews: <ElementView>[],
        relationshipViews: <RelationshipView>[],
        canvasSize: const Size(800, 600),
        elementSizes: elementSizes,
      );
      final boundingBox = layout.getBoundingBox();

      // Assert
      expect(boundingBox, isNotNull);
      expect(boundingBox, isNot(equals(Rect.zero)));
      expect(boundingBox.left, equals(100));
      expect(boundingBox.top, equals(200));
      expect(boundingBox.right, equals(550)); // 400 + 150
      expect(boundingBox.bottom, equals(420)); // 300 + 120
    });

    test('should handle position management methods', () {
      // Arrange
      final layout = ManualLayout(
        fallbackStrategy: GridLayout(),
        manualPositions: {
          'element1': const Offset(100, 200),
        },
      );

      // Act & Assert - Test setElementPosition
      layout.setElementPosition('element2', const Offset(300, 400));

      final positions = layout.calculateLayout(
        elementViews: <ElementView>[],
        relationshipViews: <RelationshipView>[],
        canvasSize: const Size(800, 600),
        elementSizes: {
          'element1': const Size(100, 100),
          'element2': const Size(100, 100),
        },
      );

      expect(positions.length, 2);
      expect(positions['element1'], equals(const Offset(100, 200)));
      expect(positions['element2'], equals(const Offset(300, 400)));

      // Act & Assert - Test clearElementPosition
      layout.clearElementPosition('element1');

      final positionsAfterClear = layout.calculateLayout(
        elementViews: <ElementView>[],
        relationshipViews: <RelationshipView>[],
        canvasSize: const Size(800, 600),
        elementSizes: {
          'element1': const Size(100, 100),
          'element2': const Size(100, 100),
        },
      );

      expect(positionsAfterClear.length, 1);
      expect(positionsAfterClear.containsKey('element1'), false);
      expect(positionsAfterClear['element2'], equals(const Offset(300, 400)));

      // Act & Assert - Test clearAllPositions
      layout.clearAllPositions();

      final positionsAfterClearAll = layout.calculateLayout(
        elementViews: <ElementView>[],
        relationshipViews: <RelationshipView>[],
        canvasSize: const Size(800, 600),
        elementSizes: {
          'element1': const Size(100, 100),
          'element2': const Size(100, 100),
        },
      );

      expect(positionsAfterClearAll, isEmpty);
    });

    test('should export and import positions correctly', () {
      // Arrange
      final manualPositions = {
        'element1': const Offset(100, 200),
        'element2': const Offset(300, 400),
      };

      final layout = ManualLayout(
        fallbackStrategy: GridLayout(),
        manualPositions: manualPositions,
      );

      // Act - Export positions
      final exportedPositions = layout.exportPositions();

      // Reset layout
      layout.clearAllPositions();
      expect(layout.calculateLayout(
        elementViews: <ElementView>[],
        relationshipViews: <RelationshipView>[],
        canvasSize: const Size(800, 600),
        elementSizes: {},
      ), isEmpty);

      // Import positions
      layout.importPositions(exportedPositions);

      // Test imported positions
      final positions = layout.calculateLayout(
        elementViews: <ElementView>[],
        relationshipViews: <RelationshipView>[],
        canvasSize: const Size(800, 600),
        elementSizes: {
          'element1': const Size(100, 100),
          'element2': const Size(100, 100),
        },
      );

      // Assert
      expect(positions.length, 2);
      expect(positions['element1'], equals(manualPositions['element1']));
      expect(positions['element2'], equals(manualPositions['element2']));
    });
  });
}