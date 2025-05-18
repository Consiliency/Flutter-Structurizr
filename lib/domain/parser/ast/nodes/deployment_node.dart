import '../ast_node.dart' show AstNode, AstVisitor;
import 'source_position.dart';

class DeploymentNodeNode extends AstNode {
  DeploymentNodeNode({SourcePosition? sourcePosition}) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) {}
}
