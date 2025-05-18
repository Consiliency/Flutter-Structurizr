import '../ast_node.dart' show AstNode, AstVisitor;
import 'source_position.dart' show SourcePosition;

class TagsNode extends AstNode {
  final List<String> tags;
  TagsNode({required this.tags, SourcePosition? sourcePosition})
      : super(sourcePosition);

  @override
  void accept(AstVisitor visitor) => visitor.visitTagsNode(this);
}
