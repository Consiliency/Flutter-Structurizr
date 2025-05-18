import '../ast_node.dart' show AstNode, AstVisitor;
import 'source_position.dart' show SourcePosition;

class InfrastructureNodeNode extends AstNode {
  final String id;
  final String name;
  String? description;
  String? technology;
  List<String> tags;
  String? url;
  Map<String, String>? properties;
  List<String>? perspectives;
  List<AstNode> relationships;
  String? group;
  List<AstNode> children;

  InfrastructureNodeNode({
    required this.id,
    required this.name,
    this.description,
    this.technology,
    this.tags = const [],
    this.url,
    this.properties,
    this.perspectives,
    this.relationships = const [],
    this.group,
    this.children = const [],
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);

  @override
  void accept(AstVisitor visitor) => visitor.visitInfrastructureNodeNode(this);
}
