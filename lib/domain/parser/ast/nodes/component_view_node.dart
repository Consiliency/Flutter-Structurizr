import '../ast_node.dart';
import 'source_position.dart' show SourcePosition;

class ComponentViewNode extends AstNode {
  final String key;
  final String containerId;
  final String? title;
  final String? description;
  final dynamic autoLayout;
  final List<dynamic> animations;
  final List<dynamic> includes;
  final List<dynamic> excludes;
  
  ComponentViewNode({
    required this.key,
    required this.containerId,
    this.title,
    this.description,
    this.autoLayout,
    this.animations = const [],
    this.includes = const [],
    this.excludes = const [],
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);

  @override
  void accept(AstVisitor visitor) => visitor.visitComponentViewNode(this);
}
