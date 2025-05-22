import 'package:flutter/material.dart' hide Element;
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';
import 'package:flutter_structurizr/domain/view/view.dart';

/// A base class for all renderers in the Structurizr diagram system.
///
/// This abstract class defines the core interface that all renderers must implement,
/// providing consistent methods for rendering elements, relationships, and handling
/// user interactions such as hit testing.
abstract class BaseRenderer {
  /// Renders an element on the provided canvas.
  ///
  /// [canvas] The canvas to render on.
  /// [element] The element to render.
  /// [elementView] The view-specific properties for the element.
  /// [style] The style to apply when rendering the element.
  /// [selected] Whether the element is currently selected.
  /// [hovered] Whether the element is currently being hovered over.
  void renderElement({
    required Canvas canvas,
    required Element element,
    required ElementView elementView,
    required ElementStyle style,
    bool selected = false,
    bool hovered = false,
    bool includeNames = true,
    bool includeDescriptions = false,
  });

  /// Renders a relationship on the provided canvas.
  ///
  /// [canvas] The canvas to render on.
  /// [relationship] The relationship to render.
  /// [relationshipView] The view-specific properties for the relationship.
  /// [style] The style to apply when rendering the relationship.
  /// [sourceRect] The bounding rectangle of the source element.
  /// [targetRect] The bounding rectangle of the target element.
  /// [selected] Whether the relationship is currently selected.
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
  });

  /// Calculates the bounds of an element.
  ///
  /// [element] The element to calculate bounds for.
  /// [elementView] The view-specific properties for the element.
  /// [style] The style applied to the element.
  ///
  /// Returns a [Rect] representing the bounds of the element.
  Rect calculateElementBounds({
    required Element element,
    required ElementView elementView,
    required ElementStyle style,
  });

  /// Calculates the path for a relationship.
  ///
  /// [relationship] The relationship to calculate the path for.
  /// [relationshipView] The view-specific properties for the relationship.
  /// [style] The style applied to the relationship.
  /// [sourceRect] The bounding rectangle of the source element.
  /// [targetRect] The bounding rectangle of the target element.
  ///
  /// Returns a [Path] representing the relationship.
  Path calculateRelationshipPath({
    required Relationship relationship,
    required RelationshipView relationshipView,
    required RelationshipStyle style,
    required Rect sourceRect,
    required Rect targetRect,
  });

  /// Performs hit testing to determine if a point is within an element.
  ///
  /// [point] The point to test.
  /// [element] The element to test against.
  /// [elementView] The view-specific properties for the element.
  /// [style] The style applied to the element.
  ///
  /// Returns true if the point is within the element, false otherwise.
  bool hitTestElement({
    required Offset point,
    required Element element,
    required ElementView elementView,
    required ElementStyle style,
  });

  /// Performs hit testing to determine if a point is on a relationship.
  ///
  /// [point] The point to test.
  /// [relationship] The relationship to test against.
  /// [relationshipView] The view-specific properties for the relationship.
  /// [style] The style applied to the relationship.
  /// [sourceRect] The bounding rectangle of the source element.
  /// [targetRect] The bounding rectangle of the target element.
  /// [hitTolerance] The distance tolerance for hit testing (in logical pixels).
  ///
  /// Returns true if the point is on the relationship, false otherwise.
  bool hitTestRelationship({
    required Offset point,
    required Relationship relationship,
    required RelationshipView relationshipView,
    required RelationshipStyle style,
    required Rect sourceRect,
    required Rect targetRect,
    double hitTolerance = 8.0,
  });

  /// Creates a text painter for rendering text in the diagram.
  ///
  /// [text] The text to be rendered.
  /// [style] The text style to apply.
  /// [maxWidth] The maximum width of the text.
  ///
  /// Returns a configured [TextPainter] ready to be used.
  TextPainter createTextPainter({
    required String text,
    required TextStyle style,
    double? maxWidth,
  }) {
    final textSpan = TextSpan(
      text: text,
      style: style,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout(minWidth: 0, maxWidth: maxWidth ?? double.infinity);
    return textPainter;
  }

  /// Finds the intersection point of a line with a rectangle.
  ///
  /// This is useful for positioning relationship lines to connect to elements.
  ///
  /// [rect] The rectangle (usually an element's bounds).
  /// [point] A point outside the rectangle.
  ///
  /// Returns the [Offset] where the line from the center of the rectangle
  /// to the point intersects with the rectangle's edge.
  Offset findIntersectionPoint(Rect rect, Offset point) {
    final center = rect.center;

    // If the point is inside the rectangle, return the point
    if (rect.contains(point)) {
      return point;
    }

    // Calculate the slope of the line connecting the center and the point
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;

    // Avoid division by zero
    final slope = dx != 0 ? dy / dx : double.infinity;

    // Find intersection with each edge of the rectangle
    final List<Offset> intersections = [];

    // Top edge
    if (dy < 0) {
      final x = center.dx + (rect.top - center.dy) / slope;
      if (x >= rect.left && x <= rect.right) {
        intersections.add(Offset(x, rect.top));
      }
    }

    // Bottom edge
    if (dy > 0) {
      final x = center.dx + (rect.bottom - center.dy) / slope;
      if (x >= rect.left && x <= rect.right) {
        intersections.add(Offset(x, rect.bottom));
      }
    }

    // Left edge
    if (dx < 0) {
      final y = slope * (rect.left - center.dx) + center.dy;
      if (y >= rect.top && y <= rect.bottom) {
        intersections.add(Offset(rect.left, y));
      }
    }

    // Right edge
    if (dx > 0) {
      final y = slope * (rect.right - center.dx) + center.dy;
      if (y >= rect.top && y <= rect.bottom) {
        intersections.add(Offset(rect.right, y));
      }
    }

    // Find the intersection that is closest to the external point
    if (intersections.isEmpty) {
      return center; // Fallback
    }

    double minDistance = double.infinity;
    Offset closestIntersection = intersections.first;

    for (final intersection in intersections) {
      final distance = (intersection - point).distance;
      if (distance < minDistance) {
        minDistance = distance;
        closestIntersection = intersection;
      }
    }

    return closestIntersection;
  }

  /// Calculates the distance from a point to a line segment.
  ///
  /// This is useful for hit testing relationships.
  ///
  /// [point] The point to measure from.
  /// [lineStart] The start point of the line segment.
  /// [lineEnd] The end point of the line segment.
  ///
  /// Returns the shortest distance from the point to the line segment.
  double distanceToLineSegment(Offset point, Offset lineStart, Offset lineEnd) {
    final a = point - lineStart;
    final b = lineEnd - lineStart;
    final projection = a.dx * b.dx + a.dy * b.dy;
    final bLengthSquared = b.dx * b.dx + b.dy * b.dy;

    // Avoid division by zero
    if (bLengthSquared == 0) {
      return a.distance;
    }

    final t = projection / bLengthSquared;

    if (t < 0) {
      return a.distance;
    } else if (t > 1) {
      return (point - lineEnd).distance;
    } else {
      final projection = lineStart + b * t;
      return (point - projection).distance;
    }
  }
}
