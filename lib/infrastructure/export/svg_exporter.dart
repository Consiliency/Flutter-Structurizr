import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart' hide Element, Container, View, Border;
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/view/model_view.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';
import 'package:flutter_structurizr/infrastructure/export/rendering_pipeline.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/infrastructure/export/diagram_exporter.dart'
    show DiagramReference, DiagramExporter;
import 'package:logging/logging.dart';
import 'package:flutter_structurizr/domain/model/element.dart'
    as structurizr_model;
import 'package:flutter_structurizr/domain/model/container.dart'
    as structurizr_model;
import 'package:flutter_structurizr/domain/model/component.dart'
    as structurizr_model;

/// An exporter for SVG format diagrams
class SvgExporter implements DiagramExporter<String> {
  /// Render parameters for the diagram
  final DiagramRenderParameters? renderParameters;

  /// Whether to include CSS styling in the SVG
  final bool includeCss;

  /// Whether to include interactive features (hover effects, etc.)
  final bool interactive;

  /// Progress callback for the export operation
  final ValueChanged<double>? onProgress;

  /// Creates a new SVG exporter
  SvgExporter({
    this.renderParameters,
    this.includeCss = true,
    this.interactive = false,
    this.onProgress,
  });

  final _logger = Logger('SVGExporter');

  @override
  Future<String> export(DiagramReference diagram) async {
    try {
      // Report starting progress
      onProgress?.call(0.1);

      // Get the view from the workspace
      final workspace = diagram.workspace;
      final viewKey = diagram.viewKey;
      final view = _findViewByKey(workspace, viewKey);

      if (view == null) {
        throw Exception('View not found with key: $viewKey');
      }

      // Get render parameters with defaults
      final width = renderParameters?.width ?? 1920;
      final height = renderParameters?.height ?? 1080;
      final includeLegend = renderParameters?.includeLegend ?? true;
      final includeTitle = renderParameters?.includeTitle ?? true;
      final includeMetadata = renderParameters?.includeMetadata ?? true;
      final elementScaleFactor = renderParameters?.elementScaleFactor ?? 1.0;

      // Report data gathering progress
      onProgress?.call(0.2);

      // Get all elements and relationships for the view
      final elements = workspace.model.elements ?? [];
      final relationships = workspace.model.relationships ?? [];

      // Report progress
      onProgress?.call(0.3);

      // Get styling information
      final styles = workspace.styles ?? const Styles();

      // Calculate diagram bounds
      const bounds = Rect.fromLTWH(0, 0, 1920, 1080);

      // Report progress
      onProgress?.call(0.4);

      // Generate SVG content
      final svgContent = _generateSvg(
        elements: elements,
        relationships: relationships,
        styles: styles,
        view: view,
        title: diagram.title ?? view.title ?? view.key,
        width: width,
        height: height,
        bounds: bounds,
        includeLegend: includeLegend,
        includeTitle: includeTitle,
        includeMetadata: includeMetadata,
        elementScaleFactor: elementScaleFactor,
        workspace: workspace,
      );

      // Report completion
      onProgress?.call(1.0);

      return svgContent;
    } catch (e) {
      throw Exception('Failed to export diagram to SVG: $e');
    }
  }

  /// Generates SVG content from diagram elements
  String _generateSvg({
    required List<structurizr_model.Element> elements,
    required List<structurizr_model.Relationship> relationships,
    required Styles styles,
    required ModelView view,
    required String title,
    required double width,
    required double height,
    required Rect bounds,
    required bool includeLegend,
    required bool includeTitle,
    required bool includeMetadata,
    required double elementScaleFactor,
    required Workspace workspace,
  }) {
    final buffer = StringBuffer();

    // Calculate scale to fit the diagram into the SVG
    final scale =
        _calculateScaleFactor(bounds, width, height, elementScaleFactor);

    // Calculate transform to center the diagram
    final translateX = (width - bounds.width * scale) / 2 - bounds.left * scale;
    final translateY =
        (height - bounds.height * scale) / 2 - bounds.top * scale;

    // SVG header
    buffer.writeln('<?xml version="1.0" encoding="UTF-8" standalone="no"?>');
    buffer.writeln(
        '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
        'version="1.1" width="$width" height="$height" viewBox="0 0 $width $height">');

    // Add metadata
    buffer.writeln('  <metadata>');
    buffer.writeln(
        '    <structurizr:metadata xmlns:structurizr="http://structurizr.com/schema">');
    buffer.writeln(
        '      <structurizr:workspace id="${workspace.id}" name="${_escapeXml(workspace.name)}"/>');
    buffer.writeln(
        '      <structurizr:view id="${view.key}" type="${view.runtimeType.toString()}"/>');
    buffer.writeln(
        '      <structurizr:generated>${DateTime.now().toIso8601String()}</structurizr:generated>');
    buffer.writeln(
        '      <structurizr:generator>Flutter Structurizr</structurizr:generator>');
    buffer.writeln('    </structurizr:metadata>');
    buffer.writeln('  </metadata>');

    // Add title
    buffer.writeln('  <title>${_escapeXml(title)}</title>');

    // Add CSS if requested
    if (includeCss) {
      buffer.writeln('  <style type="text/css"><![CDATA[');
      buffer.writeln('    /* Base styling */');
      buffer.writeln('    .element { stroke-width: 2; }');
      buffer.writeln('    .person { fill: #08427b; stroke: #052e56; }');
      buffer
          .writeln('    .software-system { fill: #1168bd; stroke: #0b4884; }');
      buffer.writeln('    .container { fill: #438dd5; stroke: #2e6295; }');
      buffer.writeln('    .component { fill: #85bbf0; stroke: #5d82a8; }');
      buffer
          .writeln('    .relationship { stroke: #707070; stroke-width: 1.5; }');
      buffer.writeln(
          '    .label { font-family: Arial, sans-serif; font-size: 12px; fill: #000000; }');
      buffer.writeln('    .element-name { font-weight: bold; }');
      buffer.writeln('    .element-description { font-size: 10px; }');

      // Add more specific styles based on element types
      buffer.writeln('    .person-label { fill: #ffffff; }');
      buffer.writeln('    .software-system-label { fill: #ffffff; }');
      buffer.writeln('    .container-label { fill: #ffffff; }');
      buffer.writeln('    .component-label { fill: #000000; }');

      if (interactive) {
        buffer.writeln('    /* Interactive features */');
        buffer.writeln('    .element:hover { opacity: 0.8; cursor: pointer; }');
        buffer.writeln(
            '    .relationship:hover { stroke-width: 2.5; cursor: pointer; }');
      }

      buffer.writeln('  ]]></style>');
    }

    // Add definitions for markers (e.g., arrowheads)
    buffer.writeln('  <defs>');
    buffer.writeln(
        '    <marker id="arrow" viewBox="0 0 10 10" refX="10" refY="5" markerWidth="6" markerHeight="6" orient="auto">');
    buffer.writeln('      <path d="M 0 0 L 10 5 L 0 10 z" fill="#707070" />');
    buffer.writeln('    </marker>');

    // Add definitions for element icons and patterns
    buffer.writeln('    <symbol id="person" viewBox="0 0 48 48">');
    buffer.writeln('      <circle cx="24" cy="12" r="8" />');
    buffer.writeln(
        '      <path d="M 12 48 L 12 30 C 12 24 18 18 24 18 C 30 18 36 24 36 30 L 36 48 Z" />');
    buffer.writeln('    </symbol>');

    buffer.writeln('  </defs>');

    // Create a group for all diagram elements with the transform
    buffer.writeln('  <g id="diagram">');

    // Add background rectangle
    buffer.writeln(
        '    <rect x="0" y="0" width="$width" height="$height" fill="white" />');

    // Create a transform group to adjust the position of all elements
    buffer.writeln(
        '    <g id="diagramContent" transform="translate($translateX, $translateY) scale($scale)">');

    // Add parent boundaries first
    buffer.writeln('      <g id="boundaries">');
    _generateSvgBoundaries(buffer, elements, styles);
    buffer.writeln('      </g>');

    // Add relationships
    buffer.writeln('      <g id="relationships">');
    _generateSvgRelationships(buffer, relationships, elements, styles);
    buffer.writeln('      </g>');

    // Add elements (boxes, circles, etc.)
    buffer.writeln('      <g id="elements">');
    _generateSvgElements(buffer, elements, styles);
    buffer.writeln('      </g>');

    // Close the transform group
    buffer.writeln('    </g>');

    // Close diagram group
    buffer.writeln('  </g>');

    // Add title if requested
    if (includeTitle) {
      buffer.writeln('  <g id="title">');
      buffer.writeln(
          '    <text x="${width / 2}" y="30" text-anchor="middle" font-family="Arial, sans-serif" font-size="24" font-weight="bold">${_escapeXml(title)}</text>');
      buffer.writeln('  </g>');
    }

    // Add legend if requested
    if (includeLegend) {
      buffer.writeln(
          '  <g id="legend" transform="translate(${width - 200}, 20)">');
      buffer.writeln(
          '    <rect x="0" y="0" width="180" height="170" fill="#f8f8f8" stroke="#dddddd" rx="5" ry="5" />');
      buffer.writeln(
          '    <text x="90" y="20" text-anchor="middle" font-family="Arial, sans-serif" font-weight="bold">Legend</text>');

      // Person
      buffer.writeln(
          '    <rect x="10" y="35" width="20" height="20" rx="10" ry="10" class="person" />');
      buffer.writeln(
          '    <text x="40" y="50" font-family="Arial, sans-serif" font-size="12">Person</text>');

      // Software System
      buffer.writeln(
          '    <rect x="10" y="65" width="20" height="20" class="software-system" />');
      buffer.writeln(
          '    <text x="40" y="80" font-family="Arial, sans-serif" font-size="12">Software System</text>');

      // Container
      buffer.writeln(
          '    <rect x="10" y="95" width="20" height="20" class="container" />');
      buffer.writeln(
          '    <text x="40" y="110" font-family="Arial, sans-serif" font-size="12">Container</text>');

      // Component
      buffer.writeln(
          '    <rect x="10" y="125" width="20" height="20" class="component" />');
      buffer.writeln(
          '    <text x="40" y="140" font-family="Arial, sans-serif" font-size="12">Component</text>');

      // Relationship
      buffer.writeln(
          '    <line x1="10" y1="155" x2="30" y2="155" class="relationship" marker-end="url(#arrow)" />');
      buffer.writeln(
          '    <text x="40" y="160" font-family="Arial, sans-serif" font-size="12">Relationship</text>');

      buffer.writeln('  </g>');
    }

    // Add metadata if requested
    if (includeMetadata) {
      _generateSvgMetadata(buffer, workspace, view, width, height);
    }

    // Close SVG
    buffer.writeln('</svg>');

    return buffer.toString();
  }

  /// Calculate scaling factor to fit diagram in view
  double _calculateScaleFactor(
      Rect bounds, double width, double height, double elementScaleFactor) {
    if (bounds == Rect.zero) {
      return 1.0;
    }

    // Calculate scale based on width and height constraints
    final scaleX = (width * 0.9) / bounds.width;
    final scaleY = (height * 0.85) / bounds.height;

    // Use the smaller scale to ensure the diagram fits within the view
    // and apply the element scale factor
    return min(scaleX, scaleY) * elementScaleFactor;
  }

  /// Generate SVG for parent boundaries
  void _generateSvgBoundaries(
    StringBuffer buffer,
    List<structurizr_model.Element> elements,
    Styles styles,
  ) {
    // Group elements by parent
    final parentGroups = <String, List<structurizr_model.Element>>{};

    for (final element in elements) {
      if (element.parentId != null && element.parentId!.isNotEmpty) {
        parentGroups.putIfAbsent(element.parentId!, () => []).add(element);
      }
    }

    // Create boundaries for each parent group
    for (final entry in parentGroups.entries) {
      final parentId = entry.key;
      final childElements = entry.value;

      if (childElements.isEmpty) continue;

      // Find the parent element manually
      structurizr_model.Element? parentElement;
      for (final e in elements) {
        if (e.id == parentId) {
          parentElement = e;
          break;
        }
      }
      if (parentElement == null) continue;

      // Calculate boundary dimensions based on children positions
      double minX = double.infinity;
      double minY = double.infinity;
      double maxX = -double.infinity;
      double maxY = -double.infinity;

      for (final child in childElements) {
        final position = (child as dynamic).position ?? null;
        if (position != null) {
          final width = (child as dynamic).width?.toDouble() ?? 150.0;
          final height = (child as dynamic).height?.toDouble() ?? 100.0;
          final x = (position.x is double)
              ? position.x
              : double.tryParse(position.x.toString()) ?? 0.0;
          final y = (position.y is double)
              ? position.y
              : double.tryParse(position.y.toString()) ?? 0.0;
          minX = min(minX, (x - 10.0) as double);
          minY = min(minY, (y - 10.0) as double);
          maxX = max(maxX, (x + width + 10.0) as double);
          maxY = max(maxY, (y + height + 10.0) as double);
        }
      }

      // Add padding
      minX -= 20;
      minY -= 30; // Extra space for header
      maxX += 20;
      maxY += 20;

      // Get style for the parent
      final style = styles.findElementStyle(parentElement);
      String backgroundColor = '#f0f0f0';
      String stroke = '#000000';
      String textColor = '#000000';

      if (style != null) {
        if (style.background != null) {
          backgroundColor = _colorToHex(style.background);
        }
        stroke = _colorToHex(style.border);
        if (style.color != null) textColor = _colorToHex(style.color);
      }

      // Determine the class based on the element type
      String cssClass = 'element boundary';
      if (parentElement is SoftwareSystem) {
        cssClass += ' software-system-boundary';
      } else if (parentElement is structurizr_model.Container) {
        cssClass += ' container-boundary';
      } else if (parentElement is structurizr_model.Component) {
        cssClass += ' component-boundary';
      }

      // Draw the boundary rectangle
      buffer.writeln(
          '        <rect id="boundary-${parentElement.id}" class="$cssClass" '
          'x="$minX" y="$minY" width="${maxX - minX}" height="${maxY - minY}" '
          'fill="${backgroundColor}40" stroke="$stroke" stroke-width="1" stroke-dasharray="5,5" rx="10" ry="10" />');

      // Draw the header
      buffer.writeln('        <text x="${minX + 10}" y="${minY + 20}" '
          'font-family="Arial, sans-serif" font-size="14" font-weight="bold" fill="$textColor">'
          '${_escapeXml(parentElement.name)}</text>');
    }
  }

  /// Generate SVG for elements
  void _generateSvgElements(
    StringBuffer buffer,
    List<structurizr_model.Element> elements,
    Styles styles,
  ) {
    for (final element in elements) {
      final position = (element as dynamic).position ?? null;
      if (position == null) continue;

      final x = position.x.toDouble();
      final y = position.y.toDouble();
      final width = (element as dynamic).width?.toDouble() ?? 150.0;
      final height = (element as dynamic).height?.toDouble() ?? 100.0;

      // Get style for the element
      final style = styles.findElementStyle(element);
      String backgroundColor = '#eeeeee';
      String stroke = '#000000';
      String textColor = '#000000';

      if (style != null) {
        if (style.background != null) {
          backgroundColor = _colorToHex(style.background);
        }
        stroke = _colorToHex(style.border);
        if (style.color != null) textColor = _colorToHex(style.color);
      }

      // Determine the CSS class based on the element type
      String cssClass = 'element';
      if (element is Person) {
        cssClass += ' person';
      } else if (element is SoftwareSystem) {
        cssClass += ' software-system';
      } else if (element is structurizr_model.Container) {
        cssClass += ' container';
      } else if (element is structurizr_model.Component) {
        cssClass += ' component';
      }

      // Add interactive features if requested
      String interactiveAttribs = '';
      if (interactive) {
        interactiveAttribs =
            ' onmouseover="evt.target.setAttribute(\'opacity\', 0.8)" '
            'onmouseout="evt.target.setAttribute(\'opacity\', 1)"';
      }

      // Use different shapes based on element type and style
      if (element is Person) {
        // Person is drawn with a special shape
        final centerX = x + width / 2;
        final iconSize = min(width as num, height as num) * 0.6;

        buffer.writeln(
            '        <circle id="${element.id}-head" class="$cssClass" cx="$centerX" cy="${y + height * 0.25}" '
            'r="${iconSize * 0.3}" fill="$backgroundColor" stroke="$stroke" stroke-width="2"$interactiveAttribs />');

        buffer.writeln(
            '        <path id="${element.id}-body" class="$cssClass" d="M ${centerX - iconSize * 0.3} ${y + height * 0.35} '
            'C ${centerX - iconSize * 0.3} ${y + height * 0.7}, ${centerX + iconSize * 0.3} ${y + height * 0.7}, '
            '${centerX + iconSize * 0.3} ${y + height * 0.35} L ${centerX + iconSize * 0.3} ${y + height * 0.8} '
            'L ${centerX - iconSize * 0.3} ${y + height * 0.8} Z" '
            'fill="$backgroundColor" stroke="$stroke" stroke-width="2"$interactiveAttribs />');
      } else {
        // Default rectangular shape for other element types
        buffer.writeln(
            '        <rect id="${element.id}" class="$cssClass" x="$x" y="$y" '
            'width="$width" height="$height" fill="$backgroundColor" stroke="$stroke" '
            'stroke-width="2" rx="5" ry="5"$interactiveAttribs />');
      }

      // Add element name
      buffer.writeln(
          '        <text id="${element.id}-name" class="label element-name" '
          'x="$x" y="$y" text-anchor="middle" dominant-baseline="middle" '
          'font-family="Arial, sans-serif" font-size="12" font-weight="bold" fill="$textColor">'
          '${_escapeXml(element.name)}</text>');
    }
  }

  /// Generate SVG for relationships
  void _generateSvgRelationships(
    StringBuffer buffer,
    List<structurizr_model.Relationship> relationships,
    List<structurizr_model.Element> elements,
    Styles styles,
  ) {
    // Function to find element by ID
    structurizr_model.Element? findElementById(String id) {
      for (final element in elements) {
        if (element.id == id) return element;
      }
      return null;
    }

    // Process each relationship
    for (final relationship in relationships) {
      final sourceElement = findElementById(relationship.sourceId);
      final targetElement = findElementById(relationship.destinationId);

      if (sourceElement == null ||
          targetElement == null ||
          (sourceElement as dynamic).position == null ||
          (targetElement as dynamic).position == null) {
        continue;
      }

      // Get style for the relationship
      final style = styles.findRelationshipStyle(relationship);
      String color = '#707070';
      if (style != null && style.color != null) {
        color = _colorToHex(style.color);
      }
      double thickness = 1.5;
      if (style != null) thickness = style.thickness.toDouble();

      // Calculate start and end points
      final sourcePos = (sourceElement as dynamic).position;
      final targetPos = (targetElement as dynamic).position;
      final sourceWidth = (sourceElement as dynamic).width?.toDouble() ?? 150.0;
      final sourceHeight =
          (sourceElement as dynamic).height?.toDouble() ?? 100.0;
      final targetWidth = (targetElement as dynamic).width?.toDouble() ?? 150.0;
      final targetHeight =
          (targetElement as dynamic).height?.toDouble() ?? 100.0;

      // Calculate center points
      final sourceCenterX = sourcePos.x.toDouble() + sourceWidth / 2;
      final sourceCenterY = sourcePos.y.toDouble() + sourceHeight / 2;
      final targetCenterX = targetPos.x.toDouble() + targetWidth / 2;
      final targetCenterY = targetPos.y.toDouble() + targetHeight / 2;

      // Calculate the path
      String pathD;

      // Simple straight line for now
      pathD = 'M $sourceCenterX $sourceCenterY L $targetCenterX $targetCenterY';

      // Determine the middle point for the label
      final midX = (sourceCenterX + targetCenterX) / 2;
      final midY = (sourceCenterY + targetCenterY) / 2;

      // Create the path
      buffer.writeln(
          '        <path id="${relationship.id}" class="relationship" d="$pathD" '
          'stroke="$color" stroke-width="$thickness" fill="none" marker-end="url(#arrow)" />');
    }
  }

  /// Generate SVG metadata footer
  void _generateSvgMetadata(
    StringBuffer buffer,
    Workspace workspace,
    ModelView view,
    double width,
    double height,
  ) {
    buffer.writeln(
        '  <g id="metadata" transform="translate(5, ${height - 25})">');
    buffer.writeln(
        '    <text font-family="Arial, sans-serif" font-size="10" fill="#666666">');
    buffer.writeln(
        '      <tspan x="0" dy="0">Workspace: ${_escapeXml(workspace.name)}</tspan>');
    buffer.writeln(
        '      <tspan x="0" dy="12">View: ${_escapeXml(view.key)}</tspan>');
    buffer.writeln(
        '      <tspan x="0" dy="12">Generated: ${DateTime.now().toIso8601String().split('T')[0]}</tspan>');
    buffer.writeln('      <tspan x="0" dy="12">Flutter Structurizr</tspan>');
    buffer.writeln('    </text>');
    buffer.writeln('  </g>');
  }

  /// Escape special XML characters
  String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  @override
  Future<List<String>> exportBatch(
    List<DiagramReference> diagrams, {
    ValueChanged<double>? onProgress,
  }) async {
    final results = <String>[];

    for (var i = 0; i < diagrams.length; i++) {
      // Call progress callback with approximate progress
      final progress = i / diagrams.length;
      onProgress?.call(progress);
      this.onProgress?.call(progress);

      // Export diagram and add to results
      try {
        final result = await export(diagrams[i]);
        results.add(result);
      } catch (e) {
        // Log error but continue with other diagrams
        _logger.severe('Error exporting diagram ${diagrams[i].viewKey}: $e');

        // Add a placeholder SVG with error message
        results.add(_generateErrorSvg(diagrams[i].viewKey, e.toString()));
      }
    }

    // Call progress callback with completion
    onProgress?.call(1.0);
    this.onProgress?.call(1.0);

    return results;
  }

  /// Generate an error SVG when export fails
  String _generateErrorSvg(String viewKey, String errorMessage) {
    final width = renderParameters?.width ?? 1920;
    final height = renderParameters?.height ?? 1080;

    final buffer = StringBuffer();

    buffer.writeln('<?xml version="1.0" encoding="UTF-8" standalone="no"?>');
    buffer.writeln(
        '<svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="$width" height="$height">');
    buffer.writeln('  <title>Export Error</title>');
    buffer.writeln(
        '  <rect x="0" y="0" width="$width" height="$height" fill="#f8d7da" />');
    buffer.writeln(
        '  <text x="${width / 2}" y="${height / 2 - 20}" text-anchor="middle" font-family="Arial, sans-serif" font-size="24" font-weight="bold" fill="#721c24">Export Error</text>');
    buffer.writeln(
        '  <text x="${width / 2}" y="${height / 2 + 20}" text-anchor="middle" font-family="Arial, sans-serif" font-size="16" fill="#721c24">View: $viewKey</text>');
    buffer.writeln(
        '  <text x="${width / 2}" y="${height / 2 + 50}" text-anchor="middle" font-family="Arial, sans-serif" font-size="14" fill="#721c24">${_escapeXml(errorMessage)}</text>');
    buffer.writeln('</svg>');

    return buffer.toString();
  }

  /// Helper to convert Color to hex string
  String _colorToHex(dynamic color) {
    if (color == null) return '';
    if (color is String) return color;
    if (color is int) {
      return '#${color.toRadixString(16).padLeft(8, '0').substring(2)}';
    }
    if (color is Color) {
      return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
    }
    return color.toString();
  }

  ModelView? _findViewByKey(Workspace workspace, String? key) {
    if (key == null) return null;
    final v = workspace.views;
    for (final view in [
      ...v.systemLandscapeViews,
      ...v.systemContextViews,
      ...v.containerViews,
      ...v.componentViews,
      ...v.dynamicViews,
      ...v.deploymentViews,
    ]) {
      if (view.key == key) return view;
    }
    return null;
  }
}
