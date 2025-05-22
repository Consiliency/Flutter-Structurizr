import 'dart:async';

import 'package:flutter/material.dart' hide Element, Container, View, Border;
import 'package:flutter_structurizr/domain/documentation/documentation.dart';
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/container.dart';
import 'package:flutter_structurizr/domain/model/component.dart';
import 'package:flutter_structurizr/domain/model/deployment_node.dart';
import 'package:flutter_structurizr/domain/model/infrastructure_node.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';
import 'package:flutter_structurizr/infrastructure/export/diagram_exporter.dart';

/// An exporter for Structurizr DSL format
class DslExporter implements DiagramExporter<String> {
  /// Whether to include metadata information
  final bool includeMetadata;

  /// Whether to include documentation in the output
  final bool includeDocumentation;

  /// Whether to include style information
  final bool includeStyles;

  /// Whether to include views definitions
  final bool includeViews;

  /// Indentation for pretty printing
  final String indent;

  /// Progress callback for the export operation
  final ValueChanged<double>? onProgress;

  /// Creates a new DSL exporter
  const DslExporter({
    this.includeMetadata = true,
    this.includeDocumentation = true,
    this.includeStyles = true,
    this.includeViews = true,
    this.indent = '  ',
    this.onProgress,
  });

  @override
  Future<List<String>> exportBatch(
    List<DiagramReference> diagrams, {
    ValueChanged<double>? onProgress,
  }) async {
    // For DSL export, we don't actually need multiple diagrams
    // since we're exporting the entire workspace in DSL format.
    // We'll just use the first diagram reference.

    if (diagrams.isEmpty) {
      return [];
    }

    // Call progress callback to indicate starting
    onProgress?.call(0.0);
    this.onProgress?.call(0.0);

    final result = await export(diagrams.first);

    // Call progress callback with completion
    onProgress?.call(1.0);
    this.onProgress?.call(1.0);

    // Return the same result for all diagrams
    return List.filled(diagrams.length, result);
  }

  @override
  Future<String> export(DiagramReference diagram) async {
    try {
      // Report starting progress
      onProgress?.call(0.1);

      // Get the workspace
      final workspace = diagram.workspace;

      // Report data gathering progress
      onProgress?.call(0.3);

      // Generate DSL content
      final buffer = StringBuffer();

      // Add metadata section
      if (includeMetadata) {
        _generateMetadataSection(buffer, workspace);
      }

      // Add model section
      _generateModelSection(buffer, workspace);

      // Add documentation section if requested
      if (includeDocumentation && workspace.documentation != null) {
        _generateDocumentationSection(buffer, workspace);
      }

      // Add views section
      if (includeViews) {
        _generateViewsSection(buffer, workspace);
      }

      // Add styles section if requested
      if (includeStyles) {
        _generateStylesSection(buffer, workspace);
      }

      // Report completion
      onProgress?.call(1.0);

      return buffer.toString();
    } catch (e) {
      throw Exception('Failed to export workspace to DSL: $e');
    }
  }

  /// Generates the workspace metadata section in DSL
  void _generateMetadataSection(StringBuffer buffer, Workspace workspace) {
    buffer.writeln('workspace {');

    if (workspace.name.isNotEmpty) {
      buffer.writeln('${indent}name "${_escapeString(workspace.name)}"');
    }

    if (workspace.description != null && workspace.description!.isNotEmpty) {
      buffer.writeln(
          '${indent}description "${_escapeString(workspace.description!)}"');
    }

    // Add any other workspace properties here

    buffer.writeln();
  }

  /// Generates the model section in DSL
  void _generateModelSection(StringBuffer buffer, Workspace workspace) {
    buffer.writeln('${indent}model {');

    // Add people
    if (workspace.model.people.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('${indent}${indent}# People/Actors');

      for (final person in workspace.model.people) {
        _generatePersonDefinition(buffer, person, '${indent}${indent}');
      }
    }

    // Add software systems
    if (workspace.model.softwareSystems.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('${indent}${indent}# Software Systems');

      for (final system in workspace.model.softwareSystems) {
        _generateSystemDefinition(buffer, system, '${indent}${indent}');
      }
    }

    // Add deployment nodes
    if (workspace.model.deploymentNodes.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('${indent}${indent}# Deployment Nodes');

      for (final node in workspace.model.deploymentNodes) {
        _generateDeploymentNodeDefinition(buffer, node, '${indent}${indent}');
      }
    }

    buffer.writeln('${indent}}');
    buffer.writeln();
  }

  /// Generates the views section in DSL
  void _generateViewsSection(StringBuffer buffer, Workspace workspace) {
    buffer.writeln('${indent}views {');

    // Add system landscape views
    if (workspace.views.systemLandscapeViews.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('${indent}${indent}# System Landscape Views');

      for (final view in workspace.views.systemLandscapeViews) {
        _generateSystemLandscapeViewDefinition(
            buffer, view, '${indent}${indent}');
      }
    }

    // Add system context views
    if (workspace.views.systemContextViews.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('${indent}${indent}# System Context Views');

      for (final view in workspace.views.systemContextViews) {
        _generateSystemContextViewDefinition(
            buffer, view, '${indent}${indent}');
      }
    }

    // Add container views
    if (workspace.views.containerViews.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('${indent}${indent}# Container Views');

      for (final view in workspace.views.containerViews) {
        _generateContainerViewDefinition(buffer, view, '${indent}${indent}');
      }
    }

    // Add component views
    if (workspace.views.componentViews.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('${indent}${indent}# Component Views');

      for (final view in workspace.views.componentViews) {
        _generateComponentViewDefinition(buffer, view, '${indent}${indent}');
      }
    }

    // Add dynamic views
    if (workspace.views.dynamicViews.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('${indent}${indent}# Dynamic Views');

      for (final view in workspace.views.dynamicViews) {
        _generateDynamicViewDefinition(buffer, view, '${indent}${indent}');
      }
    }

    // Add deployment views
    if (workspace.views.deploymentViews.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('${indent}${indent}# Deployment Views');

      for (final view in workspace.views.deploymentViews) {
        _generateDeploymentViewDefinition(buffer, view, '${indent}${indent}');
      }
    }

    // Add configuration
    _generateViewsConfigurationDefinition(
        buffer, workspace, '${indent}${indent}');

    buffer.writeln('${indent}}');
    buffer.writeln();
  }

  /// Generates the styles section in DSL
  void _generateStylesSection(StringBuffer buffer, Workspace workspace) {
    buffer.writeln('${indent}styles {');

    final styles = workspace.styles;

    // Output element styles
    if (styles.elements.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('${indent}${indent}# Element Styles');

      for (final style in styles.elements) {
        _generateElementStyleDefinition(buffer, style, '${indent}${indent}');
      }
    }

    // Output relationship styles
    if (styles.relationships.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('${indent}${indent}# Relationship Styles');

      for (final style in styles.relationships) {
        _generateRelationshipStyleDefinition(
            buffer, style, '${indent}${indent}');
      }
    }

    buffer.writeln('${indent}}');
  }

  /// Generates a person definition in DSL
  void _generatePersonDefinition(
      StringBuffer buffer, Person person, String indentation) {
    buffer.write('${indentation}person ');

    buffer.write('"${_escapeString(person.name)}"');

    if (person.description != null && person.description!.isNotEmpty) {
      buffer.write(' "${_escapeString(person.description!)}"');
    }

    buffer.writeln(' {');

    // Add tags
    if (person.tags.isNotEmpty) {
      buffer.writeln(
          '${indentation}${indent}tags "${_escapeString(person.tags.join(', '))}"');
    }

    // Add custom properties
    if (person.properties.isNotEmpty) {
      for (final entry in person.properties.entries) {
        buffer.writeln('${indentation}${indent}properties {');
        buffer.writeln(
            '${indentation}${indent}${indent}"${_escapeString(entry.key)}" "${_escapeString(entry.value)}"');
        buffer.writeln('${indentation}${indent}}');
      }
    }

    // Add relationships
    if (person.relationships.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('${indentation}${indent}# relationships');

      for (final relationship in person.relationships) {
        _generateRelationshipDefinition(
            buffer, relationship, '${indentation}${indent}');
      }
    }

    buffer.writeln('${indentation}}');
    buffer.writeln();
  }

  /// Generates a software system definition in DSL
  void _generateSystemDefinition(
      StringBuffer buffer, SoftwareSystem system, String indentation) {
    buffer.write('${indentation}softwareSystem ');

    buffer.write('"${_escapeString(system.name)}"');

    if (system.description != null && system.description!.isNotEmpty) {
      buffer.write(' "${_escapeString(system.description!)}"');
    }

    buffer.writeln(' {');

    // Add tags
    if (system.tags.isNotEmpty) {
      buffer.writeln(
          '${indentation}${indent}tags "${_escapeString(system.tags.join(', '))}"');
    }

    // Add location
    if (system.location.isNotEmpty) {
      buffer.writeln(
          '${indentation}${indent}location "${_escapeString(system.location)}"');
    }

    // Add custom properties
    if (system.properties.isNotEmpty) {
      for (final entry in system.properties.entries) {
        buffer.writeln('${indentation}${indent}properties {');
        buffer.writeln(
            '${indentation}${indent}${indent}"${_escapeString(entry.key)}" "${_escapeString(entry.value)}"');
        buffer.writeln('${indentation}${indent}}');
      }
    }

    // Add containers
    if (system.containers.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('${indentation}${indent}# containers');

      for (final container in system.containers) {
        _generateContainerDefinition(
            buffer, container, '${indentation}${indent}');
      }
    }

    // Add relationships
    if (system.relationships.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('${indentation}${indent}# relationships');

      for (final relationship in system.relationships) {
        _generateRelationshipDefinition(
            buffer, relationship, '${indentation}${indent}');
      }
    }

    buffer.writeln('${indentation}}');
    buffer.writeln();
  }

  /// Generates a container definition in DSL
  void _generateContainerDefinition(
      StringBuffer buffer, Container container, String indentation) {
    buffer.write('${indentation}container ');

    buffer.write('"${_escapeString(container.name)}"');

    if (container.description != null && container.description!.isNotEmpty) {
      buffer.write(' "${_escapeString(container.description!)}"');
    }

    if (container.technology != null && container.technology!.isNotEmpty) {
      buffer.write(' "${_escapeString(container.technology!)}"');
    }

    buffer.writeln(' {');

    // Add tags
    if (container.tags.isNotEmpty) {
      buffer.writeln(
          '${indentation}${indent}tags "${_escapeString(container.tags.join(', '))}"');
    }

    // Add custom properties
    if (container.properties.isNotEmpty) {
      for (final entry in container.properties.entries) {
        buffer.writeln('${indentation}${indent}properties {');
        buffer.writeln(
            '${indentation}${indent}${indent}"${_escapeString(entry.key)}" "${_escapeString(entry.value)}"');
        buffer.writeln('${indentation}${indent}}');
      }
    }

    // Add components
    if (container.components.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('${indentation}${indent}# components');

      for (final component in container.components) {
        _generateComponentDefinition(
            buffer, component, '${indentation}${indent}');
      }
    }

    // Add relationships
    if (container.relationships.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('${indentation}${indent}# relationships');

      for (final relationship in container.relationships) {
        _generateRelationshipDefinition(
            buffer, relationship, '${indentation}${indent}');
      }
    }

    buffer.writeln('${indentation}}');
  }

  /// Generates a component definition in DSL
  void _generateComponentDefinition(
      StringBuffer buffer, Component component, String indentation) {
    buffer.write('${indentation}component ');

    buffer.write('"${_escapeString(component.name)}"');

    if (component.description != null && component.description!.isNotEmpty) {
      buffer.write(' "${_escapeString(component.description!)}"');
    }

    if (component.technology != null && component.technology!.isNotEmpty) {
      buffer.write(' "${_escapeString(component.technology!)}"');
    }

    buffer.writeln(' {');

    // Add tags
    if (component.tags != null && component.tags!.isNotEmpty) {
      buffer.writeln(
          '${indentation}${indent}tags "${_escapeString(component.tags!.join(', '))}"');
    }

    // Add custom properties
    if (component.properties != null && component.properties!.isNotEmpty) {
      for (final entry in component.properties!.entries) {
        buffer.writeln('${indentation}${indent}properties {');
        buffer.writeln(
            '${indentation}${indent}${indent}"${_escapeString(entry.key)}" "${_escapeString(entry.value)}"');
        buffer.writeln('${indentation}${indent}}');
      }
    }

    // Add relationships
    if (component.relationships.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('${indentation}${indent}# relationships');

      for (final relationship in component.relationships) {
        _generateRelationshipDefinition(
            buffer, relationship, '${indentation}${indent}');
      }
    }

    buffer.writeln('${indentation}}');
  }

  /// Generates a deployment node definition in DSL
  void _generateDeploymentNodeDefinition(
      StringBuffer buffer, DeploymentNode node, String indentation) {
    buffer.write(
        '${indentation}deploymentNode "${_escapeString(node.environment ?? '')}" ');

    buffer.write('"${_escapeString(node.name)}"');

    if (node.description != null && node.description!.isNotEmpty) {
      buffer.write(' "${_escapeString(node.description!)}"');
    }

    if (node.technology != null && node.technology!.isNotEmpty) {
      buffer.write(' "${_escapeString(node.technology!)}"');
    }

    buffer.writeln(' {');

    // Add tags
    if (node.tags != null && node.tags!.isNotEmpty) {
      buffer.writeln(
          '${indentation}${indent}tags "${_escapeString(node.tags!.join(', '))}"');
    }

    // Add custom properties
    if (node.properties != null && node.properties!.isNotEmpty) {
      for (final entry in node.properties!.entries) {
        buffer.writeln('${indentation}${indent}properties {');
        buffer.writeln(
            '${indentation}${indent}${indent}"${_escapeString(entry.key)}" "${_escapeString(entry.value)}"');
        buffer.writeln('${indentation}${indent}}');
      }
    }

    // Add infrastructure nodes
    if (node.infrastructureNodes.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('${indentation}${indent}# infrastructure nodes');

      for (final infra in node.infrastructureNodes) {
        _generateInfrastructureNodeDefinition(
            buffer, infra, '${indentation}${indent}');
      }
    }

    // Add container instances
    if (node.containerInstances.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('${indentation}${indent}# container instances');

      for (final instance in node.containerInstances) {
        buffer
            .writeln('${indentation}${indent}containerInstance ${instance.id}');
      }
    }

    // Add software system instances
    if (node.softwareSystemInstances.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('${indentation}${indent}# software system instances');

      for (final instance in node.softwareSystemInstances) {
        buffer.writeln(
            '${indentation}${indent}softwareSystemInstance ${instance.id}');
      }
    }

    // Add child nodes recursively
    if (node.children.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('${indentation}${indent}# child deployment nodes');

      for (final child in node.children) {
        _generateDeploymentNodeDefinition(
            buffer, child, '${indentation}${indent}');
      }
    }

    buffer.writeln('${indentation}}');
  }

  /// Generates an infrastructure node definition in DSL
  void _generateInfrastructureNodeDefinition(
      StringBuffer buffer, InfrastructureNode node, String indentation) {
    buffer.write('${indentation}infrastructureNode ');

    buffer.write('"${_escapeString(node.name)}"');

    if (node.description != null && node.description!.isNotEmpty) {
      buffer.write(' "${_escapeString(node.description!)}"');
    }

    if (node.technology != null && node.technology!.isNotEmpty) {
      buffer.write(' "${_escapeString(node.technology!)}"');
    }

    buffer.writeln();
  }

  /// Generates a relationship definition in DSL
  void _generateRelationshipDefinition(
      StringBuffer buffer, Relationship relationship, String indentation) {
    buffer.write('${indentation}-> ${relationship.destinationId} ');

    if (relationship.description.isNotEmpty) {
      buffer.write('"${_escapeString(relationship.description)}" ');
    } else {
      buffer.write('"Uses" ');
    }

    if (relationship.technology != null &&
        relationship.technology!.isNotEmpty) {
      buffer.write('"${_escapeString(relationship.technology!)}"');
    }

    buffer.writeln();
  }

  /// Generates a system landscape view definition in DSL
  void _generateSystemLandscapeViewDefinition(
      StringBuffer buffer, SystemLandscapeView view, String indentation) {
    buffer.write('${indentation}systemLandscape ');

    if (view.title != null && view.title!.isNotEmpty) {
      buffer.write('"${_escapeString(view.title!)}" ');
    }

    buffer.writeln('{');

    // Add view elements
    if (view.elements.isNotEmpty) {
      buffer.writeln('${indentation}${indent}# elements');
      for (final element in view.elements) {
        buffer.writeln('${indentation}${indent}include ${element.id}');
      }
    }

    // Add explicit relationships if specified
    if (view.relationships.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('${indentation}${indent}# relationships');
      for (final rel in view.relationships) {
        buffer.writeln('${indentation}${indent}include ${rel.id}');
      }
    }

    // Add automaticLayout if specified
    if (view.automaticLayout != null) {
      buffer.writeln();
      buffer.writeln('${indentation}${indent}autoLayout');
    }

    buffer.writeln('${indentation}}');
    buffer.writeln();
  }

  /// Generates a system context view definition in DSL
  void _generateSystemContextViewDefinition(
      StringBuffer buffer, SystemContextView view, String indentation) {
    buffer.write('${indentation}systemContext ${view.softwareSystemId} ');

    if (view.title != null && view.title!.isNotEmpty) {
      buffer.write('"${_escapeString(view.title!)}" ');
    }

    buffer.writeln('{');

    // Add view elements
    if (view.elements.isNotEmpty) {
      buffer.writeln('${indentation}${indent}# elements');
      for (final element in view.elements) {
        buffer.writeln('${indentation}${indent}include ${element.id}');
      }
    }

    // Add explicit relationships if specified
    if (view.relationships.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('${indentation}${indent}# relationships');
      for (final rel in view.relationships) {
        buffer.writeln('${indentation}${indent}include ${rel.id}');
      }
    }

    // Add automaticLayout if specified
    if (view.automaticLayout != null) {
      buffer.writeln();
      buffer.writeln('${indentation}${indent}autoLayout');
    }

    buffer.writeln('${indentation}}');
    buffer.writeln();
  }

  /// Generates a container view definition in DSL
  void _generateContainerViewDefinition(
      StringBuffer buffer, ContainerView view, String indentation) {
    buffer.write('${indentation}container ${view.softwareSystemId} ');

    if (view.title != null && view.title!.isNotEmpty) {
      buffer.write('"${_escapeString(view.title!)}" ');
    }

    buffer.writeln('{');

    // Add view elements
    if (view.elements.isNotEmpty) {
      buffer.writeln('${indentation}${indent}# elements');
      for (final element in view.elements) {
        buffer.writeln('${indentation}${indent}include ${element.id}');
      }
    }

    // Add explicit relationships if specified
    if (view.relationships.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('${indentation}${indent}# relationships');
      for (final rel in view.relationships) {
        buffer.writeln('${indentation}${indent}include ${rel.id}');
      }
    }

    // Add automaticLayout if specified
    if (view.automaticLayout != null) {
      buffer.writeln();
      buffer.writeln('${indentation}${indent}autoLayout');
    }

    buffer.writeln('${indentation}}');
    buffer.writeln();
  }

  /// Generates a component view definition in DSL
  void _generateComponentViewDefinition(
      StringBuffer buffer, ComponentView view, String indentation) {
    buffer.write('${indentation}component ${view.containerId} ');

    if (view.title != null && view.title!.isNotEmpty) {
      buffer.write('"${_escapeString(view.title!)}" ');
    }

    buffer.writeln('{');

    // Add view elements
    if (view.elements.isNotEmpty) {
      buffer.writeln('${indentation}${indent}# elements');
      for (final element in view.elements) {
        buffer.writeln('${indentation}${indent}include ${element.id}');
      }
    }

    // Add explicit relationships if specified
    if (view.relationships.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('${indentation}${indent}# relationships');
      for (final rel in view.relationships) {
        buffer.writeln('${indentation}${indent}include ${rel.id}');
      }
    }

    // Add automaticLayout if specified
    if (view.automaticLayout != null) {
      buffer.writeln();
      buffer.writeln('${indentation}${indent}autoLayout');
    }

    buffer.writeln('${indentation}}');
    buffer.writeln();
  }

  /// Generates a dynamic view definition in DSL
  void _generateDynamicViewDefinition(
      StringBuffer buffer, DynamicView view, String indentation) {
    buffer.write('${indentation}dynamic ');

    if (view.elementId != null && view.elementId!.isNotEmpty) {
      buffer.write('${view.elementId} ');
    } else {
      buffer.write('* ');
    }

    if (view.title != null && view.title!.isNotEmpty) {
      buffer.write('"${_escapeString(view.title!)}" ');
    }

    buffer.writeln('{');

    // Add dynamic relationships
    if (view.relationships.isNotEmpty) {
      buffer.writeln('${indentation}${indent}# relationships');
      for (final rel in view.relationships) {
        buffer.write(
            '${indentation}${indent}${rel.sourceId} -> ${rel.destinationId}');

        if (rel.description != null && rel.description!.isNotEmpty) {
          buffer.write(' "${_escapeString(rel.description!)}"');
        }

        buffer.writeln();
      }
    }

    // Add automaticLayout if specified
    if (view.automaticLayout != null) {
      buffer.writeln();
      buffer.writeln('${indentation}${indent}autoLayout');
    }

    buffer.writeln('${indentation}}');
    buffer.writeln();
  }

  /// Generates a deployment view definition in DSL
  void _generateDeploymentViewDefinition(
      StringBuffer buffer, DeploymentView view, String indentation) {
    buffer.write('${indentation}deployment ');

    if (view.softwareSystemId != null && view.softwareSystemId!.isNotEmpty) {
      buffer.write('${view.softwareSystemId} ');
    } else {
      buffer.write('* ');
    }

    buffer.write('"${_escapeString(view.environment)}" ');

    if (view.title != null && view.title!.isNotEmpty) {
      buffer.write('"${_escapeString(view.title!)}" ');
    }

    buffer.writeln('{');

    // Add view elements
    if (view.elements.isNotEmpty) {
      buffer.writeln('${indentation}${indent}# elements');
      for (final element in view.elements) {
        buffer.writeln('${indentation}${indent}include ${element.id}');
      }
    }

    // Add explicit relationships if specified
    if (view.relationships.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('${indentation}${indent}# relationships');
      for (final rel in view.relationships) {
        buffer.writeln('${indentation}${indent}include ${rel.id}');
      }
    }

    // Add automaticLayout if specified
    if (view.automaticLayout != null) {
      buffer.writeln();
      buffer.writeln('${indentation}${indent}autoLayout');
    }

    buffer.writeln('${indentation}}');
    buffer.writeln();
  }

  /// Generates views configuration in DSL
  void _generateViewsConfigurationDefinition(
      StringBuffer buffer, Workspace workspace, String indentation) {
    buffer.writeln();
    buffer.writeln('${indentation}# views configuration');
    buffer.writeln('${indentation}configuration {');

    // Add branding if available
    if (workspace.branding != null) {
      final branding = workspace.branding!;
      buffer.writeln('${indentation}${indent}branding {');

      if (branding.logo != null && branding.logo!.isNotEmpty) {
        buffer.writeln(
            '${indentation}${indent}${indent}logo "${_escapeString(branding.logo!)}"');
      }

      buffer.writeln('${indentation}${indent}}');
    }

    // Add terminology if available
    if (workspace.configuration?.properties.containsKey('terminology') ==
        true) {
      buffer.writeln('${indentation}${indent}terminology {');
      // Add custom terminology definitions here if available
      buffer.writeln('${indentation}${indent}}');
    }

    buffer.writeln('${indentation}}');
  }

  /// Generates an element style definition in DSL
  void _generateElementStyleDefinition(
      StringBuffer buffer, ElementStyle style, String indentation) {
    buffer.write('${indentation}element ');

    buffer.writeln('{');

    // Add style properties
    if (style.background != null &&
        style.background is String &&
        (style.background as String).isNotEmpty) {
      buffer.writeln(
          '${indentation}${indent}background "${_escapeString(style.background as String)}"');
    } else if (style.background != null) {
      // Handle Color object or other type
      buffer.writeln(
          '${indentation}${indent}background "#${style.background.toString().split("0x")[1].substring(2, 8)}"');
    }

    if (style.color != null) {
      final colorStr = style.color.toString();
      buffer.writeln('${indentation}${indent}color "$colorStr"');
    }

    if (style.fontSize != null) {
      buffer.writeln('${indentation}${indent}fontSize ${style.fontSize}');
    }

    final shapeStr = style.shape.toString().split('.').last;
    buffer.writeln('${indentation}${indent}shape "$shapeStr"');

    if (style.icon != null && style.icon!.isNotEmpty) {
      buffer.writeln(
          '${indentation}${indent}icon "${_escapeString(style.icon!)}"');
    }

    final borderStr = style.border.toString().split('.').last;
    buffer.writeln('${indentation}${indent}border "$borderStr"');

    buffer.writeln('${indentation}${indent}opacity ${style.opacity}');

    if (style.width != null) {
      buffer.writeln('${indentation}${indent}width ${style.width}');
    }

    if (style.height != null) {
      buffer.writeln('${indentation}${indent}height ${style.height}');
    }

    buffer.writeln('${indentation}}');
  }

  /// Generates a relationship style definition in DSL
  void _generateRelationshipStyleDefinition(
      StringBuffer buffer, RelationshipStyle style, String indentation) {
    buffer.write('${indentation}relationship ');

    buffer.writeln('{');

    // Add style properties
    buffer.writeln('${indentation}${indent}thickness ${style.thickness}');

    if (style.color != null) {
      final colorStr = style.color.toString();
      buffer.writeln('${indentation}${indent}color "$colorStr"');
    }

    buffer.writeln('${indentation}${indent}routing ${style.routing}');

    if (style.fontSize != null) {
      buffer.writeln('${indentation}${indent}fontSize ${style.fontSize}');
    }

    if (style.width != null) {
      buffer.writeln('${indentation}${indent}width ${style.width}');
    }

    buffer.writeln('${indentation}${indent}position ${style.position}');

    buffer.writeln('${indentation}}');
  }

  /// Generates the documentation section in DSL
  void _generateDocumentationSection(StringBuffer buffer, Workspace workspace) {
    if (workspace.documentation == null ||
        (workspace.documentation!.sections.isEmpty &&
            workspace.documentation!.decisions.isEmpty)) {
      return; // No documentation to generate
    }

    buffer.writeln('${indent}documentation {');

    // Add documentation sections
    if (workspace.documentation!.sections.isNotEmpty) {
      for (final section in workspace.documentation!.sections) {
        // Start section
        buffer.writeln(
            '${indent}${indent}section "${_escapeString(section.title)}" {');

        // Add format if not markdown (markdown is the default)
        if (section.format != DocumentationFormat.markdown) {
          buffer.writeln(
              '${indent}${indent}${indent}format "${section.format.toString().split('.').last}"');
        }

        // Add content with proper escaping for multi-line strings
        buffer.writeln(
            '${indent}${indent}${indent}content """${_escapeString(section.content)}"""');

        // Close section
        buffer.writeln('${indent}${indent}}');
      }
    }

    // Add decisions section separately if there are any decisions
    if (workspace.documentation!.decisions.isNotEmpty) {
      _generateDecisionsSection(buffer, workspace);
    }

    buffer.writeln('${indent}}');
    buffer.writeln();
  }

  /// Generates the decisions section in DSL
  void _generateDecisionsSection(StringBuffer buffer, Workspace workspace) {
    if (workspace.documentation?.decisions.isEmpty ?? true) {
      return; // No decisions to generate
    }

    buffer.writeln('${indent}${indent}decisions {');

    for (final decision in workspace.documentation!.decisions) {
      // Start decision
      buffer.writeln(
          '${indent}${indent}${indent}decision "${_escapeString(decision.id)}" {');

      // Add decision properties
      buffer.writeln(
          '${indent}${indent}${indent}${indent}title "${_escapeString(decision.title)}"');
      buffer.writeln(
          '${indent}${indent}${indent}${indent}status "${_escapeString(decision.status)}"');

      // Format date as yyyy-MM-dd
      final date = decision.date;
      final formattedDate =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      buffer
          .writeln('${indent}${indent}${indent}${indent}date "$formattedDate"');

      // Add format if not markdown (markdown is the default)
      if (decision.format != DocumentationFormat.markdown) {
        buffer.writeln(
            '${indent}${indent}${indent}${indent}format "${decision.format.toString().split('.').last}"');
      }

      // Add content with proper escaping for multi-line strings
      buffer.writeln(
          '${indent}${indent}${indent}${indent}content """${_escapeString(decision.content)}"""');

      // Add links to other decisions if any
      if (decision.links.isNotEmpty) {
        final linksStr =
            decision.links.map((link) => '"${_escapeString(link)}"').join(', ');
        buffer.writeln('${indent}${indent}${indent}${indent}links $linksStr');
      }

      // Close decision
      buffer.writeln('${indent}${indent}${indent}}');
    }

    buffer.writeln('${indent}${indent}}');
  }

  /// Escapes a string for DSL output
  String _escapeString(String str) {
    return str
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n');
  }
}
