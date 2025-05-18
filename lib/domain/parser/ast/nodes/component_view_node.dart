import '../ast_node.dart';
import 'source_position.dart' show SourcePosition;

class ComponentViewNode extends AstNode {
  final String key;
  final String containerId;
  final String? title;
  final String? description;
  ComponentViewNode(
      {required this.key,
      required this.containerId,
      this.title,
      this.description,
      SourcePosition? sourcePosition})
      : super(sourcePosition);

  @override
  void accept(AstVisitor visitor) => visitor.visitComponentViewNode(this);
}
