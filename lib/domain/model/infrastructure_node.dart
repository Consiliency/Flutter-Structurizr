// This file is a placeholder for the InfrastructureNode class,
// which is actually defined in model.dart.
//
// The actual implementation is in model.dart.

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_structurizr/domain/model/element.dart'
    show Element, Relationship, ElementListConverter;

part 'infrastructure_node.freezed.dart';
part 'infrastructure_node.g.dart';

@freezed
class InfrastructureNode with _$InfrastructureNode implements Element {
  const InfrastructureNode._();

  const factory InfrastructureNode({
    required String id,
    required String name,
    String? description,
    @Default('InfrastructureNode') String type,
    @Default([]) List<String> tags,
    @Default({}) Map<String, String> properties,
    @Default([]) List<Relationship> relationships,
    String? parentId,
    @ElementListConverter() @Default([]) List<Element> children,
  }) = _InfrastructureNode;

  factory InfrastructureNode.fromJson(Map<String, dynamic> json) =>
      _$InfrastructureNodeFromJson(json);

  @override
  InfrastructureNode addTag(String tag) => this;
  @override
  InfrastructureNode addTags(List<String> newTags) => this;
  @override
  InfrastructureNode addProperty(String key, String value) => this;
  @override
  InfrastructureNode addRelationship({
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
  InfrastructureNode addChild(Element childNode) => this;
  @override
  InfrastructureNode setIdentifier(String identifier) => this;

  static InfrastructureNode create({
    required String name,
    String? parentId,
    String? description,
    List<String>? tags,
  }) {
    return InfrastructureNode(
      id: name.replaceAll(' ', '_'),
      name: name,
      parentId: parentId ?? '',
      description: description,
      tags: tags ?? [],
    );
  }
}
