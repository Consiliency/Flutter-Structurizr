import '../ast_node.dart';
import 'source_position.dart' show SourcePosition;

class CustomViewNode extends AstNode {
  final String key;
  final String? title;
  final String? description;
  CustomViewNode(
      {required this.key,
      this.title,
      this.description,
      SourcePosition? sourcePosition})
      : super(sourcePosition);

  @override
  void accept(AstVisitor visitor) => visitor.visitCustomViewNode(this);
}
