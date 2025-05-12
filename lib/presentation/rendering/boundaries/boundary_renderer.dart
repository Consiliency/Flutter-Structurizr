import 'dart:ui';

import 'package:flutter/material.dart' hide Element, Container, Border;
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/style/styles.dart' as styles;
import 'package:flutter_structurizr/domain/style/styles.dart' hide Border;
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/presentation/rendering/base_renderer.dart';

/// Renderer for boundary elements in a Structurizr diagram.
///
/// This renderer handles the visualization of container and enterprise boundaries
/// in architecture diagrams, providing visual grouping and nesting for elements.
class BoundaryRenderer extends BaseRenderer {
  /// Default padding around the boundary
  static const double defaultPadding = 20.0;
  
  /// Default padding between the label and the boundary box
  static const double labelPadding = 10.0;
  
  /// Default border radius for rounded boundaries
  static const double defaultBorderRadius = 12.0;
  
  /// Default opacity for boundaries
  static const double defaultOpacity = 0.3;
  
  /// Default label font size
  static const double defaultLabelFontSize = 14.0;
  
  /// Default stroke width
  static const double defaultStrokeWidth = 1.0;
  
  /// Default label background padding
  static const EdgeInsets labelBackgroundPadding = EdgeInsets.symmetric(
    horizontal: 8.0,
    vertical: 4.0,
  );

  /// Renders an enterprise boundary or container boundary
  @override
  void renderElement({
    required Canvas canvas,
    required Element element,
    required ElementView elementView,
    required ElementStyle style,
    bool selected = false,
  }) {
    // Calculate the boundary rect based on the container elements
    final rect = calculateElementBounds(
      element: element,
      elementView: elementView,
      style: style,
    );
    
    // Prepare background paint
    final backgroundPaint = Paint()
      ..color = style.background?.withOpacity(style.opacity / 100 * defaultOpacity) ?? 
                Colors.grey.withOpacity(defaultOpacity)
      ..style = PaintingStyle.fill;
    
    // Prepare border paint
    final borderPaint = Paint()
      ..color = style.stroke?.withOpacity(style.opacity / 100) ?? 
                Colors.grey.withOpacity(style.opacity / 100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.strokeWidth?.toDouble() ?? defaultStrokeWidth;
    
    // Apply custom border style if specified
    if (style.border == styles.Border.dashed) {
      final dashPattern = [6.0, 3.0]; // Dash pattern for boundaries
      _drawDashedRect(canvas, rect, borderPaint, dashPattern);
    } else if (style.border == styles.Border.dotted) {
      final dotPattern = [2.0, 2.0]; // Dot pattern for boundaries
      _drawDashedRect(canvas, rect, borderPaint, dotPattern);
    }
    
    // Determine what type of boundary we're rendering
    final isSoftwareSystem = element is SoftwareSystem;
    final isContainer = element is Container;
    final isEnterpriseBoundary = element.type == 'Enterprise';
    
    // Draw the boundary shape
    if (style.shape == Shape.roundedBox || isEnterpriseBoundary) {
      // Enterprise boundaries are typically shown as rounded rectangles
      final rrect = RRect.fromRectAndRadius(
        rect,
        const Radius.circular(defaultBorderRadius),
      );
      
      // Draw background and border
      canvas.drawRRect(rrect, backgroundPaint);
      if (style.border == styles.Border.solid) {
        canvas.drawRRect(rrect, borderPaint);
      }
    } else {
      // Default to rectangle for other boundaries
      canvas.drawRect(rect, backgroundPaint);
      if (style.border == styles.Border.solid) {
        canvas.drawRect(rect, borderPaint);
      }
    }
    
    // Draw selection indicator if selected
    if (selected) {
      final selectionPaint = Paint()
        ..color = Colors.blue.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      
      if (style.shape == Shape.roundedBox || isEnterpriseBoundary) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            rect.inflate(2.0),
            const Radius.circular(defaultBorderRadius + 2.0),
          ),
          selectionPaint,
        );
      } else {
        canvas.drawRect(rect.inflate(2.0), selectionPaint);
      }
    }
    
    // Render the boundary label
    _renderBoundaryLabel(canvas, element, rect, style);
  }
  
  /// Draws a dashed rectangle with the specified dash pattern
  void _drawDashedRect(
    Canvas canvas,
    Rect rect,
    Paint paint,
    List<double> pattern,
  ) {
    final Path path = Path();
    final double dashWidth = pattern[0];
    final double dashSpace = pattern[1];
    
    // Top edge
    double distance = 0.0;
    final double topLength = rect.width;
    
    while (distance < topLength) {
      final double nextDash = distance + dashWidth;
      path.moveTo(rect.left + distance, rect.top);
      path.lineTo(rect.left + (nextDash > topLength ? topLength : nextDash), rect.top);
      distance = nextDash + dashSpace;
    }
    
    // Right edge
    distance = 0.0;
    final double rightLength = rect.height;
    
    while (distance < rightLength) {
      final double nextDash = distance + dashWidth;
      path.moveTo(rect.right, rect.top + distance);
      path.lineTo(rect.right, rect.top + (nextDash > rightLength ? rightLength : nextDash));
      distance = nextDash + dashSpace;
    }
    
    // Bottom edge
    distance = 0.0;
    final double bottomLength = rect.width;
    
    while (distance < bottomLength) {
      final double nextDash = distance + dashWidth;
      path.moveTo(rect.right - distance, rect.bottom);
      path.lineTo(rect.right - (nextDash > bottomLength ? bottomLength : nextDash), rect.bottom);
      distance = nextDash + dashSpace;
    }
    
    // Left edge
    distance = 0.0;
    final double leftLength = rect.height;
    
    while (distance < leftLength) {
      final double nextDash = distance + dashWidth;
      path.moveTo(rect.left, rect.bottom - distance);
      path.lineTo(rect.left, rect.bottom - (nextDash > leftLength ? leftLength : nextDash));
      distance = nextDash + dashSpace;
    }
    
    canvas.drawPath(path, paint);
  }
  
  /// Renders the label for the boundary
  void _renderBoundaryLabel(Canvas canvas, Element element, Rect rect, ElementStyle style) {
    // Define the label text style
    final textStyle = TextStyle(
      color: style.color ?? Colors.black,
      fontSize: style.fontSize?.toDouble() ?? defaultLabelFontSize,
      fontWeight: FontWeight.bold,
    );
    
    // Create label text painter
    final labelText = element.name;
    final textPainter = createTextPainter(
      text: labelText,
      style: textStyle,
    );
    
    // Calculate label background rect
    final labelBackgroundRect = Rect.fromLTWH(
      rect.left + defaultPadding,
      rect.top - textPainter.height / 2,
      textPainter.width + labelBackgroundPadding.horizontal,
      textPainter.height + labelBackgroundPadding.vertical,
    );
    
    // Draw label background
    final labelBackgroundPaint = Paint()
      ..color = style.background?.withOpacity(0.9) ?? Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    
    // Draw rounded rectangle for label background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        labelBackgroundRect,
        const Radius.circular(4.0),
      ),
      labelBackgroundPaint,
    );
    
    // Draw the label border if needed
    if (style.border == styles.Border.solid) {
      final labelBorderPaint = Paint()
        ..color = style.stroke ?? Colors.grey
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          labelBackgroundRect,
          const Radius.circular(4.0),
        ),
        labelBorderPaint,
      );
    }
    
    // Position and paint the text
    textPainter.paint(
      canvas,
      Offset(
        rect.left + defaultPadding + labelBackgroundPadding.left,
        rect.top - textPainter.height / 2 + labelBackgroundPadding.top / 2,
      ),
    );
  }
  
  @override
  Rect calculateElementBounds({
    required Element element,
    required ElementView elementView,
    required ElementStyle style,
  }) {
    // If the view explicitly defines the boundary size, use it
    if (elementView.width != null && elementView.height != null) {
      return Rect.fromLTWH(
        elementView.x?.toDouble() ?? 0,
        elementView.y?.toDouble() ?? 0,
        elementView.width!.toDouble(),
        elementView.height!.toDouble(),
      );
    }
    
    // For software system or container boundaries, we'd typically
    // calculate this based on the contained elements plus padding
    double minWidth = style.width?.toDouble() ?? 200;
    double minHeight = style.height?.toDouble() ?? 150;
    
    // Use fixed dimensions if they are provided in the style
    return Rect.fromLTWH(
      elementView.x?.toDouble() ?? 0,
      elementView.y?.toDouble() ?? 0,
      minWidth,
      minHeight,
    );
  }
  
  /// Calculate boundary dimensions based on contained elements
  ///
  /// [containedElements] List of element views contained within this boundary
  /// [padding] Additional padding to add around the boundary
  Rect calculateBoundaryFromContainedElements(
    List<ElementView> containedElements,
    double padding,
  ) {
    if (containedElements.isEmpty) {
      // Default size if no elements
      return Rect.fromLTWH(0, 0, 200, 150);
    }
    
    // Find the min/max coordinates of contained elements
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;
    
    for (final element in containedElements) {
      final x = element.x?.toDouble() ?? 0;
      final y = element.y?.toDouble() ?? 0;
      final width = element.width?.toDouble() ?? 100;
      final height = element.height?.toDouble() ?? 80;
      
      minX = minX > x ? x : minX;
      minY = minY > y ? y : minY;
      maxX = maxX < (x + width) ? (x + width) : maxX;
      maxY = maxY < (y + height) ? (y + height) : maxY;
    }
    
    // Add padding
    return Rect.fromLTRB(
      minX - padding,
      minY - padding,
      maxX + padding,
      maxY + padding,
    );
  }
  
  @override
  bool hitTestElement({
    required Offset point,
    required Element element,
    required ElementView elementView,
    required ElementStyle style,
  }) {
    final rect = calculateElementBounds(
      element: element,
      elementView: elementView,
      style: style,
    );
    
    // Check if point is within the boundary rectangle
    return rect.contains(point);
  }
  
  @override
  void renderRelationship({
    required Canvas canvas,
    required Relationship relationship,
    required RelationshipView relationshipView,
    required RelationshipStyle style,
    required Rect sourceRect,
    required Rect targetRect,
    bool selected = false,
  }) {
    // Boundaries themselves don't render relationships
    // This is handled by the relationship renderer
  }
  
  @override
  Path calculateRelationshipPath({
    required Relationship relationship,
    required RelationshipView relationshipView,
    required RelationshipStyle style,
    required Rect sourceRect,
    required Rect targetRect,
  }) {
    // Boundaries don't define relationship paths
    return Path();
  }
  
  @override
  bool hitTestRelationship({
    required Offset point,
    required Relationship relationship,
    required RelationshipView relationshipView,
    required RelationshipStyle style,
    required Rect sourceRect,
    required Rect targetRect,
    double hitTolerance = 8.0,
  }) {
    // Boundaries don't have relationships to hit test
    return false;
  }
}