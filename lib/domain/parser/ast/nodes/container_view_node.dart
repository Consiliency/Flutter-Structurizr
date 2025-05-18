import '../ast_node.dart';
import 'source_position.dart' show SourcePosition;

class ContainerViewNode extends AstNode {
  final String key;
  final String systemId;
  final String? title;
  final String? description;
  ContainerViewNode(
      {required this.key,
      required this.systemId,
      this.title,
      this.description,
      SourcePosition? sourcePosition})
      : super(sourcePosition);

  @override
  void accept(AstVisitor visitor) => visitor.visitContainerViewNode(this);
}
