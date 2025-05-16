import 'package:flutter_structurizr/domain/documentation/documentation.dart' as domain;
import 'package:flutter_structurizr/domain/parser/ast/default_visitor.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/documentation/documentation_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/ast_base.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';

/// Mapper for converting documentation AST nodes to domain model objects.
///
/// This class implements the visitor pattern to traverse the AST
/// and build the corresponding domain documentation model.
class DocumentationMapper extends DefaultAstVisitor {
  /// The error reporter for reporting semantic errors.
  final ErrorReporter errorReporter;
  
  /// The resulting documentation after mapping.
  domain.Documentation? _documentation;
  
  /// List of documentation sections being built
  final List<domain.DocumentationSection> _sections = [];
  
  /// List of decisions being built
  final List<domain.Decision> _decisions = [];
  
  /// List of images being built
  final List<domain.Image> _images = [];
  
  /// Creates a new documentation mapper.
  DocumentationMapper(this.errorReporter);
  
  /// Maps an AST to a domain model documentation.
  /// 
  /// This is the main entry point for the mapping process.
  domain.Documentation? mapDocumentation(DocumentationNode documentationNode) {
    try {
      // Traverse the AST starting from the documentation node
      documentationNode.accept(this);
      
      // Always create an Overview section with the root content
      // This matches the original Structurizr behavior
      if (documentationNode.content.isNotEmpty) {
        _sections.add(domain.DocumentationSection(
          title: 'Overview',
          content: documentationNode.content,
          format: _mapDocumentationFormat(documentationNode.format),
          order: 1,
        ));
      }
      
      // Build the final documentation
      _documentation = domain.Documentation(
        sections: _sections,
        decisions: _decisions,
        images: _images,
      );
      
      return _documentation;
    } catch (e, stackTrace) {
      // Log any errors during mapping
      errorReporter.reportStandardError(
        'Error mapping documentation: ${e.toString()}\n$stackTrace',
        documentationNode.sourcePosition?.offset ?? 0,
      );
      return null;
    }
  }
  
  /// Maps decisions from the AST to domain model.
  List<domain.Decision> mapDecisions(List<DecisionNode> decisionNodes) {
    try {
      for (final node in decisionNodes) {
        node.accept(this);
      }
      return _decisions;
    } catch (e, stackTrace) {
      // Log any errors during mapping
      errorReporter.reportStandardError(
        'Error mapping decisions: ${e.toString()}\n$stackTrace',
        decisionNodes.isNotEmpty ? decisionNodes.first.sourcePosition?.offset ?? 0 : 0,
      );
      return [];
    }
  }
  
  /// Converts AST documentation format to domain model documentation format.
  domain.DocumentationFormat _mapDocumentationFormat(DocumentationFormat format) {
    switch (format) {
      case DocumentationFormat.markdown:
        return domain.DocumentationFormat.markdown;
      case DocumentationFormat.asciidoc:
        return domain.DocumentationFormat.asciidoc;
      case DocumentationFormat.text:
        // Text format is treated as markdown in the domain model
        return domain.DocumentationFormat.markdown;
      default:
        return domain.DocumentationFormat.markdown;
    }
  }
  
  @override
  void visitDocumentationNode(DocumentationNode node) {
    // Process any child sections
    for (final section in node.sections) {
      section.accept(this);
    }
  }
  
  @override
  void visitDocumentationSectionNode(DocumentationSectionNode node) {
    // Add the section to our collection
    _sections.add(domain.DocumentationSection(
      title: node.title,
      content: node.content,
      format: _mapDocumentationFormat(node.format),
      order: _sections.length + 1,
    ));
  }
  
  @override
  void visitDecisionNode(DecisionNode node) {
    // Parse the date string to a DateTime object
    DateTime date;
    try {
      date = node.date != null 
          ? DateTime.parse(node.date!) 
          : DateTime.now();
    } catch (e) {
      errorReporter.reportWarning(
        'Invalid date format for decision ${node.decisionId}: ${node.date}. Using current date.',
        node.sourcePosition?.offset ?? 0,
      );
      date = DateTime.now();
    }
    
    // Add the decision to our collection
    _decisions.add(domain.Decision(
      id: node.decisionId,
      date: date,
      status: node.status,
      title: node.title,
      content: node.content,
      format: _mapDocumentationFormat(node.format),
      links: node.links,
    ));
  }
}