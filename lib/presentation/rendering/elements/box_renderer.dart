import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart' hide Element, Border;
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/presentation/rendering/base_renderer.dart';

/// A renderer for box-shaped elements in a Structurizr diagram.
///
/// This renderer handles rectangular elements with various styles including
/// box, rounded box, and folder shapes. It supports selection state visualization
/// and automatic text sizing.
class BoxRenderer extends BaseRenderer {
  /// Default padding inside the box
  static const double defaultPadding = 12.0;

  /// Default border radius for rounded boxes
  static const double defaultBorderRadius = 10.0;

  /// Default minimum width for the box
  static const double defaultMinWidth = 80.0;

  /// Default minimum height for the box
  static const double defaultMinHeight = 60.0;

  @override
  void renderElement({
    required Canvas canvas,
    required Element element,
    required ElementView elementView,
    required ElementStyle style,
    bool selected = false,
  }) {
    // Calculate the element bounds
    final rect = _calculateRenderRect(elementView);

    // Prepare paint objects
    final backgroundPaint = Paint()
      ..color = style.background?.withOpacity(style.opacity / 100) ?? 
                Colors.white.withOpacity(style.opacity / 100)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = style.stroke?.withOpacity(style.opacity / 100) ?? 
                Colors.grey.withOpacity(style.opacity / 100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.strokeWidth?.toDouble() ?? 1.0;

    if (style.border == Border.dashed) {
      borderPaint.strokeJoin = StrokeJoin.round;
      // Set dashed effect
      borderPaint.strokeCap = StrokeCap.square;
      borderPaint.shader = null;
      const dashWidth = 4.0;
      const dashSpace = 4.0;
      // Create a path dash effect
      final path = Path();
      for (double i = 0; i < rect.width + rect.height * 2; i += dashWidth + dashSpace) {
        if (i < rect.width) {
          path.moveTo(rect.left + i, rect.top);
          path.lineTo(rect.left + i + dashWidth < rect.right ? 
                     rect.left + i + dashWidth : rect.right, rect.top);
        } else if (i < rect.width + rect.height) {
          path.moveTo(rect.right, rect.top + i - rect.width);
          path.lineTo(rect.right, 
                     rect.top + i - rect.width + dashWidth < rect.bottom ? 
                     rect.top + i - rect.width + dashWidth : rect.bottom);
        } else {
          path.moveTo(rect.right - (i - rect.width - rect.height), rect.bottom);
          path.lineTo(rect.right - (i - rect.width - rect.height) - dashWidth > rect.left ? 
                     rect.right - (i - rect.width - rect.height) - dashWidth : rect.left, 
                     rect.bottom);
        }
      }
      canvas.drawPath(path, borderPaint);
    } else if (style.border == Border.dotted) {
      borderPaint.strokeJoin = StrokeJoin.round;
      // Set dotted effect
      borderPaint.strokeCap = StrokeCap.round;
      borderPaint.shader = null;
      const dotWidth = 2.0;
      const dotSpace = 2.0;
      // Create a path dash effect
      final path = Path();
      for (double i = 0; i < rect.width * 2 + rect.height * 2; i += dotWidth + dotSpace) {
        final pos = i % (rect.width * 2 + rect.height * 2);
        if (pos < rect.width) {
          // Top edge
          path.moveTo(rect.left + pos, rect.top);
          path.lineTo(rect.left + pos + dotWidth < rect.right ? 
                     rect.left + pos + dotWidth : rect.right, rect.top);
        } else if (pos < rect.width + rect.height) {
          // Right edge
          path.moveTo(rect.right, rect.top + pos - rect.width);
          path.lineTo(rect.right, 
                     rect.top + pos - rect.width + dotWidth < rect.bottom ? 
                     rect.top + pos - rect.width + dotWidth : rect.bottom);
        } else if (pos < rect.width * 2 + rect.height) {
          // Bottom edge
          path.moveTo(rect.right - (pos - rect.width - rect.height), rect.bottom);
          path.lineTo(rect.right - (pos - rect.width - rect.height) - dotWidth > rect.left ? 
                     rect.right - (pos - rect.width - rect.height) - dotWidth : rect.left, 
                     rect.bottom);
        } else {
          // Left edge
          path.moveTo(rect.left, rect.bottom - (pos - rect.width * 2 - rect.height));
          path.lineTo(rect.left, 
                     rect.bottom - (pos - rect.width * 2 - rect.height) - dotWidth > rect.top ? 
                     rect.bottom - (pos - rect.width * 2 - rect.height) - dotWidth : rect.top);
        }
      }
      canvas.drawPath(path, borderPaint);
    }
    
    // Render box based on shape
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

      case Shape.ellipse:
        // Draw ellipse using path (to ensure drawnPaths is not empty)
        final ellipsePath = Path();
        ellipsePath.addOval(rect);
        canvas.drawPath(ellipsePath, backgroundPaint);
        if (style.border == Border.solid) {
          canvas.drawPath(ellipsePath, borderPaint);
        }
        break;
      
      case Shape.folder:
        // Draw folder shape with a tab
        final folderPath = Path();
        final tabHeight = rect.height * 0.15;
        final tabWidth = rect.width * 0.3;
        
        // Draw tab
        folderPath.moveTo(rect.left, rect.top);
        folderPath.lineTo(rect.left + tabWidth, rect.top);
        folderPath.lineTo(rect.left + tabWidth, rect.top + tabHeight);
        folderPath.lineTo(rect.right, rect.top + tabHeight);
        folderPath.lineTo(rect.right, rect.bottom);
        folderPath.lineTo(rect.left, rect.bottom);
        folderPath.close();
        
        canvas.drawPath(folderPath, backgroundPaint);
        if (style.border == Border.solid) {
          canvas.drawPath(folderPath, borderPaint);
        }
        break;
      
      default:
        // Fallback to regular box for other shapes
        canvas.drawRect(rect, backgroundPaint);
        if (style.border == Border.solid) {
          canvas.drawRect(rect, borderPaint);
        }
        break;
    }

    // If selected, draw a selection indicator
    if (selected) {
      final selectionPaint = Paint()
        ..color = Colors.blue.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      
      // Draw selection indicator based on shape
      if (style.shape == Shape.roundedBox) {
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

    // Render the text
    _renderText(canvas, element, rect, style);
  }

  /// Renders the text for the element.
  void _renderText(Canvas canvas, Element element, Rect rect, ElementStyle style) {
    final padding = defaultPadding;
    final textRect = Rect.fromLTRB(
      rect.left + padding,
      rect.top + padding,
      rect.right - padding,
      rect.bottom - padding,
    );

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

    // Position the name at the top of the text rect
    final namePosY = textRect.top + (textRect.height - nameTextPainter.height) / 2;
    nameTextPainter.paint(
      canvas, 
      Offset(textRect.left + (textRect.width - nameTextPainter.width) / 2, namePosY),
    );

    // If we should show description and it exists
    if ((style.description ?? true) && element.description != null) {
      final descTextPainter = createTextPainter(
        text: element.description!,
        style: textStyle,
        maxWidth: textRect.width,
      );

      // Only show description if there is space
      if (namePosY + nameTextPainter.height + 8 + descTextPainter.height < textRect.bottom) {
        descTextPainter.paint(
          canvas, 
          Offset(
            textRect.left + (textRect.width - descTextPainter.width) / 2, 
            namePosY + nameTextPainter.height + 8,
          ),
        );
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
      
      // Position the type at the bottom of the text rect
      typeTextPainter.paint(
        canvas, 
        Offset(
          textRect.left + (textRect.width - typeTextPainter.width) / 2, 
          textRect.bottom - typeTextPainter.height,
        ),
      );
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
    
    // Update dimensions based on name
    width = math.max(width, nameTextPainter.width + defaultPadding * 2);
    height = math.max(height, nameTextPainter.height + defaultPadding * 2);
    
    // If description exists, measure it too
    if ((style.description ?? true) && element.description != null) {
      final descTextPainter = createTextPainter(
        text: element.description!,
        style: textStyle,
      );
      
      width = math.max(width, descTextPainter.width + defaultPadding * 2);
      height = math.max(height, nameTextPainter.height + descTextPainter.height + defaultPadding * 3);
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
    
    // Simple rectangle hit test
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

// Math import is moved to the top of the file