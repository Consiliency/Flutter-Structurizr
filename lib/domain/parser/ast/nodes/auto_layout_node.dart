import '../ast_node.dart' show AstNode, AstVisitor;
import 'source_position.dart';

class AutoLayoutNode extends AstNode {
  AutoLayoutNode({SourcePosition? sourcePosition}) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) {}
}
