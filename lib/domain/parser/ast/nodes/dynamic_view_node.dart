import '../ast_node.dart';
import 'source_position.dart' show SourcePosition;

class DynamicViewNode extends AstNode {
  final String key;
  final String? description;
  final String? title;
  final String? scope;
  final dynamic autoLayout;
  final List<dynamic> animations;
  final List<dynamic> includes;
  final List<dynamic> excludes;
  
  DynamicViewNode({
    required this.key,
    this.description,
    this.title,
    this.scope,
    this.autoLayout,
    this.animations = const [],
    this.includes = const [],
    this.excludes = const [],
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);

  @override
  void accept(AstVisitor visitor) => visitor.visitDynamicViewNode(this);
}
