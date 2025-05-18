import 'dart:math' as math;

import 'package:flutter/material.dart' hide Element, Container, Border;
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/style/styles.dart' as styles;
import 'package:flutter_structurizr/domain/style/styles.dart' hide Border;
import 'package:flutter_structurizr/domain/style/boundary_style.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/presentation/rendering/base_renderer.dart';
import 'package:collection/collection.dart';
import 'package:flutter_structurizr/domain/model/container.dart' show Container;

/// Renderer for boundary elements in a Structurizr diagram.
///
/// This renderer handles the visualization of container and enterprise boundaries
/// in architecture diagrams, providing visual grouping and nesting for elements.
///
/// Boundaries can be nested to any depth, with visual distinctions between nesting
/// levels. They support different styling based on boundary type or tags, and can
/// be configured to show or hide their contents.
class BoundaryRenderer extends BaseRenderer {
  /// Default padding around the boundary
  static const double defaultPadding = 20.0;

  /// Default padding between the label and the boundary box
  static const double labelPadding = 10.0;

  /// Default border radius for rounded boundaries
  static const double defaultBorderRadius = 12.0;

  /// Default opacity for boundaries
  static const double defaultOpacity = 0.3;

  /// Default label font size
  static const double defaultLabelFontSize = 14.0;

  /// Default stroke width
  static const double defaultStrokeWidth = 1.0;

  /// Default label background padding
  static const EdgeInsets labelBackgroundPadding = EdgeInsets.symmetric(
    horizontal: 8.0,
    vertical: 4.0,
  );

  /// Default nesting level opacity reduction factor
  /// Each nesting level reduces opacity by this factor
  static const double nestingOpacityFactor = 0.85;

  /// Maximum nesting levels with distinct visual styling
  static const int maxDistinctNestingLevels = 5;

  /// Default colors for different nesting levels
  static const List<Color> nestingLevelColors = [
    Color(0xFF607D8B), // Blue Grey
    Color(0xFF78909C), // Blue Grey 400
    Color(0xFF90A4AE), // Blue Grey 300
    Color(0xFFB0BEC5), // Blue Grey 200
    Color(0xFFCFD8DC), // Blue Grey 100
  ];

  /// Color variation for nested boundaries with the same parent
  static const List<Color> siblingVariationColors = [
    Color(0xFF3F51B5), // Indigo
    Color(0xFF2196F3), // Blue
    Color(0xFF03A9F4), // Light Blue
    Color(0xFF00BCD4), // Cyan
    Color(0xFF009688), // Teal
  ];

  /// Flag to control whether boundaries can be collapsed
  final bool enableCollapsible;

  /// Constructor with optional configuration
  BoundaryRenderer({this.enableCollapsible = true});

  /// Helper to parse a hex color string (e.g., '#FF0000' or 'FF0000FF') to a Color
  Color? parseColor(String? hex) {
    if (hex == null) return null;
    final cleaned = hex.startsWith('#') ? hex.substring(1) : hex;
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    } else if (cleaned.length == 8) {
      return Color(int.parse(cleaned, radix: 16));
    }
    return null;
  }

  /// Renders an enterprise boundary or container boundary
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
    // Use the general renderBoundary method with an empty list of child rects
    // This is called for normal element rendering
    renderBoundary(
      canvas: canvas,
      element: element,
      bounds: calculateElementBounds(
        element: element,
        elementView: elementView,
        style: style,
      ),
      style: style,
      childRects: const [],
      selected: selected,
      hovered: hovered,
    );
  }

  /// Renders a boundary with contained elements
  ///
  /// This is a more sophisticated boundary rendering method that takes into
  /// account child rectangles for proper sizing and nesting.
  ///
  /// [canvas] The canvas to render on.
  /// [element] The boundary element to render.
  /// [bounds] The boundary element's bounds.
  /// [style] The style to apply to the boundary.
  /// [childRects] The rectangles of the child elements.
  /// [selected] Whether the boundary is selected.
  /// [hovered] Whether the boundary is being hovered over.
  /// [nestingLevel] The nesting level of this boundary (0 for top level).
  /// [parentType] The type of the parent boundary, if any.
  /// [siblingIndex] Index among siblings with the same parent (for color variations).
  /// [isCollapsed] Whether this boundary is collapsed (hiding its contents).
  void renderBoundary({
    required Canvas canvas,
    required Element element,
    required Rect bounds,
    required ElementStyle style,
    required List<Rect> childRects,
    bool selected = false,
    bool hovered = false,
    int nestingLevel = 0,
    String? parentType,
    int siblingIndex = 0,
    bool isCollapsed = false,
  }) {
    // Create a BoundaryStyle from the ElementStyle if available
    // This provides access to boundary-specific properties like padding
    final BoundaryStyle boundaryStyle = _elementToBoundaryStyle(style);

    // Get the effective padding (from boundaryStyle or default)
    final effectivePadding = boundaryStyle.padding.toDouble() ?? defaultPadding;

    // Calculate the boundary rect based on contained elements
    // If there are child rectangles, calculate a boundary that encompasses them plus padding
    Rect rect;
    if (childRects.isNotEmpty && !isCollapsed) {
      rect = _calculateBoundaryRectFromChildren(
          bounds, childRects, effectivePadding);
    } else {
      rect = bounds;
    }

    // Apply nesting level adjustments to style
    final adjustedStyle = _adjustStyleForNestingLevel(
      style,
      nestingLevel,
      element.type,
      parentType,
      siblingIndex,
    );

    // Determine what type of boundary we're rendering
    final boundaryType = _getBoundaryType(element);
    final shape = _getShapeForBoundaryType(element, adjustedStyle.shape);

    // Adjust opacity for nested boundaries
    // Each nesting level gets a bit more transparent to create visual hierarchy
    double adjustedOpacity = adjustedStyle.opacity / 100.0;
    if (nestingLevel > 0) {
      adjustedOpacity *=
          math.pow(nestingOpacityFactor, nestingLevel).toDouble();
    }

    // Special visual treatment for collapsed boundaries
    if (isCollapsed) {
      // Use a different visual style to indicate collapsed state
      // For example, a more subdued background, dashed border, etc.

      // Prepare a more subdued background for collapsed boundaries
      final collapsedBackgroundPaint = Paint()..style = PaintingStyle.fill;

      // Use a lighter/desaturated version of the background
      if (adjustedStyle.background != null) {
        final bgColor = parseColor(adjustedStyle.background);
        if (bgColor != null) {
          final hsl = HSLColor.fromColor(bgColor);
          final collapsedColor = hsl
              .withSaturation(hsl.saturation * 0.7)
              .withLightness((hsl.lightness + 0.1).clamp(0.0, 1.0))
              .toColor();
          collapsedBackgroundPaint.color =
              collapsedColor.withValues(alpha: adjustedOpacity);
        } else {
          collapsedBackgroundPaint.color =
              nestingLevelColors[nestingLevel % maxDistinctNestingLevels]
                  .withValues(alpha: adjustedOpacity * 0.7);
        }
      } else {
        collapsedBackgroundPaint.color =
            nestingLevelColors[nestingLevel % maxDistinctNestingLevels]
                .withValues(alpha: adjustedOpacity * 0.7);
      }

      // Use dashed border for collapsed boundaries if not already dashed/dotted
      Paint collapsedBorderPaint = Paint()
        ..color = (parseColor(adjustedStyle.stroke) != null)
            ? parseColor(adjustedStyle.stroke)!
                .withValues(alpha: adjustedOpacity)
            : nestingLevelColors[nestingLevel % maxDistinctNestingLevels]
                .withValues(alpha: adjustedOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth =
            adjustedStyle.strokeWidth?.toDouble() ?? defaultStrokeWidth;

      // Draw the collapsed boundary
      if (shape == Shape.roundedBox) {
        final rrect = RRect.fromRectAndRadius(
          rect,
          const Radius.circular(defaultBorderRadius),
        );

        // Draw background
        canvas.drawRRect(rrect, collapsedBackgroundPaint);

        // Draw dashed border for collapsed state
        _drawDashedRoundedRect(canvas, rect, defaultBorderRadius,
            collapsedBorderPaint, [4.0, 4.0]);
      } else {
        // Draw other shapes with dashed borders
        switch (shape) {
          case Shape.box:
            canvas.drawRect(rect, collapsedBackgroundPaint);
            _drawDashedRect(canvas, rect, collapsedBorderPaint, [4.0, 4.0]);
            break;
          case Shape.folder:
            _drawFolderShape(canvas, rect, collapsedBackgroundPaint,
                collapsedBorderPaint, styles.Border.dashed);
            break;
          case Shape.hexagon:
            _drawHexagonShape(canvas, rect, collapsedBackgroundPaint,
                collapsedBorderPaint, styles.Border.dashed);
            break;
          default:
            canvas.drawRect(rect, collapsedBackgroundPaint);
            _drawDashedRect(canvas, rect, collapsedBorderPaint, [4.0, 4.0]);
        }
      }
    } else {
      // Normal expanded boundary rendering

      // Prepare background paint with gradient if appropriate
      final backgroundPaint = _createBackgroundPaint(
        adjustedStyle,
        rect,
        hovered,
        nestingLevel,
      );

      // Prepare border paint
      final borderPaint = Paint()
        ..color = (parseColor(adjustedStyle.stroke) != null)
            ? parseColor(adjustedStyle.stroke)!
                .withValues(alpha: adjustedOpacity)
            : nestingLevelColors[nestingLevel % maxDistinctNestingLevels]
                .withValues(alpha: adjustedOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth =
            adjustedStyle.strokeWidth?.toDouble() ?? defaultStrokeWidth;

      // Draw the boundary shape based on determined shape
      _drawBoundaryShape(canvas, rect, shape, backgroundPaint, borderPaint,
          adjustedStyle.border);
    }

    // Draw selection or hover effects (always shown, even for collapsed boundaries)
    if (selected || hovered) {
      _drawSelectionEffect(canvas, rect, shape, selected, hovered);
    }

    // Draw collapse/expand indicator if enabled
    if (enableCollapsible) {
      _drawCollapseExpandIndicator(canvas, rect, isCollapsed);
    }

    // Render the boundary label with proper styling
    _renderBoundaryLabel(canvas, element, rect, adjustedStyle, nestingLevel);

    // Add a visual indicator of nesting level for debugging if desired
    // _drawNestingLevelIndicator(canvas, rect, nestingLevel);
  }

  /// Helper method to display nesting level visually (for debugging)
  void _drawNestingLevelIndicator(Canvas canvas, Rect rect, int nestingLevel) {
    // Skip for level 0
    if (nestingLevel == 0) return;

    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 10.0,
      fontWeight: FontWeight.bold,
    );

    final textSpan = TextSpan(
      text: 'L$nestingLevel',
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Draw a small badge in the top-right corner
    final badgeRect = Rect.fromLTWH(
      rect.right - textPainter.width - 10,
      rect.top + 5,
      textPainter.width + 6,
      textPainter.height + 4,
    );

    // Draw badge background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        badgeRect,
        const Radius.circular(3.0),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.6),
    );

    // Draw text
    textPainter.paint(
      canvas,
      Offset(badgeRect.left + 3, badgeRect.top + 2),
    );
  }

  /// Determines the boundary type based on the element
  String _getBoundaryType(Element element) {
    if (element is SoftwareSystem) {
      return 'SoftwareSystem';
    } else if (element is Container) {
      return 'Container';
    } else if (element.type == 'Enterprise') {
      return 'Enterprise';
    } else if (element.type == 'Group') {
      return 'Group';
    }
    return 'Generic';
  }

  /// Gets the appropriate shape for the given boundary type
  Shape _getShapeForBoundaryType(Element element, Shape defaultShape) {
    // Enterprise boundaries are typically shown as rounded rectangles
    if (element.type == 'Enterprise') {
      return Shape.roundedBox;
    }

    // Software systems often use the folder shape to indicate they contain elements
    if (element is SoftwareSystem) {
      return Shape.folder;
    }

    // Use the specified shape or default to roundedBox for most boundaries
    return defaultShape;
  }

  /// Creates a background paint with appropriate styling based on nesting level
  Paint _createBackgroundPaint(
      ElementStyle style, Rect rect, bool hovered, int nestingLevel) {
    // Use default colors based on nesting level if no specific color is provided
    final baseColor = parseColor(style.background) ??
        nestingLevelColors[nestingLevel % maxDistinctNestingLevels];

    // Calculate opacity based on nesting level
    final baseOpacity = style.opacity /
        100 *
        defaultOpacity *
        math.pow(nestingOpacityFactor, nestingLevel).toDouble();

    // Create gradient background for more visual distinction
    final Paint backgroundPaint = Paint();

    // Use gradient fill for better visual hierarchy
    if (style.shape != Shape.box) {
      // For rounded shapes, use a radial gradient
      backgroundPaint.shader = RadialGradient(
        center: Alignment.topLeft,
        radius: 1.0,
        colors: [
          baseColor.withValues(alpha: baseOpacity * 1.2),
          baseColor.withValues(alpha: baseOpacity * 0.8),
        ],
        stops: const [0.0, 1.0],
      ).createShader(rect);
    } else {
      // For rectangular shapes, use a linear gradient
      backgroundPaint.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          baseColor.withValues(alpha: baseOpacity * 1.2),
          baseColor.withValues(alpha: baseOpacity * 0.8),
        ],
        stops: const [0.0, 1.0],
      ).createShader(rect);
    }

    backgroundPaint.style = PaintingStyle.fill;

    // Enhance hover effect
    if (hovered) {
      // For hover, we'll use a brighter, more distinct gradient
      final brighterColor = _brightenColor(baseColor, 0.2);

      if (style.shape != Shape.box) {
        backgroundPaint.shader = RadialGradient(
          center: Alignment.topLeft,
          radius: 1.0,
          colors: [
            brighterColor.withValues(alpha: baseOpacity * 1.5),
            baseColor.withValues(alpha: baseOpacity * 1.2),
          ],
          stops: const [0.0, 1.0],
        ).createShader(rect);
      } else {
        backgroundPaint.shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            brighterColor.withValues(alpha: baseOpacity * 1.5),
            baseColor.withValues(alpha: baseOpacity * 1.2),
          ],
          stops: const [0.0, 1.0],
        ).createShader(rect);
      }
    }

    return backgroundPaint;
  }

  /// Draws the boundary shape with appropriate styling
  void _drawBoundaryShape(
    Canvas canvas,
    Rect rect,
    Shape shape,
    Paint backgroundPaint,
    Paint borderPaint,
    styles.Border borderStyle,
  ) {
    switch (shape) {
      case Shape.roundedBox:
        final rrect = RRect.fromRectAndRadius(
          rect,
          const Radius.circular(defaultBorderRadius),
        );

        // Draw background
        canvas.drawRRect(rrect, backgroundPaint);

        // Draw border with appropriate style
        if (borderStyle == styles.Border.dashed) {
          _drawDashedRoundedRect(
              canvas, rect, defaultBorderRadius, borderPaint, [6.0, 3.0]);
        } else if (borderStyle == styles.Border.dotted) {
          _drawDashedRoundedRect(
              canvas, rect, defaultBorderRadius, borderPaint, [2.0, 2.0]);
        } else {
          canvas.drawRRect(rrect, borderPaint);
        }
        break;

      case Shape.folder:
        _drawFolderShape(
            canvas, rect, backgroundPaint, borderPaint, borderStyle);
        break;

      case Shape.hexagon:
        _drawHexagonShape(
            canvas, rect, backgroundPaint, borderPaint, borderStyle);
        break;

      default:
        // Default rectangular shape
        canvas.drawRect(rect, backgroundPaint);

        // Draw border with appropriate style
        if (borderStyle == styles.Border.dashed) {
          _drawDashedRect(canvas, rect, borderPaint, [6.0, 3.0]);
        } else if (borderStyle == styles.Border.dotted) {
          _drawDashedRect(canvas, rect, borderPaint, [2.0, 2.0]);
        } else {
          canvas.drawRect(rect, borderPaint);
        }
    }
  }

  /// Draws a folder-shaped boundary
  void _drawFolderShape(
    Canvas canvas,
    Rect rect,
    Paint backgroundPaint,
    Paint borderPaint,
    styles.Border borderStyle,
  ) {
    // Constants for folder tab
    const double tabHeight = 20.0;
    const double tabWidth = 40.0;

    // Create path for the folder shape
    final path = Path();
    path.moveTo(rect.left, rect.top + tabHeight);
    path.lineTo(rect.left, rect.bottom);
    path.lineTo(rect.right, rect.bottom);
    path.lineTo(rect.right, rect.top + tabHeight);
    path.lineTo(rect.left + tabWidth + 10, rect.top + tabHeight);
    path.lineTo(rect.left + tabWidth, rect.top);
    path.lineTo(rect.left, rect.top);
    path.close();

    // Draw background
    canvas.drawPath(path, backgroundPaint);

    // Draw border with appropriate style
    if (borderStyle == styles.Border.dashed ||
        borderStyle == styles.Border.dotted) {
      final dashPattern =
          borderStyle == styles.Border.dashed ? [6.0, 3.0] : [2.0, 2.0];
      _drawDashedPath(canvas, path, borderPaint, dashPattern);
    } else {
      canvas.drawPath(path, borderPaint);
    }
  }

  /// Draws a hexagon-shaped boundary
  void _drawHexagonShape(
    Canvas canvas,
    Rect rect,
    Paint backgroundPaint,
    Paint borderPaint,
    styles.Border borderStyle,
  ) {
    final centerX = rect.center.dx;
    final centerY = rect.center.dy;
    final width = rect.width;
    final height = rect.height;

    // Create path for the hexagon
    final path = Path();
    path.moveTo(centerX - width / 2, centerY);
    path.lineTo(centerX - width / 4, centerY - height / 2);
    path.lineTo(centerX + width / 4, centerY - height / 2);
    path.lineTo(centerX + width / 2, centerY);
    path.lineTo(centerX + width / 4, centerY + height / 2);
    path.lineTo(centerX - width / 4, centerY + height / 2);
    path.close();

    // Draw background
    canvas.drawPath(path, backgroundPaint);

    // Draw border with appropriate style
    if (borderStyle == styles.Border.dashed ||
        borderStyle == styles.Border.dotted) {
      final dashPattern =
          borderStyle == styles.Border.dashed ? [6.0, 3.0] : [2.0, 2.0];
      _drawDashedPath(canvas, path, borderPaint, dashPattern);
    } else {
      canvas.drawPath(path, borderPaint);
    }
  }

  /// Draw a dashed or dotted path
  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint,
    List<double> pattern,
  ) {
    final pathMetrics = path.computeMetrics();

    for (final pathMetric in pathMetrics) {
      final length = pathMetric.length;
      double distance = 0.0;

      bool drawDash = true;
      final Path dashPath = Path();

      while (distance < length) {
        final double dashLength = drawDash ? pattern[0] : pattern[1];
        final double nextDistance = distance + dashLength;

        if (drawDash) {
          final extractPath = pathMetric.extractPath(
              distance, nextDistance > length ? length : nextDistance);
          dashPath.addPath(extractPath, Offset.zero);
        }

        distance = nextDistance;
        drawDash = !drawDash;
      }

      canvas.drawPath(dashPath, paint);
    }
  }

  /// Draw selection or hover effects
  void _drawSelectionEffect(
    Canvas canvas,
    Rect rect,
    Shape shape,
    bool selected,
    bool hovered,
  ) {
    if (selected) {
      // Selection effect - stronger, blue glow
      final selectionPaint = Paint()
        ..color = Colors.blue.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      if (shape == Shape.roundedBox) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            rect.inflate(2.0),
            const Radius.circular(defaultBorderRadius + 2.0),
          ),
          selectionPaint,
        );
      } else if (shape == Shape.folder) {
        // For folder shape, we'll just do a rectangle selection indicator for simplicity
        canvas.drawRect(rect.inflate(2.0), selectionPaint);
      } else if (shape == Shape.hexagon) {
        // For hexagon, we'll use a circular selection indicator
        canvas.drawCircle(rect.center,
            math.max(rect.width, rect.height) / 2 + 2.0, selectionPaint);
      } else {
        canvas.drawRect(rect.inflate(2.0), selectionPaint);
      }

      // Add an additional subtle glow effect for selection
      final glowPaint = Paint()
        ..color = Colors.blue.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

      canvas.drawRect(rect.inflate(4.0), glowPaint);
    } else if (hovered) {
      // Hover effect - subtle highlight
      final hoverPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

      if (shape == Shape.roundedBox) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            rect.inflate(1.0),
            const Radius.circular(defaultBorderRadius + 1.0),
          ),
          hoverPaint,
        );
      } else {
        canvas.drawRect(rect.inflate(1.0), hoverPaint);
      }
    }
  }

  /// Draw collapse/expand indicator for collapsible boundaries
  void _drawCollapseExpandIndicator(
    Canvas canvas,
    Rect rect,
    bool isCollapsed,
  ) {
    const double indicatorSize = 16.0;
    final indicatorRect = Rect.fromLTWH(
      rect.right - indicatorSize - 4.0,
      rect.top + 4.0,
      indicatorSize,
      indicatorSize,
    );

    // Draw indicator background
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(indicatorRect.center, indicatorSize / 2, bgPaint);

    // Draw indicator border
    final borderPaint = Paint()
      ..color = Colors.grey.shade700.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(indicatorRect.center, indicatorSize / 2, borderPaint);

    // Draw plus or minus symbol
    final symbolPaint = Paint()
      ..color = Colors.grey.shade900.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Horizontal line (for both plus and minus)
    canvas.drawLine(
      Offset(indicatorRect.left + 4.0, indicatorRect.center.dy),
      Offset(indicatorRect.right - 4.0, indicatorRect.center.dy),
      symbolPaint,
    );

    // Vertical line (only for plus/collapsed state)
    if (isCollapsed) {
      canvas.drawLine(
        Offset(indicatorRect.center.dx, indicatorRect.top + 4.0),
        Offset(indicatorRect.center.dx, indicatorRect.bottom - 4.0),
        symbolPaint,
      );
    }
  }

  /// Adjusts the style based on nesting level and boundary type
  ElementStyle _adjustStyleForNestingLevel(
    ElementStyle baseStyle,
    int nestingLevel,
    String elementType,
    String? parentType,
    int siblingIndex,
  ) {
    // For the first level, we use the original style
    if (nestingLevel == 0) {
      return baseStyle;
    }

    // Get colors based on nesting level
    final Color nestingColor =
        nestingLevelColors[nestingLevel % maxDistinctNestingLevels];

    // For siblings at the same level with the same parent, use color variations
    Color backgroundColor = nestingColor;
    if (nestingLevel > 0 && siblingIndex > 0) {
      backgroundColor =
          siblingVariationColors[siblingIndex % siblingVariationColors.length];
    }

    // Calculate opacity reduction based on nesting level
    final newOpacity = math.max(
      10, // Minimum opacity to ensure visibility
      (baseStyle.opacity * math.pow(nestingOpacityFactor, nestingLevel))
          .toInt(),
    );

    // Adjust stroke width to be thinner for deeper nesting
    final int strokeWidth = baseStyle.strokeWidth != null
        ? math.max(1, (baseStyle.strokeWidth! - nestingLevel).clamp(1, 5))
        : math.max(1, (defaultStrokeWidth.toInt() - nestingLevel).clamp(1, 5));

    // Create adjusted style
    return ElementStyle(
      tag: baseStyle.tag,
      shape: baseStyle.shape,
      icon: baseStyle.icon,
      width: baseStyle.width,
      height: baseStyle.height,
      background: baseStyle.background,
      color: baseStyle.color,
      stroke: baseStyle.stroke,
      strokeWidth: strokeWidth,
      border: baseStyle.border,
      opacity: newOpacity,
      fontSize: baseStyle.fontSize != null
          ? math.max(10, baseStyle.fontSize! - nestingLevel)
          : math.max(10, defaultLabelFontSize.toInt() - nestingLevel),
      metadata: baseStyle.metadata,
      description: baseStyle.description,
    );
  }

  /// Brightens or darkens a color by the given amount
  Color _brightenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  /// Converts an ElementStyle to a BoundaryStyle
  BoundaryStyle _elementToBoundaryStyle(ElementStyle style) {
    return BoundaryStyle(
      tag: style.tag,
      shape: style.shape,
      background: style.background,
      color: style.color,
      stroke: style.stroke,
      strokeWidth: style.strokeWidth,
      border: style.border,
      opacity: style.opacity,
      fontSize: style.fontSize,
    );
  }

  /// Calculates a boundary rectangle that encompasses all child rectangles
  ///
  /// [elementRect] The base rectangle of the boundary element
  /// [childRects] The rectangles of the child elements
  /// [padding] The padding to add around the children
  Rect _calculateBoundaryRectFromChildren(
      Rect elementRect, List<Rect> childRects, double padding) {
    if (childRects.isEmpty) {
      return elementRect;
    }

    // Find the bounds that contain all children
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final rect in childRects) {
      minX = math.min(minX, rect.left);
      minY = math.min(minY, rect.top);
      maxX = math.max(maxX, rect.right);
      maxY = math.max(maxY, rect.bottom);
    }

    // Add padding
    minX -= padding;
    minY -= padding;
    maxX += padding;
    maxY += padding;

    // Ensure the boundary encompasses both the element's own rect and all children
    minX = math.min(minX, elementRect.left);
    minY = math.min(minY, elementRect.top);
    maxX = math.max(maxX, elementRect.right);
    maxY = math.max(maxY, elementRect.bottom);

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Draws a dashed rounded rectangle
  void _drawDashedRoundedRect(
    Canvas canvas,
    Rect rect,
    double radius,
    Paint paint,
    List<double> pattern,
  ) {
    final Path path = Path();
    final double dashWidth = pattern[0];
    final double dashSpace = pattern[1];

    // Create a path for a rounded rectangle
    path.addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

    // Calculate the total length of the path
    final pathMetrics = path.computeMetrics().first;
    final length = pathMetrics.length;

    // Draw dashed segments along the path
    double distance = 0.0;
    final Path dashedPath = Path();

    bool drawDash = true;
    while (distance < length) {
      final double dashLength = drawDash ? dashWidth : dashSpace;
      final extractPath = pathMetrics.extractPath(
        distance,
        distance + dashLength > length ? length : distance + dashLength,
      );

      if (drawDash) {
        dashedPath.addPath(extractPath, Offset.zero);
      }

      distance += dashLength;
      drawDash = !drawDash;
    }

    canvas.drawPath(dashedPath, paint);
  }

  /// Draws a dashed rectangle with the specified dash pattern
  void _drawDashedRect(
    Canvas canvas,
    Rect rect,
    Paint paint,
    List<double> pattern,
  ) {
    final Path path = Path();
    final double dashWidth = pattern[0];
    final double dashSpace = pattern[1];

    // Top edge
    double distance = 0.0;
    final double topLength = rect.width;

    while (distance < topLength) {
      final double nextDash = distance + dashWidth;
      path.moveTo(rect.left + distance, rect.top);
      path.lineTo(
          rect.left + (nextDash > topLength ? topLength : nextDash), rect.top);
      distance = nextDash + dashSpace;
    }

    // Right edge
    distance = 0.0;
    final double rightLength = rect.height;

    while (distance < rightLength) {
      final double nextDash = distance + dashWidth;
      path.moveTo(rect.right, rect.top + distance);
      path.lineTo(rect.right,
          rect.top + (nextDash > rightLength ? rightLength : nextDash));
      distance = nextDash + dashSpace;
    }

    // Bottom edge
    distance = 0.0;
    final double bottomLength = rect.width;

    while (distance < bottomLength) {
      final double nextDash = distance + dashWidth;
      path.moveTo(rect.right - distance, rect.bottom);
      path.lineTo(
          rect.right - (nextDash > bottomLength ? bottomLength : nextDash),
          rect.bottom);
      distance = nextDash + dashSpace;
    }

    // Left edge
    distance = 0.0;
    final double leftLength = rect.height;

    while (distance < leftLength) {
      final double nextDash = distance + dashWidth;
      path.moveTo(rect.left, rect.bottom - distance);
      path.lineTo(rect.left,
          rect.bottom - (nextDash > leftLength ? leftLength : nextDash));
      distance = nextDash + dashSpace;
    }

    canvas.drawPath(path, paint);
  }

  /// Renders the label for the boundary with appropriate styling
  void _renderBoundaryLabel(
    Canvas canvas,
    Element element,
    Rect rect,
    ElementStyle style,
    int nestingLevel,
  ) {
    // Create a more descriptive label that includes boundary type
    String labelText = element.name;
    String? descriptionText;

    // Add type information to the label if available
    if (element is SoftwareSystem) {
      labelText = '${element.name} [System]';
      descriptionText = element.description;
    } else if (element is Container) {
      labelText = '${element.name} [Container]';
      descriptionText = element.description;
    } else if (element.type == 'Enterprise') {
      labelText = '${element.name} [Enterprise]';
    } else if (element.type == 'Group') {
      labelText = '${element.name} [Group]';
    }

    // Define the label text style with adjusted size based on nesting level
    final fontSize = style.fontSize?.toDouble() ??
        math.max(10.0, defaultLabelFontSize - nestingLevel);

    final textStyle = TextStyle(
      color: parseColor(style.color) ?? Colors.black,
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
    );

    // Create a smaller, lighter style for the description if present
    final descriptionStyle = TextStyle(
      color:
          (parseColor(style.color)?.withValues(alpha: 0.8)) ?? Colors.black54,
      fontSize: fontSize * 0.8,
      fontStyle: FontStyle.italic,
    );

    // Create label text painter
    final textPainter = createTextPainter(
      text: labelText,
      style: textStyle,
    );

    // Create description text painter if needed
    TextPainter? descriptionPainter;
    if (descriptionText != null &&
        descriptionText.isNotEmpty &&
        style.description == true) {
      // Limit description length to avoid very large labels
      if (descriptionText.length > 60) {
        descriptionText = '${descriptionText.substring(0, 57)}...';
      }

      descriptionPainter = createTextPainter(
        text: descriptionText,
        style: descriptionStyle,
      );
    }

    // Calculate label height including description if present
    final totalLabelHeight = textPainter.height +
        (descriptionPainter != null ? descriptionPainter.height + 2.0 : 0.0);

    // Handle label position based on style.labelPosition or default to top
    // Import the LabelPosition enum from styles.dart
    final labelPos = style.labelPosition ?? LabelPosition.top;
    Rect labelBackgroundRect;

    switch (labelPos) {
      case LabelPosition.top:
        // Position label at the top of the boundary
        labelBackgroundRect = Rect.fromLTWH(
          rect.left + defaultPadding,
          rect.top - totalLabelHeight / 2,
          math.max(
                textPainter.width,
                descriptionPainter?.width ?? 0.0,
              ) +
              labelBackgroundPadding.horizontal,
          totalLabelHeight + labelBackgroundPadding.vertical,
        );
        break;

      case LabelPosition.center:
        // Position label in the center of the boundary
        labelBackgroundRect = Rect.fromLTWH(
          rect.center.dx -
              (math.max(textPainter.width, descriptionPainter?.width ?? 0.0) +
                      labelBackgroundPadding.horizontal) /
                  2,
          rect.center.dy -
              (totalLabelHeight + labelBackgroundPadding.vertical) / 2,
          math.max(
                textPainter.width,
                descriptionPainter?.width ?? 0.0,
              ) +
              labelBackgroundPadding.horizontal,
          totalLabelHeight + labelBackgroundPadding.vertical,
        );
        break;

      case LabelPosition.bottom:
        // Position label at the bottom of the boundary
        labelBackgroundRect = Rect.fromLTWH(
          rect.left + defaultPadding,
          rect.bottom -
              totalLabelHeight -
              labelBackgroundPadding.vertical +
              totalLabelHeight / 2,
          math.max(
                textPainter.width,
                descriptionPainter?.width ?? 0.0,
              ) +
              labelBackgroundPadding.horizontal,
          totalLabelHeight + labelBackgroundPadding.vertical,
        );
        break;

      default:
        // Default to top position
        labelBackgroundRect = Rect.fromLTWH(
          rect.left + defaultPadding,
          rect.top - totalLabelHeight / 2,
          math.max(
                textPainter.width,
                descriptionPainter?.width ?? 0.0,
              ) +
              labelBackgroundPadding.horizontal,
          totalLabelHeight + labelBackgroundPadding.vertical,
        );
    }

    // Choose label background color based on boundary style
    Color labelBgColor;
    if (style.background != null && parseColor(style.background) != null) {
      final hsl = HSLColor.fromColor(parseColor(style.background)!);
      labelBgColor =
          hsl.withLightness((hsl.lightness + 0.3).clamp(0.0, 1.0)).toColor();
    } else {
      labelBgColor = Colors.white;
    }

    // Draw label background with gradient for better visibility
    final labelBackgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          labelBgColor.withValues(alpha: 0.95),
          labelBgColor.withValues(alpha: 0.85),
        ],
      ).createShader(labelBackgroundRect)
      ..style = PaintingStyle.fill;

    // Draw rounded rectangle for label background with subtle shadow
    canvas.save();
    canvas.translate(2, 2); // Shadow offset
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        labelBackgroundRect,
        const Radius.circular(4.0),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.2),
    );
    canvas.restore();

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        labelBackgroundRect,
        const Radius.circular(4.0),
      ),
      labelBackgroundPaint,
    );

    // Draw the label border if needed
    final labelBorderPaint = Paint()
      ..color = parseColor(style.stroke) ?? Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        labelBackgroundRect,
        const Radius.circular(4.0),
      ),
      labelBorderPaint,
    );

    // Position and paint the main text
    textPainter.paint(
      canvas,
      Offset(
        labelBackgroundRect.left + labelBackgroundPadding.left,
        labelBackgroundRect.top + labelBackgroundPadding.top / 2,
      ),
    );

    // Position and paint the description text if present
    if (descriptionPainter != null) {
      descriptionPainter.paint(
        canvas,
        Offset(
          labelBackgroundRect.left + labelBackgroundPadding.left,
          labelBackgroundRect.top +
              textPainter.height +
              2.0 +
              labelBackgroundPadding.top / 2,
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
    // If the view explicitly defines the boundary size, use it
    if (elementView.width != null && elementView.height != null) {
      return Rect.fromLTWH(
        elementView.x?.toDouble() ?? 0,
        elementView.y?.toDouble() ?? 0,
        elementView.width!.toDouble(),
        elementView.height!.toDouble(),
      );
    }

    // For software system or container boundaries, we'd typically
    // calculate this based on the contained elements plus padding
    double minWidth = style.width?.toDouble() ?? 200;
    double minHeight = style.height?.toDouble() ?? 150;

    // Use fixed dimensions if they are provided in the style
    return Rect.fromLTWH(
      elementView.x?.toDouble() ?? 0,
      elementView.y?.toDouble() ?? 0,
      minWidth,
      minHeight,
    );
  }

  /// Calculate boundary dimensions based on contained elements with improved padding logic
  ///
  /// [containedElements] List of element views contained within this boundary
  /// [padding] Additional padding to add around the boundary
  /// [boundaryStyle] Optional boundary style that may specify padding
  /// [includeNestedBoundaries] Whether to consider nested boundaries in the calculation
  Rect calculateBoundaryFromContainedElements(
    List<ElementView> containedElements,
    double padding, {
    BoundaryStyle? boundaryStyle,
    bool includeNestedBoundaries = true,
  }) {
    if (containedElements.isEmpty) {
      // Default size if no elements
      return const Rect.fromLTWH(0, 0, 200, 150);
    }

    // Use the style-specified padding if available
    final effectivePadding = boundaryStyle?.padding.toDouble() ?? padding;

    // Find the min/max coordinates of contained elements
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final element in containedElements) {
      final x = element.x?.toDouble() ?? 0;
      final y = element.y?.toDouble() ?? 0;
      final width = element.width?.toDouble() ?? 100;
      final height = element.height?.toDouble() ?? 80;

      // For nested boundaries, we might want to give them extra consideration
      // Check if this is a boundary by its properties
      // Since this is an ElementView, we need to use a different approach
      bool isNestedBoundary = false;

      // ElementView doesn't have type information, so we need to rely on another approach
      // For this implementation, we'll consider boundary-type elements to have specific dimensions
      // A better solution would be to add a 'type' property to ElementView or pass the original element
      if (element.width != null &&
          element.width! > 150 &&
          element.height != null &&
          element.height! > 100) {
        isNestedBoundary = true;
      }

      // Skip nested boundaries if requested
      if (isNestedBoundary && !includeNestedBoundaries) {
        continue;
      }

      minX = math.min(minX, x);
      minY = math.min(minY, y);
      maxX = math.max(maxX, x + width);
      maxY = math.max(maxY, y + height);
    }

    // Add padding - use extra padding for left side to accommodate labels
    return Rect.fromLTRB(
      minX - effectivePadding * 1.5, // Extra padding for label
      minY - effectivePadding * 1.2, // Extra padding for label
      maxX + effectivePadding,
      maxY + effectivePadding,
    );
  }

  /// Calculate boundary dimensions for nested hierarchies
  ///
  /// This more advanced calculation handles:
  /// - Nested boundary hierarchies (boundaries containing boundaries)
  /// - Proper padding and minimum sizing
  /// - Parent-child relationships
  ///
  /// [containedElements] Map of element ID to its ElementView
  /// [elementHierarchy] Map of parent ID to list of child element IDs
  /// [rootElementId] ID of the root boundary element
  /// [styles] Styles to apply to elements
  Rect calculateNestedBoundaryHierarchy(
    Map<String, ElementView> containedElements,
    Map<String, List<String>> elementHierarchy,
    String rootElementId,
    Styles styles,
    List<Element> elements,
  ) {
    // Base case: no children
    if (!elementHierarchy.containsKey(rootElementId) ||
        elementHierarchy[rootElementId]!.isEmpty) {
      // Return the base element's rect
      final rootView = containedElements[rootElementId];
      if (rootView == null) {
        return const Rect.fromLTWH(0, 0, 200, 150); // Default if missing
      }

      return Rect.fromLTWH(
        rootView.x?.toDouble() ?? 0,
        rootView.y?.toDouble() ?? 0,
        rootView.width?.toDouble() ?? 200,
        rootView.height?.toDouble() ?? 150,
      );
    }

    // Get all immediate children
    final childIds = elementHierarchy[rootElementId] ?? [];
    final List<Rect> childRects = [];

    // Recursively calculate rects for each child
    for (final childId in childIds) {
      // If this child is a boundary, recursively calculate its rect
      if (elementHierarchy.containsKey(childId)) {
        childRects.add(calculateNestedBoundaryHierarchy(
          containedElements,
          elementHierarchy,
          childId,
          styles,
          elements,
        ));
      } else {
        // Otherwise, just add its own rect
        final childView = containedElements[childId];
        if (childView != null) {
          childRects.add(Rect.fromLTWH(
            childView.x?.toDouble() ?? 0,
            childView.y?.toDouble() ?? 0,
            childView.width?.toDouble() ?? 100,
            childView.height?.toDouble() ?? 80,
          ));
        }
      }
    }

    // Find the element that corresponds to the root ID to get its tags
    final rootElement = elements.firstWhereOrNull((e) => e.id == rootElementId);
    List<String> tags = rootElement?.tags ?? [];

    // Get style for this boundary to determine padding
    ElementStyle style = styles.getElementStyle(tags);

    // Convert to boundary style to access padding
    BoundaryStyle boundaryStyle = _elementToBoundaryStyle(style);

    // Calculate the boundary's rect based on all children's rects
    final rootView = containedElements[rootElementId];
    final rootRect = rootView != null
        ? Rect.fromLTWH(
            rootView.x?.toDouble() ?? 0,
            rootView.y?.toDouble() ?? 0,
            rootView.width?.toDouble() ?? 200,
            rootView.height?.toDouble() ?? 150,
          )
        : const Rect.fromLTWH(0, 0, 200, 150);

    return _calculateBoundaryRectFromChildren(
      rootRect,
      childRects,
      boundaryStyle.padding.toDouble() ?? defaultPadding,
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

    // Check if point is within the boundary rectangle
    if (rect.contains(point)) {
      return true;
    }

    // Check if the point is on the collapse/expand indicator if enabled
    if (enableCollapsible) {
      const double indicatorSize = 16.0;
      final indicatorRect = Rect.fromLTWH(
        rect.right - indicatorSize - 4.0,
        rect.top + 4.0,
        indicatorSize,
        indicatorSize,
      );

      if (indicatorRect.contains(point)) {
        return true;
      }
    }

    // Check if the point is on the label
    // Create a text painter to get the size
    final textStyle = TextStyle(
      color: parseColor(style.color) ?? Colors.black,
      fontSize: style.fontSize?.toDouble() ?? defaultLabelFontSize,
      fontWeight: FontWeight.bold,
    );

    final textPainter = createTextPainter(
      text: element.name,
      style: textStyle,
    );

    final labelBackgroundRect = Rect.fromLTWH(
      rect.left + defaultPadding,
      rect.top - textPainter.height / 2,
      textPainter.width + labelBackgroundPadding.horizontal,
      textPainter.height + labelBackgroundPadding.vertical,
    );

    return labelBackgroundRect.contains(point);
  }

  /// Checks whether a point hits the collapse/expand control for a boundary
  /// Returns true if the point is on the control, false otherwise
  bool hitTestCollapseControl({
    required Offset point,
    required Rect boundaryRect,
  }) {
    if (!enableCollapsible) {
      return false;
    }

    const double indicatorSize = 16.0;
    final indicatorRect = Rect.fromLTWH(
      boundaryRect.right - indicatorSize - 4.0,
      boundaryRect.top + 4.0,
      indicatorSize,
      indicatorSize,
    );

    return indicatorRect.contains(point);
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
    bool hovered = false,
    bool includeDescription = true,
  }) {
    // Boundaries themselves don't render relationships
    // This is handled by the relationship renderer
  }

  @override
  Path calculateRelationshipPath({
    required Relationship relationship,
    required RelationshipView relationshipView,
    required RelationshipStyle style,
    required Rect sourceRect,
    required Rect targetRect,
  }) {
    // Boundaries don't define relationship paths
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
    // Boundaries don't have relationships to hit test
    return false;
  }
}
