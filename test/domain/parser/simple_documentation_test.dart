import 'package:flutter_structurizr/domain/parser/parser.dart';
import 'package:test/test.dart';

void main() {
  test('Simple documentation parsing test', () {
    // Create a simple workspace with only documentation and decisions
    final dsl = '''
    workspace "Documentation Test" {
      documentation {
        content = "This is documentation"
      }
    }
    ''';
    
    // Parse it with the standard parser
    final parser = Parser(dsl);
    
    // Monkey-patch the _match method
    // This is a hacky solution but might help us debug
    parser.overrideMatchMethod = true;
    
    final workspace = parser.parse();
    
    // Check if the workspace has documentation
    print('Workspace name: ${workspace.name}');
    print('Has documentation: ${workspace.documentation != null}');
    if (workspace.documentation != null) {
      print('Documentation content: ${workspace.documentation!.content}');
    }
    
    // Assertions
    expect(workspace.documentation, isNotNull);
    expect(workspace.documentation?.content, equals("This is documentation"));
  });
}