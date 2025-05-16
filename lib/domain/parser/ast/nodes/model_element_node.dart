import '../../error_reporter.dart';
import '../ast_base.dart';

/// Base class for all model element nodes.
abstract class ModelElementNode extends AstNode {
  /// The identifier of this element.
  final String id;
  
  /// The name of this element.
  final String name;
  
  /// The description of this element.
  final String? description;
  
  /// The tags associated with this element.
  final TagsNode? tags;
  
  /// The properties associated with this element.
  final PropertiesNode? properties;
  
  /// The relationships originating from this element.
  final List<RelationshipNode> relationships;
  
  /// The variable name if this element was assigned to a variable
  final String? variableName;
  
  /// The children of this element
  final List<ModelElementNode> children;
  
  /// Creates a new model element node.
  ModelElementNode({
    required this.id,
    required this.name,
    this.description,
    this.tags,
    this.properties,
    this.relationships = const [],
    this.variableName,
    this.children = const [],
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);
  
  /// The fully qualified ID of this element, including any parent IDs.
  String get fullId => id;
  
  /// Adds a child element to this element.
  void addChild(ModelElementNode child) {
    children.add(child);
  }
  
  /// Sets the identifier for this element.
  void setIdentifier(String identifier) {
    // Since id is final, we can't change it directly.
    // This method would need to be implemented differently in a mutable AST.
    throw UnimplementedError(
      'The AST is immutable. Create a new node with the updated identifier instead.'
    );
  }
}

/// Node representing a person in the model.
class PersonNode extends ModelElementNode {
  /// The location of this person (Internal, External).
  final String? location;
  
  /// Creates a new person node.
  PersonNode({
    required String id,
    required String name,
    String? description,
    this.location,
    TagsNode? tags,
    PropertiesNode? properties,
    List<RelationshipNode> relationships = const [],
    List<ModelElementNode> children = const [],
    SourcePosition? sourcePosition,
  }) : super(
    id: id,
    name: name,
    description: description,
    tags: tags,
    properties: properties,
    relationships: relationships,
    children: children,
    sourcePosition: sourcePosition,
  );
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitPersonNode(this);
  }
  
  /// Sets a property on this person.
  void setProperty(String key, dynamic value) {
    // Since properties is immutable, we can't modify it directly
    if (properties == null) {
      // We would need to create a new PropertiesNode if one doesn't exist
      throw UnimplementedError(
        'The AST is immutable. Create a new node with the updated properties instead.'
      );
    } else {
      // We would need to modify the existing PropertiesNode
      throw UnimplementedError(
        'The AST is immutable. Create a new node with the updated properties instead.'
      );
    }
  }
}

/// Node representing a software system in the model.
class SoftwareSystemNode extends ModelElementNode {
  /// The location of this software system (Internal, External).
  final String? location;
  
  /// The containers in this software system.
  final List<ContainerNode> containers;
  
  /// The deployment environments for this software system.
  final List<DeploymentEnvironmentNode> deploymentEnvironments;
  
  /// Creates a new software system node.
  SoftwareSystemNode({
    required String id,
    required String name,
    String? description,
    this.location,
    TagsNode? tags,
    PropertiesNode? properties,
    this.containers = const [],
    this.deploymentEnvironments = const [],
    List<RelationshipNode> relationships = const [],
    List<ModelElementNode> children = const [],
    SourcePosition? sourcePosition,
  }) : super(
    id: id,
    name: name,
    description: description,
    tags: tags,
    properties: properties,
    relationships: relationships,
    children: children,
    sourcePosition: sourcePosition,
  );
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitSoftwareSystemNode(this);
  }
  
  /// Sets a property on this software system.
  void setProperty(String key, dynamic value) {
    // Since properties is immutable, we can't modify it directly
    if (properties == null) {
      // We would need to create a new PropertiesNode if one doesn't exist
      throw UnimplementedError(
        'The AST is immutable. Create a new node with the updated properties instead.'
      );
    } else {
      // We would need to modify the existing PropertiesNode
      throw UnimplementedError(
        'The AST is immutable. Create a new node with the updated properties instead.'
      );
    }
  }
}

/// Node representing a container in a software system.
class ContainerNode extends ModelElementNode {
  /// The parent software system ID.
  final String parentId;
  
  /// The technology used by this container.
  final String? technology;
  
  /// The components in this container.
  final List<ComponentNode> components;
  
  /// Creates a new container node.
  ContainerNode({
    required String id,
    required this.parentId,
    required String name,
    String? description,
    this.technology,
    TagsNode? tags,
    PropertiesNode? properties,
    this.components = const [],
    List<RelationshipNode> relationships = const [],
    List<ModelElementNode> children = const [],
    SourcePosition? sourcePosition,
  }) : super(
    id: id,
    name: name,
    description: description,
    tags: tags,
    properties: properties,
    relationships: relationships,
    children: children,
    sourcePosition: sourcePosition,
  );
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitContainerNode(this);
  }
  
  @override
  String get fullId => '$parentId.$id';
}

/// Node representing a component in a container.
class ComponentNode extends ModelElementNode {
  /// The parent container ID.
  final String parentId;
  
  /// The technology used by this component.
  final String? technology;
  
  /// Creates a new component node.
  ComponentNode({
    required String id,
    required this.parentId,
    required String name,
    String? description,
    this.technology,
    TagsNode? tags,
    PropertiesNode? properties,
    List<RelationshipNode> relationships = const [],
    List<ModelElementNode> children = const [],
    SourcePosition? sourcePosition,
  }) : super(
    id: id,
    name: name,
    description: description,
    tags: tags,
    properties: properties,
    relationships: relationships,
    children: children,
    sourcePosition: sourcePosition,
  );
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitComponentNode(this);
  }
  
  @override
  String get fullId => '$parentId.$id';
}

/// Node representing tags for an element.
class TagsNode extends AstNode {
  /// The tags.
  final List<String> tags;

  /// Creates a new tags node.
  TagsNode({
    required this.tags,
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);

  @override
  void accept(AstVisitor visitor) {
    visitor.visitTagsNode(this);
  }
}

/// Node representing properties for an element.
class PropertiesNode extends AstNode {
  /// The properties.
  final Map<String, dynamic> properties;

  /// Creates a new properties node.
  PropertiesNode({
    required this.properties,
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);

  @override
  void accept(AstVisitor visitor) {
    visitor.visitPropertiesNode(this);
  }
}

/// Node representing a relationship between elements.
class RelationshipNode extends AstNode {
  /// The source element ID.
  final String sourceId;

  /// The destination element ID.
  final String destinationId;

  /// The description of this relationship.
  final String description;

  /// The technology used in this relationship.
  final String? technology;

  /// The tags for this relationship.
  final List<String>? tags;

  /// The properties for this relationship.
  final Map<String, dynamic>? properties;

  /// Creates a new relationship node.
  RelationshipNode({
    required this.sourceId,
    required this.destinationId,
    required this.description,
    this.technology,
    this.tags,
    this.properties,
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);

  @override
  void accept(AstVisitor visitor) {
    visitor.visitRelationshipNode(this);
  }
}

/// Node representing a deployment environment.
class DeploymentEnvironmentNode extends ModelElementNode {
  /// The deployment nodes in this environment.
  final List<DeploymentNodeNode> deploymentNodes;

  /// Creates a new deployment environment node.
  DeploymentEnvironmentNode({
    required String id,
    required String name,
    String? description,
    TagsNode? tags,
    PropertiesNode? properties,
    List<RelationshipNode> relationships = const [],
    List<ModelElementNode> children = const [],
    this.deploymentNodes = const [],
    SourcePosition? sourcePosition,
  }) : super(
    id: id,
    name: name,
    description: description,
    tags: tags,
    properties: properties,
    relationships: relationships,
    children: children,
    sourcePosition: sourcePosition,
  );

  @override
  void accept(AstVisitor visitor) {
    visitor.visitDeploymentEnvironmentNode(this);
  }
}

/// Node representing a deployment node.
class DeploymentNodeNode extends ModelElementNode {
  /// The environment of this deployment node.
  final String environment;

  /// The technology of this deployment node.
  final String? technology;

  /// The number of instances of this deployment node.
  final int? instances;

  /// The infrastructure nodes in this deployment node.
  final List<InfrastructureNodeNode> infrastructureNodes;

  /// The container instances in this deployment node.
  final List<ContainerInstanceNode> containerInstances;

  /// The child deployment nodes.
  final List<DeploymentNodeNode> children;

  /// Creates a new deployment node.
  DeploymentNodeNode({
    required String id,
    required String name,
    String? description,
    TagsNode? tags,
    PropertiesNode? properties,
    List<RelationshipNode> relationships = const [],
    required this.environment,
    this.technology,
    this.instances,
    this.infrastructureNodes = const [],
    this.containerInstances = const [],
    this.children = const [],
    SourcePosition? sourcePosition,
  }) : super(
    id: id,
    name: name,
    description: description,
    tags: tags,
    properties: properties,
    relationships: relationships,
    sourcePosition: sourcePosition,
  );

  @override
  void accept(AstVisitor visitor) {
    visitor.visitDeploymentNodeNode(this);
  }
}

/// Node representing an infrastructure node.
class InfrastructureNodeNode extends ModelElementNode {
  /// The technology of this infrastructure node.
  final String? technology;

  /// Creates a new infrastructure node.
  InfrastructureNodeNode({
    required String id,
    required String name,
    String? description,
    TagsNode? tags,
    PropertiesNode? properties,
    List<RelationshipNode> relationships = const [],
    List<ModelElementNode> children = const [],
    this.technology,
    SourcePosition? sourcePosition,
  }) : super(
    id: id,
    name: name,
    description: description,
    tags: tags,
    properties: properties,
    relationships: relationships,
    children: children,
    sourcePosition: sourcePosition,
  );

  @override
  void accept(AstVisitor visitor) {
    visitor.visitInfrastructureNodeNode(this);
  }
}

/// Node representing a container instance.
class ContainerInstanceNode extends ModelElementNode {
  /// The container that this instance is based on.
  final String containerId;

  /// The instance ID.
  final int? instanceId;

  /// The health endpoint for this instance.
  final String? healthEndpoint;

  /// Creates a new container instance node.
  ContainerInstanceNode({
    required String id,
    required this.containerId,
    this.instanceId,
    this.healthEndpoint,
    TagsNode? tags,
    PropertiesNode? properties,
    List<RelationshipNode> relationships = const [],
    List<ModelElementNode> children = const [],
    SourcePosition? sourcePosition,
  }) : super(
    id: id,
    name: 'Container Instance',
    description: null,
    tags: tags,
    properties: properties,
    relationships: relationships,
    children: children,
    sourcePosition: sourcePosition,
  );

  @override
  void accept(AstVisitor visitor) {
    visitor.visitContainerInstanceNode(this);
  }
}