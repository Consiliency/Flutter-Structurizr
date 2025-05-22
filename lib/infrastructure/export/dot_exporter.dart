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

final logger = Logger('DotExporter');

/// The layout algorithm to use for DOT output
enum DotLayout {
  /// Hierarchical layout (top to bottom)
  dot,

  /// Undirected graph layout (spring model)
  neato,

  /// Radial layout
  twopi,

  /// Circular layout
  circo,

  /// Force-directed layout
  fdp,

  /// Force-directed layout using stress majorization
  sfdp,

  /// Hierarchical layout with edge concentration
  osage,

  /// Hierarchical layout with edge concentration (newer version)
  patchwork,
}

/// The output format for the DOT file
enum DotRankDirection {
  /// Top to bottom (default)
  topToBottom,

  /// Bottom to top
  bottomToTop,

  /// Left to right
  leftToRight,

  /// Right to left
  rightToLeft,
}

/// An exporter for DOT/Graphviz diagram format
class DotExporter implements DiagramExporter<String> {
  /// The layout algorithm to use
  final DotLayout layout;

  /// The rank direction for hierarchical layouts
  final DotRankDirection rankDirection;

  /// Whether to include clustering for nested elements
  final bool includeClusters;

  /// Whether to include labels with detailed information
  final bool includeDetailedLabels;

  /// Whether to use custom styling for different element types
  final bool includeCustomStyling;

  /// Progress callback for the export operation
  final ValueChanged<double>? onProgress;

  /// Creates a new DOT exporter
  const DotExporter({
    this.layout = DotLayout.dot,
    this.rankDirection = DotRankDirection.topToBottom,
    this.includeClusters = true,
    this.includeDetailedLabels = true,
    this.includeCustomStyling = true,
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
        logger.severe('Error exporting diagram ${diagrams[i].viewKey}: $e');
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

      // Generate DOT content based on view type
      String dotContent = '';
      if (view is SystemContextView) {
        dotContent =
            _generateSystemContextDiagram(view, elements, relationships);
      } else if (view is ContainerView) {
        dotContent = _generateContainerDiagram(view, elements, relationships);
      } else if (view is ComponentView) {
        dotContent = _generateComponentDiagram(view, elements, relationships);
      } else if (view is DeploymentView) {
        dotContent = _generateDeploymentDiagram(view, elements, relationships);
      } else {
        // Default generic diagram
        dotContent = _generateGenericDiagram(view, elements, relationships);
      }

      // Report completion
      onProgress?.call(1.0);

      return dotContent;
    } catch (e) {
      throw Exception('Failed to export diagram to DOT/Graphviz: $e');
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
            orElse: () => const Container(id: '', name: '', parentId: ''));
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
              orElse: () => const Component(id: '', name: '', parentId: ''));
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
          orElse: () =>
              const DeploymentNode(id: '', name: '', environment: ''));
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

  /// Generates a System Context diagram in DOT format
  String _generateSystemContextDiagram(
    SystemContextView view,
    List<Element> elements,
    List<Relationship> relationships,
  ) {
    final buffer = StringBuffer();

    // Start DOT diagram with type based on layout
    buffer.writeln('${_getLayoutName()} "${view.title ?? view.key}" {');

    // Add global attributes
    buffer.writeln('  // Global attributes');
    buffer.writeln('  graph [');
    buffer.writeln('    fontname = "Arial"');
    buffer.writeln('    fontsize = 14');
    buffer.writeln('    rankdir = ${_getRankDir()}');
    buffer.writeln('    ranksep = 1.0');
    buffer.writeln('    nodesep = 0.8');
    buffer.writeln('    pad = 0.4');
    buffer.writeln('    splines = "polyline"');
    buffer.writeln('    overlap = false');
    buffer.writeln('  ];');

    buffer.writeln('  node [');
    buffer.writeln('    fontname = "Arial"');
    buffer.writeln('    fontsize = 12');
    buffer.writeln('    shape = "box"');
    buffer.writeln('    style = "filled"');
    buffer.writeln('    fillcolor = "#FFFFFF"');
    buffer.writeln('    color = "#000000"');
    buffer.writeln('    width = 1.3');
    buffer.writeln('    height = 0.8');
    buffer.writeln('  ];');

    buffer.writeln('  edge [');
    buffer.writeln('    fontname = "Arial"');
    buffer.writeln('    fontsize = 10');
    buffer.writeln('    style = "solid"');
    buffer.writeln('    color = "#707070"');
    buffer.writeln('  ];');
    buffer.writeln();

    // Define elements
    buffer.writeln('  // Elements');
    for (final element in elements) {
      if (element is Person) {
        buffer.write('  ${_sanitizeId(element.id)} [');
        if (includeDetailedLabels) {
          buffer
              .write('label = "${_escapeLabel(element.name + '\\n[Person]')}');
          if (element.description != null && element.description!.isNotEmpty) {
            buffer.write('\\n\\n${_escapeLabel(element.description!)}');
          }
          buffer.write('"');
        } else {
          buffer.write('label = "${_escapeLabel(element.name)}\\n[Person]"');
        }

        if (includeCustomStyling) {
          buffer.write(
              ', shape = "ellipse", fillcolor = "#08427B", fontcolor = "#FFFFFF"');
        }

        buffer.writeln(' ];');
      } else if (element is SoftwareSystem) {
        buffer.write('  ${_sanitizeId(element.id)} [');
        if (includeDetailedLabels) {
          buffer.write(
              'label = "${_escapeLabel(element.name + '\\n[Software System]')}');
          if (element.description != null && element.description!.isNotEmpty) {
            buffer.write('\\n\\n${_escapeLabel(element.description!)}');
          }
          buffer.write('"');
        } else {
          buffer.write(
              'label = "${_escapeLabel(element.name)}\\n[Software System]"');
        }

        if (includeCustomStyling) {
          final isExternal = element.id != view.softwareSystemId;
          if (isExternal) {
            buffer.write(', fillcolor = "#999999", fontcolor = "#FFFFFF"');
          } else {
            buffer.write(', fillcolor = "#1168BD", fontcolor = "#FFFFFF"');
          }
        }

        buffer.writeln(' ];');
      }
    }
    buffer.writeln();

    // Define relationships
    buffer.writeln('  // Relationships');
    for (final relationship in relationships) {
      final sourceId = _sanitizeId(relationship.sourceId);
      final targetId = _sanitizeId(relationship.destinationId);
      final label = relationship.description;

      buffer.write('  ${sourceId} -> ${targetId}');
      if (label.isNotEmpty) {
        buffer.write(' [ label = "${_escapeLabel(label)}"');
        if (relationship.technology != null &&
            relationship.technology!.isNotEmpty) {
          buffer.write(
              ' headlabel = "${_escapeLabel('[' + relationship.technology! + ']')}"');
        }
        buffer.write(' ]');
      }
      buffer.writeln(';');
    }
    buffer.writeln();

    // Add legend
    buffer.writeln('  // Legend');
    buffer.writeln('  subgraph cluster_legend {');
    buffer.writeln('    label = "Legend";');
    buffer.writeln('    fontsize = 12;');
    buffer.writeln('    _legend [ shape = "none", label = <');
    buffer.writeln(
        '      <table border="0" cellborder="1" cellpadding="4" cellspacing="0">');
    buffer.writeln(
        '        <tr><td>System Context diagram for ${view.softwareSystemId}</td></tr>');
    buffer
        .writeln('        <tr><td>Generated by Flutter Structurizr</td></tr>');
    buffer.writeln('      </table>');
    buffer.writeln('    > ];');
    buffer.writeln('  }');

    // Close diagram
    buffer.writeln('}');

    return buffer.toString();
  }

  /// Generates a Container diagram in DOT format
  String _generateContainerDiagram(
    ContainerView view,
    List<Element> elements,
    List<Relationship> relationships,
  ) {
    final buffer = StringBuffer();

    // Start DOT diagram with type based on layout
    buffer.writeln('${_getLayoutName()} "${view.title ?? view.key}" {');

    // Add global attributes
    buffer.writeln('  // Global attributes');
    buffer.writeln('  graph [');
    buffer.writeln('    fontname = "Arial"');
    buffer.writeln('    fontsize = 14');
    buffer.writeln('    rankdir = ${_getRankDir()}');
    buffer.writeln('    ranksep = 1.0');
    buffer.writeln('    nodesep = 0.8');
    buffer.writeln('    pad = 0.4');
    buffer.writeln('    splines = "polyline"');
    buffer.writeln('    overlap = false');
    buffer.writeln('  ];');

    buffer.writeln('  node [');
    buffer.writeln('    fontname = "Arial"');
    buffer.writeln('    fontsize = 12');
    buffer.writeln('    shape = "box"');
    buffer.writeln('    style = "filled"');
    buffer.writeln('    fillcolor = "#FFFFFF"');
    buffer.writeln('    color = "#000000"');
    buffer.writeln('    width = 1.3');
    buffer.writeln('    height = 0.8');
    buffer.writeln('  ];');

    buffer.writeln('  edge [');
    buffer.writeln('    fontname = "Arial"');
    buffer.writeln('    fontsize = 10');
    buffer.writeln('    style = "solid"');
    buffer.writeln('    color = "#707070"');
    buffer.writeln('  ];');
    buffer.writeln();

    // Find the system being detailed
    final softwareSystem = elements.firstWhere(
      (e) => e.id == view.softwareSystemId,
      orElse: () => const SoftwareSystem(id: '', name: ''),
    ) as SoftwareSystem;

    // Create cluster for the system if using clustering
    if (includeClusters) {
      buffer.writeln('  // System cluster');
      buffer.writeln('  subgraph cluster_${_sanitizeId(softwareSystem.id)} {');
      buffer.writeln('    label = "${_escapeLabel(softwareSystem.name)}";');
      if (includeCustomStyling) {
        buffer.writeln('    color = "#1168BD";');
        buffer.writeln('    fontcolor = "#1168BD";');
        buffer.writeln('    bgcolor = "#F7F7F7";');
      }

      // Define containers within the system
      buffer.writeln('    // Containers');
      for (final element in elements) {
        if (element is Container && element.parentId == softwareSystem.id) {
          buffer.write('    ${_sanitizeId(element.id)} [');
          if (includeDetailedLabels) {
            buffer.write(
                'label = "${_escapeLabel(element.name + '\\n[Container]')}');
            if (element.technology != null && element.technology!.isNotEmpty) {
              buffer.write('\\n[${_escapeLabel(element.technology!)}]');
            }
            if (element.description != null &&
                element.description!.isNotEmpty) {
              buffer.write('\\n\\n${_escapeLabel(element.description!)}');
            }
            buffer.write('"');
          } else {
            buffer
                .write('label = "${_escapeLabel(element.name)}\\n[Container]"');
          }

          if (includeCustomStyling) {
            buffer.write(', fillcolor = "#438DD5", fontcolor = "#FFFFFF"');
          }

          buffer.writeln(' ];');
        }
      }

      buffer.writeln('  }');
      buffer.writeln();
    } else {
      // Define containers without clustering
      buffer.writeln('  // Containers');
      for (final element in elements) {
        if (element is Container && element.parentId == softwareSystem.id) {
          buffer.write('  ${_sanitizeId(element.id)} [');
          if (includeDetailedLabels) {
            buffer.write(
                'label = "${_escapeLabel(element.name + '\\n[Container]')}');
            if (element.technology != null && element.technology!.isNotEmpty) {
              buffer.write('\\n[${_escapeLabel(element.technology!)}]');
            }
            if (element.description != null &&
                element.description!.isNotEmpty) {
              buffer.write('\\n\\n${_escapeLabel(element.description!)}');
            }
            buffer.write('"');
          } else {
            buffer
                .write('label = "${_escapeLabel(element.name)}\\n[Container]"');
          }

          if (includeCustomStyling) {
            buffer.write(', fillcolor = "#438DD5", fontcolor = "#FFFFFF"');
          }

          buffer.writeln(' ];');
        }
      }
      buffer.writeln();
    }

    // Define external elements
    buffer.writeln('  // External elements');
    for (final element in elements) {
      if (element is Person) {
        buffer.write('  ${_sanitizeId(element.id)} [');
        if (includeDetailedLabels) {
          buffer
              .write('label = "${_escapeLabel(element.name + '\\n[Person]')}');
          if (element.description != null && element.description!.isNotEmpty) {
            buffer.write('\\n\\n${_escapeLabel(element.description!)}');
          }
          buffer.write('"');
        } else {
          buffer.write('label = "${_escapeLabel(element.name)}\\n[Person]"');
        }

        if (includeCustomStyling) {
          buffer.write(
              ', shape = "ellipse", fillcolor = "#08427B", fontcolor = "#FFFFFF"');
        }

        buffer.writeln(' ];');
      } else if (element is SoftwareSystem && element.id != softwareSystem.id) {
        buffer.write('  ${_sanitizeId(element.id)} [');
        if (includeDetailedLabels) {
          buffer.write(
              'label = "${_escapeLabel(element.name + '\\n[Software System]')}');
          if (element.description != null && element.description!.isNotEmpty) {
            buffer.write('\\n\\n${_escapeLabel(element.description!)}');
          }
          buffer.write('"');
        } else {
          buffer.write(
              'label = "${_escapeLabel(element.name)}\\n[Software System]"');
        }

        if (includeCustomStyling) {
          buffer.write(', fillcolor = "#999999", fontcolor = "#FFFFFF"');
        }

        buffer.writeln(' ];');
      } else if (!includeClusters &&
          element is SoftwareSystem &&
          element.id == softwareSystem.id) {
        // Add the system itself if not using clustering
        buffer.write('  ${_sanitizeId(element.id)} [');
        if (includeDetailedLabels) {
          buffer.write(
              'label = "${_escapeLabel(element.name + '\\n[Software System]')}');
          if (element.description != null && element.description!.isNotEmpty) {
            buffer.write('\\n\\n${_escapeLabel(element.description!)}');
          }
          buffer.write('"');
        } else {
          buffer.write(
              'label = "${_escapeLabel(element.name)}\\n[Software System]"');
        }

        if (includeCustomStyling) {
          buffer.write(', fillcolor = "#1168BD", fontcolor = "#FFFFFF"');
        }

        buffer.writeln(' ];');
      }
    }
    buffer.writeln();

    // Define relationships
    buffer.writeln('  // Relationships');
    for (final relationship in relationships) {
      final sourceId = _sanitizeId(relationship.sourceId);
      final targetId = _sanitizeId(relationship.destinationId);
      final label = relationship.description;

      buffer.write('  ${sourceId} -> ${targetId}');
      if (label.isNotEmpty) {
        buffer.write(' [ label = "${_escapeLabel(label)}"');
        if (relationship.technology != null &&
            relationship.technology!.isNotEmpty) {
          buffer.write(
              ' headlabel = "${_escapeLabel('[' + relationship.technology! + ']')}"');
        }
        buffer.write(' ]');
      }
      buffer.writeln(';');
    }
    buffer.writeln();

    // Add legend
    buffer.writeln('  // Legend');
    buffer.writeln('  subgraph cluster_legend {');
    buffer.writeln('    label = "Legend";');
    buffer.writeln('    fontsize = 12;');
    buffer.writeln('    _legend [ shape = "none", label = <');
    buffer.writeln(
        '      <table border="0" cellborder="1" cellpadding="4" cellspacing="0">');
    buffer.writeln(
        '        <tr><td>Container diagram for ${softwareSystem.name}</td></tr>');
    buffer
        .writeln('        <tr><td>Generated by Flutter Structurizr</td></tr>');
    buffer.writeln('      </table>');
    buffer.writeln('    > ];');
    buffer.writeln('  }');

    // Close diagram
    buffer.writeln('}');

    return buffer.toString();
  }

  /// Generates a Component diagram in DOT format
  String _generateComponentDiagram(
    ComponentView view,
    List<Element> elements,
    List<Relationship> relationships,
  ) {
    final buffer = StringBuffer();

    // Start DOT diagram with type based on layout
    buffer.writeln('${_getLayoutName()} "${view.title ?? view.key}" {');

    // Add global attributes
    buffer.writeln('  // Global attributes');
    buffer.writeln('  graph [');
    buffer.writeln('    fontname = "Arial"');
    buffer.writeln('    fontsize = 14');
    buffer.writeln('    rankdir = ${_getRankDir()}');
    buffer.writeln('    ranksep = 1.0');
    buffer.writeln('    nodesep = 0.8');
    buffer.writeln('    pad = 0.4');
    buffer.writeln('    splines = "polyline"');
    buffer.writeln('    overlap = false');
    buffer.writeln('  ];');

    buffer.writeln('  node [');
    buffer.writeln('    fontname = "Arial"');
    buffer.writeln('    fontsize = 12');
    buffer.writeln('    shape = "box"');
    buffer.writeln('    style = "filled"');
    buffer.writeln('    fillcolor = "#FFFFFF"');
    buffer.writeln('    color = "#000000"');
    buffer.writeln('    width = 1.3');
    buffer.writeln('    height = 0.8');
    buffer.writeln('  ];');

    buffer.writeln('  edge [');
    buffer.writeln('    fontname = "Arial"');
    buffer.writeln('    fontsize = 10');
    buffer.writeln('    style = "solid"');
    buffer.writeln('    color = "#707070"');
    buffer.writeln('  ];');
    buffer.writeln();

    // Find the container being detailed
    final container = elements.firstWhere(
      (e) => e.id == view.containerId,
      orElse: () => const Container(id: '', name: '', parentId: ''),
    ) as Container;

    // Create cluster for the container if using clustering
    if (includeClusters) {
      buffer.writeln('  // Container cluster');
      buffer.writeln('  subgraph cluster_${_sanitizeId(container.id)} {');
      buffer.write('    label = "${_escapeLabel(container.name)}');
      if (container.technology != null && container.technology!.isNotEmpty) {
        buffer.write(' [${_escapeLabel(container.technology!)}]');
      }
      buffer.writeln('";');

      if (includeCustomStyling) {
        buffer.writeln('    color = "#438DD5";');
        buffer.writeln('    fontcolor = "#438DD5";');
        buffer.writeln('    bgcolor = "#F7F7F7";');
      }

      // Define components within the container
      buffer.writeln('    // Components');
      for (final element in elements) {
        if (element is Component && element.parentId == container.id) {
          buffer.write('    ${_sanitizeId(element.id)} [');
          if (includeDetailedLabels) {
            buffer.write(
                'label = "${_escapeLabel(element.name + '\\n[Component]')}');
            if (element.technology != null && element.technology!.isNotEmpty) {
              buffer.write('\\n[${_escapeLabel(element.technology!)}]');
            }
            if (element.description != null &&
                element.description!.isNotEmpty) {
              buffer.write('\\n\\n${_escapeLabel(element.description!)}');
            }
            buffer.write('"');
          } else {
            buffer
                .write('label = "${_escapeLabel(element.name)}\\n[Component]"');
          }

          if (includeCustomStyling) {
            buffer.write(', fillcolor = "#85BBF0", fontcolor = "#000000"');
          }

          buffer.writeln(' ];');
        }
      }

      buffer.writeln('  }');
      buffer.writeln();
    } else {
      // Define components without clustering
      buffer.writeln('  // Components');
      for (final element in elements) {
        if (element is Component && element.parentId == container.id) {
          buffer.write('  ${_sanitizeId(element.id)} [');
          if (includeDetailedLabels) {
            buffer.write(
                'label = "${_escapeLabel(element.name + '\\n[Component]')}');
            if (element.technology != null && element.technology!.isNotEmpty) {
              buffer.write('\\n[${_escapeLabel(element.technology!)}]');
            }
            if (element.description != null &&
                element.description!.isNotEmpty) {
              buffer.write('\\n\\n${_escapeLabel(element.description!)}');
            }
            buffer.write('"');
          } else {
            buffer
                .write('label = "${_escapeLabel(element.name)}\\n[Component]"');
          }

          if (includeCustomStyling) {
            buffer.write(', fillcolor = "#85BBF0", fontcolor = "#000000"');
          }

          buffer.writeln(' ];');
        }
      }
      buffer.writeln();
    }

    // Define external elements
    buffer.writeln('  // External elements');
    for (final element in elements) {
      if (element is Person) {
        buffer.write('  ${_sanitizeId(element.id)} [');
        if (includeDetailedLabels) {
          buffer
              .write('label = "${_escapeLabel(element.name + '\\n[Person]')}');
          if (element.description != null && element.description!.isNotEmpty) {
            buffer.write('\\n\\n${_escapeLabel(element.description!)}');
          }
          buffer.write('"');
        } else {
          buffer.write('label = "${_escapeLabel(element.name)}\\n[Person]"');
        }

        if (includeCustomStyling) {
          buffer.write(
              ', shape = "ellipse", fillcolor = "#08427B", fontcolor = "#FFFFFF"');
        }

        buffer.writeln(' ];');
      } else if (element is SoftwareSystem) {
        buffer.write('  ${_sanitizeId(element.id)} [');
        if (includeDetailedLabels) {
          buffer.write(
              'label = "${_escapeLabel(element.name + '\\n[Software System]')}');
          if (element.description != null && element.description!.isNotEmpty) {
            buffer.write('\\n\\n${_escapeLabel(element.description!)}');
          }
          buffer.write('"');
        } else {
          buffer.write(
              'label = "${_escapeLabel(element.name)}\\n[Software System]"');
        }

        if (includeCustomStyling) {
          buffer.write(', fillcolor = "#1168BD", fontcolor = "#FFFFFF"');
        }

        buffer.writeln(' ];');
      } else if (element is Container && element.id != container.id) {
        buffer.write('  ${_sanitizeId(element.id)} [');
        if (includeDetailedLabels) {
          buffer.write(
              'label = "${_escapeLabel(element.name + '\\n[Container]')}');
          if (element.technology != null && element.technology!.isNotEmpty) {
            buffer.write('\\n[${_escapeLabel(element.technology!)}]');
          }
          if (element.description != null && element.description!.isNotEmpty) {
            buffer.write('\\n\\n${_escapeLabel(element.description!)}');
          }
          buffer.write('"');
        } else {
          buffer.write('label = "${_escapeLabel(element.name)}\\n[Container]"');
        }

        if (includeCustomStyling) {
          buffer.write(', fillcolor = "#438DD5", fontcolor = "#FFFFFF"');
        }

        buffer.writeln(' ];');
      } else if (!includeClusters &&
          element is Container &&
          element.id == container.id) {
        // Add the container itself if not using clustering
        buffer.write('  ${_sanitizeId(element.id)} [');
        if (includeDetailedLabels) {
          buffer.write(
              'label = "${_escapeLabel(element.name + '\\n[Container]')}');
          if (element.technology != null && element.technology!.isNotEmpty) {
            buffer.write('\\n[${_escapeLabel(element.technology!)}]');
          }
          if (element.description != null && element.description!.isNotEmpty) {
            buffer.write('\\n\\n${_escapeLabel(element.description!)}');
          }
          buffer.write('"');
        } else {
          buffer.write('label = "${_escapeLabel(element.name)}\\n[Container]"');
        }

        if (includeCustomStyling) {
          buffer.write(', fillcolor = "#438DD5", fontcolor = "#FFFFFF"');
        }

        buffer.writeln(' ];');
      }
    }
    buffer.writeln();

    // Define relationships
    buffer.writeln('  // Relationships');
    for (final relationship in relationships) {
      final sourceId = _sanitizeId(relationship.sourceId);
      final targetId = _sanitizeId(relationship.destinationId);
      final label = relationship.description;

      buffer.write('  ${sourceId} -> ${targetId}');
      if (label.isNotEmpty) {
        buffer.write(' [ label = "${_escapeLabel(label)}"');
        if (relationship.technology != null &&
            relationship.technology!.isNotEmpty) {
          buffer.write(
              ' headlabel = "${_escapeLabel('[' + relationship.technology! + ']')}"');
        }
        buffer.write(' ]');
      }
      buffer.writeln(';');
    }
    buffer.writeln();

    // Add legend
    buffer.writeln('  // Legend');
    buffer.writeln('  subgraph cluster_legend {');
    buffer.writeln('    label = "Legend";');
    buffer.writeln('    fontsize = 12;');
    buffer.writeln('    _legend [ shape = "none", label = <');
    buffer.writeln(
        '      <table border="0" cellborder="1" cellpadding="4" cellspacing="0">');
    buffer.writeln(
        '        <tr><td>Component diagram for ${container.name}</td></tr>');
    buffer
        .writeln('        <tr><td>Generated by Flutter Structurizr</td></tr>');
    buffer.writeln('      </table>');
    buffer.writeln('    > ];');
    buffer.writeln('  }');

    // Close diagram
    buffer.writeln('}');

    return buffer.toString();
  }

  /// Generates a Deployment diagram in DOT format
  String _generateDeploymentDiagram(
    DeploymentView view,
    List<Element> elements,
    List<Relationship> relationships,
  ) {
    final buffer = StringBuffer();

    // Start DOT diagram with type based on layout
    buffer.writeln(
        '${_getLayoutName()} "${view.title ?? view.key} (${view.environment})" {');

    // Add global attributes
    buffer.writeln('  // Global attributes');
    buffer.writeln('  graph [');
    buffer.writeln('    fontname = "Arial"');
    buffer.writeln('    fontsize = 14');
    buffer.writeln('    rankdir = ${_getRankDir()}');
    buffer.writeln('    ranksep = 1.0');
    buffer.writeln('    nodesep = 0.8');
    buffer.writeln('    pad = 0.4');
    buffer.writeln('    splines = "polyline"');
    buffer.writeln('    overlap = false');
    buffer.writeln('  ];');

    buffer.writeln('  node [');
    buffer.writeln('    fontname = "Arial"');
    buffer.writeln('    fontsize = 12');
    buffer.writeln('    shape = "box"');
    buffer.writeln('    style = "filled"');
    buffer.writeln('    fillcolor = "#FFFFFF"');
    buffer.writeln('    color = "#000000"');
    buffer.writeln('    width = 1.3');
    buffer.writeln('    height = 0.8');
    buffer.writeln('  ];');

    buffer.writeln('  edge [');
    buffer.writeln('    fontname = "Arial"');
    buffer.writeln('    fontsize = 10');
    buffer.writeln('    style = "solid"');
    buffer.writeln('    color = "#707070"');
    buffer.writeln('  ];');
    buffer.writeln();

    // Process deployment nodes
    final deploymentNodes = elements
        .whereType<DeploymentNode>()
        .where((node) => node.environment == view.environment)
        .toList();

    // Generate deployment node clusters
    for (final node in deploymentNodes) {
      _processDeploymentNode(buffer, node, elements, '  ');
    }

    // Define relationships
    buffer.writeln('  // Relationships');
    for (final relationship in relationships) {
      final sourceId = _sanitizeId(relationship.sourceId);
      final targetId = _sanitizeId(relationship.destinationId);
      final label = relationship.description;

      buffer.write('  ${sourceId} -> ${targetId}');
      if (label.isNotEmpty) {
        buffer.write(' [ label = "${_escapeLabel(label)}"');
        if (relationship.technology != null &&
            relationship.technology!.isNotEmpty) {
          buffer.write(
              ' headlabel = "${_escapeLabel('[' + relationship.technology! + ']')}"');
        }
        buffer.write(' ]');
      }
      buffer.writeln(';');
    }
    buffer.writeln();

    // Add legend
    buffer.writeln('  // Legend');
    buffer.writeln('  subgraph cluster_legend {');
    buffer.writeln('    label = "Legend";');
    buffer.writeln('    fontsize = 12;');
    buffer.writeln('    _legend [ shape = "none", label = <');
    buffer.writeln(
        '      <table border="0" cellborder="1" cellpadding="4" cellspacing="0">');
    buffer.writeln(
        '        <tr><td>Deployment diagram for ${view.environment}</td></tr>');
    buffer
        .writeln('        <tr><td>Generated by Flutter Structurizr</td></tr>');
    buffer.writeln('      </table>');
    buffer.writeln('    > ];');
    buffer.writeln('  }');

    // Close diagram
    buffer.writeln('}');

    return buffer.toString();
  }

  /// Generates a deployment node cluster for deployment diagrams
  void _processDeploymentNode(StringBuffer buffer, DeploymentNode node,
      List<Element> elements, String indent) {
    buffer.writeln('${indent}// Deployment Node: ${node.name}');
    buffer.writeln('${indent}subgraph cluster_${_sanitizeId(node.id)} {');
    buffer.write('${indent}  label = "${_escapeLabel(node.name)}');
    if (node.technology != null && node.technology!.isNotEmpty) {
      buffer.write(' [${_escapeLabel(node.technology!)}]');
    }
    buffer.writeln('";');

    if (includeCustomStyling) {
      buffer.writeln('${indent}  color = "#888888";');
      buffer.writeln('${indent}  fontcolor = "#000000";');
      buffer.writeln('${indent}  bgcolor = "#FFFFFF";');
    }

    // Add infrastructure nodes
    buffer.writeln('${indent}  // Infrastructure nodes');
    for (final infraNode in node.infrastructureNodes) {
      buffer.write('${indent}  ${_sanitizeId(infraNode.id)} [');
      if (includeDetailedLabels) {
        buffer.write(
            'label = "${_escapeLabel(infraNode.name + '\\n[Infrastructure Node]')}');
        if (infraNode.technology != null && infraNode.technology!.isNotEmpty) {
          buffer.write('\\n[${_escapeLabel(infraNode.technology!)}]');
        }
        if (infraNode.description != null &&
            infraNode.description!.isNotEmpty) {
          buffer.write('\\n\\n${_escapeLabel(infraNode.description!)}');
        }
        buffer.write('"');
      } else {
        buffer.write(
            'label = "${_escapeLabel(infraNode.name)}\\n[Infrastructure Node]"');
      }

      if (includeCustomStyling) {
        buffer.write(', fillcolor = "#85BBF0", fontcolor = "#000000"');
      }

      buffer.writeln(' ];');
    }

    // Add container instances
    buffer.writeln('${indent}  // Container instances');
    for (final containerInstance in node.containerInstances) {
      buffer.write('${indent}  ${_sanitizeId(containerInstance.id)} [');
      buffer.write(
          'label = "${_escapeLabel(containerInstance.name)}\\n[Container Instance]"');

      if (includeCustomStyling) {
        buffer.write(', fillcolor = "#438DD5", fontcolor = "#FFFFFF"');
      }

      buffer.writeln(' ];');
    }

    // Add software system instances
    buffer.writeln('${indent}  // Software system instances');
    for (final systemInstance in node.softwareSystemInstances) {
      buffer.write('${indent}  ${_sanitizeId(systemInstance.id)} [');
      buffer.write(
          'label = "${_escapeLabel(systemInstance.name)}\\n[Software System Instance]"');

      if (includeCustomStyling) {
        buffer.write(', fillcolor = "#1168BD", fontcolor = "#FFFFFF"');
      }

      buffer.writeln(' ];');
    }

    // Process child nodes recursively
    for (final childNode in node.children) {
      _processDeploymentNode(buffer, childNode, elements, indent + '  ');
    }

    buffer.writeln('${indent}}');
  }

  /// Generates a generic diagram for any view type in DOT format
  String _generateGenericDiagram(
    View view,
    List<Element> elements,
    List<Relationship> relationships,
  ) {
    final buffer = StringBuffer();

    // Start DOT diagram with type based on layout
    buffer.writeln('${_getLayoutName()} "${view.title ?? view.key}" {');

    // Add global attributes
    buffer.writeln('  // Global attributes');
    buffer.writeln('  graph [');
    buffer.writeln('    fontname = "Arial"');
    buffer.writeln('    fontsize = 14');
    buffer.writeln('    rankdir = ${_getRankDir()}');
    buffer.writeln('    ranksep = 1.0');
    buffer.writeln('    nodesep = 0.8');
    buffer.writeln('    pad = 0.4');
    buffer.writeln('    splines = "polyline"');
    buffer.writeln('    overlap = false');
    buffer.writeln('  ];');

    buffer.writeln('  node [');
    buffer.writeln('    fontname = "Arial"');
    buffer.writeln('    fontsize = 12');
    buffer.writeln('    shape = "box"');
    buffer.writeln('    style = "filled"');
    buffer.writeln('    fillcolor = "#FFFFFF"');
    buffer.writeln('    color = "#000000"');
    buffer.writeln('    width = 1.3');
    buffer.writeln('    height = 0.8');
    buffer.writeln('  ];');

    buffer.writeln('  edge [');
    buffer.writeln('    fontname = "Arial"');
    buffer.writeln('    fontsize = 10');
    buffer.writeln('    style = "solid"');
    buffer.writeln('    color = "#707070"');
    buffer.writeln('  ];');
    buffer.writeln();

    // Define all elements
    buffer.writeln('  // Elements');
    for (final element in elements) {
      if (element is Person) {
        buffer.write('  ${_sanitizeId(element.id)} [');
        buffer.write('label = "${_escapeLabel(element.name)}\\n[Person]"');

        if (includeCustomStyling) {
          buffer.write(
              ', shape = "ellipse", fillcolor = "#08427B", fontcolor = "#FFFFFF"');
        }

        buffer.writeln(' ];');
      } else if (element is SoftwareSystem) {
        buffer.write('  ${_sanitizeId(element.id)} [');
        buffer.write(
            'label = "${_escapeLabel(element.name)}\\n[Software System]"');

        if (includeCustomStyling) {
          buffer.write(', fillcolor = "#1168BD", fontcolor = "#FFFFFF"');
        }

        buffer.writeln(' ];');
      } else if (element is Container) {
        buffer.write('  ${_sanitizeId(element.id)} [');
        if (includeDetailedLabels &&
            element.technology != null &&
            element.technology!.isNotEmpty) {
          buffer.write(
              'label = "${_escapeLabel(element.name)}\\n[Container]\\n[${_escapeLabel(element.technology!)}]"');
        } else {
          buffer.write('label = "${_escapeLabel(element.name)}\\n[Container]"');
        }

        if (includeCustomStyling) {
          buffer.write(', fillcolor = "#438DD5", fontcolor = "#FFFFFF"');
        }

        buffer.writeln(' ];');
      } else if (element is Component) {
        buffer.write('  ${_sanitizeId(element.id)} [');
        if (includeDetailedLabels &&
            element.technology != null &&
            element.technology!.isNotEmpty) {
          buffer.write(
              'label = "${_escapeLabel(element.name)}\\n[Component]\\n[${_escapeLabel(element.technology!)}]"');
        } else {
          buffer.write('label = "${_escapeLabel(element.name)}\\n[Component]"');
        }

        if (includeCustomStyling) {
          buffer.write(', fillcolor = "#85BBF0", fontcolor = "#000000"');
        }

        buffer.writeln(' ];');
      } else if (element is DeploymentNode) {
        buffer.write('  ${_sanitizeId(element.id)} [');
        if (includeDetailedLabels &&
            element.technology != null &&
            element.technology!.isNotEmpty) {
          buffer.write(
              'label = "${_escapeLabel(element.name)}\\n[Deployment Node]\\n[${_escapeLabel(element.technology!)}]"');
        } else {
          buffer.write(
              'label = "${_escapeLabel(element.name)}\\n[Deployment Node]"');
        }

        if (includeCustomStyling) {
          buffer.write(
              ', shape = "folder", fillcolor = "#999999", fontcolor = "#FFFFFF"');
        }

        buffer.writeln(' ];');
      } else {
        buffer.writeln(
            '  ${_sanitizeId(element.id)} [ label = "${_escapeLabel(element.name)}" ];');
      }
    }
    buffer.writeln();

    // Define relationships
    buffer.writeln('  // Relationships');
    for (final relationship in relationships) {
      final sourceId = _sanitizeId(relationship.sourceId);
      final targetId = _sanitizeId(relationship.destinationId);
      final label = relationship.description;

      buffer.write('  ${sourceId} -> ${targetId}');
      if (label.isNotEmpty) {
        buffer.write(' [ label = "${_escapeLabel(label)}"');
        if (relationship.technology != null &&
            relationship.technology!.isNotEmpty) {
          buffer.write(
              ' headlabel = "${_escapeLabel('[' + relationship.technology! + ']')}"');
        }
        buffer.write(' ]');
      }
      buffer.writeln(';');
    }
    buffer.writeln();

    // Add legend
    buffer.writeln('  // Legend');
    buffer.writeln('  subgraph cluster_legend {');
    buffer.writeln('    label = "Legend";');
    buffer.writeln('    fontsize = 12;');
    buffer.writeln('    _legend [ shape = "none", label = <');
    buffer.writeln(
        '      <table border="0" cellborder="1" cellpadding="4" cellspacing="0">');
    buffer.writeln('        <tr><td>Diagram for ${view.key}</td></tr>');
    buffer
        .writeln('        <tr><td>Generated by Flutter Structurizr</td></tr>');
    buffer.writeln('      </table>');
    buffer.writeln('    > ];');
    buffer.writeln('  }');

    // Close diagram
    buffer.writeln('}');

    return buffer.toString();
  }

  /// Gets the layout algorithm name for DOT
  String _getLayoutName() {
    switch (layout) {
      case DotLayout.dot:
        return 'digraph';
      case DotLayout.neato:
        return 'graph';
      case DotLayout.twopi:
        return 'digraph';
      case DotLayout.circo:
        return 'digraph';
      case DotLayout.fdp:
        return 'graph';
      case DotLayout.sfdp:
        return 'graph';
      case DotLayout.osage:
        return 'graph';
      case DotLayout.patchwork:
        return 'graph';
    }
  }

  /// Gets the rank direction for DOT
  String _getRankDir() {
    switch (rankDirection) {
      case DotRankDirection.topToBottom:
        return 'TB';
      case DotRankDirection.bottomToTop:
        return 'BT';
      case DotRankDirection.leftToRight:
        return 'LR';
      case DotRankDirection.rightToLeft:
        return 'RL';
    }
  }

  /// Escapes a label for use in DOT
  String _escapeLabel(String label) {
    return label
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n');
  }

  /// Sanitizes an ID to be valid in DOT
  String _sanitizeId(String id) {
    // Replace invalid characters with underscores
    return id.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
  }
}
