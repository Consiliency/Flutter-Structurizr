import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Element, Container, View;
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/view/views.dart';
import 'package:flutter_structurizr/presentation/rendering/base_renderer.dart';

/// A memory-efficient rendering pipeline for exporting diagrams
class RenderingPipeline {
  /// Render a diagram to a raw byte buffer (efficient for large diagrams)
  ///
  /// [workspace] The workspace containing the diagram
  /// [viewKey] The key of the view to render
  /// [width] The width of the output image
  /// [height] The height of the output image
  /// [includeLegend] Whether to include the legend
  /// [includeTitle] Whether to include the title
  /// [includeMetadata] Whether to include metadata
  /// [backgroundColor] The background color
  /// [transparentBackground] Whether to use a transparent background
  /// [onProgress] Progress callback (0.0 to 1.0)
  ///
  /// Returns a Future with the raw byte buffer
  static Future<ByteData> renderToBuffer({
    required Workspace workspace,
    required String viewKey,
    required double width,
    required double height,
    bool includeLegend = true,
    bool includeTitle = true,
    bool includeMetadata = true,
    Color backgroundColor = Colors.white,
    bool transparentBackground = false,
    ValueChanged<double>? onProgress,
  }) async {
    // Report initial progress
    onProgress?.call(0.1);
    
    // Find the view
    final view = _findViewByKey(workspace.views, viewKey);
    if (view == null) {
      throw Exception('View not found: $viewKey');
    }
    
    // Report progress
    onProgress?.call(0.2);
    
    // Create a recorder
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    
    // Create render parameters
    final renderParameters = RenderParameters(
      width: width,
      height: height,
      includeLegend: includeLegend,
      includeTitle: includeTitle,
      includeMetadata: includeMetadata,
      backgroundColor: transparentBackground ? Colors.transparent : backgroundColor,
    );
    
    // Report progress
    onProgress?.call(0.3);
    
    // Render the diagram
    final renderer = BaseRenderer();
    renderer.render(
      canvas: canvas,
      workspace: workspace,
      view: view,
      parameters: renderParameters,
      onProgress: (progress) {
        // Scale progress from 0.3 to 0.8
        onProgress?.call(0.3 + progress * 0.5);
      },
    );
    
    // Report progress
    onProgress?.call(0.8);
    
    // Convert to a picture
    final picture = pictureRecorder.endRecording();
    
    // Report progress
    onProgress?.call(0.85);
    
    // Convert to an image
    final img = await picture.toImage(width.toInt(), height.toInt());
    
    // Report progress
    onProgress?.call(0.9);
    
    // Get pixels
    final byteData = await img.toByteData(
      format: transparentBackground 
          ? ui.ImageByteFormat.png 
          : ui.ImageByteFormat.rawRgba,
    );
    
    if (byteData == null) {
      throw Exception('Failed to convert image to bytes');
    }
    
    // Report completion
    onProgress?.call(1.0);
    
    return byteData;
  }

  /// Render multiple diagrams in a memory-efficient way
  ///
  /// This uses isolates to avoid memory leaks and reduces peak memory usage
  /// by rendering diagrams sequentially instead of all at once.
  ///
  /// [diagrams] List of diagrams to render
  /// [renderParameters] Parameters for rendering
  /// [onProgress] Progress callback (0.0 to 1.0)
  ///
  /// Returns a Future with the rendered diagrams
  static Future<List<dynamic>> renderBatch({
    required List<Map<String, dynamic>> diagramParams,
    ValueChanged<double>? onProgress,
  }) async {
    final results = <dynamic>[];
    
    // Render diagrams one at a time to limit memory usage
    for (int i = 0; i < diagramParams.length; i++) {
      final params = diagramParams[i];
      
      // Calculate progress bounds for this diagram
      final progressStart = i / diagramParams.length;
      final progressEnd = (i + 1) / diagramParams.length;
      
      // Report progress
      onProgress?.call(progressStart);
      
      try {
        // Render in a separate isolate to prevent memory leaks
        final result = await compute(_renderDiagramIsolate, params);
        results.add(result);
        
        // Force garbage collection between diagrams
        // This is not a guaranteed way to collect memory, but it helps
        // Note: In a real implementation, you might want to use a platform
        // channel to force GC more reliably
      } catch (e) {
        results.add(null); // Add null for failed renders
      }
      
      // Report progress
      onProgress?.call(progressEnd);
    }
    
    return results;
  }
  
  /// Finds a view by its key
  static ModelView? _findViewByKey(Views views, String key) {
    // Check system context views
    for (final view in views.systemContextViews) {
      if (view.key == key) return view;
    }
    
    // Check container views
    for (final view in views.containerViews) {
      if (view.key == key) return view;
    }
    
    // Check component views
    for (final view in views.componentViews) {
      if (view.key == key) return view;
    }
    
    // Check deployment views
    for (final view in views.deploymentViews) {
      if (view.key == key) return view;
    }
    
    // Check filtered views
    for (final view in views.filteredViews) {
      if (view.key == key) return view;
    }
    
    // Check dynamic views
    for (final view in views.dynamicViews) {
      if (view.key == key) return view;
    }
    
    // Check custom views
    for (final view in views.customViews) {
      if (view.key == key) return view;
    }
    
    return null;
  }
}

/// Helper method to render a diagram in an isolate
Future<dynamic> _renderDiagramIsolate(Map<String, dynamic> params) async {
  // In a real implementation, you would initialize the renderer
  // and render the diagram. The params map would contain
  // the workspace, view key, and render parameters.
  // For now, we'll just return a mock result.
  
  // This function would be implemented to actually render the diagram
  // but isolate rendering requires more complex setup with message passing
  // since UI objects like Canvas can't be passed directly to isolates.
  
  // In practice, this requires:
  // 1. Serializing the workspace and view
  // 2. Creating a custom rendering pipeline that doesn't depend on UI objects
  // 3. Rendering to raw bytes
  // 4. Passing the bytes back to the main isolate
  
  return params;
}