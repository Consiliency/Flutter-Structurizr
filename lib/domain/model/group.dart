import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_structurizr/domain/model/element.dart'
    show Element, Relationship, ElementListConverter;
import 'package:uuid/uuid.dart';

part 'group.freezed.dart';
part 'group.g.dart';

/// Represents a group of elements in the architecture model.
@freezed
class Group with _$Group implements Element {
  const Group._();

  /// Creates a new group with the given properties.
  const factory Group({
    required String id,
    required String name,
    String? description,
    @Default('Group') String type,
    @Default([]) List<String> tags,
    @Default({}) Map<String, String> properties,
    @Default([]) List<Relationship> relationships,
    required String parentId,
    @ElementListConverter() @Default([]) List<Element> elements,
  }) = _Group;

  /// Creates a group from a JSON object.
  factory Group.fromJson(Map<String, dynamic> json) => _Group.fromJson(json);

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
      'elements': elements.map((e) => e.toJson()).toList(),
    };
  }

  /// Creates a new group with a generated ID.
  factory Group.create({
    required String name,
    required String parentId,
    String? description,
    List<String> tags = const [],
    Map<String, String> properties = const {},
    List<Element> elements = const [],
  }) {
    final id = const Uuid().v4();
    return Group(
      id: id,
      name: name,
      description: description,
      parentId: parentId,
      tags: [...tags],
      properties: properties,
      elements: elements,
    );
  }

  @override
  Group addTag(String tag) {
    return copyWith(tags: [...tags, tag]);
  }

  @override
  Group addTags(List<String> newTags) {
    return copyWith(tags: [...tags, ...newTags]);
  }

  @override
  Group addProperty(String key, String value) {
    final updatedProperties = Map<String, String>.from(properties);
    updatedProperties[key] = value;
    return copyWith(properties: updatedProperties);
  }

  @override
  Group addRelationship({
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

  /// Adds an element to this group.
  Group addElement(Element element) {
    return copyWith(elements: [...elements, element]);
  }

  /// Sets a property on this group.
  Group setProperty(String key, dynamic value) {
    final updatedProperties = Map<String, String>.from(properties);
    if (value is String) {
      updatedProperties[key] = value;
    } else {
      updatedProperties[key] = value.toString();
    }
    return copyWith(properties: updatedProperties);
  }

  @override
  Group addChild(Element childNode) {
    return copyWith(elements: [...elements, childNode]);
  }

  @override
  Group setIdentifier(String identifier) {
    return copyWith(id: identifier);
  }
}
