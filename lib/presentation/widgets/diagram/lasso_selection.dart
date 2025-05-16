import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart' hide Element, Container, View;
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/relationship.dart';

/// A utility class for implementing lasso selection in a diagram
class LassoSelection {
  /// The path of the lasso selection
  final Path _path = Path();
  
  /// The polygon points of the lasso selection for hit testing
  final List<Offset> _points = [];
  
  /// Whether the lasso selection is active
  bool _isActive = false;
  
  /// Whether the lasso selection is complete
  bool _isComplete = false;
  
  /// Minimum distance between points to add to the polygon
  final double _minPointDistance = 5.0;
  
  /// Last added point
  Offset? _lastAddedPoint;
  
  /// Selected element IDs
  final Set<String> _selectedElementIds = {};
  
  /// Selected relationship IDs
  final Set<String> _selectedRelationshipIds = {};
  
  /// Creates a new lasso selection
  LassoSelection();
  
  /// Starts a new lasso selection at the given position
  void start(Offset position) {
    _path.reset();
    _path.moveTo(position.dx, position.dy);
    _points.clear();
    _points.add(position);
    _lastAddedPoint = position;
    _isActive = true;
    _isComplete = false;
    _selectedElementIds.clear();
    _selectedRelationshipIds.clear();
  }
  
  /// Updates the lasso selection with a new position
  void update(Offset position) {
    if (!_isActive) return;
    
    // Add to path
    _path.lineTo(position.dx, position.dy);
    
    // Add to points list if it's far enough from the last point
    if (_lastAddedPoint != null) {
      final distance = (position - _lastAddedPoint!).distance;
      if (distance >= _minPointDistance) {
        _points.add(position);
        _lastAddedPoint = position;
      }
    }
  }
  
  /// Completes the lasso selection
  void complete() {
    if (!_isActive) return;
    
    // Close the path
    _path.close();
    
    // Add the first point again to close the polygon
    if (_points.isNotEmpty && _points.length > 2) {
      _points.add(_points.first);
    }
    
    _isActive = false;
    _isComplete = true;
  }
  
  /// Cancels the lasso selection
  void cancel() {
    _path.reset();
    _points.clear();
    _lastAddedPoint = null;
    _isActive = false;
    _isComplete = false;
    _selectedElementIds.clear();
    _selectedRelationshipIds.clear();
  }
  
  /// Updates the selected element IDs
  void setSelectedElements(Set<String> elementIds) {
    _selectedElementIds.clear();
    _selectedElementIds.addAll(elementIds);
  }
  
  /// Updates the selected relationship IDs
  void setSelectedRelationships(Set<String> relationshipIds) {
    _selectedRelationshipIds.clear();
    _selectedRelationshipIds.addAll(relationshipIds);
  }
  
  /// Returns whether the lasso selection is active
  bool get isActive => _isActive;
  
  /// Returns whether the lasso selection is complete
  bool get isComplete => _isComplete;
  
  /// Returns the path of the lasso selection
  Path get path => _path;
  
  /// Returns the set of selected element IDs
  Set<String> get selectedElementIds => Set.unmodifiable(_selectedElementIds);
  
  /// Returns the set of selected relationship IDs
  Set<String> get selectedRelationshipIds => Set.unmodifiable(_selectedRelationshipIds);
  
  /// Returns the points of the lasso selection for visualization
  List<Offset> getPoints() => List.unmodifiable(_points);
  
  /// Tests if a point is inside the lasso selection
  bool containsPoint(Offset point) {
    if (!_isComplete || _points.length < 3) return false;
    
    // Use point-in-polygon algorithm for accurate hit testing
    return _isPointInPolygon(point, _points);
  }
  
  /// Tests if a rectangle is intersecting or inside the lasso selection
  bool intersectsRect(Rect rect) {
    if (!_isComplete || _points.length < 3) return false;
    
    // Optimization: Check bounds overlap first
    final bounds = _path.getBounds();
    if (!rect.overlaps(bounds)) {
      return false;
    }
    
    // Check if any corner of the rectangle is inside the lasso
    if (containsPoint(rect.topLeft) ||
        containsPoint(rect.topRight) ||
        containsPoint(rect.bottomLeft) ||
        containsPoint(rect.bottomRight)) {
      return true;
    }
    
    // Check if the center is inside
    if (containsPoint(rect.center)) {
      return true;
    }
    
    // Check if any edge of the polygon intersects with any edge of the rectangle
    for (int i = 0; i < _points.length - 1; i++) {
      final p1 = _points[i];
      final p2 = _points[i + 1];
      
      // Check intersection with all 4 sides of the rectangle
      if (_lineIntersectsLine(p1, p2, rect.topLeft, rect.topRight) ||
          _lineIntersectsLine(p1, p2, rect.topRight, rect.bottomRight) ||
          _lineIntersectsLine(p1, p2, rect.bottomRight, rect.bottomLeft) ||
          _lineIntersectsLine(p1, p2, rect.bottomLeft, rect.topLeft)) {
        return true;
      }
    }
    
    // If we've reached here and haven't found an intersection,
    // check if the rectangle completely contains the lasso
    if (_points.every((point) => rect.contains(point))) {
      return true;
    }
    
    return false;
  }
  
  /// Tests if a relationship line is intersecting the lasso selection
  bool intersectsRelationship(Offset source, Offset target) {
    if (!_isComplete || _points.length < 3) return false;
    
    // Check if either endpoint is inside the lasso
    if (containsPoint(source) || containsPoint(target)) {
      return true;
    }
    
    // Check if the relationship line intersects with any edge of the polygon
    for (int i = 0; i < _points.length - 1; i++) {
      if (_lineIntersectsLine(_points[i], _points[i + 1], source, target)) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Implements the point-in-polygon algorithm (ray casting)
  bool _isPointInPolygon(Offset point, List<Offset> polygon) {
    if (polygon.length < 3) return false;
    
    bool isInside = false;
    final x = point.dx;
    final y = point.dy;
    
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final xi = polygon[i].dx;
      final yi = polygon[i].dy;
      final xj = polygon[j].dx;
      final yj = polygon[j].dy;
      
      final intersect = ((yi > y) != (yj > y)) && 
          (x < (xj - xi) * (y - yi) / (yj - yi) + xi);
      
      if (intersect) isInside = !isInside;
    }
    
    return isInside;
  }
  
  /// Line segment intersection test
  bool _lineIntersectsLine(Offset a, Offset b, Offset c, Offset d) {
    // Calculate the cross products
    final ccw1 = _ccw(a, c, d);
    final ccw2 = _ccw(b, c, d);
    final ccw3 = _ccw(a, b, c);
    final ccw4 = _ccw(a, b, d);
    
    // Check if the line segments intersect - using strict inequality to avoid false positives
    // when lines are collinear but not overlapping
    if (ccw1 == 0 && ccw2 == 0 && ccw3 == 0 && ccw4 == 0) {
      // Collinear - check if they overlap
      return _isOverlapping(a.dx, b.dx, c.dx, d.dx) && _isOverlapping(a.dy, b.dy, c.dy, d.dy);
    }
    
    return (ccw1 * ccw2 < 0) && (ccw3 * ccw4 < 0);
  }
  
  /// Helper method to determine if two line segments overlap
  bool _isOverlapping(double a1, double a2, double b1, double b2) {
    if (a1 > a2) {
      final temp = a1;
      a1 = a2;
      a2 = temp;
    }
    if (b1 > b2) {
      final temp = b1;
      b1 = b2;
      b2 = temp;
    }
    return math.max(a1, b1) <= math.min(a2, b2);
  }
  
  /// Counter-clockwise test for three points
  int _ccw(Offset a, Offset b, Offset c) {
    final val = (b.dy - a.dy) * (c.dx - b.dx) - (b.dx - a.dx) * (c.dy - b.dy);
    if (val == 0) return 0;      // Collinear
    return val > 0 ? 1 : -1;     // Clockwise or Counterclockwise
  }
  
  /// Paints the lasso selection on a canvas
  void paint(Canvas canvas, Paint paint) {
    if (_isActive || _isComplete) {
      canvas.drawPath(_path, paint);
    }
  }
}