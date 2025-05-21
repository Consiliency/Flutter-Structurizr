import '../ast_node.dart';
import 'source_position.dart' show SourcePosition;

class FilteredViewNode extends AstNode {
  final String key;
  final String baseViewKey;
  final String mode;
  final String? description;
  final String? title;
  final dynamic autoLayout;
  final List<dynamic> animations;
  final List<dynamic> includes;
  final List<dynamic> excludes;
  
  FilteredViewNode({
    required this.key,
    required this.baseViewKey,
    required this.mode,
    this.description,
    this.title,
    this.autoLayout,
    this.animations = const [],
    this.includes = const [],
    this.excludes = const [],
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);

  @override
  void accept(AstVisitor visitor) => visitor.visitFilteredViewNode(this);
}
