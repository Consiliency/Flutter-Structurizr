import 'dart:convert';

import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/view/model_view.dart';

/// Helper class for JSON serialization and deserialization.
class JsonSerializationHelper {
  const JsonSerializationHelper._();
  
  /// Converts a workspace to a JSON string.
  static String workspaceToJson(Workspace workspace) {
    return jsonEncode(workspace.toJson());
  }
  
  /// Creates a workspace from a JSON string.
  static Workspace workspaceFromJson(String json) {
    return Workspace.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }
  
  /// Pretty prints a workspace as formatted JSON.
  static String prettyPrintWorkspace(Workspace workspace) {
    final encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(workspace.toJson());
  }
  
  /// Converts a list of elements to a JSON string.
  static String elementsToJson(List<Element> elements) {
    return jsonEncode(elements.map((e) => _elementToJson(e)).toList());
  }
  
  /// Converts an element to a JSON map based on its type.
  static Map<String, dynamic> _elementToJson(Element element) {
    // We need to use dynamic serialization based on element type
    // This would typically be implemented through a visitor pattern
    // For now, we'll use a simple switch on element.type
    
    switch (element.type) {
      case 'Person':
        // Cast element to specific type if needed
        // Use the toJson method from the generated code
        return {'type': 'Person', 'id': element.id, 'name': element.name};
      case 'SoftwareSystem':
        return {'type': 'SoftwareSystem', 'id': element.id, 'name': element.name};
      case 'Container':
        return {'type': 'Container', 'id': element.id, 'name': element.name};
      case 'Component':
        return {'type': 'Component', 'id': element.id, 'name': element.name};
      case 'DeploymentNode':
        return {'type': 'DeploymentNode', 'id': element.id, 'name': element.name};
      // Add cases for other element types
      default:
        return {'type': element.type, 'id': element.id, 'name': element.name};
    }
  }
  
  // Temporarily removing view-related code until View type conflicts are resolved
  /*
  /// Converts a list of views to a JSON string.
  static String viewsToJson(List<View> views) {
    return jsonEncode(views.map((v) => _viewToJson(v)).toList());
  }

  /// Converts a view to a JSON map based on its type.
  static Map<String, dynamic> _viewToJson(View view) {
    // Simple basic implementation
    return {
      'type': view.viewType,
      'key': view.key,
      'title': view.title,
    };
  }
  */
  
  /// Validates JSON string against Structurizr schema.
  static List<String> validateJson(String json) {
    final errors = <String>[];
    
    try {
      final decoded = jsonDecode(json);
      
      // Basic validation checks
      if (decoded is! Map<String, dynamic>) {
        errors.add('Invalid JSON: Root object must be a map');
        return errors;
      }
      
      final map = decoded as Map<String, dynamic>;
      
      // Check required root fields
      if (!map.containsKey('id')) {
        errors.add('Missing required field "id"');
      }
      
      if (!map.containsKey('name')) {
        errors.add('Missing required field "name"');
      }
      
      if (!map.containsKey('model')) {
        errors.add('Missing required field "model"');
      }
      
      // Verify model structure
      if (map.containsKey('model')) {
        final model = map['model'];
        if (model is! Map<String, dynamic>) {
          errors.add('Invalid "model" field: Must be an object');
        }
      }
      
      // Verify views structure
      if (map.containsKey('views')) {
        final views = map['views'];
        if (views is! Map<String, dynamic>) {
          errors.add('Invalid "views" field: Must be an object');
        }
      }
      
    } catch (e) {
      errors.add('Invalid JSON: ${e.toString()}');
    }
    
    return errors;
  }
  
  /// Converts a JSON string to a map for direct access.
  static Map<String, dynamic>? jsonToMap(String json) {
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}