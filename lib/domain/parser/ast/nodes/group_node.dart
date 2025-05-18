import '../ast_node.dart' show AstNode, AstVisitor;
import 'source_position.dart';

class GroupNode extends AstNode {
  final String name;
  final List<dynamic> children;
  final Map<String, String> properties;

  GroupNode({
    this.name = '',
    this.children = const [],
    this.properties = const {},
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);

  GroupNode addElement(dynamic element) {
    return GroupNode(
      name: name,
      children: [...children, element],
      properties: properties,
      sourcePosition: sourcePosition,
    );
  }

  GroupNode setProperty(String key, String value) {
    final newProperties = Map<String, String>.from(properties);
    newProperties[key] = value;
    return GroupNode(
      name: name,
      children: children,
      properties: newProperties,
      sourcePosition: sourcePosition,
    );
  }

  List<dynamic> get relationships => const [];

  @override
  void accept(AstVisitor visitor) {}
}
