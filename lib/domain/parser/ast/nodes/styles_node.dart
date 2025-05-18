import '../ast_node.dart' show AstNode, AstVisitor;
import 'source_position.dart';

class StylesNode extends AstNode {
  StylesNode({SourcePosition? sourcePosition}) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) {}

  List<dynamic> get elements => const [];
  List<dynamic> get relationships => const [];
}

class ElementStyleNode extends AstNode {
  ElementStyleNode({SourcePosition? sourcePosition}) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) {}
}

class RelationshipStyleNode extends AstNode {
  RelationshipStyleNode({SourcePosition? sourcePosition})
      : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) {}
}
