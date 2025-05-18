import '../ast_node.dart';
import 'source_position.dart' show SourcePosition;

class DynamicViewNode extends AstNode {
  final String key;
  final String? description;
  DynamicViewNode(
      {required this.key, this.description, SourcePosition? sourcePosition})
      : super(sourcePosition);

  @override
  void accept(AstVisitor visitor) => visitor.visitDynamicViewNode(this);
}
