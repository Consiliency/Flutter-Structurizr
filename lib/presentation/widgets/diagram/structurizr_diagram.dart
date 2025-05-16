import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide Container, Border, Element, View;
import 'package:flutter/services.dart';
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/style/styles.dart' hide Border;
import 'package:flutter_structurizr/domain/view/model_view.dart';
import 'package:flutter_structurizr/domain/view/view.dart' as s_view;
import 'package:flutter_structurizr/domain/view/view.dart' hide View;
import 'package:flutter_structurizr/presentation/layout/force_directed_layout.dart';
import 'package:flutter_structurizr/presentation/layout/automatic_layout.dart';
import 'package:flutter_structurizr/presentation/layout/layout_strategy.dart';
import 'package:flutter_structurizr/presentation/rendering/base_renderer.dart';
import 'package:flutter_structurizr/presentation/widgets/diagram/diagram_painter.dart' as diagram;
import 'package:flutter_structurizr/presentation/widgets/diagram/lasso_selection.dart';
import 'package:flutter_structurizr/domain/model/model.dart' hide Container, Element;
import 'package:flutter_structurizr/domain/model/model.dart' as structurizr_model;
import 'package:flutter_structurizr/presentation/widgets/diagram/diagram_painter.dart' show DiagramHitTestResult, DiagramHitTestResultType;
import 'package:flutter/rendering.dart';

/// Modes for selection operation
enum SelectionMode {
  /// Normal selection mode (single click)
  normal,
  
  /// Lasso selection mode (drawing lasso)
  lasso,
  
  /// Dragging mode (moving selected elements)
  dragging,
}

/// A custom painter for drawing a grid in the background
class _GridPainter extends CustomPainter {
  /// The current zoom scale
  final double zoomScale;
  
  /// The current pan offset
  final Offset panOffset;
  
  /// The spacing between grid lines
  final double spacing;
  
  /// The color of the grid lines
  final Color color;
  
  /// Creates a new grid painter
  const _GridPainter({
    required this.zoomScale,
    required this.panOffset,
    required this.spacing,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;
    
    // Adjust grid spacing based on zoom
    final adjustedSpacing = spacing * zoomScale;
    
    // Calculate the visible area
    final visibleRect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // Calculate the grid offset
    final offsetX = panOffset.dx % adjustedSpacing;
    final offsetY = panOffset.dy % adjustedSpacing;
    
    // Calculate the number of vertical and horizontal lines needed
    final horizontalLineCount = (size.height / adjustedSpacing).ceil() + 1;
    final verticalLineCount = (size.width / adjustedSpacing).ceil() + 1;
    
    // Draw horizontal lines
    for (var i = 0; i < horizontalLineCount; i++) {
      final y = i * adjustedSpacing + offsetY;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
    
    // Draw vertical lines
    for (var i = 0; i < verticalLineCount; i++) {
      final x = i * adjustedSpacing + offsetX;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(_GridPainter oldDelegate) {
    return oldDelegate.zoomScale != zoomScale ||
           oldDelegate.panOffset != panOffset ||
           oldDelegate.spacing != spacing ||
           oldDelegate.color != color;
  }
}

/// A custom painter for drawing the lasso selection
class _LassoPainter extends CustomPainter {
  /// The lasso selection
  final LassoSelection lassoSelection;
  
  /// The color of the lasso border
  final Color borderColor;
  
  /// The color of the lasso fill
  final Color fillColor;
  
  /// The width of the lasso border
  final double borderWidth;
  
  /// Whether to apply shadow effects for better visual depth
  final bool enableShadows;
  
  /// Whether to apply glow effects for active selection
  final bool enableGlow;
  
  /// Creates a new lasso painter
  const _LassoPainter({
    required this.lassoSelection,
    required this.borderColor,
    required this.fillColor,
    required this.borderWidth,
    this.enableShadows = true,
    this.enableGlow = true,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Create paints for the border and fill
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    
    // Apply shadow effect for better depth perception if enabled
    if (enableShadows && lassoSelection.isComplete) {
      canvas.drawShadow(
        lassoSelection.path, 
        Colors.black.withOpacity(0.3), 
        3.0, 
        true
      );
    }
    
    // Apply glow effect for active selection if enabled
    if (enableGlow && lassoSelection.isActive) {
      final glowPaint = Paint()
        ..color = borderColor.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth + 2.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
      
      canvas.drawPath(lassoSelection.path, glowPaint);
    }
    
    // Draw the lasso fill first, then the border
    canvas.drawPath(lassoSelection.path, fillPaint);
    canvas.drawPath(lassoSelection.path, borderPaint);
    
    // Draw dots at corners for visual feedback during drawing
    if (lassoSelection.isActive) {
      final dotPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.fill;
      
      // Get points from the lasso selection
      final points = lassoSelection.getPoints();
      
      // Draw dots at each point (max 20 points to avoid performance issues)
      final step = points.length < 20 ? 1 : points.length ~/ 20;
      for (int i = 0; i < points.length; i += step) {
        canvas.drawCircle(points[i], borderWidth / 2, dotPaint);
      }
    }
  }
  
  @override
  bool shouldRepaint(_LassoPainter oldDelegate) {
    return oldDelegate.lassoSelection != lassoSelection ||
           oldDelegate.borderColor != borderColor ||
           oldDelegate.fillColor != fillColor ||
           oldDelegate.borderWidth != borderWidth ||
           oldDelegate.enableShadows != enableShadows ||
           oldDelegate.enableGlow != enableGlow;
  }
}

/// A composite painter that combines multiple painters
class _CompositePainter extends CustomPainter {
  /// The grid painter (optional)
  final _GridPainter? gridPainter;
  
  /// The lasso painter (optional)
  final _LassoPainter? lassoPainter;
  
  /// Creates a new composite painter
  const _CompositePainter({
    this.gridPainter,
    this.lassoPainter,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Paint in order: grid first, then lasso
    gridPainter?.paint(canvas, size);
    lassoPainter?.paint(canvas, size);
  }
  
  @override
  bool shouldRepaint(_CompositePainter oldDelegate) {
    return oldDelegate.gridPainter != gridPainter ||
           oldDelegate.lassoPainter != lassoPainter;
  }
}

/// Configuration options for the StructurizrDiagram widget
class StructurizrDiagramConfig {
  /// Whether the diagram is editable
  final bool isEditable;
  
  /// Whether to enable pan and zoom
  final bool enablePanAndZoom;
  
  /// Whether to show a grid in the background
  final bool showGrid;
  
  /// Initial zoom scale
  final double initialZoomScale;
  
  /// Minimum zoom scale
  final double minZoomScale;
  
  /// Maximum zoom scale
  final double maxZoomScale;
  
  /// Whether to fit the diagram to the screen on initial render
  final bool fitToScreen;
  
  /// Whether to center the diagram on start
  final bool centerOnStart;
  
  /// Whether to show element names
  final bool showElementNames;
  
  /// Whether to show element descriptions
  final bool showElementDescriptions;
  
  /// Whether to show relationship descriptions
  final bool showRelationshipDescriptions;
  
  /// Whether to render animation step indicators
  final bool showAnimationStepIndicators;
  
  /// Creates configuration for the diagram
  const StructurizrDiagramConfig({
    this.isEditable = false,
    this.enablePanAndZoom = true,
    this.showGrid = true,
    this.initialZoomScale = 1.0,
    this.minZoomScale = 0.1,
    this.maxZoomScale = 3.0,
    this.fitToScreen = false,
    this.centerOnStart = false,
    this.showElementNames = true,
    this.showElementDescriptions = false,
    this.showRelationshipDescriptions = true,
    this.showAnimationStepIndicators = false,
  });
  
  /// Creates a copy of this configuration with the given fields replaced with the new values
  StructurizrDiagramConfig copyWith({
    bool? isEditable,
    bool? enablePanAndZoom,
    bool? showGrid,
    double? initialZoomScale,
    double? minZoomScale,
    double? maxZoomScale,
    bool? fitToScreen,
    bool? centerOnStart,
    bool? showElementNames,
    bool? showElementDescriptions,
    bool? showRelationshipDescriptions,
    bool? showAnimationStepIndicators,
  }) {
    return StructurizrDiagramConfig(
      isEditable: isEditable ?? this.isEditable,
      enablePanAndZoom: enablePanAndZoom ?? this.enablePanAndZoom,
      showGrid: showGrid ?? this.showGrid,
      initialZoomScale: initialZoomScale ?? this.initialZoomScale,
      minZoomScale: minZoomScale ?? this.minZoomScale,
      maxZoomScale: maxZoomScale ?? this.maxZoomScale,
      fitToScreen: fitToScreen ?? this.fitToScreen,
      centerOnStart: centerOnStart ?? this.centerOnStart,
      showElementNames: showElementNames ?? this.showElementNames,
      showElementDescriptions: showElementDescriptions ?? this.showElementDescriptions,
      showRelationshipDescriptions: showRelationshipDescriptions ?? this.showRelationshipDescriptions,
      showAnimationStepIndicators: showAnimationStepIndicators ?? this.showAnimationStepIndicators,
    );
  }
}

/// A widget that displays a Structurizr diagram.
///
/// This widget renders a diagram from a specified workspace and view, handling
/// user interactions like selection, zooming, and panning. It supports both
/// interactive and static views, with configurable behavior for different use cases.
class StructurizrDiagram extends StatefulWidget {
  /// The workspace containing the diagram data
  final Workspace workspace;
  
  /// The view to render
  final View view;
  
  /// Callback for when an element is selected
  final Function(String id, Element element)? onElementSelected;
  
  /// Callback for when a relationship is selected
  final Function(String id, Relationship relationship)? onRelationshipSelected;
  
  /// Callback for when selection is cleared
  final Function()? onSelectionCleared;
  
  /// Callback for when an element is hovered over
  final Function(String id, Element element)? onElementHovered;
  
  /// Callback for when multiple elements are selected
  final Function(Set<String> elementIds, Set<String> relationshipIds)? onMultipleItemsSelected;
  
  /// Callback for when elements are moved
  final Function(Map<String, Offset> newPositions)? onElementsMoved;
  
  /// The animation step to display (for dynamic views)
  final int? animationStep;
  
  /// The layout strategy to use
  final LayoutStrategy? layoutStrategy;
  
  /// Configuration options for the diagram
  final StructurizrDiagramConfig config;
  
  /// Creates a new Structurizr diagram.
  const StructurizrDiagram({
    Key? key,
    required this.workspace,
    required this.view,
    this.onElementSelected,
    this.onRelationshipSelected,
    this.onSelectionCleared,
    this.onElementHovered,
    this.onMultipleItemsSelected,
    this.onElementsMoved,
    this.animationStep,
    this.layoutStrategy,
    this.config = const StructurizrDiagramConfig(),
  }) : super(key: key);
  
  /// Legacy constructor for backward compatibility
  @Deprecated('Use the constructor with config parameter instead')
  factory StructurizrDiagram.legacy({
    Key? key,
    required Workspace workspace,
    required View view,
    Function(String id, Element element)? onElementSelected,
    Function(String id, Relationship relationship)? onRelationshipSelected,
    Function()? onSelectionCleared,
    Function(String id, Element element)? onElementHovered,
    Function(Set<String> elementIds, Set<String> relationshipIds)? onMultipleItemsSelected,
    Function(Map<String, Offset> newPositions)? onElementsMoved,
    bool isEditable = false,
    bool enablePanAndZoom = true,
    bool showGrid = true,
    double initialZoomScale = 1.0,
    double minZoomScale = 0.1,
    double maxZoomScale = 3.0,
    int? animationStep,
    LayoutStrategy? layoutStrategy,
  }) {
    return StructurizrDiagram(
      key: key,
      workspace: workspace,
      view: view,
      onElementSelected: onElementSelected,
      onRelationshipSelected: onRelationshipSelected,
      onSelectionCleared: onSelectionCleared,
      onElementHovered: onElementHovered,
      onMultipleItemsSelected: onMultipleItemsSelected,
      onElementsMoved: onElementsMoved,
      animationStep: animationStep,
      layoutStrategy: layoutStrategy,
      config: StructurizrDiagramConfig(
        isEditable: isEditable,
        enablePanAndZoom: enablePanAndZoom,
        showGrid: showGrid,
        initialZoomScale: initialZoomScale,
        minZoomScale: minZoomScale,
        maxZoomScale: maxZoomScale,
      ),
    );
  }
  
  @override
  StructurizrDiagramState createState() => StructurizrDiagramState();
}

/// The state for the [StructurizrDiagram] widget.
///
/// This class manages the interaction and rendering state for the diagram,
/// handling gestures for panning, zooming, and selection, as well as
/// rendering the diagram using a custom painter.
class StructurizrDiagramState extends State<StructurizrDiagram> with SingleTickerProviderStateMixin {
  /// The current zoom scale of the diagram
  double _zoomScale = 1.0;
  
  /// The current pan offset of the diagram
  Offset _panOffset = Offset.zero;
  
  /// The currently selected element or relationship ID
  String? _selectedId;
  
  /// Set of IDs for multi-selected elements
  final Set<String> _selectedIds = {};
  
  /// The currently hovered element ID
  String? _hoveredId;
  
  /// The lasso selection tool
  final LassoSelection _lassoSelection = LassoSelection();
  
  /// The layout strategy to use
  LayoutStrategy? _layoutStrategy;
  
  /// The animation controller for smooth transitions
  late AnimationController _animationController;
  
  /// Key bindings for modifier keys
  bool _isCtrlPressed = false;
  bool _isShiftPressed = false;
  
  /// Last pointer position for drag operations
  Offset? _lastPointerPosition;
  
  /// Map of original positions for multi-element drag
  Map<String, Offset> _originalElementPositions = {};
  
  /// Map of current positions for multi-element drag
  Map<String, Offset> _currentElementPositions = {};
  
  /// Mode of selection operation
  SelectionMode _selectionMode = SelectionMode.normal;
  
  /// The animation for zoom transitions
  Animation<double>? _zoomAnimation;
  
  /// The animation for pan transitions
  Animation<Offset>? _panAnimation;
  
  @override
  void initState() {
    super.initState();
    _zoomScale = widget.config.initialZoomScale;
    _layoutStrategy = widget.layoutStrategy ?? ForceDirectedLayoutAdapter();
    
    // Initialize animation controller for smooth transitions
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _animationController.addListener(() {
      if (_zoomAnimation != null || _panAnimation != null) {
        setState(() {
          if (_zoomAnimation != null) {
            _zoomScale = _zoomAnimation!.value;
          }
          if (_panAnimation != null) {
            _panOffset = _panAnimation!.value;
          }
        });
      }
    });
    
    // Apply initial view settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.config.fitToScreen) {
        fitToScreen();
      } else if (widget.config.centerOnStart) {
        // Center the diagram without changing zoom level
        _centerDiagram();
      }
    });
  }
  
  /// Centers the diagram on the screen without changing zoom level
  void _centerDiagram() {
    // Get the diagram painter to access content bounds
    final painter = diagram.DiagramPainter(
      view: widget.view,
      workspace: widget.workspace,
    );
    
    // Get the bounding box of all elements
    final boundingBox = painter.getBoundingBox();
    if (boundingBox == Rect.zero) return;
    
    // Get the current viewport size
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    
    // Calculate the center offset
    final targetPanOffset = Offset(
      size.width / 2 - boundingBox.center.dx * _zoomScale,
      size.height / 2 - boundingBox.center.dy * _zoomScale,
    );
    
    // Animate to the center position
    setState(() {
      _panOffset = targetPanOffset;
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  void didUpdateWidget(StructurizrDiagram oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update layout strategy if changed
    if (widget.layoutStrategy != oldWidget.layoutStrategy) {
      _layoutStrategy = widget.layoutStrategy ?? ForceDirectedLayoutAdapter();
    }
    
    // Update view if changed
    if (widget.view != oldWidget.view) {
      // Clear selection when view changes
      _selectedId = null;
      _hoveredId = null;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: _handleHover,
      child: GestureDetector(
        onScaleStart: widget.config.enablePanAndZoom ? _handleScaleStart : null,
        onScaleUpdate: widget.config.enablePanAndZoom ? _handleScaleUpdate : null,
        onScaleEnd: widget.config.enablePanAndZoom ? _handleScaleEnd : null,
        onTapDown: _handleTapDown,
        onPanStart: widget.config.isEditable ? _handlePanStart : null,
        onPanUpdate: widget.config.isEditable ? _handlePanUpdate : null,
        onPanEnd: widget.config.isEditable ? _handlePanEnd : null,
        onSecondaryTapDown: _handleSecondaryTapDown,
        child: KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: _handleKeyEvent,
          child: MouseRegion(
            cursor: _getCursorForMode(),
            child: Stack(
              children: [
                // Background grid (optional)
                if (widget.config.showGrid)
                  CustomPaint(
                    painter: _GridPainter(
                      zoomScale: _zoomScale,
                      panOffset: _panOffset,
                      spacing: 20.0,
                      color: Colors.grey.withOpacity(0.2),
                    ),
                    size: Size.infinite,
                  ),
                
                // Main diagram
                CustomPaint(
                  painter: diagram.DiagramPainter(
                    view: widget.view,
                    workspace: widget.workspace,
                    selectedId: _selectedId,
                    hoveredId: _hoveredId,
                    zoomScale: _zoomScale,
                    panOffset: _panOffset,
                    layoutStrategy: _layoutStrategy,
                    animationStep: widget.animationStep,
                    includeNames: widget.config.showElementNames,
                    includeDescriptions: widget.config.showElementDescriptions,
                    includeRelationshipDescriptions: widget.config.showRelationshipDescriptions,
                    showAnimationStepIndicators: widget.config.showAnimationStepIndicators,
                  ),
                  size: Size.infinite,
                ),
                
                // Lasso selection (when active)
                if (_lassoSelection.isActive || _lassoSelection.isComplete)
                  CustomPaint(
                    painter: _LassoPainter(
                      lassoSelection: _lassoSelection,
                      borderColor: Colors.blue,
                      fillColor: Colors.blue.withOpacity(0.1),
                      borderWidth: 1.5,
                      enableShadows: true,
                      enableGlow: true,
                    ),
                    size: Size.infinite,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Variables for scale gesture handling
  Offset? _lastFocalPoint;
  double _lastZoomScale = 1.0;
  
  /// Handles the start of a scale gesture
  void _handleScaleStart(ScaleStartDetails details) {
    _lastFocalPoint = details.focalPoint;
    _lastZoomScale = 1.0;
    
    // Cancel any active animations
    _animationController.stop();
    _zoomAnimation = null;
    _panAnimation = null;
  }
  
  /// Handles updates during a scale gesture
  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_lastFocalPoint == null) return;
    
    setState(() {
      // Handle zoom
      if (details.scale != 1.0) {
        // Calculate the new zoom scale, considering min/max limits
        final targetZoomScale = (_zoomScale * details.scale / _lastZoomScale)
            .clamp(widget.config.minZoomScale, widget.config.maxZoomScale);
        
        // Calculate zoom around focal point to maintain context
        final focalPointDelta = details.focalPoint - _lastFocalPoint!;
        final zoomDelta = targetZoomScale / _zoomScale;
        
        // Update pan to zoom around focal point
        _panOffset = _panOffset * zoomDelta + focalPointDelta * (1 - zoomDelta);
        _zoomScale = targetZoomScale;
      } else {
        // Handle pan
        _panOffset += details.focalPoint - _lastFocalPoint!;
      }
      
      _lastFocalPoint = details.focalPoint;
      _lastZoomScale = details.scale;
      
      // Apply viewport constraints
      _constrainViewport();
    });
  }
  
  /// Handles the end of a scale gesture
  void _handleScaleEnd(ScaleEndDetails details) {
    _lastFocalPoint = null;
  }
  
  /// Handles tap down events for element selection
  void _handleTapDown(TapDownDetails details) {
    // Don't handle taps while in lasso mode
    if (_lassoSelection.isActive) return;
    
    // Clear any completed lasso selection
    if (_lassoSelection.isComplete) {
      setState(() {
        _lassoSelection.cancel();
      });
      return;
    }
    
    // Adjust point for current pan and zoom
    final adjustedPoint = (details.localPosition - _panOffset) / _zoomScale;
    
    // Get the diagram painter to hit test
    final hitTestResult = diagram.DiagramPainter(
      view: widget.view,
      workspace: widget.workspace,
      zoomScale: _zoomScale,
      panOffset: _panOffset,
    ).performHitTest(adjustedPoint);
    
    // Check for keyboard modifiers (Ctrl/Cmd for multi-select)
    final RenderBox box = context.findRenderObject() as RenderBox;
    final BoxHitTestResult result = BoxHitTestResult();
    box.hitTest(result, position: box.globalToLocal(details.globalPosition));
    
    // Check if Ctrl/Cmd key is pressed for multi-selection
    bool isMultiSelectModifierPressed = false;
    for (final entry in result.path) {
      if (entry.runtimeType.toString().contains('MultipleGestureRecognizer')) {
        isMultiSelectModifierPressed = true;
        break;
      }
    }
    
    setState(() {
      if (hitTestResult.type == DiagramHitTestResultType.element) {
        // Element hit
        final elementId = hitTestResult.id!;
        
        if (isMultiSelectModifierPressed) {
          // Add to multi-selection
          if (_selectedIds.contains(elementId)) {
            // If already selected, remove it (toggle)
            _selectedIds.remove(elementId);
            if (_selectedId == elementId) {
              // If removing the primary selection, pick a new one or clear
              _selectedId = _selectedIds.isEmpty ? null : _selectedIds.first;
            }
          } else {
            // Add to selection
            _selectedIds.add(elementId);
            _selectedId = elementId; // Make the new item the primary selection
          }
        } else {
          // Single selection (normal tap)
          _selectedIds.clear();
          _selectedIds.add(elementId);
          _selectedId = elementId;
        }
        
        // Notify selection callback if element exists
        if (widget.onElementSelected != null && hitTestResult.element != null && _selectedId != null) {
          widget.onElementSelected!(_selectedId!, hitTestResult.element!);
        }
      } else if (hitTestResult.type == DiagramHitTestResultType.relationship) {
        // Relationship hit - no multi-select for relationships
        _selectedIds.clear();
        _selectedId = hitTestResult.id;
        if (widget.onRelationshipSelected != null && hitTestResult.relationship != null) {
          widget.onRelationshipSelected!(_selectedId!, hitTestResult.relationship!);
        }
      } else {
        // No hit - clear selection unless Ctrl/Cmd is pressed (for adding to selection)
        if (!isMultiSelectModifierPressed) {
          _selectedId = null;
          _selectedIds.clear();
          if (widget.onSelectionCleared != null) {
            widget.onSelectionCleared!();
          }
        }
      }
    });
  }
  
  /// Handles the start of a pan gesture for lasso selection or element dragging
  void _handlePanStart(DragStartDetails details) {
    if (!widget.config.isEditable) return;
    
    // Adjust point for current pan and zoom
    final adjustedPoint = (details.localPosition - _panOffset) / _zoomScale;
    
    // Hit test to determine if we're starting on an element
    final hitTestResult = diagram.DiagramPainter(
      view: widget.view,
      workspace: widget.workspace,
      zoomScale: _zoomScale,
      panOffset: _panOffset,
    ).performHitTest(adjustedPoint);
    
    setState(() {
      // If we hit an element and it's selected (or we're selecting it now),
      // prepare for dragging the element(s)
      if (hitTestResult.type == DiagramHitTestResultType.element && 
          (_selectedIds.contains(hitTestResult.id) || 
           (_selectedIds.isEmpty && !_isCtrlPressed && !_isShiftPressed))) {
        
        _selectionMode = SelectionMode.dragging;
        _lastPointerPosition = adjustedPoint;
        
        // If the element isn't already selected, select it
        if (!_selectedIds.contains(hitTestResult.id!)) {
          _selectedId = hitTestResult.id;
          _selectedIds.clear();
          _selectedIds.add(hitTestResult.id!);
          
          if (widget.onElementSelected != null && hitTestResult.element != null) {
            widget.onElementSelected!(hitTestResult.id!, hitTestResult.element!);
          }
        }
        
        // Store original positions for all selected elements
        _originalElementPositions = {};
        _currentElementPositions = {};
        
        for (final elementId in _selectedIds) {
          final element = widget.workspace.model.getElementById(elementId);
          if (element == null) continue;
          
          final elementView = widget.view.getElementById(elementId);
          if (elementView == null || elementView.x == null || elementView.y == null) continue;
          
          final position = Offset(elementView.x!.toDouble(), elementView.y!.toDouble());
          _originalElementPositions[elementId] = position;
          _currentElementPositions[elementId] = position;
        }
      } else {
        // Start lasso selection
        _selectionMode = SelectionMode.lasso;
        _lassoSelection.start(adjustedPoint);
      }
    });
  }
  
  /// Handles updates during a pan gesture for lasso selection or element dragging
  void _handlePanUpdate(DragUpdateDetails details) {
    if (!widget.config.isEditable) return;
    
    // Adjust point for current pan and zoom
    final adjustedPoint = (details.localPosition - _panOffset) / _zoomScale;
    
    setState(() {
      if (_selectionMode == SelectionMode.lasso && _lassoSelection.isActive) {
        // Update lasso selection
        _lassoSelection.update(adjustedPoint);
      } else if (_selectionMode == SelectionMode.dragging && _lastPointerPosition != null) {
        // Calculate the delta movement
        final delta = adjustedPoint - _lastPointerPosition!;
        _lastPointerPosition = adjustedPoint;
        
        // Update positions for all selected elements
        final updatedPositions = <String, Offset>{};
        final updatedElements = <ElementView>[];
        
        for (final entry in _currentElementPositions.entries) {
          final elementId = entry.key;
          final currentPosition = entry.value;
          
          // Calculate new position
          final newPosition = currentPosition + delta;
          _currentElementPositions[elementId] = newPosition;
          updatedPositions[elementId] = newPosition;
          
          // Update the element view immutably
          final elementView = widget.view.getElementById(elementId);
          if (elementView != null) {
            final updatedElementView = elementView.copyWithPositionOffset(newPosition);
            updatedElements.add(updatedElementView);
          }
        }
        
        // TODO: Use proper view updating through the immutable model
        // This would require passing the updated elements to the parent for proper state management
        // For now, we just update the positions visually and will apply the real update on pan end
      }
    });
  }
  
  /// Handles the end of a pan gesture for lasso selection or element dragging
  void _handlePanEnd(DragEndDetails details) {
    if (!widget.config.isEditable) return;
    
    setState(() {
      if (_selectionMode == SelectionMode.lasso && _lassoSelection.isActive) {
        // Complete lasso selection
        _lassoSelection.complete();
        
        // Process selection of elements within lasso
        _selectElementsInLasso();
      } else if (_selectionMode == SelectionMode.dragging && _lastPointerPosition != null) {
        // Apply the element position changes using immutable updates
        if (_currentElementPositions.isNotEmpty) {
          // Create immutable updates through proper extension methods
          final updatedElementViews = <ElementView>[];
          
          for (final entry in _currentElementPositions.entries) {
            final elementId = entry.key;
            final newPosition = entry.value;
            
            // Get the original element view
            final originalView = widget.view.getElementById(elementId);
            if (originalView != null) {
              // Create an updated view with the new position using extension method
              final updatedView = originalView.copyWithPosition(
                newPosition.dx.round(),
                newPosition.dy.round(),
              );
              updatedElementViews.add(updatedView);
            }
          }
          
          // Notify about the movement with the updated positions
          if (widget.onElementsMoved != null) {
            widget.onElementsMoved!(_currentElementPositions);
          }
        }
        
        // Reset drag state
        _lastPointerPosition = null;
        _originalElementPositions = {};
        _currentElementPositions = {};
      }
      
      // Reset selection mode
      _selectionMode = SelectionMode.normal;
    });
  }
  
  /// Selects all elements that are inside the lasso selection
  void _selectElementsInLasso() {
    if (!_lassoSelection.isComplete) return;
    
    // Get all element rectangles from the diagram painter
    final painter = diagram.DiagramPainter(
      view: widget.view,
      workspace: widget.workspace,
      zoomScale: _zoomScale,
      panOffset: _panOffset,
    );
    
    final elementRects = painter.getAllElementRects();
    final relationshipPaths = painter.getAllRelationshipPaths();
    
    // Build lists of selected item IDs
    final selectedElementIds = <String>{};
    final selectedRelationshipIds = <String>{};
    
    // Check each element against the lasso
    for (final entry in elementRects.entries) {
      final elementId = entry.key;
      final rect = entry.value;
      
      // Check if the lasso intersects the element
      if (_lassoSelection.intersectsRect(rect)) {
        selectedElementIds.add(elementId);
      }
    }
    
    // Check each relationship against the lasso with improved path testing
    for (final entry in relationshipPaths.entries) {
      final relationshipId = entry.key;
      final path = entry.value;
      
      if (path.isEmpty) continue;
      
      // Get the complete relationship details
      final relationship = widget.workspace.model.getAllRelationships().firstWhere(
        (r) => r.id == relationshipId,
        orElse: () => throw Exception('Relationship not found')
      );
      
      // Get the relationship view with potential vertices
      final relationshipView = widget.view.getRelationshipById(relationshipId);
      
      // Path intersection flag
      bool pathIntersects = false;
      
      // Check vertices if available in the relationship view
      if (relationshipView != null && relationshipView.vertices != null && relationshipView.vertices!.isNotEmpty) {
        // Create a list of vertex points
        final vertexPoints = relationshipView.vertices!
            .where((v) => v.x != null && v.y != null)
            .map((v) => Offset(v.x!.toDouble(), v.y!.toDouble()))
            .toList();
        
        // Check if any vertex is inside the lasso
        for (final vertex in vertexPoints) {
          if (_lassoSelection.containsPoint(vertex)) {
            pathIntersects = true;
            break;
          }
        }
        
        // Check segments between vertices
        if (!pathIntersects && vertexPoints.isNotEmpty) {
          // Check source to first vertex
          if (path.isNotEmpty && vertexPoints.isNotEmpty && 
              _lassoSelection.intersectsRelationship(path.first, vertexPoints.first)) {
            pathIntersects = true;
          }
          
          // Check between vertices
          if (!pathIntersects) {
            for (int i = 0; i < vertexPoints.length - 1; i++) {
              if (_lassoSelection.intersectsRelationship(vertexPoints[i], vertexPoints[i + 1])) {
                pathIntersects = true;
                break;
              }
            }
          }
          
          // Check last vertex to target
          if (!pathIntersects && path.isNotEmpty && vertexPoints.isNotEmpty && 
              _lassoSelection.intersectsRelationship(vertexPoints.last, path.last)) {
            pathIntersects = true;
          }
        }
      }
      
      // If no vertices or no intersection found yet, check the main path
      if (!pathIntersects && path.length >= 2) {
        // For curved relationships, check multiple points along the path
        if (path.length > 2) {
          // Check each segment in the path
          for (int i = 0; i < path.length - 1; i++) {
            if (_lassoSelection.intersectsRelationship(path[i], path[i + 1])) {
              pathIntersects = true;
              break;
            }
            
            // For long segments, check intermediate points
            final distance = (path[i + 1] - path[i]).distance;
            if (distance > 50) {
              // Sample intermediate points along the segment
              final steps = (distance / 25).ceil();
              for (int step = 1; step < steps; step++) {
                final t = step / steps;
                final intermediatePoint = Offset(
                  path[i].dx + (path[i + 1].dx - path[i].dx) * t,
                  path[i].dy + (path[i + 1].dy - path[i].dy) * t
                );
                
                if (_lassoSelection.containsPoint(intermediatePoint)) {
                  pathIntersects = true;
                  break;
                }
              }
              
              if (pathIntersects) break;
            }
          }
        } else {
          // Simple straight-line relationship
          pathIntersects = _lassoSelection.intersectsRelationship(path.first, path.last);
        }
      }
      
      // Check endpoints as well (source and target)
      if (!pathIntersects && path.isNotEmpty) {
        if (path.length >= 2 && 
            (_lassoSelection.containsPoint(path.first) || _lassoSelection.containsPoint(path.last))) {
          pathIntersects = true;
        }
      }
      
      // Add to selection if any part of the path intersects
      if (pathIntersects) {
        selectedRelationshipIds.add(relationshipId);
      }
    }
    
    // Update selection based on results
    if (selectedElementIds.isEmpty && selectedRelationshipIds.isEmpty) {
      // If nothing selected, clear selection unless modifier key is pressed
      if (!_isCtrlPressed && !_isShiftPressed) {
        _selectedId = null;
        _selectedIds.clear();
        if (widget.onSelectionCleared != null) {
          widget.onSelectionCleared!();
        }
      }
    } else {
      // Add to multi-selection if Ctrl/Shift is pressed, otherwise replace
      if (_isCtrlPressed || _isShiftPressed) {
        // Add to existing selection
        _selectedIds.addAll(selectedElementIds);
        _selectedIds.addAll(selectedRelationshipIds);
      } else {
        // Replace existing selection
        _selectedIds.clear();
        _selectedIds.addAll(selectedElementIds);
        _selectedIds.addAll(selectedRelationshipIds);
      }
      
      // Set a primary selection if we have one
      if (_selectedIds.isNotEmpty) {
        _selectedId = _selectedIds.first;
      }
      
      // Call multi-selection callback
      if (widget.onMultipleItemsSelected != null) {
        widget.onMultipleItemsSelected!(
          selectedElementIds,
          selectedRelationshipIds
        );
      } else if (_selectedId != null) {
        // Fall back to single selection callback if no multi-selection callback
        final element = widget.workspace.model.getElementById(_selectedId!);
        if (element != null && widget.onElementSelected != null) {
          widget.onElementSelected!(_selectedId!, element);
        } else {
          final relationship = widget.workspace.model.getAllRelationships().firstWhere(
            (r) => r.id == _selectedId!,
            orElse: () => throw Exception('Relationship not found')
          );
          if (widget.onRelationshipSelected != null) {
            widget.onRelationshipSelected!(_selectedId!, relationship);
          }
        }
      }
    }
    
    // Store selected elements in the lasso selection for visual feedback
    _lassoSelection.setSelectedElements(selectedElementIds);
    _lassoSelection.setSelectedRelationships(selectedRelationshipIds);
  }
  
  /// Handles hover events for element highlighting
  void _handleHover(PointerHoverEvent event) {
    // Adjust point for current pan and zoom
    final adjustedPoint = (event.localPosition - _panOffset) / _zoomScale;
    
    // Get the diagram painter to hit test
    final hitTestResult = diagram.DiagramPainter(
      view: widget.view,
      workspace: widget.workspace,
      zoomScale: _zoomScale,
      panOffset: _panOffset,
    ).performHitTest(adjustedPoint);
    
    // Only update state if hoveredId changes to avoid unnecessary rebuilds
    if ((hitTestResult.type == DiagramHitTestResultType.element && hitTestResult.id != _hoveredId) ||
        (hitTestResult.type != DiagramHitTestResultType.element && _hoveredId != null)) {
      setState(() {
        if (hitTestResult.type == DiagramHitTestResultType.element) {
          _hoveredId = hitTestResult.id;
          if (widget.onElementHovered != null && hitTestResult.element != null) {
            widget.onElementHovered!(_hoveredId!, hitTestResult.element!);
          }
        } else {
          _hoveredId = null;
        }
      });
    }
  }
  
  /// Zooms to fit all elements in the view
  void fitToScreen() {
    final painter = diagram.DiagramPainter(
      view: widget.view,
      workspace: widget.workspace,
    );
    
    // Calculate the bounding box for all elements
    final boundingBox = painter.getBoundingBox();
    if (boundingBox == Rect.zero) return;
    
    // Get the size of the widget
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    
    // Calculate the zoom scale needed to fit the bounding box
    final horizontalScale = size.width / boundingBox.width;
    final verticalScale = size.height / boundingBox.height;
    
    // Use the smaller scale to ensure everything fits
    final targetScale = math.min(horizontalScale, verticalScale) * 0.9; // 90% to add some margin
    final targetScale1 = targetScale.clamp(widget.config.minZoomScale, widget.config.maxZoomScale);
    
    // Calculate the pan offset to center the bounding box
    final targetPanOffset = Offset(
      size.width / 2 - boundingBox.center.dx * targetScale1,
      size.height / 2 - boundingBox.center.dy * targetScale1,
    );
    
    // Animate to the new zoom and pan
    _animateToZoomAndPan(targetScale1, targetPanOffset);
  }
  
  /// Zooms to fit the currently selected elements
  void zoomToSelection() {
    if (_selectedIds.isEmpty) return;
    
    final painter = diagram.DiagramPainter(
      view: widget.view,
      workspace: widget.workspace,
    );
    
    // Get all element and relationship bounding rectangles
    final allRects = painter.getAllElementRects();
    final relationshipPaths = painter.getAllRelationshipPaths();
    
    // Initialize bounding box variables
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;
    bool hasElements = false;
    
    // Find bounds for selected elements
    for (final id in _selectedIds) {
      // Check if it's an element
      final rect = allRects[id];
      if (rect != null) {
        minX = math.min(minX, rect.left);
        minY = math.min(minY, rect.top);
        maxX = math.max(maxX, rect.right);
        maxY = math.max(maxY, rect.bottom);
        hasElements = true;
        continue;
      }
      
      // Check if it's a relationship
      final path = relationshipPaths[id];
      if (path != null && path.isNotEmpty) {
        for (final point in path) {
          minX = math.min(minX, point.dx);
          minY = math.min(minY, point.dy);
          maxX = math.max(maxX, point.dx);
          maxY = math.max(maxY, point.dy);
          hasElements = true;
        }
      }
    }
    
    // Exit if no selected elements or relationships found
    if (!hasElements) return;
    
    // Create a bounding box with some padding (20% of the dimensions)
    final width = maxX - minX;
    final height = maxY - minY;
    final paddingX = width * 0.2;
    final paddingY = height * 0.2;
    
    final selectionBounds = Rect.fromLTRB(
      minX - paddingX,
      minY - paddingY,
      maxX + paddingX,
      maxY + paddingY
    );
    
    // Get the size of the widget
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    
    // Calculate the zoom scale needed to fit the selection
    final horizontalScale = size.width / selectionBounds.width;
    final verticalScale = size.height / selectionBounds.height;
    
    // Use the smaller scale to ensure everything fits
    final targetScale = math.min(horizontalScale, verticalScale);
    final constrainedScale = targetScale.clamp(widget.config.minZoomScale, widget.config.maxZoomScale);
    
    // Calculate the pan offset to center the selection
    final targetPanOffset = Offset(
      size.width / 2 - selectionBounds.center.dx * constrainedScale,
      size.height / 2 - selectionBounds.center.dy * constrainedScale,
    );
    
    // Animate to the new zoom and pan
    _animateToZoomAndPan(constrainedScale, targetPanOffset);
  }
  
  /// Centers the view on a specific element
  void centerOnElement(String elementId) {
    final painter = diagram.DiagramPainter(
      view: widget.view,
      workspace: widget.workspace,
    );
    
    // Get the rectangle for the element
    final elementRect = painter.getElementRect(elementId);
    if (elementRect == null) return;
    
    // Get the size of the widget
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    
    // Calculate the pan offset to center the element
    final targetPanOffset = Offset(
      size.width / 2 - elementRect.center.dx * _zoomScale,
      size.height / 2 - elementRect.center.dy * _zoomScale,
    );
    
    // Animate to the new pan offset (keeping the current zoom)
    _animateToZoomAndPan(_zoomScale, targetPanOffset);
  }
  
  /// Programmatically selects an element
  void selectElement(String elementId) {
    final element = widget.workspace.model.getElementById(elementId);
    if (element == null) return;
    
    setState(() {
      _selectedId = elementId;
      if (widget.onElementSelected != null) {
        widget.onElementSelected!(elementId, element);
      }
    });
  }
  
  /// Clears the current selection
  void clearSelection() {
    setState(() {
      _selectedId = null;
      if (widget.onSelectionCleared != null) {
        widget.onSelectionCleared!();
      }
    });
  }
  
  /// Animates to a new zoom scale and pan offset
  void _animateToZoomAndPan(double targetScale, Offset targetPanOffset) {
    // Cancel any previous animations
    _animationController.stop();
    
    // Ensure the target scale is within bounds
    final constrainedScale = targetScale.clamp(widget.config.minZoomScale, widget.config.maxZoomScale);
    
    // Apply viewport constraints to target pan offset (simulate with the target scale)
    final double originalScale = _zoomScale;
    _zoomScale = constrainedScale; // Temporarily set scale to apply constraints
    final constrainedOffset = _getConstrainedPanOffset(targetPanOffset);
    _zoomScale = originalScale; // Restore original scale
    
    // Create animations for zoom and pan
    _zoomAnimation = Tween<double>(
      begin: _zoomScale,
      end: constrainedScale,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _panAnimation = Tween<Offset>(
      begin: _panOffset,
      end: constrainedOffset,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    // Reset the controller and start the animation
    _animationController.reset();
    _animationController.forward();
  }
  
  /// Gets the current zoom scale
  double getZoomScale() => _zoomScale;
  
  /// Gets the current pan offset
  Offset getPanOffset() => _panOffset;
  
  /// Gets the currently selected element or relationship ID
  String? getSelectedId() => _selectedId;
  
  /// Gets the lasso selection
  LassoSelection getLassoSelection() => _lassoSelection;
  
  /// Gets the current animation step
  int? getAnimationStep() => widget.animationStep;
  
  /// Constrains the current viewport to ensure content remains visible
  void _constrainViewport() {
    _panOffset = _getConstrainedPanOffset(_panOffset);
  }
  
  /// Calculates constrained pan offset to prevent getting lost
  Offset _getConstrainedPanOffset(Offset panOffset) {
    // Get the diagram painter to access the content bounds
    final painter = diagram.DiagramPainter(
      view: widget.view,
      workspace: widget.workspace,
    );
    
    // Get the bounding box of all diagram elements
    final boundingBox = painter.getBoundingBox();
    if (boundingBox == Rect.zero || context == null) {
      return panOffset; // Nothing to constrain
    }
    
    // Get current viewport size
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return panOffset;
    
    final viewportSize = renderBox.size;
    
    // Calculate the scaled content size
    final scaledWidth = boundingBox.width * _zoomScale;
    final scaledHeight = boundingBox.height * _zoomScale;
    
    // Calculate padding - add extra space around the diagram
    final horizontalPadding = viewportSize.width * 0.1; // 10% of viewport width
    final verticalPadding = viewportSize.height * 0.1; // 10% of viewport height
    
    // Calculate the bounds that ensure at least 20% of the diagram is visible
    // This prevents zooming out so far that the diagram is unrecognizable
    final minVisibleWidth = scaledWidth * 0.2;
    final minVisibleHeight = scaledHeight * 0.2;
    
    double minX, maxX, minY, maxY;
    
    // If the scaled content is smaller than the viewport, center it
    if (scaledWidth < viewportSize.width) {
      final center = (viewportSize.width - scaledWidth) / 2;
      minX = center - horizontalPadding;
      maxX = center + horizontalPadding;
    } else {
      // Content is larger than viewport
      // Ensure the right edge never goes further left than 20% visible
      minX = viewportSize.width - minVisibleWidth;
      // Ensure the left edge never goes further right than 20% visible  
      maxX = -scaledWidth + minVisibleWidth;
      
      // Adjust min/max bounds to ensure they're in the right order
      if (minX < maxX) {
        final temp = minX;
        minX = maxX;
        maxX = temp;
      }
    }
    
    // Apply the same logic for vertical constraints
    if (scaledHeight < viewportSize.height) {
      final center = (viewportSize.height - scaledHeight) / 2;
      minY = center - verticalPadding;
      maxY = center + verticalPadding;
    } else {
      minY = viewportSize.height - minVisibleHeight;
      maxY = -scaledHeight + minVisibleHeight;
      
      if (minY < maxY) {
        final temp = minY;
        minY = maxY;
        maxY = temp;
      }
    }
    
    // Apply bounds with an adjustment for the scaled content origin
    final boundedPanX = (panOffset.dx + (boundingBox.left * _zoomScale))
        .clamp(maxX, minX) - (boundingBox.left * _zoomScale);
    final boundedPanY = (panOffset.dy + (boundingBox.top * _zoomScale))
        .clamp(maxY, minY) - (boundingBox.top * _zoomScale);
    
    return Offset(boundedPanX, boundedPanY);
  }
  
  /// Handles key events for modifier keys
  void _handleKeyEvent(KeyEvent event) {
    final isCtrlEvent = event.logicalKey == LogicalKeyboardKey.controlLeft || 
                         event.logicalKey == LogicalKeyboardKey.controlRight;
    final isShiftEvent = event.logicalKey == LogicalKeyboardKey.shiftLeft || 
                          event.logicalKey == LogicalKeyboardKey.shiftRight;
    
    if (isCtrlEvent || isShiftEvent) {
      final isKeyDown = event is KeyDownEvent;
      
      setState(() {
        if (isCtrlEvent) _isCtrlPressed = isKeyDown;
        if (isShiftEvent) _isShiftPressed = isKeyDown;
      });
    }
    
    // Handle other key events
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.delete || 
          event.logicalKey == LogicalKeyboardKey.backspace) {
        // Handle delete operation for selected elements
        _deleteSelectedElements();
      } else if (event.logicalKey == LogicalKeyboardKey.keyA && _isCtrlPressed) {
        // Handle Ctrl+A to select all elements
        _selectAllElements();
      } else if (event.logicalKey == LogicalKeyboardKey.keyF && _isCtrlPressed) {
        // Handle Ctrl+F to fit all elements to screen
        fitToScreen();
      } else if (event.logicalKey == LogicalKeyboardKey.keyE && _isCtrlPressed) {
        // Handle Ctrl+E to zoom to selection (mnemonic: 'E'nlarge selection)
        if (_selectedIds.isNotEmpty) {
          zoomToSelection();
        }
      } else if (event.logicalKey == LogicalKeyboardKey.equal && _isCtrlPressed) {
        // Handle Ctrl+ to zoom in
        setState(() {
          final newScale = (_zoomScale * 1.2).clamp(widget.config.minZoomScale, widget.config.maxZoomScale);
          _animateToZoomAndPan(newScale, _panOffset);
        });
      } else if (event.logicalKey == LogicalKeyboardKey.minus && _isCtrlPressed) {
        // Handle Ctrl- to zoom out
        setState(() {
          final newScale = (_zoomScale / 1.2).clamp(widget.config.minZoomScale, widget.config.maxZoomScale);
          _animateToZoomAndPan(newScale, _panOffset);
        });
      } else if (event.logicalKey == LogicalKeyboardKey.digit0 && _isCtrlPressed) {
        // Handle Ctrl+0 to reset zoom
        setState(() {
          _animateToZoomAndPan(1.0, Offset.zero);
        });
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        // Cancel any active operation and clear selection
        setState(() {
          if (_lassoSelection.isActive) {
            _lassoSelection.cancel();
          }
          _selectionMode = SelectionMode.normal;
          _selectedId = null;
          _selectedIds.clear();
          if (widget.onSelectionCleared != null) {
            widget.onSelectionCleared!();
          }
        });
      }
    }
  }
  
  /// Handles secondary (right-click) tap for context menu
  void _handleSecondaryTapDown(TapDownDetails details) {
    // Adjust point for current pan and zoom
    final adjustedPoint = (details.localPosition - _panOffset) / _zoomScale;
    
    // Hit test to determine what was clicked
    final hitTestResult = diagram.DiagramPainter(
      view: widget.view,
      workspace: widget.workspace,
      zoomScale: _zoomScale,
      panOffset: _panOffset,
    ).performHitTest(adjustedPoint);
    
    // Show context menu based on what was clicked
    _showContextMenu(details.globalPosition, hitTestResult);
  }
  
  /// Shows a context menu at the given position
  void _showContextMenu(Offset position, DiagramHitTestResult hitTestResult) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localPosition = box.globalToLocal(position);
    
    // Build the menu items based on the hit test result
    final List<PopupMenuEntry<String>> menuItems = [];
    
    if (hitTestResult.type == DiagramHitTestResultType.element && hitTestResult.id != null) {
      // Element context menu
      final bool isSelected = _selectedIds.contains(hitTestResult.id);
      final element = hitTestResult.element;
      final elementType = element != null ? element.runtimeType.toString() : 'Element';
      
      menuItems.add(PopupMenuItem<String>(
        enabled: false,
        child: Text(
          element?.name ?? 'Element',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ));
      
      menuItems.add(const PopupMenuDivider());
      
      if (!isSelected) {
        // If element is not selected, add "Select" option
        menuItems.add(const PopupMenuItem<String>(
          value: 'select',
          child: Text('Select'),
        ));
      } else if (_selectedIds.length > 1) {
        // If it's part of a multi-selection, add "Select Only This" option
        menuItems.add(const PopupMenuItem<String>(
          value: 'select_only',
          child: Text('Select Only This'),
        ));
      }
      
      // Add center option
      menuItems.add(const PopupMenuItem<String>(
        value: 'center',
        child: Text('Center on this element'),
      ));
      
      // Add zoom to option
      menuItems.add(const PopupMenuItem<String>(
        value: 'zoom_to_element',
        child: Text('Zoom to this element'),
      ));
      
      menuItems.add(const PopupMenuDivider());
      
      // Edit operations (only if editable)
      if (widget.config.isEditable) {
        menuItems.addAll([
          const PopupMenuItem<String>(
            value: 'copy',
            child: Text('Copy'),
          ),
          const PopupMenuItem<String>(
            value: 'delete',
            child: Text('Delete'),
          ),
        ]);
        menuItems.add(const PopupMenuDivider());
      }
      
      // Add element details option
      menuItems.add(PopupMenuItem<String>(
        value: 'show_details',
        child: Row(
          children: [
            const Text('Show Details'),
            const Spacer(),
            Icon(
              Icons.info_outline,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ));
      
    } else if (hitTestResult.type == DiagramHitTestResultType.relationship && hitTestResult.id != null) {
      // Relationship context menu
      final relationship = hitTestResult.relationship;
      
      menuItems.add(PopupMenuItem<String>(
        enabled: false,
        child: Text(
          relationship?.description ?? 'Relationship',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ));
      
      menuItems.add(const PopupMenuDivider());
      
      menuItems.add(const PopupMenuItem<String>(
        value: 'select_relationship',
        child: Text('Select Relationship'),
      ));
      
      // Edit operations (only if editable)
      if (widget.config.isEditable) {
        menuItems.add(const PopupMenuDivider());
        menuItems.add(const PopupMenuItem<String>(
          value: 'delete_relationship',
          child: Text('Delete Relationship'),
        ));
      }
      
      // Add relationship details option
      menuItems.add(const PopupMenuDivider());
      menuItems.add(PopupMenuItem<String>(
        value: 'show_details',
        child: Row(
          children: [
            const Text('Show Details'),
            const Spacer(),
            Icon(
              Icons.info_outline,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ));
    } else {
      // Background context menu
      menuItems.addAll([
        const PopupMenuItem<String>(
          value: 'select_all',
          child: Text('Select All'),
        ),
        const PopupMenuItem<String>(
          value: 'fit_to_screen',
          child: Text('Fit to Screen'),
        ),
      ]);
      
      // Add selection options if there are selected elements
      if (_selectedIds.isNotEmpty) {
        menuItems.add(const PopupMenuItem<String>(
          value: 'zoom_to_selection',
          child: Text('Zoom to Selection'),
        ));
        
        menuItems.add(const PopupMenuItem<String>(
          value: 'clear_selection',
          child: Text('Clear Selection'),
        ));
      }
      
      // Add clipboard options (only if editable)
      if (widget.config.isEditable) {
        menuItems.add(const PopupMenuDivider());
        
        if (_selectedIds.isNotEmpty) {
          menuItems.add(const PopupMenuItem<String>(
            value: 'copy',
            child: Text('Copy Selected Elements'),
          ));
        }
        
        // Add paste option
        menuItems.add(const PopupMenuItem<String>(
          value: 'paste',
          child: Text('Paste'),
        ));
      }
      
      // Add view options menu
      menuItems.add(const PopupMenuDivider());
      menuItems.add(PopupMenuItem<String>(
        value: 'view_options',
        child: Row(
          children: [
            const Text('View Options'),
            const Spacer(),
            Icon(
              Icons.settings_outlined,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ));
    }
    
    // Show the context menu
    if (menuItems.isNotEmpty) {
      showMenu<String>(
        context: context,
        position: RelativeRect.fromLTRB(
          localPosition.dx,
          localPosition.dy,
          localPosition.dx + 1,
          localPosition.dy + 1,
        ),
        items: menuItems,
      ).then((value) {
        // Handle menu selection
        _handleContextMenuSelection(value, hitTestResult);
      });
    }
  }
  
  /// Handles a selection from the context menu
  void _handleContextMenuSelection(String? value, DiagramHitTestResult hitTestResult) {
    if (value == null) return;
    
    setState(() {
      switch (value) {
        // Element operations
        case 'select':
          if (hitTestResult.id != null && hitTestResult.element != null) {
            _selectedId = hitTestResult.id;
            _selectedIds.clear();
            _selectedIds.add(hitTestResult.id!);
            if (widget.onElementSelected != null) {
              widget.onElementSelected!(hitTestResult.id!, hitTestResult.element!);
            }
          }
          break;
          
        case 'select_only':
          if (hitTestResult.id != null && hitTestResult.element != null) {
            _selectedId = hitTestResult.id;
            _selectedIds.clear();
            _selectedIds.add(hitTestResult.id!);
            if (widget.onElementSelected != null) {
              widget.onElementSelected!(hitTestResult.id!, hitTestResult.element!);
            }
          }
          break;
          
        // Relationship operations
        case 'select_relationship':
          if (hitTestResult.id != null && hitTestResult.relationship != null) {
            _selectedId = hitTestResult.id;
            _selectedIds.clear();
            _selectedIds.add(hitTestResult.id!);
            if (widget.onRelationshipSelected != null) {
              widget.onRelationshipSelected!(hitTestResult.id!, hitTestResult.relationship!);
            }
          }
          break;
          
        // Navigation operations
        case 'center':
          if (hitTestResult.id != null) {
            centerOnElement(hitTestResult.id!);
          }
          break;
          
        case 'zoom_to_element':
          if (hitTestResult.id != null) {
            // Clear current selection
            _selectedIds.clear();
            
            // Select only this element
            _selectedId = hitTestResult.id;
            _selectedIds.add(hitTestResult.id!);
            
            // Zoom to it
            zoomToSelection();
            
            // Notify about selection if needed
            if (hitTestResult.element != null && widget.onElementSelected != null) {
              widget.onElementSelected!(hitTestResult.id!, hitTestResult.element!);
            }
          }
          break;
          
        case 'fit_to_screen':
          fitToScreen();
          break;
        
        case 'zoom_to_selection':
          zoomToSelection();
          break;
          
        case 'clear_selection':
          _selectedId = null;
          _selectedIds.clear();
          if (widget.onSelectionCleared != null) {
            widget.onSelectionCleared!();
          }
          break;
        
        // Edit operations
        case 'delete':
        case 'delete_relationship':
          if (widget.config.isEditable) {
            _deleteSelectedElements();
          }
          break;
          
        case 'copy':
          if (widget.config.isEditable) {
            // In a full implementation, this would use the clipboard
            // For now, we'll just show a snackbar indicating the operation
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Copy operation not implemented'),
                duration: Duration(seconds: 2),
              ),
            );
          }
          break;
          
        case 'paste':
          if (widget.config.isEditable) {
            // In a full implementation, this would use the clipboard
            // For now, we'll just show a snackbar indicating the operation
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Paste operation not implemented'),
                duration: Duration(seconds: 2),
              ),
            );
          }
          break;
          
        // Selection operations
        case 'select_all':
          _selectAllElements();
          break;
          
        // Detail views
        case 'show_details':
          // Show detailed information about the element or relationship
          _showDetailsDialog(hitTestResult);
          break;
          
        // View settings
        case 'view_options':
          _showViewOptionsDialog();
          break;
      }
    });
  }
  
  /// Shows a dialog with detailed information about an element or relationship
  void _showDetailsDialog(DiagramHitTestResult hitTestResult) {
    if (hitTestResult.id == null) return;
    
    if (hitTestResult.type == DiagramHitTestResultType.element && hitTestResult.element != null) {
      // Show element details dialog
      final element = hitTestResult.element!;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(element.name),
          content: SizedBox(
            width: 400,
            height: 300,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Type: ${element.runtimeType}'),
                  const SizedBox(height: 8),
                  
                  Text('ID: ${element.id}'),
                  const SizedBox(height: 8),
                  
                  if (element.description != null) ...[
                    const Text(
                      'Description:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(element.description!),
                    const SizedBox(height: 8),
                  ],
                  
                  // Show tags if available
                  if (element.tags != null && element.tags!.isNotEmpty) ...[
                    const Text(
                      'Tags:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: element.tags!.map((tag) {
                        return Chip(
                          label: Text(tag, style: const TextStyle(fontSize: 10)),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  // Show properties if available
                  if (element.properties != null && element.properties!.isNotEmpty) ...[
                    const Text(
                      'Properties:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...element.properties!.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry.key}: ',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Expanded(
                              child: Text(entry.value.toString()),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } else if (hitTestResult.type == DiagramHitTestResultType.relationship && 
               hitTestResult.relationship != null) {
      // Show relationship details dialog
      final relationship = hitTestResult.relationship!;
      
      // Get source and target elements for display
      final sourceElement = widget.workspace.model.getElementById(relationship.sourceId);
      final targetElement = widget.workspace.model.getElementById(relationship.destinationId);
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(relationship.description ?? 'Relationship'),
          content: SizedBox(
            width: 400,
            height: 300,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('ID: ${relationship.id}'),
                  const SizedBox(height: 8),
                  
                  const Text(
                    'Source:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(sourceElement?.name ?? relationship.sourceId),
                  const SizedBox(height: 8),
                  
                  const Text(
                    'Target:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(targetElement?.name ?? relationship.destinationId),
                  const SizedBox(height: 8),
                  
                  if (relationship.technology != null) ...[
                    const Text(
                      'Technology:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(relationship.technology!),
                    const SizedBox(height: 8),
                  ],
                  
                  // Show tags if available
                  if (relationship.tags != null && relationship.tags!.isNotEmpty) ...[
                    const Text(
                      'Tags:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: relationship.tags!.map((tag) {
                        return Chip(
                          label: Text(tag, style: const TextStyle(fontSize: 10)),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  // Show properties if available
                  if (relationship.properties != null && relationship.properties!.isNotEmpty) ...[
                    const Text(
                      'Properties:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...relationship.properties!.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry.key}: ',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Expanded(
                              child: Text(entry.value.toString()),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }
  
  /// Shows a dialog with view options
  void _showViewOptionsDialog() {
    // Extract current view parameters from config
    final showGrid = widget.config.showGrid;
    final showElementNames = widget.config.showElementNames;
    final showElementDescriptions = widget.config.showElementDescriptions;
    final showRelationshipDescriptions = widget.config.showRelationshipDescriptions;
    
    // Create copies for editing
    bool localShowGrid = showGrid;
    bool localShowElementNames = showElementNames;
    bool localShowElementDescriptions = showElementDescriptions;
    bool localShowRelationshipDescriptions = showRelationshipDescriptions;
    
    // Show the dialog
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('View Options'),
            content: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Grid toggle
                  SwitchListTile(
                    title: const Text('Show Grid'),
                    value: localShowGrid,
                    onChanged: (value) {
                      setState(() {
                        localShowGrid = value;
                      });
                    },
                  ),
                  
                  // Element names toggle
                  SwitchListTile(
                    title: const Text('Show Element Names'),
                    value: localShowElementNames,
                    onChanged: (value) {
                      setState(() {
                        localShowElementNames = value;
                      });
                    },
                  ),
                  
                  // Element descriptions toggle
                  SwitchListTile(
                    title: const Text('Show Element Descriptions'),
                    value: localShowElementDescriptions,
                    onChanged: (value) {
                      setState(() {
                        localShowElementDescriptions = value;
                      });
                    },
                  ),
                  
                  // Relationship descriptions toggle
                  SwitchListTile(
                    title: const Text('Show Relationship Descriptions'),
                    value: localShowRelationshipDescriptions,
                    onChanged: (value) {
                      setState(() {
                        localShowRelationshipDescriptions = value;
                      });
                    },
                  ),
                  
                  // Zoom info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      'Current Zoom: ${(_zoomScale * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  
                  // Add more view options here as needed
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              
              // These options would normally be applied through callbacks
              // or state management, but for now we'll just show a message
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  
                  // Show application message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('View options application not implemented'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  /// Deletes the currently selected elements
  void _deleteSelectedElements() {
    // This would require integration with the model to actually delete elements
    // For now, just clear the selection
    setState(() {
      _selectedId = null;
      _selectedIds.clear();
      if (widget.onSelectionCleared != null) {
        widget.onSelectionCleared!();
      }
    });
  }
  
  /// Selects all elements in the view
  void _selectAllElements() {
    setState(() {
      _selectedIds.clear();
      
      // Add all elements to selection
      for (final elementView in widget.view.elements) {
        _selectedIds.add(elementView.id);
      }
      
      // Add all relationships to selection
      for (final relationshipView in widget.view.relationships) {
        _selectedIds.add(relationshipView.id);
      }
      
      // Set primary selection
      if (_selectedIds.isNotEmpty) {
        _selectedId = _selectedIds.first;
      }
      
      // Notify selection
      if (widget.onMultipleItemsSelected != null) {
        final elementIds = widget.view.elements
            .map((e) => e.id)
            .where((id) => _selectedIds.contains(id))
            .toSet();
        
        final relationshipIds = widget.view.relationships
            .map((r) => r.id)
            .where((id) => _selectedIds.contains(id))
            .toSet();
        
        widget.onMultipleItemsSelected!(elementIds, relationshipIds);
      }
    });
  }
  
  /// Returns the appropriate cursor for the current mode
  MouseCursor _getCursorForMode() {
    switch (_selectionMode) {
      case SelectionMode.normal:
        return SystemMouseCursors.basic;
      case SelectionMode.lasso:
        return SystemMouseCursors.cell;
      case SelectionMode.dragging:
        return SystemMouseCursors.move;
    }
  }
}