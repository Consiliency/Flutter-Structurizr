import '../ast_node.dart' show AstNode, AstVisitor;
import 'source_position.dart' show SourcePosition;
import 'relationship_node.dart' show RelationshipNode;
import 'component_node.dart' show ComponentNode;

class ContainerNode extends AstNode {
  final String id;
  final String name;
  final String? description;
  final String? technology;
  final List<String> tags;
  final Map<String, String> properties;
  final List<RelationshipNode> relationships;
  final List<ComponentNode> components;
  String? url;
  List<String>? perspectives;
  String? group;
  List<AstNode> docs;
  List<AstNode> adrs;
  List<AstNode> children;

  ContainerNode({
    required this.id,
    required this.name,
    this.description,
    this.technology,
    this.tags = const [],
    this.properties = const {},
    this.relationships = const [],
    this.components = const [],
    this.url,
    this.perspectives,
    this.group,
    this.docs = const [],
    this.adrs = const [],
    this.children = const [],
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);

  @override
  void accept(AstVisitor visitor) => visitor.visitContainerNode(this);
}
