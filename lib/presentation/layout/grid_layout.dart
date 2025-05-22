import 'dart:math';
import 'dart:ui';

import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/presentation/layout/layout_strategy.dart';
import 'package:flutter/material.dart' hide Element, Container, View;

/// A simple grid layout strategy that arranges elements in a grid pattern.
///
/// This layout strategy is most useful for:
/// - Small diagrams with few elements
/// - Initial layout before user refinement
/// - When uniformity is more important than relationship visualization
/// - Preserving hierarchical structure with nested elements
class GridLayout implements LayoutStrategy {
  /// The amount of spacing between grid cells horizontally
  final double horizontalSpacing;

  /// The amount of spacing between grid cells vertically
  final double verticalSpacing;

  /// Additional padding around the entire grid
  final double padding;

  /// How to handle elements with parent/child relationships:
  /// - true: nest children within parents
  /// - false: ignore parent relationships in layout
  final bool respectHierarchy;

  /// Bounding box containing all positioned elements
  Rect _boundingBox = Rect.zero;

  GridLayout({
    this.horizontalSpacing = 60.0,
    this.verticalSpacing = 60.0,
    this.padding = 40.0,
    this.respectHierarchy = true,
  });

  @override
  Map<String, Offset> calculateLayout({
    required List<ElementView> elementViews,
    required List<RelationshipView> relationshipViews,
    required Size canvasSize,
    required Map<String, Size> elementSizes,
  }) {
    if (elementViews.isEmpty) {
      return {};
    }

    // Use existing positions if available
    Map<String, Offset> existingPositions = {};
    for (final element in elementViews) {
      if (element.x != null && element.y != null) {
        existingPositions[element.id] = Offset(
          element.x!.toDouble(),
          element.y!.toDouble(),
        );
      }
    }

    // If we respect hierarchy, handle elements differently
    if (respectHierarchy) {
      return _calculateHierarchicalLayout(
        elementViews,
        existingPositions,
        canvasSize,
        elementSizes,
      );
    } else {
      return _calculateFlatLayout(
        elementViews,
        existingPositions,
        canvasSize,
        elementSizes,
      );
    }
  }

  /// Calculate a flat grid layout ignoring parent-child relationships
  Map<String, Offset> _calculateFlatLayout(
    List<ElementView> elementViews,
    Map<String, Offset> existingPositions,
    Size canvasSize,
    Map<String, Size> elementSizes,
  ) {
    final positions = <String, Offset>{};
    positions.addAll(existingPositions);

    // Find elements that need positioning (those without existing positions)
    final elementsToPosition = elementViews
        .where((element) => !existingPositions.containsKey(element.id))
        .toList();

    if (elementsToPosition.isEmpty) {
      _calculateBoundingBox(positions, elementSizes);
      return positions;
    }

    // Determine grid dimensions based on element count
    final elementCount = elementsToPosition.length;
    final gridSize = _calculateGridDimensions(elementCount);
    final columns = gridSize.width.toInt();
    final rows = gridSize.height.toInt();

    // Calculate effective area for grid (accounting for existing elements)
    Rect effectiveArea;
    if (existingPositions.isEmpty) {
      // If no existing positions, use the whole canvas
      effectiveArea = Rect.fromLTWH(
        padding,
        padding,
        max(0, canvasSize.width - 2 * padding),
        max(0, canvasSize.height - 2 * padding),
      );
    } else {
      // If existing positions, use remaining space or overlap if necessary
      final existingBounds = _calculateExistingBounds(
        existingPositions,
        elementSizes,
      );

      // Decide whether to place below or to the right
      if (existingBounds.width > existingBounds.height) {
        // Existing elements are wider than tall, place new elements below
        effectiveArea = Rect.fromLTWH(
          padding,
          existingBounds.bottom + verticalSpacing,
          max(0, canvasSize.width - 2 * padding),
          max(
              0,
              canvasSize.height -
                  existingBounds.bottom -
                  verticalSpacing -
                  padding),
        );
      } else {
        // Existing elements are taller than wide, place new elements to the right
        effectiveArea = Rect.fromLTWH(
          existingBounds.right + horizontalSpacing,
          padding,
          max(
              0,
              canvasSize.width -
                  existingBounds.right -
                  horizontalSpacing -
                  padding),
          max(0, canvasSize.height - 2 * padding),
        );
      }

      // If effective area is too small, use the whole canvas and overlap
      if (effectiveArea.width < 100 || effectiveArea.height < 100) {
        effectiveArea = Rect.fromLTWH(
          padding,
          padding,
          max(0, canvasSize.width - 2 * padding),
          max(0, canvasSize.height - 2 * padding),
        );
      }
    }

    // Calculate cell size
    final avgElementWidth =
        _calculateAverageSize(elementsToPosition, elementSizes).width;
    final avgElementHeight =
        _calculateAverageSize(elementsToPosition, elementSizes).height;

    final cellWidth = max(
      avgElementWidth,
      (effectiveArea.width - (columns - 1) * horizontalSpacing) / columns,
    );
    final cellHeight = max(
      avgElementHeight,
      (effectiveArea.height - (rows - 1) * verticalSpacing) / rows,
    );

    // Position each element in the grid
    int index = 0;
    for (final element in elementsToPosition) {
      // Skip elements that already have positions
      if (positions.containsKey(element.id)) {
        continue;
      }

      final row = index ~/ columns;
      final col = index % columns;

      final x = effectiveArea.left + col * (cellWidth + horizontalSpacing);
      final y = effectiveArea.top + row * (cellHeight + verticalSpacing);

      // Center the element in its cell
      final size = elementSizes[element.id] ?? const Size(100, 100);
      final centeredX = x + (cellWidth - size.width) / 2;
      final centeredY = y + (cellHeight - size.height) / 2;

      positions[element.id] = Offset(centeredX, centeredY);
      index++;
    }

    _calculateBoundingBox(positions, elementSizes);
    return positions;
  }

  /// Calculate a hierarchical layout respecting parent-child relationships
  Map<String, Offset> _calculateHierarchicalLayout(
    List<ElementView> elementViews,
    Map<String, Offset> existingPositions,
    Size canvasSize,
    Map<String, Size> elementSizes,
  ) {
    final positions = <String, Offset>{};
    positions.addAll(existingPositions);

    // Identify parent-child relationships
    final Map<String?, List<ElementView>> parentToChildren = {};
    for (final element in elementViews) {
      parentToChildren.putIfAbsent(element.parentId, () => []).add(element);
    }

    // Position top-level elements (those without parents)
    final topLevelElements = parentToChildren[null] ?? [];

    // Position top-level elements in a grid
    final topLevelLayout = _calculateFlatLayout(
      topLevelElements,
      existingPositions,
      canvasSize,
      elementSizes,
    );
    positions.addAll(topLevelLayout);

    // Now position children within their parents
    for (final parentId in parentToChildren.keys) {
      if (parentId == null) continue; // Skip top-level elements

      final children = parentToChildren[parentId]!;
      if (children.isEmpty) continue;

      // Skip if parent position is unknown
      if (!positions.containsKey(parentId)) continue;

      final parentPos = positions[parentId]!;
      final parentSize = elementSizes[parentId] ?? const Size(300, 200);

      // Calculate available area within parent (with internal padding)
      const innerPadding = 20.0;
      final availableArea = Rect.fromLTWH(
        parentPos.dx + innerPadding,
        parentPos.dy + innerPadding,
        max(0, parentSize.width - 2 * innerPadding),
        max(0, parentSize.height - 2 * innerPadding),
      );

      // Determine grid dimensions for children
      final childrenCount = children.length;
      final gridSize = _calculateGridDimensions(childrenCount);
      final columns = gridSize.width.toInt();
      final rows = gridSize.height.toInt();

      // Calculate cell size for children
      final avgChildWidth = _calculateAverageSize(children, elementSizes).width;
      final avgChildHeight =
          _calculateAverageSize(children, elementSizes).height;

      final cellWidth = max(
        avgChildWidth,
        (availableArea.width - (columns - 1) * horizontalSpacing / 2) / columns,
      );
      final cellHeight = max(
        avgChildHeight,
        (availableArea.height - (rows - 1) * verticalSpacing / 2) / rows,
      );

      // Position each child in the grid
      int index = 0;
      for (final child in children) {
        // Skip children that already have positions
        if (positions.containsKey(child.id)) {
          continue;
        }

        final row = index ~/ columns;
        final col = index % columns;

        final x =
            availableArea.left + col * (cellWidth + horizontalSpacing / 2);
        final y = availableArea.top + row * (cellHeight + verticalSpacing / 2);

        // Center the child in its cell
        final size = elementSizes[child.id] ?? const Size(80, 50);
        final centeredX = x + (cellWidth - size.width) / 2;
        final centeredY = y + (cellHeight - size.height) / 2;

        positions[child.id] = Offset(centeredX, centeredY);
        index++;
      }
    }

    _calculateBoundingBox(positions, elementSizes);
    return positions;
  }

  /// Calculate the bounding rectangle of existing positioned elements
  Rect _calculateExistingBounds(
    Map<String, Offset> existingPositions,
    Map<String, Size> elementSizes,
  ) {
    if (existingPositions.isEmpty) {
      return Rect.zero;
    }

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final entry in existingPositions.entries) {
      final id = entry.key;
      final position = entry.value;
      final size = elementSizes[id] ?? const Size(100, 100);

      minX = min(minX, position.dx);
      minY = min(minY, position.dy);
      maxX = max(maxX, position.dx + size.width);
      maxY = max(maxY, position.dy + size.height);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Calculate the grid dimensions (number of rows and columns) based on element count
  Size _calculateGridDimensions(int elementCount) {
    if (elementCount <= 0) {
      return Size.zero;
    }

    // Aim for a balanced grid (square-ish)
    int columns = sqrt(elementCount).ceil();
    int rows = (elementCount / columns).ceil();

    // Ensure we have enough cells
    while (columns * rows < elementCount) {
      columns++;
    }

    return Size(columns.toDouble(), rows.toDouble());
  }

  /// Calculate average element size from a list of elements
  Size _calculateAverageSize(
    List<ElementView> elements,
    Map<String, Size> elementSizes,
  ) {
    if (elements.isEmpty) {
      return const Size(100, 100);
    }

    double totalWidth = 0;
    double totalHeight = 0;
    int count = 0;

    for (final element in elements) {
      if (elementSizes.containsKey(element.id)) {
        final size = elementSizes[element.id]!;
        totalWidth += size.width;
        totalHeight += size.height;
        count++;
      }
    }

    if (count == 0) {
      return const Size(100, 100);
    }

    return Size(totalWidth / count, totalHeight / count);
  }

  /// Calculate the bounding box of all positioned elements
  void _calculateBoundingBox(
    Map<String, Offset> positions,
    Map<String, Size> sizes,
  ) {
    if (positions.isEmpty) {
      _boundingBox = Rect.zero;
      return;
    }

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final entry in positions.entries) {
      final id = entry.key;
      final position = entry.value;
      final size = sizes[id] ?? const Size(100, 100);

      minX = min(minX, position.dx);
      minY = min(minY, position.dy);
      maxX = max(maxX, position.dx + size.width);
      maxY = max(maxY, position.dy + size.height);
    }

    _boundingBox = Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  @override
  Rect getBoundingBox() {
    return _boundingBox;
  }

  @override
  String get name => 'Grid Layout';

  @override
  String get description =>
      'Arranges elements in a grid pattern with regular spacing';
}
