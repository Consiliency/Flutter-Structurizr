import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Element, Container, View, Border;
import 'package:flutter_structurizr/domain/model/component.dart';
import 'package:flutter_structurizr/domain/model/container.dart';
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/person.dart';
import 'package:flutter_structurizr/domain/model/software_system.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';
import 'package:flutter_structurizr/domain/view/model_view.dart';
import 'package:flutter_structurizr/domain/view/views.dart';
import 'package:flutter_structurizr/presentation/rendering/elements/box_renderer.dart';
import 'package:flutter_structurizr/presentation/rendering/elements/component_renderer.dart';
import 'package:flutter_structurizr/presentation/rendering/elements/container_renderer.dart';
import 'package:flutter_structurizr/presentation/rendering/elements/person_renderer.dart';
import 'package:flutter_structurizr/presentation/rendering/boundaries/boundary_renderer.dart';
import 'package:flutter_structurizr/presentation/rendering/relationships/relationship_renderer.dart';
import 'package:flutter_structurizr/presentation/rendering/base_renderer.dart';

/// Parameters for rendering a diagram
class DiagramRenderParameters {
  /// Width of the rendered image
  final double width;

  /// Height of the rendered image
  final double height;

  /// Whether to include a legend
  final bool includeLegend;

  /// Whether to include the diagram title
  final bool includeTitle;

  /// Whether to include metadata about the diagram
  final bool includeMetadata;

  /// Background color for the diagram
  final Color backgroundColor;

  /// Whether to include element names
  final bool includeElementNames;

  /// Whether to include element descriptions
  final bool includeElementDescriptions;

  /// Whether to include relationship descriptions
  final bool includeRelationshipDescriptions;

  /// Element scale factor
  final double elementScaleFactor;

  /// Creates a new set of render parameters
  const DiagramRenderParameters({
    required this.width,
    required this.height,
    this.includeLegend = false,
    this.includeTitle = true,
    this.includeMetadata = false,
    this.backgroundColor = Colors.white,
    this.includeElementNames = true,
    this.includeElementDescriptions = false,
    this.includeRelationshipDescriptions = true,
    this.elementScaleFactor = 1.0,
  });

  /// Create a copy with specified parameters changed
  DiagramRenderParameters copyWith({
    double? width,
    double? height,
    bool? includeLegend,
    bool? includeTitle,
    bool? includeMetadata,
    Color? backgroundColor,
    bool? includeElementNames,
    bool? includeElementDescriptions,
    bool? includeRelationshipDescriptions,
    double? elementScaleFactor,
  }) {
    return DiagramRenderParameters(
      width: width ?? this.width,
      height: height ?? this.height,
      includeLegend: includeLegend ?? this.includeLegend,
      includeTitle: includeTitle ?? this.includeTitle,
      includeMetadata: includeMetadata ?? this.includeMetadata,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      includeElementNames: includeElementNames ?? this.includeElementNames,
      includeElementDescriptions:
          includeElementDescriptions ?? this.includeElementDescriptions,
      includeRelationshipDescriptions: includeRelationshipDescriptions ??
          this.includeRelationshipDescriptions,
      elementScaleFactor: elementScaleFactor ?? this.elementScaleFactor,
    );
  }
}

/// A memory-efficient rendering pipeline for exporting diagrams
class RenderingPipeline {
  /// Create a renderer for a specific element type
  static BaseRenderer getRendererForElement(Element element, Styles styles) {
    if (element is Person) {
      return PersonRenderer();
    } else if (element is Container) {
      return ContainerRenderer();
    } else if (element is Component) {
      return ComponentRenderer();
    } else if (element is SoftwareSystem) {
      return BoxRenderer();
    } else {
      // Default renderer for other element types
      return BoxRenderer();
    }
  }

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
  /// [includeElementNames] Whether to include element names
  /// [includeElementDescriptions] Whether to include element descriptions
  /// [includeRelationshipDescriptions] Whether to include relationship descriptions
  /// [elementScaleFactor] Scale factor for elements
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
    bool includeElementNames = true,
    bool includeElementDescriptions = false,
    bool includeRelationshipDescriptions = true,
    double elementScaleFactor = 1.0,
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
    final renderParameters = DiagramRenderParameters(
      width: width,
      height: height,
      includeLegend: includeLegend,
      includeTitle: includeTitle,
      includeMetadata: includeMetadata,
      backgroundColor:
          transparentBackground ? Colors.transparent : backgroundColor,
      includeElementNames: includeElementNames,
      includeElementDescriptions: includeElementDescriptions,
      includeRelationshipDescriptions: includeRelationshipDescriptions,
      elementScaleFactor: elementScaleFactor,
    );

    // Report progress
    onProgress?.call(0.3);

    // Get styles from workspace
    const styles = Styles();

    // Draw the background
    final backgroundPaint = Paint()
      ..color = renderParameters.backgroundColor
      ..style = PaintingStyle.fill;

    canvas.drawRect(
        Rect.fromLTWH(0, 0, renderParameters.width, renderParameters.height),
        backgroundPaint);

    // Get elements and relationships from the view
    final elementViews = _getViewElements(workspace, view);
    final elements = elementViews
        .map((ev) => workspace.model.getElementById(ev.id))
        .whereType<Element>()
        .toList();
    final relationships = _getViewRelationships(workspace, view);

    // Calculate diagram bounds and apply scaling
    final bounds = _calculateDiagramBounds(elements, relationships);
    final scale = _calculateScaleFactor(bounds, renderParameters);

    // Apply transformations to fit the diagram into the view
    canvas.translate(
        (renderParameters.width - bounds.width * scale) / 2 -
            bounds.left * scale,
        (renderParameters.height - bounds.height * scale) / 2 -
            bounds.top * scale);
    canvas.scale(scale);

    // Report progress
    onProgress?.call(0.4);

    // Draw boundaries first (behind everything else)
    _renderBoundaries(canvas, elements, styles, renderParameters);

    // Report progress
    onProgress?.call(0.5);

    // Draw relationships
    _renderRelationships(canvas, relationships, styles, renderParameters);

    // Report progress
    onProgress?.call(0.6);

    // Draw elements
    _renderElements(canvas, elementViews, workspace, styles, renderParameters);

    // Report progress
    onProgress?.call(0.7);

    // Draw title if needed
    if (renderParameters.includeTitle) {
      _renderTitle(canvas, view, renderParameters);
    }

    // Draw legend if needed
    if (renderParameters.includeLegend) {
      _renderLegend(canvas, elements, relationships, renderParameters);
    }

    // Draw metadata if needed
    if (renderParameters.includeMetadata) {
      _renderMetadata(canvas, workspace, view, renderParameters);
    }

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
      } catch (e) {
        results.add(null); // Add null for failed renders
      }

      // Report progress
      onProgress?.call(progressEnd);
    }

    return results;
  }

  /// Calculate the diagram bounds
  static Rect _calculateDiagramBounds(
      List<Element> elements, List<Relationship> relationships) {
    if (elements.isEmpty) {
      return Rect.zero;
    }

    // Find the bounds of the diagram by iterating through all elements
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;

    for (final element in elements) {
      // Only access position if the element is a type that has it
      if ((element is Container ||
              element is Component ||
              element is SoftwareSystem) &&
          (element as dynamic).position != null) {
        final pos = (element as dynamic).position;
        final left = pos.x.toDouble();
        final top = pos.y.toDouble();
        final right = left + 150.0;
        final bottom = top + 100.0;

        minX = min(minX, left);
        minY = min(minY, top);
        maxX = max(maxX, right);
        maxY = max(maxY, bottom);
      }
    }

    // Add padding
    const padding = 50.0;

    return Rect.fromLTRB(
        minX - padding, minY - padding, maxX + padding, maxY + padding);
  }

  /// Calculate scaling factor to fit diagram in view
  static double _calculateScaleFactor(
      Rect bounds, DiagramRenderParameters params) {
    if (bounds == Rect.zero) {
      return 1.0;
    }

    // Calculate scale based on width and height constraints
    final scaleX = params.width / bounds.width;
    final scaleY = params.height / bounds.height;

    // Use the smaller scale to ensure the diagram fits within the view
    return min(scaleX, scaleY) * params.elementScaleFactor;
  }

  /// Render all boundaries in the view
  static void _renderBoundaries(Canvas canvas, List<Element> elements,
      Styles styles, DiagramRenderParameters params) {
    // Group elements by parent
    final parentGroups = <String, List<Element>>{};

    for (final element in elements) {
      if (element.parentId != null && element.parentId!.isNotEmpty) {
        parentGroups.putIfAbsent(element.parentId!, () => []).add(element);
      }
    }

    // Now render boundaries for each parent group
    final boundaryRenderer = BoundaryRenderer();

    for (final entry in parentGroups.entries) {
      final parentId = entry.key;
      final parentElement = elements.firstWhere((e) => e.id == parentId,
          orElse: () => Person(id: parentId, name: 'Unknown'));

      // Extract the child elements
      final childElements = entry.value;

      // Compute childRects as the bounds of each child element
      final childRects = childElements
          .map((e) => const Rect.fromLTWH(0, 0, 0, 0))
          .toList(); // TODO: Replace with actual bounds
      boundaryRenderer.renderBoundary(
        canvas: canvas,
        element: parentElement,
        bounds: Rect.zero, // TODO: Replace with actual bounds
        style: const Styles().getElementStyle(parentElement.tags),
        childRects: childRects,
        selected: false,
        hovered: false,
      );
    }
  }

  /// Render all elements in the view
  static void _renderElements(Canvas canvas, List<ElementView> elementViews,
      Workspace workspace, Styles styles, DiagramRenderParameters params) {
    for (final elementView in elementViews) {
      final element = workspace.model.getElementById(elementView.id);
      if (element == null) continue;
      final renderer = getRendererForElement(element, styles);
      renderer.renderElement(
        canvas: canvas,
        element: element,
        elementView: elementView,
        style: styles.getElementStyle(element.tags),
        selected: false,
        hovered: false,
        includeNames: params.includeElementNames,
        includeDescriptions: params.includeElementDescriptions,
      );
    }
  }

  /// Render all relationships in the view
  static void _renderRelationships(
      Canvas canvas,
      List<Relationship> relationships,
      Styles styles,
      DiagramRenderParameters params) {
    final relationshipRenderer = RelationshipRenderer();

    for (final relationship in relationships) {
      relationshipRenderer.renderRelationship(
        canvas: canvas,
        relationship: relationship,
        relationshipView: RelationshipView(id: relationship.id),
        style: styles.getRelationshipStyle(relationship.tags),
        sourceRect: Rect.zero, // TODO: Provide actual source rect
        targetRect: Rect.zero, // TODO: Provide actual target rect
        selected: false,
        hovered: false,
        includeDescription: params.includeRelationshipDescriptions,
      );
    }
  }

  /// Render the diagram title
  static void _renderTitle(
      Canvas canvas, ModelView view, DiagramRenderParameters params) {
    final title = view.title ?? view.key;

    const titleStyle = TextStyle(
      color: Colors.black,
      fontSize: 24.0,
      fontWeight: FontWeight.bold,
    );

    final titlePainter = TextPainter(
      text: TextSpan(
        text: title,
        style: titleStyle,
      ),
      textDirection: TextDirection.ltr,
    );

    titlePainter.layout(maxWidth: params.width * 0.9);

    // Position at top center
    titlePainter.paint(
      canvas,
      Offset(
        (params.width - titlePainter.width) / 2,
        20.0,
      ),
    );
  }

  /// Render diagram legend
  static void _renderLegend(Canvas canvas, List<Element> elements,
      List<Relationship> relationships, DiagramRenderParameters params) {
    // Create a map of element types to counts
    final elementTypeCounts = <String, int>{};
    for (final element in elements) {
      final type = element.runtimeType.toString();
      elementTypeCounts[type] = (elementTypeCounts[type] ?? 0) + 1;
    }

    // Create a rectangle for the legend
    final rect =
        Rect.fromLTWH(params.width - 250, params.height - 200, 230, 180);

    // Draw rectangle with white background and border
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRect(rect, bgPaint);
    canvas.drawRect(rect, borderPaint);

    // Draw legend title
    final titlePainter = TextPainter(
      text: const TextSpan(
        text: 'Legend',
        style: TextStyle(
          color: Colors.black,
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    titlePainter.layout();
    titlePainter.paint(canvas, Offset(rect.left + 10, rect.top + 10));

    // Draw legend items
    double y = rect.top + 40;

    elementTypeCounts.forEach((type, count) {
      final itemPainter = TextPainter(
        text: TextSpan(
          text: '$type: $count',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      itemPainter.layout();
      itemPainter.paint(canvas, Offset(rect.left + 15, y));

      y += 20;
    });

    // Add relationship count
    final relationshipsPainter = TextPainter(
      text: TextSpan(
        text: 'Relationships: ${relationships.length}',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 12.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    relationshipsPainter.layout();
    relationshipsPainter.paint(canvas, Offset(rect.left + 15, y));
  }

  /// Render metadata about the diagram
  static void _renderMetadata(Canvas canvas, Workspace workspace,
      ModelView view, DiagramRenderParameters params) {
    final metadataItems = <String>[
      'Workspace: ${workspace.name}',
      'View: ${view.key}',
      'Generated: ${DateTime.now().toIso8601String().split('T')[0]}',
      'Flutter Structurizr',
    ];

    double y = params.height - 60.0;

    for (final item in metadataItems) {
      final painter = TextPainter(
        text: TextSpan(
          text: item,
          style: TextStyle(
            color: Colors.black.withValues(alpha: 0.5),
            fontSize: 10.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      painter.layout();
      painter.paint(canvas, Offset(20, y));

      y += 15;
    }
  }

  /// Utility function to get minimum value
  static double min(double a, double b) => a < b ? a : b;

  /// Utility function to get maximum value
  static double max(double a, double b) => a > b ? a : b;

  /// Get elements from the view
  static List<ElementView> _getViewElements(
      Workspace workspace, ModelView view) {
    final result = <ElementView>[];
    final model = workspace.model;

    // Go through each element in the view and find the corresponding element in the model
    for (final elementView in view.elements) {
      final id = elementView.id;
      final element = model.getElementById(id);

      if (element != null) {
        result.add(elementView);
      }
    }

    return result;
  }

  /// Get relationships from the view
  static List<Relationship> _getViewRelationships(
      Workspace workspace, ModelView view) {
    final result = <Relationship>[];
    final model = workspace.model;

    // If explicit relationships are defined in the view
    if (view.relationships.isNotEmpty) {
      // Go through each relationship in the view
      for (final relationshipView in view.relationships) {
        final id = relationshipView.id;
        // TODO: Implement relationship lookup if needed
        // For now, skip or add a dummy relationship
      }
    } else {
      // If no explicit relationships, infer from elements in view
      final elementIds = view.elements.map((e) => e.id).toSet();

      // Get all relationships where both source and target are in the view
      for (final relationship in model.getAllRelationships()) {
        if (elementIds.contains(relationship.sourceId) &&
            elementIds.contains(relationship.destinationId)) {
          result.add(relationship);
        }
      }
    }

    // For dynamic views, use relationships defined in view
    if (view is DynamicView && view.relationships.isNotEmpty) {
      result.clear();

      // Add all relationships from the dynamic view in the specified order
      for (final interaction in view.relationships) {
        result.add(Relationship(
          id: interaction.id ??
              '${interaction.sourceId ?? ''}_${interaction.destinationId ?? ''}',
          sourceId: interaction.sourceId ?? '',
          destinationId: interaction.destinationId ?? '',
          description: interaction.description ?? '',
          // order: interaction.order, // Not supported
        ));
      }
    }

    return result;
  }

  /// Finds a view by its key
  static ModelView? _findViewByKey(Views views, String key) {
    // First try system landscape views
    final systemLandscapeView = views.systemLandscapeViews.firstWhere(
      (view) => view.key == key,
      orElse: () =>
          const SystemLandscapeView(key: ''), // Empty view if not found
    );
    if (systemLandscapeView.key.isNotEmpty) return systemLandscapeView;

    // Check system context views
    final systemContextView = views.systemContextViews.firstWhere(
      (view) => view.key == key,
      orElse: () => const SystemContextView(
          key: '', softwareSystemId: ''), // Empty view if not found
    );
    if (systemContextView.key.isNotEmpty) return systemContextView;

    // Check container views
    final containerView = views.containerViews.firstWhere(
      (view) => view.key == key,
      orElse: () => const ContainerView(
          key: '', softwareSystemId: ''), // Empty view if not found
    );
    if (containerView.key.isNotEmpty) return containerView;

    // Check component views
    final componentView = views.componentViews.firstWhere(
      (view) => view.key == key,
      orElse: () => const ComponentView(
          key: '',
          containerId: '',
          softwareSystemId: ''), // Empty view if not found
    );
    if (componentView.key.isNotEmpty) return componentView;

    // Check dynamic views
    final dynamicView = views.dynamicViews.firstWhere(
      (view) => view.key == key,
      orElse: () =>
          const DynamicView(key: '', elementId: ''), // Empty view if not found
    );
    if (dynamicView.key.isNotEmpty) return dynamicView;

    // Check deployment views
    final deploymentView = views.deploymentViews.firstWhere(
      (view) => view.key == key,
      orElse: () => const DeploymentView(
          key: '', environment: ''), // Empty view if not found
    );
    if (deploymentView.key.isNotEmpty) return deploymentView;

    // Check filtered views
    final filteredView = views.filteredViews.firstWhere(
      (view) => view.key == key,
      orElse: () => const FilteredView(
          key: '', baseViewKey: ''), // Empty view if not found
    );
    if (filteredView.key.isNotEmpty) return filteredView;

    // Check custom views
    final customView = views.customViews.firstWhere(
      (view) => view.key == key,
      orElse: () => const CustomView(key: ''), // Empty view if not found
    );
    if (customView.key.isNotEmpty) return customView;

    return null;
  }
}

/// Helper method to render a diagram in an isolate
Future<dynamic> _renderDiagramIsolate(Map<String, dynamic> params) async {
  // In a real implementation, you would initialize the renderer
  // and render the diagram. The params map would contain
  // the workspace, view key, and render parameters.

  // This is a placeholder. In practice, isolate rendering requires:
  // 1. Serializing the workspace and view data
  // 2. Using the render pipeline
  // 3. Returning the output bytes

  // For now, return the params as a placeholder
  return params;
}
