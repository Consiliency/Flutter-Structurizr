import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart' hide Element;
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/style/styles.dart' as styles;
import 'package:flutter_structurizr/domain/style/styles.dart'; // Import the styles without hiding anything
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/presentation/rendering/base_renderer.dart';
import 'package:flutter_structurizr/presentation/rendering/relationships/arrow_style.dart';

/// Helper class to store a tuple of two values
class _Tuple<T1, T2> {
  final T1 first;
  final T2 second;
  
  _Tuple(this.first, this.second);
}

/// Placement options for self-relationships
enum _SelfRelationshipPlacement {
  top,
  right,
  bottom,
  left,
}

/// Node in the grid for the grid-based routing algorithm
class _GridNode {
  final double x;
  final double y;
  double g; // Cost from start node
  double h; // Heuristic cost to end node
  _GridNode? parent;
  
  _GridNode({
    required this.x,
    required this.y,
    required this.g,
    required this.h,
    this.parent,
  });
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _GridNode && 
           (other.x - x).abs() < 0.001 && 
           (other.y - y).abs() < 0.001;
  }
  
  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

/// Renderer for relationships between elements in Structurizr diagrams.
///
/// This class handles the drawing of connections between elements, including
/// line paths, arrowheads, and relationship labels. It supports different routing
/// strategies and line styles as defined in the relationship style.
class RelationshipRenderer extends BaseRenderer {
  /// The arrow style for rendering arrowheads
  final ArrowStyle _arrowStyle;
  
  /// Cached source and target intersection points for the last rendered relationship
  late Offset sourceIntersection;
  late Offset targetIntersection;
  
  /// Padding around elements to use when routing relationships
  final double _routingPadding = 20.0;
  
  /// Minimum distance for control points in curved relationships
  final double _minControlPointDistance = 40.0;
  
  /// Spacing between parallel relationships (for bidirectional relationships)
  final double _parallelRelationshipSpacing = 20.0;
  
  /// Minimum angle variation for self-relationships (in radians)
  final double _selfRelationshipAngle = math.pi / 6;
  
  /// Cache of all element bounds for collision detection
  /// This is populated by the diagram widget and used for path planning
  final Map<String, Rect> _elementBoundsCache = {};
  
  /// Cache of bidirectional relationships for path offsetting
  final Map<String, String> _bidirectionalRelationships = {};
  
  /// Cache of parallel relationships for path offsetting
  final Map<String, List<String>> _parallelRelationships = {};
  
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
    bool hovered = false,
    bool includeNames = true,
    bool includeDescriptions = false,
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
    bool hovered = false,
    bool includeDescription = true,
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
    if (includeDescription && textPositionInfo != null && relationship.description.isNotEmpty) {
      _drawRelationshipText(
        canvas,
        relationship.description,
        textPositionInfo.position,
        textPositionInfo.angle,
        style,
        selected,
        hovered,
      );
    }
    
    // If hovered or selected, draw a highlight
    if (selected || hovered) {
      final highlightPaint = Paint()
        ..color = selected ? Colors.blue : Colors.grey.shade400
        ..strokeWidth = style.thickness.toDouble() + (selected ? 2 : 1)
        ..style = PaintingStyle.stroke;
      
      canvas.drawPath(path, highlightPaint);
      
      // Draw selection handles (small circles) at the start and end points
      if (selected) {
        final handlePaint = Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.fill;
        
        // Draw handles at the start and end points for selected relationships
        canvas.drawCircle(sourceIntersection, 4.0, handlePaint);
        canvas.drawCircle(targetIntersection, 4.0, handlePaint);
      } else if (hovered) {
        final handlePaint = Paint()
          ..color = Colors.grey.shade400
          ..style = PaintingStyle.fill;
        
        // Draw slightly smaller handles for hover state
        canvas.drawCircle(sourceIntersection, 3.0, handlePaint);
        canvas.drawCircle(targetIntersection, 3.0, handlePaint);
      }
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
  
  /// Sets the cache of element bounds for collision detection and path planning.
  ///
  /// This should be called by the diagram widget before rendering relationships.
  ///
  /// [elementBounds] A map of element IDs to their bounding rectangles.
  void setElementBoundsCache(Map<String, Rect> elementBounds) {
    _elementBoundsCache.clear();
    _elementBoundsCache.addAll(elementBounds);
  }
  
  /// Sets bidirectional relationship mappings for offset calculation.
  ///
  /// This should be called by the diagram widget after analyzing all relationships.
  ///
  /// [bidirectionalMap] A map of relationship IDs to their bidirectional counterparts.
  void setBidirectionalRelationships(Map<String, String> bidirectionalMap) {
    _bidirectionalRelationships.clear();
    _bidirectionalRelationships.addAll(bidirectionalMap);
  }
  
  /// Sets parallel relationship mappings for offset calculation.
  ///
  /// This method records which relationships run between the same elements and
  /// should be offset from each other.
  ///
  /// [parallelMap] A map of relationship IDs to lists of parallel relationship IDs.
  void setParallelRelationships(Map<String, List<String>> parallelMap) {
    _parallelRelationships.clear();
    _parallelRelationships.addAll(parallelMap);
  }
  
  /// Detects bidirectional relationships in a list of relationships.
  ///
  /// A bidirectional relationship is one where there are relationships in both
  /// directions between the same two elements.
  ///
  /// [relationships] The list of relationships to analyze.
  ///
  /// Returns a map of relationship IDs to their bidirectional counterparts.
  Map<String, String> detectBidirectionalRelationships(List<Relationship> relationships) {
    final result = <String, String>{};
    final relationshipsByEndpoints = <String, List<Relationship>>{};
    
    // Group relationships by their endpoints
    for (final relationship in relationships) {
      final endpoints = '${relationship.sourceId}-${relationship.destinationId}';
      final reverseEndpoints = '${relationship.destinationId}-${relationship.sourceId}';
      
      relationshipsByEndpoints[endpoints] = 
          (relationshipsByEndpoints[endpoints] ?? [])..add(relationship);
      
      // Check for relationships in the opposite direction
      if (relationshipsByEndpoints.containsKey(reverseEndpoints)) {
        // Found bidirectional relationship
        for (final forwardRel in relationshipsByEndpoints[endpoints]!) {
          for (final backwardRel in relationshipsByEndpoints[reverseEndpoints]!) {
            result[forwardRel.id] = backwardRel.id;
            result[backwardRel.id] = forwardRel.id;
          }
        }
      }
    }
    
    return result;
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
    
    // Check if this is a self-relationship (same source and target)
    final isSelfRelationship = relationship.sourceId == relationship.destinationId;
    
    if (isSelfRelationship) {
      return _calculateSelfRelationshipPath(
        relationship: relationship,
        relationshipView: relationshipView,
        style: style,
        elementRect: sourceRect,
      );
    }
    
    // Get the center points of source and target
    final sourceCenter = sourceRect.center;
    final targetCenter = targetRect.center;
    
    // Calculate intersection points with the element rectangles
    this.sourceIntersection = findIntersectionPoint(sourceRect, targetCenter);
    this.targetIntersection = findIntersectionPoint(targetRect, sourceCenter);
    
    // Check if this is part of a bidirectional relationship pair
    final isBidirectional = _isBidirectionalRelationship(relationship);
    
    // Adjust path start and end points for bidirectional relationships
    if (isBidirectional) {
      final adjustedPoints = _adjustBidirectionalRelationshipPoints(
        relationship, 
        sourceIntersection, 
        targetIntersection,
        sourceRect,
        targetRect
      );
      
      this.sourceIntersection = adjustedPoints.first;
      this.targetIntersection = adjustedPoints.second;
    }
    
    // Start the path at the source intersection
    path.moveTo(sourceIntersection.dx, sourceIntersection.dy);
    
    // If we have custom vertices, use them for routing
    if (relationshipView.vertices.isNotEmpty) {
      // Add the custom vertices as waypoints
      for (final vertex in relationshipView.vertices) {
        path.lineTo(vertex.x.toDouble(), vertex.y.toDouble());
      }
      // Connect to the target
      path.lineTo(targetIntersection.dx, targetIntersection.dy);
      return path;
    }
    
    // Apply different routing strategies based on the relationship style
    // Use the fully qualified Routing enum from the styles import
    var routing = style.routing;
    
    // Check for custom routing based on tags
    routing = _getEffectiveRouting(relationship, style);
    
    if (routing == StyleRouting.direct) {
      // Direct straight line
      path.lineTo(targetIntersection.dx, targetIntersection.dy);
    } 
    else if (routing == StyleRouting.curved) {
      // Enhanced curved routing
      _addEnhancedCurvedPath(
        path,
        relationship,
        sourceIntersection,
        targetIntersection,
        sourceRect,
        targetRect,
        isBidirectional,
      );
    }
    else if (routing == StyleRouting.orthogonal) {
      // Enhanced orthogonal routing with obstacle avoidance
      _addEnhancedOrthogonalPath(
        path,
        sourceIntersection,
        targetIntersection,
        sourceRect,
        targetRect,
        relationship,
      );
    }
    else {
      // Default to direct path if routing type is unknown
      path.lineTo(targetIntersection.dx, targetIntersection.dy);
    }
    
    return path;
  }
  
  /// Checks if the control points for a curved path would intersect with any obstacles.
  ///
  /// [start] The start point of the curve.
  /// [end] The end point of the curve.
  /// [controlPoint1] The first control point.
  /// [controlPoint2] The second control point.
  /// [obstacles] The list of rectangle obstacles to check against.
  ///
  /// Returns true if the curve formed by these control points would likely intersect
  /// with any of the obstacles, false otherwise.
  bool _controlPointsWouldIntersectObstacles(
    Offset start,
    Offset end,
    Offset controlPoint1,
    Offset controlPoint2,
    List<Rect> obstacles,
  ) {
    // Simple approximation of the curve by sampling points along it
    const numSamples = 8;
    List<Offset> curvePoints = [];
    
    for (int i = 0; i <= numSamples; i++) {
      final t = i / numSamples;
      final point = _evaluateCubicBezier(start, controlPoint1, controlPoint2, end, t);
      curvePoints.add(point);
    }
    
    // Check if any line segment between consecutive curve points intersects an obstacle
    for (int i = 0; i < curvePoints.length - 1; i++) {
      final segmentStart = curvePoints[i];
      final segmentEnd = curvePoints[i + 1];
      
      for (final obstacle in obstacles) {
        if (_lineIntersectsRect(segmentStart, segmentEnd, obstacle)) {
          return true;
        }
      }
    }
    
    return false;
  }

  /// Evaluates a point on a cubic Bezier curve at parameter t.
  ///
  /// [p0] The start point of the curve.
  /// [p1] The first control point.
  /// [p2] The second control point.
  /// [p3] The end point of the curve.
  /// [t] The parameter value (0.0 to 1.0) along the curve.
  ///
  /// Returns the point on the cubic Bezier curve at parameter t.
  Offset _evaluateCubicBezier(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final mt = 1 - t;
    final mt2 = mt * mt;
    final mt3 = mt2 * mt;
    final t2 = t * t;
    final t3 = t2 * t;
    
    return Offset(
      mt3 * p0.dx + 3 * mt2 * t * p1.dx + 3 * mt * t2 * p2.dx + t3 * p3.dx,
      mt3 * p0.dy + 3 * mt2 * t * p1.dy + 3 * mt * t2 * p2.dy + t3 * p3.dy,
    );
  }

  /// Calculates a control point with obstacle avoidance.
  ///
  /// This creates control points that avoid overlapping the source or target elements.
  ///
  /// [start] The start point of the curve.
  /// [end] The end point of the curve.
  /// [t] The position along the path (0.0 to 1.0).
  /// [startRect] The source element's bounds.
  /// [endRect] The target element's bounds.
  /// [offsetMagnitude] The magnitude of the perpendicular offset.
  /// [isBidirectional] Whether this is part of a bidirectional relationship.
  ///
  /// Returns an [Offset] representing the control point.
  Offset _calculateControlPointWithObstacleAvoidance(
    Offset start, 
    Offset end, 
    double t,
    Rect startRect,
    Rect endRect,
    double offsetMagnitude,
    bool isBidirectional,
  ) {
    // Calculate a control point that's offset from the straight line
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    
    // Determine which dimension has more space
    final horizontalSpace = (end.dx - start.dx).abs();
    final verticalSpace = (end.dy - start.dy).abs();
    
    // For bidirectional relationships, alternate the direction of the curve
    // This creates balanced opposing curves for the two relationships
    double directionMultiplier = isBidirectional ? -1.0 : 1.0;
    
    // Calculate perpendicular unit vector
    final lineMagnitude = math.sqrt(dx * dx + dy * dy);
    final perpDx = -dy / lineMagnitude * directionMultiplier;
    final perpDy = dx / lineMagnitude * directionMultiplier;
    
    // Scale the perpendicular offset based on relationship distance
    final perpMagnitude = math.max(distance * 0.3, offsetMagnitude);
    
    // Create the control point with smart obstacle avoidance
    Offset controlPoint = Offset(
      start.dx + dx * t + perpDx * perpMagnitude,
      start.dy + dy * t + perpDy * perpMagnitude,
    );
    
    // Check if this control point creates a path that intersects any obstacles
    // If it does, try the opposite direction
    if (_elementBoundsCache.isNotEmpty) {
      final samplePoints = [
        _evaluateCubicBezier(start, controlPoint, controlPoint, end, 0.33),
        _evaluateCubicBezier(start, controlPoint, controlPoint, end, 0.66),
      ];
      
      // Check against all obstacles
      bool hasIntersection = false;
      for (final obstacle in _elementBoundsCache.values) {
        // Skip source and target
        if (obstacle == startRect || obstacle == endRect) continue;
        
        // Check if any of the sample points is inside the obstacle
        for (final point in samplePoints) {
          if (obstacle.contains(point)) {
            hasIntersection = true;
            break;
          }
        }
        
        if (hasIntersection) break;
      }
      
      // If there's an intersection, try the opposite direction
      if (hasIntersection) {
        controlPoint = Offset(
          start.dx + dx * t - perpDx * perpMagnitude,
          start.dy + dy * t - perpDy * perpMagnitude,
        );
      }
    }
    
    return controlPoint;
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
    bool hovered,
  ) {
    // Save the canvas state before transformations
    canvas.save();
    
    // Create the text painter
    final textStyle = TextStyle(
      color: selected ? Colors.blue : hovered ? Colors.grey.shade700 : (style.color ?? Colors.black),
      fontSize: style.fontSize?.toDouble() ?? 12.0,
      fontWeight: selected ? FontWeight.bold : hovered ? FontWeight.w500 : FontWeight.normal,
      backgroundColor: Colors.white.withOpacity(selected || hovered ? 0.8 : 0.7),
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
  
  /// Finds a path using the A* algorithm to navigate around obstacles.
  ///
  /// This is used for complex orthogonal routing with multiple obstacles.
  ///
  /// [start] The start point of the path.
  /// [end] The end point of the path.
  /// [obstacles] The list of rectangle obstacles to avoid.
  ///
  /// Returns a list of waypoints forming a path from start to end, or an empty list if no path is found.
  List<Offset> _findPathWithAStarAlgorithm(
    Offset start,
    Offset end,
    List<Rect> obstacles,
  ) {
    // For very short paths, don't bother with A*
    if ((end - start).distance < 50) {
      return [];
    }
    
    // Create a grid of points to navigate through
    // This is a simplified version that uses a grid with fixed spacing
    const gridSpacing = 30.0;
    
    // Define the bounds of the grid based on the start and end points with some margin
    final minX = math.min(start.dx, end.dx) - 100;
    final maxX = math.max(start.dx, end.dx) + 100;
    final minY = math.min(start.dy, end.dy) - 100;
    final maxY = math.max(start.dy, end.dy) + 100;
    
    // We'll use a simple orthogonal movement model (horizontal and vertical only)
    // This means each node can have 4 neighbors
    final List<_GridNode> openSet = [];
    final Map<String, _GridNode> closedSet = {};
    
    // Create the start node
    final startNode = _GridNode(
      x: start.dx,
      y: start.dy,
      g: 0,
      h: _heuristic(start, end),
      parent: null,
    );
    
    openSet.add(startNode);
    
    // Maximum number of iterations to prevent infinite loops
    const maxIterations = 200;
    int iterations = 0;
    
    while (openSet.isNotEmpty && iterations < maxIterations) {
      iterations++;
      
      // Sort the open set by f score (g + h)
      openSet.sort((a, b) => (a.g + a.h).compareTo(b.g + b.h));
      
      // Get the node with the lowest f score
      final current = openSet.removeAt(0);
      
      // If we're close enough to the end, we're done
      if ((Offset(current.x, current.y) - end).distance < gridSpacing) {
        // Construct the path by working backwards from the current node
        final path = <Offset>[];
        var node = current;
        
        while (node.parent != null) {
          path.add(Offset(node.x, node.y));
          node = node.parent!;
        }
        
        // Reverse the path to go from start to end
        return path.reversed.toList();
      }
      
      // Add the current node to the closed set
      closedSet['${current.x},${current.y}'] = current;
      
      // Generate the four possible neighbors (orthogonal movement only)
      final neighbors = [
        _GridNode(x: current.x + gridSpacing, y: current.y, g: 0, h: 0, parent: current),
        _GridNode(x: current.x - gridSpacing, y: current.y, g: 0, h: 0, parent: current),
        _GridNode(x: current.x, y: current.y + gridSpacing, g: 0, h: 0, parent: current),
        _GridNode(x: current.x, y: current.y - gridSpacing, g: 0, h: 0, parent: current),
      ];
      
      // Process each neighbor
      for (final neighbor in neighbors) {
        // Skip if the neighbor is outside our grid bounds
        if (neighbor.x < minX || neighbor.x > maxX || neighbor.y < minY || neighbor.y > maxY) {
          continue;
        }
        
        // Skip if the neighbor is in the closed set
        final neighborKey = '${neighbor.x},${neighbor.y}';
        if (closedSet.containsKey(neighborKey)) {
          continue;
        }
        
        // Skip if the neighbor intersects an obstacle
        final neighborPoint = Offset(neighbor.x, neighbor.y);
        bool intersectsObstacle = false;
        
        for (final obstacle in obstacles) {
          if (obstacle.contains(neighborPoint)) {
            intersectsObstacle = true;
            break;
          }
        }
        
        if (intersectsObstacle) {
          continue;
        }
        
        // Skip if the path to the neighbor intersects an obstacle
        final currentPoint = Offset(current.x, current.y);
        bool pathIntersectsObstacle = false;
        
        for (final obstacle in obstacles) {
          if (_lineIntersectsRect(currentPoint, neighborPoint, obstacle)) {
            pathIntersectsObstacle = true;
            break;
          }
        }
        
        if (pathIntersectsObstacle) {
          continue;
        }
        
        // Calculate g score (distance from start)
        final tentativeG = current.g + (neighborPoint - currentPoint).distance;
        
        // Find the neighbor in the open set if it exists
        final existingIndex = openSet.indexWhere(
          (node) => (node.x - neighbor.x).abs() < 0.1 && (node.y - neighbor.y).abs() < 0.1
        );
        
        if (existingIndex >= 0 && tentativeG >= openSet[existingIndex].g) {
          // This is not a better path
          continue;
        }
        
        // This is the best path so far, record it
        if (existingIndex >= 0) {
          openSet.removeAt(existingIndex);
        }
        
        neighbor.g = tentativeG;
        neighbor.h = _heuristic(neighborPoint, end);
        openSet.add(neighbor);
      }
    }
    
    // If we get here, we didn't find a path
    return [];
  }

  /// Heuristic function for A* algorithm (Manhattan distance).
  ///
  /// [a] The first point.
  /// [b] The second point.
  ///
  /// Returns the Manhattan distance between a and b.
  double _heuristic(Offset a, Offset b) {
    return (a.dx - b.dx).abs() + (a.dy - b.dy).abs();
  }
  
  /// Gets the effective routing strategy based on relationship properties.
  ///
  /// This allows for custom routing based on relationship tags.
  ///
  /// [relationship] The relationship to determine routing for.
  /// [defaultStyle] The default relationship style to use if no custom routing is specified.
  ///
  /// Returns the [StyleRouting] to use for this relationship.
  StyleRouting _getEffectiveRouting(Relationship relationship, styles.RelationshipStyle defaultStyle) {
    // Example: Use curved routing for relationships tagged with 'async'
    if (relationship.tags.contains('async')) {
      return StyleRouting.curved;
    }
    
    // Default to the style-specified routing
    return defaultStyle.routing;
  }

  /// Calculates a path for a self-relationship (same source and target).
  ///
  /// [relationship] The relationship to calculate the path for.
  /// [relationshipView] The view information for the relationship.
  /// [style] The style to apply to the relationship.
  /// [elementRect] The bounding rectangle of the element.
  ///
  /// Returns a [Path] for the self-relationship.
  Path _calculateSelfRelationshipPath({
    required Relationship relationship,
    required RelationshipView relationshipView,
    required styles.RelationshipStyle style,
    required Rect elementRect,
  }) {
    final path = Path();
    
    // Check if we have custom vertices
    if (relationshipView.vertices.isNotEmpty) {
      // Get the first intersection point (from element to first vertex)
      final firstVertex = Offset(relationshipView.vertices.first.x.toDouble(), 
                             relationshipView.vertices.first.y.toDouble());
      this.sourceIntersection = findIntersectionPoint(elementRect, firstVertex);
      
      // Get the last intersection point (from element to last vertex)
      final lastVertex = Offset(relationshipView.vertices.last.x.toDouble(), 
                           relationshipView.vertices.last.y.toDouble());
      this.targetIntersection = findIntersectionPoint(elementRect, lastVertex);
      
      // Build the path
      path.moveTo(sourceIntersection.dx, sourceIntersection.dy);
      for (final vertex in relationshipView.vertices) {
        path.lineTo(vertex.x.toDouble(), vertex.y.toDouble());
      }
      path.lineTo(targetIntersection.dx, targetIntersection.dy);
      
      return path;
    }
    
    // Determine which side to place the self-relationship on
    // Default to the right side, but check if there's more space elsewhere
    final center = elementRect.center;
    final padding = _routingPadding * 2;
    
    // Determine the best side based on available space and existing elements
    final sides = [
      _SelfRelationshipPlacement.right,
      _SelfRelationshipPlacement.bottom,
      _SelfRelationshipPlacement.left,
      _SelfRelationshipPlacement.top,
    ];
    
    // Choose the side with most space
    var bestSide = _SelfRelationshipPlacement.right;
    var maxSpace = 0.0;
    
    for (final side in sides) {
      final space = _getSpaceForSelfRelationship(elementRect, side);
      if (space > maxSpace) {
        maxSpace = space;
        bestSide = side;
      }
    }
    
    // Calculate the points for the self-relationship loop
    Offset startPoint;
    Offset endPoint;
    Offset controlPoint1;
    Offset controlPoint2;
    
    switch (bestSide) {
      case _SelfRelationshipPlacement.right:
        startPoint = Offset(elementRect.right, elementRect.center.dy - elementRect.height / 4);
        endPoint = Offset(elementRect.right, elementRect.center.dy + elementRect.height / 4);
        controlPoint1 = Offset(elementRect.right + padding, startPoint.dy - padding / 2);
        controlPoint2 = Offset(elementRect.right + padding, endPoint.dy + padding / 2);
        break;
      case _SelfRelationshipPlacement.bottom:
        startPoint = Offset(elementRect.center.dx - elementRect.width / 4, elementRect.bottom);
        endPoint = Offset(elementRect.center.dx + elementRect.width / 4, elementRect.bottom);
        controlPoint1 = Offset(startPoint.dx - padding / 2, elementRect.bottom + padding);
        controlPoint2 = Offset(endPoint.dx + padding / 2, elementRect.bottom + padding);
        break;
      case _SelfRelationshipPlacement.left:
        startPoint = Offset(elementRect.left, elementRect.center.dy - elementRect.height / 4);
        endPoint = Offset(elementRect.left, elementRect.center.dy + elementRect.height / 4);
        controlPoint1 = Offset(elementRect.left - padding, startPoint.dy - padding / 2);
        controlPoint2 = Offset(elementRect.left - padding, endPoint.dy + padding / 2);
        break;
      case _SelfRelationshipPlacement.top:
        startPoint = Offset(elementRect.center.dx - elementRect.width / 4, elementRect.top);
        endPoint = Offset(elementRect.center.dx + elementRect.width / 4, elementRect.top);
        controlPoint1 = Offset(startPoint.dx - padding / 2, elementRect.top - padding);
        controlPoint2 = Offset(endPoint.dx + padding / 2, elementRect.top - padding);
        break;
    }
    
    // Set the intersection points for rendering arrowheads
    this.sourceIntersection = startPoint;
    this.targetIntersection = endPoint;
    
    // Create a curved path
    path.moveTo(startPoint.dx, startPoint.dy);
    path.cubicTo(
      controlPoint1.dx, controlPoint1.dy,
      controlPoint2.dx, controlPoint2.dy,
      endPoint.dx, endPoint.dy
    );
    
    return path;
  }

  /// Calculates the available space for a self-relationship on a given side.
  ///
  /// [elementRect] The element's bounding rectangle.
  /// [side] The side to check for space.
  ///
  /// Returns the available space in logical pixels.
  double _getSpaceForSelfRelationship(Rect elementRect, _SelfRelationshipPlacement side) {
    // Default padding for self-relationship loops
    final padding = _routingPadding * 3;
    
    // Find all elements that might limit space on this side
    double minDistance = double.infinity;
    
    // Check each element to find the closest one in the direction of the side
    for (final otherRect in _elementBoundsCache.values) {
      // Skip the source element itself
      if (otherRect == elementRect) continue;
      
      double distance;
      
      switch (side) {
        case _SelfRelationshipPlacement.right:
          if (otherRect.left > elementRect.right && 
              otherRect.top < elementRect.bottom && 
              otherRect.bottom > elementRect.top) {
            distance = otherRect.left - elementRect.right;
            if (distance < minDistance) minDistance = distance;
          }
          break;
        case _SelfRelationshipPlacement.bottom:
          if (otherRect.top > elementRect.bottom && 
              otherRect.left < elementRect.right && 
              otherRect.right > elementRect.left) {
            distance = otherRect.top - elementRect.bottom;
            if (distance < minDistance) minDistance = distance;
          }
          break;
        case _SelfRelationshipPlacement.left:
          if (otherRect.right < elementRect.left && 
              otherRect.top < elementRect.bottom && 
              otherRect.bottom > elementRect.top) {
            distance = elementRect.left - otherRect.right;
            if (distance < minDistance) minDistance = distance;
          }
          break;
        case _SelfRelationshipPlacement.top:
          if (otherRect.bottom < elementRect.top && 
              otherRect.left < elementRect.right && 
              otherRect.right > elementRect.left) {
            distance = elementRect.top - otherRect.bottom;
            if (distance < minDistance) minDistance = distance;
          }
          break;
      }
    }
    
    // If no element was found in this direction, use a large default value
    // Make sure we return at least the element size to ensure the self-relationship loop is visible
    double minimumSpace = math.max(elementRect.width, elementRect.height) * 0.5;
    return minDistance == double.infinity ? minimumSpace + 80.0 : math.max(minDistance, minimumSpace);
  }

  /// Adds an enhanced orthogonal path to the given path with obstacle avoidance.
  ///
  /// This creates orthogonal paths that avoid overlapping source and target elements
  /// and tries to create more aesthetically pleasing routes.
  ///
  /// [path] The path to add to.
  /// [start] The start point of the orthogonal path.
  /// [end] The end point of the orthogonal path.
  /// [sourceRect] The source element's bounds.
  /// [targetRect] The target element's bounds.
  /// [relationship] The relationship being rendered (for customization).
  void _addEnhancedOrthogonalPath(
    Path path,
    Offset start,
    Offset end,
    Rect sourceRect,
    Rect targetRect,
    Relationship relationship,
  ) {
    // Check for element overlap
    final hasOverlap = sourceRect.overlaps(targetRect);
    
    // Get the direction from source to target
    final isHorizontal = (end.dx - start.dx).abs() > (end.dy - start.dy).abs();
    final isMovingRight = end.dx > start.dx;
    final isMovingDown = end.dy > start.dy;
    
    // Calculate midpoints for routing
    final horizontalMidpoint = start.dx + (end.dx - start.dx) / 2;
    final verticalMidpoint = start.dy + (end.dy - start.dy) / 2;
    
    // Calculate padding around elements
    final padding = _routingPadding;
    final sourcePadded = sourceRect.inflate(padding);
    final targetPadded = targetRect.inflate(padding);
    
    // Add all other element rects for collision detection
    final List<Rect> obstacleRects = [];
    for (final rect in _elementBoundsCache.values) {
      // Skip source and target elements
      if (rect == sourceRect || rect == targetRect) continue;
      obstacleRects.add(rect.inflate(padding * 0.5)); // Slightly smaller padding for other elements
    }
    
    if (hasOverlap) {
      // Special case for overlapping elements
      _routeAroundOverlappingElements(
        path, start, end, sourcePadded, targetPadded, isHorizontal
      );
    } 
    // Try the most direct 2-segment path first
    else if (isHorizontal && !_wouldIntersectAny(start, Offset(end.dx, start.dy), [sourcePadded, targetPadded, ...obstacleRects])) {
      // Horizontal first, then vertical (if no intersection)
      _addSmoothCornerOrthogonalPath(path, start, end, true);
    } 
    else if (!isHorizontal && !_wouldIntersectAny(start, Offset(start.dx, end.dy), [sourcePadded, targetPadded, ...obstacleRects])) {
      // Vertical first, then horizontal (if no intersection)
      _addSmoothCornerOrthogonalPath(path, start, end, false);
    } 
    // Try standard 3-segment path with midpoints
    else if (!_wouldIntersectAny(start, Offset(horizontalMidpoint, start.dy), [sourcePadded, targetPadded, ...obstacleRects]) &&
             !_wouldIntersectAny(Offset(horizontalMidpoint, start.dy), Offset(horizontalMidpoint, end.dy), [sourcePadded, targetPadded, ...obstacleRects]) &&
             !_wouldIntersectAny(Offset(horizontalMidpoint, end.dy), end, [sourcePadded, targetPadded, ...obstacleRects])) {
      // Use horizontal-vertical-horizontal path
      path.lineTo(horizontalMidpoint, start.dy);
      path.lineTo(horizontalMidpoint, end.dy);
      path.lineTo(end.dx, end.dy);
    } 
    else if (!_wouldIntersectAny(start, Offset(start.dx, verticalMidpoint), [sourcePadded, targetPadded, ...obstacleRects]) &&
             !_wouldIntersectAny(Offset(start.dx, verticalMidpoint), Offset(end.dx, verticalMidpoint), [sourcePadded, targetPadded, ...obstacleRects]) &&
             !_wouldIntersectAny(Offset(end.dx, verticalMidpoint), end, [sourcePadded, targetPadded, ...obstacleRects])) {
      // Use vertical-horizontal-vertical path
      path.lineTo(start.dx, verticalMidpoint);
      path.lineTo(end.dx, verticalMidpoint);
      path.lineTo(end.dx, end.dy);
    } 
    else {
      // Use A* pathfinding for complex routing with obstacles
      final waypoints = _findPathWithAStarAlgorithm(start, end, [sourcePadded, targetPadded, ...obstacleRects]);
      
      // If A* found a path, use it
      if (waypoints.isNotEmpty) {
        for (final point in waypoints) {
          path.lineTo(point.dx, point.dy);
        }
        path.lineTo(end.dx, end.dy);
      } else {
        // Fallback to simple 3-segment routing for extreme cases
        _routeWithThreeSegments(
          path, start, end, sourcePadded, targetPadded, isHorizontal, isMovingRight, isMovingDown
        );
      }
    }
  }
  
  /// Routes a path with three segments (Two bends) to avoid obstacles.
  ///
  /// [path] The path to add to.
  /// [start] The start point.
  /// [end] The end point.
  /// [sourceRect] The source element's bounds.
  /// [targetRect] The target element's bounds.
  /// [isHorizontal] Whether the primary direction is horizontal.
  /// [isMovingRight] Whether the path is moving right.
  /// [isMovingDown] Whether the path is moving down.
  void _routeWithThreeSegments(
    Path path,
    Offset start,
    Offset end,
    Rect sourceRect,
    Rect targetRect,
    bool isHorizontal,
    bool isMovingRight,
    bool isMovingDown,
  ) {
    if (isHorizontal) {
      // Determine if we should route above or below the elements
      final topSpace = math.min(start.dy, end.dy) - math.min(sourceRect.top, targetRect.top);
      final bottomSpace = math.max(sourceRect.bottom, targetRect.bottom) - math.max(start.dy, end.dy);
      
      if (topSpace > bottomSpace) {
        // Route above elements
        final topY = math.min(sourceRect.top, targetRect.top) - 20;
        path.lineTo(start.dx, topY);
        path.lineTo(end.dx, topY);
        path.lineTo(end.dx, end.dy);
      } else {
        // Route below elements
        final bottomY = math.max(sourceRect.bottom, targetRect.bottom) + 20;
        path.lineTo(start.dx, bottomY);
        path.lineTo(end.dx, bottomY);
        path.lineTo(end.dx, end.dy);
      }
    } else {
      // Determine if we should route left or right of the elements
      final leftSpace = math.min(start.dx, end.dx) - math.min(sourceRect.left, targetRect.left);
      final rightSpace = math.max(sourceRect.right, targetRect.right) - math.max(start.dx, end.dx);
      
      if (leftSpace > rightSpace) {
        // Route to the left of elements
        final leftX = math.min(sourceRect.left, targetRect.left) - 20;
        path.lineTo(leftX, start.dy);
        path.lineTo(leftX, end.dy);
        path.lineTo(end.dx, end.dy);
      } else {
        // Route to the right of elements
        final rightX = math.max(sourceRect.right, targetRect.right) + 20;
        path.lineTo(rightX, start.dy);
        path.lineTo(rightX, end.dy);
        path.lineTo(end.dx, end.dy);
      }
    }
  }
  
  /// Routes a path around overlapping elements.
  ///
  /// [path] The path to add to.
  /// [start] The start point.
  /// [end] The end point.
  /// [sourceRect] The source element's bounds.
  /// [targetRect] The target element's bounds.
  /// [isHorizontal] Whether the primary direction is horizontal.
  void _routeAroundOverlappingElements(
    Path path,
    Offset start,
    Offset end,
    Rect sourceRect,
    Rect targetRect,
    bool isHorizontal,
  ) {
    // Create a combined bounding box for both elements
    final combinedRect = Rect.fromLTRB(
      math.min(sourceRect.left, targetRect.left),
      math.min(sourceRect.top, targetRect.top),
      math.max(sourceRect.right, targetRect.right),
      math.max(sourceRect.bottom, targetRect.bottom),
    );
    
    // Determine which side to route around
    if (isHorizontal) {
      // Route around the top or bottom
      final topSpace = start.dy - combinedRect.top;
      final bottomSpace = combinedRect.bottom - start.dy;
      
      if (topSpace < bottomSpace) {
        // Go around the top
        final topY = combinedRect.top - 20;
        path.lineTo(start.dx, topY);
        path.lineTo(end.dx, topY);
        path.lineTo(end.dx, end.dy);
      } else {
        // Go around the bottom
        final bottomY = combinedRect.bottom + 20;
        path.lineTo(start.dx, bottomY);
        path.lineTo(end.dx, bottomY);
        path.lineTo(end.dx, end.dy);
      }
    } else {
      // Route around the left or right
      final leftSpace = start.dx - combinedRect.left;
      final rightSpace = combinedRect.right - start.dx;
      
      if (leftSpace < rightSpace) {
        // Go around the left
        final leftX = combinedRect.left - 20;
        path.lineTo(leftX, start.dy);
        path.lineTo(leftX, end.dy);
        path.lineTo(end.dx, end.dy);
      } else {
        // Go around the right
        final rightX = combinedRect.right + 20;
        path.lineTo(rightX, start.dy);
        path.lineTo(rightX, end.dy);
        path.lineTo(end.dx, end.dy);
      }
    }
  }
  
  /// Adds a curved path with enhanced control points and obstacle avoidance.
  ///
  /// [path] The path to add to.
  /// [relationship] The relationship being rendered.
  /// [start] The start point of the curve.
  /// [end] The end point of the curve.
  /// [sourceRect] The source element's bounds.
  /// [targetRect] The target element's bounds.
  /// [isBidirectional] Whether this is part of a bidirectional relationship pair.
  void _addEnhancedCurvedPath(
    Path path,
    Relationship relationship,
    Offset start,
    Offset end,
    Rect sourceRect,
    Rect targetRect,
    bool isBidirectional,
  ) {
    // Check for rectangle overlap to adjust curve
    final overlap = sourceRect.overlaps(targetRect);
    final distance = (end - start).distance;
    
    // Adjust control point offsets based on distance
    final controlPointOffset = math.max(distance * 0.2, _minControlPointDistance);
    
    // Bidirectional relationships should curve more
    final curveFactor = isBidirectional ? 0.4 : 0.3;
    
    // Calculate tangent vectors at the start and end points
    final midpoint = Offset(
      start.dx + (end.dx - start.dx) / 2,
      start.dy + (end.dy - start.dy) / 2,
    );
    
    if (overlap) {
      // Use more pronounced curves for overlapping elements
      final controlPoint1 = _calculateControlPointWithObstacleAvoidance(
        start, end, 0.33, sourceRect, targetRect, controlPointOffset, isBidirectional
      );
      final controlPoint2 = _calculateControlPointWithObstacleAvoidance(
        end, start, 0.33, targetRect, sourceRect, controlPointOffset, isBidirectional
      );
      
      path.cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        end.dx, end.dy,
      );
    } else {
      // Use arc length-based control points for smoother curves
      final tangentAngle = math.atan2(end.dy - start.dy, end.dx - start.dx);
      
      // Calculate perpendicular vectors
      final perpVector = Offset(
        -math.sin(tangentAngle) * controlPointOffset * curveFactor,
        math.cos(tangentAngle) * controlPointOffset * curveFactor,
      );
      
      // Adjust perpendicular vector based on bidirectional status
      final adjustedPerpVector = isBidirectional ? perpVector : perpVector * 0.7;
      
      // Create control points that lead from the start and end points smoothly
      final controlPoint1 = Offset(
        start.dx + (end.dx - start.dx) / 3 + adjustedPerpVector.dx,
        start.dy + (end.dy - start.dy) / 3 + adjustedPerpVector.dy,
      );
      
      final controlPoint2 = Offset(
        start.dx + 2 * (end.dx - start.dx) / 3 + adjustedPerpVector.dx,
        start.dy + 2 * (end.dy - start.dy) / 3 + adjustedPerpVector.dy,
      );
      
      // Check for obstacle intersection and adjust if needed
      final obstacles = _elementBoundsCache.values.where((rect) => 
        rect != sourceRect && rect != targetRect
      ).toList();
      
      if (_controlPointsWouldIntersectObstacles(start, end, controlPoint1, controlPoint2, obstacles)) {
        // Fall back to simpler curve with obstacle avoidance
        final adjustedControl1 = _calculateControlPointWithObstacleAvoidance(
          start, end, 0.33, sourceRect, targetRect, controlPointOffset, isBidirectional
        );
        final adjustedControl2 = _calculateControlPointWithObstacleAvoidance(
          end, start, 0.33, targetRect, sourceRect, controlPointOffset, isBidirectional
        );
        
        path.cubicTo(
          adjustedControl1.dx, adjustedControl1.dy,
          adjustedControl2.dx, adjustedControl2.dy,
          end.dx, end.dy,
        );
      } else {
        // Use the smooth control points
        path.cubicTo(
          controlPoint1.dx, controlPoint1.dy,
          controlPoint2.dx, controlPoint2.dy,
          end.dx, end.dy,
        );
      }
    }
  }

  /// Adds a smooth-cornered orthogonal path (with corner rounding).
  ///
  /// [path] The path to add to.
  /// [start] The start point of the path.
  /// [end] The end point of the path.
  /// [horizontalFirst] Whether to go horizontal first then vertical.
  void _addSmoothCornerOrthogonalPath(
    Path path,
    Offset start,
    Offset end,
    bool horizontalFirst,
  ) {
    final cornerRadius = 10.0; // Radius for the rounded corners
    
    if (horizontalFirst) {
      // Go horizontal first
      final midY = start.dy;
      final midX = end.dx;
      
      // Calculate corner positions with insets for the curve
      final cornerX = midX - (midX > start.dx ? cornerRadius : -cornerRadius);
      final cornerY = midY + (end.dy > midY ? cornerRadius : -cornerRadius);
      
      // Draw the first segment (horizontal)
      if ((cornerX - start.dx).abs() > cornerRadius) {
        path.lineTo(cornerX, midY);
      }
      
      // Draw the corner using an arc
      final rect = Rect.fromCenter(
        center: Offset(cornerX, cornerY - (end.dy > midY ? cornerRadius : -cornerRadius)),
        width: 2 * cornerRadius,
        height: 2 * cornerRadius
      );
      
      // Determine the start angle and sweep based on the direction
      double startAngle, sweepAngle;
      if (midX > start.dx && end.dy > midY) {
        // Curve bottom-right
        startAngle = 3 * math.pi / 2;
        sweepAngle = math.pi / 2;
      } else if (midX > start.dx && end.dy < midY) {
        // Curve top-right
        startAngle = 0;
        sweepAngle = math.pi / 2;
      } else if (midX < start.dx && end.dy > midY) {
        // Curve bottom-left
        startAngle = math.pi;
        sweepAngle = math.pi / 2;
      } else {
        // Curve top-left
        startAngle = math.pi / 2;
        sweepAngle = math.pi / 2;
      }
      
      path.arcTo(rect, startAngle, sweepAngle, false);
      
      // Draw the final segment (vertical)
      path.lineTo(midX, end.dy);
      path.lineTo(end.dx, end.dy);
    } else {
      // Go vertical first
      final midX = start.dx;
      final midY = end.dy;
      
      // Calculate corner positions with insets for the curve
      final cornerX = midX + (end.dx > midX ? cornerRadius : -cornerRadius);
      final cornerY = midY - (midY > start.dy ? cornerRadius : -cornerRadius);
      
      // Draw the first segment (vertical)
      if ((cornerY - start.dy).abs() > cornerRadius) {
        path.lineTo(midX, cornerY);
      }
      
      // Draw the corner using an arc
      final rect = Rect.fromCenter(
        center: Offset(cornerX - (end.dx > midX ? cornerRadius : -cornerRadius), cornerY),
        width: 2 * cornerRadius,
        height: 2 * cornerRadius
      );
      
      // Determine the start angle and sweep based on the direction
      double startAngle, sweepAngle;
      if (end.dx > midX && midY > start.dy) {
        // Curve top-right
        startAngle = math.pi;
        sweepAngle = math.pi / 2;
      } else if (end.dx > midX && midY < start.dy) {
        // Curve bottom-right
        startAngle = math.pi / 2;
        sweepAngle = math.pi / 2;
      } else if (end.dx < midX && midY > start.dy) {
        // Curve top-left
        startAngle = 0;
        sweepAngle = -math.pi / 2;
      } else {
        // Curve bottom-left
        startAngle = 3 * math.pi / 2;
        sweepAngle = -math.pi / 2;
      }
      
      path.arcTo(rect, startAngle, sweepAngle, false);
      
      // Draw the final segment (horizontal)
      path.lineTo(end.dx, midY);
      path.lineTo(end.dx, end.dy);
    }
  }

  /// Checks if a bidirectional relationship exists between source and target.
  ///
  /// A bidirectional relationship is one where there are relationships in both
  /// directions between the same two elements.
  ///
  /// [relationship] The relationship to check.
  ///
  /// Returns true if a bidirectional relationship exists, false otherwise.
  bool _isBidirectionalRelationship(Relationship relationship) {
    // Check the bidirectional map first
    if (_bidirectionalRelationships.containsKey(relationship.id)) {
      return true;
    }
    
    // If we don't have an element bounds cache, we can't check this
    if (_elementBoundsCache.isEmpty) return false;
    
    // Look for a relationship going the other way
    // This is a simplistic implementation - a full implementation would need
    // access to the complete set of relationships
    final sourceId = relationship.sourceId;
    final destId = relationship.destinationId;
    
    // For testing purposes, assume bidirectional if tags contain 'bidirectional'
    return relationship.tags.contains('bidirectional');
  }

  /// Adjusts the start and end points for bidirectional relationships.
  ///
  /// This ensures that the two relationships in a bidirectional pair don't overlap.
  ///
  /// [relationship] The relationship to adjust points for.
  /// [start] The original start point.
  /// [end] The original end point.
  /// [sourceRect] The source element's bounds.
  /// [targetRect] The target element's bounds.
  ///
  /// Returns a tuple of adjusted (start, end) points.
  _Tuple<Offset, Offset> _adjustBidirectionalRelationshipPoints(
    Relationship relationship,
    Offset start,
    Offset end,
    Rect sourceRect,
    Rect targetRect,
  ) {
    // Calculate the angle between start and end points
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    
    // Perpendicular angle
    final perpAngle = angle + math.pi / 2;
    
    // Create the offset vector based on relationship direction
    // For testing, use the relationship order to determine direction
    // (a full implementation would need actual relationship direction data)
    final isFirstDirection = relationship.id.compareTo(relationship.destinationId) > 0;
    final direction = isFirstDirection ? 1.0 : -1.0;
    
    // Calculate distance-based offset amount
    final dist = (end - start).distance;
    final offsetAmount = math.max(_parallelRelationshipSpacing, dist * 0.08);
    
    final offsetX = math.cos(perpAngle) * offsetAmount * direction;
    final offsetY = math.sin(perpAngle) * offsetAmount * direction;
    final offset = Offset(offsetX, offsetY);
    
    // Adjust the start and end points
    final adjustedStart = start + offset;
    final adjustedEnd = end + offset;
    
    return _Tuple(adjustedStart, adjustedEnd);
  }

  /// Checks if a line segment would intersect with any of the given rectangles.
  ///
  /// [start] The start of the line segment.
  /// [end] The end of the line segment.
  /// [rects] The list of rectangles to check for intersection.
  ///
  /// Returns true if the line segment would intersect any rectangle, false otherwise.
  bool _wouldIntersectAny(Offset start, Offset end, List<Rect> rects) {
    for (final rect in rects) {
      // Skip if both points are inside the rectangle (internal connection)
      if (rect.contains(start) && rect.contains(end)) {
        continue;
      }
      
      // Check if either point is inside the rectangle
      if ((rect.contains(start) && !rect.contains(end)) ||
          (rect.contains(end) && !rect.contains(start))) {
        return true;
      }
      
      // Check for line-rectangle intersection
      if (_lineIntersectsRect(start, end, rect)) {
        return true;
      }
    }
    
    return false;
  }

  /// Checks if a line segment would intersect with either of the rectangles.
  ///
  /// [start] The start of the line segment.
  /// [end] The end of the line segment.
  /// [rect1] The first rectangle.
  /// [rect2] The second rectangle.
  ///
  /// Returns true if the line segment would intersect either rectangle, false otherwise.
  bool _wouldIntersect(Offset start, Offset end, Rect rect1, Rect rect2) {
    // Check if either point is inside either rectangle
    if (rect1.contains(start) || rect1.contains(end) || 
        rect2.contains(start) || rect2.contains(end)) {
      return true;
    }
    
    // Check for line-rectangle intersection
    return _lineIntersectsRect(start, end, rect1) || 
           _lineIntersectsRect(start, end, rect2);
  }
  
  /// Checks if a line segment intersects with a rectangle.
  ///
  /// [start] The start of the line segment.
  /// [end] The end of the line segment.
  /// [rect] The rectangle to check.
  ///
  /// Returns true if the line segment intersects the rectangle, false otherwise.
  bool _lineIntersectsRect(Offset start, Offset end, Rect rect) {
    // Check against all four edges of the rectangle
    return _linesIntersect(start, end, Offset(rect.left, rect.top), Offset(rect.right, rect.top)) || // top
           _linesIntersect(start, end, Offset(rect.right, rect.top), Offset(rect.right, rect.bottom)) || // right
           _linesIntersect(start, end, Offset(rect.right, rect.bottom), Offset(rect.left, rect.bottom)) || // bottom
           _linesIntersect(start, end, Offset(rect.left, rect.bottom), Offset(rect.left, rect.top)); // left
  }
  
  /// Checks if two line segments intersect.
  ///
  /// [a1] The start of the first line segment.
  /// [a2] The end of the first line segment.
  /// [b1] The start of the second line segment.
  /// [b2] The end of the second line segment.
  ///
  /// Returns true if the line segments intersect, false otherwise.
  bool _linesIntersect(Offset a1, Offset a2, Offset b1, Offset b2) {
    // Calculate direction vectors
    final ua_t = (b2.dx - b1.dx) * (a1.dy - b1.dy) - (b2.dy - b1.dy) * (a1.dx - b1.dx);
    final ub_t = (a2.dx - a1.dx) * (a1.dy - b1.dy) - (a2.dy - a1.dy) * (a1.dx - b1.dx);
    final u_b = (b2.dy - b1.dy) * (a2.dx - a1.dx) - (b2.dx - b1.dx) * (a2.dy - a1.dy);
    
    // If the lines are parallel (u_b == 0), they could be colinear but won't intersect
    if (u_b == 0) {
      return false;
    }
    
    // Calculate intersection parameters
    final ua = ua_t / u_b;
    final ub = ub_t / u_b;
    
    // If intersection parameters are both in [0,1], the segments intersect
    return ua >= 0 && ua <= 1 && ub >= 0 && ub <= 1;
  }
}