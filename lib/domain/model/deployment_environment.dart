import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_structurizr/domain/model/element.dart'
    show Element, Relationship, ElementListConverter;
import 'package:uuid/uuid.dart';
import 'package:flutter_structurizr/domain/model/deployment_node.dart';
import 'package:flutter_structurizr/domain/model/infrastructure_node.dart';
import 'package:flutter_structurizr/domain/model/container_instance.dart';

part 'deployment_environment.freezed.dart';
part 'deployment_environment.g.dart';

/// Represents a deployment environment (e.g., Development, Test, Production).
@freezed
class DeploymentEnvironment with _$DeploymentEnvironment implements Element {
  const DeploymentEnvironment._();

  /// Creates a new deployment environment with the given properties.
  const factory DeploymentEnvironment({
    required String id,
    required String name,
    String? description,
    @Default('DeploymentEnvironment') String type,
    @Default([]) List<String> tags,
    @Default({}) Map<String, String> properties,
    @Default([]) List<Relationship> relationships,
    String? parentId,
    @Default([]) List<DeploymentNode> deploymentNodes,
  }) = _DeploymentEnvironment;

  /// Creates a deployment environment from a JSON object.
  factory DeploymentEnvironment.fromJson(Map<String, dynamic> json) =>
      _DeploymentEnvironment.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'tags': tags,
      'properties': properties,
      'relationships': relationships.map((r) => r.toJson()).toList(),
      'parentId': parentId,
      'deploymentNodes': deploymentNodes.map((n) => n.toJson()).toList(),
    };
  }

  /// Creates a new deployment environment with a generated ID.
  factory DeploymentEnvironment.create({
    required String name,
    String? description,
    String? parentId,
    List<String> tags = const [],
    Map<String, String> properties = const {},
    List<DeploymentNode> deploymentNodes = const [],
  }) {
    final id = const Uuid().v4();
    return DeploymentEnvironment(
      id: id,
      name: name,
      description: description,
      parentId: parentId,
      tags: [...tags],
      properties: properties,
      deploymentNodes: deploymentNodes,
    );
  }

  @override
  DeploymentEnvironment addTag(String tag) {
    return copyWith(tags: [...tags, tag]);
  }

  @override
  DeploymentEnvironment addTags(List<String> newTags) {
    return copyWith(tags: [...tags, ...newTags]);
  }

  @override
  DeploymentEnvironment addProperty(String key, String value) {
    final updatedProperties = Map<String, String>.from(properties);
    updatedProperties[key] = value;
    return copyWith(properties: updatedProperties);
  }

  @override
  DeploymentEnvironment addRelationship({
    required String destinationId,
    required String description,
    String? technology,
    List<String> tags = const [],
    Map<String, String> properties = const {},
  }) {
    final relationship = Relationship(
      id: const Uuid().v4(),
      sourceId: id,
      destinationId: destinationId,
      description: description,
      technology: technology,
      tags: tags,
      properties: properties,
    );

    return copyWith(relationships: [...relationships, relationship]);
  }

  @override
  Relationship? getRelationshipById(String relationshipId) {
    try {
      return relationships.firstWhere((r) => r.id == relationshipId);
    } catch (_) {
      return null;
    }
  }

  @override
  List<Relationship> getRelationshipsTo(String destinationId) {
    return relationships
        .where((r) => r.destinationId == destinationId)
        .toList();
  }

  /// Adds a deployment node to this environment.
  DeploymentEnvironment addDeploymentNode(DeploymentNode node) {
    return copyWith(deploymentNodes: [...deploymentNodes, node]);
  }

  /// Finds a deployment node by its name in this environment.
  /// Returns null if no deployment node is found with the given name.
  DeploymentNode? findDeploymentNodeByName(String name,
      {bool ignoreCase = false}) {
    // First try direct children
    DeploymentNode? result = _findDeploymentNodeByNameInList(
        deploymentNodes, name,
        ignoreCase: ignoreCase);

    // If not found, search recursively in children
    if (result == null) {
      for (final node in deploymentNodes) {
        result = _findDeploymentNodeByNameInNestedChildren(node, name,
            ignoreCase: ignoreCase);
        if (result != null) break;
      }
    }

    return result;
  }

  /// Helper method to find a deployment node by name in a list of nodes
  DeploymentNode? _findDeploymentNodeByNameInList(
      List<DeploymentNode> nodes, String name,
      {bool ignoreCase = false}) {
    if (ignoreCase) {
      final lowerName = name.toLowerCase();
      try {
        return nodes.firstWhere(
          (node) => node.name.toLowerCase() == lowerName,
        );
      } catch (_) {
        return null;
      }
    } else {
      try {
        return nodes.firstWhere(
          (node) => node.name == name,
        );
      } catch (_) {
        return null;
      }
    }
  }

  /// Helper method to recursively find a deployment node by name in child nodes
  DeploymentNode? _findDeploymentNodeByNameInNestedChildren(
      DeploymentNode parentNode, String name,
      {bool ignoreCase = false}) {
    // First check direct children
    DeploymentNode? result = _findDeploymentNodeByNameInList(
        parentNode.children, name,
        ignoreCase: ignoreCase);

    // If not found, recursively search in each child's children
    if (result == null) {
      for (final child in parentNode.children) {
        result = _findDeploymentNodeByNameInNestedChildren(child, name,
            ignoreCase: ignoreCase);
        if (result != null) break;
      }
    }

    return result;
  }

  /// Finds an infrastructure node by its name in this environment.
  /// Returns null if no infrastructure node is found with the given name.
  InfrastructureNode? findInfrastructureNodeByName(String name,
      {bool ignoreCase = false}) {
    // Search through all deployment nodes and their children
    for (final node in deploymentNodes) {
      InfrastructureNode? result = _findInfrastructureNodeByNameInNode(
          node, name,
          ignoreCase: ignoreCase);
      if (result != null) return result;
    }

    return null;
  }

  /// Helper method to recursively find an infrastructure node by name in a deployment node hierarchy
  InfrastructureNode? _findInfrastructureNodeByNameInNode(
      DeploymentNode node, String name,
      {bool ignoreCase = false}) {
    // Check infrastructure nodes in this node
    InfrastructureNode? result = _findInfrastructureNodeByNameInList(
        node.infrastructureNodes, name,
        ignoreCase: ignoreCase);

    // If not found, search in child deployment nodes
    if (result == null) {
      for (final childNode in node.children) {
        result = _findInfrastructureNodeByNameInNode(childNode, name,
            ignoreCase: ignoreCase);
        if (result != null) break;
      }
    }

    return result;
  }

  /// Helper method to find an infrastructure node by name in a list of nodes
  InfrastructureNode? _findInfrastructureNodeByNameInList(
      List<InfrastructureNode> nodes, String name,
      {bool ignoreCase = false}) {
    if (ignoreCase) {
      final lowerName = name.toLowerCase();
      try {
        return nodes.firstWhere(
          (node) => node.name.toLowerCase() == lowerName,
        );
      } catch (_) {
        return null;
      }
    } else {
      try {
        return nodes.firstWhere(
          (node) => node.name == name,
        );
      } catch (_) {
        return null;
      }
    }
  }

  /// Finds a container instance for a given container in this environment.
  /// Returns null if no container instance is found for the given container.
  ContainerInstance? findContainerInstanceForContainer(String containerId) {
    // Search through all deployment nodes and their children
    for (final node in deploymentNodes) {
      ContainerInstance? result =
          _findContainerInstanceInNode(node, containerId);
      if (result != null) return result;
    }

    return null;
  }

  /// Helper method to recursively find a container instance in a deployment node hierarchy
  ContainerInstance? _findContainerInstanceInNode(
      DeploymentNode node, String containerId) {
    // Check container instances in this node
    try {
      return node.containerInstances.firstWhere(
        (instance) => instance.containerId == containerId,
      );
    } catch (_) {
      // Not found, search in child deployment nodes
      for (final childNode in node.children) {
        final result = _findContainerInstanceInNode(childNode, containerId);
        if (result != null) return result;
      }

      return null;
    }
  }

  /// Finds a relationship between two elements in this environment.
  /// Returns null if no relationship is found.
  Relationship? findRelationshipBetween(String sourceId, String destinationId,
      [String? description]) {
    // Check relationships directly on the environment
    Relationship? foundRelationship = _findRelationshipInList(
        relationships, sourceId, destinationId, description);

    // If not found, search in deployment nodes
    if (foundRelationship == null) {
      for (final node in deploymentNodes) {
        foundRelationship = _findRelationshipInDeploymentNode(
            node, sourceId, destinationId, description);
        if (foundRelationship != null) break;
      }
    }

    return foundRelationship;
  }

  /// Helper method to find a relationship in a list of relationships
  Relationship? _findRelationshipInList(
      List<Relationship> relationships, String sourceId, String destinationId,
      [String? description]) {
    try {
      if (description != null) {
        return relationships.firstWhere(
          (r) =>
              r.sourceId == sourceId &&
              r.destinationId == destinationId &&
              r.description == description,
        );
      } else {
        return relationships.firstWhere(
          (r) => r.sourceId == sourceId && r.destinationId == destinationId,
        );
      }
    } catch (_) {
      return null;
    }
  }

  /// Helper method to recursively find a relationship in a deployment node hierarchy
  Relationship? _findRelationshipInDeploymentNode(
      DeploymentNode node, String sourceId, String destinationId,
      [String? description]) {
    // Check relationships in this node
    Relationship? foundRelationship = _findRelationshipInList(
        node.relationships, sourceId, destinationId, description);

    // If not found, check in infrastructure nodes
    if (foundRelationship == null) {
      for (final infraNode in node.infrastructureNodes) {
        foundRelationship = _findRelationshipInList(
            infraNode.relationships, sourceId, destinationId, description);
        if (foundRelationship != null) break;
      }
    }

    // If not found, check in container instances
    if (foundRelationship == null) {
      for (final containerInstance in node.containerInstances) {
        foundRelationship = _findRelationshipInList(
            containerInstance.relationships,
            sourceId,
            destinationId,
            description);
        if (foundRelationship != null) break;
      }
    }

    // If not found, recursively search in child deployment nodes
    if (foundRelationship == null) {
      for (final childNode in node.children) {
        foundRelationship = _findRelationshipInDeploymentNode(
            childNode, sourceId, destinationId, description);
        if (foundRelationship != null) break;
      }
    }

    return foundRelationship;
  }

  @override
  DeploymentEnvironment addChild(Element childNode) {
    if (childNode is DeploymentNode) {
      return copyWith(deploymentNodes: [...deploymentNodes, childNode]);
    }
    throw ArgumentError(
        'DeploymentEnvironment can only have DeploymentNode children');
  }

  @override
  DeploymentEnvironment setIdentifier(String identifier) {
    return copyWith(id: identifier);
  }
}
