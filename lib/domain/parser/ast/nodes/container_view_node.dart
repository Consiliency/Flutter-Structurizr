import '../ast_node.dart';
import 'source_position.dart' show SourcePosition;

class ContainerViewNode extends AstNode {
  final String key;
  final String systemId;
  final String? title;
  final String? description;
  final dynamic autoLayout;
  final List<dynamic> animations;
  final List<dynamic> includes;
  final List<dynamic> excludes;
  
  ContainerViewNode({
    required this.key,
    required this.systemId,
    this.title,
    this.description,
    this.autoLayout,
    this.animations = const [],
    this.includes = const [],
    this.excludes = const [],
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);

  @override
  void accept(AstVisitor visitor) => visitor.visitContainerViewNode(this);
}
