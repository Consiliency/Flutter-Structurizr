import '../ast_node.dart';
import 'source_position.dart' show SourcePosition;

class FilteredViewNode extends AstNode {
  final String key;
  final String baseViewKey;
  final String mode;
  final String? description;
  FilteredViewNode(
      {required this.key,
      required this.baseViewKey,
      required this.mode,
      this.description,
      SourcePosition? sourcePosition})
      : super(sourcePosition);

  @override
  void accept(AstVisitor visitor) => visitor.visitFilteredViewNode(this);
}
