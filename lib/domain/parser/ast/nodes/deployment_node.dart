import '../../error_reporter.dart';
import '../ast_base.dart';
import 'model_element_node.dart';

/// Node representing a deployment environment.
class DeploymentEnvironmentNode extends ModelElementNode {
  /// The parent software system ID.
  final String? parentId;
  
  /// The deployment nodes in this environment.
  final List<DeploymentNodeNode> deploymentNodes;
  
  /// Creates a new deployment environment node.
  DeploymentEnvironmentNode({
    required String id,
    this.parentId,
    required String name,
    String? description,
    TagsNode? tags,
    PropertiesNode? properties,
    this.deploymentNodes = const [],
    List<RelationshipNode> relationships = const [],
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
    visitor.visitDeploymentEnvironmentNode(this);
  }
  
  @override
  String get fullId => parentId != null ? '$parentId.$id' : id;
}

/// Node representing a deployment node.
class DeploymentNodeNode extends ModelElementNode {
  /// The parent node ID.
  final String parentId;
  
  /// The technology of this deployment node.
  final String? technology;
  
  /// The child deployment nodes.
  final List<DeploymentNodeNode> children;
  
  /// The infrastructure nodes in this deployment node.
  final List<InfrastructureNodeNode> infrastructureNodes;
  
  /// The container instances in this deployment node.
  final List<ContainerInstanceNode> containerInstances;
  
  /// Creates a new deployment node node.
  DeploymentNodeNode({
    required String id,
    required this.parentId,
    required String name,
    String? description,
    this.technology,
    TagsNode? tags,
    PropertiesNode? properties,
    this.children = const [],
    this.infrastructureNodes = const [],
    this.containerInstances = const [],
    List<RelationshipNode> relationships = const [],
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
  
  @override
  String get fullId => '$parentId.$id';
}

/// Node representing an infrastructure node.
class InfrastructureNodeNode extends ModelElementNode {
  /// The parent deployment node ID.
  final String parentId;
  
  /// The technology of this infrastructure node.
  final String? technology;
  
  /// Creates a new infrastructure node node.
  InfrastructureNodeNode({
    required String id,
    required this.parentId,
    required String name,
    String? description,
    this.technology,
    TagsNode? tags,
    PropertiesNode? properties,
    List<RelationshipNode> relationships = const [],
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
    visitor.visitInfrastructureNodeNode(this);
  }
  
  @override
  String get fullId => '$parentId.$id';
}

/// Node representing a container instance.
class ContainerInstanceNode extends ModelElementNode {
  /// The parent deployment node ID.
  final String parentId;
  
  /// The referenced container ID.
  final String containerId;
  
  /// The number of instances.
  final int instanceCount;
  
  /// Creates a new container instance node.
  ContainerInstanceNode({
    required String id,
    required this.parentId,
    required this.containerId,
    required String name,
    String? description,
    this.instanceCount = 1,
    TagsNode? tags,
    PropertiesNode? properties,
    List<RelationshipNode> relationships = const [],
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
    visitor.visitContainerInstanceNode(this);
  }
  
  @override
  String get fullId => '$parentId.$id';
}