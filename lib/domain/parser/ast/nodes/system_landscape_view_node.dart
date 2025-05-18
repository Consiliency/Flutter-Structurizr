import '../ast_node.dart';
import 'source_position.dart' show SourcePosition;

class SystemLandscapeViewNode extends AstNode {
  final String key;
  final String? title;
  final String? description;
  SystemLandscapeViewNode(
      {required this.key,
      this.title,
      this.description,
      SourcePosition? sourcePosition})
      : super(sourcePosition);

  @override
  void accept(AstVisitor visitor) => visitor.visitSystemLandscapeViewNode(this);
}
