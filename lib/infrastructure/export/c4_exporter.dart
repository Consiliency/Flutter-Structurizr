import 'dart:async';

import 'package:flutter/material.dart' hide Element, Container, View;
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/component.dart';
import 'package:flutter_structurizr/domain/model/deployment_node.dart';
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/infrastructure/export/diagram_exporter.dart';
import 'package:logging/logging.dart';
import 'package:flutter_structurizr/domain/model/container.dart';

final logger = Logger('C4Exporter');

/// The style of C4 diagram to generate
enum C4DiagramStyle {
  /// Standard C4 model
  standard,

  /// C4 model with additional styling
  enhanced,
}

/// The format of the C4 output
enum C4OutputFormat {
  /// JSON format
  json,

  /// YAML format
  yaml,
}

/// An exporter for C4 model diagrams
class C4Exporter implements DiagramExporter<String> {
  /// The C4 style to use
  final C4DiagramStyle style;

  /// The output format to use
  final C4OutputFormat format;

  /// Whether to include detailed metadata
  final bool includeMetadata;

  /// Whether to include relationships in the output
  final bool includeRelationships;

  /// Whether to include styles in the output
  final bool includeStyles;

  /// Progress callback for the export operation
  final ValueChanged<double>? onProgress;

  /// Creates a new C4 model exporter
  const C4Exporter({
    this.style = C4DiagramStyle.standard,
    this.format = C4OutputFormat.json,
    this.includeMetadata = true,
    this.includeRelationships = true,
    this.includeStyles = true,
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

      // Generate C4 model content based on view type
      String c4Content = '';
      if (view is SystemContextView) {
        c4Content = _generateSystemContextModel(view, elements, relationships);
      } else if (view is ContainerView) {
        c4Content = _generateContainerModel(view, elements, relationships);
      } else if (view is ComponentView) {
        c4Content = _generateComponentModel(view, elements, relationships);
      } else if (view is DeploymentView) {
        c4Content = _generateDeploymentModel(view, elements, relationships);
      } else {
        // Default generic model
        c4Content = _generateGenericModel(view, elements, relationships);
      }

      // Report completion
      onProgress?.call(1.0);

      return c4Content;
    } catch (e) {
      throw Exception('Failed to export diagram to C4 model: $e');
    }
  }

  /// Finds a view in the workspace by key
  View? _findViewByKey(workspace, String key) {
    final views = workspace.views;
    // Check system landscape views
    for (final view in (views.systemLandscapeViews as List<View>)) {
      if (view.key == key) return view;
    }
    // Check system context views
    for (final view in (views.systemContextViews as List<View>)) {
      if (view.key == key) return view;
    }
    // Check container views
    for (final view in (views.containerViews as List<View>)) {
      if (view.key == key) return view;
    }
    // Check component views
    for (final view in (views.componentViews as List<View>)) {
      if (view.key == key) return view;
    }
    // Check dynamic views
    for (final view in (views.dynamicViews as List<View>)) {
      if (view.key == key) return view;
    }
    // Check deployment views
    for (final view in (views.deploymentViews as List<View>)) {
      if (view.key == key) return view;
    }
    return null;
  }

  /// Gets elements for a view from the workspace
  List<Element> _getElementsInView(View view, workspace) {
    final result = <Element>[];
    final model = workspace.model;

    for (final elementView in view.elements) {
      final id = elementView.id;

      // Check in people
      final person = model.getPeopleById(id) as Person?;
      if (person != null) {
        result.add(person);
        continue;
      }

      // Check in software systems
      final softwareSystem = model.getSoftwareSystemById(id) as SoftwareSystem?;
      if (softwareSystem != null) {
        result.add(softwareSystem);
        // If this is a container view for this system, add all its containers
        if (view is ContainerView && view.softwareSystemId == id) {
          result.addAll(softwareSystem.containers.cast<Element>());
        }
        continue;
      }

      // Check containers in all systems
      for (final system in (model.softwareSystems as List<SoftwareSystem>)) {
        final container = system.containers.firstWhere(
          (c) => c.id == id,
          orElse: () => const Container(id: '', name: '', parentId: ''),
        );
        if (container.id.isNotEmpty) {
          result.add(container as Element);
          // If this is a component view for this container, add all its components
          if (view is ComponentView && view.containerId == id) {
            result.addAll((container.components as List).cast<Element>());
          }
          break;
        }
      }

      // Check components in all containers of all systems
      for (final system in (model.softwareSystems as List<SoftwareSystem>)) {
        bool found = false;
        for (final container in system.containers) {
          final component = container.components.firstWhere(
            (c) => c.id == id,
            orElse: () => const Component(id: '', name: '', parentId: ''),
          );
          if (component.id.isNotEmpty) {
            result.add(component as Element);
            found = true;
            break;
          }
        }
        if (found) break;
      }

      // Check in deployment nodes
      final deploymentNode = model.deploymentNodes.firstWhere(
        (n) => n.id == id,
        orElse: () => null,
      );
      if (deploymentNode != null && deploymentNode.id.isNotEmpty) {
        result.add(deploymentNode as Element);
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
        for (final person in (model.people as List<Person>)) {
          final relationship = person.getRelationshipById(id);
          if (relationship != null) {
            result.add(relationship);
            break;
          }
        }

        // Find relationships in software systems
        for (final system in (model.softwareSystems as List<SoftwareSystem>)) {
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
      for (final person in (model.people as List<Person>)) {
        if (elementIds.contains(person.id)) {
          for (final relationship in person.relationships) {
            if (isRelationshipInView(relationship)) {
              result.add(relationship);
            }
          }
        }
      }

      // From software systems and their containers/components
      for (final system in (model.softwareSystems as List<SoftwareSystem>)) {
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
        final relationshipId =
            interaction.id ?? '${sourceId}_${destinationId}_${result.length}';

        // Handle potentially null strings by providing defaults
        final safeSourceId = sourceId ?? '';
        final safeDestId = destinationId ?? '';
        final safeDescription = description ?? '';

        final relationship = Relationship(
          id: relationshipId,
          sourceId: safeSourceId,
          destinationId: safeDestId,
          description: safeDescription,
        );

        result.add(relationship);
      }
    }

    return result;
  }

  /// Generates a System Context model in C4 format
  String _generateSystemContextModel(
    SystemContextView view,
    List<Element> elements,
    List<Relationship> relationships,
  ) {
    // Find the central system being described
    final centralSystem = elements.firstWhere(
      (element) => element.id == view.softwareSystemId,
      orElse: () => const SoftwareSystem(id: '', name: 'Unknown System'),
    );

    final Map<String, dynamic> c4Model = {};

    // Add metadata
    if (includeMetadata) {
      c4Model['type'] = 'SystemContext';
      c4Model['scope'] = centralSystem.name;
      c4Model['description'] = view.description ??
          'System Context diagram for ${centralSystem.name}';
      c4Model['viewKey'] = view.key;
      c4Model['title'] = view.title ?? view.key;
    }

    // Add elements
    c4Model['elements'] = _generateElementsSection(elements, view);

    // Add relationships
    if (includeRelationships) {
      c4Model['relationships'] =
          _generateRelationshipsSection(relationships, elements);
    }

    // Add styles
    if (includeStyles) {
      c4Model['styles'] = _generateStylesSection(elements);
    }

    // Convert to the requested format
    return format == C4OutputFormat.json
        ? _convertToJson(c4Model)
        : _convertToYaml(c4Model);
  }

  /// Generates a Container model in C4 format
  String _generateContainerModel(
    ContainerView view,
    List<Element> elements,
    List<Relationship> relationships,
  ) {
    // Find the system being described
    final system = elements.firstWhere(
      (element) => element.id == view.softwareSystemId,
      orElse: () => const SoftwareSystem(id: '', name: 'Unknown System'),
    );

    final Map<String, dynamic> c4Model = {};

    // Add metadata
    if (includeMetadata) {
      c4Model['type'] = 'Container';
      c4Model['scope'] = system.name;
      c4Model['description'] =
          view.description ?? 'Container diagram for ${system.name}';
      c4Model['viewKey'] = view.key;
      c4Model['title'] = view.title ?? view.key;
    }

    // Add elements
    c4Model['elements'] = _generateElementsSection(elements, view);

    // Add relationships
    if (includeRelationships) {
      c4Model['relationships'] =
          _generateRelationshipsSection(relationships, elements);
    }

    // Add styles
    if (includeStyles) {
      c4Model['styles'] = _generateStylesSection(elements);
    }

    // Convert to the requested format
    return format == C4OutputFormat.json
        ? _convertToJson(c4Model)
        : _convertToYaml(c4Model);
  }

  /// Generates a Component model in C4 format
  String _generateComponentModel(
    ComponentView view,
    List<Element> elements,
    List<Relationship> relationships,
  ) {
    // Find the container being described
    final container = elements.firstWhere(
      (element) => element.id == view.containerId,
      orElse: () => const SoftwareSystem(id: '', name: 'Unknown Container'),
    );

    final Map<String, dynamic> c4Model = {};

    // Add metadata
    if (includeMetadata) {
      c4Model['type'] = 'Component';
      c4Model['scope'] = container.name;
      c4Model['description'] =
          view.description ?? 'Component diagram for ${container.name}';
      c4Model['viewKey'] = view.key;
      c4Model['title'] = view.title ?? view.key;
    }

    // Add elements
    c4Model['elements'] = _generateElementsSection(elements, view);

    // Add relationships
    if (includeRelationships) {
      c4Model['relationships'] =
          _generateRelationshipsSection(relationships, elements);
    }

    // Add styles
    if (includeStyles) {
      c4Model['styles'] = _generateStylesSection(elements);
    }

    // Convert to the requested format
    return format == C4OutputFormat.json
        ? _convertToJson(c4Model)
        : _convertToYaml(c4Model);
  }

  /// Generates a Deployment model in C4 format
  String _generateDeploymentModel(
    DeploymentView view,
    List<Element> elements,
    List<Relationship> relationships,
  ) {
    final Map<String, dynamic> c4Model = {};

    // Add metadata
    if (includeMetadata) {
      c4Model['type'] = 'Deployment';
      c4Model['scope'] = view.environment;
      c4Model['description'] =
          view.description ?? 'Deployment diagram for ${view.environment}';
      c4Model['viewKey'] = view.key;
      c4Model['title'] = view.title ?? view.key;
    }

    // Add elements
    c4Model['elements'] = _generateElementsSection(elements, view);

    // Add relationships
    if (includeRelationships) {
      c4Model['relationships'] =
          _generateRelationshipsSection(relationships, elements);
    }

    // Add styles
    if (includeStyles) {
      c4Model['styles'] = _generateStylesSection(elements);
    }

    // Add deployment-specific metadata
    c4Model['environment'] = view.environment;

    // Convert to the requested format
    return format == C4OutputFormat.json
        ? _convertToJson(c4Model)
        : _convertToYaml(c4Model);
  }

  /// Generates a generic model for any view type in C4 format
  String _generateGenericModel(
    View view,
    List<Element> elements,
    List<Relationship> relationships,
  ) {
    final Map<String, dynamic> c4Model = {};

    // Add metadata
    if (includeMetadata) {
      c4Model['type'] = 'Generic';
      c4Model['description'] = view.description ?? 'Diagram for ${view.key}';
      c4Model['viewKey'] = view.key;
      c4Model['title'] = view.title ?? view.key;
    }

    // Add elements
    c4Model['elements'] = _generateElementsSection(elements, view);

    // Add relationships
    if (includeRelationships) {
      c4Model['relationships'] =
          _generateRelationshipsSection(relationships, elements);
    }

    // Add styles
    if (includeStyles) {
      c4Model['styles'] = _generateStylesSection(elements);
    }

    // Convert to the requested format
    return format == C4OutputFormat.json
        ? _convertToJson(c4Model)
        : _convertToYaml(c4Model);
  }

  /// Generates the elements section for a C4 model
  List<Map<String, dynamic>> _generateElementsSection(
      List<Element> elements, View view) {
    final result = <Map<String, dynamic>>[];

    for (final element in elements) {
      final elementMap = <String, dynamic>{
        'id': element.id,
        'name': element.name,
      };

      if (element.description != null && element.description!.isNotEmpty) {
        elementMap['description'] = element.description;
      }

      // Add element-type specific attributes
      if (element is Person) {
        elementMap['type'] = 'person';
        elementMap['location'] = element.location ?? 'Unspecified';
      } else if (element is SoftwareSystem) {
        elementMap['type'] = 'softwareSystem';
        elementMap['location'] = element.location ?? 'Unspecified';
      } else if (element is Container) {
        elementMap['type'] = 'container';
        elementMap['parent'] = element.parentId;
        if ((element).technology != null && (element).technology!.isNotEmpty) {
          elementMap['technology'] = (element).technology;
        }
      } else if (element is Component) {
        elementMap['type'] = 'component';
        elementMap['parent'] = element.parentId;
        if ((element).technology != null && (element).technology!.isNotEmpty) {
          elementMap['technology'] = (element).technology;
        }
      } else if (element is DeploymentNode) {
        elementMap['type'] = 'deploymentNode';
        elementMap['environment'] = (element as dynamic).environment ?? '';
        if ((element as dynamic).technology != null &&
            (element as dynamic).technology != '') {
          elementMap['technology'] = (element as dynamic).technology;
        }
        // Add infrastructure nodes if any
        if ((element as dynamic).infrastructureNodes != null &&
            (element as dynamic).infrastructureNodes.isNotEmpty) {
          elementMap['infrastructureNodes'] =
              (element as dynamic).infrastructureNodes.map((node) {
            final tech = (node as dynamic).technology;
            if (tech is String && tech.isNotEmpty) {
              return {
                'id': node.id,
                'name': node.name,
                'description': node.description,
                'technology': tech,
              };
            } else {
              return {
                'id': node.id,
                'name': node.name,
                'description': node.description,
              };
            }
          }).toList();
        }
        // Add container instances if any
        if ((element as dynamic).containerInstances != null &&
            (element as dynamic).containerInstances.isNotEmpty) {
          elementMap['containerInstances'] = (element as dynamic)
              .containerInstances
              .map((instance) => {
                    'id': instance.id,
                    'containerId': instance.containerId,
                  })
              .toList();
        }
      }

      // Add layout-specific information from view
      final elementView = view.elements.firstWhere(
        (e) => e.id == element.id,
        orElse: () => const ElementView(id: ''),
      );

      if (elementView.id.isNotEmpty &&
          elementView.x != null &&
          elementView.y != null) {
        elementMap['x'] = elementView.x;
        elementMap['y'] = elementView.y;
      }

      result.add(elementMap);
    }

    return result;
  }

  /// Generates the relationships section for a C4 model
  List<Map<String, dynamic>> _generateRelationshipsSection(
    List<Relationship> relationships,
    List<Element> elements,
  ) {
    final result = <Map<String, dynamic>>[];

    for (final relationship in relationships) {
      final relationshipMap = <String, dynamic>{
        'id': relationship.id,
        'source': relationship.sourceId,
        'destination': relationship.destinationId,
      };

      if (relationship.description.isNotEmpty) {
        relationshipMap['description'] = relationship.description;
      }

      if (relationship.technology != null &&
          relationship.technology!.isNotEmpty) {
        relationshipMap['technology'] = relationship.technology;
      }

      // The relationship order is not available in this implementation
      // But we'll keep it in the generated JSON/YAML for compatibility
      relationshipMap['order'] = 1;

      result.add(relationshipMap);
    }

    return result;
  }

  /// Generates the styles section for a C4 model
  Map<String, dynamic> _generateStylesSection(List<Element> elements) {
    // Default C4 model styles
    final styles = <String, dynamic>{
      'elements': {
        'person': {
          'shape': 'person',
          'background': '#08427B',
          'color': '#ffffff',
        },
        'softwareSystem': {
          'shape': 'box',
          'background': '#1168BD',
          'color': '#ffffff',
        },
        'container': {
          'shape': 'box',
          'background': '#438DD5',
          'color': '#ffffff',
        },
        'component': {
          'shape': 'box',
          'background': '#85BBF0',
          'color': '#000000',
        },
        'deploymentNode': {
          'shape': 'folder',
          'background': '#999999',
          'color': '#ffffff',
        },
      },
      'relationships': {
        'default': {
          'thickness': 2,
          'color': '#707070',
          'style': 'solid',
        },
      },
    };

    // Add element-specific styles (enhanced mode only)
    if (style == C4DiagramStyle.enhanced) {
      final elementStyles = <Map<String, dynamic>>[];

      for (final element in elements) {
        // Add custom styles based on element properties
        // This would be more sophisticated in a real implementation
        if (element is SoftwareSystem && element.location == 'External') {
          elementStyles.add({
            'tag': element.id,
            'background': '#999999',
            'color': '#ffffff',
          });
        }
      }

      if (elementStyles.isNotEmpty) {
        styles['customStyles'] = elementStyles;
      }
    }

    return styles;
  }

  /// Converts a Map to a JSON string
  String _convertToJson(Map<String, dynamic> model) {
    // In a real implementation, use json.encode with proper indentation
    // This is a placeholder for a prettier JSON format
    StringBuffer buffer = StringBuffer();
    buffer.writeln('{');

    final entries = model.entries.toList();
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      buffer.write('  "${entry.key}": ');
      _writeJsonValue(buffer, entry.value, indent: 2);

      if (i < entries.length - 1) {
        buffer.writeln(',');
      } else {
        buffer.writeln();
      }
    }

    buffer.writeln('}');
    return buffer.toString();
  }

  /// Helper function to write a JSON value with proper indentation
  void _writeJsonValue(StringBuffer buffer, dynamic value, {int indent = 0}) {
    final indentStr = ' ' * indent;

    if (value is String) {
      buffer.write('"${_escapeJsonString(value)}"');
    } else if (value is num || value is bool || value == null) {
      buffer.write('$value');
    } else if (value is List) {
      if (value.isEmpty) {
        buffer.write('[]');
      } else {
        buffer.writeln('[');
        for (int i = 0; i < value.length; i++) {
          buffer.write('$indentStr  ');
          _writeJsonValue(buffer, value[i], indent: indent + 2);
          if (i < value.length - 1) {
            buffer.writeln(',');
          } else {
            buffer.writeln();
          }
        }
        buffer.write('$indentStr]');
      }
    } else if (value is Map) {
      if (value.isEmpty) {
        buffer.write('{}');
      } else {
        buffer.writeln('{');
        final entries = value.entries.toList();
        for (int i = 0; i < entries.length; i++) {
          final entry = entries[i];
          buffer.write('$indentStr  "${entry.key}": ');
          _writeJsonValue(buffer, entry.value, indent: indent + 2);
          if (i < entries.length - 1) {
            buffer.writeln(',');
          } else {
            buffer.writeln();
          }
        }
        buffer.write('$indentStr}');
      }
    } else {
      buffer.write('"$value"');
    }
  }

  /// Escapes a string for JSON
  String _escapeJsonString(String s) {
    return s
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }

  /// Converts a Map to a YAML string
  String _convertToYaml(Map<String, dynamic> model) {
    // In a real implementation, use a YAML library
    // This is a placeholder for a basic YAML format
    StringBuffer buffer = StringBuffer();

    for (final entry in model.entries) {
      buffer.write('${entry.key}: ');
      _writeYamlValue(buffer, entry.value);
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Helper function to write a YAML value with proper indentation
  void _writeYamlValue(StringBuffer buffer, dynamic value, {int indent = 0}) {
    final indentStr = ' ' * indent;

    if (value is String) {
      // Quote strings that contain special characters
      if (_needsQuoting(value)) {
        buffer.write('"${_escapeYamlString(value)}"');
      } else {
        buffer.write(value);
      }
    } else if (value is num || value is bool || value == null) {
      buffer.write('$value');
    } else if (value is List) {
      if (value.isEmpty) {
        buffer.write('[]');
      } else {
        buffer.writeln();
        for (final item in value) {
          buffer.write('$indentStr- ');
          _writeYamlValue(buffer, item, indent: indent + 2);
          buffer.writeln();
        }
      }
    } else if (value is Map) {
      if (value.isEmpty) {
        buffer.write('{}');
      } else {
        buffer.writeln();
        for (final entry in value.entries) {
          buffer.write('$indentStr${entry.key}: ');
          _writeYamlValue(buffer, entry.value, indent: indent + 2);
          buffer.writeln();
        }
      }
    } else {
      buffer.write('$value');
    }
  }

  /// Checks if a string needs to be quoted in YAML
  bool _needsQuoting(String s) {
    final specialChars = RegExp(r'[:\{\}\[\],&\*#\?|\-<>=!%@`]');
    final numericStart = RegExp(r'^[\d\-]');
    return specialChars.hasMatch(s) ||
        numericStart.hasMatch(s) ||
        s.contains('\n');
  }

  /// Escapes a string for YAML
  String _escapeYamlString(String s) {
    return s
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }
}
