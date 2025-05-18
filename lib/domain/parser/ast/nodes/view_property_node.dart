import '../ast_node.dart' show AstNode, AstVisitor;
import 'source_position.dart' show SourcePosition;

class ViewPropertyNode extends AstNode {
  final String name;
  final String value;
  ViewPropertyNode({
    required this.name,
    required this.value,
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);

  @override
  void accept(AstVisitor visitor) => visitor.visitViewPropertyNode(this);
}
