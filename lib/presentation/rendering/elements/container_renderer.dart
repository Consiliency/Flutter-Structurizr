import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart' hide Element, Container, Border;
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/presentation/rendering/base_renderer.dart';

/// A renderer for container elements in a Structurizr diagram.
///
/// This renderer supports box, rounded box, and cylinder styles for containers.
/// It handles styling and text rendering based on the container's properties.
class ContainerRenderer extends BaseRenderer {
  /// Default padding inside the container
  static const double defaultPadding = 16.0;
  
  /// Default border radius for rounded containers
  static const double defaultBorderRadius = 12.0;
  
  /// Default minimum width for the container
  static const double defaultMinWidth = 120.0;
  
  /// Default minimum height for the container
  static const double defaultMinHeight = 80.0;
  
  /// Height ratio for the cylinder cap
  static const double cylinderCapRatio = 0.1;
  
  @override
  void renderElement({
    required Canvas canvas,
    required Element element,
    required ElementView elementView,
    required ElementStyle style,
    bool selected = false,
    bool hovered = false,
    bool includeNames = true,
    bool includeDescriptions = false,
  }) {
    // Calculate the element bounds
    final rect = _calculateRenderRect(elementView);
    
    // Prepare paint objects
    final backgroundPaint = Paint()
      ..color = style.background?.withOpacity(style.opacity / 100) ?? 
                Colors.lightBlue.withOpacity(style.opacity / 100)
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = style.stroke?.withOpacity(style.opacity / 100) ?? 
                Colors.blue.withOpacity(style.opacity / 100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.strokeWidth?.toDouble() ?? 1.0;
    
    // Apply border style
    if (style.border == Border.dashed) {
      borderPaint.strokeJoin = StrokeJoin.round;
      // Set dashed effect
      const dashWidth = 4.0;
      const dashSpace = 4.0;
      final dashPattern = [dashWidth, dashSpace];
      // Flutter doesn't directly support path dashing, so we have to draw lines manually
      _applyDashPattern(canvas, rect, borderPaint, dashPattern);
    } else if (style.border == Border.dotted) {
      borderPaint.strokeJoin = StrokeJoin.round;
      // Set dotted effect
      const dotWidth = 2.0;
      const dotSpace = 2.0;
      final dashPattern = [dotWidth, dotSpace];
      _applyDashPattern(canvas, rect, borderPaint, dashPattern);
    } else {
      // Solid border
      borderPaint.strokeCap = StrokeCap.butt;
      borderPaint.strokeJoin = StrokeJoin.miter;
    }
    
    // Render based on shape
    switch (style.shape) {
      case Shape.box:
        canvas.drawRect(rect, backgroundPaint);
        if (style.border == Border.solid) {
          canvas.drawRect(rect, borderPaint);
        }
        break;
      
      case Shape.roundedBox:
        final rrect = RRect.fromRectAndRadius(
          rect, 
          const Radius.circular(defaultBorderRadius),
        );
        canvas.drawRRect(rrect, backgroundPaint);
        if (style.border == Border.solid) {
          canvas.drawRRect(rrect, borderPaint);
        }
        break;
      
      case Shape.cylinder:
        _drawCylinder(canvas, rect, backgroundPaint, borderPaint, style.border);
        break;
        
      case Shape.hexagon:
        _drawHexagon(canvas, rect, backgroundPaint, borderPaint, style.border);
        break;
        
      case Shape.pipe:
        _drawPipe(canvas, rect, backgroundPaint, borderPaint, style.border);
        break;
      
      default:
        // Fallback to box for other shapes
        canvas.drawRect(rect, backgroundPaint);
        if (style.border == Border.solid) {
          canvas.drawRect(rect, borderPaint);
        }
        break;
    }
    
    // If selected or hovered, draw a visual indicator
    if (selected || hovered) {
      final indicatorPaint = Paint()
        ..color = selected ? Colors.blue.withOpacity(0.5) : Colors.grey.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 2.0 : 1.5;
      
      // Draw indicator based on shape
      if (style.shape == Shape.roundedBox) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            rect.inflate(selected ? 2.0 : 1.5), 
            Radius.circular(defaultBorderRadius + (selected ? 2.0 : 1.5)),
          ), 
          indicatorPaint,
        );
      } else {
        // For other shapes, use a simple rectangle
        canvas.drawRect(rect.inflate(selected ? 2.0 : 1.5), indicatorPaint);
      }
      
      // Optional: add a subtle glow effect for hover state
      if (hovered && !selected) {
        final glowPaint = Paint()
          ..color = Colors.grey.withOpacity(0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;
        
        if (style.shape == Shape.roundedBox) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              rect.inflate(3.0),
              const Radius.circular(defaultBorderRadius + 3.0),
            ),
            glowPaint,
          );
        } else {
          canvas.drawRect(rect.inflate(3.0), glowPaint);
        }
      }
    }
    
    // Render text content
    _renderText(canvas, element, rect, style, includeNames, includeDescriptions);
  }
  
  /// Draws a cylinder shape
  void _drawCylinder(
    Canvas canvas, 
    Rect rect, 
    Paint fillPaint, 
    Paint strokePaint,
    Border border,
  ) {
    // Calculate dimensions for the cylinder
    final capHeight = rect.height * cylinderCapRatio;
    
    // Top ellipse (cap)
    final topRect = Rect.fromLTWH(
      rect.left, 
      rect.top, 
      rect.width, 
      capHeight * 2, // Needed because ellipse is centered in the rect
    );
    
    // Bottom ellipse (base)
    final bottomRect = Rect.fromLTWH(
      rect.left, 
      rect.bottom - capHeight * 2, 
      rect.width, 
      capHeight * 2,
    );
    
    // Body rectangle (sides)
    final bodyRect = Rect.fromLTWH(
      rect.left, 
      rect.top + capHeight, 
      rect.width, 
      rect.height - capHeight * 2,
    );
    
    // Draw the cylinder body
    final bodyPath = Path()
      ..moveTo(rect.left, rect.top + capHeight)
      ..lineTo(rect.left, rect.bottom - capHeight)
      ..arcTo(bottomRect, math.pi, math.pi, false)
      ..lineTo(rect.right, rect.top + capHeight)
      ..arcTo(topRect, 0, math.pi, false)
      ..close();
    
    canvas.drawPath(bodyPath, fillPaint);
    
    // Draw the elliptical cap on top
    final topCapPath = Path();
    topCapPath.addArc(topRect, 0, math.pi);
    
    if (border == Border.solid) {
      canvas.drawPath(bodyPath, strokePaint);
      canvas.drawPath(topCapPath, strokePaint);
    }
  }
  
  /// Draws a hexagon shape
  void _drawHexagon(
    Canvas canvas, 
    Rect rect, 
    Paint fillPaint, 
    Paint strokePaint, 
    Border border,
  ) {
    final path = Path();
    final halfWidth = rect.width / 2;
    final halfHeight = rect.height / 2;
    final center = rect.center;
    
    // Calculate the six points of the hexagon
    final double radius = math.min(halfWidth, halfHeight) * 0.95; // 95% to add a small margin
    
    path.moveTo(center.dx, center.dy - radius); // Top point
    
    for (int i = 1; i < 6; i++) {
      final angle = i * math.pi / 3;
      final x = center.dx + radius * math.sin(angle);
      final y = center.dy - radius * math.cos(angle);
      path.lineTo(x, y);
    }
    
    path.close();
    
    canvas.drawPath(path, fillPaint);
    if (border == Border.solid) {
      canvas.drawPath(path, strokePaint);
    }
  }
  
  /// Draws a pipe shape (horizontal cylinder)
  void _drawPipe(
    Canvas canvas, 
    Rect rect, 
    Paint fillPaint, 
    Paint strokePaint, 
    Border border,
  ) {
    // Calculate dimensions for the pipe
    final capWidth = rect.width * cylinderCapRatio;
    
    // Left circle (cap)
    final leftRect = Rect.fromLTWH(
      rect.left, 
      rect.top, 
      capWidth * 2, 
      rect.height,
    );
    
    // Right circle (cap)
    final rightRect = Rect.fromLTWH(
      rect.right - capWidth * 2, 
      rect.top, 
      capWidth * 2, 
      rect.height,
    );
    
    // Body rectangle (sides)
    final bodyRect = Rect.fromLTWH(
      rect.left + capWidth, 
      rect.top, 
      rect.width - capWidth * 2, 
      rect.height,
    );
    
    // Draw the pipe body
    final bodyPath = Path()
      ..moveTo(rect.left + capWidth, rect.top)
      ..lineTo(rect.right - capWidth, rect.top)
      ..arcTo(rightRect, -math.pi/2, math.pi, false)
      ..lineTo(rect.left + capWidth, rect.bottom)
      ..arcTo(leftRect, math.pi/2, math.pi, false)
      ..close();
    
    canvas.drawPath(bodyPath, fillPaint);
    
    if (border == Border.solid) {
      canvas.drawPath(bodyPath, strokePaint);
    }
  }
  
  /// Applies a dash or dot pattern to a rectangle border
  void _applyDashPattern(
    Canvas canvas,
    Rect rect,
    Paint paint,
    List<double> pattern,
  ) {
    final dashWidth = pattern[0];
    final dashSpace = pattern[1];
    
    final path = Path();
    double distance = 0;
    final perimeter = 2 * (rect.width + rect.height);
    
    while (distance < perimeter) {
      // Calculate the position on the perimeter
      final pos = distance % perimeter;
      
      // Determine which side of the rectangle we're on
      if (pos < rect.width) {
        // Top edge
        path.moveTo(rect.left + pos, rect.top);
        path.lineTo(rect.left + pos + dashWidth < rect.right ? 
                   rect.left + pos + dashWidth : rect.right, rect.top);
      } else if (pos < rect.width + rect.height) {
        // Right edge
        path.moveTo(rect.right, rect.top + pos - rect.width);
        path.lineTo(rect.right, 
                   rect.top + pos - rect.width + dashWidth < rect.bottom ? 
                   rect.top + pos - rect.width + dashWidth : rect.bottom);
      } else if (pos < 2 * rect.width + rect.height) {
        // Bottom edge
        path.moveTo(rect.right - (pos - rect.width - rect.height), rect.bottom);
        path.lineTo(rect.right - (pos - rect.width - rect.height) - dashWidth > rect.left ? 
                   rect.right - (pos - rect.width - rect.height) - dashWidth : rect.left, 
                   rect.bottom);
      } else {
        // Left edge
        path.moveTo(rect.left, rect.bottom - (pos - 2 * rect.width - rect.height));
        path.lineTo(rect.left, 
                   rect.bottom - (pos - 2 * rect.width - rect.height) - dashWidth > rect.top ? 
                   rect.bottom - (pos - 2 * rect.width - rect.height) - dashWidth : rect.top);
      }
      
      // Move to the next dash position
      distance += dashWidth + dashSpace;
    }
    
    canvas.drawPath(path, paint);
  }
  
  /// Renders the text for the element
  void _renderText(Canvas canvas, Element element, Rect rect, ElementStyle style, bool includeNames, bool includeDescriptions) {
    final padding = defaultPadding;
    
    // Adjust text rectangle based on shape
    Rect textRect;
    if (style.shape == Shape.cylinder) {
      final capHeight = rect.height * cylinderCapRatio;
      textRect = Rect.fromLTRB(
        rect.left + padding,
        rect.top + capHeight + padding, // Account for cylinder cap
        rect.right - padding,
        rect.bottom - capHeight - padding,
      );
    } else {
      textRect = Rect.fromLTRB(
        rect.left + padding,
        rect.top + padding,
        rect.right - padding,
        rect.bottom - padding,
      );
    }
    
    // Text style based on element style
    final textStyle = TextStyle(
      color: style.color ?? Colors.black,
      fontSize: style.fontSize?.toDouble() ?? 14.0,
      fontWeight: FontWeight.normal,
    );
    
    // Name of the element
    final nameTextPainter = createTextPainter(
      text: element.name,
      style: textStyle.copyWith(fontWeight: FontWeight.bold),
      maxWidth: textRect.width,
    );
    
    // Calculate the starting Y position for centering
    double nextY = textRect.top;
    double totalTextHeight = 0;
    
    // Only include name height if we're showing names
    if (includeNames) {
      totalTextHeight += nameTextPainter.height;
    }
    
    // Add description height if applicable and we're showing descriptions
    if (includeDescriptions && (style.description ?? true) && element.description != null) {
      final descTextPainter = createTextPainter(
        text: element.description!,
        style: textStyle,
        maxWidth: textRect.width,
      );
      if (includeNames) {
        totalTextHeight += 8; // 8px gap after name
      }
      totalTextHeight += descTextPainter.height;
    }
    
    // Type height if showing metadata
    if (style.metadata ?? false) {
      final typeTextPainter = createTextPainter(
        text: element.type,
        style: textStyle.copyWith(
          fontSize: (style.fontSize?.toDouble() ?? 14.0) - 2,
          fontStyle: FontStyle.italic,
        ),
        maxWidth: textRect.width,
      );
      if (totalTextHeight > 0) {
        totalTextHeight += 8; // 8px gap before type
      }
      totalTextHeight += typeTextPainter.height;
    }
    
    // Center the text block vertically in the available space
    if (totalTextHeight < textRect.height) {
      nextY = textRect.top + (textRect.height - totalTextHeight) / 2;
    }
    
    // Render name if we should show it
    if (includeNames) {
      nameTextPainter.paint(
        canvas, 
        Offset(textRect.left + (textRect.width - nameTextPainter.width) / 2, nextY),
      );
      nextY += nameTextPainter.height + 8; // 8px gap
    }
    
    // Render description if we should show it and it exists
    if (includeDescriptions && (style.description ?? true) && element.description != null) {
      final descTextPainter = createTextPainter(
        text: element.description!,
        style: textStyle,
        maxWidth: textRect.width,
      );
      
      // Only show description if there is space
      if (nextY + descTextPainter.height < textRect.bottom) {
        descTextPainter.paint(
          canvas, 
          Offset(
            textRect.left + (textRect.width - descTextPainter.width) / 2, 
            nextY,
          ),
        );
        nextY += descTextPainter.height + 8; // 8px gap
      }
    }
    
    // Optionally show type/metadata if specified in style
    if (style.metadata ?? false) {
      final typeTextPainter = createTextPainter(
        text: element.type,
        style: textStyle.copyWith(
          fontSize: (style.fontSize?.toDouble() ?? 14.0) - 2,
          fontStyle: FontStyle.italic,
        ),
        maxWidth: textRect.width,
      );
      
      // Only show type if there is space
      if (nextY + typeTextPainter.height < textRect.bottom) {
        typeTextPainter.paint(
          canvas, 
          Offset(
            textRect.left + (textRect.width - typeTextPainter.width) / 2, 
            nextY,
          ),
        );
      }
    }
  }
  
  @override
  Rect calculateElementBounds({
    required Element element,
    required ElementView elementView,
    required ElementStyle style,
  }) {
    // Use provided dimensions if available, otherwise calculate from text size
    if (elementView.width != null && elementView.height != null) {
      return Rect.fromLTWH(
        elementView.x?.toDouble() ?? 0,
        elementView.y?.toDouble() ?? 0,
        elementView.width!.toDouble(),
        elementView.height!.toDouble(),
      );
    }
    
    // Calculate width and height based on text
    double width = style.width?.toDouble() ?? defaultMinWidth;
    double height = style.height?.toDouble() ?? defaultMinHeight;
    
    // Text style for measuring
    final textStyle = TextStyle(
      fontSize: style.fontSize?.toDouble() ?? 14.0,
      fontWeight: FontWeight.normal,
    );
    
    // Measure name
    final nameTextPainter = createTextPainter(
      text: element.name,
      style: textStyle.copyWith(fontWeight: FontWeight.bold),
    );
    
    // Update dimensions based on name (add padding)
    width = math.max(width, nameTextPainter.width + defaultPadding * 2);
    
    // If description exists, measure it too
    if ((style.description ?? true) && element.description != null) {
      final descTextPainter = createTextPainter(
        text: element.description!,
        style: textStyle,
      );
      
      width = math.max(width, descTextPainter.width + defaultPadding * 2);
      height = math.max(
        height, 
        nameTextPainter.height + descTextPainter.height + defaultPadding * 3,
      );
    }
    
    // If metadata is shown, account for type text
    if (style.metadata ?? false) {
      final typeTextPainter = createTextPainter(
        text: element.type,
        style: textStyle.copyWith(
          fontSize: (style.fontSize?.toDouble() ?? 14.0) - 2,
          fontStyle: FontStyle.italic,
        ),
      );
      
      width = math.max(width, typeTextPainter.width + defaultPadding * 2);
      height = math.max(
        height, 
        (height + typeTextPainter.height + defaultPadding),
      );
    }
    
    // Return the calculated bounds
    return Rect.fromLTWH(
      elementView.x?.toDouble() ?? 0,
      elementView.y?.toDouble() ?? 0,
      width,
      height,
    );
  }
  
  /// Calculate the rendering rectangle based on the element view
  Rect _calculateRenderRect(ElementView elementView) {
    return Rect.fromLTWH(
      elementView.x?.toDouble() ?? 0,
      elementView.y?.toDouble() ?? 0,
      elementView.width?.toDouble() ?? defaultMinWidth,
      elementView.height?.toDouble() ?? defaultMinHeight,
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
    
    // For most shapes, a rectangle hit test is sufficient
    if (style.shape == Shape.box || 
        style.shape == Shape.roundedBox || 
        style.shape == Shape.cylinder ||
        style.shape == Shape.pipe) {
      return rect.contains(point);
    }
    
    // For hexagon, we need a more precise hit test
    if (style.shape == Shape.hexagon) {
      final halfWidth = rect.width / 2;
      final halfHeight = rect.height / 2;
      final center = rect.center;
      
      // Calculate the radius of the hexagon
      final radius = math.min(halfWidth, halfHeight) * 0.95;
      
      // Calculate distance from center
      final distance = (point - center).distance;
      
      // Check if point is within the hexagon's radius
      // This is a simplification - for perfect accuracy, we would check against each edge
      return distance <= radius;
    }
    
    // Default fallback
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
    bool hovered = false,
    bool includeDescription = true,
  }) {
    // This is handled by the relationship renderer, not the element renderer
  }
  
  @override
  Path calculateRelationshipPath({
    required Relationship relationship,
    required RelationshipView relationshipView,
    required RelationshipStyle style,
    required Rect sourceRect,
    required Rect targetRect,
  }) {
    // This is handled by the relationship renderer, not the element renderer
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
    // This is handled by the relationship renderer, not the element renderer
    return false;
  }
}