import '../../error_reporter.dart';
import '../ast_base.dart';
import 'model_element_node.dart';
import 'deployment_node.dart';
import 'relationship_node.dart';

/// Node representing the model section of a workspace.
class ModelNode extends AstNode {
  /// The enterprise name.
  final String? enterpriseName;
  
  /// The people in the model.
  final List<PersonNode> people;
  
  /// The software systems in the model.
  final List<SoftwareSystemNode> softwareSystems;
  
  /// The deployment environments in the model.
  final List<DeploymentEnvironmentNode> deploymentEnvironments;
  
  /// The relationships in the model that aren't owned by a specific element.
  final List<RelationshipNode> relationships;
  
  /// The groups in the model.
  final List<GroupNode> groups;
  
  /// The enterprise in the model.
  final EnterpriseNode? enterprise;
  
  /// The implied relationships in the model.
  final List<RelationshipNode> impliedRelationships;

  /// Creates a new model node.
  ModelNode({
    this.enterpriseName,
    this.people = const [],
    this.softwareSystems = const [],
    this.deploymentEnvironments = const [],
    this.relationships = const [],
    this.groups = const [],
    this.enterprise,
    this.impliedRelationships = const [],
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitModelNode(this);
  }
  
  /// Returns all elements in this model.
  List<ModelElementNode> get allElements {
    final result = <ModelElementNode>[];
    
    // Add people
    result.addAll(people);
    
    // Add software systems and their containers
    for (final system in softwareSystems) {
      result.add(system);
      
      for (final container in system.containers) {
        result.add(container);
        
        // Add components
        result.addAll(container.components);
      }
    }
    
    // Add deployment environments and their nodes
    for (final env in deploymentEnvironments) {
      result.add(env);
      
      // Add deployment nodes recursively
      result.addAll(_collectDeploymentNodes(env.deploymentNodes));
    }
    
    return result;
  }
  
  /// Recursively collects all deployment nodes.
  List<DeploymentNodeNode> _collectDeploymentNodes(List<DeploymentNodeNode> nodes) {
    final result = <DeploymentNodeNode>[];
    
    for (final node in nodes) {
      result.add(node);
      
      // Add child nodes recursively
      result.addAll(_collectDeploymentNodes(node.children));
      
      // Add infrastructure nodes
      result.addAll(node.infrastructureNodes);
      
      // Add container instances
      result.addAll(node.containerInstances);
    }
    
    return result;
  }

  /// Adds a group to this model.
  void addGroup(GroupNode groupNode) {
    groups.add(groupNode);
  }

  /// Adds an enterprise to this model.
  void addEnterprise(EnterpriseNode enterpriseNode) {
    // Since enterprise is immutable, we need to create a new model node
    // This is a design limitation in the AST implementation
    throw UnimplementedError(
      'ModelNode.addEnterprise is not supported in the immutable AST. '
      'Create a new ModelNode with the enterprise set directly.',
    );
  }

  /// Adds an element to this model.
  void addElement(ModelElementNode elementNode) {
    if (elementNode is PersonNode) {
      people.add(elementNode);
    } else if (elementNode is SoftwareSystemNode) {
      softwareSystems.add(elementNode);
    } else if (elementNode is DeploymentEnvironmentNode) {
      deploymentEnvironments.add(elementNode);
    } else {
      throw ArgumentError('Unsupported element type: ${elementNode.runtimeType}');
    }
  }

  /// Adds a relationship to this model.
  void addRelationship(RelationshipNode relationshipNode) {
    relationships.add(relationshipNode);
  }

  /// Adds an implied relationship to this model.
  void addImpliedRelationship(RelationshipNode relationshipNode) {
    impliedRelationships.add(relationshipNode);
  }

  /// Sets an advanced property on this model.
  void setAdvancedProperty(String key, dynamic value) {
    // Since properties are immutable, this would require creating a new ModelNode
    throw UnimplementedError(
      'ModelNode.setAdvancedProperty is not supported in the immutable AST. '
      'Create a new ModelNode with the properties set directly.',
    );
  }
}

/// Node representing a group of elements.
class GroupNode extends AstNode {
  /// The name of the group.
  final String name;

  /// The elements in this group.
  final List<ModelElementNode> elements;

  /// The tags associated with this group.
  final TagsNode? tags;

  /// The properties associated with this group.
  final PropertiesNode? properties;

  /// The children of this group.
  final List<ModelElementNode> children;

  /// The relationships in this group.
  final List<RelationshipNode> relationships;

  /// Creates a new group node.
  GroupNode({
    required this.name,
    this.elements = const [],
    this.tags,
    this.properties,
    this.children = const [],
    this.relationships = const [],
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);

  @override
  void accept(AstVisitor visitor) {
    visitor.visitGroupNode(this);
  }

  /// Adds an element to this group.
  void addElement(ModelElementNode elementNode) {
    elements.add(elementNode);
  }

  /// Sets a property on this group.
  void setProperty(String key, dynamic value) {
    // Since properties are immutable, this would require creating a new GroupNode
    throw UnimplementedError(
      'GroupNode.setProperty is not supported in the immutable AST. '
      'Create a new GroupNode with the properties set directly.',
    );
  }
}

/// Node representing an enterprise in the model.
class EnterpriseNode extends AstNode {
  /// The name of the enterprise.
  final String name;

  /// The groups in this enterprise.
  final List<GroupNode> groups;

  /// The tags associated with this enterprise.
  final TagsNode? tags;

  /// The properties associated with this enterprise.
  final PropertiesNode? properties;

  /// Creates a new enterprise node.
  EnterpriseNode({
    required this.name,
    this.groups = const [],
    this.tags,
    this.properties,
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);

  @override
  void accept(AstVisitor visitor) {
    visitor.visitEnterpriseNode(this);
  }

  /// Adds a group to this enterprise.
  void addGroup(GroupNode groupNode) {
    groups.add(groupNode);
  }

  /// Sets a property on this enterprise.
  void setProperty(String key, dynamic value) {
    // Since properties are immutable, this would require creating a new EnterpriseNode
    throw UnimplementedError(
      'EnterpriseNode.setProperty is not supported in the immutable AST. '
      'Create a new EnterpriseNode with the properties set directly.',
    );
  }
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