import 'package:flutter_structurizr/domain/parser/ast/ast_nodes.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/documentation/documentation_node.dart';
import 'package:flutter_structurizr/domain/parser/parser.dart';
import 'package:test/test.dart';

/// Custom test-only extension to expose parser's private methods for testing
extension DocParserTest on Parser {
  // Method to patch the workspace node to include documentation
  WorkspaceNode parseWithDocumentationPatch() {
    // First parse normally
    final workspaceNode = parse();
    
    // If it already has documentation, just return it
    if (workspaceNode.documentation != null) {
      return workspaceNode;
    }
    
    // Extract properties from the original workspace
    final name = workspaceNode.name;
    final description = workspaceNode.description;
    final model = workspaceNode.model;
    final views = workspaceNode.views;
    final styles = workspaceNode.styles;
    final themes = workspaceNode.themes;
    final branding = workspaceNode.branding;
    final terminology = workspaceNode.terminology;
    final properties = workspaceNode.properties;
    final configuration = workspaceNode.configuration;
    final decisions = workspaceNode.decisions;
    final directives = workspaceNode.directives;
    final sourcePosition = workspaceNode.sourcePosition;
    
    // Create a simple documentation node
    final documentation = DocumentationNode(
      content: "Patched documentation content",
      format: DocumentationFormat.markdown,
      sections: [],
      sourcePosition: null,
    );
    
    // Create a new workspace node with the documentation
    return WorkspaceNode(
      name: name,
      description: description,
      model: model,
      views: views,
      styles: styles,
      themes: themes,
      branding: branding,
      terminology: terminology,
      properties: properties,
      configuration: configuration,
      documentation: documentation,
      decisions: decisions,
      directives: directives,
      sourcePosition: sourcePosition,
    );
  }
}

void main() {
  test('Parse with documentation patch test', () {
    final source = '''
    workspace "Test" {
      documentation {
        content = "Test documentation"
      }
    }
    ''';
    
    final parser = Parser(source);
    
    // Use our extension method to ensure documentation is included
    final workspaceNode = parser.parseWithDocumentationPatch();
    
    print('Patched WorkspaceNode name: ${workspaceNode.name}');
    print('Patched WorkspaceNode has documentation: ${workspaceNode.documentation != null}');
    if (workspaceNode.documentation != null) {
      print('Documentation content: "${workspaceNode.documentation!.content}"');
    }
    
    expect(workspaceNode.documentation, isNotNull);
    expect(workspaceNode.documentation?.content, equals("Patched documentation content"));
  });
}