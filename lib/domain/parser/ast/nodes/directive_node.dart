import '../ast_node.dart';
import 'source_position.dart' show SourcePosition;

class DirectiveNode extends AstNode {
  final String type;
  final String value;
  DirectiveNode(
      {required this.type, required this.value, SourcePosition? sourcePosition})
      : super(sourcePosition);

  @override
  void accept(AstVisitor visitor) => visitor.visitDirectiveNode(this);
}
