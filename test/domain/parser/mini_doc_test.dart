import 'package:flutter_structurizr/domain/parser/parser.dart';
import 'package:test/test.dart';

void main() {
  test('Minimal documentation parser test', () {
    // Create a simple test with just documentation
    const source = '''
    workspace "Test" {
      documentation {
        content = "Test documentation"
      }
    }
    ''';

    // Parse it - but use direct assertion on the WorkspaceNode
    final parser = Parser(source);
    final workspaceNode =
        parser.parse(); // This is a WorkspaceNode, not a Workspace

    // This test is looking at the WorkspaceNode from the parser, not the Domain model Workspace
    // TODO: Replace with proper logging or remove for production

    // Let's make the minimal assertion
    expect(workspaceNode.documentation, isNotNull,
        reason: 'Documentation should be present in the workspace node');
  });
}
