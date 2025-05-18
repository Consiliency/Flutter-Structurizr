import 'dart:async';

import 'package:flutter/material.dart' hide Element, Container, View;
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/infrastructure/export/diagram_exporter.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:logging/logging.dart';

final _logger = Logger('PlantUMLExporter');

/// The style of PlantUML to generate
enum PlantUmlStyle {
  /// Standard PlantUML
  standard,

  /// C4-style PlantUML (uses C4 macros)
  c4,

  /// C4-style PlantUML with additional styling
  c4puml,
}

/// An exporter for PlantUML diagram format
class PlantUmlExporter implements DiagramExporter<String> {
  /// The PlantUML style to use
  final PlantUmlStyle style;

  /// Whether to include stereotypes in the output
  final bool includeStereotypes;

  /// Whether to include notes in the output
  final bool includeNotes;

  /// Whether to include legend in the output
  final bool includeLegend;

  /// Progress callback for the export operation
  final ValueChanged<double>? onProgress;

  /// Creates a new PlantUML exporter
  const PlantUmlExporter({
    this.style = PlantUmlStyle.standard,
    this.includeStereotypes = true,
    this.includeNotes = true,
    this.includeLegend = true,
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

      // Generate PlantUML content based on view type
      String plantUmlContent = '';
      if (view is SystemContextView) {
        plantUmlContent =
            _generateSystemContextDiagram(view, elements, relationships);
      } else if (view is ContainerView) {
        plantUmlContent =
            _generateContainerDiagram(view, elements, relationships);
      } else if (view is ComponentView) {
        plantUmlContent =
            _generateComponentDiagram(view, elements, relationships);
      } else if (view is DeploymentView) {
        plantUmlContent =
            _generateDeploymentDiagram(view, elements, relationships);
      } else {
        // Default generic diagram
        plantUmlContent =
            _generateGenericDiagram(view, elements, relationships);
      }

      // Report completion
      onProgress?.call(1.0);

      return plantUmlContent;
    } catch (e) {
      throw Exception('Failed to export diagram to PlantUML: $e');
    }
  }

  /// Finds a view in the workspace by key
  View? _findViewByKey(Workspace workspace, String key) {
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
  List<Element> _getElementsInView(View view, Workspace workspace) {
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
  List<Relationship> _getRelationshipsInView(View view, Workspace workspace) {
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

  /// Generates a System Context diagram in PlantUML format
  String _generateSystemContextDiagram(
    SystemContextView view,
    List<Element> elements,
    List<Relationship> relationships,
  ) {
    final buffer = StringBuffer();

    // Start PlantUML diagram
    buffer.writeln('@startuml');

    // Add title
    buffer.writeln('title ${view.title ?? view.key}');
    buffer.writeln();

    // Include appropriate C4 library if using C4 style
    if (style == PlantUmlStyle.c4 || style == PlantUmlStyle.c4puml) {
      buffer.writeln('!include <C4/C4_Context>');
      if (style == PlantUmlStyle.c4puml) {
        buffer.writeln('!include <C4/C4_Container>');
        buffer.writeln(
            '!include https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/skinparam.puml');
      }
      buffer.writeln();
    }

    // Define elements
    buffer.writeln('/' + '* Elements */');
    for (final element in elements) {
      if (element is Person) {
        _writePersonDefinition(buffer, element);
      } else if (element is SoftwareSystem) {
        _writeSystemDefinition(buffer, element);
      }
    }
    buffer.writeln();

    // Define relationships
    buffer.writeln('/' + '* Relationships */');
    for (final relationship in relationships) {
      _writeRelationship(buffer, relationship, elements);
    }
    buffer.writeln();

    // Add legend if requested
    if (includeLegend) {
      buffer.writeln('legend right');
      buffer.writeln('  System Context diagram for ${view.softwareSystemId}');
      buffer.writeln('  Generated by Flutter Structurizr');
      buffer.writeln('endlegend');
    }

    // End diagram
    buffer.writeln('@enduml');

    return buffer.toString();
  }

  /// Generates a Container diagram in PlantUML format
  String _generateContainerDiagram(
    ContainerView view,
    List<Element> elements,
    List<Relationship> relationships,
  ) {
    final buffer = StringBuffer();

    // Start PlantUML diagram
    buffer.writeln('@startuml');

    // Add title
    buffer.writeln('title ${view.title ?? view.key}');
    buffer.writeln();

    // Include appropriate C4 library if using C4 style
    if (style == PlantUmlStyle.c4 || style == PlantUmlStyle.c4puml) {
      buffer.writeln('!include <C4/C4_Container>');
      if (style == PlantUmlStyle.c4puml) {
        buffer.writeln(
            '!include https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/skinparam.puml');
      }
      buffer.writeln();
    }

    // Define elements
    buffer.writeln('/' + '* Elements */');
    for (final element in elements) {
      if (element is Person) {
        _writePersonDefinition(buffer, element);
      } else if (element is SoftwareSystem) {
        // Check if this is the system being detailed
        if (element.id == view.softwareSystemId) {
          // If using C4, define the system boundary
          if (style == PlantUmlStyle.c4 || style == PlantUmlStyle.c4puml) {
            buffer.writeln(
                'System_Boundary(${_sanitizeId(element.id)}_boundary, "${element.name}") {');

            // Add containers inside the boundary
            for (final container in element.containers) {
              if (elements.any((e) => e.id == container.id)) {
                _writeContainerDefinition(buffer, container, indentation: '  ');
              }
            }

            buffer.writeln('}');
          } else {
            // Standard PlantUML without C4
            _writeSystemDefinition(buffer, element);

            // Add containers
            for (final container in element.containers) {
              if (elements.any((e) => e.id == container.id)) {
                _writeContainerDefinition(buffer, container);
              }
            }
          }
        } else {
          // External system - just add it normally
          _writeSystemDefinition(buffer, element);
        }
      }
    }
    buffer.writeln();

    // Define relationships
    buffer.writeln('/' + '* Relationships */');
    for (final relationship in relationships) {
      _writeRelationship(buffer, relationship, elements);
    }
    buffer.writeln();

    // Add legend if requested
    if (includeLegend) {
      buffer.writeln('legend right');
      buffer.writeln('  Container diagram for ${view.softwareSystemId}');
      buffer.writeln('  Generated by Flutter Structurizr');
      buffer.writeln('endlegend');
    }

    // End diagram
    buffer.writeln('@enduml');

    return buffer.toString();
  }

  /// Generates a Component diagram in PlantUML format
  String _generateComponentDiagram(
    ComponentView view,
    List<Element> elements,
    List<Relationship> relationships,
  ) {
    final buffer = StringBuffer();

    // Start PlantUML diagram
    buffer.writeln('@startuml');

    // Add title
    buffer.writeln('title ${view.title ?? view.key}');
    buffer.writeln();

    // Include appropriate C4 library if using C4 style
    if (style == PlantUmlStyle.c4 || style == PlantUmlStyle.c4puml) {
      buffer.writeln('!include <C4/C4_Component>');
      if (style == PlantUmlStyle.c4puml) {
        buffer.writeln(
            '!include https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/skinparam.puml');
      }
      buffer.writeln();
    }

    // Define elements
    buffer.writeln('/' + '* Elements */');

    // Find the container being detailed
    final containerElements =
        elements.where((e) => e.id == view.containerId).toList();
    if (containerElements.isNotEmpty && containerElements.first is Container) {
      final container = containerElements.first as Container;

      // If using C4, define the container boundary
      if (style == PlantUmlStyle.c4 || style == PlantUmlStyle.c4puml) {
        buffer.writeln(
            'Container_Boundary(${_sanitizeId(container.id)}_boundary, "${container.name}") {');

        // Add components inside the boundary
        for (final component in container.components) {
          if (elements.any((e) => e.id == component.id)) {
            _writeComponentDefinition(buffer, component, indentation: '  ');
          }
        }

        buffer.writeln('}');
      } else {
        // Standard PlantUML without C4
        _writeContainerDefinition(buffer, container);

        // Add components
        for (final component in container.components) {
          if (elements.any((e) => e.id == component.id)) {
            _writeComponentDefinition(buffer, component);
          }
        }
      }
    }

    // Add other elements (like external systems, people, etc.)
    for (final element in elements) {
      if (element.id != view.containerId && !(element is Component)) {
        if (element is Person) {
          _writePersonDefinition(buffer, element);
        } else if (element is SoftwareSystem) {
          _writeSystemDefinition(buffer, element);
        } else if (element is Container) {
          _writeContainerDefinition(buffer, element);
        }
      }
    }
    buffer.writeln();

    // Define relationships
    buffer.writeln('/' + '* Relationships */');
    for (final relationship in relationships) {
      _writeRelationship(buffer, relationship, elements);
    }
    buffer.writeln();

    // Add legend if requested
    if (includeLegend) {
      buffer.writeln('legend right');
      buffer.writeln('  Component diagram for ${view.containerId}');
      buffer.writeln('  Generated by Flutter Structurizr');
      buffer.writeln('endlegend');
    }

    // End diagram
    buffer.writeln('@enduml');

    return buffer.toString();
  }

  /// Generates a Deployment diagram in PlantUML format
  String _generateDeploymentDiagram(
    DeploymentView view,
    List<Element> elements,
    List<Relationship> relationships,
  ) {
    final buffer = StringBuffer();

    // Start PlantUML diagram
    buffer.writeln('@startuml');

    // Add title
    buffer.writeln('title ${view.title ?? view.key} (${view.environment})');
    buffer.writeln();

    // Include appropriate C4 library if using C4 style
    if (style == PlantUmlStyle.c4 || style == PlantUmlStyle.c4puml) {
      buffer.writeln('!include <C4/C4_Deployment>');
      if (style == PlantUmlStyle.c4puml) {
        buffer.writeln(
            '!include https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/skinparam.puml');
      }
      buffer.writeln();
    }

    // Define elements
    buffer.writeln('/' + '* Elements */');
    for (final element in elements) {
      if (element is DeploymentNode) {
        _writeDeploymentNodeDefinition(buffer, element, elements);
      }
    }
    buffer.writeln();

    // Define relationships
    buffer.writeln('/' + '* Relationships */');
    for (final relationship in relationships) {
      _writeRelationship(buffer, relationship, elements);
    }
    buffer.writeln();

    // Add legend if requested
    if (includeLegend) {
      buffer.writeln('legend right');
      buffer.writeln('  Deployment diagram for ${view.environment}');
      buffer.writeln('  Generated by Flutter Structurizr');
      buffer.writeln('endlegend');
    }

    // End diagram
    buffer.writeln('@enduml');

    return buffer.toString();
  }

  /// Generates a generic diagram for any view type in PlantUML format
  String _generateGenericDiagram(
    View view,
    List<Element> elements,
    List<Relationship> relationships,
  ) {
    final buffer = StringBuffer();

    // Start PlantUML diagram
    buffer.writeln('@startuml');

    // Add title
    buffer.writeln('title ${view.title ?? view.key}');
    buffer.writeln();

    // Standard PlantUML settings
    buffer.writeln('skinparam monochrome true');
    buffer.writeln('skinparam shadowing false');
    buffer.writeln('skinparam defaultFontName Arial');
    buffer.writeln('skinparam defaultFontSize 12');
    buffer.writeln();

    // Define all elements
    buffer.writeln('/' + '* Elements */');
    for (final element in elements) {
      if (element is Person) {
        buffer.writeln('actor "${element.name}" as ${_sanitizeId(element.id)}');
      } else if (element is SoftwareSystem) {
        buffer.writeln(
            'rectangle "${element.name}" as ${_sanitizeId(element.id)}');
      } else if (element is Container) {
        buffer.writeln(
            'component "${element.name}" as ${_sanitizeId(element.id)}');
      } else if (element is Component) {
        buffer.writeln('card "${element.name}" as ${_sanitizeId(element.id)}');
      } else if (element is DeploymentNode) {
        buffer.writeln('node "${element.name}" as ${_sanitizeId(element.id)}');
      } else {
        buffer.writeln(
            'rectangle "${element.name}" as ${_sanitizeId(element.id)}');
      }
    }
    buffer.writeln();

    // Define relationships
    buffer.writeln('/' + '* Relationships */');
    for (final relationship in relationships) {
      final sourceId = _sanitizeId(relationship.sourceId);
      final targetId = _sanitizeId(relationship.destinationId);
      buffer.writeln('$sourceId --> $targetId : "${relationship.description}"');
    }
    buffer.writeln();

    // Add legend if requested
    if (includeLegend) {
      buffer.writeln('legend right');
      buffer.writeln('  Diagram for ${view.key}');
      buffer.writeln('  Generated by Flutter Structurizr');
      buffer.writeln('endlegend');
    }

    // End diagram
    buffer.writeln('@enduml');

    return buffer.toString();
  }

  /// Writes a Person definition to the buffer
  void _writePersonDefinition(StringBuffer buffer, Person person,
      {String indentation = ''}) {
    if (style == PlantUmlStyle.c4 || style == PlantUmlStyle.c4puml) {
      buffer.writeln(
          '${indentation}Person(${_sanitizeId(person.id)}, "${person.name}", '
          '"${person.description ?? ''}")');
    } else {
      buffer.writeln(
          '${indentation}actor "${person.name}" as ${_sanitizeId(person.id)}');
      if (person.description != null && includeNotes) {
        buffer.writeln('${indentation}note right of ${_sanitizeId(person.id)}');
        buffer.writeln('${indentation}  ${person.description}');
        buffer.writeln('${indentation}end note');
      }
    }
  }

  /// Writes a SoftwareSystem definition to the buffer
  void _writeSystemDefinition(StringBuffer buffer, SoftwareSystem system,
      {String indentation = ''}) {
    if (style == PlantUmlStyle.c4 || style == PlantUmlStyle.c4puml) {
      final systemType =
          system.location == 'External' ? 'System_Ext' : 'System';
      buffer.writeln(
          '${indentation}$systemType(${_sanitizeId(system.id)}, "${system.name}", '
          '"${system.description ?? ''}")');
    } else {
      buffer.writeln(
          '${indentation}rectangle "${system.name}" as ${_sanitizeId(system.id)}');
      if (system.description != null && includeNotes) {
        buffer.writeln('${indentation}note right of ${_sanitizeId(system.id)}');
        buffer.writeln('${indentation}  ${system.description}');
        buffer.writeln('${indentation}end note');
      }
    }
  }

  /// Writes a Container definition to the buffer
  void _writeContainerDefinition(StringBuffer buffer, Container container,
      {String indentation = ''}) {
    if (style == PlantUmlStyle.c4 || style == PlantUmlStyle.c4puml) {
      buffer.writeln(
          '${indentation}Container(${_sanitizeId(container.id)}, "${container.name}", '
          '"${container.technology ?? ''}", "${container.description ?? ''}")');
    } else {
      buffer.writeln(
          '${indentation}component "${container.name}" as ${_sanitizeId(container.id)}');
      if (container.description != null && includeNotes) {
        buffer.writeln(
            '${indentation}note right of ${_sanitizeId(container.id)}');
        buffer.writeln('${indentation}  ${container.description}');
        if (container.technology != null) {
          buffer.writeln('${indentation}  [${container.technology}]');
        }
        buffer.writeln('${indentation}end note');
      }
    }
  }

  /// Writes a Component definition to the buffer
  void _writeComponentDefinition(StringBuffer buffer, Component component,
      {String indentation = ''}) {
    if (style == PlantUmlStyle.c4 || style == PlantUmlStyle.c4puml) {
      buffer.writeln(
          '${indentation}Component(${_sanitizeId(component.id)}, "${component.name}", '
          '"${component.technology ?? ''}", "${component.description ?? ''}")');
    } else {
      buffer.writeln(
          '${indentation}card "${component.name}" as ${_sanitizeId(component.id)}');
      if (component.description != null && includeNotes) {
        buffer.writeln(
            '${indentation}note right of ${_sanitizeId(component.id)}');
        buffer.writeln('${indentation}  ${component.description}');
        if (component.technology != null) {
          buffer.writeln('${indentation}  [${component.technology}]');
        }
        buffer.writeln('${indentation}end note');
      }
    }
  }

  /// Writes a DeploymentNode definition to the buffer
  void _writeDeploymentNodeDefinition(
      StringBuffer buffer, DeploymentNode node, List<Element> elements,
      {String indentation = ''}) {
    if (style == PlantUmlStyle.c4 || style == PlantUmlStyle.c4puml) {
      buffer.writeln(
          '${indentation}Deployment_Node(${_sanitizeId(node.id)}, "${node.name}", '
          '"${node.technology ?? ''}")');

      // Add contained elements (nested nodes, container instances, etc.)
      final childIndent = '$indentation  ';

      // Add container instances
      for (final instance in node.containerInstances) {
        if (elements.any((e) => e.id == instance.id)) {
          buffer.writeln('${childIndent}Container(${_sanitizeId(instance.id)}, '
              '"Container Instance", "", "")');
        }
      }

      // Add software system instances
      for (final instance in node.softwareSystemInstances) {
        if (elements.any((e) => e.id == instance.id)) {
          buffer.writeln('${childIndent}SystemDb(${_sanitizeId(instance.id)}, '
              '"System Instance", "", "")');
        }
      }

      // Add infrastructure nodes
      for (final infra in node.infrastructureNodes) {
        if (elements.any((e) => e.id == infra.id)) {
          buffer.writeln(
              '${childIndent}Infrastructure_Node(${_sanitizeId(infra.id)}, '
              '"${infra.name}", "${infra.technology ?? ''}")');
        }
      }

      // Add child nodes recursively
      for (final child in node.children) {
        if (elements.any((e) => e.id == child.id)) {
          _writeDeploymentNodeDefinition(buffer, child, elements,
              indentation: childIndent);
        }
      }
    } else {
      // Standard PlantUML
      buffer.writeln(
          '${indentation}node "${node.name}" as ${_sanitizeId(node.id)} {');

      // Add contained elements
      final childIndent = '$indentation  ';

      // Add container instances
      for (final instance in node.containerInstances) {
        if (elements.any((e) => e.id == instance.id)) {
          buffer.writeln(
              '${childIndent}component "Container Instance" as ${_sanitizeId(instance.id)}');
        }
      }

      // Add software system instances
      for (final instance in node.softwareSystemInstances) {
        if (elements.any((e) => e.id == instance.id)) {
          buffer.writeln(
              '${childIndent}database "System Instance" as ${_sanitizeId(instance.id)}');
        }
      }

      // Add infrastructure nodes
      for (final infra in node.infrastructureNodes) {
        if (elements.any((e) => e.id == infra.id)) {
          buffer.writeln(
              '${childIndent}card "${infra.name}" as ${_sanitizeId(infra.id)}');
        }
      }

      // Add child nodes recursively
      for (final child in node.children) {
        if (elements.any((e) => e.id == child.id)) {
          _writeDeploymentNodeDefinition(buffer, child, elements,
              indentation: childIndent);
        }
      }

      buffer.writeln('${indentation}}');
    }
  }

  /// Writes a relationship definition to the buffer
  void _writeRelationship(
      StringBuffer buffer, Relationship relationship, List<Element> elements,
      {String indentation = ''}) {
    final sourceId = _sanitizeId(relationship.sourceId);
    final targetId = _sanitizeId(relationship.destinationId);

    if (style == PlantUmlStyle.c4 || style == PlantUmlStyle.c4puml) {
      buffer.writeln(
          '${indentation}Rel($sourceId, $targetId, "${relationship.description}", '
          '"${relationship.technology ?? ''}")');
    } else {
      buffer.writeln(
          '${indentation}$sourceId --> $targetId : "${relationship.description}"');

      // Add technology as a note if available
      if (relationship.technology != null && includeNotes) {
        buffer.writeln('${indentation}note on link');
        buffer.writeln('${indentation}  ${relationship.technology}');
        buffer.writeln('${indentation}end note');
      }
    }
  }

  /// Sanitizes an ID to be valid in PlantUML
  String _sanitizeId(String id) {
    // Replace invalid characters with underscores
    return id.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
  }
}
