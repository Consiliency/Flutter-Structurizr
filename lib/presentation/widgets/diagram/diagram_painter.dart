import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart' hide Container, Border, Element, View;
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/style/styles.dart' hide Border;
import 'package:flutter_structurizr/domain/view/view.dart' as structurizr_view;
import 'package:flutter_structurizr/domain/model/model.dart' hide Container, Element;
import 'package:flutter_structurizr/presentation/layout/force_directed_layout.dart';
import 'package:flutter_structurizr/presentation/layout/layout_strategy.dart';
import 'package:flutter_structurizr/presentation/rendering/base_renderer.dart';
import 'package:flutter_structurizr/presentation/rendering/boundaries/boundary_renderer.dart';
import 'package:flutter_structurizr/presentation/rendering/elements/box_renderer.dart';
import 'package:flutter_structurizr/presentation/rendering/elements/component_renderer.dart';
import 'package:flutter_structurizr/presentation/rendering/elements/container_renderer.dart';
import 'package:flutter_structurizr/presentation/rendering/elements/person_renderer.dart';
import 'package:flutter_structurizr/presentation/rendering/relationships/relationship_renderer.dart';
import 'package:flutter/material.dart' as flutter;
import 'package:flutter_structurizr/domain/model/model.dart' as structurizr_model;
import 'package:flutter_structurizr/domain/view/model_view.dart';

/// A custom painter that renders Structurizr diagrams.
///
/// DiagramPainter orchestrates the rendering of elements, relationships, and
/// boundaries based on the current view and model. It supports features like
/// zooming, panning, selection, and highlighting of diagram elements.
class DiagramPainter extends CustomPainter {
  /// The view to render
  final structurizr_view.View view;

  /// The workspace containing the model
  final Workspace workspace;

  /// The currently selected element or relationship ID, if any
  final String? selectedId;

  /// Set of IDs for multi-selected elements
  final Set<String>? selectedIds;

  /// The ID of the element being hovered over, if any
  final String? hoveredId;

  /// The current zoom scale
  final double zoomScale;

  /// The current pan offset
  final Offset panOffset;

  /// The layout strategy to use
  final LayoutStrategy? layoutStrategy;

  /// Animation step to display (for dynamic views)
  final int? animationStep;
  
  /// Whether to include names in element renderings
  final bool includeNames;
  
  /// Whether to include descriptions in element renderings
  final bool includeDescriptions;
  
  /// Whether to include relationship descriptions
  final bool includeRelationshipDescriptions;
  
  /// Whether to show animation step indicators
  final bool showAnimationStepIndicators;

  /// Map of element renderers by element type
  final Map<String, BaseRenderer> _elementRenderers = {};

  /// The relationship renderer
  final RelationshipRenderer _relationshipRenderer;

  /// The boundary renderer
  final BoundaryRenderer _boundaryRenderer;
  
  /// Map of element positions
  Map<String, Offset> _elementPositions = {};
  
  /// Map of element rectangles (bounds)
  Map<String, Rect> _elementRects = {};
  
  /// Map of relationship paths for hit testing
  Map<String, List<Offset>> _relationshipPaths = {};
  
  /// The bounding box for all elements
  Rect _boundingBox = Rect.zero;
  
  /// Constructor for DiagramPainter
  DiagramPainter({
    required this.view,
    required this.workspace,
    this.selectedId,
    this.selectedIds,
    this.hoveredId,
    this.zoomScale = 1.0,
    this.panOffset = Offset.zero,
    this.layoutStrategy,
    this.animationStep,
    this.includeNames = true,
    this.includeDescriptions = false,
    this.includeRelationshipDescriptions = true,
    this.showAnimationStepIndicators = false,
  }) : _relationshipRenderer = RelationshipRenderer(),
       _boundaryRenderer = BoundaryRenderer() {
    _initializeRenderers();
  }
  
  /// Initialize the element renderers for different element types
  void _initializeRenderers() {
    // Add standard renderers for common element types
    _elementRenderers['Person'] = PersonRenderer();
    _elementRenderers['SoftwareSystem'] = BoxRenderer();
    _elementRenderers['Container'] = ContainerRenderer();
    _elementRenderers['Component'] = ComponentRenderer();
    _elementRenderers['DeploymentNode'] = BoxRenderer();
    _elementRenderers['InfrastructureNode'] = BoxRenderer();
    
    // Default renderer for unknown element types
    _elementRenderers['Default'] = BoxRenderer();
  }
  
  @override
  void paint(Canvas canvas, Size size) {
    // Apply zoom and pan transformations
    canvas.save();
    canvas.translate(panOffset.dx, panOffset.dy);
    canvas.scale(zoomScale);
    
    // Calculate layout if not already done or if we need to recalculate
    _calculateLayout(size);
    
    // Draw in the correct order: boundaries first, then elements, then relationships
    _drawBoundaries(canvas);
    _drawElements(canvas);
    _drawRelationships(canvas);
    
    // Restore canvas state
    canvas.restore();
  }
  
  /// Calculate the layout for elements in the view
  void _calculateLayout(Size size) {
    // Skip if we already have positions and they are valid
    if (_elementPositions.isNotEmpty && _elementPositions.length == view.elements.length) {
      // Layout already calculated
      return;
    }
    
    // Calculate sizes for each element
    final elementSizes = <String, Size>{};
    for (final elementView in view.elements) {
      final element = _findElementById(elementView.id);
      if (element == null) continue;
      
      final style = _getElementStyle(element);
      final renderer = _getRendererForElement(element);
      
      // Calculate the bounds based on the element, its view, and style
      final rect = renderer.calculateElementBounds(
        element: element,
        elementView: elementView,
        style: style,
      );
      
      elementSizes[elementView.id] = Size(rect.width, rect.height);
    }
    
    // If we have a layout strategy, use it to calculate positions
    if (layoutStrategy != null) {
      _elementPositions = layoutStrategy!.calculateLayout(
        elementViews: view.elements,
        relationshipViews: view.relationships,
        canvasSize: size,
        elementSizes: elementSizes,
      );
      
      _boundingBox = layoutStrategy!.getBoundingBox();
    } else if (view.automaticLayout != null) {
      // Use force-directed layout as fallback
      final layout = ForceDirectedLayout();
      _elementPositions = layout.calculateLayout(
        elementViews: view.elements,
        relationshipViews: view.relationships,
        canvasSize: size,
        elementSizes: elementSizes,
      );
      
      _boundingBox = layout.calculateBoundingBox();
    } else {
      // Manual layout - use positions from the view
      _elementPositions = {};
      for (final elementView in view.elements) {
        if (elementView.x != null && elementView.y != null) {
          _elementPositions[elementView.id] = Offset(
            elementView.x!.toDouble(),
            elementView.y!.toDouble(),
          );
        } else {
          // Default position in the center if not specified
          _elementPositions[elementView.id] = Offset(
            size.width / 2 - (elementSizes[elementView.id]?.width ?? 100) / 2,
            size.height / 2 - (elementSizes[elementView.id]?.height ?? 100) / 2,
          );
        }
      }
      
      // Calculate bounding box for manual layout
      _calculateBoundingBox(elementSizes);
    }
    
    // Update the element rectangles based on calculated positions
    _updateElementRects(elementSizes);
  }
  
  /// Calculate the bounding box containing all elements
  void _calculateBoundingBox(Map<String, Size> elementSizes) {
    if (_elementPositions.isEmpty) {
      _boundingBox = Rect.zero;
      return;
    }
    
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;
    
    for (final entry in _elementPositions.entries) {
      final id = entry.key;
      final position = entry.value;
      final size = elementSizes[id] ?? Size(100, 100);
      
      minX = math.min(minX, position.dx);
      minY = math.min(minY, position.dy);
      maxX = math.max(maxX, position.dx + size.width);
      maxY = math.max(maxY, position.dy + size.height);
    }
    
    _boundingBox = Rect.fromLTRB(minX, minY, maxX, maxY);
  }
  
  /// Update the element rectangles based on positions and sizes
  void _updateElementRects(Map<String, Size> elementSizes) {
    _elementRects = {};
    
    for (final entry in _elementPositions.entries) {
      final id = entry.key;
      final position = entry.value;
      final size = elementSizes[id] ?? Size(100, 100);
      
      _elementRects[id] = Rect.fromLTWH(
        position.dx,
        position.dy,
        size.width,
        size.height,
      );
    }
  }
  
  /// Draw all boundary elements with proper nesting
  void _drawBoundaries(Canvas canvas) {
    // Group elements by parent ID to identify boundaries
    final Map<String, List<String>> boundaryElements = {};
    
    // Identify parent-child relationships
    for (final elementView in view.elements) {
      final element = _findElementById(elementView.id);
      if (element == null) continue;
      
      if (element.parentId != null && view.containsElement(element.parentId!)) {
        boundaryElements.putIfAbsent(element.parentId!, () => []).add(element.id);
      }
    }
    
    // Build a hierarchy of boundaries to know which to draw first
    final rootBoundaries = _findRootBoundaries(boundaryElements);
    
    // Draw boundaries from root (top level) to leaf (most nested)
    _drawNestedBoundaries(canvas, rootBoundaries, boundaryElements);
  }
  
  /// Find root boundaries (those that have no parents in the boundary map)
  List<String> _findRootBoundaries(Map<String, List<String>> boundaryElements) {
    // Start with all parent IDs
    final Set<String> parentIds = boundaryElements.keys.toSet();
    
    // Remove any that are children of other boundaries
    for (final childIds in boundaryElements.values) {
      for (final childId in childIds) {
        if (parentIds.contains(childId)) {
          // This child is itself a parent, so remove it from root candidates
          parentIds.remove(childId);
        }
      }
    }
    
    return parentIds.toList();
  }

  /// Draw boundaries recursively, starting with outermost (root) boundaries
  void _drawNestedBoundaries(
    Canvas canvas, 
    List<String> parentIds, 
    Map<String, List<String>> boundaryElements
  ) {
    // Sort parent IDs to ensure consistent drawing order
    parentIds.sort();
    
    // Process each boundary in sorted order
    for (final parentId in parentIds) {
      final childIds = boundaryElements[parentId] ?? [];
      
      // Skip if parent doesn't have a rectangle
      if (!_elementRects.containsKey(parentId)) continue;
      
      final parent = _findElementById(parentId);
      if (parent == null) continue;
      
      final parentRect = _elementRects[parentId]!;
      
      // Find the style for the boundary
      final style = _getBoundaryStyle(parent);
      
      // Get rectangles for the direct children
      final childRects = childIds
          .map((id) => _elementRects[id])
          .whereType<Rect>()
          .toList();
      
      // Draw the boundary
      _boundaryRenderer.renderBoundary(
        canvas: canvas,
        element: parent,
        bounds: parentRect,
        style: style,
        childRects: childRects,
        selected: parentId == selectedId,
        hovered: parentId == hoveredId,
      );
      
      // Recursively draw any child boundaries
      final childBoundaryIds = childIds.where((id) => boundaryElements.containsKey(id)).toList();
      if (childBoundaryIds.isNotEmpty) {
        _drawNestedBoundaries(canvas, childBoundaryIds, boundaryElements);
      }
    }
  }
  
  /// Draw all elements in the view
  void _drawElements(Canvas canvas) {
    // Filter elements based on animation step if one is specified
    final elementsToRender = view.elements.where((element) {
      if (animationStep == null || view.animations.isEmpty) {
        return true;
      }
      
      // Find the animation step
      final step = view.animations.firstWhere(
        (a) => a.order == animationStep,
        orElse: () => ModelAnimationStep(order: -1, elements: const [], relationships: const []),
      );
      
      // Check if element is included in this step
      return step.elements.contains(element.id);
    }).toList();
    
    // Draw each element
    for (final elementView in elementsToRender) {
      final element = _findElementById(elementView.id);
      if (element == null) continue;
      
      // Skip if the element doesn't have a position
      if (!_elementPositions.containsKey(elementView.id)) continue;
      
      final position = _elementPositions[elementView.id]!;
      
      // Update the element view with its position and size
      final updatedElementView = structurizr_view.ElementView(
        id: elementView.id,
        x: position.dx.round(),
        y: position.dy.round(),
        width: elementView.width ?? _elementRects[elementView.id]?.width.round(),
        height: elementView.height ?? _elementRects[elementView.id]?.height.round(),
      );
      
      // Get the style and renderer for this element
      final style = _getElementStyle(element);
      final renderer = _getRendererForElement(element);
      
      // Draw the element
      renderer.renderElement(
        canvas: canvas,
        element: element,
        elementView: updatedElementView,
        style: style,
        selected: elementView.id == selectedId || (selectedIds?.contains(elementView.id) ?? false),
        hovered: elementView.id == hoveredId,
        includeNames: includeNames,
        includeDescriptions: includeDescriptions,
      );
    }
  }
  
  /// Draw all relationships in the view
  void _drawRelationships(Canvas canvas) {
    // Filter relationships based on animation step if one is specified
    final relationshipsToRender = view.relationships.where((relationship) {
      if (animationStep == null || view.animations.isEmpty) {
        return true;
      }
      
      // Find the animation step
      final step = view.animations.firstWhere(
        (a) => a.order == animationStep,
        orElse: () => ModelAnimationStep(order: -1, elements: const [], relationships: const []),
      );
      
      // Check if relationship is included in this step
      return step.relationships.contains(relationship.id);
    }).toList();
    
    // Sort relationships by order if specified (for dynamic views)
    relationshipsToRender.sort((a, b) {
      if (a.order == null || b.order == null) return 0;
      return int.parse(a.order!) - int.parse(b.order!);
    });
    
    // Draw each relationship
    for (final relationshipView in relationshipsToRender) {
      final relationship = _findRelationshipById(relationshipView.id);
      if (relationship == null) continue;
      
      // Find source and target elements
      final sourceRect = _elementRects[relationship.sourceId];
      final targetRect = _elementRects[relationship.destinationId];
      
      // Skip if source or target is not visible
      if (sourceRect == null || targetRect == null) continue;
      
      // Get the style for this relationship
      final style = _getRelationshipStyle(relationship);
      
      // Draw the relationship
      _relationshipRenderer.renderRelationship(
        canvas: canvas,
        relationship: relationship,
        relationshipView: relationshipView,
        style: style,
        sourceRect: sourceRect,
        targetRect: targetRect,
        selected: relationshipView.id == selectedId || (selectedIds?.contains(relationshipView.id) ?? false),
        hovered: relationshipView.id == hoveredId,
        includeDescription: includeRelationshipDescriptions,
      );
      
      // Store relationship path for hit testing
      _relationshipPaths[relationshipView.id] = [
        sourceRect.center,
        targetRect.center,
      ];
    }
  }
  
  /// Find an element by its ID
  Element? _findElementById(String id) {
    return workspace.model.getElementById(id);
  }
  
  /// Find a relationship by its ID
  Relationship? _findRelationshipById(String id) {
    try {
      return workspace.model.getAllRelationships().firstWhere(
        (r) => r.id == id,
      );
    } catch (e) {
      return null;
    }
  }
  
  /// Get the appropriate renderer for an element based on its type
  BaseRenderer _getRendererForElement(Element element) {
    // Get renderer for the element's type, or default if not found
    return _elementRenderers[element.type] ?? _elementRenderers['Default']!;
  }
  
  /// Get the style for an element
  ElementStyle _getElementStyle(Element element) {
    // Try to get style from the workspace styles
    if (workspace.styles != null) {
      final foundStyle = workspace.styles.findElementStyle(element);
      if (foundStyle != null) {
        return foundStyle;
      }
    }
    
    // Default style if none found
    return const ElementStyle();
  }
  
  /// Get the style for a boundary
  ElementStyle _getBoundaryStyle(Element element) {
    // Typically boundaries use the same style as their element
    return _getElementStyle(element);
  }
  
  /// Get the style for a relationship
  RelationshipStyle _getRelationshipStyle(Relationship relationship) {
    // Try to get style from the workspace styles
    if (workspace.styles != null) {
      final foundStyle = workspace.styles.findRelationshipStyle(relationship);
      if (foundStyle != null) {
        return foundStyle;
      }
    }
    
    // Default style if none found
    return const RelationshipStyle();
  }
  
  // These methods are no longer used as we're now using the built-in
  // findElementStyle and findRelationshipStyle methods from the Styles class
  
  @override
  bool shouldRepaint(DiagramPainter oldDelegate) {
    // Determine if we need to repaint based on changed properties
    return oldDelegate.view != view ||
           oldDelegate.selectedId != selectedId ||
           oldDelegate.hoveredId != hoveredId ||
           oldDelegate.zoomScale != zoomScale ||
           oldDelegate.panOffset != panOffset ||
           oldDelegate.animationStep != animationStep ||
           oldDelegate.includeNames != includeNames ||
           oldDelegate.includeDescriptions != includeDescriptions ||
           oldDelegate.includeRelationshipDescriptions != includeRelationshipDescriptions ||
           oldDelegate.showAnimationStepIndicators != showAnimationStepIndicators;
  }
  
  /// Hit test to determine which element or relationship was clicked
  bool? hitTest(Offset position) {
    // Delegate to our custom hit test implementation
    final result = _hitTest(position);
    return result.type != DiagramHitTestResultType.none;
  }
  
  /// Custom hit test to determine which element or relationship was clicked
  DiagramHitTestResult _hitTest(Offset point) {
    // Adjust point for pan and zoom
    final adjustedPoint = (point - panOffset) / zoomScale;
    
    // Check elements first (elements are on top of relationships)
    for (final elementView in view.elements) {
      final element = _findElementById(elementView.id);
      if (element == null) continue;
      
      final rect = _elementRects[elementView.id];
      if (rect == null) continue;
      
      final style = _getElementStyle(element);
      final renderer = _getRendererForElement(element);
      
      // Update element view with current position and size
      final updatedElementView = structurizr_view.ElementView(
        id: elementView.id,
        x: rect.left.round(),
        y: rect.top.round(),
        width: rect.width.round(),
        height: rect.height.round(),
      );
      
      // Perform hit testing with the renderer
      if (renderer.hitTestElement(
        point: adjustedPoint,
        element: element,
        elementView: updatedElementView,
        style: style,
      )) {
        return DiagramHitTestResult(
          type: DiagramHitTestResultType.element,
          id: elementView.id,
          element: element,
        );
      }
    }
    
    // Then check relationships
    for (final relationshipView in view.relationships) {
      final relationship = _findRelationshipById(relationshipView.id);
      if (relationship == null) continue;
      
      final sourceRect = _elementRects[relationship.sourceId];
      final targetRect = _elementRects[relationship.destinationId];
      
      if (sourceRect == null || targetRect == null) continue;
      
      final style = _getRelationshipStyle(relationship);
      
      // Perform hit testing with the relationship renderer
      if (_relationshipRenderer.hitTestRelationship(
        point: adjustedPoint,
        relationship: relationship,
        relationshipView: relationshipView,
        style: style,
        sourceRect: sourceRect,
        targetRect: targetRect,
      )) {
        return DiagramHitTestResult(
          type: DiagramHitTestResultType.relationship,
          id: relationshipView.id,
          relationship: relationship,
        );
      }
    }
    
    // No hit
    return DiagramHitTestResult(type: DiagramHitTestResultType.none);
  }
  
  /// Public method to expose custom hit testing
  DiagramHitTestResult performHitTest(Offset point) {
    return _hitTest(point);
  }
  
  /// Gets the current bounding box of all elements
  Rect getBoundingBox() => _boundingBox;
  
  /// Gets the rectangle for a specific element by ID
  Rect? getElementRect(String elementId) => _elementRects[elementId];
  
  /// Gets all element rectangles
  Map<String, Rect> getAllElementRects() => Map.unmodifiable(_elementRects);
  
  /// Gets all relationship paths
  Map<String, List<Offset>> getAllRelationshipPaths() => Map.unmodifiable(_relationshipPaths);
  
  /// Gets elements that intersect with the given rectangle
  Set<String> getElementsInRect(Rect rect) {
    final result = <String>{};
    
    for (final entry in _elementRects.entries) {
      if (entry.value.overlaps(rect)) {
        result.add(entry.key);
      }
    }
    
    return result;
  }
  
  /// Gets relationships that intersect with the given rectangle
  Set<String> getRelationshipsInRect(Rect rect) {
    final result = <String>{};
    
    for (final entry in _relationshipPaths.entries) {
      final relationshipId = entry.key;
      final path = entry.value;
      
      if (path.length < 2) continue;
      
      // Check if either endpoint is inside the rect
      if (rect.contains(path.first) || rect.contains(path.last)) {
        result.add(relationshipId);
        continue;
      }
      
      // Check if the line segment intersects with any edge of the rect
      if (_lineIntersectsRect(path.first, path.last, rect)) {
        result.add(relationshipId);
      }
    }
    
    return result;
  }
  
  /// Checks if a line segment intersects with a rectangle
  bool _lineIntersectsRect(Offset p1, Offset p2, Rect rect) {
    // Check intersection with all 4 sides of the rectangle
    return _lineIntersectsLine(p1, p2, rect.topLeft, rect.topRight) ||
           _lineIntersectsLine(p1, p2, rect.topRight, rect.bottomRight) ||
           _lineIntersectsLine(p1, p2, rect.bottomRight, rect.bottomLeft) ||
           _lineIntersectsLine(p1, p2, rect.bottomLeft, rect.topLeft);
  }
  
  /// Line segment intersection test
  bool _lineIntersectsLine(Offset a, Offset b, Offset c, Offset d) {
    // Calculate the cross products
    final ccw1 = _ccw(a, c, d);
    final ccw2 = _ccw(b, c, d);
    final ccw3 = _ccw(a, b, c);
    final ccw4 = _ccw(a, b, d);
    
    // Check if the line segments intersect
    return (ccw1 * ccw2 <= 0) && (ccw3 * ccw4 <= 0);
  }
  
  /// Counter-clockwise test for three points
  int _ccw(Offset a, Offset b, Offset c) {
    final val = (b.dy - a.dy) * (c.dx - b.dx) - (b.dx - a.dx) * (c.dy - b.dy);
    if (val == 0) return 0;      // Collinear
    return val > 0 ? 1 : -1;     // Clockwise or Counterclockwise
  }
}

/// Types of hit test results
enum DiagramHitTestResultType {
  /// No element or relationship was hit
  none,
  
  /// An element was hit
  element,
  
  /// A relationship was hit
  relationship,
}

/// Result of a hit test
class DiagramHitTestResult {
  /// The type of hit test result
  final DiagramHitTestResultType type;
  
  /// The ID of the element or relationship that was hit
  final String? id;
  
  /// The element that was hit, if any
  final Element? element;
  
  /// The relationship that was hit, if any
  final Relationship? relationship;
  
  /// Creates a new hit test result
  DiagramHitTestResult({
    required this.type,
    this.id,
    this.element,
    this.relationship,
  });
}