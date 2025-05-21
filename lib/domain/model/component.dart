// This file is a placeholder for the Component class,
// which is actually defined in model.dart.
//
// The actual implementation is in model.dart.

// Re-export the Component class from model.dart
// export 'model.dart' show Component;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_structurizr/domain/model/element.dart'
    show Element, Relationship, ElementListConverter;

part 'component.freezed.dart';
part 'component.g.dart';

@freezed
class Component with _$Component implements Element {
  const Component._();

  const factory Component({
    required String id,
    required String name,
    String? description,
    @Default('Component') String type,
    @Default([]) List<String> tags,
    @Default({}) Map<String, String> properties,
    @Default([]) List<Relationship> relationships,
    String? parentId,
    String? technology,
    @ElementListConverter() @Default([]) List<Element> children,
  }) = _Component;

  factory Component.fromJson(Map<String, dynamic> json) =>
      _$ComponentFromJson(json);

  @override
  Component addTag(String tag) {
    return copyWith(tags: [...tags, tag]);
  }
  
  @override
  Component addTags(List<String> newTags) {
    return copyWith(tags: [...tags, ...newTags]);
  }
  
  @override
  Component addProperty(String key, String value) {
    final updatedProperties = Map<String, String>.from(properties);
    updatedProperties[key] = value;
    return copyWith(properties: updatedProperties);
  }
  
  @override
  Component addRelationship({
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
  Component addChild(Element childNode) => this;
  @override
  Component setIdentifier(String identifier) => this;

  static Component create({
    required String name,
    String? parentId,
    String? description,
    String? technology,
    List<String>? tags,
  }) {
    return Component(
      id: name.replaceAll(' ', '_'),
      name: name,
      parentId: parentId ?? '',
      description: description,
      technology: technology,
      tags: tags ?? [],
    );
  }
}
