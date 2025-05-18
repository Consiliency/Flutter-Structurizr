import '../ast_node.dart' show AstNode, AstVisitor;
import 'source_position.dart';

class ThemeNode extends AstNode {
  ThemeNode({SourcePosition? sourcePosition}) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) {}
}
