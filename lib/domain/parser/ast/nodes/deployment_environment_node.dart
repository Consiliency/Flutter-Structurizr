import '../ast_node.dart' show AstNode, AstVisitor;
import 'source_position.dart' show SourcePosition;

class DeploymentEnvironmentNode extends AstNode {
  final String id;
  final String name;
  String? group;
  List<AstNode> children;

  DeploymentEnvironmentNode({
    required this.id,
    required this.name,
    this.group,
    this.children = const [],
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);

  @override
  void accept(AstVisitor visitor) =>
      visitor.visitDeploymentEnvironmentNode(this);
}
