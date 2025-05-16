import 'package:flutter/widgets.dart' hide Element, Container, View;
import 'package:flutter_structurizr/domain/model/workspace.dart';

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