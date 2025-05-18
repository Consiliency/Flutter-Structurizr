import '../../ast/ast_node.dart';
import 'source_position.dart' show SourcePosition;

class DocumentationNode extends AstNode {
  final String id;
  final List<DocumentationSectionNode> sections;
  DocumentationNode(
      {required this.id,
      this.sections = const [],
      SourcePosition? sourcePosition})
      : super(sourcePosition);

  @override
  void accept(AstVisitor visitor) => visitor.visitDocumentationNode(this);
}

class DocumentationSectionNode extends AstNode {
  final String id;
  final String title;
  final String content;
  DocumentationSectionNode(
      {required this.id,
      required this.title,
      required this.content,
      SourcePosition? sourcePosition})
      : super(sourcePosition);

  @override
  void accept(AstVisitor visitor) =>
      visitor.visitDocumentationSectionNode(this);
}
