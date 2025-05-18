import '../ast_node.dart';
import 'source_position.dart' show SourcePosition;

class DeploymentViewNode extends AstNode {
  final String key;
  final String environment;
  final String? title;
  final String? description;
  DeploymentViewNode(
      {required this.key,
      required this.environment,
      this.title,
      this.description,
      SourcePosition? sourcePosition})
      : super(sourcePosition);

  @override
  void accept(AstVisitor visitor) => visitor.visitDeploymentViewNode(this);
}
