// REMOVE: import 'dart:ui';
// typedef Color = String; // TODO: Replace with platform-specific color handling
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_structurizr/domain/model/element.dart';

part 'styles.freezed.dart';
part 'styles.g.dart';

/// Converts between a Color and a hex string
class ColorConverter implements JsonConverter<String?, String?> {
  const ColorConverter();

  @override
  String? fromJson(String? json) => _colorFromJson(json);

  @override
  String? toJson(String? object) => _colorToJson(object);
}

/// Represents a collection of styles for elements and relationships.
@freezed
class Styles with _$Styles {
  const Styles._();

  /// Creates a new styles collection with the given properties.
  const factory Styles({
    /// Styles for elements, keyed by tag.
    @Default([]) List<ElementStyle> elements,
    
    /// Styles for relationships, keyed by tag.
    @Default([]) List<RelationshipStyle> relationships,
    
    /// Theme colors for the workspace.
    @Default([]) List<String> themes,
  }) = _Styles;

  /// Creates a styles collection from a JSON object.
  factory Styles.fromJson(Map<String, dynamic> json) => _$StylesFromJson(json);

  /// Gets an element style for the given tags.
  /// Returns a merged style based on tag priority.
  ElementStyle getElementStyle(List<String> tags) {
    // Default style if no matches are found
    ElementStyle style = const ElementStyle();
    
    // For each tag, find matching styles and merge them in tag order
    for (final tag in tags) {
      final matchingStyles = elements.where(
        (style) => style.tag == tag,
      ).toList();
      
      if (matchingStyles.isNotEmpty) {
        // Merge all matching styles into the accumulated style
        for (final matchingStyle in matchingStyles) {
          style = style.merge(matchingStyle);
        }
      }
    }
    
    return style;
  }

  /// Gets a relationship style for the given tags.
  /// Returns a merged style based on tag priority.
  RelationshipStyle getRelationshipStyle(List<String> tags) {
    // Default style if no matches are found
    RelationshipStyle style = const RelationshipStyle();
    
    // For each tag, find matching styles and merge them in tag order
    for (final tag in tags) {
      final matchingStyles = relationships.where(
        (style) => style.tag == tag,
      ).toList();
      
      if (matchingStyles.isNotEmpty) {
        // Merge all matching styles into the accumulated style
        for (final matchingStyle in matchingStyles) {
          style = style.merge(matchingStyle);
        }
      }
    }
    
    return style;
  }

  /// Adds an element style to this styles collection.
  Styles addElementStyle(ElementStyle style) {
    return copyWith(elements: [...elements, style]);
  }

  /// Adds a relationship style to this styles collection.
  Styles addRelationshipStyle(RelationshipStyle style) {
    return copyWith(relationships: [...relationships, style]);
  }

  /// Adds a theme to this styles collection.
  Styles addTheme(String theme) {
    return copyWith(themes: [...themes, theme]);
  }

  /// Finds an element style for a specific element based on its tags.
  ElementStyle? findElementStyle(Element element) {
    if (element.tags.isEmpty) return null;

    // Find all matching styles for the element's tags
    final matchingStyles = elements.where((style) =>
      style.tag != null && element.tags.contains(style.tag)
    ).toList();

    if (matchingStyles.isEmpty) {
      return null;
    }

    // Merge all matching styles in tag order
    ElementStyle merged = const ElementStyle();
    for (final tag in element.tags) {
      for (final style in matchingStyles.where((s) => s.tag == tag)) {
        merged = merged.merge(style);
      }
    }
    return merged;
  }

  /// Finds a relationship style for a specific relationship based on its tags.
  RelationshipStyle? findRelationshipStyle(Relationship relationship) {
    if (relationship.tags.isEmpty) return null;

    // Get the merged style for all tags
    return getRelationshipStyle(relationship.tags);
  }
}

/// Styles for architecture elements.
@freezed
class ElementStyle with _$ElementStyle {
  const ElementStyle._();

  /// Creates a new element style with the given properties.
  const factory ElementStyle({
    /// The tag this style applies to.
    String? tag,

    /// The shape of the element.
    @Default(Shape.box) Shape shape,

    /// Icon URL or data URI.
    String? icon,

    /// Width in pixels.
    int? width,

    /// Height in pixels.
    int? height,

    /// Background color.
    @ColorConverter() String? background,

    /// Text color.
    @ColorConverter() String? color,

    /// Border color.
    @ColorConverter() String? stroke,

    /// Border thickness (1-10px).
    int? strokeWidth,

    /// Border style.
    @Default(Border.solid) Border border,

    /// Opacity (0-100).
    @Default(100) int opacity,

    /// Font size in pixels.
    int? fontSize,

    /// Whether to show metadata.
    bool? metadata,

    /// Whether to show description.
    bool? description,
    
    /// Position of the label on the element.
    LabelPosition? labelPosition,
  }) = _ElementStyle;

  /// Creates an element style from a JSON object.
  factory ElementStyle.fromJson(Map<String, dynamic> json) => _$ElementStyleFromJson(json);

  /// Merges this style with another style.
  /// Properties from the other style take precedence if they are not null.
  ElementStyle merge(ElementStyle other) {
    return ElementStyle(
      tag: other.tag ?? tag,
      shape: other.shape,
      icon: other.icon ?? icon,
      width: other.width ?? width,
      height: other.height ?? height,
      background: other.background ?? background,
      color: other.color ?? color,
      stroke: other.stroke ?? stroke,
      strokeWidth: other.strokeWidth ?? strokeWidth,
      border: other.border,
      opacity: other.opacity,
      fontSize: other.fontSize ?? fontSize,
      metadata: other.metadata ?? metadata,
      description: other.description ?? description,
      labelPosition: other.labelPosition ?? labelPosition,
    );
  }
}

/// Styles for relationships between elements.
@freezed
class RelationshipStyle with _$RelationshipStyle {
  const RelationshipStyle._();

  /// Creates a new relationship style with the given properties.
  const factory RelationshipStyle({
    /// The tag this style applies to.
    String? tag,

    /// Line thickness in pixels.
    @Default(1) int thickness,

    /// Line color.
    @ColorConverter() String? color,

    /// Line style.
    @Default(LineStyle.solid) LineStyle style,

    /// Routing mode.
    @Default(StyleRouting.direct) StyleRouting routing,

    /// Font size for labels.
    int? fontSize,

    /// Width constraint for labels.
    int? width,

    /// Position of the label along the line (0-100%).
    @Default(50) int position,

    /// Opacity (0-100).
    @Default(100) int opacity,
  }) = _RelationshipStyle;

  /// Creates a relationship style from a JSON object.
  factory RelationshipStyle.fromJson(Map<String, dynamic> json) => _$RelationshipStyleFromJson(json);

  /// Merges this style with another style.
  /// Properties from the other style take precedence if they are not null.
  RelationshipStyle merge(RelationshipStyle other) {
    return RelationshipStyle(
      tag: other.tag ?? tag,
      thickness: other.thickness,
      color: other.color ?? color,
      style: other.style,
      routing: other.routing,
      fontSize: other.fontSize ?? fontSize,
      width: other.width ?? width,
      position: other.position,
      opacity: other.opacity,
    );
  }
}

/// Shape types for elements.
enum Shape {
  box,
  roundedBox,
  circle,
  ellipse,
  hexagon,
  cylinder,
  pipe,
  person,
  robot,
  folder,
  webBrowser,
  mobileDevicePortrait,
  mobileDeviceLandscape,
  component,
}

/// Border styles for elements.
enum Border {
  solid,
  dashed,
  dotted,
}

/// Line styles for relationships.
enum LineStyle {
  solid,
  dashed,
  dotted,
}

/// Routing modes for relationships.
enum StyleRouting {
  direct,
  curved,
  orthogonal,
}

/// Position of labels on elements.
enum LabelPosition {
  top,
  center,
  bottom,
}

// This is intentionally removed as we already have a ColorConverter class above

String? _colorFromJson(String? hexString) {
  if (hexString == null) return null;
  
  // Remove any leading # character
  final hex = hexString.startsWith('#') ? hexString.substring(1) : hexString;
  
  // Parse the hex color
  if (hex.length == 6) {
    final r = int.parse(hex.substring(0, 2), radix: 16);
    final g = int.parse(hex.substring(2, 4), radix: 16);
    final b = int.parse(hex.substring(4, 6), radix: 16);
    return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
  } else if (hex.length == 8) {
    final a = int.parse(hex.substring(0, 2), radix: 16);
    final r = int.parse(hex.substring(2, 4), radix: 16);
    final g = int.parse(hex.substring(4, 6), radix: 16);
    final b = int.parse(hex.substring(6, 8), radix: 16);
    return '#${a.toRadixString(16).padLeft(2, '0')}${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
  }
  
  return null;
}

String? _colorToJson(String? color) {
  if (color == null) return null;
  
  return color;
}