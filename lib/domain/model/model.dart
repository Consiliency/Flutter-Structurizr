import 'package:flutter_structurizr/domain/model/element.dart'
    show Element, Relationship, ElementListConverter;
import 'package:flutter_structurizr/domain/model/deployment_environment.dart';
import 'package:flutter_structurizr/domain/model/modeled_relationship.dart';
import 'package:flutter_structurizr/domain/model/group.dart';
import 'package:flutter_structurizr/domain/model/enterprise.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_structurizr/domain/model/deployment_node.dart';
import 'package:flutter_structurizr/domain/model/container.dart';
import 'package:flutter_structurizr/domain/model/component.dart';

part 'model.freezed.dart';
part 'model.g.dart';

/// Represents the architecture model containing all elements and their relationships.
///
/// The model is the container for all architecture elements (people, systems, containers,
/// components) and the relationships between them.
@freezed
class Model with _$Model {
  const Model._();

  /// Creates a new model with the given properties.
  const factory Model({
    /// Enterprise name if this model represents a specific enterprise.
    String? enterpriseName,

    /// List of people in the model.
    @Default([]) List<Person> people,

    /// List of software systems in the model.
    @Default([]) List<SoftwareSystem> softwareSystems,

    /// List of deployment nodes in the model.
    @Default([]) List<DeploymentNode> deploymentNodes,

    /// List of deployment environments in the model.
    @Default([]) List<DeploymentEnvironment> deploymentEnvironments,

    /// List of groups in the model.
    @Default([]) List<Group> groups,

    /// The enterprise in the model.
    Enterprise? enterprise,

    /// List of implied relationships in the model.
    @Default([]) List<Relationship> impliedRelationships,

    /// Map of advanced properties for the model.
    @Default({}) Map<String, dynamic> advancedProperties,
  }) = _Model;

  /// Creates a model from a JSON object.
  factory Model.fromJson(Map<String, dynamic> json) => _$ModelFromJson(json);

  /// Gets all elements in the model.
  List<Element> getAllElements() {
    final elements = <Element>[];

    // Add people
    elements.addAll(people);

    // Add enterprise if present
    if (enterprise != null) {
      elements.add(enterprise!);
    }

    // Add groups
    elements.addAll(groups);

    // Add software systems and their containers/components
    for (final system in softwareSystems) {
      elements.add(system);

      for (final container in system.containers) {
        elements.add(container);
        elements.addAll(container.components);
      }
    }

    // Add deployment nodes and their contained elements
    for (final node in deploymentNodes) {
      elements.add(node);
      elements.addAll(_getDeploymentNodeElements(node));
    }

    return elements;
  }

  /// Getter for all elements in the model.
  List<Element> get elements => getAllElements();

  /// Gets all elements in a deployment node recursively.
  List<Element> _getDeploymentNodeElements(DeploymentNode node) {
    final elements = <Element>[];

    elements.addAll(node.infrastructureNodes);
    elements.addAll(node.containerInstances);
    elements.addAll(node.softwareSystemInstances);

    for (final childNode in node.children) {
      elements.add(childNode);
      elements.addAll(_getDeploymentNodeElements(childNode));
    }

    return elements;
  }

  /// Gets all relationships in the model.
  List<Relationship> getAllRelationships() {
    final relationships = <Relationship>[];

    for (final element in getAllElements()) {
      relationships.addAll(element.relationships);
    }

    // Add implied relationships
    relationships.addAll(impliedRelationships);

    return relationships;
  }

  /// Getter for all relationships in the model.
  /// Returns the same result as getAllRelationships() for convenience.
  List<Relationship> get relationships => getAllRelationships();

  /// Finds an element by its ID.
  Element? getElementById(String id) {
    try {
      return getAllElements().firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Adds a person to the model.
  Model addPerson(Person person) {
    return copyWith(people: [...people, person]);
  }

  /// Adds a software system to the model.
  Model addSoftwareSystem(SoftwareSystem system) {
    return copyWith(softwareSystems: [...softwareSystems, system]);
  }

  /// Adds a deployment node to the model.
  Model addDeploymentNode(DeploymentNode node) {
    return copyWith(deploymentNodes: [...deploymentNodes, node]);
  }

  /// Adds a group to the model.
  Model addGroup(Group group) {
    return copyWith(groups: [...groups, group]);
  }

  /// Adds an enterprise to the model.
  Model addEnterprise(Enterprise enterpriseNode) {
    return copyWith(enterprise: enterpriseNode);
  }

  /// Adds an element to the model.
  Model addElement(Element element) {
    if (element is Person) {
      return addPerson(element);
    } else if (element is SoftwareSystem) {
      return addSoftwareSystem(element);
    } else if (element is DeploymentNode) {
      return addDeploymentNode(element);
    } else if (element is Group) {
      return addGroup(element);
    } else if (element is Enterprise) {
      return addEnterprise(element);
    } else {
      throw ArgumentError('Unsupported element type: ${element.runtimeType}');
    }
  }

  /// Adds a relationship to the model.
  Model addRelationship(Relationship relationship) {
    // Relationships are owned by elements, so we need to find the element
    // and add the relationship to it
    final sourceElement = getElementById(relationship.sourceId);
    if (sourceElement == null) {
      throw ArgumentError('Source element not found: ${relationship.sourceId}');
    }

    // Since elements are immutable, we need to create a new element with the relationship added
    // and then update the model with the new element
    final updatedElement = sourceElement.addRelationship(
      destinationId: relationship.destinationId,
      description: relationship.description,
      technology: relationship.technology,
      tags: relationship.tags,
      properties: relationship.properties,
    );

    return addElement(updatedElement);
  }

  /// Adds an implied relationship to the model.
  Model addImpliedRelationship(Relationship relationship) {
    return copyWith(
        impliedRelationships: [...impliedRelationships, relationship]);
  }

  /// Sets an advanced property on the model.
  Model setAdvancedProperty(String key, dynamic value) {
    final updatedProperties = Map<String, dynamic>.from(advancedProperties);
    updatedProperties[key] = value;
    return copyWith(advancedProperties: updatedProperties);
  }

  /// Validates the model for consistency.
  /// Returns a list of validation errors, or an empty list if valid.
  List<String> validate() {
    final errors = <String>[];
    final elementIds = <String>{};

    // Check for duplicate element IDs
    for (final element in getAllElements()) {
      if (elementIds.contains(element.id)) {
        errors.add('Duplicate element ID: ${element.id}');
      } else {
        elementIds.add(element.id);
      }
    }

    // Check for valid relationship references
    for (final element in getAllElements()) {
      for (final relationship in element.relationships) {
        if (!elementIds.contains(relationship.destinationId)) {
          errors.add(
            'Relationship ${relationship.id} references non-existent destination: '
            '${relationship.destinationId}',
          );
        }
      }
    }

    return errors;
  }

  /// Finds a person by their name.
  /// Returns null if no person is found with the given name.
  Person? findPersonByName(String name, {bool ignoreCase = false}) {
    if (ignoreCase) {
      final lowerName = name.toLowerCase();
      return people.firstWhere(
        (person) => person.name.toLowerCase() == lowerName,
        orElse: () => const Person(id: '', name: ''),
      );
    } else {
      return people.firstWhere(
        (person) => person.name == name,
        orElse: () => const Person(id: '', name: ''),
      );
    }
  }

  /// Finds a software system by its name.
  /// Returns null if no software system is found with the given name.
  SoftwareSystem? findSoftwareSystemByName(String name,
      {bool ignoreCase = false}) {
    if (ignoreCase) {
      final lowerName = name.toLowerCase();
      return softwareSystems.firstWhere(
        (system) => system.name.toLowerCase() == lowerName,
        orElse: () => const SoftwareSystem(id: '', name: ''),
      );
    } else {
      return softwareSystems.firstWhere(
        (system) => system.name == name,
        orElse: () => const SoftwareSystem(id: '', name: ''),
      );
    }
  }

  /// Finds a container by its name within a software system.
  /// Returns null if no container is found with the given name.
  Container? findContainerByName(String name,
      {String? softwareSystemId, bool ignoreCase = false}) {
    if (softwareSystemId != null) {
      final system = getSoftwareSystemById(softwareSystemId);
      if (system == null) return null;

      if (ignoreCase) {
        final lowerName = name.toLowerCase();
        try {
          return system.containers.firstWhere(
            (container) => container.name.toLowerCase() == lowerName,
          );
        } catch (_) {
          return null;
        }
      } else {
        try {
          return system.containers.firstWhere(
            (container) => container.name == name,
          );
        } catch (_) {
          return null;
        }
      }
    } else {
      // Search across all software systems
      for (final system in softwareSystems) {
        Container? container;

        if (ignoreCase) {
          final lowerName = name.toLowerCase();
          try {
            container = system.containers.firstWhere(
              (c) => c.name.toLowerCase() == lowerName,
            );
          } catch (_) {
            container = null;
          }
        } else {
          try {
            container = system.containers.firstWhere(
              (c) => c.name == name,
            );
          } catch (_) {
            container = null;
          }
        }

        if (container != null) {
          return container;
        }
      }

      return null;
    }
  }

  /// Finds a component by its name within a container.
  /// Returns null if no component is found with the given name.
  Component? findComponentByName(String name,
      {String? containerId, bool ignoreCase = false}) {
    if (containerId != null) {
      // First, find the container
      Container? container;
      for (final system in softwareSystems) {
        final foundContainer = system.getContainerById(containerId);
        if (foundContainer != null) {
          container = foundContainer;
          break;
        }
      }

      if (container == null) return null;

      if (ignoreCase) {
        final lowerName = name.toLowerCase();
        try {
          return container.components.firstWhere(
            (component) => component.name.toLowerCase() == lowerName,
          );
        } catch (_) {
          return null;
        }
      } else {
        try {
          return container.components.firstWhere(
            (component) => component.name == name,
          );
        } catch (_) {
          return null;
        }
      }
    } else {
      // Search across all containers in all systems
      for (final system in softwareSystems) {
        for (final container in system.containers) {
          Component? component;

          if (ignoreCase) {
            final lowerName = name.toLowerCase();
            try {
              component = container.components.firstWhere(
                (c) => c.name.toLowerCase() == lowerName,
              );
            } catch (_) {
              component = null;
            }
          } else {
            try {
              component = container.components.firstWhere(
                (c) => c.name == name,
              );
            } catch (_) {
              component = null;
            }
          }

          if (component != null) {
            return component;
          }
        }
      }

      return null;
    }
  }

  /// Finds a relationship between two elements.
  /// Returns a ModeledRelationship that provides access to source and destination elements.
  /// Returns null if no such relationship exists.
  ModeledRelationship? findRelationshipBetween(
      String sourceId, String destinationId,
      [String? description]) {
    final source = getElementById(sourceId);
    if (source == null) return null;

    Relationship? foundRelationship;

    // If a description is provided, look for a specific relationship
    if (description != null) {
      foundRelationship = source.relationships.firstWhere(
        (r) => r.destinationId == destinationId && r.description == description,
        orElse: () => const Relationship(
          id: '',
          sourceId: '',
          destinationId: '',
          description: '',
        ),
      );
    } else {
      // Otherwise, find any relationship between the source and destination
      foundRelationship = source.relationships.firstWhere(
        (r) => r.destinationId == destinationId,
        orElse: () => const Relationship(
          id: '',
          sourceId: '',
          destinationId: '',
          description: '',
        ),
      );
    }

    // If we found a valid relationship, wrap it in a ModeledRelationship
    if (foundRelationship.id.isNotEmpty) {
      return ModeledRelationship.fromRelationship(foundRelationship, this);
    }

    // No relationship found
    return null;
  }

  /// Gets a person by its ID.
  Person? getPeopleById(String id) {
    try {
      return people.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Gets a software system by its ID.
  SoftwareSystem? getSoftwareSystemById(String id) {
    try {
      return softwareSystems.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// Represents a person in the architecture model.
@freezed
class Person with _$Person implements Element {
  const Person._();

  /// Creates a new person with the given properties.
  const factory Person({
    required String id,
    required String name,
    String? description,
    @Default('Person') String type,
    @Default([]) List<String> tags,
    @Default({}) Map<String, String> properties,
    @Default([]) List<Relationship> relationships,
    String? parentId,
    @Default('Internal') String location,
    @ElementListConverter() @Default([]) List<Element> children,
  }) = _Person;

  /// Creates a person from a JSON object.
  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: json['type'] as String? ?? 'Person',
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      properties: (json['properties'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as String)) ??
          {},
      relationships: (json['relationships'] as List<dynamic>?)
              ?.map((e) => Relationship.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      parentId: json['parentId'] as String?,
      location: json['location'] as String? ?? 'Internal',
      children: (json['children'] as List<dynamic>?)
              ?.map((e) => Element.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
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
      'parentId': parentId,
      'location': location,
      'children': children.map((e) => e.toJson()).toList(),
    };
  }

  /// Creates a new person with a generated ID.
  factory Person.create({
    required String name,
    String? description,
    List<String> tags = const ['Person'],
    Map<String, String> properties = const {},
    String location = 'Internal',
    List<Element> children = const [],
  }) {
    final id = const Uuid().v4();
    return Person(
      id: id,
      name: name,
      description: description,
      tags: [...tags],
      properties: properties,
      location: location,
      children: children,
    );
  }

  @override
  Person addTag(String tag) {
    return copyWith(tags: [...tags, tag]);
  }

  @override
  Person addTags(List<String> newTags) {
    return copyWith(tags: [...tags, ...newTags]);
  }

  @override
  Person addProperty(String key, String value) {
    final updatedProperties = Map<String, String>.from(properties);
    updatedProperties[key] = value;
    return copyWith(properties: updatedProperties);
  }

  @override
  Person addRelationship({
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

  /// Adds a child element to this person.
  @override
  Person addChild(Element childNode) {
    return copyWith(children: [...children, childNode]);
  }

  /// Sets the identifier for this person.
  @override
  Person setIdentifier(String identifier) {
    // The id is immutable, so we can't change it directly
    // We would need to create a new Person with the new id
    throw UnsupportedError('Cannot change the ID of an existing Person.');
  }

  /// Sets a property on this person.
  Person setProperty(String key, dynamic value) {
    final updatedProperties = Map<String, String>.from(properties);
    if (value is String) {
      updatedProperties[key] = value;
    } else {
      updatedProperties[key] = value.toString();
    }
    return copyWith(properties: updatedProperties);
  }
}

/// Represents a software system in the architecture model.
@freezed
class SoftwareSystem with _$SoftwareSystem implements Element {
  const SoftwareSystem._();

  /// Creates a new software system with the given properties.
  const factory SoftwareSystem({
    required String id,
    required String name,
    String? description,
    @Default('SoftwareSystem') String type,
    @Default([]) List<String> tags,
    @Default({}) Map<String, String> properties,
    @Default([]) List<Relationship> relationships,
    String? parentId,
    @Default('Internal') String location,
    @Default([]) List<Container> containers,
    @Default([]) List<DeploymentEnvironment> deploymentEnvironments,
    @ElementListConverter() @Default([]) List<Element> children,
  }) = _SoftwareSystem;

  /// Creates a software system from a JSON object.
  factory SoftwareSystem.fromJson(Map<String, dynamic> json) {
    return SoftwareSystem(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: json['type'] as String? ?? 'SoftwareSystem',
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      properties: (json['properties'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as String)) ??
          {},
      relationships: (json['relationships'] as List<dynamic>?)
              ?.map((e) => Relationship.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      parentId: json['parentId'] as String?,
      location: json['location'] as String? ?? 'Internal',
      containers: (json['containers'] as List<dynamic>?)
              ?.map((e) => Container.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      deploymentEnvironments: (json['deploymentEnvironments'] as List<dynamic>?)
              ?.map((e) =>
                  DeploymentEnvironment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      children: (json['children'] as List<dynamic>?)
              ?.map((e) => Element.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
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
      'parentId': parentId,
      'location': location,
      'containers': containers.map((c) => c.toJson()).toList(),
      'deploymentEnvironments':
          deploymentEnvironments.map((d) => d.toJson()).toList(),
      'children': children.map((e) => e.toJson()).toList(),
    };
  }

  /// Creates a new software system with a generated ID.
  factory SoftwareSystem.create({
    required String name,
    String? description,
    List<String> tags = const ['SoftwareSystem'],
    Map<String, String> properties = const {},
    String location = 'Internal',
    List<Container> containers = const [],
    List<Element> children = const [],
  }) {
    final id = const Uuid().v4();
    return SoftwareSystem(
      id: id,
      name: name,
      description: description,
      tags: [...tags],
      properties: properties,
      location: location,
      containers: containers,
      children: children,
    );
  }

  @override
  SoftwareSystem addTag(String tag) {
    return copyWith(tags: [...tags, tag]);
  }

  @override
  SoftwareSystem addTags(List<String> newTags) {
    return copyWith(tags: [...tags, ...newTags]);
  }

  @override
  SoftwareSystem addProperty(String key, String value) {
    final updatedProperties = Map<String, String>.from(properties);
    updatedProperties[key] = value;
    return copyWith(properties: updatedProperties);
  }

  @override
  SoftwareSystem addRelationship({
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

  /// Adds a container to this software system.
  SoftwareSystem addContainer(Container container) {
    return copyWith(containers: [...containers, container]);
  }

  /// Gets a container by its ID.
  Container? getContainerById(String containerId) {
    try {
      return containers.firstWhere((c) => c.id == containerId);
    } catch (_) {
      return null;
    }
  }

  /// Adds a child element to this software system.
  @override
  SoftwareSystem addChild(Element childNode) {
    return copyWith(children: [...children, childNode]);
  }

  /// Sets the identifier for this software system.
  @override
  SoftwareSystem setIdentifier(String identifier) {
    // The id is immutable, so we can't change it directly
    // We would need to create a new SoftwareSystem with the new id
    throw UnsupportedError(
        'Cannot change the ID of an existing SoftwareSystem.');
  }

  /// Sets a property on this software system.
  SoftwareSystem setProperty(String key, dynamic value) {
    final updatedProperties = Map<String, String>.from(properties);
    if (value is String) {
      updatedProperties[key] = value;
    } else {
      updatedProperties[key] = value.toString();
    }
    return copyWith(properties: updatedProperties);
  }
}
