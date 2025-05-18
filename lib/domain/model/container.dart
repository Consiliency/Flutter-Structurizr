// This file is a placeholder for the Container class,
// which is actually defined in model.dart.
//
// The actual implementation is in model.dart.

// Re-export the Container class from model.dart
export 'model.dart' show Container;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_structurizr/domain/model/element.dart'
    show Element, Relationship, ElementListConverter;
import 'package:flutter_structurizr/domain/model/component.dart';

part 'container.freezed.dart';
part 'container.g.dart';

@freezed
class Container with _$Container implements Element {
  const Container._();

  const factory Container({
    required String id,
    required String name,
    String? description,
    @Default('Container') String type,
    @Default([]) List<String> tags,
    @Default({}) Map<String, String> properties,
    @Default([]) List<Relationship> relationships,
    String? parentId,
    String? technology,
    @Default([]) List<Component> components,
    @ElementListConverter() @Default([]) List<Element> children,
  }) = _Container;

  factory Container.fromJson(Map<String, dynamic> json) =>
      _$ContainerFromJson(json);

  @override
  Container addTag(String tag) => this;
  @override
  Container addTags(List<String> newTags) => this;
  @override
  Container addProperty(String key, String value) => this;
  @override
  Container addRelationship({
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
  Container addChild(Element childNode) => this;
  @override
  Container setIdentifier(String identifier) => this;

  // Add this factory for test compatibility
  static Container create({
    required String name,
    String? parentId,
    String? description,
    List<String>? tags,
  }) {
    return Container(
      id: name.replaceAll(' ', '_'),
      name: name,
      parentId: parentId ?? '',
      description: description,
      tags: tags ?? [],
    );
  }
}
