import '../ast_node.dart' show AstNode, AstVisitor;
import 'source_position.dart' show SourcePosition;

class ExcludeNode extends AstNode {
  final String pattern;
  ExcludeNode({
    required this.pattern,
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);

  @override
  void accept(AstVisitor visitor) => visitor.visitExcludeNode(this);
}
