import 'dart:convert';
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';

/// Utility class for JSON serialization and deserialization of Structurizr models.
class JsonSerialization {
  const JsonSerialization._(); // Private constructor to prevent instantiation

  /// Converts a JSON string to a Workspace object.
  static Workspace workspaceFromJson(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return Workspace.fromJson(json);
    } catch (e) {
      throw JsonParsingException(
        'Failed to parse Workspace JSON: ${e.toString()}',
        jsonString,
      );
    }
  }

  /// Converts a Workspace object to a JSON string.
  static String workspaceToJson(Workspace workspace) {
    return jsonEncode(workspace.toJson());
  }

  /// Converts a JSON string to a Model object.
  static Model modelFromJson(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return Model.fromJson(json);
    } catch (e) {
      throw JsonParsingException(
        'Failed to parse Model JSON: ${e.toString()}',
        jsonString,
      );
    }
  }

  /// Converts a Model object to a JSON string.
  static String modelToJson(Model model) {
    return jsonEncode(model.toJson());
  }

  /// Converts a JSON string to an Element object based on the element type.
  static Element elementFromJson(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final type = json['type'] as String? ?? 'Element';

      switch (type) {
        case 'Person':
          return Person.fromJson(json);
        case 'SoftwareSystem':
          return SoftwareSystem.fromJson(json);
        case 'Container':
          return Container.fromJson(json);
        case 'Component':
          return Component.fromJson(json);
        case 'DeploymentNode':
          return DeploymentNode.fromJson(json);
        case 'InfrastructureNode':
          return InfrastructureNode.fromJson(json);
        case 'ContainerInstance':
          return ContainerInstance.fromJson(json);
        case 'SoftwareSystemInstance':
          return SoftwareSystemInstance.fromJson(json);
        default:
          throw JsonParsingException(
            'Unknown element type: $type',
            jsonEncode(json),
          );
      }
    } catch (e) {
      if (e is JsonParsingException) {
        throw e;
      } else {
        throw JsonParsingException(
          'Failed to parse Element JSON: ${e.toString()}',
          jsonString,
        );
      }
    }
  }

  /// Converts an Element object to a JSON string.
  static String elementToJson(Element element) {
    // Handle different element types since Element is an interface
    if (element is Person) {
      return jsonEncode(element.toJson());
    } else if (element is SoftwareSystem) {
      // Convert the containers to JSON manually to avoid type casting issues
      final json = element.toJson();
      if (json.containsKey('containers') && json['containers'] is List) {
        final List<dynamic> containersList = json['containers'] as List;
        final List<Map<String, dynamic>> containersJson = containersList
            .map((container) {
              if (container is Container) {
                return container.toJson();
              } else if (container is Map<String, dynamic>) {
                return container;
              } else {
                return {'error': 'Invalid container type: ${container.runtimeType}'};
              }
            })
            .toList();
        json['containers'] = containersJson;
      }
      return jsonEncode(json);
    } else if (element is Container) {
      // Handle components similar to containers in SoftwareSystem
      final json = element.toJson();
      if (json.containsKey('components') && json['components'] is List) {
        final List<dynamic> componentsList = json['components'] as List;
        final List<Map<String, dynamic>> componentsJson = componentsList
            .map((component) {
              if (component is Component) {
                return component.toJson();
              } else if (component is Map<String, dynamic>) {
                return component;
              } else {
                return {'error': 'Invalid component type: ${component.runtimeType}'};
              }
            })
            .toList();
        json['components'] = componentsJson;
      }
      return jsonEncode(json);
    } else if (element is Component) {
      return jsonEncode(element.toJson());
    } else if (element is DeploymentNode) {
      return jsonEncode(element.toJson());
    } else if (element is InfrastructureNode) {
      return jsonEncode(element.toJson());
    } else if (element is ContainerInstance) {
      return jsonEncode(element.toJson());
    } else if (element is SoftwareSystemInstance) {
      return jsonEncode(element.toJson());
    } else if (element is BasicElement) {
      // BasicElement doesn't have toJson, so create a map manually
      return jsonEncode({
        'id': element.id,
        'name': element.name,
        'description': element.description,
        'type': element.type,
        'tags': element.tags,
        'properties': element.properties,
        'parentId': element.parentId,
        'relationships': element.relationships.map((r) => r.toJson()).toList(),
      });
    } else {
      throw UnimplementedError('toJson not implemented for element type: ${element.runtimeType}');
    }
  }

  /// Converts a JSON string to a Styles object.
  static Styles stylesFromJson(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return Styles.fromJson(json);
    } catch (e) {
      throw JsonParsingException(
        'Failed to parse Styles JSON: ${e.toString()}',
        jsonString,
      );
    }
  }

  /// Converts a Styles object to a JSON string.
  static String stylesToJson(Styles styles) {
    return jsonEncode(styles.toJson());
  }

  /// Parses a JSON object as a List of elements of the given type T.
  static List<T> parseList<T>(
    Map<String, dynamic> json,
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final list = json[key] as List<dynamic>?;
    if (list == null) return [];
    
    return list
        .cast<Map<String, dynamic>>()
        .map((e) => fromJson(e))
        .toList();
  }

  /// Validates a JSON string against the Structurizr JSON schema.
  /// Returns true if valid, false otherwise.
  static bool validateWorkspaceJson(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Basic schema validation
      if (!json.containsKey('id')) return false;
      if (!json.containsKey('name')) return false;
      if (!json.containsKey('model')) return false;
      
      // Model validation
      final model = json['model'] as Map<String, dynamic>?;
      if (model == null) return false;
      
      // Convert to a workspace and check business rules
      final workspace = Workspace.fromJson(json);
      final errors = workspace.validate();
      
      return errors.isEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Handles errors during JSON parsing.
  /// Throws a [JsonParsingException] with a detailed error message.
  static void handleJsonError(dynamic error, String jsonString) {
    // FormatException indicates invalid JSON syntax
    if (error is FormatException) {
      throw JsonParsingException(
        'Invalid JSON syntax: ${error.message}',
        jsonString,
      );
    }
    
    // TypeError indicates JSON format doesn't match expected model
    if (error is TypeError) {
      throw JsonParsingException(
        'JSON schema mismatch: ${error.toString()}',
        jsonString,
      );
    }
    
    // Generic error handling
    throw JsonParsingException(
      'Error parsing JSON: ${error.toString()}',
      jsonString,
    );
  }
}

/// Exception thrown when JSON parsing fails.
class JsonParsingException implements Exception {
  final String message;
  final String jsonString;
  
  JsonParsingException(this.message, this.jsonString);
  
  @override
  String toString() => 'JsonParsingException: $message';
}