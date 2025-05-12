import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// A mock Canvas for testing rendering operations.
class MockCanvas implements Canvas {
  final List<Rect> drawnRects = [];
  final List<RRect> drawnRRects = [];
  final List<Path> drawnPaths = [];
  final List<Circle> drawnCircles = [];
  final List<Line> drawnLines = [];
  final List<TextPainter> drawnTexts = [];
  final List<Offset> drawnTextOffsets = [];

  /// Records a drawn rectangle
  @override
  void drawRect(Rect rect, Paint paint) {
    drawnRects.add(rect);
  }
  
  /// Records a drawn rounded rectangle
  @override
  void drawRRect(RRect rrect, Paint paint) {
    drawnRRects.add(rrect);
  }
  
  /// Records a drawn path
  @override
  void drawPath(Path path, Paint paint) {
    drawnPaths.add(path);
  }
  
  /// Records a drawn circle
  @override
  void drawCircle(Offset c, double radius, Paint paint) {
    drawnCircles.add(Circle(c, radius));
  }
  
  /// Records a drawn line
  @override
  void drawLine(Offset p1, Offset p2, Paint paint) {
    drawnLines.add(Line(p1, p2));
  }
  
  /// Clears all recorded drawing operations
  void clear() {
    drawnRects.clear();
    drawnRRects.clear();
    drawnPaths.clear();
    drawnCircles.clear();
    drawnLines.clear();
    drawnTexts.clear();
    drawnTextOffsets.clear();
  }
  
  /// Records saving the canvas state
  @override
  void save() {}
  
  /// Records restoring the canvas state
  @override
  void restore() {}
  
  /// Records applying a translation transformation
  @override
  void translate(double dx, double dy) {}
  
  /// Records applying a rotation transformation
  @override
  void rotate(double radians) {}
  
  /// Records applying a scale transformation
  @override
  void scale(double sx, [double? sy]) {}
  
  /// Records applying a transformation matrix
  @override
  void transform(Float64List matrix4) {}
  
  /// Handles all other Canvas methods not explicitly implemented
  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Handle text painting (called from TextPainter.paint)
    if (invocation.memberName == #drawParagraph) {
      // This is triggered when TextPainter.paint() is called on this canvas
      return null;
    }
    return null;
  }
}

/// Captures information about a drawn circle
class Circle {
  final Offset center;
  final double radius;
  
  Circle(this.center, this.radius);
  
  @override
  String toString() => 'Circle(center: $center, radius: $radius)';
}

/// Captures information about a drawn line
class Line {
  final Offset start;
  final Offset end;
  
  Line(this.start, this.end);
  
  @override
  String toString() => 'Line(start: $start, end: $end)';
}

/// Extension on MockCanvas to record text painter operations
extension TextPainterRecording on MockCanvas {
  void recordTextPainter(TextPainter painter, Offset offset) {
    drawnTexts.add(painter);
    drawnTextOffsets.add(offset);
  }
}