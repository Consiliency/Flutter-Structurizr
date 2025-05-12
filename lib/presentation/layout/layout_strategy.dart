import 'dart:ui';

import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter/material.dart' hide Element, Container, View;

/// Base interface for layout strategies in Structurizr diagrams.
///
/// Layout strategies are responsible for calculating the positions of elements
/// in a diagram view. Different strategies can be implemented for different
/// use cases: automatic layout, grid layout, manual layout, etc.
abstract class LayoutStrategy {
  /// Calculate the layout for elements in the given diagram view.
  ///
  /// [elementViews] - The elements to position in the diagram
  /// [relationshipViews] - The relationships between elements
  /// [canvasSize] - The size of the canvas/diagram area
  /// [elementSizes] - Map of element IDs to their sizes
  ///
  /// Returns a map of element IDs to their calculated positions
  Map<String, Offset> calculateLayout({
    required List<ElementView> elementViews,
    required List<RelationshipView> relationshipViews,
    required Size canvasSize,
    required Map<String, Size> elementSizes,
  });

  /// Calculate the bounding box containing all elements after layout.
  ///
  /// This can be used for centering the view or determining zoom level.
  /// This method should be called after calculateLayout.
  Rect getBoundingBox();

  /// Name of the layout strategy for UI display and selection
  String get name;

  /// Description of the layout strategy
  String get description;
}