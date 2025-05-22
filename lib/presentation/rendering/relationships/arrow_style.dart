import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';

/// Helper class for arrowhead styling and rendering in relationship paths.
///
/// This class provides methods to create and render different arrowhead styles that
/// are used at the end points of relationships in architectural diagrams.
class ArrowStyle {
  /// Size of the arrowhead in logical pixels.
  final double size;

  /// Creates a new arrow style with the specified size.
  ///
  /// [size] The size of the arrowhead in logical pixels. Default is 8.0.
  const ArrowStyle({this.size = 8.0});

  /// Creates a path for a standard arrowhead.
  ///
  /// [endPoint] The point where the arrowhead should be positioned.
  /// [angle] The angle of the arrowhead in radians.
  /// [color] The color to use for the arrowhead.
  /// [filled] Whether the arrowhead should be filled or outlined.
  ///
  /// Returns a [Path] representing the arrowhead.
  Path createStandardArrowhead(
    Offset endPoint,
    double angle,
    Color color, {
    bool filled = true,
  }) {
    final path = Path();

    // Calculate the three points of the arrowhead
    final point1 =
        _calculatePointOnCircle(endPoint, angle + math.pi * 0.8, size);
    final point2 = endPoint;
    final point3 =
        _calculatePointOnCircle(endPoint, angle - math.pi * 0.8, size);

    // Draw the arrowhead
    path.moveTo(point1.dx, point1.dy);
    path.lineTo(point2.dx, point2.dy);
    path.lineTo(point3.dx, point3.dy);

    // Close the path if the arrowhead should be filled
    if (filled) {
      path.close();
    }

    return path;
  }

  /// Creates a path for a diamond arrowhead (often used for aggregation relationships).
  ///
  /// [endPoint] The point where the arrowhead should be positioned.
  /// [angle] The angle of the arrowhead in radians.
  /// [color] The color to use for the arrowhead.
  /// [filled] Whether the arrowhead should be filled or outlined.
  ///
  /// Returns a [Path] representing the diamond arrowhead.
  Path createDiamondArrowhead(
    Offset endPoint,
    double angle,
    Color color, {
    bool filled = false,
  }) {
    final path = Path();

    // Calculate the four points of the diamond
    final point1 = endPoint;
    final point2 =
        _calculatePointOnCircle(endPoint, angle + math.pi / 2, size * 0.5);
    final point3 = _calculatePointOnCircle(endPoint, angle + math.pi, size);
    final point4 =
        _calculatePointOnCircle(endPoint, angle - math.pi / 2, size * 0.5);

    // Draw the diamond
    path.moveTo(point1.dx, point1.dy);
    path.lineTo(point2.dx, point2.dy);
    path.lineTo(point3.dx, point3.dy);
    path.lineTo(point4.dx, point4.dy);
    path.close();

    return path;
  }

  /// Creates a path for a circle arrowhead (often used for composition relationships).
  ///
  /// [endPoint] The point where the arrowhead should be positioned.
  /// [angle] The angle of the arrowhead in radians.
  /// [color] The color to use for the arrowhead.
  /// [filled] Whether the arrowhead should be filled or outlined.
  ///
  /// Returns a [Path] representing the circle arrowhead.
  Path createCircleArrowhead(
    Offset endPoint,
    double angle,
    Color color, {
    bool filled = true,
  }) {
    final path = Path();

    // Calculate the center point for the circle, offset from the end point
    final circleCenter =
        _calculatePointOnCircle(endPoint, angle + math.pi, size);

    // Draw the circle
    path.addOval(Rect.fromCircle(center: circleCenter, radius: size * 0.6));

    return path;
  }

  /// Draws the appropriate arrowhead based on relationship style.
  ///
  /// [canvas] The canvas to draw on.
  /// [endPoint] The point where the arrowhead should be positioned.
  /// [angle] The angle of the arrowhead in radians.
  /// [style] The relationship style to apply.
  /// [paint] The paint to use for drawing.
  void drawArrowhead(
    Canvas canvas,
    Offset endPoint,
    double angle,
    RelationshipStyle style,
    Paint paint,
  ) {
    final arrowheadPath = createStandardArrowhead(endPoint, angle, paint.color);

    // Create a filled arrowhead
    final fillPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;

    canvas.drawPath(arrowheadPath, fillPaint);
  }

  /// Helper method to calculate a point on a circle at a specific angle.
  ///
  /// [center] The center of the circle.
  /// [angle] The angle in radians.
  /// [radius] The radius of the circle.
  ///
  /// Returns an [Offset] representing the point on the circle.
  Offset _calculatePointOnCircle(Offset center, double angle, double radius) {
    return Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
  }

  /// Calculate the angle between two points in radians.
  ///
  /// [from] The starting point.
  /// [to] The ending point.
  ///
  /// Returns the angle in radians.
  static double calculateAngle(Offset from, Offset to) {
    return math.atan2(to.dy - from.dy, to.dx - from.dx);
  }

  /// Creates a custom arrowhead based on the specified relationship style.
  ///
  /// [endPoint] The point where the arrowhead should be positioned.
  /// [angle] The angle of the arrowhead in radians.
  /// [style] The relationship style to apply.
  ///
  /// Returns a [Path] representing the custom arrowhead.
  Path createArrowheadForStyle(
    Offset endPoint,
    double angle,
    RelationshipStyle style,
  ) {
    // Default to standard arrowhead
    // In a real implementation, you would examine style properties to determine
    // the appropriate arrowhead type
    Color color = Colors.black;
    if (style.color != null) {
      // Convert hex string to Color
      final hexColor = style.color!.replaceAll('#', '');
      if (hexColor.length == 6) {
        color = Color(int.parse('FF$hexColor', radix: 16));
      }
    }
    return createStandardArrowhead(endPoint, angle, color);
  }
}
