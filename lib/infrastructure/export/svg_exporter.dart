import 'dart:async';

import 'package:flutter/material.dart' hide Element, Container, View;
import 'package:flutter_structurizr/infrastructure/export/diagram_exporter.dart';
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';

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
  const SvgExporter({
    this.renderParameters,
    this.includeCss = true,
    this.interactive = false,
    this.onProgress,
  });

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

      // Gather all elements and relationships for the view
      final elements = _getElementsInView(view, workspace);
      final relationships = _getRelationshipsInView(view, workspace);
      
      // Report data gathering progress
      onProgress?.call(0.3);

      // Get styling information
      final styles = workspace.configuration?.styles ?? Styles();
      
      // Report progress
      onProgress?.call(0.5);

      // Generate SVG content
      final svgContent = _generateSvg(
        elements: elements,
        relationships: relationships,
        styles: styles,
        view: view,
        title: diagram.title ?? view.title ?? view.key,
      );
      
      // Report completion
      onProgress?.call(1.0);

      return svgContent;
    } catch (e) {
      throw Exception('Failed to export diagram to SVG: $e');
    }
  }

  /// Finds a view in the workspace by key
  View? _findViewByKey(workspace, String key) {
    // Navigate through the workspace views structure to find the view with the specified key
    final views = workspace.views;

    // Check system landscape views
    final systemLandscapeView = views.systemLandscapeViews.firstWhere(
      (view) => view.key == key,
      orElse: () => SystemLandscapeView(key: ''), // Empty view if not found
    );
    if (systemLandscapeView.key.isNotEmpty) return systemLandscapeView;

    // Check system context views
    final systemContextView = views.systemContextViews.firstWhere(
      (view) => view.key == key,
      orElse: () => SystemContextView(key: '', softwareSystemId: ''), // Empty view if not found
    );
    if (systemContextView.key.isNotEmpty) return systemContextView;

    // Check container views
    final containerView = views.containerViews.firstWhere(
      (view) => view.key == key,
      orElse: () => ContainerView(key: '', softwareSystemId: ''), // Empty view if not found
    );
    if (containerView.key.isNotEmpty) return containerView;

    // Check component views
    final componentView = views.componentViews.firstWhere(
      (view) => view.key == key,
      orElse: () => ComponentView(key: '', containerId: '', softwareSystemId: ''), // Empty view if not found
    );
    if (componentView.key.isNotEmpty) return componentView;

    // Check dynamic views
    final dynamicView = views.dynamicViews.firstWhere(
      (view) => view.key == key,
      orElse: () => DynamicView(key: '', elementId: ''), // Empty view if not found
    );
    if (dynamicView.key.isNotEmpty) return dynamicView;

    // Check deployment views
    final deploymentView = views.deploymentViews.firstWhere(
      (view) => view.key == key,
      orElse: () => DeploymentView(key: '', environment: ''), // Empty view if not found
    );
    if (deploymentView.key.isNotEmpty) return deploymentView;

    // Not found in any collection
    return null;
  }

  /// Gets elements for a view from the workspace
  List<Element> _getElementsInView(View view, workspace) {
    final result = <Element>[];
    final model = workspace.model;

    // Go through each element ID in the view and find the corresponding element in the model
    for (final elementView in view.elements) {
      final id = elementView.id;

      // Check in people
      final person = model.getPeopleById(id);
      if (person != null) {
        result.add(person);
        continue;
      }

      // Check in software systems
      final softwareSystem = model.getSoftwareSystemById(id);
      if (softwareSystem != null) {
        result.add(softwareSystem);

        // If this is a container view for this system, add all its containers
        if (view is ContainerView && view.softwareSystemId == id) {
          result.addAll(softwareSystem.containers);
        }
        continue;
      }

      // Check containers in all systems
      for (final system in model.softwareSystems) {
        final container = system.containers.firstWhere(
          (c) => c.id == id,
          orElse: () => Container(id: '', name: '', parentId: '')
        );
        if (container.id.isNotEmpty) {
          result.add(container);

          // If this is a component view for this container, add all its components
          if (view is ComponentView && view.containerId == id) {
            result.addAll(container.components);
          }
          break;
        }
      }

      // Check components in all containers of all systems
      for (final system in model.softwareSystems) {
        bool found = false;
        for (final container in system.containers) {
          final component = container.components.firstWhere(
            (c) => c.id == id,
            orElse: () => Component(id: '', name: '', parentId: '')
          );
          if (component.id.isNotEmpty) {
            result.add(component);
            found = true;
            break;
          }
        }
        if (found) break;
      }

      // Check in deployment nodes
      final deploymentNode = model.deploymentNodes.firstWhere(
        (n) => n.id == id,
        orElse: () => DeploymentNode(id: '', name: '', environment: '')
      );
      if (deploymentNode.id.isNotEmpty) {
        result.add(deploymentNode);
        continue;
      }
    }

    return result;
  }

  /// Gets relationships for a view from the workspace
  List<Relationship> _getRelationshipsInView(View view, workspace) {
    final result = <Relationship>[];
    final model = workspace.model;

    // If explicit relationships are defined in the view
    if (view.relationships.isNotEmpty) {
      // Go through each relationship ID in the view and find the corresponding relationship in the model
      for (final relationshipView in view.relationships) {
        final id = relationshipView.id;

        // Find relationships in people
        for (final person in model.people) {
          final relationship = person.getRelationshipById(id);
          if (relationship != null) {
            result.add(relationship);
            break;
          }
        }

        // Find relationships in software systems
        for (final system in model.softwareSystems) {
          final relationship = system.getRelationshipById(id);
          if (relationship != null) {
            result.add(relationship);
            break;
          }

          // Find relationships in containers
          for (final container in system.containers) {
            final relationship = container.getRelationshipById(id);
            if (relationship != null) {
              result.add(relationship);
              break;
            }

            // Find relationships in components
            for (final component in container.components) {
              final relationship = component.getRelationshipById(id);
              if (relationship != null) {
                result.add(relationship);
                break;
              }
            }
          }
        }
      }
    } else {
      // If no explicit relationships are defined, infer from elements in view
      final elementIds = view.elements.map((e) => e.id).toSet();

      // Function to check if both source and destination are in the view
      bool isRelationshipInView(Relationship rel) {
        return elementIds.contains(rel.sourceId) && elementIds.contains(rel.destinationId);
      }

      // Collect all relationships between elements in the view

      // From people
      for (final person in model.people) {
        if (elementIds.contains(person.id)) {
          for (final relationship in person.relationships) {
            if (isRelationshipInView(relationship)) {
              result.add(relationship);
            }
          }
        }
      }

      // From software systems and their containers/components
      for (final system in model.softwareSystems) {
        if (elementIds.contains(system.id)) {
          for (final relationship in system.relationships) {
            if (isRelationshipInView(relationship)) {
              result.add(relationship);
            }
          }
        }

        // From containers
        for (final container in system.containers) {
          if (elementIds.contains(container.id)) {
            for (final relationship in container.relationships) {
              if (isRelationshipInView(relationship)) {
                result.add(relationship);
              }
            }
          }

          // From components
          for (final component in container.components) {
            if (elementIds.contains(component.id)) {
              for (final relationship in component.relationships) {
                if (isRelationshipInView(relationship)) {
                  result.add(relationship);
                }
              }
            }
          }
        }
      }
    }

    // For dynamic views, use the sequence of relationships defined in the view
    if (view is DynamicView) {
      // Clear previous results since dynamic views explicitly define the sequence
      result.clear();

      // Add all relationships defined in the dynamic view
      for (final interaction in view.relationships) {
        final sourceId = interaction.sourceId;
        final destinationId = interaction.destinationId;
        final description = interaction.description;

        // Create a representation of this interaction
        final relationship = Relationship(
          id: interaction.id ?? '${sourceId}_${destinationId}_${result.length}',
          sourceId: sourceId,
          destinationId: destinationId,
          description: description,
          order: interaction.order,
        );

        result.add(relationship);
      }
    }

    return result;
  }

  /// Generates SVG content from diagram elements
  String _generateSvg({
    required List<Element> elements,
    required List<Relationship> relationships,
    required Styles styles,
    required View view,
    required String title,
  }) {
    // Create SVG document with dimensions from render parameters or defaults
    final width = renderParameters?.width ?? 1920;
    final height = renderParameters?.height ?? 1080;
    
    final buffer = StringBuffer();
    
    // SVG header
    buffer.writeln('<?xml version="1.0" encoding="UTF-8" standalone="no"?>');
    buffer.writeln('<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
        'version="1.1" width="$width" height="$height" viewBox="0 0 $width $height">');
    
    // Add title
    buffer.writeln('  <title>$title</title>');
    
    // Add CSS if requested
    if (includeCss) {
      buffer.writeln('  <style type="text/css">');
      buffer.writeln('    /* Base styling */');
      buffer.writeln('    .element { stroke-width: 2; }');
      buffer.writeln('    .relationship { stroke-width: 1.5; }');
      buffer.writeln('    .label { font-family: sans-serif; font-size: 12px; }');
      // Add more CSS as needed for element types, relationships, etc.
      buffer.writeln('  </style>');
    }
    
    // Add definitions for markers (e.g., arrowheads)
    buffer.writeln('  <defs>');
    buffer.writeln('    <marker id="arrow" viewBox="0 0 10 10" refX="10" refY="5" markerWidth="6" markerHeight="6" orient="auto">');
    buffer.writeln('      <path d="M 0 0 L 10 5 L 0 10 z" fill="#707070" />');
    buffer.writeln('    </marker>');
    buffer.writeln('  </defs>');
    
    // Create a group for all diagram elements
    buffer.writeln('  <g id="diagram">');
    
    // Add background rectangle
    buffer.writeln('    <rect x="0" y="0" width="$width" height="$height" fill="white" />');
    
    // Add elements (boxes, circles, etc.)
    buffer.writeln('    <g id="elements">');
    for (final element in elements) {
      // In a real implementation, you would:
      // 1. Get the element style from styles
      // 2. Calculate element position from view layout
      // 3. Generate SVG based on element type and style
      
      // Example placeholder for a box element at position x=100, y=100
      buffer.writeln('      <rect class="element" id="${element.id}" x="100" y="100" '
          'width="120" height="80" fill="#dddddd" stroke="#000000" />');
      buffer.writeln('      <text class="label" x="160" y="140" text-anchor="middle">${element.name}</text>');
    }
    buffer.writeln('    </g>');
    
    // Add relationships (lines, arrows, etc.)
    buffer.writeln('    <g id="relationships">');
    for (final relationship in relationships) {
      // Similar to elements, in a real implementation you would:
      // 1. Get the relationship style
      // 2. Calculate path based on connected elements' positions
      // 3. Generate SVG path with proper markers
      
      // Example placeholder for a line from (200,200) to (300,300)
      buffer.writeln('      <path class="relationship" id="${relationship.id}" '
          'd="M 200 200 L 300 300" stroke="#707070" marker-end="url(#arrow)" />');
      buffer.writeln('      <text class="label" x="250" y="250" text-anchor="middle">${relationship.description}</text>');
    }
    buffer.writeln('    </g>');
    
    // Close diagram group
    buffer.writeln('  </g>');
    
    // Add legend if requested
    if (renderParameters?.includeLegend == true) {
      buffer.writeln('  <g id="legend" transform="translate(${width - 200}, 20)">');
      buffer.writeln('    <rect x="0" y="0" width="180" height="100" fill="#f8f8f8" stroke="#dddddd" />');
      buffer.writeln('    <text x="90" y="20" text-anchor="middle">Legend</text>');
      // Add legend content
      buffer.writeln('  </g>');
    }
    
    // Close SVG
    buffer.writeln('</svg>');

    return buffer.toString();
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
        print('Error exporting diagram ${diagrams[i].viewKey}: $e');
      }
    }

    // Call progress callback with completion
    onProgress?.call(1.0);
    this.onProgress?.call(1.0);

    return results;
  }
}