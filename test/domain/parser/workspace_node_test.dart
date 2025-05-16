import 'package:flutter_structurizr/domain/parser/ast/ast.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/documentation/documentation_node.dart';
import 'package:flutter_structurizr/domain/parser/lexer/token.dart';
import 'package:test/test.dart';

void main() {
  test('WorkspaceNode correctly stores documentation', () {
    // Create a simple documentation node
    final docNode = DocumentationNode(
      content: "Test documentation",
      format: DocumentationFormat.markdown,
      sections: [],
      sourcePosition: SourcePosition(line: 1, column: 1, offset: 0),
    );
    
    // Create a workspace node with the documentation
    final workspaceNode = WorkspaceNode(
      name: "Test",
      description: null,
      model: null,
      views: null,
      styles: null,
      themes: [],
      branding: null,
      terminology: null,
      properties: null,
      configuration: {},
      documentation: docNode,
      decisions: [],
      sourcePosition: SourcePosition(line: 1, column: 1, offset: 0),
    );
    
    // Check that the documentation is properly stored
    print('Workspace name: ${workspaceNode.name}');
    print('Has documentation: ${workspaceNode.documentation != null}');
    
    if (workspaceNode.documentation != null) {
      print('Documentation content: ${workspaceNode.documentation!.content}');
    }
    
    expect(workspaceNode.documentation, isNotNull);
    expect(workspaceNode.documentation?.content, equals("Test documentation"));
  });
}