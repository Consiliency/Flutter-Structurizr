import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_structurizr/domain/model/element.dart'
    show Element, Relationship, ElementListConverter;
import 'package:flutter_structurizr/domain/model/group.dart';
import 'package:uuid/uuid.dart';

part 'enterprise.freezed.dart';
part 'enterprise.g.dart';

/// Represents an enterprise in the architecture model.
@freezed
class Enterprise with _$Enterprise implements Element {
  const Enterprise._();

  /// Creates a new enterprise with the given properties.
  const factory Enterprise({
    required String id,
    required String name,
    String? description,
    @Default('Enterprise') String type,
    @Default([]) List<String> tags,
    @Default({}) Map<String, String> properties,
    @Default([]) List<Relationship> relationships,
    String? parentId,
    @Default([]) List<Group> groups,
  }) = _Enterprise;

  /// Creates an enterprise from a JSON object.
  factory Enterprise.fromJson(Map<String, dynamic> json) =>
      _Enterprise.fromJson(json);

  /// Creates a new enterprise with a generated ID.
  factory Enterprise.create({
    required String name,
    String? description,
    List<String> tags = const [],
    Map<String, String> properties = const {},
    List<Group> groups = const [],
  }) {
    final id = const Uuid().v4();
    return Enterprise(
      id: id,
      name: name,
      description: description,
      tags: [...tags],
      properties: properties,
      groups: groups,
    );
  }

  @override
  Enterprise addTag(String tag) {
    return copyWith(tags: [...tags, tag]);
  }

  @override
  Enterprise addTags(List<String> newTags) {
    return copyWith(tags: [...tags, ...newTags]);
  }

  @override
  Enterprise addProperty(String key, String value) {
    final updatedProperties = Map<String, String>.from(properties);
    updatedProperties[key] = value;
    return copyWith(properties: updatedProperties);
  }

  @override
  Enterprise addRelationship({
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

  /// Adds a group to this enterprise.
  Enterprise addGroup(Group group) {
    return copyWith(groups: [...groups, group]);
  }

  /// Sets a property on this enterprise.
  Enterprise setProperty(String key, dynamic value) {
    final updatedProperties = Map<String, String>.from(properties);
    if (value is String) {
      updatedProperties[key] = value;
    } else {
      updatedProperties[key] = value.toString();
    }
    return copyWith(properties: updatedProperties);
  }

  @override
  String? get parentId => null;

  @override
  Enterprise addChild(Element childNode) {
    if (childNode is Group) {
      return copyWith(groups: [...groups, childNode]);
    }
    throw ArgumentError('Enterprise can only have Group children');
  }

  @override
  Enterprise setIdentifier(String identifier) {
    return copyWith(id: identifier);
  }

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
      'groups': groups.map((g) => g.toJson()).toList(),
    };
  }
}
