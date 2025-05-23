import '../ast_node.dart' show AstNode, AstVisitor;
import 'source_position.dart' show SourcePosition;

class ContainerInstanceNode extends AstNode {
  final String id;
  final String identifier;
  List<String> deploymentGroups;
  List<String> tags;
  String? group;
  List<AstNode> relationships;
  List<AstNode> healthChecks;
  List<AstNode> children;
  
  // Alias for id to match workspace builder usage
  String get containerId => id;
  
  // Properties for workspace builder compatibility
  Map<String, String> get properties => const {};

  ContainerInstanceNode({
    required this.id,
    required this.identifier,
    this.deploymentGroups = const [],
    this.tags = const [],
    this.group,
    this.relationships = const [],
    this.healthChecks = const [],
    this.children = const [],
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);

  @override
  void accept(AstVisitor visitor) => visitor.visitContainerInstanceNode(this);
}
