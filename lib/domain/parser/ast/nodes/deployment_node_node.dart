import '../ast_node.dart' show AstNode, AstVisitor;
import 'source_position.dart' show SourcePosition;
import 'infrastructure_node_node.dart' show InfrastructureNodeNode;
import 'container_instance_node.dart' show ContainerInstanceNode;
import 'relationship_node.dart' show RelationshipNode;

class DeploymentNodeNode extends AstNode {
  final String id;
  final String name;
  String? description;
  String? technology;
  List<String> tags;
  String? url;
  Map<String, String>? properties;
  List<String>? perspectives;
  List<RelationshipNode> relationships;
  String? group;
  String? instances;
  List<InfrastructureNodeNode> infrastructureNodes;
  List<ContainerInstanceNode> containerInstances;
  List<AstNode> children;

  DeploymentNodeNode({
    required this.id,
    required this.name,
    this.description,
    this.technology,
    this.tags = const [],
    this.url,
    this.properties,
    this.perspectives,
    this.relationships = const [],
    this.group,
    this.instances,
    this.infrastructureNodes = const [],
    this.containerInstances = const [],
    this.children = const [],
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);

  @override
  void accept(AstVisitor visitor) => visitor.visitDeploymentNodeNode(this);
}
