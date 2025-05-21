import '../ast_node.dart';
import 'source_position.dart' show SourcePosition;

class SystemLandscapeViewNode extends AstNode {
  final String key;
  final String? title;
  final String? description;
  final dynamic autoLayout;
  final List<dynamic> animations;
  final List<dynamic> includes;
  final List<dynamic> excludes;
  
  SystemLandscapeViewNode({
    required this.key,
    this.title,
    this.description,
    this.autoLayout,
    this.animations = const [],
    this.includes = const [],
    this.excludes = const [],
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);

  @override
  void accept(AstVisitor visitor) => visitor.visitSystemLandscapeViewNode(this);
}
