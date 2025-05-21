import '../ast_node.dart' show AstNode, AstVisitor;
import 'source_position.dart';

class ThemeNode extends AstNode {
  final String? url;
  
  ThemeNode({
    this.url,
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);
  
  @override
  void accept(AstVisitor visitor) {}
}
