import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/deployment_environment.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

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
  }) = _Model;

  /// Creates a model from a JSON object.
  factory Model.fromJson(Map<String, dynamic> json) => _$ModelFromJson(json);

  /// Gets all elements in the model.
  List<Element> getAllElements() {
    final elements = <Element>[];
    
    // Add people
    elements.addAll(people);
    
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
    
    return relationships;
  }

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
        orElse: () => Person(id: '', name: ''),
      );
    } else {
      return people.firstWhere(
        (person) => person.name == name,
        orElse: () => Person(id: '', name: ''),
      );
    }
  }

  /// Finds a software system by its name.
  /// Returns null if no software system is found with the given name.
  SoftwareSystem? findSoftwareSystemByName(String name, {bool ignoreCase = false}) {
    if (ignoreCase) {
      final lowerName = name.toLowerCase();
      return softwareSystems.firstWhere(
        (system) => system.name.toLowerCase() == lowerName,
        orElse: () => SoftwareSystem(id: '', name: ''),
      );
    } else {
      return softwareSystems.firstWhere(
        (system) => system.name == name,
        orElse: () => SoftwareSystem(id: '', name: ''),
      );
    }
  }

  /// Finds a container by its name within a software system.
  /// Returns null if no container is found with the given name.
  Container? findContainerByName(String softwareSystemId, String name, {bool ignoreCase = false}) {
    final system = getSoftwareSystemById(softwareSystemId);
    if (system == null) return null;

    if (ignoreCase) {
      final lowerName = name.toLowerCase();
      return system.containers.firstWhere(
        (container) => container.name.toLowerCase() == lowerName,
        orElse: () => Container(id: '', name: '', parentId: ''),
      );
    } else {
      return system.containers.firstWhere(
        (container) => container.name == name,
        orElse: () => Container(id: '', name: '', parentId: ''),
      );
    }
  }

  /// Finds a component by its name within a container.
  /// Returns null if no component is found with the given name.
  Component? findComponentByName(String containerId, String name, {bool ignoreCase = false}) {
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
      return container.components.firstWhere(
        (component) => component.name.toLowerCase() == lowerName,
        orElse: () => Component(id: '', name: '', parentId: ''),
      );
    } else {
      return container.components.firstWhere(
        (component) => component.name == name,
        orElse: () => Component(id: '', name: '', parentId: ''),
      );
    }
  }

  /// Finds a relationship between two elements.
  /// Returns null if no such relationship exists.
  Relationship? findRelationshipBetween(String sourceId, String destinationId, String? description) {
    final source = getElementById(sourceId);
    if (source == null) return null;

    // If a description is provided, look for a specific relationship
    if (description != null) {
      return source.relationships.firstWhere(
        (r) => r.destinationId == destinationId && r.description == description,
        orElse: () => Relationship(
          id: '',
          sourceId: '',
          destinationId: '',
          description: '',
        ),
      );
    } else {
      // Otherwise, find any relationship between the source and destination
      return source.relationships.firstWhere(
        (r) => r.destinationId == destinationId,
        orElse: () => Relationship(
          id: '',
          sourceId: '',
          destinationId: '',
          description: '',
        ),
      );
    }
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
  }) = _Person;

  /// Creates a person from a JSON object.
  factory Person.fromJson(Map<String, dynamic> json) => _$PersonFromJson(json);

  /// Creates a new person with a generated ID.
  factory Person.create({
    required String name,
    String? description,
    List<String> tags = const ['Person'],
    Map<String, String> properties = const {},
    String location = 'Internal',
  }) {
    final id = const Uuid().v4();
    return Person(
      id: id,
      name: name,
      description: description,
      tags: [...tags],
      properties: properties,
      location: location,
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
    return relationships.where((r) => r.destinationId == destinationId).toList();
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
  }) = _SoftwareSystem;

  /// Creates a software system from a JSON object.
  factory SoftwareSystem.fromJson(Map<String, dynamic> json) => _$SoftwareSystemFromJson(json);

  /// Creates a new software system with a generated ID.
  factory SoftwareSystem.create({
    required String name,
    String? description,
    List<String> tags = const ['SoftwareSystem'],
    Map<String, String> properties = const {},
    String location = 'Internal',
    List<Container> containers = const [],
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
    return relationships.where((r) => r.destinationId == destinationId).toList();
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
}

/// Represents a container (application, database, etc.) in a software system.
@freezed
class Container with _$Container implements Element {
  const Container._();

  /// Creates a new container with the given properties.
  const factory Container({
    required String id,
    required String name,
    String? description,
    @Default('Container') String type,
    @Default([]) List<String> tags,
    @Default({}) Map<String, String> properties,
    @Default([]) List<Relationship> relationships,
    required String parentId,
    String? technology,
    @Default([]) List<Component> components,
  }) = _Container;

  /// Creates a container from a JSON object.
  factory Container.fromJson(Map<String, dynamic> json) => _$ContainerFromJson(json);

  /// Creates a new container with a generated ID.
  factory Container.create({
    required String name,
    required String parentId,
    String? description,
    String? technology,
    List<String> tags = const ['Container'],
    Map<String, String> properties = const {},
    List<Component> components = const [],
  }) {
    final id = const Uuid().v4();
    return Container(
      id: id,
      name: name,
      description: description,
      parentId: parentId,
      technology: technology,
      tags: [...tags],
      properties: properties,
      components: components,
    );
  }

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

  /// Adds a component to this container.
  Container addComponent(Component component) {
    return copyWith(components: [...components, component]);
  }

  /// Gets a component by its ID.
  Component? getComponentById(String componentId) {
    try {
      return components.firstWhere((c) => c.id == componentId);
    } catch (_) {
      return null;
    }
  }
}

/// Represents a component in a container.
@freezed
class Component with _$Component implements Element {
  const Component._();

  /// Creates a new component with the given properties.
  const factory Component({
    required String id,
    required String name,
    String? description,
    @Default('Component') String type,
    @Default([]) List<String> tags,
    @Default({}) Map<String, String> properties,
    @Default([]) List<Relationship> relationships,
    required String parentId,
    String? technology,
  }) = _Component;

  /// Creates a component from a JSON object.
  factory Component.fromJson(Map<String, dynamic> json) => _$ComponentFromJson(json);

  /// Creates a new component with a generated ID.
  factory Component.create({
    required String name,
    required String parentId,
    String? description,
    String? technology,
    List<String> tags = const ['Component'],
    Map<String, String> properties = const {},
  }) {
    final id = const Uuid().v4();
    return Component(
      id: id,
      name: name,
      description: description,
      parentId: parentId,
      technology: technology,
      tags: [...tags],
      properties: properties,
    );
  }

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
}

/// Represents a deployment node in the architecture model.
@freezed
class DeploymentNode with _$DeploymentNode implements Element {
  const DeploymentNode._();

  /// Creates a new deployment node with the given properties.
  const factory DeploymentNode({
    required String id,
    required String name,
    String? description,
    @Default('DeploymentNode') String type,
    @Default([]) List<String> tags,
    @Default({}) Map<String, String> properties,
    @Default([]) List<Relationship> relationships,
    String? parentId,
    required String environment,
    String? technology,
    int? instances,
    @Default([]) List<ContainerInstance> containerInstances,
    @Default([]) List<SoftwareSystemInstance> softwareSystemInstances,
    @Default([]) List<InfrastructureNode> infrastructureNodes,
    @Default([]) List<DeploymentNode> children,
  }) = _DeploymentNode;

  /// Creates a deployment node from a JSON object.
  factory DeploymentNode.fromJson(Map<String, dynamic> json) => _$DeploymentNodeFromJson(json);

  /// Creates a new deployment node with a generated ID.
  factory DeploymentNode.create({
    required String name,
    required String environment,
    String? parentId,
    String? description,
    String? technology,
    int? instances,
    List<String> tags = const ['DeploymentNode'],
    Map<String, String> properties = const {},
    List<ContainerInstance> containerInstances = const [],
    List<SoftwareSystemInstance> softwareSystemInstances = const [],
    List<InfrastructureNode> infrastructureNodes = const [],
    List<DeploymentNode> children = const [],
  }) {
    final id = const Uuid().v4();
    return DeploymentNode(
      id: id,
      name: name,
      description: description,
      parentId: parentId,
      environment: environment,
      technology: technology,
      instances: instances,
      tags: [...tags],
      properties: properties,
      containerInstances: containerInstances,
      softwareSystemInstances: softwareSystemInstances,
      infrastructureNodes: infrastructureNodes,
      children: children,
    );
  }

  @override
  DeploymentNode addTag(String tag) {
    return copyWith(tags: [...tags, tag]);
  }

  @override
  DeploymentNode addTags(List<String> newTags) {
    return copyWith(tags: [...tags, ...newTags]);
  }

  @override
  DeploymentNode addProperty(String key, String value) {
    final updatedProperties = Map<String, String>.from(properties);
    updatedProperties[key] = value;
    return copyWith(properties: updatedProperties);
  }

  @override
  DeploymentNode addRelationship({
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

  /// Adds a child deployment node to this node.
  DeploymentNode addChildNode(DeploymentNode node) {
    return copyWith(children: [...children, node]);
  }

  /// Adds a container instance to this node.
  DeploymentNode addContainerInstance(ContainerInstance instance) {
    return copyWith(containerInstances: [...containerInstances, instance]);
  }

  /// Adds a software system instance to this node.
  DeploymentNode addSoftwareSystemInstance(SoftwareSystemInstance instance) {
    return copyWith(softwareSystemInstances: [...softwareSystemInstances, instance]);
  }

  /// Adds an infrastructure node to this node.
  DeploymentNode addInfrastructureNode(InfrastructureNode node) {
    return copyWith(infrastructureNodes: [...infrastructureNodes, node]);
  }
}

/// Represents an infrastructure node (load balancer, firewall, etc.).
@freezed
class InfrastructureNode with _$InfrastructureNode implements Element {
  const InfrastructureNode._();

  /// Creates a new infrastructure node with the given properties.
  const factory InfrastructureNode({
    required String id,
    required String name,
    String? description,
    @Default('InfrastructureNode') String type,
    @Default([]) List<String> tags,
    @Default({}) Map<String, String> properties,
    @Default([]) List<Relationship> relationships,
    required String parentId,
    String? technology,
  }) = _InfrastructureNode;

  /// Creates an infrastructure node from a JSON object.
  factory InfrastructureNode.fromJson(Map<String, dynamic> json) => _$InfrastructureNodeFromJson(json);

  /// Creates a new infrastructure node with a generated ID.
  factory InfrastructureNode.create({
    required String name,
    required String parentId,
    String? description,
    String? technology,
    List<String> tags = const ['InfrastructureNode'],
    Map<String, String> properties = const {},
  }) {
    final id = const Uuid().v4();
    return InfrastructureNode(
      id: id,
      name: name,
      description: description,
      parentId: parentId,
      technology: technology,
      tags: [...tags],
      properties: properties,
    );
  }

  @override
  InfrastructureNode addTag(String tag) {
    return copyWith(tags: [...tags, tag]);
  }

  @override
  InfrastructureNode addTags(List<String> newTags) {
    return copyWith(tags: [...tags, ...newTags]);
  }

  @override
  InfrastructureNode addProperty(String key, String value) {
    final updatedProperties = Map<String, String>.from(properties);
    updatedProperties[key] = value;
    return copyWith(properties: updatedProperties);
  }

  @override
  InfrastructureNode addRelationship({
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
}

/// Represents a deployed instance of a container.
@freezed
class ContainerInstance with _$ContainerInstance implements Element {
  const ContainerInstance._();

  /// Creates a new container instance with the given properties.
  const factory ContainerInstance({
    required String id,
    @Default('ContainerInstance') String type,
    @Default([]) List<String> tags,
    @Default({}) Map<String, String> properties,
    @Default([]) List<Relationship> relationships,
    required String parentId,
    required String containerId,
    int? instanceId,
    String? healthEndpoint,
  }) = _ContainerInstance;

  /// Creates a container instance from a JSON object.
  factory ContainerInstance.fromJson(Map<String, dynamic> json) => _$ContainerInstanceFromJson(json);

  /// Creates a new container instance with a generated ID.
  factory ContainerInstance.create({
    required String parentId,
    required String containerId,
    int? instanceId = 1,
    String? healthEndpoint,
    List<String> tags = const ['ContainerInstance'],
    Map<String, String> properties = const {},
  }) {
    final id = const Uuid().v4();
    return ContainerInstance(
      id: id,
      parentId: parentId,
      containerId: containerId,
      instanceId: instanceId,
      healthEndpoint: healthEndpoint,
      tags: [...tags],
      properties: properties,
    );
  }

  @override
  String get name => 'Container Instance';

  @override
  String? get description => null;

  @override
  ContainerInstance addTag(String tag) {
    return copyWith(tags: [...tags, tag]);
  }

  @override
  ContainerInstance addTags(List<String> newTags) {
    return copyWith(tags: [...tags, ...newTags]);
  }

  @override
  ContainerInstance addProperty(String key, String value) {
    final updatedProperties = Map<String, String>.from(properties);
    updatedProperties[key] = value;
    return copyWith(properties: updatedProperties);
  }

  @override
  ContainerInstance addRelationship({
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
}

/// Represents a deployed instance of a software system.
@freezed
class SoftwareSystemInstance with _$SoftwareSystemInstance implements Element {
  const SoftwareSystemInstance._();

  /// Creates a new software system instance with the given properties.
  const factory SoftwareSystemInstance({
    required String id,
    @Default('SoftwareSystemInstance') String type,
    @Default([]) List<String> tags,
    @Default({}) Map<String, String> properties,
    @Default([]) List<Relationship> relationships,
    required String parentId,
    required String softwareSystemId,
    int? instanceId,
    String? healthEndpoint,
  }) = _SoftwareSystemInstance;

  /// Creates a software system instance from a JSON object.
  factory SoftwareSystemInstance.fromJson(Map<String, dynamic> json) => _$SoftwareSystemInstanceFromJson(json);

  /// Creates a new software system instance with a generated ID.
  factory SoftwareSystemInstance.create({
    required String parentId,
    required String softwareSystemId,
    int? instanceId = 1,
    String? healthEndpoint,
    List<String> tags = const ['SoftwareSystemInstance'],
    Map<String, String> properties = const {},
  }) {
    final id = const Uuid().v4();
    return SoftwareSystemInstance(
      id: id,
      parentId: parentId,
      softwareSystemId: softwareSystemId,
      instanceId: instanceId,
      healthEndpoint: healthEndpoint,
      tags: [...tags],
      properties: properties,
    );
  }

  @override
  String get name => 'Software System Instance';

  @override
  String? get description => null;

  @override
  SoftwareSystemInstance addTag(String tag) {
    return copyWith(tags: [...tags, tag]);
  }

  @override
  SoftwareSystemInstance addTags(List<String> newTags) {
    return copyWith(tags: [...tags, ...newTags]);
  }

  @override
  SoftwareSystemInstance addProperty(String key, String value) {
    final updatedProperties = Map<String, String>.from(properties);
    updatedProperties[key] = value;
    return copyWith(properties: updatedProperties);
  }

  @override
  SoftwareSystemInstance addRelationship({
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
}