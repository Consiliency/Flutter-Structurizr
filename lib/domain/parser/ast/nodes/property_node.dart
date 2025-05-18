import '../ast_node.dart';
import 'source_position.dart' show SourcePosition;

class PropertyNode extends AstNode {
  final String key;
  final String value;
  PropertyNode(
      {required this.key, required this.value, SourcePosition? sourcePosition})
      : super(sourcePosition);

  @override
  void accept(AstVisitor visitor) => visitor.visitPropertyNode(this);
}
