import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_structurizr/infrastructure/export/diagram_exporter.dart';
import 'package:flutter_structurizr/infrastructure/export/export_manager.dart';
import 'package:flutter_structurizr/infrastructure/export/mermaid_exporter.dart';
import 'package:flutter_structurizr/infrastructure/export/plantuml_exporter.dart';
import 'package:flutter_structurizr/infrastructure/export/png_exporter.dart';
import 'package:flutter_structurizr/infrastructure/export/svg_exporter.dart';
import 'package:flutter_structurizr/infrastructure/export/dot_exporter.dart';
import 'package:flutter_structurizr/infrastructure/export/dsl_exporter.dart';

/// A mock export manager for testing
class MockExportManager extends ExportManager {
  /// Future to complete when export is called
  final Completer<dynamic> _exportCompleter = Completer();
  
  /// Options passed in last export call
  ExportOptions? lastExportOptions;
  
  /// Log of progress updates received
  List<double> progressUpdates = [];
  
  /// Whether to simulate an error during export
  final bool simulateError;
  
  /// Number of milliseconds to delay the export
  final int delayMilliseconds;
  
  /// Creates a new mock export manager
  MockExportManager({
    this.simulateError = false,
    this.delayMilliseconds = 100,
  });
  
  @override
  Future<dynamic> exportDiagram({
    required Workspace workspace,
    required String viewKey,
    required ExportOptions options,
    String? title,
  }) async {
    lastExportOptions = options;
    
    // Call progress handler if provided
    if (options.onProgress != null) {
      for (var i = 0; i <= 10; i++) {
        final progress = i / 10.0;
        options.onProgress!(progress);
        progressUpdates.add(progress);
        await Future.delayed(Duration(milliseconds: delayMilliseconds ~/ 10));
      }
    }
    
    // Simulate delay
    await Future.delayed(Duration(milliseconds: delayMilliseconds));
    
    // Simulate error if requested
    if (simulateError) {
      throw Exception('Simulated export error');
    }
    
    // Return result based on format
    switch (options.format) {
      case ExportFormat.png:
        return Uint8List.fromList(List.generate(100, (i) => i % 256));
      case ExportFormat.svg:
        return _generateMockSvg();
      case ExportFormat.plantuml:
      case ExportFormat.c4plantuml:
        return '@startuml\ntitle Mock PlantUML Diagram\nactor User\nUser -> System: Request\n@enduml';
      case ExportFormat.mermaid:
      case ExportFormat.c4mermaid:
        return 'graph TD\n  A[Client] -->|Request| B[System]\n  B -->|Response| A';
      case ExportFormat.dot:
        return 'digraph G {\n  "Client" -> "System";\n}';
      case ExportFormat.dsl:
        return 'workspace "Test" {\n  model {\n    user = person "User"\n    system = softwareSystem "System"\n  }\n}';
      default:
        return 'Mock export result';
    }
  }
  
  /// Generates a mock SVG string
  String _generateMockSvg() {
    return '''
<svg width="400" height="300" xmlns="http://www.w3.org/2000/svg">
  <rect x="50" y="50" width="300" height="200" fill="white" stroke="black" />
  <circle cx="200" cy="150" r="50" fill="blue" />
  <text x="200" y="150" text-anchor="middle" fill="white">System</text>
  <rect x="70" y="70" width="100" height="60" fill="green" />
  <text x="120" y="100" text-anchor="middle" fill="white">Component A</text>
  <rect x="230" y="70" width="100" height="60" fill="red" />
  <text x="280" y="100" text-anchor="middle" fill="white">Component B</text>
  <line x1="120" y1="130" x2="200" y2="150" stroke="black" />
  <line x1="280" y1="130" x2="200" y2="150" stroke="black" />
  <text x="150" y="140" text-anchor="middle" font-size="10">Uses</text>
  <text x="250" y="140" text-anchor="middle" font-size="10">Uses</text>
</svg>
''';
  }
}

/// A mock PNG exporter for testing
class MockPngExporter extends PngExporter {
  /// Whether to simulate an error during export
  final bool simulateError;
  
  /// Creates a new mock PNG exporter
  MockPngExporter({
    super.renderParameters,
    super.transparentBackground,
    super.scaleFactor,
    super.onProgress,
    this.simulateError = false,
  });
  
  @override
  Future<Uint8List> export(DiagramReference diagramRef) async {
    // Call progress handler if provided
    if (onProgress != null) {
      for (var i = 0; i <= 10; i++) {
        onProgress!(i / 10.0);
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }
    
    // Simulate delay
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Simulate error if requested
    if (simulateError) {
      throw Exception('Simulated PNG export error');
    }
    
    // Return mock PNG data
    return Uint8List.fromList(List.generate(100, (i) => i % 256));
  }
}

/// A mock SVG exporter for testing
class MockSvgExporter extends SvgExporter {
  /// Whether to simulate an error during export
  final bool simulateError;
  
  /// Creates a new mock SVG exporter
  MockSvgExporter({
    super.renderParameters,
    super.includeCss,
    super.interactive,
    super.onProgress,
    this.simulateError = false,
  });
  
  @override
  Future<String> export(DiagramReference diagramRef) async {
    // Call progress handler if provided
    if (onProgress != null) {
      for (var i = 0; i <= 10; i++) {
        onProgress!(i / 10.0);
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }
    
    // Simulate delay
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Simulate error if requested
    if (simulateError) {
      throw Exception('Simulated SVG export error');
    }
    
    // Return mock SVG data
    return '''
<svg width="400" height="300" xmlns="http://www.w3.org/2000/svg">
  <rect x="50" y="50" width="300" height="200" fill="white" stroke="black" />
  <circle cx="200" cy="150" r="50" fill="blue" />
  <text x="200" y="150" text-anchor="middle" fill="white">System</text>
  <rect x="70" y="70" width="100" height="60" fill="green" />
  <text x="120" y="100" text-anchor="middle" fill="white">Component A</text>
  <rect x="230" y="70" width="100" height="60" fill="red" />
  <text x="280" y="100" text-anchor="middle" fill="white">Component B</text>
  <line x1="120" y1="130" x2="200" y2="150" stroke="black" />
  <line x1="280" y1="130" x2="200" y2="150" stroke="black" />
  <text x="150" y="140" text-anchor="middle" font-size="10">Uses</text>
  <text x="250" y="140" text-anchor="middle" font-size="10">Uses</text>
</svg>
''';
  }
}

/// A mock completer for testing async operations
class Completer<T> {
  /// The future to complete
  final Future<T> future;
  
  /// Creates a new completer
  Completer() : future = Future<T>.value(null as T);
  
  /// Completes the future with the given value
  void complete([T? value]) { }
  
  /// Completes the future with the given error
  void completeError(Object error, [StackTrace? stackTrace]) { }
}

/// A mock workspace class for testing
class Workspace {
  /// The workspace name
  final String name;
  
  /// The workspace description
  final String? description;
  
  /// The workspace views
  final WorkspaceViews? views;
  
  /// Creates a new workspace
  const Workspace({
    required this.name,
    this.description,
    this.views,
  });
}

/// A mock workspace views class for testing
class WorkspaceViews {
  /// System landscape views
  final List<ModelView> systemLandscapeViews;
  
  /// System context views
  final List<ModelView> systemContextViews;
  
  /// Container views
  final List<ModelView> containerViews;
  
  /// Component views
  final List<ModelView> componentViews;
  
  /// Deployment views
  final List<ModelView> deploymentViews;
  
  /// Dynamic views
  final List<ModelView> dynamicViews;
  
  /// Filtered views
  final List<ModelView> filteredViews;
  
  /// Creates new workspace views
  const WorkspaceViews({
    this.systemLandscapeViews = const [],
    this.systemContextViews = const [],
    this.containerViews = const [],
    this.componentViews = const [],
    this.deploymentViews = const [],
    this.dynamicViews = const [],
    this.filteredViews = const [],
  });
}

/// A mock model view class for testing
class ModelView {
  /// The view key
  final String key;
  
  /// The view title
  final String? title;
  
  /// Creates a new model view
  const ModelView({
    required this.key,
    this.title,
  });
}

/// Mock diagram reference
class DiagramReference {
  /// The workspace
  final Workspace workspace;
  
  /// The view key
  final String viewKey;
  
  /// Creates a new diagram reference
  const DiagramReference({
    required this.workspace,
    required this.viewKey,
  });
}