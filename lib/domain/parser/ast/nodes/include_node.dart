import '../ast_node.dart' show AstNode, AstVisitor;
import 'source_position.dart' show SourcePosition;
import 'package:flutter_structurizr/domain/parser/ast/ast_node.dart'
    show WorkspaceNode;

enum IncludeType { file, directory, url, view }

class IncludeNode extends AstNode {
  final String path;
  final bool isFileInclude;
  final String expression;
  final IncludeType type;
  WorkspaceNode? _workspace;
  WorkspaceNode? get workspace => _workspace;
  set workspace(WorkspaceNode? ws) => _workspace = ws;

  IncludeNode({
    required this.path,
    this.isFileInclude = true,
    this.expression = '',
    this.type = IncludeType.file,
    WorkspaceNode? workspace,
    SourcePosition? sourcePosition,
  }) : super(sourcePosition) {
    _workspace = workspace;
  }

  @override
  void accept(AstVisitor visitor) => visitor.visitIncludeNode(this);
}
