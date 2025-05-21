import '../ast_node.dart';
import 'source_position.dart' show SourcePosition;

class DeploymentViewNode extends AstNode {
  final String key;
  final String environment;
  final String? title;
  final String? description;
  final String? systemId;
  final dynamic autoLayout;
  final List<dynamic> animations;
  final List<dynamic> includes;
  final List<dynamic> excludes;
  
  DeploymentViewNode({
    required this.key,
    required this.environment,
    this.title,
    this.description,
    this.systemId,
    this.autoLayout,
    this.animations = const [],
    this.includes = const [],
    this.excludes = const [],
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);

  @override
  void accept(AstVisitor visitor) => visitor.visitDeploymentViewNode(this);
}
