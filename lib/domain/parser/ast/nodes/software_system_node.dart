import '../ast_node.dart' show AstNode, AstVisitor;
import 'source_position.dart' show SourcePosition;
import 'relationship_node.dart' show RelationshipNode;
import 'container_node.dart' show ContainerNode;
import 'deployment_environment_node.dart' show DeploymentEnvironmentNode;

class SoftwareSystemNode extends AstNode {
  final String id;
  final String name;
  final String? description;
  final String? location;
  final List<String> tags;
  final Map<String, String> properties;
  final List<RelationshipNode> relationships;
  final List<ContainerNode> containers;
  final List<DeploymentEnvironmentNode> deploymentEnvironments;
  String? url;
  List<String>? perspectives;
  String? group;
  List<AstNode> docs;
  List<AstNode> adrs;
  List<AstNode> children;

  SoftwareSystemNode({
    required this.id,
    required this.name,
    this.description,
    this.location,
    this.tags = const [],
    this.properties = const {},
    this.relationships = const [],
    this.containers = const [],
    this.deploymentEnvironments = const [],
    this.url,
    this.perspectives,
    this.group,
    this.docs = const [],
    this.adrs = const [],
    this.children = const [],
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);

  @override
  void accept(AstVisitor visitor) => visitor.visitSoftwareSystemNode(this);
}
