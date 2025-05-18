import '../ast_node.dart' show AstNode, AstVisitor;
import 'source_position.dart';

class TerminologyNode extends AstNode {
  TerminologyNode({SourcePosition? sourcePosition}) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) {}
}
