import 'package:flutter_structurizr/domain/parser/ast/ast_base.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';

/// An enumeration representing the format of documentation content.
enum DocumentationFormat {
  /// Plain text format
  text,
  
  /// Markdown format
  markdown,
  
  /// AsciiDoc format
  asciidoc,
}

/// Base class for all documentation-related nodes.
abstract class DocumentationBaseNode extends AstNode {
  /// Creates a new documentation node
  DocumentationBaseNode({
    required SourcePosition? sourcePosition,
  }) : super(sourcePosition);
}

/// Represents a documentation section in the AST.
class DocumentationNode extends AstNode {
  /// The content of the documentation
  final String content;
  
  /// The format of the documentation (markdown, asciidoc, etc.)
  final DocumentationFormat format;
  
  /// Child sections within this documentation section
  final List<DocumentationSectionNode> sections;
  
  /// Creates a new documentation node.
  DocumentationNode({
    required this.content,
    this.format = DocumentationFormat.markdown,
    this.sections = const [],
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitDocumentationNode(this);
  }
}

/// Represents a section within a documentation block.
class DocumentationSectionNode extends AstNode {
  /// The title of the section
  final String title;
  
  /// The content of the section
  final String content;
  
  /// The format of the section content
  final DocumentationFormat format;
  
  /// Creates a new documentation section node.
  DocumentationSectionNode({
    required this.title,
    required this.content,
    this.format = DocumentationFormat.markdown,
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitDocumentationSectionNode(this);
  }
}

/// Represents a reference to a diagram embedded within documentation.
class DiagramReferenceNode extends AstNode {
  /// The key of the diagram to include
  final String diagramKey;
  
  /// Optional title for the diagram
  final String? title;
  
  /// Optional width for the diagram rendering
  final String? width;
  
  /// Optional height for the diagram rendering
  final String? height;
  
  /// Creates a new diagram reference node.
  DiagramReferenceNode({
    required this.diagramKey,
    this.title,
    this.width,
    this.height,
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitDiagramReferenceNode(this);
  }
}

/// Represents an Architecture Decision Record (ADR) in the AST.
class DecisionNode extends AstNode {
  /// The ID of the decision
  final String decisionId;
  
  /// The title of the decision
  final String title;
  
  /// The date the decision was made
  final String? date;
  
  /// The status of the decision
  final String status;
  
  /// The content of the decision record
  final String content;
  
  /// The format of the decision content
  final DocumentationFormat format;
  
  /// References to related decisions
  final List<String> links;
  
  /// Creates a new decision node.
  DecisionNode({
    required this.decisionId,
    required this.title,
    required this.status,
    required this.content,
    this.date,
    this.format = DocumentationFormat.markdown,
    this.links = const [],
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitDecisionNode(this);
  }
}