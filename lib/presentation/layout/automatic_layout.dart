import 'dart:ui';
import 'dart:math';

import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/domain/view/model_view.dart';
import 'package:flutter_structurizr/presentation/layout/force_directed_layout.dart';
import 'package:flutter_structurizr/presentation/layout/grid_layout.dart';
import 'package:flutter_structurizr/presentation/layout/layout_strategy.dart';
import 'package:flutter_structurizr/util/import_helper.dart';
import 'package:flutter/material.dart' hide Element, Container, View;

/// AutomaticLayout is a meta-strategy that selects the appropriate layout
/// algorithm based on the diagram type and content.
///
/// This strategy analyzes the diagram and chooses the most appropriate layout:
/// - For small diagrams (< 5 elements): Grid layout for simplicity
/// - For context diagrams: Force-directed with emphasis on central element
/// - For container diagrams: Force-directed with boundary constraints
/// - For component diagrams: Force-directed with hierarchical emphasis
/// - For dynamic diagrams: Special ordering based on sequence
class AutomaticLayout implements LayoutStrategy {
  /// Cache for the actual strategy used after selection
  LayoutStrategy? _selectedStrategy;

  /// Whether to enable debug output
  final bool debug;

  AutomaticLayout({this.debug = false});

  @override
  Map<String, Offset> calculateLayout({
    required List<ElementView> elementViews,
    required List<RelationshipView> relationshipViews,
    required Size canvasSize,
    required Map<String, Size> elementSizes,
  }) {
    // Select the appropriate layout strategy based on the diagram content
    _selectedStrategy = _selectLayoutStrategy(
      elementViews,
      relationshipViews,
      elementViews.length,
    );

    if (debug) {
      print('AutomaticLayout: Selected strategy: ${_selectedStrategy?.name}');
    }

    // Use the selected strategy to calculate the layout
    return _selectedStrategy!.calculateLayout(
      elementViews: elementViews,
      relationshipViews: relationshipViews,
      canvasSize: canvasSize,
      elementSizes: elementSizes,
    );
  }

  /// Select the most appropriate layout strategy based on the diagram content
  LayoutStrategy _selectLayoutStrategy(
    List<ElementView> elementViews,
    List<RelationshipView> relationshipViews,
    int elementCount,
  ) {
    // For very small diagrams (fewer than 5 elements), use a simple grid layout
    if (elementCount < 5) {
      return GridLayout();
    }

    // Analyze the diagram to determine its type and characteristics
    bool hasBoundaries = _hasBoundariesOrContainment(elementViews);
    bool isDynamic = _isDynamicDiagram(relationshipViews);
    bool hasHighConnectivity = _hasHighConnectivityRatio(
      elementViews.length,
      relationshipViews.length,
    );

    // For diagrams with boundaries, optimize for boundary visualization
    if (hasBoundaries) {
      return ForceDirectedLayoutAdapter(
        springConstant: 0.05,
        repulsionConstant: 25000.0,
        boundaryForce: 2.0,  // Stronger boundary force
      );
    }

    // For dynamic diagrams (sequence diagrams)
    if (isDynamic) {
      return ForceDirectedLayoutAdapter(
        springConstant: 0.08,  // Stronger springs
        repulsionConstant: 15000.0,
        maxIterations: 300,  // More iterations for precision
      );
    }

    // For highly connected diagrams, optimize for relationship visibility
    if (hasHighConnectivity) {
      return ForceDirectedLayoutAdapter(
        springConstant: 0.06,
        repulsionConstant: 30000.0,  // Stronger repulsion
        dampingFactor: 0.9,  // Higher damping
      );
    }

    // Default to a balanced force-directed layout
    return ForceDirectedLayoutAdapter();
  }

  /// Check if the diagram has boundaries or containment relationships
  bool _hasBoundariesOrContainment(List<ElementView> elementViews) {
    // Count elements that have a parent using the extension method
    int elementsWithParent = elementViews
        .where((element) => element.hasParent)
        .length;

    // Consider having boundaries if at least one element has a parent
    return elementsWithParent > 0;
  }

  /// Check if this appears to be a dynamic diagram based on relationship properties
  bool _isDynamicDiagram(List<RelationshipView> relationshipViews) {
    // Check for order values on relationships, which are common in dynamic diagrams
    int relationshipsWithOrder = relationshipViews
        .where((rel) => rel.order != null && rel.order!.toString().isNotEmpty)
        .length;

    // If at least half the relationships have order values, likely a dynamic diagram
    return relationshipsWithOrder > relationshipViews.length / 2;
  }

  /// Calculate the connectivity ratio (relationships per element)
  bool _hasHighConnectivityRatio(int elementCount, int relationshipCount) {
    if (elementCount <= 1) return false;
    
    // Calculate average relationships per element
    double connectivityRatio = relationshipCount / elementCount;
    
    // Consider high connectivity if more than 2 relationships per element on average
    return connectivityRatio > 2.0;
  }

  @override
  Rect getBoundingBox() {
    if (_selectedStrategy == null) {
      return Rect.zero;
    }
    return _selectedStrategy!.getBoundingBox();
  }

  @override
  String get name => 'Automatic Layout';

  @override
  String get description =>
      'Automatically selects the best layout algorithm based on diagram content';
}

/// Adapter class for ForceDirectedLayout to implement the LayoutStrategy interface
class ForceDirectedLayoutAdapter implements LayoutStrategy {
  final ForceDirectedLayout _layout;
  Rect _boundingBox = Rect.zero;

  ForceDirectedLayoutAdapter({
    double springConstant = 0.05,
    double repulsionConstant = 20000.0,
    double dampingFactor = 0.85,
    double boundaryForce = 1.5,
    int maxIterations = 500,
    double energyThreshold = 0.01,
  }) : _layout = ForceDirectedLayout(
          springConstant: springConstant,
          repulsionConstant: repulsionConstant,
          dampingFactor: dampingFactor,
          boundaryForce: boundaryForce,
          maxIterations: maxIterations,
          energyThreshold: energyThreshold,
        );

  @override
  Map<String, Offset> calculateLayout({
    required List<ElementView> elementViews,
    required List<RelationshipView> relationshipViews,
    required Size canvasSize,
    required Map<String, Size> elementSizes,
  }) {
    // Log information about the elements for debugging
    print('ForceDirectedLayoutAdapter: Processing ${elementViews.length} elements, ${relationshipViews.length} relationships');
    
    // Count elements with parents
    int elementsWithParent = elementViews.where((el) => el.hasParent).length;
    print('Elements with parents: $elementsWithParent');
    
    Map<String, Offset> positions = ForceDirectedLayoutOptimizer.multiPhaseLayout(
      layout: _layout,
      elementViews: elementViews,
      relationshipViews: relationshipViews,
      canvasSize: canvasSize,
      elementSizes: elementSizes,
    );

    // Calculate the bounding box for the result
    _calculateBoundingBox(positions, elementSizes);
    
    // Log information about calculated positions
    print('ForceDirectedLayoutAdapter: Calculated ${positions.length} positions');
    
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
  String get name => 'Force-Directed Layout';

  @override
  String get description =>
      'Physics-based layout using spring and repulsive forces';
}