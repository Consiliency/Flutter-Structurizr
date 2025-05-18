import 'package:flutter_structurizr/domain/parser/parser.dart';
import 'package:test/test.dart';
import 'package:logging/logging.dart';

final _logger = Logger('ParserKeywordTest');

void main() {
  test('Parser recognizes documentation and decisions blocks', () {
    const source = '''
      workspace "Test" {
        documentation {
          content = "Documentation content"
        }
        
        decisions {
          decision "ADR-001" {
            title = "Test Decision"
            status = "Accepted"
            content = "Decision content"
          }
        }
      }
    ''';

    final parser = Parser(source);
    final workspaceNode = parser.parse();

    _logger.info(
        'Workspace has documentation: ${workspaceNode.documentation != null}');
    _logger
        .info('Documentation content: ${workspaceNode.documentation?.content}');
    _logger.info(
        'Workspace has decisions: ${workspaceNode.decisions?.length ?? 0}');

    if (workspaceNode.decisions != null &&
        workspaceNode.decisions!.isNotEmpty) {
      _logger
          .info('First decision ID: ${workspaceNode.decisions![0].decisionId}');
    }

    expect(workspaceNode.documentation, isNotNull);
    expect(
        workspaceNode.documentation?.content, equals('Documentation content'));
    expect(workspaceNode.decisions, isNotNull);
    expect(workspaceNode.decisions!.length, equals(1));
    expect(workspaceNode.decisions![0].decisionId, equals('ADR-001'));
  });
}
