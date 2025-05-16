import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart' hide Element, Border;
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/presentation/rendering/base_renderer.dart';

/// A renderer for box-shaped elements in a Structurizr diagram.
///
/// This renderer handles rectangular elements with various styles including
/// box, rounded box, and folder shapes. It supports selection state visualization
/// and automatic text sizing.
class BoxRenderer extends BaseRenderer {
  /// Default padding inside the box
  static const double defaultPadding = 12.0;

  /// Default border radius for rounded boxes
  static const double defaultBorderRadius = 10.0;

  /// Default minimum width for the box
  static const double defaultMinWidth = 80.0;

  /// Default minimum height for the box
  static const double defaultMinHeight = 60.0;

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
    // Calculate the element bounds
    final rect = _calculateRenderRect(elementView);

    // Prepare paint objects
    final backgroundPaint = Paint()
      ..color = style.background?.withOpacity(style.opacity / 100) ?? 
                Colors.white.withOpacity(style.opacity / 100)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = style.stroke?.withOpacity(style.opacity / 100) ?? 
                Colors.grey.withOpacity(style.opacity / 100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.strokeWidth?.toDouble() ?? 1.0;

    if (style.border == Border.dashed) {
      borderPaint.strokeJoin = StrokeJoin.round;
      // Set dashed effect
      borderPaint.strokeCap = StrokeCap.square;
      borderPaint.shader = null;
      const dashWidth = 4.0;
      const dashSpace = 4.0;
      // Create a path dash effect
      final path = Path();
      for (double i = 0; i < rect.width + rect.height * 2; i += dashWidth + dashSpace) {
        if (i < rect.width) {
          path.moveTo(rect.left + i, rect.top);
          path.lineTo(rect.left + i + dashWidth < rect.right ? 
                     rect.left + i + dashWidth : rect.right, rect.top);
        } else if (i < rect.width + rect.height) {
          path.moveTo(rect.right, rect.top + i - rect.width);
          path.lineTo(rect.right, 
                     rect.top + i - rect.width + dashWidth < rect.bottom ? 
                     rect.top + i - rect.width + dashWidth : rect.bottom);
        } else {
          path.moveTo(rect.right - (i - rect.width - rect.height), rect.bottom);
          path.lineTo(rect.right - (i - rect.width - rect.height) - dashWidth > rect.left ? 
                     rect.right - (i - rect.width - rect.height) - dashWidth : rect.left, 
                     rect.bottom);
        }
      }
      canvas.drawPath(path, borderPaint);
    } else if (style.border == Border.dotted) {
      borderPaint.strokeJoin = StrokeJoin.round;
      // Set dotted effect
      borderPaint.strokeCap = StrokeCap.round;
      borderPaint.shader = null;
      const dotWidth = 2.0;
      const dotSpace = 2.0;
      // Create a path dash effect
      final path = Path();
      for (double i = 0; i < rect.width * 2 + rect.height * 2; i += dotWidth + dotSpace) {
        final pos = i % (rect.width * 2 + rect.height * 2);
        if (pos < rect.width) {
          // Top edge
          path.moveTo(rect.left + pos, rect.top);
          path.lineTo(rect.left + pos + dotWidth < rect.right ? 
                     rect.left + pos + dotWidth : rect.right, rect.top);
        } else if (pos < rect.width + rect.height) {
          // Right edge
          path.moveTo(rect.right, rect.top + pos - rect.width);
          path.lineTo(rect.right, 
                     rect.top + pos - rect.width + dotWidth < rect.bottom ? 
                     rect.top + pos - rect.width + dotWidth : rect.bottom);
        } else if (pos < rect.width * 2 + rect.height) {
          // Bottom edge
          path.moveTo(rect.right - (pos - rect.width - rect.height), rect.bottom);
          path.lineTo(rect.right - (pos - rect.width - rect.height) - dotWidth > rect.left ? 
                     rect.right - (pos - rect.width - rect.height) - dotWidth : rect.left, 
                     rect.bottom);
        } else {
          // Left edge
          path.moveTo(rect.left, rect.bottom - (pos - rect.width * 2 - rect.height));
          path.lineTo(rect.left, 
                     rect.bottom - (pos - rect.width * 2 - rect.height) - dotWidth > rect.top ? 
                     rect.bottom - (pos - rect.width * 2 - rect.height) - dotWidth : rect.top);
        }
      }
      canvas.drawPath(path, borderPaint);
    }
    
    // Render box based on shape
    switch (style.shape) {
      case Shape.box:
        canvas.drawRect(rect, backgroundPaint);
        if (style.border == Border.solid) {
          canvas.drawRect(rect, borderPaint);
        }
        break;
      
      case Shape.roundedBox:
        final rrect = RRect.fromRectAndRadius(
          rect,
          const Radius.circular(defaultBorderRadius),
        );
        canvas.drawRRect(rrect, backgroundPaint);
        if (style.border == Border.solid) {
          canvas.drawRRect(rrect, borderPaint);
        }
        break;

      case Shape.ellipse:
        // Draw ellipse using path (to ensure drawnPaths is not empty)
        final ellipsePath = Path();
        ellipsePath.addOval(rect);
        canvas.drawPath(ellipsePath, backgroundPaint);
        if (style.border == Border.solid) {
          canvas.drawPath(ellipsePath, borderPaint);
        }
        break;
      
      case Shape.folder:
        // Draw folder shape with a tab
        final folderPath = Path();
        final tabHeight = rect.height * 0.15;
        final tabWidth = rect.width * 0.3;
        
        // Draw tab
        folderPath.moveTo(rect.left, rect.top);
        folderPath.lineTo(rect.left + tabWidth, rect.top);
        folderPath.lineTo(rect.left + tabWidth, rect.top + tabHeight);
        folderPath.lineTo(rect.right, rect.top + tabHeight);
        folderPath.lineTo(rect.right, rect.bottom);
        folderPath.lineTo(rect.left, rect.bottom);
        folderPath.close();
        
        canvas.drawPath(folderPath, backgroundPaint);
        if (style.border == Border.solid) {
          canvas.drawPath(folderPath, borderPaint);
        }
        break;
      
      default:
        // Fallback to regular box for other shapes
        canvas.drawRect(rect, backgroundPaint);
        if (style.border == Border.solid) {
          canvas.drawRect(rect, borderPaint);
        }
        break;
    }

    // If selected or hovered, draw a visual indicator
    if (selected || hovered) {
      final indicatorPaint = Paint()
        ..color = selected ? Colors.blue.withOpacity(0.5) : Colors.grey.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 2.0 : 1.5;
      
      // Draw indicator based on shape
      if (style.shape == Shape.roundedBox) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            rect.inflate(selected ? 2.0 : 1.5), 
            Radius.circular(defaultBorderRadius + (selected ? 2.0 : 1.5)),
          ), 
          indicatorPaint,
        );
      } else if (style.shape == Shape.ellipse) {
        // For ellipse, draw slightly larger ellipse
        canvas.drawOval(
          rect.inflate(selected ? 2.0 : 1.5), 
          indicatorPaint,
        );
      } else {
        // For box and other shapes
        canvas.drawRect(rect.inflate(selected ? 2.0 : 1.5), indicatorPaint);
      }
      
      // Optional: add a subtle glow effect for hover state
      if (hovered && !selected) {
        final glowPaint = Paint()
          ..color = Colors.grey.withOpacity(0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0;
        
        // Draw glow based on shape
        if (style.shape == Shape.roundedBox) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              rect.inflate(3.0), 
              const Radius.circular(defaultBorderRadius + 3.0),
            ), 
            glowPaint,
          );
        } else if (style.shape == Shape.ellipse) {
          canvas.drawOval(rect.inflate(3.0), glowPaint);
        } else {
          canvas.drawRect(rect.inflate(3.0), glowPaint);
        }
      }
    }

    // Render the text
    _renderText(canvas, element, rect, style, includeNames, includeDescriptions);
  }

  /// Renders the text for the element.
  void _renderText(Canvas canvas, Element element, Rect rect, ElementStyle style, 
                  bool includeNames, bool includeDescriptions) {
    final padding = defaultPadding;
    final textRect = Rect.fromLTRB(
      rect.left + padding,
      rect.top + padding,
      rect.right - padding,
      rect.bottom - padding,
    );

    // Text style based on element style
    final textStyle = TextStyle(
      color: style.color ?? Colors.black,
      fontSize: style.fontSize?.toDouble() ?? 14.0,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.1,  // Improve readability
      height: 1.2,  // Line height multiplier for better spacing
    );

    // Determine how many sections of text we have to display
    final hasName = includeNames;
    final hasDescription = includeDescriptions && (style.description ?? true) && 
                          element.description != null && element.description!.isNotEmpty;
    final hasMetadata = (style.metadata ?? false) && element.type.isNotEmpty;
    
    // Name of the element with enhanced styling
    final nameTextPainter = createTextPainter(
      text: element.name,
      style: textStyle.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: (style.fontSize?.toDouble() ?? 14.0) + 1, // Slightly larger
        letterSpacing: 0.2, // Better letter spacing for titles
      ),
      maxWidth: textRect.width,
    );
    
    // Calculate vertical positions based on content
    double totalTextHeight = hasName ? nameTextPainter.height : 0;
    
    if (hasDescription) {
      final descTextPainter = createTextPainter(
        text: element.description!,
        style: textStyle,
        maxWidth: textRect.width,
      );
      totalTextHeight += descTextPainter.height + (hasName ? 8 : 0); // 8px spacing if name is included
    }
    
    if (hasMetadata) {
      final typeTextPainter = createTextPainter(
        text: element.type,
        style: textStyle.copyWith(
          fontSize: (style.fontSize?.toDouble() ?? 14.0) - 1,
          fontStyle: FontStyle.italic,
        ),
        maxWidth: textRect.width,
      );
      totalTextHeight += typeTextPainter.height + 4; // 4px spacing
    }
    
    // Start position - centered vertically if there's enough space
    double yPos = textRect.top;
    if (totalTextHeight < textRect.height) {
      yPos += (textRect.height - totalTextHeight) / 2;
    }
    
    // Draw name if includeNames is true
    if (hasName) {
      nameTextPainter.paint(
        canvas,
        Offset(textRect.left + (textRect.width - nameTextPainter.width) / 2, yPos),
      );
      
      yPos += nameTextPainter.height + 8; // Move down for next text section
    }
    
    // If we should show description and it exists
    if (hasDescription) {
      // Use a text style with slightly smaller font for description
      final descTextStyle = textStyle.copyWith(
        fontSize: (style.fontSize?.toDouble() ?? 14.0) - 0.5, // Slightly smaller
      );
      
      // For longer descriptions, truncate with ellipsis if needed
      String description = element.description!;
      final maxDescriptionLength = 150;
      if (description.length > maxDescriptionLength) {
        description = description.substring(0, maxDescriptionLength - 3) + '...';
      }
      
      final descTextPainter = createTextPainter(
        text: description,
        style: descTextStyle,
        maxWidth: textRect.width,
      );
      
      // Only show description if there is space
      if (yPos + descTextPainter.height < textRect.bottom - (hasMetadata ? 20 : 0)) {
        // Draw text with a subtle background for better readability
        final descRect = Rect.fromLTWH(
          textRect.left,
          yPos - 2,
          textRect.width,
          descTextPainter.height + 4
        );
        
        // Optional: Add subtle background for description
        /* 
        final bgPaint = Paint()
          ..color = style.background?.withOpacity(0.3) ?? Colors.white.withOpacity(0.3)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(descRect, Radius.circular(2)),
          bgPaint
        );
        */
        
        descTextPainter.paint(
          canvas, 
          Offset(
            textRect.left + (textRect.width - descTextPainter.width) / 2, 
            yPos,
          ),
        );
        
        yPos += descTextPainter.height + 4; // Move down for next text section
      }
    }
    
    // Optionally show type/metadata if specified in style
    if (hasMetadata) {
      final typeTextPainter = createTextPainter(
        text: element.type,
        style: textStyle.copyWith(
          fontSize: (style.fontSize?.toDouble() ?? 14.0) - 1,
          fontStyle: FontStyle.italic,
          color: style.color?.withOpacity(0.8) ?? Colors.black.withOpacity(0.8),
        ),
        maxWidth: textRect.width,
      );
      
      // Position at the bottom if there's space, otherwise use current position
      double typeYPos = math.min(
        textRect.bottom - typeTextPainter.height,
        yPos
      );
      
      // Draw with subtle styling
      final typeBgRect = Rect.fromLTWH(
        textRect.left + (textRect.width - typeTextPainter.width) / 2 - 4,
        typeYPos - 2,
        typeTextPainter.width + 8,
        typeTextPainter.height + 4
      );
      
      // Optional: Add subtle background pill for type label
      final typeBgPaint = Paint()
        ..color = style.background?.withOpacity(0.2) ?? Colors.grey.withOpacity(0.2)
        ..style = PaintingStyle.fill;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(typeBgRect, Radius.circular(4)),
        typeBgPaint
      );
      
      typeTextPainter.paint(
        canvas, 
        Offset(
          textRect.left + (textRect.width - typeTextPainter.width) / 2, 
          typeYPos,
        ),
      );
    }
    
    // Optional: Draw technology inside element if available
    String? technology = _getTechnologyForElement(element);
    if (technology != null && technology.isNotEmpty) {
      final techTextPainter = createTextPainter(
        text: technology,
        style: textStyle.copyWith(
          fontSize: (style.fontSize?.toDouble() ?? 14.0) - 2,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w300,
          color: style.color?.withOpacity(0.7) ?? Colors.black.withOpacity(0.7),
        ),
        maxWidth: textRect.width,
      );
      
      // Position at the very bottom
      double techYPos = textRect.bottom - techTextPainter.height - 4;
      
      // Only draw if there's space and not overlapping with metadata
      if (hasMetadata) {
        techYPos = math.min(techYPos, textRect.bottom - 24);
      }
      
      if (techYPos > yPos + 8) {
        techTextPainter.paint(
          canvas, 
          Offset(
            textRect.left + (textRect.width - techTextPainter.width) / 2, 
            techYPos,
          ),
        );
      }
    }
  }

  @override
  Rect calculateElementBounds({
    required Element element,
    required ElementView elementView,
    required ElementStyle style,
  }) {
    // Use provided dimensions if available, otherwise calculate from text size
    if (elementView.width != null && elementView.height != null) {
      return Rect.fromLTWH(
        elementView.x?.toDouble() ?? 0,
        elementView.y?.toDouble() ?? 0,
        elementView.width!.toDouble(),
        elementView.height!.toDouble(),
      );
    }
    
    // Calculate width and height based on text and content
    double width = style.width?.toDouble() ?? defaultMinWidth;
    double height = style.height?.toDouble() ?? defaultMinHeight;
    
    // Determine which sections of text we need to account for
    final hasDescription = (style.description ?? true) && element.description != null && element.description!.isNotEmpty;
    final hasMetadata = (style.metadata ?? false) && element.type.isNotEmpty;
    final hasTechnology = _getTechnologyForElement(element) != null && _getTechnologyForElement(element)!.isNotEmpty;
    
    // Enhanced text style for measuring
    final textStyle = TextStyle(
      fontSize: style.fontSize?.toDouble() ?? 14.0,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.1,  // Improve readability
      height: 1.2,  // Line height multiplier for better spacing
    );

    // Measure name with enhanced styling
    final nameTextPainter = createTextPainter(
      text: element.name,
      style: textStyle.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: (style.fontSize?.toDouble() ?? 14.0) + 1, // Slightly larger
        letterSpacing: 0.2, // Better letter spacing for titles
      ),
    );
    
    // Calculate required dimensions based on name
    width = math.max(width, nameTextPainter.width + defaultPadding * 2 + 20); // Extra padding for readability
    height = math.max(height, nameTextPainter.height + defaultPadding * 2);
    
    // Extra vertical space needed for content
    double extraHeight = 0;
    
    // If description exists, measure it too
    if (hasDescription) {
      // For longer descriptions, truncate to get realistic size
      String description = element.description!;
      final maxDescriptionLength = 150;
      if (description.length > maxDescriptionLength) {
        description = description.substring(0, maxDescriptionLength);
      }
      
      final descTextPainter = createTextPainter(
        text: description,
        style: textStyle.copyWith(
          fontSize: (style.fontSize?.toDouble() ?? 14.0) - 0.5, // Slightly smaller
        ),
        maxWidth: width - defaultPadding * 2, // Constrain width for wrapping
      );
      
      width = math.max(width, descTextPainter.width + defaultPadding * 2 + 10); // Extra padding for readability
      extraHeight += descTextPainter.height + 8; // Extra space for description
    }
    
    // If we should show metadata, measure that too
    if (hasMetadata) {
      final typeTextPainter = createTextPainter(
        text: element.type,
        style: textStyle.copyWith(
          fontSize: (style.fontSize?.toDouble() ?? 14.0) - 1,
          fontStyle: FontStyle.italic,
        ),
        maxWidth: width - defaultPadding * 2, // Constrain width for wrapping
      );
      
      width = math.max(width, typeTextPainter.width + defaultPadding * 2 + 16); // Extra padding for pill background
      extraHeight += typeTextPainter.height + 8; // Extra space for metadata pill
    }
    
    // If technology is specified, account for it too
    if (hasTechnology) {
      final techTextPainter = createTextPainter(
        text: _getTechnologyForElement(element)!,
        style: textStyle.copyWith(
          fontSize: (style.fontSize?.toDouble() ?? 14.0) - 2,
          fontStyle: FontStyle.normal,
        ),
        maxWidth: width - defaultPadding * 2, // Constrain width for wrapping
      );
      
      width = math.max(width, techTextPainter.width + defaultPadding * 2);
      extraHeight += techTextPainter.height + 4; // Extra space for technology
    }
    
    // Add extra vertical space for content
    height = math.max(height, nameTextPainter.height + extraHeight + defaultPadding * 2);
    
    // Element-specific sizing adjustments
    if (element.type == 'Person') {
      // People are typically square or slightly taller
      height = math.max(height, width * 1.1);
    } else if (element.type == 'SoftwareSystem') {
      // Software systems are typically wider
      width = math.max(width, height * 1.2);
    } else if (element.type == 'Container') {
      // Containers are typically slightly wider than tall
      width = math.max(width, height * 1.1);
    } else if (element.type == 'Component') {
      // Components are typically slightly taller than wide
      height = math.max(height, width * 1.05);
    }
    
    // Apply style-based sizing
    if (style.shape == Shape.circle || style.shape == Shape.hexagon) {
      // Make circular and hexagonal elements square
      final size = math.max(width, height);
      width = size;
      height = size;
    } else if (style.shape == Shape.cylinder) {
      // Adjust height for cylinders to account for top/bottom ellipses
      height += 20; // Extra height for cylinder caps
    }
    
    // Ensure minimum dimensions
    width = math.max(width, defaultMinWidth);
    height = math.max(height, defaultMinHeight);
    
    // Return the calculated bounds
    return Rect.fromLTWH(
      elementView.x?.toDouble() ?? 0,
      elementView.y?.toDouble() ?? 0,
      width,
      height,
    );
  }

  /// Calculate the rendering rectangle based on the element view
  Rect _calculateRenderRect(ElementView elementView) {
    return Rect.fromLTWH(
      elementView.x?.toDouble() ?? 0,
      elementView.y?.toDouble() ?? 0,
      elementView.width?.toDouble() ?? defaultMinWidth,
      elementView.height?.toDouble() ?? defaultMinHeight,
    );
  }
  
  /// Helper method to get technology from an element.
  /// This handles the fact that technology is only available on certain element types.
  String? _getTechnologyForElement(Element element) {
    // We need to check for specific element types that have technology
    final type = element.type.toLowerCase();
    
    // Check if technology is in properties
    if (element.properties.containsKey('technology')) {
      return element.properties['technology'];
    }
    
    // For Container and Component, the technology field is available
    // through dynamic casting, but we'll access it from properties instead
    if (type == 'container' || type == 'component') {
      // 'technology' is a commonly used property for these elements
      return element.properties['technology'];
    }
    
    return null;
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
    
    // Simple rectangle hit test
    return rect.contains(point);
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
    // This is handled by the relationship renderer, not the element renderer
  }

  @override
  Path calculateRelationshipPath({
    required Relationship relationship,
    required RelationshipView relationshipView,
    required RelationshipStyle style,
    required Rect sourceRect,
    required Rect targetRect,
  }) {
    // This is handled by the relationship renderer, not the element renderer
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
    // This is handled by the relationship renderer, not the element renderer
    return false;
  }
}

// Math import is moved to the top of the file