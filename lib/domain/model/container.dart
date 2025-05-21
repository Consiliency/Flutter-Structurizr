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
  Container addTag(String tag) {
    return copyWith(tags: [...tags, tag]);
  }
  
  @override
  Container addTags(List<String> newTags) {
    return copyWith(tags: [...tags, ...newTags]);
  }
  
  @override
  Container addProperty(String key, String value) {
    final updatedProperties = Map<String, String>.from(properties);
    updatedProperties[key] = value;
    return copyWith(properties: updatedProperties);
  }
  
  @override
  Container addRelationship({
    required String destinationId,
    required String description,
    String? technology,
    List<String> tags = const [],
    Map<String, String> properties = const {},
  }) {
    final newRelationship = Relationship(
      id: '$id-to-$destinationId', // Generate a relationship ID
      sourceId: id,
      destinationId: destinationId,
      description: description,
      technology: technology,
      tags: tags,
      properties: properties,
    );
    return copyWith(relationships: [...relationships, newRelationship]);
  }
  @override
  Relationship? getRelationshipById(String relationshipId) => null;
  @override
  List<Relationship> getRelationshipsTo(String destinationId) => const [];
  @override
  Container addChild(Element childNode) => this;
  @override
  Container setIdentifier(String identifier) => this;
  
  /// Add a component to this container
  Container addComponent(Component component) {
    return copyWith(
      components: [...components, component],
    );
  }
  
  /// Get a component by its ID
  Component? getComponentById(String componentId) {
    try {
      return components.firstWhere((component) => component.id == componentId);
    } catch (e) {
      return null;
    }
  }

  // Add this factory for test compatibility
  static Container create({
    required String name,
    String? parentId,
    String? description,
    String? technology,
    List<String>? tags,
  }) {
    return Container(
      id: name.replaceAll(' ', '_'),
      name: name,
      parentId: parentId ?? '',
      description: description,
      technology: technology,
      tags: [...(tags ?? []), 'Container'], // Add default Container tag
    );
  }
}
