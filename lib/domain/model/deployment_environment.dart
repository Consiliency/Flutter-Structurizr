import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:uuid/uuid.dart';

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
      _$DeploymentEnvironmentFromJson(json);

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
    return relationships.where((r) => r.destinationId == destinationId).toList();
  }

  /// Adds a deployment node to this environment.
  DeploymentEnvironment addDeploymentNode(DeploymentNode node) {
    return copyWith(deploymentNodes: [...deploymentNodes, node]);
  }
}