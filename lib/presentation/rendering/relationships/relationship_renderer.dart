import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart' hide Element;
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/style/styles.dart' as styles;
import 'package:flutter_structurizr/domain/style/styles.dart' hide Routing;
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/presentation/rendering/base_renderer.dart';
import 'package:flutter_structurizr/presentation/rendering/relationships/arrow_style.dart';

/// Renderer for relationships between elements in Structurizr diagrams.
///
/// This class handles the drawing of connections between elements, including
/// line paths, arrowheads, and relationship labels. It supports different routing
/// strategies and line styles as defined in the relationship style.
class RelationshipRenderer extends BaseRenderer {
  /// The arrow style for rendering arrowheads
  final ArrowStyle _arrowStyle;
  
  /// Creates a new relationship renderer with the specified arrow style.
  ///
  /// [arrowStyle] The arrow style to use for rendering arrowheads.
  RelationshipRenderer({
    ArrowStyle? arrowStyle,
  }) : _arrowStyle = arrowStyle ?? const ArrowStyle();
  
  @override
  void renderElement({
    required Canvas canvas,
    required Element element,
    required ElementView elementView,
    required ElementStyle style,
    bool selected = false,
  }) {
    // Relationship renderer doesn't render elements
    throw UnsupportedError('RelationshipRenderer does not support rendering elements');
  }
  
  @override
  void renderRelationship({
    required Canvas canvas,
    required Relationship relationship,
    required RelationshipView relationshipView,
    required styles.RelationshipStyle style,
    required Rect sourceRect,
    required Rect targetRect,
    bool selected = false,
  }) {
    // Calculate the path for the relationship
    final path = calculateRelationshipPath(
      relationship: relationship,
      relationshipView: relationshipView,
      style: style,
      sourceRect: sourceRect,
      targetRect: targetRect,
    );
    
    // Calculate path metrics for positioning text and arrowhead
    final pathMetrics = path.computeMetrics().first;
    
    // Create the paint for the relationship line
    final paint = Paint()
      ..color = style.color ?? Colors.black
      ..strokeWidth = style.thickness.toDouble()
      ..style = PaintingStyle.stroke;
    
    // Apply line style (solid, dashed, dotted)
    if (style.style == styles.LineStyle.dashed) {
      paint.strokeCap = StrokeCap.butt;
      // Draw a dashed line
      _drawDashedPath(canvas, path, paint);
    } else if (style.style == styles.LineStyle.dotted) {
      paint.strokeCap = StrokeCap.round;
      // Draw a dotted line
      _drawDottedPath(canvas, path, paint);
    } else {
      // Solid line (default)
      canvas.drawPath(path, paint);
    }
    
    // Calculate positions for arrowhead and text
    final pathPosition = style.position / 100.0;
    final textPosition = pathMetrics.length * pathPosition;
    final arrowPosition = pathMetrics.length;
    
    // Get points and tangent angles for text and arrowhead
    final textPositionInfo = pathMetrics.getTangentForOffset(textPosition);
    final arrowPositionInfo = pathMetrics.getTangentForOffset(arrowPosition);
    
    // Draw the arrowhead at the end of the relationship
    if (arrowPositionInfo != null) {
      _arrowStyle.drawArrowhead(
        canvas, 
        arrowPositionInfo.position, 
        arrowPositionInfo.angle, 
        style,
        paint,
      );
    }
    
    // Draw the relationship description text
    if (textPositionInfo != null && relationship.description.isNotEmpty) {
      _drawRelationshipText(
        canvas,
        relationship.description,
        textPositionInfo.position,
        textPositionInfo.angle,
        style,
        selected,
      );
    }
    
    // If selected, draw an indicator
    if (selected) {
      final highlightPaint = Paint()
        ..color = Colors.blue
        ..strokeWidth = style.thickness.toDouble() + 2
        ..style = PaintingStyle.stroke;
      
      canvas.drawPath(path, highlightPaint);
    }
  }
  
  @override
  Rect calculateElementBounds({
    required Element element,
    required ElementView elementView,
    required ElementStyle style,
  }) {
    // Relationship renderer doesn't calculate element bounds
    throw UnsupportedError('RelationshipRenderer does not support calculating element bounds');
  }
  
  @override
  Path calculateRelationshipPath({
    required Relationship relationship,
    required RelationshipView relationshipView,
    required styles.RelationshipStyle style,
    required Rect sourceRect,
    required Rect targetRect,
  }) {
    final path = Path();
    
    // Get the center points of source and target
    final sourceCenter = sourceRect.center;
    final targetCenter = targetRect.center;
    
    // Calculate intersection points with the element rectangles
    final sourceIntersection = findIntersectionPoint(sourceRect, targetCenter);
    final targetIntersection = findIntersectionPoint(targetRect, sourceCenter);
    
    // Start the path at the source intersection
    path.moveTo(sourceIntersection.dx, sourceIntersection.dy);
    
    // Apply different routing strategies based on the relationship style
    switch (style.routing) {
      case styles.Routing.direct:
        // Direct straight line
        path.lineTo(targetIntersection.dx, targetIntersection.dy);
        break;

      case styles.Routing.curved:
        // Curved line with control points
        final controlPoint1 = _calculateControlPoint(sourceIntersection, targetIntersection, 0.25);
        final controlPoint2 = _calculateControlPoint(sourceIntersection, targetIntersection, 0.75);

        path.cubicTo(
          controlPoint1.dx, controlPoint1.dy,
          controlPoint2.dx, controlPoint2.dy,
          targetIntersection.dx, targetIntersection.dy,
        );
        break;

      case styles.Routing.orthogonal:
        // Orthogonal line with right angles
        _addOrthogonalPath(
          path,
          sourceIntersection,
          targetIntersection,
          relationshipView.vertices,
        );
        break;
    }
    
    return path;
  }
  
  @override
  bool hitTestElement({
    required Offset point,
    required Element element,
    required ElementView elementView,
    required ElementStyle style,
  }) {
    // Relationship renderer doesn't hit test elements
    throw UnsupportedError('RelationshipRenderer does not support hit testing elements');
  }
  
  @override
  bool hitTestRelationship({
    required Offset point,
    required Relationship relationship,
    required RelationshipView relationshipView,
    required styles.RelationshipStyle style,
    required Rect sourceRect,
    required Rect targetRect,
    double hitTolerance = 8.0,
  }) {
    // Calculate the path for the relationship
    final path = calculateRelationshipPath(
      relationship: relationship,
      relationshipView: relationshipView,
      style: style,
      sourceRect: sourceRect,
      targetRect: targetRect,
    );
    
    // For curved or complex paths, we need to iterate through the path and check
    // the distance to each line segment
    final pathMetrics = path.computeMetrics().first;
    final pathLength = pathMetrics.length;
    
    // Sample the path at regular intervals to check for hits
    const sampleRate = 10.0; // Sample every 10 pixels
    final numSamples = (pathLength / sampleRate).ceil();
    
    Offset? prevPoint;
    for (int i = 0; i <= numSamples; i++) {
      final distance = i * sampleRate;
      if (distance > pathLength) break;
      
      final tangent = pathMetrics.getTangentForOffset(distance);
      if (tangent == null) continue;
      
      final currentPoint = tangent.position;
      
      if (prevPoint != null) {
        // Check if the point is close to this line segment
        final distanceToSegment = distanceToLineSegment(point, prevPoint, currentPoint);
        if (distanceToSegment <= hitTolerance) {
          return true;
        }
      }
      
      prevPoint = currentPoint;
    }
    
    return false;
  }
  
  /// Draws a relationship label text at the specified position.
  ///
  /// [canvas] The canvas to draw on.
  /// [text] The text to draw.
  /// [position] The position to draw the text at.
  /// [angle] The angle of the relationship line in radians.
  /// [style] The relationship style to apply.
  /// [selected] Whether the relationship is selected.
  void _drawRelationshipText(
    Canvas canvas,
    String text,
    Offset position,
    double angle,
    styles.RelationshipStyle style,
    bool selected,
  ) {
    // Save the canvas state before transformations
    canvas.save();
    
    // Create the text painter
    final textStyle = TextStyle(
      color: selected ? Colors.blue : (style.color ?? Colors.black),
      fontSize: style.fontSize?.toDouble() ?? 12.0,
      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      backgroundColor: Colors.white.withOpacity(0.7),
    );
    
    final textPainter = createTextPainter(
      text: text,
      style: textStyle,
      maxWidth: style.width?.toDouble() ?? 200.0,
    );
    
    // Normalize the angle to keep text readable
    double textAngle = angle;
    if (textAngle > math.pi / 2 && textAngle < 3 * math.pi / 2) {
      textAngle += math.pi;
    }
    
    // Move to the position where text should be drawn
    canvas.translate(position.dx, position.dy);
    
    // Rotate if needed for angled relationships (optional - can be disabled for readability)
    // canvas.rotate(textAngle);
    
    // Center the text on the path point
    final textOffset = Offset(
      -textPainter.width / 2,
      -textPainter.height - 5, // Offset above the line
    );
    
    // Draw the text
    textPainter.paint(canvas, textOffset);
    
    // Restore the canvas state
    canvas.restore();
  }
  
  /// Draws a dashed line for a relationship path.
  ///
  /// [canvas] The canvas to draw on.
  /// [path] The path to draw.
  /// [paint] The paint to use for drawing.
  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final pathMetrics = path.computeMetrics().first;
    final dashLength = math.max(paint.strokeWidth * 2, 6.0);
    final gapLength = math.max(paint.strokeWidth, 3.0);
    
    double distance = 0.0;
    bool drawDash = true;
    
    final dashPath = Path();
    
    while (distance < pathMetrics.length) {
      final segmentLength = drawDash ? dashLength : gapLength;
      final extractPath = pathMetrics.extractPath(
        distance, 
        distance + segmentLength,
        startWithMoveTo: true,
      );
      
      if (drawDash) {
        dashPath.addPath(extractPath, Offset.zero);
      }
      
      distance += segmentLength;
      drawDash = !drawDash;
    }
    
    canvas.drawPath(dashPath, paint);
  }
  
  /// Draws a dotted line for a relationship path.
  ///
  /// [canvas] The canvas to draw on.
  /// [path] The path to draw.
  /// [paint] The paint to use for drawing.
  void _drawDottedPath(Canvas canvas, Path path, Paint paint) {
    final pathMetrics = path.computeMetrics().first;
    final dotSpacing = math.max(paint.strokeWidth * 3, 8.0);
    
    double distance = 0.0;
    
    while (distance < pathMetrics.length) {
      final tangent = pathMetrics.getTangentForOffset(distance);
      if (tangent != null) {
        canvas.drawCircle(tangent.position, paint.strokeWidth / 2, paint);
      }
      
      distance += dotSpacing;
    }
  }
  
  /// Calculates a control point for a curved relationship path.
  ///
  /// [start] The start point of the path.
  /// [end] The end point of the path.
  /// [t] A value between 0 and 1 representing the position along the path.
  ///
  /// Returns an [Offset] representing the control point.
  Offset _calculateControlPoint(Offset start, Offset end, double t) {
    // Calculate a control point that's offset from the straight line
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    
    // Calculate perpendicular offset
    final offsetMagnitude = distance * 0.2; // 20% of the distance
    final normalizedPerpendicular = Offset(-dy / distance, dx / distance);
    
    // Create the control point
    final controlPoint = Offset(
      start.dx + dx * t + normalizedPerpendicular.dx * offsetMagnitude,
      start.dy + dy * t + normalizedPerpendicular.dy * offsetMagnitude,
    );
    
    return controlPoint;
  }
  
  /// Adds an orthogonal path to the given path.
  ///
  /// [path] The path to add to.
  /// [start] The start point of the orthogonal path.
  /// [end] The end point of the orthogonal path.
  /// [vertices] Custom vertices for the path (if any).
  void _addOrthogonalPath(
    Path path, 
    Offset start, 
    Offset end, 
    List<Vertex> vertices,
  ) {
    if (vertices.isNotEmpty) {
      // Use custom vertices if provided
      for (final vertex in vertices) {
        path.lineTo(vertex.x.toDouble(), vertex.y.toDouble());
      }
      path.lineTo(end.dx, end.dy);
    } else {
      // Determine if the orthogonal path should go horizontal-vertical or vertical-horizontal
      final dx = (end.dx - start.dx).abs();
      final dy = (end.dy - start.dy).abs();
      
      if (dx > dy) {
        // Horizontal first, then vertical
        path.lineTo(start.dx + (end.dx - start.dx) / 2, start.dy);
        path.lineTo(start.dx + (end.dx - start.dx) / 2, end.dy);
      } else {
        // Vertical first, then horizontal
        path.lineTo(start.dx, start.dy + (end.dy - start.dy) / 2);
        path.lineTo(end.dx, start.dy + (end.dy - start.dy) / 2);
      }
      
      path.lineTo(end.dx, end.dy);
    }
  }
}