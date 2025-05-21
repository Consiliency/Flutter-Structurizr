import 'dart:async';

import 'package:flutter/material.dart' hide Element, Container, View;
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/container.dart';
import 'package:flutter_structurizr/domain/model/component.dart';
import 'package:flutter_structurizr/domain/model/deployment_node.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/infrastructure/export/diagram_exporter.dart';
import 'package:logging/logging.dart';

/// The style of Mermaid diagram to generate
enum MermaidStyle {
  /// Standard Mermaid
  standard,

  /// C4-style Mermaid
  c4,
}

/// The layout direction for Mermaid diagrams
enum MermaidDirection {
  /// Top to bottom (default)
  topToBottom,

  /// Bottom to top
  bottomToTop,

  /// Left to right
  leftToRight,

  /// Right to left
  rightToLeft,
}

/// An exporter for Mermaid diagram format
class MermaidExporter implements DiagramExporter<String> {
  /// The Mermaid style to use
  final MermaidStyle style;

  /// The direction of diagram layout
  final MermaidDirection direction;

  /// Whether to include notes in the output
  final bool includeNotes;

  /// Whether to include theme customization
  final bool includeTheme;

  /// Progress callback for the export operation
  final ValueChanged<double>? onProgress;

  /// Creates a new Mermaid exporter
  const MermaidExporter({
    this.style = MermaidStyle.standard,
    this.direction = MermaidDirection.topToBottom,
    this.includeNotes = true,
    this.includeTheme = true,
    this.onProgress,
  });

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
      }
    }

    // Call progress callback with completion
    onProgress?.call(1.0);
    this.onProgress?.call(1.0);

    return results;
  }

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

      // Generate Mermaid content based on view type
      String mermaidContent = '';
      if (view is SystemContextView) {
        mermaidContent =
            _generateSystemContextDiagram(view, elements, relationships);
      } else if (view is ContainerView) {
        mermaidContent =
            _generateContainerDiagram(view, elements, relationships);
      } else if (view is ComponentView) {
        mermaidContent =
            _generateComponentDiagram(view, elements, relationships);
      } else if (view is DeploymentView) {
        mermaidContent =
            _generateDeploymentDiagram(view, elements, relationships);
      } else {
        // Default generic diagram
        mermaidContent = _generateGenericDiagram(view, elements, relationships);
      }

      // Report completion
      onProgress?.call(1.0);

      return mermaidContent;
    } catch (e) {
      throw Exception('Failed to export diagram to Mermaid: $e');
    }
  }

  /// Finds a view in the workspace by key
  View? _findViewByKey(workspace, String key) {
    // Navigate through the workspace views structure to find the view with the specified key
    final views = workspace.views;

    // Check system landscape views
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
        final container = system.containers.firstWhere((c) => c.id == id,
            orElse: () => Container(id: '', name: '', parentId: ''));
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
          final component = container.components.firstWhere((c) => c.id == id,
              orElse: () => Component(id: '', name: '', parentId: ''));
          if (component.id.isNotEmpty) {
            result.add(component);
            found = true;
            break;
          }
        }
        if (found) break;
      }

      // Check in deployment nodes
      final deploymentNode = model.deploymentNodes.firstWhere((n) => n.id == id,
          orElse: () => DeploymentNode(id: '', name: '', environment: ''));
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
        return elementIds.contains(rel.sourceId) &&
            elementIds.contains(rel.destinationId);
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
          sourceId: sourceId ?? '',
          destinationId: destinationId ?? '',
          description: description ?? '',
        );

        result.add(relationship);
      }
    }

    return result;
  }

  /// Generates a System Context diagram in Mermaid format
  String _generateSystemContextDiagram(
    SystemContextView view,
    List<Element> elements,
    List<Relationship> relationships,
  ) {
    final buffer = StringBuffer();

    // Start Mermaid diagram with diagram type and direction
    buffer.writeln('graph ${_getDirectionCode()}');

    // Add title as comment
    buffer.writeln('%% ${view.title ?? view.key}');
    buffer.writeln();

    // Add styling if requested
    if (includeTheme) {
      buffer.writeln('  %% Styling for diagram');
      buffer.writeln(
          '  classDef person fill:#08427B,stroke:#052E56,color:#FFFFFF');
      buffer.writeln(
          '  classDef system fill:#1168BD,stroke:#0B4884,color:#FFFFFF');
      buffer.writeln(
          '  classDef external fill:#999999,stroke:#6B6B6B,color:#FFFFFF');
      buffer.writeln();
    }

    // Define elements
    buffer.writeln('  %% Elements');
    for (final element in elements) {
      if (element is Person) {
        buffer.writeln(
            '  ${_sanitizeId(element.id)}["${_escapeMermaidText(element.name)}<br><i>Person</i>"]');
        if (includeTheme) {
          buffer.writeln('  class ${_sanitizeId(element.id)} person');
        }
      } else if (element is SoftwareSystem) {
        // Check if this is the system being detailed or an external system
        final isExternal = element.id != view.softwareSystemId;
        buffer.writeln(
            '  ${_sanitizeId(element.id)}["${_escapeMermaidText(element.name)}<br><i>Software System</i>"]');
        if (includeTheme) {
          buffer.writeln(
              '  class ${_sanitizeId(element.id)} ${isExternal ? 'external' : 'system'}');
        }
      }

      // Add notes if requested
      if (includeNotes &&
          element.description != null &&
          element.description!.isNotEmpty) {
        buffer.writeln(
            '  ${_sanitizeId(element.id)}_note["${_escapeMermaidText(element.description!)}"]');
        buffer.writeln(
            '  ${_sanitizeId(element.id)} --- ${_sanitizeId(element.id)}_note');
      }
    }
    buffer.writeln();

    // Define relationships
    buffer.writeln('  %% Relationships');
    for (final relationship in relationships) {
      final sourceId = _sanitizeId(relationship.sourceId);
      final targetId = _sanitizeId(relationship.destinationId);
      final label = relationship.description ?? '';

      buffer.writeln(
          '  ${sourceId} -->|"${_escapeMermaidText(label)}"| ${targetId}');
    }
    buffer.writeln();

    // Add legend if in C4 style
    if (style == MermaidStyle.c4) {
      buffer.writeln('  %% Legend');
      buffer.writeln('  subgraph Legend');
      buffer.writeln(
          '    legend[System Context diagram for ${view.softwareSystemId}<br>Generated by Flutter Structurizr]');
      buffer.writeln('  end');
    }

    return buffer.toString();
  }

  /// Generates a Container diagram in Mermaid format
  String _generateContainerDiagram(
    ContainerView view,
    List<Element> elements,
    List<Relationship> relationships,
  ) {
    final buffer = StringBuffer();

    // Start Mermaid diagram with diagram type and direction
    buffer.writeln('graph ${_getDirectionCode()}');

    // Add title as comment
    buffer.writeln('%% ${view.title ?? view.key}');
    buffer.writeln();

    // Add styling if requested
    if (includeTheme) {
      buffer.writeln('  %% Styling for diagram');
      buffer.writeln(
          '  classDef person fill:#08427B,stroke:#052E56,color:#FFFFFF');
      buffer.writeln(
          '  classDef system fill:#1168BD,stroke:#0B4884,color:#FFFFFF');
      buffer.writeln(
          '  classDef container fill:#438DD5,stroke:#2E6295,color:#FFFFFF');
      buffer.writeln(
          '  classDef external fill:#999999,stroke:#6B6B6B,color:#FFFFFF');
      buffer.writeln();
    }

    // Find the system being detailed
    final softwareSystem = elements.firstWhere(
      (e) => e.id == view.softwareSystemId,
      orElse: () => const SoftwareSystem(id: '', name: ''),
    ) as SoftwareSystem;

    // Define external elements
    buffer.writeln('  %% External elements');
    for (final element in elements) {
      // Skip containers of the system being detailed - we'll add those in their own subgraph
      if (element is Container && element.parentId == softwareSystem.id) {
        continue;
      }

      if (element is Person) {
        buffer.writeln(
            '  ${_sanitizeId(element.id)}["${_escapeMermaidText(element.name)}<br><i>Person</i>"]');
        if (includeTheme) {
          buffer.writeln('  class ${_sanitizeId(element.id)} person');
        }
      } else if (element is SoftwareSystem && element.id != softwareSystem.id) {
        buffer.writeln(
            '  ${_sanitizeId(element.id)}["${_escapeMermaidText(element.name)}<br><i>Software System</i>"]');
        if (includeTheme) {
          buffer.writeln('  class ${_sanitizeId(element.id)} external');
        }
      }

      // Add notes if requested
      if (includeNotes &&
          element.description != null &&
          element.description!.isNotEmpty &&
          !(element is Container && element.parentId == softwareSystem.id)) {
        buffer.writeln(
            '  ${_sanitizeId(element.id)}_note["${_escapeMermaidText(element.description!)}"]');
        buffer.writeln(
            '  ${_sanitizeId(element.id)} --- ${_sanitizeId(element.id)}_note');
      }
    }
    buffer.writeln();

    // Now add the system and its containers as a subgraph
    buffer.writeln('  %% System and its containers');
    buffer.writeln(
        '  subgraph ${_sanitizeId(softwareSystem.id)}_system["${_escapeMermaidText(softwareSystem.name)}"]');

    // Add containers
    final containers = elements
        .whereType<Container>()
        .where((container) => container.parentId == softwareSystem.id)
        .toList();

    for (final container in containers) {
      final technologyInfo =
          container.technology != null && container.technology!.isNotEmpty
              ? '<br>[${_escapeMermaidText(container.technology!)}]'
              : '';

      buffer.writeln(
          '    ${_sanitizeId(container.id)}["${_escapeMermaidText(container.name)}<br><i>Container</i>${technologyInfo}"]');
      if (includeTheme) {
        buffer.writeln('    class ${_sanitizeId(container.id)} container');
      }

      // Add notes if requested
      if (includeNotes &&
          container.description != null &&
          container.description!.isNotEmpty) {
        buffer.writeln(
            '    ${_sanitizeId(container.id)}_note["${_escapeMermaidText(container.description!)}"]');
        buffer.writeln(
            '    ${_sanitizeId(container.id)} --- ${_sanitizeId(container.id)}_note');
      }
    }

    buffer.writeln('  end');
    buffer.writeln('  class ${_sanitizeId(softwareSystem.id)}_system system');
    buffer.writeln();

    // Define relationships
    buffer.writeln('  %% Relationships');
    for (final relationship in relationships) {
      final sourceId = _sanitizeId(relationship.sourceId);
      final targetId = _sanitizeId(relationship.destinationId);
      final label = relationship.description ?? '';

      buffer.writeln(
          '  ${sourceId} -->|"${_escapeMermaidText(label)}"| ${targetId}');
    }
    buffer.writeln();

    // Add legend if in C4 style
    if (style == MermaidStyle.c4) {
      buffer.writeln('  %% Legend');
      buffer.writeln('  subgraph Legend');
      buffer.writeln(
          '    legend[Container diagram for ${softwareSystem.name}<br>Generated by Flutter Structurizr]');
      buffer.writeln('  end');
    }

    return buffer.toString();
  }

  /// Generates a Component diagram in Mermaid format
  String _generateComponentDiagram(
    ComponentView view,
    List<Element> elements,
    List<Relationship> relationships,
  ) {
    final buffer = StringBuffer();

    // Start Mermaid diagram with diagram type and direction
    buffer.writeln('graph ${_getDirectionCode()}');

    // Add title as comment
    buffer.writeln('%% ${view.title ?? view.key}');
    buffer.writeln();

    // Add styling if requested
    if (includeTheme) {
      buffer.writeln('  %% Styling for diagram');
      buffer.writeln(
          '  classDef person fill:#08427B,stroke:#052E56,color:#FFFFFF');
      buffer.writeln(
          '  classDef system fill:#1168BD,stroke:#0B4884,color:#FFFFFF');
      buffer.writeln(
          '  classDef container fill:#438DD5,stroke:#2E6295,color:#FFFFFF');
      buffer.writeln(
          '  classDef component fill:#85BBF0,stroke:#5C8AB8,color:#000000');
      buffer.writeln(
          '  classDef external fill:#999999,stroke:#6B6B6B,color:#FFFFFF');
      buffer.writeln();
    }

    // Find the container being detailed
    final container = elements.firstWhere(
      (e) => e.id == view.containerId,
      orElse: () => Container(id: '', name: '', parentId: ''),
    ) as Container;

    // Define external elements
    buffer.writeln('  %% External elements');
    for (final element in elements) {
      // Skip components of the container being detailed - we'll add those in their own subgraph
      if (element is Component && element.parentId == container.id) {
        continue;
      }

      if (element is Person) {
        buffer.writeln(
            '  ${_sanitizeId(element.id)}["${_escapeMermaidText(element.name)}<br><i>Person</i>"]');
        if (includeTheme) {
          buffer.writeln('  class ${_sanitizeId(element.id)} person');
        }
      } else if (element is SoftwareSystem) {
        buffer.writeln(
            '  ${_sanitizeId(element.id)}["${_escapeMermaidText(element.name)}<br><i>Software System</i>"]');
        if (includeTheme) {
          buffer.writeln(
              '  class ${_sanitizeId(element.id)} ${element.id == view.softwareSystemId ? 'system' : 'external'}');
        }
      } else if (element is Container && element.id != container.id) {
        final technologyInfo =
            element.technology != null && element.technology!.isNotEmpty
                ? '<br>[${_escapeMermaidText(element.technology!)}]'
                : '';

        buffer.writeln(
            '  ${_sanitizeId(element.id)}["${_escapeMermaidText(element.name)}<br><i>Container</i>${technologyInfo}"]');
        if (includeTheme) {
          buffer.writeln('  class ${_sanitizeId(element.id)} container');
        }
      }

      // Add notes if requested
      if (includeNotes &&
          element.description != null &&
          element.description!.isNotEmpty &&
          !(element is Component && element.parentId == container.id)) {
        buffer.writeln(
            '  ${_sanitizeId(element.id)}_note["${_escapeMermaidText(element.description!)}"]');
        buffer.writeln(
            '  ${_sanitizeId(element.id)} --- ${_sanitizeId(element.id)}_note');
      }
    }
    buffer.writeln();

    // Now add the container and its components as a subgraph
    buffer.writeln('  %% Container and its components');
    final technologyInfo =
        container.technology != null && container.technology!.isNotEmpty
            ? ' [${container.technology}]'
            : '';

    buffer.writeln(
        '  subgraph ${_sanitizeId(container.id)}_container["${_escapeMermaidText(container.name)}${_escapeMermaidText(technologyInfo)}"]');

    // Add components
    final components = elements
        .whereType<Component>()
        .where((component) => component.parentId == container.id)
        .toList();

    for (final component in components) {
      final componentTechInfo =
          component.technology != null && component.technology!.isNotEmpty
              ? '<br>[${_escapeMermaidText(component.technology!)}]'
              : '';

      buffer.writeln(
          '    ${_sanitizeId(component.id)}["${_escapeMermaidText(component.name)}<br><i>Component</i>${componentTechInfo}"]');
      if (includeTheme) {
        buffer.writeln('    class ${_sanitizeId(component.id)} component');
      }

      // Add notes if requested
      if (includeNotes &&
          component.description != null &&
          component.description!.isNotEmpty) {
        buffer.writeln(
            '    ${_sanitizeId(component.id)}_note["${_escapeMermaidText(component.description!)}"]');
        buffer.writeln(
            '    ${_sanitizeId(component.id)} --- ${_sanitizeId(component.id)}_note');
      }
    }

    buffer.writeln('  end');
    buffer.writeln('  class ${_sanitizeId(container.id)}_container container');
    buffer.writeln();

    // Define relationships
    buffer.writeln('  %% Relationships');
    for (final relationship in relationships) {
      final sourceId = _sanitizeId(relationship.sourceId);
      final targetId = _sanitizeId(relationship.destinationId);
      final label = relationship.description ?? '';

      buffer.writeln(
          '  ${sourceId} -->|"${_escapeMermaidText(label)}"| ${targetId}');
    }
    buffer.writeln();

    // Add legend if in C4 style
    if (style == MermaidStyle.c4) {
      buffer.writeln('  %% Legend');
      buffer.writeln('  subgraph Legend');
      buffer.writeln(
          '    legend[Component diagram for ${container.name}<br>Generated by Flutter Structurizr]');
      buffer.writeln('  end');
    }

    return buffer.toString();
  }

  /// Generates a Deployment diagram in Mermaid format
  String _generateDeploymentDiagram(
    DeploymentView view,
    List<Element> elements,
    List<Relationship> relationships,
  ) {
    final buffer = StringBuffer();

    // Start Mermaid diagram with diagram type and direction
    buffer.writeln('graph ${_getDirectionCode()}');

    // Add title as comment
    buffer.writeln('%% ${view.title ?? view.key} (${view.environment})');
    buffer.writeln();

    // Add styling if requested
    if (includeTheme) {
      buffer.writeln('  %% Styling for diagram');
      buffer.writeln(
          '  classDef deploymentNode fill:#999999,stroke:#6B6B6B,color:#FFFFFF');
      buffer.writeln(
          '  classDef infrastructureNode fill:#85BBF0,stroke:#5C8AB8,color:#000000');
      buffer.writeln(
          '  classDef containerInstance fill:#438DD5,stroke:#2E6295,color:#FFFFFF');
      buffer.writeln(
          '  classDef systemInstance fill:#1168BD,stroke:#0B4884,color:#FFFFFF');
      buffer.writeln();
    }

    // Process deployment nodes recursively
    _processDeploymentNodes(buffer, elements, view.environment, '  ');

    // Define relationships
    buffer.writeln('  %% Relationships');
    for (final relationship in relationships) {
      final sourceId = _sanitizeId(relationship.sourceId);
      final targetId = _sanitizeId(relationship.destinationId);
      final label = relationship.description ?? '';

      buffer.writeln(
          '  ${sourceId} -->|"${_escapeMermaidText(label)}"| ${targetId}');
    }
    buffer.writeln();

    // Add legend if in C4 style
    if (style == MermaidStyle.c4) {
      buffer.writeln('  %% Legend');
      buffer.writeln('  subgraph Legend');
      buffer.writeln(
          '    legend[Deployment diagram for ${view.environment}<br>Generated by Flutter Structurizr]');
      buffer.writeln('  end');
    }

    return buffer.toString();
  }

  /// Recursively processes deployment nodes for deployment diagram
  void _processDeploymentNodes(StringBuffer buffer, List<Element> elements,
      String environment, String indent) {
    // Find top-level deployment nodes for this environment
    final deploymentNodes = elements
        .whereType<DeploymentNode>()
        .where((node) => node.environment == environment)
        .toList();

    for (final node in deploymentNodes) {
      final technologyInfo =
          node.technology != null && node.technology!.isNotEmpty
              ? ' [${node.technology}]'
              : '';

      buffer.writeln('${indent}%% Deployment Node: ${node.name}');
      buffer.writeln(
          '${indent}subgraph ${_sanitizeId(node.id)}["${_escapeMermaidText(node.name)}${_escapeMermaidText(technologyInfo)}"]');

      // Add infrastructure nodes
      for (final infraNode in node.infrastructureNodes) {
        final infraTechInfo =
            infraNode.technology != null && infraNode.technology!.isNotEmpty
                ? '<br>[${_escapeMermaidText(infraNode.technology!)}]'
                : '';

        buffer.writeln(
            '${indent}  ${_sanitizeId(infraNode.id)}["${_escapeMermaidText(infraNode.name)}<br><i>Infrastructure</i>${infraTechInfo}"]');
        if (includeTheme) {
          buffer.writeln(
              '${indent}  class ${_sanitizeId(infraNode.id)} infrastructureNode');
        }
      }

      // Add container instances
      for (final containerInstance in node.containerInstances) {
        buffer.writeln(
            '${indent}  ${_sanitizeId(containerInstance.id)}["${_escapeMermaidText(containerInstance.name)}<br><i>Container Instance</i>"]');
        if (includeTheme) {
          buffer.writeln(
              '${indent}  class ${_sanitizeId(containerInstance.id)} containerInstance');
        }
      }

      // Add software system instances
      for (final systemInstance in node.softwareSystemInstances) {
        buffer.writeln(
            '${indent}  ${_sanitizeId(systemInstance.id)}["${_escapeMermaidText(systemInstance.name)}<br><i>System Instance</i>"]');
        if (includeTheme) {
          buffer.writeln(
              '${indent}  class ${_sanitizeId(systemInstance.id)} systemInstance');
        }
      }

      // Process child nodes recursively
      for (final childNode in node.children) {
        _processChildDeploymentNode(buffer, childNode, '${indent}  ');
      }

      buffer.writeln('${indent}end');
      if (includeTheme) {
        buffer.writeln('${indent}class ${_sanitizeId(node.id)} deploymentNode');
      }
      buffer.writeln();
    }
  }

  /// Recursively processes a child deployment node
  void _processChildDeploymentNode(
      StringBuffer buffer, DeploymentNode node, String indent) {
    final technologyInfo =
        node.technology != null && node.technology!.isNotEmpty
            ? ' [${node.technology}]'
            : '';

    buffer.writeln(
        '${indent}subgraph ${_sanitizeId(node.id)}["${_escapeMermaidText(node.name)}${_escapeMermaidText(technologyInfo)}"]');

    // Add infrastructure nodes
    for (final infraNode in node.infrastructureNodes) {
      final infraTechInfo =
          infraNode.technology != null && infraNode.technology!.isNotEmpty
              ? '<br>[${_escapeMermaidText(infraNode.technology!)}]'
              : '';

      buffer.writeln(
          '${indent}  ${_sanitizeId(infraNode.id)}["${_escapeMermaidText(infraNode.name)}<br><i>Infrastructure</i>${infraTechInfo}"]');
      if (includeTheme) {
        buffer.writeln(
            '${indent}  class ${_sanitizeId(infraNode.id)} infrastructureNode');
      }
    }

    // Add container instances
    for (final containerInstance in node.containerInstances) {
      buffer.writeln(
          '${indent}  ${_sanitizeId(containerInstance.id)}["${_escapeMermaidText(containerInstance.name)}<br><i>Container Instance</i>"]');
      if (includeTheme) {
        buffer.writeln(
            '${indent}  class ${_sanitizeId(containerInstance.id)} containerInstance');
      }
    }

    // Add software system instances
    for (final systemInstance in node.softwareSystemInstances) {
      buffer.writeln(
          '${indent}  ${_sanitizeId(systemInstance.id)}["${_escapeMermaidText(systemInstance.name)}<br><i>System Instance</i>"]');
      if (includeTheme) {
        buffer.writeln(
            '${indent}  class ${_sanitizeId(systemInstance.id)} systemInstance');
      }
    }

    // Process children recursively
    for (final childNode in node.children) {
      _processChildDeploymentNode(buffer, childNode, '${indent}  ');
    }

    buffer.writeln('${indent}end');
    if (includeTheme) {
      buffer.writeln('${indent}class ${_sanitizeId(node.id)} deploymentNode');
    }
  }

  /// Generates a generic diagram for any view type in Mermaid format
  String _generateGenericDiagram(
    View view,
    List<Element> elements,
    List<Relationship> relationships,
  ) {
    final buffer = StringBuffer();

    // Start Mermaid diagram with diagram type and direction
    buffer.writeln('graph ${_getDirectionCode()}');

    // Add title as comment
    buffer.writeln('%% ${view.title ?? view.key}');
    buffer.writeln();

    // Add styling if requested
    if (includeTheme) {
      buffer.writeln('  %% Styling for diagram');
      buffer.writeln(
          '  classDef default fill:#FFFFFF,stroke:#000000,color:#000000');
      buffer.writeln(
          '  classDef person fill:#08427B,stroke:#052E56,color:#FFFFFF');
      buffer.writeln(
          '  classDef system fill:#1168BD,stroke:#0B4884,color:#FFFFFF');
      buffer.writeln(
          '  classDef container fill:#438DD5,stroke:#2E6295,color:#FFFFFF');
      buffer.writeln(
          '  classDef component fill:#85BBF0,stroke:#5C8AB8,color:#000000');
      buffer.writeln();
    }

    // Define all elements
    buffer.writeln('  %% Elements');
    for (final element in elements) {
      if (element is Person) {
        buffer.writeln(
            '  ${_sanitizeId(element.id)}(["${_escapeMermaidText(element.name)}<br><i>Person</i>"])');
        if (includeTheme) {
          buffer.writeln('  class ${_sanitizeId(element.id)} person');
        }
      } else if (element is SoftwareSystem) {
        buffer.writeln(
            '  ${_sanitizeId(element.id)}["${_escapeMermaidText(element.name)}<br><i>Software System</i>"]');
        if (includeTheme) {
          buffer.writeln('  class ${_sanitizeId(element.id)} system');
        }
      } else if (element is Container) {
        final technologyInfo =
            element.technology != null && element.technology!.isNotEmpty
                ? '<br>[${_escapeMermaidText(element.technology!)}]'
                : '';

        buffer.writeln(
            '  ${_sanitizeId(element.id)}["${_escapeMermaidText(element.name)}<br><i>Container</i>${technologyInfo}"]');
        if (includeTheme) {
          buffer.writeln('  class ${_sanitizeId(element.id)} container');
        }
      } else if (element is Component) {
        final technologyInfo =
            element.technology != null && element.technology!.isNotEmpty
                ? '<br>[${_escapeMermaidText(element.technology!)}]'
                : '';

        buffer.writeln(
            '  ${_sanitizeId(element.id)}["${_escapeMermaidText(element.name)}<br><i>Component</i>${technologyInfo}"]');
        if (includeTheme) {
          buffer.writeln('  class ${_sanitizeId(element.id)} component');
        }
      } else if (element is DeploymentNode) {
        final technologyInfo =
            element.technology != null && element.technology!.isNotEmpty
                ? '<br>[${_escapeMermaidText(element.technology!)}]'
                : '';

        buffer.writeln(
            '  ${_sanitizeId(element.id)}[("${_escapeMermaidText(element.name)}<br><i>Deployment Node</i>${technologyInfo}")]');
      } else {
        buffer.writeln(
            '  ${_sanitizeId(element.id)}["${_escapeMermaidText(element.name)}"]');
      }

      // Add notes if requested
      if (includeNotes &&
          element.description != null &&
          element.description!.isNotEmpty) {
        buffer.writeln(
            '  ${_sanitizeId(element.id)}_note["${_escapeMermaidText(element.description!)}"]');
        buffer.writeln(
            '  ${_sanitizeId(element.id)} --- ${_sanitizeId(element.id)}_note');
      }
    }
    buffer.writeln();

    // Define relationships
    buffer.writeln('  %% Relationships');
    for (final relationship in relationships) {
      final sourceId = _sanitizeId(relationship.sourceId);
      final targetId = _sanitizeId(relationship.destinationId);
      final label = relationship.description ?? '';

      buffer.writeln(
          '  ${sourceId} -->|"${_escapeMermaidText(label)}"| ${targetId}');
    }
    buffer.writeln();

    return buffer.toString();
  }

  /// Gets the direction code for Mermaid diagrams
  String _getDirectionCode() {
    switch (direction) {
      case MermaidDirection.topToBottom:
        return 'TD';
      case MermaidDirection.bottomToTop:
        return 'BT';
      case MermaidDirection.leftToRight:
        return 'LR';
      case MermaidDirection.rightToLeft:
        return 'RL';
    }
  }

  /// Escapes text for use in Mermaid diagrams
  String _escapeMermaidText(String text) {
    return text
        .replaceAll('"', '\\"')
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }

  /// Sanitizes an ID to be valid in Mermaid
  String _sanitizeId(String id) {
    // Replace invalid characters with underscores
    return id.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
  }
}

final _logger = Logger('MermaidExporter');
