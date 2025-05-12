import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Element, Container, View;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/infrastructure/export/diagram_exporter.dart';
import 'package:flutter_structurizr/infrastructure/export/rendering_pipeline.dart';
import 'package:flutter_structurizr/presentation/widgets/structurizr_diagram.dart';

/// An exporter for PNG format images of diagrams
class PngExporter implements DiagramExporter<Uint8List> {
  /// Render parameters for the diagram
  final DiagramRenderParameters? renderParameters;

  /// Whether to use a transparent background (true) or white (false)
  final bool transparentBackground;

  /// Scale factor to increase image resolution (e.g., 2.0 for 2x resolution)
  final double scaleFactor;

  /// Progress callback for the export operation
  final ValueChanged<double>? onProgress;

  /// Image quality for JPEG compression (0.0 to 1.0, only used for JPEG format)
  final double jpegQuality;

  /// Whether to use memory-efficient rendering (recommended for large diagrams)
  final bool useMemoryEfficientRendering;

  /// Creates a new PNG exporter
  const PngExporter({
    this.renderParameters,
    this.transparentBackground = false,
    this.scaleFactor = 2.0, // High quality by default
    this.jpegQuality = 0.9,
    this.onProgress,
    this.useMemoryEfficientRendering = true, // Enable by default
  });

  @override
  Future<Uint8List> export(DiagramReference diagram) async {
    try {
      // Use memory-efficient rendering pipeline for large diagrams
      if (useMemoryEfficientRendering) {
        return await _exportMemoryEfficient(diagram);
      } else {
        return await _exportStandard(diagram);
      }
    } catch (e) {
      throw Exception('Failed to export diagram to PNG: $e');
    }
  }

  /// Exports a diagram using the memory-efficient rendering pipeline
  Future<Uint8List> _exportMemoryEfficient(DiagramReference diagram) async {
    // Get render parameters
    final width = renderParameters?.width ?? 1920;
    final height = renderParameters?.height ?? 1080;
    final includeLegend = renderParameters?.includeLegend ?? true;
    final includeTitle = renderParameters?.includeTitle ?? true;
    final includeMetadata = renderParameters?.includeMetadata ?? true;

    // Render using the efficient pipeline
    final byteData = await RenderingPipeline.renderToBuffer(
      workspace: diagram.workspace,
      viewKey: diagram.viewKey,
      width: width * scaleFactor, // Apply scale factor
      height: height * scaleFactor,
      includeLegend: includeLegend,
      includeTitle: includeTitle,
      includeMetadata: includeMetadata,
      backgroundColor: Colors.white,
      transparentBackground: transparentBackground,
      onProgress: onProgress,
    );

    // Convert to PNG bytes
    final bytes = byteData.buffer.asUint8List();

    return bytes;
  }

  /// Exports a diagram using the standard rendering approach
  Future<Uint8List> _exportStandard(DiagramReference diagram) async {
    // Create a boundary key for the RepaintBoundary
    final boundaryKey = GlobalKey();

    // Report starting progress
    onProgress?.call(0.1);

    // Create a widget to render offscreen
    final offscreenWidget = MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: transparentBackground ? Colors.transparent : Colors.white,
        body: RepaintBoundary(
          key: boundaryKey,
          child: StructurizrDiagram(
            workspace: diagram.workspace,
            viewKey: diagram.viewKey,
            enablePanAndZoom: false, // Static rendering for export
            showControls: false, // Hide controls
            renderParameters: renderParameters,
          ),
        ),
      ),
    );

    // Render the widget to a virtual display
    final RenderRepaintBoundary boundary = await _renderOffscreen(
      offscreenWidget,
      boundaryKey,
    );

    // Report rendering progress
    onProgress?.call(0.5);

    // Capture image from the boundary
    final image = await boundary.toImage(pixelRatio: scaleFactor);
    final byteData = await image.toByteData(format: transparentBackground
        ? ui.ImageByteFormat.png
        : ui.ImageByteFormat.rawRgba);

    if (byteData == null) {
      throw Exception("Failed to export diagram: couldn't capture image data");
    }

    // Convert to appropriate format
    Uint8List bytes;
    if (transparentBackground) {
      // PNG format for transparency
      bytes = byteData.buffer.asUint8List();
    } else {
      // Convert RGBA to PNG
      final codec = await ui.instantiateImageCodec(
        byteData.buffer.asUint8List(),
        targetHeight: image.height,
        targetWidth: image.width,
      );
      final frameInfo = await codec.getNextFrame();
      final pngByteData = await frameInfo.image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (pngByteData == null) {
        throw Exception("Failed to convert image to PNG format");
      }
      bytes = pngByteData.buffer.asUint8List();
    }

    // Report completion
    onProgress?.call(1.0);

    return bytes;
  }

  /// Renders the widget offscreen to capture its image
  Future<RenderRepaintBoundary> _renderOffscreen(
    Widget widget,
    GlobalKey boundaryKey,
  ) async {
    // Create a test widget binding
    final binding = TestWidgetsFlutterBinding.ensureInitialized();

    // Define a reasonable size for the virtual screen
    final width = renderParameters?.width ?? 1920;
    final height = renderParameters?.height ?? 1080;
    binding.window.physicalSizeTestValue = Size(width, height);
    binding.window.devicePixelRatioTestValue = 1.0;

    // Pump the widget to render it
    final testWidget = binding.pipelineOwner.rootNode;
    binding.pipelineOwner.rootNode = widget as RenderObject;

    // Allow layout and animations to complete
    await binding.pump(const Duration(milliseconds: 20));
    await binding.pump(const Duration(milliseconds: 20));

    // Get the RenderObject from the boundary key
    final RenderRepaintBoundary boundary =
        boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    return boundary;
  }

  @override
  Future<List<Uint8List>> exportBatch(
    List<DiagramReference> diagrams, {
    ValueChanged<double>? onProgress,
  }) async {
    // If using memory-efficient rendering, use the optimized batch export
    if (useMemoryEfficientRendering) {
      return await _exportBatchMemoryEfficient(diagrams, onProgress: onProgress);
    }

    // Otherwise, use the standard approach
    final results = <Uint8List>[];

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

  /// Exports multiple diagrams using memory-efficient rendering
  Future<List<Uint8List>> _exportBatchMemoryEfficient(
    List<DiagramReference> diagrams, {
    ValueChanged<double>? onProgress,
  }) async {
    // Get common render parameters
    final width = renderParameters?.width ?? 1920;
    final height = renderParameters?.height ?? 1080;
    final includeLegend = renderParameters?.includeLegend ?? true;
    final includeTitle = renderParameters?.includeTitle ?? true;
    final includeMetadata = renderParameters?.includeMetadata ?? true;

    // Create list of diagram parameters
    final diagramParams = diagrams.map((diagram) => <String, dynamic>{
      'workspace': diagram.workspace,
      'viewKey': diagram.viewKey,
      'width': width * scaleFactor,
      'height': height * scaleFactor,
      'includeLegend': includeLegend,
      'includeTitle': includeTitle,
      'includeMetadata': includeMetadata,
      'backgroundColor': Colors.white,
      'transparentBackground': transparentBackground,
    }).toList();

    // Render each diagram sequentially to limit memory usage
    final results = <Uint8List>[];

    for (int i = 0; i < diagrams.length; i++) {
      // Calculate progress bounds for this diagram
      final progressStart = i / diagrams.length;
      final progressEnd = (i + 1) / diagrams.length;

      // Custom progress callback that maps to the overall progress
      final diagramProgress = (double progress) {
        final mappedProgress = progressStart + (progressEnd - progressStart) * progress;
        onProgress?.call(mappedProgress);
      };

      // Render the diagram
      final byteData = await RenderingPipeline.renderToBuffer(
        workspace: diagrams[i].workspace,
        viewKey: diagrams[i].viewKey,
        width: width * scaleFactor,
        height: height * scaleFactor,
        includeLegend: includeLegend,
        includeTitle: includeTitle,
        includeMetadata: includeMetadata,
        backgroundColor: Colors.white,
        transparentBackground: transparentBackground,
        onProgress: diagramProgress,
      );

      // Add to results
      results.add(byteData.buffer.asUint8List());
    }

    // Report completion
    onProgress?.call(1.0);

    return results;
  }
}