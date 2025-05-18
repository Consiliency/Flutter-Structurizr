import '../ast_node.dart' show AstNode, AstVisitor;
import 'source_position.dart';

class AnimationNode extends AstNode {
  AnimationNode({SourcePosition? sourcePosition}) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) {}
}
