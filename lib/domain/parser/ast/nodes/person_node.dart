import '../ast_node.dart' show AstNode, AstVisitor;
import 'source_position.dart' show SourcePosition;
import 'relationship_node.dart' show RelationshipNode;

class PersonNode extends AstNode {
  final String id;
  final String name;
  final String? description;
  final String? location;
  final List<String> tags;
  final Map<String, String> properties;
  final List<RelationshipNode> relationships;
  String? url;
  List<String>? perspectives;
  String? group;
  List<AstNode> children;

  PersonNode({
    required this.id,
    required this.name,
    this.description,
    this.location,
    this.tags = const [],
    this.properties = const {},
    this.relationships = const [],
    this.url,
    this.perspectives,
    this.group,
    this.children = const [],
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);

  @override
  void accept(AstVisitor visitor) => visitor.visitPersonNode(this);
}
