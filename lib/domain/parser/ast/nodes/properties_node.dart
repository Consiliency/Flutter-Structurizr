import '../ast_node.dart';
import 'source_position.dart' show SourcePosition;

class PropertiesNode extends AstNode {
  final Map<String, String> properties;
  PropertiesNode({required this.properties, SourcePosition? sourcePosition})
      : super(sourcePosition);

  @override
  void accept(AstVisitor visitor) => visitor.visitPropertiesNode(this);
}
