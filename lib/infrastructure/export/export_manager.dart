import 'package:flutter/material.dart' hide Element, Container, View;
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/infrastructure/export/rendering_pipeline.dart';
import 'package:flutter_structurizr/infrastructure/export/png_exporter.dart';
import 'package:flutter_structurizr/infrastructure/export/svg_exporter.dart';
import 'package:flutter_structurizr/infrastructure/export/plantuml_exporter.dart';
import 'package:flutter_structurizr/infrastructure/export/mermaid_exporter.dart';
import 'package:flutter_structurizr/infrastructure/export/dot_exporter.dart';
import 'package:flutter_structurizr/infrastructure/export/dsl_exporter.dart';
import 'package:flutter_structurizr/infrastructure/export/c4_exporter.dart';
import 'package:flutter_structurizr/infrastructure/export/diagram_exporter.dart'
    show DiagramReference;

/// Format for diagram export
enum ExportFormat {
  /// PNG image format
  png,

  /// SVG vector format
  svg,

  /// PlantUML format
  plantuml,

  /// C4-PlantUML format
  c4plantuml,

  /// Mermaid format
  mermaid,

  /// C4-style Mermaid format
  c4mermaid,

  /// DOT/Graphviz format
  dot,

  /// Structurizr DSL format
  dsl,

  /// C4 model JSON format
  c4json,

  /// C4 model YAML format
  c4yaml,
}

/// Configuration for diagram export
class ExportOptions {
  /// Format to export to
  final ExportFormat format;

  /// Width of the exported diagram
  final double width;

  /// Height of the exported diagram
  final double height;

  /// Whether to include a legend
  final bool includeLegend;

  /// Whether to include a title
  final bool includeTitle;

  /// Whether to include metadata (date, version, etc.)
  final bool includeMetadata;

  /// Background color (only for raster formats)
  final Color backgroundColor;

  /// Whether to use a transparent background (PNG only)
  final bool transparentBackground;

  /// Whether to use memory-efficient rendering (recommended for large diagrams)
  final bool useMemoryEfficientRendering;

  /// Progress callback
  final ValueChanged<double>? onProgress;

  /// Creates a new export options configuration
  const ExportOptions({
    required this.format,
    this.width = 1920,
    this.height = 1080,
    this.includeLegend = true,
    this.includeTitle = true,
    this.includeMetadata = true,
    this.backgroundColor = Colors.white,
    this.transparentBackground = false,
    this.useMemoryEfficientRendering = true,
    this.onProgress,
  });
}

/// Event for export progress
class ExportProgressEvent {
  /// Percentage complete (0.0 to 1.0)
  final double percentage;

  /// Optional message about the current phase
  final String? message;

  /// Creates a new progress event
  const ExportProgressEvent({
    required this.percentage,
    this.message,
  });
}

/// Manager for all diagram export operations
class ExportManager {
  /// Exports a diagram to the specified format
  ///
  /// [workspace] The workspace containing the diagram
  /// [viewKey] The key of the view to export
  /// [options] Configuration for the export
  ///
  /// Returns the exported content (Uint8List for PNG, String for others)
  Future<dynamic> exportDiagram({
    required Workspace workspace,
    required String viewKey,
    required ExportOptions options,
    String? title,
  }) async {
    // Create a diagram reference
    final diagram = DiagramReference(
      workspace: workspace,
      viewKey: viewKey,
      title: title,
    );

    // Create render parameters from options
    final renderParameters = DiagramRenderParameters(
      width: options.width,
      height: options.height,
      includeLegend: options.includeLegend,
      includeTitle: options.includeTitle,
      includeMetadata: options.includeMetadata,
      backgroundColor: options.backgroundColor,
      includeElementNames: true,
      includeElementDescriptions: false,
      includeRelationshipDescriptions: true,
      elementScaleFactor: 1.0,
    );

    // Choose the appropriate exporter
    switch (options.format) {
      case ExportFormat.png:
        final exporter = PngExporter(
          renderParameters: renderParameters,
          transparentBackground: options.transparentBackground,
          onProgress: options.onProgress,
          useMemoryEfficientRendering: options.useMemoryEfficientRendering,
        );
        return await exporter.export(diagram);

      case ExportFormat.svg:
        final exporter = SvgExporter(
          renderParameters: renderParameters,
          includeCss: true,
          interactive: false,
          onProgress: options.onProgress,
        );
        return await exporter.export(diagram);

      case ExportFormat.plantuml:
        final exporter = PlantUmlExporter(
          style: PlantUmlStyle.standard,
          includeLegend: options.includeLegend,
          onProgress: options.onProgress,
        );
        return await exporter.export(diagram);

      case ExportFormat.c4plantuml:
        final exporter = PlantUmlExporter(
          style: PlantUmlStyle.c4puml,
          includeLegend: options.includeLegend,
          onProgress: options.onProgress,
        );
        return await exporter.export(diagram);

      case ExportFormat.mermaid:
        final exporter = MermaidExporter(
          style: MermaidStyle.standard,
          includeTheme: true,
          onProgress: options.onProgress,
        );
        return await exporter.export(diagram);

      case ExportFormat.c4mermaid:
        final exporter = MermaidExporter(
          style: MermaidStyle.c4,
          includeTheme: true,
          onProgress: options.onProgress,
        );
        return await exporter.export(diagram);

      case ExportFormat.dot:
        final exporter = DotExporter(
          layout: DotLayout.dot,
          includeCustomStyling: true,
          onProgress: options.onProgress,
        );
        return await exporter.export(diagram);

      case ExportFormat.dsl:
        final exporter = DslExporter(
          includeMetadata: true,
          includeStyles: true,
          includeViews: true,
          onProgress: options.onProgress,
        );
        return await exporter.export(diagram);

      case ExportFormat.c4json:
        final exporter = C4Exporter(
          style: C4DiagramStyle.standard,
          format: C4OutputFormat.json,
          includeMetadata: options.includeMetadata,
          includeRelationships: true,
          includeStyles: true,
          onProgress: options.onProgress,
        );
        return await exporter.export(diagram);

      case ExportFormat.c4yaml:
        final exporter = C4Exporter(
          style: C4DiagramStyle.standard,
          format: C4OutputFormat.yaml,
          includeMetadata: options.includeMetadata,
          includeRelationships: true,
          includeStyles: true,
          onProgress: options.onProgress,
        );
        return await exporter.export(diagram);
    }
  }

  /// Exports multiple diagrams in a batch operation
  ///
  /// [diagrams] List of DiagramReference objects to export
  /// [options] Configuration for the export
  ///
  /// Returns a list of exported content, matching the order of input diagrams
  Future<List<dynamic>> exportBatch({
    required List<DiagramReference> diagrams,
    required ExportOptions options,
  }) async {
    // Create render parameters from options
    final renderParameters = DiagramRenderParameters(
      width: options.width,
      height: options.height,
      includeLegend: options.includeLegend,
      includeTitle: options.includeTitle,
      includeMetadata: options.includeMetadata,
      backgroundColor: options.backgroundColor,
      includeElementNames: true,
      includeElementDescriptions: false,
      includeRelationshipDescriptions: true,
      elementScaleFactor: 1.0,
    );

    // Choose the appropriate exporter
    switch (options.format) {
      case ExportFormat.png:
        final exporter = PngExporter(
          renderParameters: renderParameters,
          transparentBackground: options.transparentBackground,
          onProgress: options.onProgress,
          useMemoryEfficientRendering: options.useMemoryEfficientRendering,
        );
        return await exporter.exportBatch(diagrams,
            onProgress: options.onProgress);

      case ExportFormat.svg:
        final exporter = SvgExporter(
          renderParameters: renderParameters,
          includeCss: true,
          interactive: false,
          onProgress: options.onProgress,
        );
        return await exporter.exportBatch(diagrams,
            onProgress: options.onProgress);

      case ExportFormat.plantuml:
        final exporter = PlantUmlExporter(
          style: PlantUmlStyle.standard,
          includeLegend: options.includeLegend,
          onProgress: options.onProgress,
        );
        return await exporter.exportBatch(diagrams,
            onProgress: options.onProgress);

      case ExportFormat.c4plantuml:
        final exporter = PlantUmlExporter(
          style: PlantUmlStyle.c4puml,
          includeLegend: options.includeLegend,
          onProgress: options.onProgress,
        );
        return await exporter.exportBatch(diagrams,
            onProgress: options.onProgress);

      case ExportFormat.mermaid:
        final exporter = MermaidExporter(
          style: MermaidStyle.standard,
          includeTheme: true,
          onProgress: options.onProgress,
        );
        return await exporter.exportBatch(diagrams,
            onProgress: options.onProgress);

      case ExportFormat.c4mermaid:
        final exporter = MermaidExporter(
          style: MermaidStyle.c4,
          includeTheme: true,
          onProgress: options.onProgress,
        );
        return await exporter.exportBatch(diagrams,
            onProgress: options.onProgress);

      case ExportFormat.dot:
        final exporter = DotExporter(
          layout: DotLayout.dot,
          includeCustomStyling: true,
          onProgress: options.onProgress,
        );
        return await exporter.exportBatch(diagrams,
            onProgress: options.onProgress);

      case ExportFormat.dsl:
        final exporter = DslExporter(
          includeMetadata: true,
          includeStyles: true,
          includeViews: true,
          onProgress: options.onProgress,
        );
        return await exporter.exportBatch(diagrams,
            onProgress: options.onProgress);

      case ExportFormat.c4json:
        final exporter = C4Exporter(
          style: C4DiagramStyle.standard,
          format: C4OutputFormat.json,
          includeMetadata: options.includeMetadata,
          includeRelationships: true,
          includeStyles: true,
          onProgress: options.onProgress,
        );
        return await exporter.exportBatch(diagrams,
            onProgress: options.onProgress);

      case ExportFormat.c4yaml:
        final exporter = C4Exporter(
          style: C4DiagramStyle.standard,
          format: C4OutputFormat.yaml,
          includeMetadata: options.includeMetadata,
          includeRelationships: true,
          includeStyles: true,
          onProgress: options.onProgress,
        );
        return await exporter.exportBatch(diagrams,
            onProgress: options.onProgress);
    }
  }

  /// Returns the appropriate file extension for a given export format
  static String getFileExtension(ExportFormat format) {
    switch (format) {
      case ExportFormat.png:
        return 'png';
      case ExportFormat.svg:
        return 'svg';
      case ExportFormat.plantuml:
      case ExportFormat.c4plantuml:
        return 'puml';
      case ExportFormat.mermaid:
      case ExportFormat.c4mermaid:
        return 'mmd';
      case ExportFormat.dot:
        return 'dot';
      case ExportFormat.dsl:
        return 'dsl';
      case ExportFormat.c4json:
        return 'json';
      case ExportFormat.c4yaml:
        return 'yaml';
    }
  }

  /// Returns the MIME type for a given export format
  static String getMimeType(ExportFormat format) {
    switch (format) {
      case ExportFormat.png:
        return 'image/png';
      case ExportFormat.svg:
        return 'image/svg+xml';
      case ExportFormat.c4json:
        return 'application/json';
      case ExportFormat.c4yaml:
        return 'application/yaml';
      case ExportFormat.plantuml:
      case ExportFormat.c4plantuml:
      case ExportFormat.mermaid:
      case ExportFormat.c4mermaid:
      case ExportFormat.dot:
      case ExportFormat.dsl:
        return 'text/plain';
    }
  }
}
