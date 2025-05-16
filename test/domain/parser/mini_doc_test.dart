import 'package:flutter_structurizr/domain/parser/parser.dart';
import 'package:flutter_structurizr/domain/parser/ast/ast.dart'; // Import AST types 
import 'package:test/test.dart';

void main() {
  test('Minimal documentation parser test', () {
    // Create a simple test with just documentation
    final source = '''
    workspace "Test" {
      documentation {
        content = "Test documentation"
      }
    }
    ''';
    
    // Parse it - but use direct assertion on the WorkspaceNode
    final parser = Parser(source);
    final workspaceNode = parser.parse(); // This is a WorkspaceNode, not a Workspace

    // This test is looking at the WorkspaceNode from the parser, not the Domain model Workspace
    print('WorkspaceNode name: ${workspaceNode.name}');
    print('WorkspaceNode has documentation: ${workspaceNode.documentation != null}');
    
    if (workspaceNode.documentation != null) {
      print('Documentation content: ${workspaceNode.documentation!.content}');
    } else {
      print('WARNING: No documentation found in workspace node!');
    }
    
    // Let's make the minimal assertion
    expect(workspaceNode.documentation, isNotNull, 
      reason: 'Documentation should be present in the workspace node');
  });
}