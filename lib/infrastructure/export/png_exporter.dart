import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart' hide Element, Container, View, Border;
import 'package:flutter_structurizr/infrastructure/export/diagram_exporter.dart'
    as diagram;
import 'package:flutter_structurizr/infrastructure/export/rendering_pipeline.dart';
import 'package:image/image.dart' as img;

/// An exporter for PNG format images of diagrams
class PngExporter implements diagram.DiagramExporter<Uint8List> {
  /// Render parameters for the diagram
  final DiagramRenderParameters renderParameters;

  /// Whether to use a transparent background (true) or white (false)
  final bool transparentBackground;

  /// Scale factor to increase image resolution (e.g., 2.0 for 2x resolution)
  final double scaleFactor;

  /// Progress callback for the export operation
  final ValueChanged<double>? onProgress;

  /// Whether to use memory-efficient rendering (recommended for large diagrams)
  final bool useMemoryEfficientRendering;

  /// Creates a new PNG exporter
  const PngExporter({
    required this.renderParameters,
    this.transparentBackground = false,
    this.scaleFactor = 2.0, // High quality by default
    this.onProgress,
    this.useMemoryEfficientRendering = true, // Enable by default
  });

  @override
  Future<Uint8List> export(diagram.DiagramReference diagram) async {
    try {
      // Always use the memory-efficient rendering pipeline now
      return await _exportWithRenderingPipeline(diagram);
    } catch (e) {
      throw Exception('Failed to export diagram to PNG: $e');
    }
  }

  /// Exports a diagram using the unified rendering pipeline
  Future<Uint8List> _exportWithRenderingPipeline(
      diagram.DiagramReference diagram) async {
    // Get render parameters with defaults
    final width = renderParameters.width ?? 1920;
    final height = renderParameters.height ?? 1080;
    final includeLegend = renderParameters.includeLegend ?? true;
    final includeTitle = renderParameters.includeTitle ?? true;
    final includeMetadata = renderParameters.includeMetadata ?? true;
    final includeElementNames = renderParameters.includeElementNames ?? true;
    final includeElementDescriptions =
        renderParameters.includeElementDescriptions ?? false;
    final includeRelationshipDescriptions =
        renderParameters.includeRelationshipDescriptions ?? true;
    final elementScaleFactor = renderParameters.elementScaleFactor ?? 1.0;

    // Render using the unified pipeline
    final byteData = await RenderingPipeline.renderToBuffer(
      workspace: diagram.workspace,
      viewKey: diagram.viewKey,
      width: width * scaleFactor, // Apply scale factor
      height: height * scaleFactor,
      includeLegend: includeLegend,
      includeTitle: includeTitle,
      includeMetadata: includeMetadata,
      backgroundColor:
          transparentBackground ? Colors.transparent : Colors.white,
      transparentBackground: transparentBackground,
      includeElementNames: includeElementNames,
      includeElementDescriptions: includeElementDescriptions,
      includeRelationshipDescriptions: includeRelationshipDescriptions,
      elementScaleFactor: elementScaleFactor,
      onProgress: onProgress,
    );

    // For PNG format, we need to properly encode the raw bytes
    if (transparentBackground) {
      // If transparent, we already have PNG format data
      return byteData.buffer.asUint8List();
    } else {
      // For non-transparent, convert RGBA to PNG using image library
      return _convertRgbaToEncodedPng(
          byteData, width * scaleFactor, height * scaleFactor);
    }
  }

  /// Converts raw RGBA data to properly encoded PNG
  Uint8List _convertRgbaToEncodedPng(
      ByteData rgbaData, double width, double height) {
    final widthInt = width.toInt();
    final heightInt = height.toInt();

    // Create an image from the RGBA data
    final image = img.Image(width: widthInt, height: heightInt);
    final rgbaBytes = rgbaData.buffer.asUint8List();

    // Copy pixel data
    for (int y = 0; y < heightInt; y++) {
      for (int x = 0; x < widthInt; x++) {
        final pixelIndex = (y * widthInt + x) * 4;

        if (pixelIndex + 3 < rgbaBytes.length) {
          final red = rgbaBytes[pixelIndex];
          final green = rgbaBytes[pixelIndex + 1];
          final blue = rgbaBytes[pixelIndex + 2];
          final alpha = rgbaBytes[pixelIndex + 3];

          // Set the pixel in the image
          image.setPixel(x, y, img.ColorRgba8(red, green, blue, alpha));
        }
      }
    }

    // Encode as PNG
    final pngBytes = img.encodePng(image);
    return pngBytes;
  }

  @override
  Future<List<Uint8List>> exportBatch(
    List<diagram.DiagramReference> diagrams, {
    ValueChanged<double>? onProgress,
  }) async {
    // Get common render parameters
    final width = renderParameters.width ?? 1920;
    final height = renderParameters.height ?? 1080;
    final includeLegend = renderParameters.includeLegend ?? true;
    final includeTitle = renderParameters.includeTitle ?? true;
    final includeMetadata = renderParameters.includeMetadata ?? true;
    final includeElementNames = renderParameters.includeElementNames ?? true;
    final includeElementDescriptions =
        renderParameters.includeElementDescriptions ?? false;
    final includeRelationshipDescriptions =
        renderParameters.includeRelationshipDescriptions ?? true;
    final elementScaleFactor = renderParameters.elementScaleFactor ?? 1.0;

    // Create list of diagram parameters for batch processing
    final diagramParams = diagrams
        .map((diagram) => <String, dynamic>{
              'workspace': diagram.workspace,
              'viewKey': diagram.viewKey,
              'width': width * scaleFactor,
              'height': height * scaleFactor,
              'includeLegend': includeLegend,
              'includeTitle': includeTitle,
              'includeMetadata': includeMetadata,
              'includeElementNames': includeElementNames,
              'includeElementDescriptions': includeElementDescriptions,
              'includeRelationshipDescriptions':
                  includeRelationshipDescriptions,
              'elementScaleFactor': elementScaleFactor,
              'backgroundColor': Colors.white,
              'transparentBackground': transparentBackground,
            })
        .toList();

    // Process each diagram one by one to avoid memory issues
    final results = <Uint8List>[];

    for (int i = 0; i < diagrams.length; i++) {
      // Calculate progress bounds for this diagram
      final progressStart = i / diagrams.length;
      final progressEnd = (i + 1) / diagrams.length;

      // Custom progress callback that maps to the overall progress
      final diagramProgress = (double progress) {
        final mappedProgress =
            progressStart + (progressEnd - progressStart) * progress;
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
        backgroundColor:
            transparentBackground ? Colors.transparent : Colors.white,
        transparentBackground: transparentBackground,
        includeElementNames: includeElementNames,
        includeElementDescriptions: includeElementDescriptions,
        includeRelationshipDescriptions: includeRelationshipDescriptions,
        elementScaleFactor: elementScaleFactor,
        onProgress: diagramProgress,
      );

      // Convert to properly encoded PNG
      Uint8List pngBytes;
      if (transparentBackground) {
        // If transparent, we already have PNG format data
        pngBytes = byteData.buffer.asUint8List();
      } else {
        // For non-transparent, convert RGBA to PNG using image library
        pngBytes = _convertRgbaToEncodedPng(
            byteData, width * scaleFactor, height * scaleFactor);
      }

      // Add to results
      results.add(pngBytes);
    }

    // Report completion
    onProgress?.call(1.0);

    return results;
  }
}
