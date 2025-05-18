import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_structurizr/domain/model/element.dart'
    show Element, Relationship, ElementListConverter;

part 'container_instance.freezed.dart';
part 'container_instance.g.dart';

@freezed
class ContainerInstance with _$ContainerInstance implements Element {
  const ContainerInstance._();

  const factory ContainerInstance({
    required String id,
    required String containerId,
    required String name,
    String? description,
    @Default('ContainerInstance') String type,
    @Default([]) List<String> tags,
    @Default({}) Map<String, String> properties,
    @Default([]) List<Relationship> relationships,
    String? parentId,
    @ElementListConverter() @Default([]) List<Element> children,
  }) = _ContainerInstance;

  factory ContainerInstance.fromJson(Map<String, dynamic> json) =>
      _$ContainerInstanceFromJson(json);

  @override
  ContainerInstance addTag(String tag) => this;
  @override
  ContainerInstance addTags(List<String> newTags) => this;
  @override
  ContainerInstance addProperty(String key, String value) => this;
  @override
  ContainerInstance addRelationship({
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
  ContainerInstance addChild(Element childNode) => this;
  @override
  ContainerInstance setIdentifier(String identifier) => this;

  static ContainerInstance create({
    required String containerId,
    required String name,
    String? parentId,
    List<String>? tags,
  }) {
    return ContainerInstance(
      id: containerId + '_' + name.replaceAll(' ', '_'),
      containerId: containerId,
      name: name,
      parentId: parentId ?? '',
      tags: tags ?? [],
    );
  }
}
