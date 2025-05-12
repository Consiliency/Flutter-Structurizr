import 'dart:math';
import 'dart:ui';

import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/presentation/layout/layout_strategy.dart';
import 'package:flutter/material.dart' hide Element, Container, View;

/// A layout strategy that preserves manual positioning of elements.
///
/// This layout strategy:
/// - Preserves existing positions for elements that have them
/// - Provides fallback positioning for elements without defined positions
/// - Supports saving and restoring layout configurations
/// - Can handle partial manual layouts (mixing manual and automatic positioning)
class ManualLayout implements LayoutStrategy {
  /// Fallback strategy to use for elements without manual positions
  final LayoutStrategy fallbackStrategy;

  /// Mapping of element IDs to manually set positions
  final Map<String, Offset> manualPositions;

  /// Whether to apply the fallback strategy for unpositioned elements
  final bool applyFallbackForMissing;

  /// Bounding box containing all positioned elements
  Rect _boundingBox = Rect.zero;

  ManualLayout({
    required this.fallbackStrategy,
    this.manualPositions = const {},
    this.applyFallbackForMissing = true,
  });

  /// Create a manual layout using positions from element views
  factory ManualLayout.fromElementViews(
    List<ElementView> elementViews,
    LayoutStrategy fallbackStrategy,
  ) {
    Map<String, Offset> positions = {};
    for (final element in elementViews) {
      if (element.x != null && element.y != null) {
        positions[element.id] = Offset(
          element.x!.toDouble(),
          element.y!.toDouble(),
        );
      }
    }
    return ManualLayout(
      fallbackStrategy: fallbackStrategy,
      manualPositions: positions,
    );
  }

  @override
  Map<String, Offset> calculateLayout({
    required List<ElementView> elementViews,
    required List<RelationshipView> relationshipViews,
    required Size canvasSize,
    required Map<String, Size> elementSizes,
  }) {
    // Start with our manual positions
    final positions = Map<String, Offset>.from(manualPositions);

    // Update manual positions with any recent positions from element views
    for (final element in elementViews) {
      if (element.x != null && element.y != null) {
        positions[element.id] = Offset(
          element.x!.toDouble(),
          element.y!.toDouble(),
        );
      }
    }

    // If we should apply fallback strategy for missing elements
    if (applyFallbackForMissing) {
      // Identify elements needing positions
      final elementsNeedingPositions = elementViews
          .where((element) => !positions.containsKey(element.id))
          .toList();

      if (elementsNeedingPositions.isNotEmpty) {
        // Use the fallback strategy for elements without positions
        final fallbackPositions = fallbackStrategy.calculateLayout(
          elementViews: elementsNeedingPositions,
          relationshipViews: relationshipViews,
          canvasSize: canvasSize,
          elementSizes: elementSizes,
        );

        // Add fallback positions to our result
        positions.addAll(fallbackPositions);
      }
    }

    _calculateBoundingBox(positions, elementSizes);
    return positions;
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
      final size = sizes[id] ?? Size(100, 100);

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
  String get name => 'Manual Layout';

  @override
  String get description =>
      'Preserves manually positioned elements and arrangements';

  /// Set the position for a specific element
  void setElementPosition(String elementId, Offset position) {
    manualPositions[elementId] = position;
  }

  /// Remove a specific element from manual positions
  void clearElementPosition(String elementId) {
    manualPositions.remove(elementId);
  }

  /// Clear all manual positions
  void clearAllPositions() {
    manualPositions.clear();
  }

  /// Export manual positions as a map for serialization
  Map<String, Map<String, double>> exportPositions() {
    final result = <String, Map<String, double>>{};
    
    for (final entry in manualPositions.entries) {
      result[entry.key] = {
        'x': entry.value.dx,
        'y': entry.value.dy,
      };
    }
    
    return result;
  }

  /// Import positions from a serialized map
  void importPositions(Map<String, Map<String, dynamic>> serializedPositions) {
    manualPositions.clear();
    
    for (final entry in serializedPositions.entries) {
      final x = entry.value['x'];
      final y = entry.value['y'];
      
      if (x is num && y is num) {
        manualPositions[entry.key] = Offset(
          x.toDouble(),
          y.toDouble(),
        );
      }
    }
  }
}