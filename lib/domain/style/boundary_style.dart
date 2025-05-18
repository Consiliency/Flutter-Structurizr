// REMOVE: import 'dart:ui';
// typedef Color = String; // TODO: Replace with platform-specific color handling

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';

part 'boundary_style.freezed.dart';
part 'boundary_style.g.dart';

/// Style specifically for boundary elements in architecture diagrams.
///
/// Boundary elements include container boundaries, enterprise boundaries,
/// and any other visual grouping of elements.
@freezed
class BoundaryStyle with _$BoundaryStyle {
  const BoundaryStyle._();

  /// Creates a new boundary style with the given properties.
  const factory BoundaryStyle({
    /// The tag this style applies to.
    String? tag,

    /// The shape of the boundary.
    @Default(Shape.roundedBox) Shape shape,

    /// Background color.
    @ColorConverter() String? background,

    /// Text color.
    @ColorConverter() String? color,

    /// Border color.
    @ColorConverter() String? stroke,

    /// Border thickness (1-10px).
    int? strokeWidth,

    /// Border style.
    @Default(Border.dashed) Border border,

    /// Opacity (0-100).
    @Default(30) int opacity,

    /// Font size in pixels.
    int? fontSize,

    /// Padding around contained elements.
    @Default(20) int padding,
  }) = _BoundaryStyle;

  /// Creates a boundary style from a JSON object.
  factory BoundaryStyle.fromJson(Map<String, dynamic> json) => _$BoundaryStyleFromJson(json);

  /// Merges this style with another style.
  /// Properties from the other style take precedence if they are not null.
  BoundaryStyle merge(BoundaryStyle other) {
    return BoundaryStyle(
      tag: other.tag ?? tag,
      shape: other.shape,
      background: other.background ?? background,
      color: other.color ?? color,
      stroke: other.stroke ?? stroke,
      strokeWidth: other.strokeWidth ?? strokeWidth,
      border: other.border,
      opacity: other.opacity,
      fontSize: other.fontSize ?? fontSize,
      padding: other.padding,
    );
  }

  /// Converts the boundary style to an element style.
  ElementStyle toElementStyle() {
    return ElementStyle(
      tag: tag,
      shape: shape,
      background: background,
      color: color,
      stroke: stroke,
      strokeWidth: strokeWidth,
      border: border,
      opacity: opacity,
      fontSize: fontSize,
    );
  }
}