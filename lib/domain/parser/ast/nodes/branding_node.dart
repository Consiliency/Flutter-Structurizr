import '../ast_node.dart' show AstNode, AstVisitor;
import 'source_position.dart';

class BrandingNode extends AstNode {
  final String? logo;
  final String? font;
  
  BrandingNode({
    this.logo,
    this.font,
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);
  
  @override
  void accept(AstVisitor visitor) {}
}
