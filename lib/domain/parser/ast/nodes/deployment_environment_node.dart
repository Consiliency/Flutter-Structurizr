import '../ast_node.dart' show AstNode, AstVisitor;
import 'source_position.dart' show SourcePosition;
import 'deployment_node_node.dart' show DeploymentNodeNode;
import 'relationship_node.dart' show RelationshipNode;

class DeploymentEnvironmentNode extends AstNode {
  final String id;
  final String name;
  final String? description;
  final List<String> tags;
  final Map<String, String> properties;
  final String? group;
  final List<DeploymentNodeNode> deploymentNodes;
  final List<RelationshipNode> relationships;
  final List<AstNode> children;

  DeploymentEnvironmentNode({
    required this.id,
    required this.name,
    this.description,
    this.tags = const [],
    this.properties = const {},
    this.group,
    this.deploymentNodes = const [],
    this.relationships = const [],
    this.children = const [],
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);

  @override
  void accept(AstVisitor visitor) =>
      visitor.visitDeploymentEnvironmentNode(this);
}
