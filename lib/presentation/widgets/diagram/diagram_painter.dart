import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart' hide Element;
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/presentation/layout/force_directed_layout.dart';
import 'package:flutter_structurizr/presentation/layout/layout_strategy.dart';
import 'package:flutter_structurizr/presentation/rendering/base_renderer.dart';
import 'package:flutter_structurizr/presentation/rendering/boundaries/boundary_renderer.dart';
import 'package:flutter_structurizr/presentation/rendering/elements/box_renderer.dart';
import 'package:flutter_structurizr/presentation/rendering/elements/component_renderer.dart';
import 'package:flutter_structurizr/presentation/rendering/elements/container_renderer.dart';
import 'package:flutter_structurizr/presentation/rendering/elements/person_renderer.dart';
import 'package:flutter_structurizr/presentation/rendering/relationships/relationship_renderer.dart';

/// A custom painter that renders Structurizr diagrams.
///
/// DiagramPainter orchestrates the rendering of elements, relationships, and
/// boundaries based on the current view and model. It supports features like
/// zooming, panning, selection, and highlighting of diagram elements.
class DiagramPainter extends CustomPainter {
  /// The view to render
  final View view;

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
  
  /// The bounding box for all elements
  Rect _boundingBox = Rect.zero;
  
  /// Constructor for DiagramPainter
  DiagramPainter({
    required this.view,
    required this.workspace,
    this.selectedId,
    this.hoveredId,
    this.zoomScale = 1.0,
    this.panOffset = Offset.zero,
    this.layoutStrategy,
    this.animationStep,
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
  
  /// Draw all boundary elements
  void _drawBoundaries(Canvas canvas) {
    // Group elements by parent ID to identify boundaries
    final Map<String, List<String>> boundaryElements = {};
    
    for (final elementView in view.elements) {
      final element = _findElementById(elementView.id);
      if (element == null) continue;
      
      if (element.parentId != null && view.containsElement(element.parentId!)) {
        boundaryElements.putIfAbsent(element.parentId!, () => []).add(element.id);
      }
    }
    
    // Draw each boundary
    for (final entry in boundaryElements.entries) {
      final parentId = entry.key;
      final childIds = entry.value;
      
      // Skip if parent doesn't have a rectangle
      if (!_elementRects.containsKey(parentId)) continue;
      
      final parent = _findElementById(parentId);
      if (parent == null) continue;
      
      final parentRect = _elementRects[parentId]!;
      
      // Find the style for the boundary
      final style = _getBoundaryStyle(parent);
      
      // Draw the boundary
      _boundaryRenderer.renderBoundary(
        canvas: canvas,
        element: parent,
        bounds: parentRect,
        style: style,
        childRects: childIds.map((id) => _elementRects[id]).whereType<Rect>().toList(),
        selected: parentId == selectedId,
        hovered: parentId == hoveredId,
      );
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
        orElse: () => const AnimationStep(order: 0),
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
      final updatedElementView = ElementView(
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
        selected: elementView.id == selectedId,
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
        orElse: () => const AnimationStep(order: 0),
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
        selected: relationshipView.id == selectedId,
      );
    }
  }
  
  /// Find an element by its ID
  Element? _findElementById(String id) {
    return workspace.model.getElementById(id);
  }
  
  /// Find a relationship by its ID
  Relationship? _findRelationshipById(String id) {
    return workspace.model.getAllRelationships().firstWhere(
      (r) => r.id == id,
      orElse: () => null,
    );
  }
  
  /// Get the appropriate renderer for an element based on its type
  BaseRenderer _getRendererForElement(Element element) {
    // Get renderer for the element's type, or default if not found
    return _elementRenderers[element.type] ?? _elementRenderers['Default']!;
  }
  
  /// Get the style for an element
  ElementStyle _getElementStyle(Element element) {
    // Try to get style from the workspace styles
    final style = workspace.views.configuration.styles.elements.firstWhere(
      (s) => _elementMatchesStyle(element, s),
      orElse: () => ElementStyle(),  // Default style if none found
    );
    
    return style;
  }
  
  /// Get the style for a boundary
  ElementStyle _getBoundaryStyle(Element element) {
    // Typically boundaries use the same style as their element
    return _getElementStyle(element);
  }
  
  /// Get the style for a relationship
  RelationshipStyle _getRelationshipStyle(Relationship relationship) {
    // Try to get style from the workspace styles
    final style = workspace.views.configuration.styles.relationships.firstWhere(
      (s) => _relationshipMatchesStyle(relationship, s),
      orElse: () => RelationshipStyle(),  // Default style if none found
    );
    
    return style;
  }
  
  /// Check if an element matches a style definition
  bool _elementMatchesStyle(Element element, ElementStyle style) {
    // Check if the element's type matches the style
    if (style.tag != null && element.tags.contains(style.tag)) {
      return true;
    }
    
    if (style.type != null && element.type == style.type) {
      return true;
    }
    
    return false;
  }
  
  /// Check if a relationship matches a style definition
  bool _relationshipMatchesStyle(Relationship relationship, RelationshipStyle style) {
    // Check if the relationship's tags match the style
    if (style.tag != null && relationship.tags.contains(style.tag)) {
      return true;
    }
    
    return false;
  }
  
  @override
  bool shouldRepaint(DiagramPainter oldDelegate) {
    // Determine if we need to repaint based on changed properties
    return oldDelegate.view != view ||
           oldDelegate.selectedId != selectedId ||
           oldDelegate.hoveredId != hoveredId ||
           oldDelegate.zoomScale != zoomScale ||
           oldDelegate.panOffset != panOffset ||
           oldDelegate.animationStep != animationStep;
  }
  
  /// Hit test to determine which element or relationship was clicked
  HitTestResult hitTest(Offset point) {
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
      final updatedElementView = ElementView(
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
        return HitTestResult(
          type: HitTestResultType.element,
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
        return HitTestResult(
          type: HitTestResultType.relationship,
          id: relationshipView.id,
          relationship: relationship,
        );
      }
    }
    
    // No hit
    return HitTestResult(type: HitTestResultType.none);
  }
  
  /// Gets the current bounding box of all elements
  Rect getBoundingBox() => _boundingBox;
  
  /// Gets the rectangle for a specific element by ID
  Rect? getElementRect(String elementId) => _elementRects[elementId];
  
  /// Gets all element rectangles
  Map<String, Rect> getAllElementRects() => Map.unmodifiable(_elementRects);
}

/// Types of hit test results
enum HitTestResultType {
  /// No element or relationship was hit
  none,
  
  /// An element was hit
  element,
  
  /// A relationship was hit
  relationship,
}

/// Result of a hit test
class HitTestResult {
  /// The type of hit test result
  final HitTestResultType type;
  
  /// The ID of the element or relationship that was hit
  final String? id;
  
  /// The element that was hit, if any
  final Element? element;
  
  /// The relationship that was hit, if any
  final Relationship? relationship;
  
  /// Creates a new hit test result
  HitTestResult({
    required this.type,
    this.id,
    this.element,
    this.relationship,
  });
}