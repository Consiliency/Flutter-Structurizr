import 'package:flutter_structurizr/domain/parser/ast/ast_nodes.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/documentation/documentation_node.dart';
import 'package:flutter_structurizr/domain/parser/lexer/token.dart';
import 'package:test/test.dart';

void main() {
  test('Direct WorkspaceNode construction with documentation', () {
    // 1. Create a DocumentationNode
    final docNode = DocumentationNode(
      content: "Test Documentation",
      format: DocumentationFormat.markdown,
      sections: [],
      sourcePosition: null,
    );
    
    // 2. Create a WorkspaceNode with this documentation
    final workspaceNode = WorkspaceNode(
      name: "Test Workspace",
      documentation: docNode,
      decisions: [],
    );
    
    // 3. Verify it has the documentation
    print('Directly created WorkspaceNode:');
    print('- has documentation: ${workspaceNode.documentation != null}');
    if (workspaceNode.documentation != null) {
      print('- documentation content: "${workspaceNode.documentation!.content}"');
    }
    
    // 4. Assert
    expect(workspaceNode.documentation, isNotNull);
    expect(workspaceNode.documentation?.content, equals("Test Documentation"));
  });
}