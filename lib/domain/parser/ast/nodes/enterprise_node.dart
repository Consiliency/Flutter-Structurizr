import '../ast_node.dart' show AstNode, AstVisitor;
import 'source_position.dart';

class EnterpriseNode extends AstNode {
  final String name;
  final List<dynamic> children;
  final Map<String, String> properties;

  EnterpriseNode({
    this.name = '',
    this.children = const [],
    this.properties = const {},
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);

  EnterpriseNode addElement(dynamic element) {
    return EnterpriseNode(
      name: name,
      children: [...children, element],
      properties: properties,
      sourcePosition: sourcePosition,
    );
  }

  EnterpriseNode setProperty(String key, String value) {
    final newProperties = Map<String, String>.from(properties);
    newProperties[key] = value;
    return EnterpriseNode(
      name: name,
      children: children,
      properties: newProperties,
      sourcePosition: sourcePosition,
    );
  }

  @override
  void accept(AstVisitor visitor) {}
}
