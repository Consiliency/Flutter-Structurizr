import 'package:flutter_structurizr/domain/parser/lexer/token.dart';
import '../ast_base.dart';

/// Types of includes in the Structurizr DSL.
enum IncludeType {
  /// Include a file (e.g., `!include file.dsl`).
  file,
  
  /// Include elements in a view (e.g., `include *` or `include "element1"`).
  view,
}

/// Node representing an include statement in the Structurizr DSL.
class IncludeNode extends AstNode {
  /// The expression to include (either a file path or an element pattern).
  final String expression;
  
  /// The type of include (file or view).
  IncludeType? type;
  
  /// Creates a new include node.
  IncludeNode({
    required this.expression,
    this.type,
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitIncludeNode(this);
  }
  
  /// Sets the type of this include node.
  void setType(IncludeType newType) {
    type = newType;
  }
  
  /// Returns true if this is a file include.
  bool get isFileInclude => type == IncludeType.file;
  
  /// Returns true if this is a view include.
  bool get isViewInclude => type == IncludeType.view;
  
  @override
  String toString() => 'IncludeNode(expression: "$expression", type: $type)';
}