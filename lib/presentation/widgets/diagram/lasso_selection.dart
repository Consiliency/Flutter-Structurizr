import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart' hide Element, Container, View;

/// A utility class for implementing lasso selection in a diagram
class LassoSelection {
  /// The path of the lasso selection
  final Path _path = Path();
  
  /// Whether the lasso selection is active
  bool _isActive = false;
  
  /// Whether the lasso selection is complete
  bool _isComplete = false;
  
  /// Creates a new lasso selection
  LassoSelection();
  
  /// Starts a new lasso selection at the given position
  void start(Offset position) {
    _path.reset();
    _path.moveTo(position.dx, position.dy);
    _isActive = true;
    _isComplete = false;
  }
  
  /// Updates the lasso selection with a new position
  void update(Offset position) {
    if (!_isActive) return;
    _path.lineTo(position.dx, position.dy);
  }
  
  /// Completes the lasso selection
  void complete() {
    if (!_isActive) return;
    _path.close();
    _isActive = false;
    _isComplete = true;
  }
  
  /// Cancels the lasso selection
  void cancel() {
    _path.reset();
    _isActive = false;
    _isComplete = false;
  }
  
  /// Returns whether the lasso selection is active
  bool get isActive => _isActive;
  
  /// Returns whether the lasso selection is complete
  bool get isComplete => _isComplete;
  
  /// Returns the path of the lasso selection
  Path get path => _path;
  
  /// Tests if a point is inside the lasso selection
  bool containsPoint(Offset point) {
    if (!_isComplete) return false;
    return _path.contains(point);
  }
  
  /// Tests if a rectangle is intersecting or inside the lasso selection
  bool intersectsRect(Rect rect) {
    if (!_isComplete) return false;
    
    // Test each corner of the rectangle
    if (_path.contains(rect.topLeft) ||
        _path.contains(rect.topRight) ||
        _path.contains(rect.bottomLeft) ||
        _path.contains(rect.bottomRight)) {
      return true;
    }
    
    // Test the center point
    if (_path.contains(rect.center)) {
      return true;
    }
    
    // Test if any edge of the rectangle intersects the path
    // This is an approximate test that works in most cases
    final bounds = _path.getBounds();
    if (!rect.overlaps(bounds)) {
      return false;
    }
    
    // If we don't have a more precise path-rectangle intersection,
    // we'll use this approximation which works for most cases
    return true;
  }
  
  /// Paints the lasso selection on a canvas
  void paint(Canvas canvas, Paint paint) {
    if (_isActive || _isComplete) {
      canvas.drawPath(_path, paint);
    }
  }
}