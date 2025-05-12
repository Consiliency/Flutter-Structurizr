import 'package:flutter/widgets.dart' hide Element, Container, View;
import 'package:flutter_structurizr/domain/model/workspace.dart';

/// Common parameters for diagram rendering
class DiagramRenderParameters {
  /// The width of the export in pixels
  final double width;
  
  /// The height of the export in pixels
  final double height;
  
  /// Whether to include a diagram key/legend
  final bool includeLegend;
  
  /// Whether to include diagram title
  final bool includeTitle;
  
  /// Whether to include diagram metadata
  final bool includeMetadata;
  
  /// Custom scale factor for all elements
  final double elementScaleFactor;

  /// Creates a new set of diagram render parameters
  const DiagramRenderParameters({
    this.width = 1920,
    this.height = 1080,
    this.includeLegend = true,
    this.includeTitle = true,
    this.includeMetadata = true,
    this.elementScaleFactor = 1.0,
  });

  /// Creates a copy of this DiagramRenderParameters with the given fields replaced
  DiagramRenderParameters copyWith({
    double? width,
    double? height,
    bool? includeLegend,
    bool? includeTitle,
    bool? includeMetadata,
    double? elementScaleFactor,
  }) {
    return DiagramRenderParameters(
      width: width ?? this.width,
      height: height ?? this.height,
      includeLegend: includeLegend ?? this.includeLegend,
      includeTitle: includeTitle ?? this.includeTitle,
      includeMetadata: includeMetadata ?? this.includeMetadata,
      elementScaleFactor: elementScaleFactor ?? this.elementScaleFactor,
    );
  }
}

/// A diagram to export
class DiagramReference {
  /// The workspace containing the diagram
  final Workspace workspace;
  
  /// The key of the view to export
  final String viewKey;
  
  /// Optional title override for the diagram
  final String? title;

  /// Creates a new diagram reference
  const DiagramReference({
    required this.workspace,
    required this.viewKey,
    this.title,
  });
}

/// Base interface for all diagram exporters
abstract class DiagramExporter<T> {
  /// Exports a diagram to the format specified by the concrete exporter
  /// 
  /// [diagram] The diagram to export
  Future<T> export(DiagramReference diagram);
  
  /// Exports multiple diagrams, returning the results in an ordered list
  /// 
  /// [diagrams] The diagrams to export
  /// [onProgress] Optional callback for progress reporting (0.0 to 1.0)
  Future<List<T>> exportBatch(
    List<DiagramReference> diagrams, {
    ValueChanged<double>? onProgress,
  }) async {
    final results = <T>[];
    
    for (var i = 0; i < diagrams.length; i++) {
      // Call progress callback with approximate progress
      onProgress?.call(i / diagrams.length);
      
      // Export diagram and add to results
      final result = await export(diagrams[i]);
      results.add(result);
    }
    
    // Call progress callback with completion
    onProgress?.call(1.0);
    
    return results;
  }
}