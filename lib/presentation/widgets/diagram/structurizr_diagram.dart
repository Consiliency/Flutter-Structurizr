import 'dart:math' as math;
import 'dart:ui' show PictureRecorder, Canvas;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide Container, Border, Element, View;
import 'package:flutter/services.dart';
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/presentation/layout/automatic_layout.dart';
import 'package:flutter_structurizr/presentation/layout/layout_strategy.dart';
import 'package:flutter_structurizr/presentation/layout/force_directed_layout.dart';
import 'package:flutter_structurizr/presentation/widgets/diagram/diagram_painter.dart'
    as diagram;
import 'package:flutter_structurizr/presentation/widgets/diagram/lasso_selection.dart';
import 'package:flutter_structurizr/presentation/widgets/diagram/diagram_painter.dart'
    show DiagramHitTestResult, DiagramHitTestResultType;
import 'package:flutter/rendering.dart';
import 'package:flutter_structurizr/domain/view/model_view.dart';
import 'package:flutter_structurizr/domain/view/view.dart' as structurizr_view;

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

/// A debug painter that shows element hit areas
class _DebugHitAreaPainter extends CustomPainter {
  final structurizr_view.View view;
  final double zoomScale;
  final Offset panOffset;
  final Map<String, Rect> cachedElementRects;
  final Map<String, List<Offset>> cachedRelationshipPaths;

  const _DebugHitAreaPainter({
    required this.view,
    required this.zoomScale,
    required this.panOffset,
    required this.cachedElementRects,
    required this.cachedRelationshipPaths,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Apply transformations
    canvas.save();
    canvas.translate(panOffset.dx, panOffset.dy);
    canvas.scale(zoomScale);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 / zoomScale; // Keep stroke width constant

    // Use the cached element rectangles
    for (final entry in cachedElementRects.entries) {
      final elementId = entry.key;
      final elementRect = entry.value;
      
      // Draw the hit area rectangle
      paint.color = Colors.red.withOpacity(0.5);
      canvas.drawRect(elementRect, paint);
      
      // Draw the element ID
      final textPainter = TextPainter(
        text: TextSpan(
          text: elementId,
          style: TextStyle(
            color: Colors.red,
            fontSize: 12 / zoomScale,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(elementRect.left + 2, elementRect.top + 2));
    }
    
    // Draw relationship hit areas
    print('DEBUG: Drawing ${cachedRelationshipPaths.length} relationship hit areas');
    paint.color = Colors.orange.withOpacity(0.5);
    paint.strokeWidth = 20.0 / zoomScale; // Show the hit threshold visually
    
    for (final entry in cachedRelationshipPaths.entries) {
      final relationshipId = entry.key;
      final path = entry.value;
      
      print('DEBUG: Drawing relationship $relationshipId with ${path.length} points');
      if (path.length < 2) continue;
      
      // Draw the relationship path with hit area thickness
      for (int i = 0; i < path.length - 1; i++) {
        canvas.drawLine(path[i], path[i + 1], paint);
      }
      
      // Draw relationship ID at midpoint
      if (path.length >= 2) {
        final midpoint = path[path.length ~/ 2];
        final textPainter = TextPainter(
          text: TextSpan(
            text: relationshipId,
            style: TextStyle(
              color: Colors.orange,
              fontSize: 10 / zoomScale,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, midpoint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_DebugHitAreaPainter oldDelegate) {
    return oldDelegate.view != view ||
        oldDelegate.zoomScale != zoomScale ||
        oldDelegate.panOffset != panOffset ||
        oldDelegate.cachedElementRects != cachedElementRects ||
        oldDelegate.cachedRelationshipPaths != cachedRelationshipPaths;
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
          lassoSelection.path, Colors.black.withValues(alpha: 0.3), 3.0, true);
    }

    // Apply glow effect for active selection if enabled
    if (enableGlow && lassoSelection.isActive) {
      final glowPaint = Paint()
        ..color = borderColor.withValues(alpha: 0.5)
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
  final _GridPainter? gridPainter = null;

  /// The lasso painter (optional)
  final _LassoPainter? lassoPainter = null;

  /// Creates a new composite painter
  const _CompositePainter();

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
      showElementDescriptions:
          showElementDescriptions ?? this.showElementDescriptions,
      showRelationshipDescriptions:
          showRelationshipDescriptions ?? this.showRelationshipDescriptions,
      showAnimationStepIndicators:
          showAnimationStepIndicators ?? this.showAnimationStepIndicators,
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
  final Function(Set<String> elementIds, Set<String> relationshipIds)?
      onMultipleItemsSelected;

  /// Callback for when elements are moved
  final Function(Map<String, Offset> newPositions)? onElementsMoved;

  /// Callback for when relationship vertices are changed
  final Function(String relationshipId, List<Vertex> vertices)? onRelationshipVerticesChanged;

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
    this.onRelationshipVerticesChanged,
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
    Function(Set<String> elementIds, Set<String> relationshipIds)?
        onMultipleItemsSelected,
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
class StructurizrDiagramState extends State<StructurizrDiagram>
    with SingleTickerProviderStateMixin {
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

  // Add initializers for final variables
  var gridPainter;
  var lassoPainter;
  
  // Store the diagram painter to access element positions
  diagram.DiagramPainter? _currentDiagramPainter;
  
  // Cache element positions to ensure consistency
  Map<String, Rect> _cachedElementRects = {};
  
  // Cache relationship paths for hit testing
  Map<String, List<Offset>> _cachedRelationshipPaths = {};
  
  // Temporary element positions during dragging
  Map<String, Offset>? _temporaryElementPositions;
  
  // Last tap position for vertex addition
  Offset? _lastTapPosition;
  
  // Relationship dragging state for vertex addition
  bool _isDraggingRelationship = false;
  String? _draggedRelationshipId;
  Offset? _relationshipDragStartPoint;
  Offset? _relationshipDragCurrentPoint;

  @override
  void initState() {
    super.initState();
    
    // Show vertex manipulation instructions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vertex editing: Drag relationship edge to add vertex, Shift+Click also works, Right-click vertex to delete'),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.blue,
          ),
        );
      }
    });
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
      print('DEBUG: Post frame callback - fitToScreen: ${widget.config.fitToScreen}, centerOnStart: ${widget.config.centerOnStart}');
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
    // Use the cached element rectangles
    if (_cachedElementRects.isEmpty) return;
    
    // Calculate centroid of all elements
    double totalX = 0;
    double totalY = 0;
    int elementCount = 0;
    
    for (final rect in _cachedElementRects.values) {
      totalX += rect.center.dx;
      totalY += rect.center.dy;
      elementCount++;
    }
    
    if (elementCount == 0) return;
    
    final centroid = Offset(totalX / elementCount, totalY / elementCount);

    // Get the current viewport size
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    // Calculate the center offset using centroid
    final targetPanOffset = Offset(
      size.width / 2 - centroid.dx * _zoomScale,
      size.height / 2 - centroid.dy * _zoomScale,
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
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent && widget.config.enablePanAndZoom) {
          // Handle mouse wheel zoom
          setState(() {
            // Calculate zoom factor based on scroll direction
            final double zoomFactor = event.scrollDelta.dy > 0 ? 0.9 : 1.1;
            final double targetZoomScale = (_zoomScale * zoomFactor)
                .clamp(widget.config.minZoomScale, widget.config.maxZoomScale);
            
            // Get the pointer position relative to the widget
            final RenderBox box = context.findRenderObject() as RenderBox;
            final Offset localPosition = box.globalToLocal(event.position);
            
            // Calculate the point in diagram coordinates
            final Offset diagramPoint = (localPosition - _panOffset) / _zoomScale;
            
            // Update zoom scale
            final double zoomDelta = targetZoomScale / _zoomScale;
            _zoomScale = targetZoomScale;
            
            // Adjust pan to zoom around the mouse pointer
            _panOffset = localPosition - diagramPoint * _zoomScale;
            
            // Apply viewport constraints
            _constrainViewport();
          });
        }
      },
      child: MouseRegion(
        onHover: null, // Disabled to reduce debug output
        child: GestureDetector(
          // Always handle tap for selection
          onTapDown: (details) {
            print('DEBUG: GestureDetector onTapDown triggered!');
            _handleTapDown(details);
          },
          onSecondaryTapDown: _handleSecondaryTapDown,
          // Use scale gestures which include both pan and zoom
          onScaleStart: (widget.config.isEditable || widget.config.enablePanAndZoom) ? _handleUnifiedScaleStart : null,
          onScaleUpdate: (widget.config.isEditable || widget.config.enablePanAndZoom) ? _handleUnifiedScaleUpdate : null,
          onScaleEnd: (widget.config.isEditable || widget.config.enablePanAndZoom) ? _handleUnifiedScaleEnd : null,
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
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                    size: Size.infinite,
                  ),

                // Main diagram
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Create the painter and store it
                    _currentDiagramPainter = diagram.DiagramPainter(
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
                      includeRelationshipDescriptions:
                          widget.config.showRelationshipDescriptions,
                      showAnimationStepIndicators:
                          widget.config.showAnimationStepIndicators,
                      temporaryElementPositions: _temporaryElementPositions,
                    );
                    
                    // Force layout calculation by painting to a dummy canvas
                    final recorder = PictureRecorder();
                    final canvas = Canvas(recorder);
                    _currentDiagramPainter!.paint(canvas, constraints.biggest);
                    recorder.endRecording();
                    
                    // Cache the element rectangles and relationship paths
                    _cachedElementRects = _currentDiagramPainter!.getAllElementRects();
                    _cachedRelationshipPaths = _currentDiagramPainter!.getAllRelationshipPaths();
                    
                    // Debug output disabled for performance
                    
                    return CustomPaint(
                      painter: _currentDiagramPainter,
                      size: Size.infinite,
                    );
                  },
                ),

                // Lasso selection (when active)
                if (_lassoSelection.isActive || _lassoSelection.isComplete)
                  CustomPaint(
                    painter: _LassoPainter(
                      lassoSelection: _lassoSelection,
                      borderColor: Colors.blue,
                      fillColor: Colors.blue.withValues(alpha: 0.1),
                      borderWidth: 1.5,
                      enableShadows: true,
                      enableGlow: true,
                    ),
                    size: Size.infinite,
                  ),
                  
                // DEBUG: Visual overlay showing element hit areas
                if (false) // Disabled - set to true for debugging
                  CustomPaint(
                    painter: _DebugHitAreaPainter(
                      view: widget.view,
                      zoomScale: _zoomScale,
                      panOffset: _panOffset,
                      cachedElementRects: _cachedElementRects,
                      cachedRelationshipPaths: _cachedRelationshipPaths,
                    ),
                    size: Size.infinite,
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }

  // Variables for scale gesture handling
  Offset? _lastFocalPoint;
  double _lastZoomScale = 1.0;
  bool _isDraggingElement = false;

  /// Unified scale start handler that handles both pan/zoom and element dragging
  void _handleUnifiedScaleStart(ScaleStartDetails details) {
    print('DEBUG: === UnifiedScaleStart START ===');
    print('DEBUG:   focalPoint: ${details.focalPoint}');
    print('DEBUG:   pointerCount: ${details.pointerCount}');
    print('DEBUG:   Current _isDraggingElement: $_isDraggingElement');
    print('DEBUG:   Current _selectionMode: $_selectionMode');
    
    // Reset drag state
    _isDraggingElement = false;
    _isDraggingRelationship = false;
    _draggedRelationshipId = null;
    print('DEBUG:   Reset _isDraggingElement to false');
    
    // Single pointer - could be drag or pan
    if (details.pointerCount == 1) {
      // Get the render box to convert global to local coordinates
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      if (box == null) {
        print('DEBUG:   RenderBox is null, cannot convert coordinates');
        return;
      }
      
      // Convert global focalPoint to local coordinates
      final localPosition = box.globalToLocal(details.focalPoint);
      
      print('DEBUG:   details.focalPoint (global): ${details.focalPoint}');
      print('DEBUG:   localPosition: $localPosition');
      print('DEBUG:   _panOffset: $_panOffset');
      print('DEBUG:   _zoomScale: $_zoomScale');
      
      // Apply pan and zoom transformation
      final adjustedPoint = (localPosition - _panOffset) / _zoomScale;
      
      print('DEBUG:   Adjusted point: $adjustedPoint');
      
      // First check for relationship hit before element hit
      // This is important to allow dragging on relationships to add vertices
      DiagramHitTestResult hitTestResult = DiagramHitTestResult(
        type: DiagramHitTestResultType.none,
      );
      
      // Check for relationship hit first
      for (final entry in _cachedRelationshipPaths.entries) {
        final relationshipId = entry.key;
        final path = entry.value;
        
        if (path.length >= 2) {
          // Check if the point is near any segment of the relationship
          for (int i = 0; i < path.length - 1; i++) {
            final distance = _distanceToLineSegment(adjustedPoint, path[i], path[i + 1]);
            if (distance <= 10) { // 10 pixel tolerance
              final relationship = widget.workspace.model
                  .getAllRelationships()
                  .firstWhere((r) => r.id == relationshipId);
              
              hitTestResult = DiagramHitTestResult(
                type: DiagramHitTestResultType.relationship,
                id: relationshipId,
                relationship: relationship,
              );
              print('DEBUG:   HIT! Relationship $relationshipId');
              break;
            }
          }
          
          if (hitTestResult.type == DiagramHitTestResultType.relationship) break;
        }
      }
      
      // If no relationship hit, check for element hit
      if (hitTestResult.type == DiagramHitTestResultType.none) {
        print('DEBUG:   Checking ${_cachedElementRects.length} cached element rects');
        
        if (_cachedElementRects.isEmpty) {
          print('DEBUG:   WARNING: _cachedElementRects is EMPTY!');
        } else {
          print('DEBUG:   Cached element rects:');
          for (final entry in _cachedElementRects.entries) {
            print('DEBUG:     ${entry.key}: ${entry.value}');
          }
        }
        
        for (final entry in _cachedElementRects.entries) {
          final elementId = entry.key;
          final elementRect = entry.value;
          
          print('DEBUG:   Checking element $elementId');
          print('DEBUG:     Rect: $elementRect');
          print('DEBUG:     Point: $adjustedPoint');
          print('DEBUG:     Contains? ${elementRect.contains(adjustedPoint)}');
          
          if (elementRect.contains(adjustedPoint)) {
            final element = widget.workspace.model.getElementById(elementId);
            if (element != null) {
              hitTestResult = DiagramHitTestResult(
                type: DiagramHitTestResultType.element,
                id: elementId,
                element: element,
              );
              print('DEBUG:   HIT! Element $elementId at rect: $elementRect');
              break;
            } else {
              print('DEBUG:   WARNING: Element $elementId not found in model!');
            }
          }
        }
      }
      
      print('DEBUG:   Hit test result: ${hitTestResult.type}, id: ${hitTestResult.id}');

      // Handle based on what we hit
      if (hitTestResult.type == DiagramHitTestResultType.relationship && widget.config.isEditable) {
        // We hit a relationship - start dragging to add a vertex
        print('DEBUG: >>> STARTING RELATIONSHIP DRAG (for vertex addition) <<<');
        print('DEBUG:   Relationship ID: ${hitTestResult.id}');
        _isDraggingRelationship = true;
        _draggedRelationshipId = hitTestResult.id;
        _relationshipDragStartPoint = adjustedPoint;
        print('DEBUG:   Set _isDraggingRelationship to true');
        return;
      } else if (hitTestResult.type == DiagramHitTestResultType.element && widget.config.isEditable) {
        // We hit an element - start dragging
        print('DEBUG: >>> STARTING ELEMENT DRAG <<<');
        print('DEBUG:   Element ID: ${hitTestResult.id}');
        _isDraggingElement = true;
        print('DEBUG:   Set _isDraggingElement to true');
        
        // Call pan start which will set selection mode to dragging
        print('DEBUG: >>> PASSING TO _handlePanStart <<<');
        print('DEBUG:   Creating DragStartDetails with:');
        print('DEBUG:     localPosition: ${localPosition}');  // Use the converted local position
        print('DEBUG:     globalPosition: ${details.focalPoint}');
        _handlePanStart(DragStartDetails(
          localPosition: localPosition,  // Use the converted local position!
          globalPosition: details.focalPoint,
        ));
        print('DEBUG:   After _handlePanStart, _selectionMode: $_selectionMode');
        return;
      } else if ((_isCtrlPressed || _isShiftPressed) && widget.config.isEditable) {
        // Modifier keys - start lasso selection
        print('DEBUG: >>> STARTING LASSO SELECTION <<<');
        _isDraggingElement = false;
        _handlePanStart(DragStartDetails(
          localPosition: details.focalPoint,
          globalPosition: details.focalPoint,
        ));
        return;
      }
    }

    // Only allow pan/zoom if we're not dragging an element
    if (!_isDraggingElement && widget.config.enablePanAndZoom) {
      print('DEBUG: >>> STARTING REGULAR PAN/ZOOM <<<');
      _lastFocalPoint = details.focalPoint;
      _lastZoomScale = 1.0;
      _animationController.stop();
      _zoomAnimation = null;
      _panAnimation = null;
    }
    print('DEBUG: === UnifiedScaleStart END ===');
  }

  /// Handles the start of a scale gesture
  void _handleScaleStart(ScaleStartDetails details) {
    _lastFocalPoint = details.focalPoint;
    _lastZoomScale = 1.0;

    // Cancel any active animations
    _animationController.stop();
    _zoomAnimation = null;
    _panAnimation = null;
  }

  /// Unified scale update handler
  void _handleUnifiedScaleUpdate(ScaleUpdateDetails details) {
    print('DEBUG: === UnifiedScaleUpdate START ===');
    print('DEBUG:   isDraggingElement: $_isDraggingElement');
    print('DEBUG:   isDraggingRelationship: $_isDraggingRelationship');
    print('DEBUG:   selectionMode: $_selectionMode');
    print('DEBUG:   focalPoint: ${details.focalPoint}');
    print('DEBUG:   focalPointDelta: ${details.focalPointDelta}');
    print('DEBUG:   scale: ${details.scale}');
    print('DEBUG:   pointerCount: ${details.pointerCount}');
    print('DEBUG:   enablePanAndZoom: ${widget.config.enablePanAndZoom}');
    print('DEBUG:   isEditable: ${widget.config.isEditable}');
    
    // Check if we're dragging a relationship to add a vertex
    if (_isDraggingRelationship && _draggedRelationshipId != null) {
      // Track the current drag position
      print('DEBUG: >>> RELATIONSHIP DRAGGING UPDATE <<<');
      
      // Get the render box to convert coordinates
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      if (box != null) {
        final localPosition = box.globalToLocal(details.focalPoint);
        _relationshipDragCurrentPoint = (localPosition - _panOffset) / _zoomScale;
        print('DEBUG: Tracking relationship drag at: $_relationshipDragCurrentPoint');
      }
      
      // We could show a preview of where the vertex will be added here
      // For now, just track the drag position
      return;
    }
    
    // Check if we're dragging elements
    if (_isDraggingElement || _selectionMode == SelectionMode.dragging) {
      // Handle element dragging WITHOUT updating canvas pan
      print('DEBUG: >>> ELEMENT DRAGGING MODE <<<');
      
      // Convert to local coordinates
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      if (box == null) {
        print('DEBUG:   RenderBox is null in update');
        return;
      }
      final localPosition = box.globalToLocal(details.focalPoint);
      
      print('DEBUG:   Calling _handlePanUpdate with:');
      print('DEBUG:     globalPosition: ${details.focalPoint}');
      print('DEBUG:     localPosition: $localPosition');
      print('DEBUG:     delta: ${details.focalPointDelta}');
      _handlePanUpdate(DragUpdateDetails(
        localPosition: localPosition,
        globalPosition: details.focalPoint,
        delta: details.focalPointDelta,
      ));
      // Important: Do NOT update _panOffset when dragging elements
      print('DEBUG: >>> Returning early - NOT updating canvas pan <<<');
      return;
    } 
    
    // Check if we're doing lasso selection
    if (_selectionMode == SelectionMode.lasso) {
      // Handle lasso selection
      print('DEBUG: >>> LASSO SELECTION MODE <<<');
      _handlePanUpdate(DragUpdateDetails(
        localPosition: details.focalPoint,
        globalPosition: details.focalPoint,
        delta: details.focalPointDelta,
      ));
      // Lasso selection also shouldn't pan the canvas
      print('DEBUG: >>> Returning early - NOT updating canvas pan <<<');
      return;
    }
    
    // Only handle pan/zoom if we're not dragging elements and pan/zoom is enabled
    if (widget.config.enablePanAndZoom) {
      print('DEBUG: >>> PAN/ZOOM MODE <<<');
      // Handle pan/zoom
      if (_lastFocalPoint == null) {
        print('DEBUG: lastFocalPoint is null, returning');
        return;
      }

      setState(() {
        // Handle zoom with proper focal point
        if (details.scale != 1.0 && details.pointerCount == 2) {
          // Two-finger zoom
          print('DEBUG: Two-finger zoom detected');
          final targetZoomScale = (_zoomScale * details.scale / _lastZoomScale)
              .clamp(widget.config.minZoomScale, widget.config.maxZoomScale);

          // Calculate zoom around focal point
          final focalPointDelta = details.focalPoint - _lastFocalPoint!;
          final zoomDelta = targetZoomScale / _zoomScale;

          // Update pan to zoom around focal point
          _panOffset = _panOffset * zoomDelta + focalPointDelta * (1 - zoomDelta);
          _zoomScale = targetZoomScale;
          print('DEBUG: Updated zoom scale: $_zoomScale');
        } else {
          // Single finger pan - but only if we're not dragging elements
          final panDelta = details.focalPoint - _lastFocalPoint!;
          _panOffset += panDelta;
          print('DEBUG: Single finger pan - pan delta: $panDelta, new panOffset: $_panOffset');
        }

        _lastFocalPoint = details.focalPoint;
        _lastZoomScale = details.scale;

        // Apply viewport constraints
        _constrainViewport();
      });
    } else {
      print('DEBUG: >>> PAN/ZOOM DISABLED <<<');
    }
    print('DEBUG: === UnifiedScaleUpdate END ===');
  }

  /// Unified scale end handler
  void _handleUnifiedScaleEnd(ScaleEndDetails details) {
    print('DEBUG: UnifiedScaleEnd - isDraggingElement: $_isDraggingElement, isDraggingRelationship: $_isDraggingRelationship, selectionMode: $_selectionMode');
    
    // Handle relationship drag end for vertex addition
    if (_isDraggingRelationship && _draggedRelationshipId != null) {
      print('DEBUG: >>> ENDING RELATIONSHIP DRAG <<<');
      
      // Use the last tracked drag position
      if (_relationshipDragCurrentPoint != null) {
        print('DEBUG: Adding vertex at drop position: $_relationshipDragCurrentPoint');
        
        // Add the vertex at the drop position
        _addVertexToRelationship(_draggedRelationshipId!, _relationshipDragCurrentPoint!);
      } else {
        print('DEBUG: No current drag point tracked');
      }
      
      // Reset relationship drag state
      _isDraggingRelationship = false;
      _draggedRelationshipId = null;
      _relationshipDragStartPoint = null;
      _relationshipDragCurrentPoint = null;
      return;
    }
    
    if (_isDraggingElement || _selectionMode == SelectionMode.lasso || _selectionMode == SelectionMode.dragging) {
      // End element dragging or lasso selection
      _handlePanEnd(DragEndDetails());
      _isDraggingElement = false;
    } else {
      // End pan/zoom
      _handleScaleEnd(details);
    }
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
    
    // Check if shift is pressed for vertex manipulation
    final isShiftPressed = _isShiftPressed;

    // Get the actual render box
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) {
      print('DEBUG: RenderBox is null, cannot perform hit test');
      return;
    }
    
    final canvasSize = box.size;
    
    print('DEBUG: ===== HIT TEST DEBUG =====');
    print('DEBUG: Tap at global: ${details.globalPosition}');
    print('DEBUG: Tap at local: ${details.localPosition}');
    print('DEBUG: Canvas size: $canvasSize');
    print('DEBUG: Current pan offset: $_panOffset');
    print('DEBUG: Current zoom scale: $_zoomScale');
    
    // Debug: Let's trace the coordinate transformation step by step
    final step1 = details.localPosition - _panOffset;
    print('DEBUG: Step 1 (localPos - panOffset): $step1');
    
    final adjustedPoint = step1 / _zoomScale;
    print('DEBUG: Step 2 (step1 / zoomScale): $adjustedPoint');
    
    // Store the adjusted tap position for vertex addition
    _lastTapPosition = adjustedPoint;
    
    print('DEBUG: View has ${widget.view.elements.length} elements');

    // Use the cached element rectangles from the actual DiagramPainter
    print('DEBUG: Using cached element rectangles: $_cachedElementRects');
    
    DiagramHitTestResult hitTestResult = DiagramHitTestResult(
      type: DiagramHitTestResultType.none,
    );
    
    // Check each element using the cached rectangles
    for (final entry in _cachedElementRects.entries) {
      final elementId = entry.key;
      final elementRect = entry.value;
      
      print('DEBUG: Checking element $elementId at rect: $elementRect');
      print('DEBUG:   - Adjusted point: $adjustedPoint');
      print('DEBUG:   - Contains point? ${elementRect.contains(adjustedPoint)}');
      
      if (elementRect.contains(adjustedPoint)) {
        final element = widget.workspace.model.getElementById(elementId);
        if (element != null) {
          print('DEBUG: HIT! Element $elementId (${element.name})');
          hitTestResult = DiagramHitTestResult(
            type: DiagramHitTestResultType.element,
            id: elementId,
            element: element,
          );
          break;
        }
      }
    }
    
    // If no element hit, check relationships
    if (hitTestResult.type == DiagramHitTestResultType.none) {
      print('DEBUG: No element hit, checking relationships...');
      print('DEBUG: Cached relationship paths: $_cachedRelationshipPaths');
      
      // Check each relationship path
      for (final entry in _cachedRelationshipPaths.entries) {
        final relationshipId = entry.key;
        final path = entry.value;
        
        if (path.length < 2) continue;
        
        // Check if click is near the relationship line
        const hitThreshold = 10.0; // pixels
        
        // For each segment in the path
        for (int i = 0; i < path.length - 1; i++) {
          final start = path[i];
          final end = path[i + 1];
          
          // Calculate distance from point to line segment
          final distance = _distanceToLineSegment(adjustedPoint, start, end);
          
          if (distance <= hitThreshold) {
            final relationship = widget.workspace.model
                .getAllRelationships()
                .firstWhere((r) => r.id == relationshipId,
                    orElse: () => throw Exception('Relationship not found'));
            
            print('DEBUG: HIT! Relationship $relationshipId');
            hitTestResult = DiagramHitTestResult(
              type: DiagramHitTestResultType.relationship,
              id: relationshipId,
              relationship: relationship,
            );
            break;
          }
        }
        
        if (hitTestResult.type != DiagramHitTestResultType.none) break;
      }
    }
    
    print('DEBUG: Manual hit test result: ${hitTestResult.type}, id: ${hitTestResult.id}');
    print('DEBUG: ===== END HIT TEST DEBUG =====');
    
    _processHitTestResult(hitTestResult);
  }
  
  /// Process the hit test result and update selection
  void _processHitTestResult(DiagramHitTestResult hitTestResult) {
    print('DEBUG: Processing hit test result: type=${hitTestResult.type}, id=${hitTestResult.id}');

    // Check if Ctrl/Cmd key is pressed for multi-selection
    bool isMultiSelectModifierPressed = _isCtrlPressed;

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
        if (widget.onElementSelected != null &&
            hitTestResult.element != null &&
            _selectedId != null) {
          widget.onElementSelected!(_selectedId!, hitTestResult.element!);
        }
      } else if (hitTestResult.type == DiagramHitTestResultType.relationship) {
        // Check if shift is pressed for vertex addition
        if (_isShiftPressed && widget.config.isEditable) {
          // Add vertex to the relationship at the click point
          final adjustedPoint = _lastTapPosition;
          if (adjustedPoint != null) {
            _addVertexToRelationship(hitTestResult.id!, adjustedPoint);
          }
        } else {
          // Normal relationship selection
          _selectedIds.clear();
          _selectedId = hitTestResult.id;
          if (widget.onRelationshipSelected != null &&
              hitTestResult.relationship != null) {
            widget.onRelationshipSelected!(
                _selectedId!, hitTestResult.relationship!);
          }
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

  /// New handlers that can handle both panning and element dragging
  void _handleEditablePanStart(DragStartDetails details) {
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
      // If we hit an element, handle it for dragging
      if (hitTestResult.type == DiagramHitTestResultType.element) {
        // Call the original pan start for element handling
        _handlePanStart(details);
      } else if (widget.config.enablePanAndZoom && !_isCtrlPressed && !_isShiftPressed) {
        // If pan/zoom is enabled and no modifier keys, start panning
        _lastFocalPoint = details.localPosition;
      } else {
        // Otherwise start lasso selection
        _handlePanStart(details);
      }
    });
  }

  void _handleEditablePanUpdate(DragUpdateDetails details) {
    if (!widget.config.isEditable) return;

    setState(() {
      // If we're in dragging or lasso mode, use the original handler
      if (_selectionMode == SelectionMode.dragging || _selectionMode == SelectionMode.lasso) {
        _handlePanUpdate(details);
      } else if (widget.config.enablePanAndZoom && _lastFocalPoint != null) {
        // Handle canvas panning
        _panOffset += details.localPosition - _lastFocalPoint!;
        _lastFocalPoint = details.localPosition;
        _constrainViewport();
      }
    });
  }

  void _handleEditablePanEnd(DragEndDetails details) {
    if (!widget.config.isEditable) return;

    setState(() {
      // If we're in dragging or lasso mode, use the original handler
      if (_selectionMode == SelectionMode.dragging || _selectionMode == SelectionMode.lasso) {
        _handlePanEnd(details);
      } else {
        // Reset pan state
        _lastFocalPoint = null;
      }
    });
  }

  /// Handles the start of a pan gesture for lasso selection or element dragging
  void _handlePanStart(DragStartDetails details) {
    print('DEBUG: === _handlePanStart START ===');
    print('DEBUG: === COORDINATE TRACKING ===');
    print('DEBUG:   [1] Raw Input:');
    print('DEBUG:       localPosition: ${details.localPosition}');
    print('DEBUG:       globalPosition: ${details.globalPosition}');
    print('DEBUG:   [2] Transform Parameters:');
    print('DEBUG:       panOffset: $_panOffset');
    print('DEBUG:       zoomScale: $_zoomScale');
    print('DEBUG:   [3] Widget State:');
    print('DEBUG:       isEditable: ${widget.config.isEditable}');
    print('DEBUG:       Ctrl pressed: $_isCtrlPressed');
    print('DEBUG:       Shift pressed: $_isShiftPressed');
    
    if (!widget.config.isEditable) {
      print('DEBUG: Not editable, returning');
      return;
    }

    // Adjust point for current pan and zoom
    print('DEBUG:   [4] Coordinate Transformation:');
    print('DEBUG:       Step 1: localPosition - panOffset = ${details.localPosition} - $_panOffset = ${details.localPosition - _panOffset}');
    final step1 = details.localPosition - _panOffset;
    print('DEBUG:       Step 2: step1 / zoomScale = $step1 / $_zoomScale = ${step1 / _zoomScale}');
    final adjustedPoint = step1 / _zoomScale;
    print('DEBUG:       Final adjustedPoint: $adjustedPoint');
    print('DEBUG:   [5] Hit Testing:');
    print('DEBUG:       cachedElementRects count: ${_cachedElementRects.length}');

    // Use cached element rectangles for hit testing
    DiagramHitTestResult hitTestResult = DiagramHitTestResult(
      type: DiagramHitTestResultType.none,
    );
    
    for (final entry in _cachedElementRects.entries) {
      final elementId = entry.key;
      final elementRect = entry.value;
      
      print('DEBUG:   Checking element $elementId at rect: $elementRect');
      if (elementRect.contains(adjustedPoint)) {
        final element = widget.workspace.model.getElementById(elementId);
        if (element != null) {
          hitTestResult = DiagramHitTestResult(
            type: DiagramHitTestResultType.element,
            id: elementId,
            element: element,
          );
          print('DEBUG:   HIT! Element $elementId');
          break;
        }
      }
    }

    print('DEBUG:   Hit test result: ${hitTestResult.type}, id: ${hitTestResult.id}');

    setState(() {
      // If we hit an element, prepare for dragging
      if (hitTestResult.type == DiagramHitTestResultType.element) {
        print('DEBUG: >>> PREPARING ELEMENT DRAG <<<');
        print('DEBUG:   Hit element ${hitTestResult.id} for dragging');
        
        // If the element isn't already selected, select it first
        if (!_selectedIds.contains(hitTestResult.id!)) {
          print('DEBUG:   Element not selected, selecting it first');
          _selectedId = hitTestResult.id;
          _selectedIds.clear();
          _selectedIds.add(hitTestResult.id!);

          if (widget.onElementSelected != null &&
              hitTestResult.element != null) {
            widget.onElementSelected!(
                hitTestResult.id!, hitTestResult.element!);
          }
        }
        
        _selectionMode = SelectionMode.dragging;
        _lastPointerPosition = adjustedPoint;
        print('DEBUG:   [7] Drag State Initialization:');
        print('DEBUG:       Set selection mode to DRAGGING');
        print('DEBUG:       Set lastPointerPosition: $adjustedPoint');

        // Store original positions for all selected elements
        _originalElementPositions = {};
        _currentElementPositions = {};

        print('DEBUG:   [8] Element Position Capture:');
        print('DEBUG:       Selected elements count: ${_selectedIds.length}');
        for (final elementId in _selectedIds) {
          // Use cached element rectangles to get current position
          final rect = _cachedElementRects[elementId];
          if (rect != null) {
            final position = rect.topLeft;
            _originalElementPositions[elementId] = position;
            _currentElementPositions[elementId] = position;
            print('DEBUG:       Element $elementId:');
            print('DEBUG:         Cached rect: $rect');
            print('DEBUG:         Initial position (topLeft): $position');
          } else {
            print('DEBUG:       WARNING: No cached rect for element $elementId');
          }
        }
        print('DEBUG:       originalElementPositions count: ${_originalElementPositions.length}');
        print('DEBUG:       currentElementPositions count: ${_currentElementPositions.length}');
      } else {
        // Start lasso selection
        print('DEBUG: >>> STARTING LASSO SELECTION <<<');
        _selectionMode = SelectionMode.lasso;
        _lassoSelection.start(adjustedPoint);
      }
    });
    print('DEBUG: === _handlePanStart END ===');
  }

  /// Handles updates during a pan gesture for lasso selection or element dragging
  void _handlePanUpdate(DragUpdateDetails details) {
    print('DEBUG: === _handlePanUpdate START ===');
    print('DEBUG:   isEditable: ${widget.config.isEditable}');
    print('DEBUG:   selectionMode: $_selectionMode');
    print('DEBUG:   localPosition: ${details.localPosition}');
    print('DEBUG:   delta: ${details.delta}');
    print('DEBUG:   panOffset: $_panOffset');
    print('DEBUG:   zoomScale: $_zoomScale');
    
    if (!widget.config.isEditable) {
      print('DEBUG: Not editable, returning');
      return;
    }

    // Adjust point for current pan and zoom
    final adjustedPoint = (details.localPosition - _panOffset) / _zoomScale;
    print('DEBUG:   adjustedPoint: $adjustedPoint');

    setState(() {
      if (_selectionMode == SelectionMode.lasso && _lassoSelection.isActive) {
        // Update lasso selection
        print('DEBUG: Updating lasso selection');
        _lassoSelection.update(adjustedPoint);
      } else if (_selectionMode == SelectionMode.dragging &&
          _lastPointerPosition != null) {
        // Calculate the delta movement
        print('DEBUG: >>> ELEMENT DRAGGING UPDATE <<<');
        print('DEBUG: === DRAG COORDINATE ANALYSIS ===');
        print('DEBUG:   [1] Previous State:');
        print('DEBUG:       lastPointerPosition: $_lastPointerPosition');
        print('DEBUG:   [2] Current Input:');
        print('DEBUG:       adjustedPoint: $adjustedPoint');
        print('DEBUG:   [3] Delta Calculation:');
        print('DEBUG:       delta = adjustedPoint - lastPointerPosition');
        print('DEBUG:       delta = $adjustedPoint - $_lastPointerPosition');
        final delta = adjustedPoint - _lastPointerPosition!;
        print('DEBUG:       calculated delta: $delta');
        _lastPointerPosition = adjustedPoint;
        print('DEBUG:   [4] Updated State:');
        print('DEBUG:       new lastPointerPosition: $_lastPointerPosition');
        print('DEBUG:       selected elements count: ${_currentElementPositions.length}');

        // Update positions for all selected elements
        _temporaryElementPositions = {};

        for (final entry in _currentElementPositions.entries) {
          final elementId = entry.key;
          final currentPosition = entry.value;

          // Calculate new position
          final newPosition = currentPosition + delta;
          _currentElementPositions[elementId] = newPosition;
          _temporaryElementPositions![elementId] = newPosition;
          
          print('DEBUG:   Moving element $elementId:');
          print('DEBUG:     from: $currentPosition');
          print('DEBUG:     to: $newPosition');
        }
        
        print('DEBUG:   temporaryElementPositions set: ${_temporaryElementPositions != null}');
        print('DEBUG:   temporaryElementPositions count: ${_temporaryElementPositions?.length ?? 0}');
        
        // The repaint will happen automatically because we're in setState
      } else {
        print('DEBUG: No action taken - mode: $_selectionMode, lastPointerPosition: $_lastPointerPosition');
      }
    });
    print('DEBUG: === _handlePanUpdate END ===');
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
      } else if (_selectionMode == SelectionMode.dragging &&
          _lastPointerPosition != null) {
        print('DEBUG: === _handlePanEnd - APPLYING FINAL POSITIONS ===');
        // Apply the element position changes using immutable updates
        if (_currentElementPositions.isNotEmpty) {
          print('DEBUG: Current element positions to apply:');
          for (final entry in _currentElementPositions.entries) {
            print('DEBUG:   ${entry.key}: ${entry.value}');
          }
          
          // Create immutable updates through proper extension methods
          final updatedElementViews = <ElementView>[];

          for (final entry in _currentElementPositions.entries) {
            final elementId = entry.key;
            final newPosition = entry.value;

            // Get the original element view
            final originalView = widget.view.getElementById(elementId);
            if (originalView != null) {
              print('DEBUG: Creating updated view for $elementId');
              print('DEBUG:   Original position: x=${originalView.x}, y=${originalView.y}');
              print('DEBUG:   New position: x=${newPosition.dx.round()}, y=${newPosition.dy.round()}');
              
              // Create an updated view with the new position using extension method
              final updatedView = originalView.copyWithPosition(
                newPosition.dx.round(),
                newPosition.dy.round(),
              );
              updatedElementViews.add(updatedView);
            } else {
              print('DEBUG: WARNING: Could not find element view for $elementId');
            }
          }

          print('DEBUG: Created ${updatedElementViews.length} updated views');
          
          // Update the view's element positions
          print('DEBUG: Updating view element positions...');
          
          // Since views are immutable, we need to update the elements in the view
          for (final updatedView in updatedElementViews) {
            // Find the element in the view and update its position
            final index = widget.view.elements.indexWhere((e) => e.id == updatedView.id);
            if (index != -1) {
              // Update the element view's position
              widget.view.elements[index] = updatedView;
              print('DEBUG: Updated position for ${updatedView.id} in view.elements');
            }
          }
          
          // Force the diagram painter to recalculate layouts with new positions
          _cachedElementRects.clear();
          _cachedRelationshipPaths.clear();
          
          // Notify about the movement with the updated positions
          if (widget.onElementsMoved != null) {
            print('DEBUG: Calling onElementsMoved callback');
            widget.onElementsMoved!(_currentElementPositions);
          } else {
            print('DEBUG: No onElementsMoved callback provided');
          }
        }

        // Reset drag state
        print('DEBUG: Resetting drag state');
        _lastPointerPosition = null;
        _originalElementPositions = {};
        _currentElementPositions = {};
        _temporaryElementPositions = null; // Clear temporary positions
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
      final relationship = widget.workspace.model
          .getAllRelationships()
          .firstWhere((r) => r.id == relationshipId,
              orElse: () => throw Exception('Relationship not found'));

      // Get the relationship view with potential vertices
      final relationshipView = widget.view.getRelationshipById(relationshipId);

      // Path intersection flag
      bool pathIntersects = false;

      // Check vertices if available in the relationship view
      if (relationshipView != null && relationshipView.vertices.isNotEmpty) {
        // Create a list of vertex points
        final vertexPoints = relationshipView.vertices
            .where((v) => v.y != null)
            .map((v) => Offset(v.x.toDouble(), v.y.toDouble()))
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
          if (path.isNotEmpty &&
              vertexPoints.isNotEmpty &&
              _lassoSelection.intersectsRelationship(
                  path.first, vertexPoints.first)) {
            pathIntersects = true;
          }

          // Check between vertices
          if (!pathIntersects) {
            for (int i = 0; i < vertexPoints.length - 1; i++) {
              if (_lassoSelection.intersectsRelationship(
                  vertexPoints[i], vertexPoints[i + 1])) {
                pathIntersects = true;
                break;
              }
            }
          }

          // Check last vertex to target
          if (!pathIntersects &&
              path.isNotEmpty &&
              vertexPoints.isNotEmpty &&
              _lassoSelection.intersectsRelationship(
                  vertexPoints.last, path.last)) {
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
                    path[i].dy + (path[i + 1].dy - path[i].dy) * t);

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
          pathIntersects =
              _lassoSelection.intersectsRelationship(path.first, path.last);
        }
      }

      // Check endpoints as well (source and target)
      if (!pathIntersects && path.isNotEmpty) {
        if (path.length >= 2 &&
            (_lassoSelection.containsPoint(path.first) ||
                _lassoSelection.containsPoint(path.last))) {
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
            selectedElementIds, selectedRelationshipIds);
      } else if (_selectedId != null) {
        // Fall back to single selection callback if no multi-selection callback
        final element = widget.workspace.model.getElementById(_selectedId!);
        if (element != null && widget.onElementSelected != null) {
          widget.onElementSelected!(_selectedId!, element);
        } else {
          final relationship = widget.workspace.model
              .getAllRelationships()
              .firstWhere((r) => r.id == _selectedId!,
                  orElse: () => throw Exception('Relationship not found'));
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
    // Debug logging
    print('DEBUG: Mouse hover at: ${event.localPosition}');
    
    // This method was using the broken DiagramPainter hit test
    // Let's skip it for now to focus on click detection
    return;
  }

  /// Zooms to fit all elements in the view
  void fitToScreen() {
    print('DEBUG: ===== FIT TO SCREEN CALLED =====');
    
    // Get render box for canvas size
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) {
      print('DEBUG: RenderBox is null');
      return;
    }
    
    final canvasSize = box.size;
    print('DEBUG: Canvas size for fit to screen: $canvasSize');
    
    // Use the cached element rectangles from the current diagram painter
    if (_cachedElementRects.isEmpty) {
      print('DEBUG: No cached element rectangles');
      return;
    }
    
    // Get the bounding box from the diagram painter if available
    Rect boundingBox;
    if (_currentDiagramPainter != null) {
      boundingBox = _currentDiagramPainter!.getBoundingBox();
      print('DEBUG: Got bounding box from painter: $boundingBox');
    } else {
      // Calculate bounds manually from cached rectangles
      double minX = double.infinity;
      double minY = double.infinity;
      double maxX = double.negativeInfinity;
      double maxY = double.negativeInfinity;
      
      for (final rect in _cachedElementRects.values) {
        minX = math.min(minX, rect.left);
        minY = math.min(minY, rect.top);
        maxX = math.max(maxX, rect.right);
        maxY = math.max(maxY, rect.bottom);
      }
      
      boundingBox = Rect.fromLTRB(minX, minY, maxX, maxY);
      print('DEBUG: Calculated bounding box manually: $boundingBox');
    }
    
    // Calculate centroid based on actual element positions
    double totalX = 0;
    double totalY = 0;
    int elementCount = 0;
    
    // Use the cached element rectangles which contain the actual rendered positions
    for (final entry in _cachedElementRects.entries) {
      final elementId = entry.key;
      final rect = entry.value;
      
      // Add to centroid calculation (use center of each element)
      totalX += rect.center.dx;
      totalY += rect.center.dy;
      elementCount++;
      
      print('DEBUG: Element $elementId rect: $rect, center: ${rect.center}');
    }
    
    if (elementCount == 0) {
      print('DEBUG: No elements to fit');
      return;
    }
    
    final centroid = Offset(totalX / elementCount, totalY / elementCount);
    
    print('DEBUG: Final bounding box: $boundingBox');
    print('DEBUG: Calculated centroid: $centroid');
    
    if (boundingBox.width == 0 || boundingBox.height == 0) {
      print('DEBUG: Invalid bounding box');
      return;
    }

    // Get the size of the widget
    final size = box.size;

    // Calculate the zoom scale needed to fit the bounding box
    final horizontalScale = size.width / boundingBox.width;
    final verticalScale = size.height / boundingBox.height;

    // Use the smaller scale to ensure everything fits
    final targetScale = math.min(horizontalScale, verticalScale) * 0.85; // 85% to add margin
    final clampedScale = targetScale.clamp(
        widget.config.minZoomScale, widget.config.maxZoomScale);

    // Calculate the pan offset to center the CENTROID (not bounding box center)
    final targetPanOffset = Offset(
      size.width / 2 - centroid.dx * clampedScale,
      size.height / 2 - centroid.dy * clampedScale,
    );
    
    print('DEBUG: Viewport size: $size');
    print('DEBUG: Target scale: $clampedScale'); 
    print('DEBUG: Using centroid for centering: $centroid');
    print('DEBUG: Target pan offset: $targetPanOffset');

    // Animate to the new zoom and pan
    animateToZoomAndPan(clampedScale, targetPanOffset);
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
        minX - paddingX, minY - paddingY, maxX + paddingX, maxY + paddingY);

    // Get the size of the widget
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    // Calculate the zoom scale needed to fit the selection
    final horizontalScale = size.width / selectionBounds.width;
    final verticalScale = size.height / selectionBounds.height;

    // Use the smaller scale to ensure everything fits
    final targetScale = math.min(horizontalScale, verticalScale);
    final constrainedScale = targetScale.clamp(
        widget.config.minZoomScale, widget.config.maxZoomScale);

    // Calculate the pan offset to center the selection
    final targetPanOffset = Offset(
      size.width / 2 - selectionBounds.center.dx * constrainedScale,
      size.height / 2 - selectionBounds.center.dy * constrainedScale,
    );

    // Animate to the new zoom and pan
    animateToZoomAndPan(constrainedScale, targetPanOffset);
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
    animateToZoomAndPan(_zoomScale, targetPanOffset);
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
  void animateToZoomAndPan(double targetScale, Offset targetPanOffset) {
    // Cancel any previous animations
    _animationController.stop();

    // Ensure the target scale is within bounds
    final constrainedScale = targetScale.clamp(
        widget.config.minZoomScale, widget.config.maxZoomScale);

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
    if (boundingBox == Rect.zero) {
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
    final boundedPanX =
        (panOffset.dx + (boundingBox.left * _zoomScale)).clamp(maxX, minX) -
            (boundingBox.left * _zoomScale);
    final boundedPanY =
        (panOffset.dy + (boundingBox.top * _zoomScale)).clamp(maxY, minY) -
            (boundingBox.top * _zoomScale);

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
      } else if (event.logicalKey == LogicalKeyboardKey.keyA &&
          _isCtrlPressed) {
        // Handle Ctrl+A to select all elements
        _selectAllElements();
      } else if (event.logicalKey == LogicalKeyboardKey.keyF &&
          _isCtrlPressed) {
        // Handle Ctrl+F to fit all elements to screen
        fitToScreen();
      } else if (event.logicalKey == LogicalKeyboardKey.keyE &&
          _isCtrlPressed) {
        // Handle Ctrl+E to zoom to selection (mnemonic: 'E'nlarge selection)
        if (_selectedIds.isNotEmpty) {
          zoomToSelection();
        }
      } else if (event.logicalKey == LogicalKeyboardKey.equal &&
          _isCtrlPressed) {
        // Handle Ctrl+ to zoom in
        setState(() {
          final newScale = (_zoomScale * 1.2)
              .clamp(widget.config.minZoomScale, widget.config.maxZoomScale);
          animateToZoomAndPan(newScale, _panOffset);
        });
      } else if (event.logicalKey == LogicalKeyboardKey.minus &&
          _isCtrlPressed) {
        // Handle Ctrl- to zoom out
        setState(() {
          final newScale = (_zoomScale / 1.2)
              .clamp(widget.config.minZoomScale, widget.config.maxZoomScale);
          animateToZoomAndPan(newScale, _panOffset);
        });
      } else if (event.logicalKey == LogicalKeyboardKey.digit0 &&
          _isCtrlPressed) {
        // Handle Ctrl+0 to reset zoom
        setState(() {
          animateToZoomAndPan(1.0, Offset.zero);
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
    
    // Check if we clicked on a vertex
    final vertexInfo = _findVertexAtPoint(adjustedPoint);
    if (vertexInfo != null) {
      _showVertexContextMenu(details.globalPosition, vertexInfo);
    } else {
      // Show regular context menu
      _showContextMenu(details.globalPosition, hitTestResult);
    }
  }

  /// Shows a context menu at the given position
  void _showContextMenu(Offset position, DiagramHitTestResult hitTestResult) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localPosition = box.globalToLocal(position);

    // Build the menu items based on the hit test result
    final List<PopupMenuEntry<String>> menuItems = [];

    if (hitTestResult.type == DiagramHitTestResultType.element &&
        hitTestResult.id != null) {
      // Element context menu
      final bool isSelected = _selectedIds.contains(hitTestResult.id);
      final element = hitTestResult.element;
      final elementType =
          element != null ? element.runtimeType.toString() : 'Element';

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
    } else if (hitTestResult.type == DiagramHitTestResultType.relationship &&
        hitTestResult.id != null) {
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
  void _handleContextMenuSelection(
      String? value, DiagramHitTestResult hitTestResult) {
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
              widget.onElementSelected!(
                  hitTestResult.id!, hitTestResult.element!);
            }
          }
          break;

        case 'select_only':
          if (hitTestResult.id != null && hitTestResult.element != null) {
            _selectedId = hitTestResult.id;
            _selectedIds.clear();
            _selectedIds.add(hitTestResult.id!);
            if (widget.onElementSelected != null) {
              widget.onElementSelected!(
                  hitTestResult.id!, hitTestResult.element!);
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
              widget.onRelationshipSelected!(
                  hitTestResult.id!, hitTestResult.relationship!);
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
            if (hitTestResult.element != null &&
                widget.onElementSelected != null) {
              widget.onElementSelected!(
                  hitTestResult.id!, hitTestResult.element!);
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

    if (hitTestResult.type == DiagramHitTestResultType.element &&
        hitTestResult.element != null) {
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
                  if (element.tags.isNotEmpty) ...[
                    const Text(
                      'Tags:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: element.tags.map((tag) {
                        return Chip(
                          label:
                              Text(tag, style: const TextStyle(fontSize: 10)),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Show properties if available
                  if (element.properties.isNotEmpty) ...[
                    const Text(
                      'Properties:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...element.properties.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry.key}: ',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
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
      final sourceElement =
          widget.workspace.model.getElementById(relationship.sourceId);
      final targetElement =
          widget.workspace.model.getElementById(relationship.destinationId);

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
                  if (relationship.tags.isNotEmpty) ...[
                    const Text(
                      'Tags:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: relationship.tags.map((tag) {
                        return Chip(
                          label:
                              Text(tag, style: const TextStyle(fontSize: 10)),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Show properties if available
                  if (relationship.properties.isNotEmpty) ...[
                    const Text(
                      'Properties:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...relationship.properties.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry.key}: ',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
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
    final showRelationshipDescriptions =
        widget.config.showRelationshipDescriptions;

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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
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
  
  
  /// Finds a vertex at the given point
  Map<String, dynamic>? _findVertexAtPoint(Offset point) {
    const double hitRadius = 10.0;
    
    for (final relationship in widget.view.relationships) {
      for (int i = 0; i < relationship.vertices.length; i++) {
        final vertex = relationship.vertices[i];
        final vertexPoint = Offset(vertex.x.toDouble(), vertex.y.toDouble());
        
        if ((vertexPoint - point).distance <= hitRadius) {
          return {
            'relationshipId': relationship.id,
            'vertexIndex': i,
            'vertex': vertex,
          };
        }
      }
    }
    
    return null;
  }
  
  /// Shows context menu for a vertex
  void _showVertexContextMenu(Offset position, Map<String, dynamic> vertexInfo) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localPosition = box.globalToLocal(position);
    
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        localPosition.dx,
        localPosition.dy,
        localPosition.dx,
        localPosition.dy,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'delete_vertex',
          child: Row(
            children: [
              Icon(Icons.delete, size: 16),
              SizedBox(width: 8),
              Text('Delete Vertex'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'delete_vertex') {
        _deleteVertex(vertexInfo);
      }
    });
  }
  
  /// Deletes a vertex from a relationship
  void _deleteVertex(Map<String, dynamic> vertexInfo) {
    final relationshipId = vertexInfo['relationshipId'] as String;
    final vertexIndex = vertexInfo['vertexIndex'] as int;
    
    print('DEBUG: Deleting vertex $vertexIndex from relationship $relationshipId');
    
    // Get the relationship view
    final relationshipView = widget.view.getRelationshipById(relationshipId);
    if (relationshipView == null) return;
    
    // Create updated vertices list without the selected vertex
    final updatedVertices = List<Vertex>.from(relationshipView.vertices);
    updatedVertices.removeAt(vertexIndex);
    
    // Notify parent about the vertex change
    if (widget.onRelationshipVerticesChanged != null) {
      widget.onRelationshipVerticesChanged!(relationshipId, updatedVertices);
      print('DEBUG: Notified parent about vertex deletion. Remaining vertices: ${updatedVertices.length}');
    } else {
      print('DEBUG: No onRelationshipVerticesChanged callback provided');
      // If no callback is provided, we can't update the view
      // Show a snackbar to inform the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vertex editing requires view update callback'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
    
    // Clear caches to force redraw
    _cachedRelationshipPaths.clear();
    
    setState(() {
      // Force a repaint
    });
  }

  /// Adds a vertex to a relationship at the specified point
  void _addVertexToRelationship(String relationshipId, Offset point) {
    print('DEBUG: Adding vertex to relationship $relationshipId at point $point');
    
    // Get the relationship view
    final relationshipView = widget.view.getRelationshipById(relationshipId);
    if (relationshipView == null) {
      print('DEBUG: Relationship view not found');
      return;
    }
    
    // Get the relationship path from cached paths
    final path = _cachedRelationshipPaths[relationshipId];
    if (path == null || path.length < 2) {
      print('DEBUG: No path found for relationship');
      return;
    }
    
    // Find the closest segment to insert the vertex
    double minDistance = double.infinity;
    int insertIndex = 0;
    
    for (int i = 0; i < path.length - 1; i++) {
      final distance = _distanceToLineSegment(point, path[i], path[i + 1]);
      if (distance < minDistance) {
        minDistance = distance;
        insertIndex = i + 1;
      }
    }
    
    // Create new vertex
    final newVertex = Vertex(
      x: point.dx.round(),
      y: point.dy.round(),
    );
    
    // Create updated vertices list
    final updatedVertices = List<Vertex>.from(relationshipView.vertices);
    
    // If this is the first vertex, just add it
    if (updatedVertices.isEmpty) {
      updatedVertices.add(newVertex);
    } else {
      // Insert at the appropriate position
      if (insertIndex <= updatedVertices.length) {
        updatedVertices.insert(insertIndex - 1, newVertex);
      } else {
        updatedVertices.add(newVertex);
      }
    }
    
    // Notify parent about the vertex change
    if (widget.onRelationshipVerticesChanged != null) {
      widget.onRelationshipVerticesChanged!(relationshipId, updatedVertices);
      print('DEBUG: Notified parent about vertex addition. Total vertices: ${updatedVertices.length}');
    } else {
      print('DEBUG: No onRelationshipVerticesChanged callback provided');
      // If no callback is provided, we can't update the view
      // Show a snackbar to inform the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vertex editing requires view update callback'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
    
    // Clear caches to force redraw
    _cachedRelationshipPaths.clear();
    
    setState(() {
      // Force a repaint
    });
  }

  /// Calculate distance from a point to a line segment
  double _distanceToLineSegment(Offset point, Offset lineStart, Offset lineEnd) {
    // Vector from lineStart to lineEnd
    final lineVec = lineEnd - lineStart;
    // Vector from lineStart to point
    final pointVec = point - lineStart;
    
    // Calculate the parameter t that represents the closest point on the line
    final lineLengthSquared = lineVec.dx * lineVec.dx + lineVec.dy * lineVec.dy;
    
    if (lineLengthSquared == 0) {
      // Line start and end are the same point
      return (point - lineStart).distance;
    }
    
    // Dot product
    final t = ((pointVec.dx * lineVec.dx) + (pointVec.dy * lineVec.dy)) / lineLengthSquared;
    
    // Clamp t to [0, 1] to handle points outside the line segment
    final clampedT = t.clamp(0.0, 1.0);
    
    // Find the closest point on the line segment
    final closestPoint = lineStart + lineVec * clampedT;
    
    // Return the distance from the point to the closest point on the line
    return (point - closestPoint).distance;
  }
}
