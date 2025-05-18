import '../ast_node.dart' show AstNode, AstVisitor;
import 'source_position.dart' show SourcePosition;

class RelationshipNode extends AstNode {
  final String sourceId;
  final String destinationId;
  final String? description;
  final String? technology;
  final List<String> tags;
  final Map<String, String> properties;
  RelationshipNode(
      {required this.sourceId,
      required this.destinationId,
      this.description,
      this.technology,
      this.tags = const [],
      this.properties = const {},
      SourcePosition? sourcePosition})
      : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) {}
}
