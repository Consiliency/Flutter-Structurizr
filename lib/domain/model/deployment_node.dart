// This file is a placeholder for the DeploymentNode class,
// which is actually defined in model.dart.
//
// The actual implementation is in model.dart.

// Re-export the DeploymentNode class from model.dart
export 'model.dart' show DeploymentNode;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_structurizr/domain/model/element.dart'
    show Element, Relationship, ElementListConverter;
import 'package:flutter_structurizr/domain/model/infrastructure_node.dart';
import 'package:flutter_structurizr/domain/model/container_instance.dart';
import 'package:flutter_structurizr/domain/model/software_system_instance.dart';

part 'deployment_node.freezed.dart';
part 'deployment_node.g.dart';

@freezed
class DeploymentNode with _$DeploymentNode implements Element {
  const DeploymentNode._();

  const factory DeploymentNode({
    required String id,
    required String name,
    String? description,
    @Default('DeploymentNode') String type,
    @Default([]) List<String> tags,
    @Default({}) Map<String, String> properties,
    @Default([]) List<Relationship> relationships,
    String? parentId,
    String? environment,
    String? technology,
    @Default([]) List<DeploymentNode> children,
    @Default([]) List<InfrastructureNode> infrastructureNodes,
    @Default([]) List<ContainerInstance> containerInstances,
    @Default([]) List<SoftwareSystemInstance> softwareSystemInstances,
  }) = _DeploymentNode;

  factory DeploymentNode.fromJson(Map<String, dynamic> json) =>
      _$DeploymentNodeFromJson(json);

  @override
  DeploymentNode addTag(String tag) => this;
  @override
  DeploymentNode addTags(List<String> newTags) => this;
  @override
  DeploymentNode addProperty(String key, String value) => this;
  @override
  DeploymentNode addRelationship({
    required String destinationId,
    required String description,
    String? technology,
    List<String> tags = const [],
    Map<String, String> properties = const {},
  }) =>
      this;
  @override
  Relationship? getRelationshipById(String relationshipId) => null;
  @override
  List<Relationship> getRelationshipsTo(String destinationId) => const [];
  @override
  DeploymentNode addChild(Element childNode) => this;
  @override
  DeploymentNode setIdentifier(String identifier) => this;

  static DeploymentNode create({
    required String name,
    String? parentId,
    String? description,
    List<String>? tags,
  }) {
    return DeploymentNode(
      id: name.replaceAll(' ', '_'),
      name: name,
      parentId: parentId ?? '',
      description: description,
      tags: tags ?? [],
    );
  }
}
