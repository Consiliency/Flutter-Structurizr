import 'package:flutter_structurizr/domain/parser/lexer/lexer.dart';
import 'package:flutter_structurizr/domain/parser/lexer/token.dart';
import 'package:test/test.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/source_position.dart';

void main() {
  test('Documentation and decisions are properly recognized as tokens', () {
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

    final lexer = Lexer(source);
    final tokens = lexer.scanTokens();

    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      // (logging removed)
    }

    // Find documentation and decisions tokens
    final docToken = tokens.firstWhere(
      (t) => t.lexeme == 'documentation',
      orElse: () => Token(
        type: TokenType.error,
        lexeme: 'not_found',
        value: null,
        position: const SourcePosition(0, 0, 0),
      ),
    );

    final decisionsToken = tokens.firstWhere(
      (t) => t.lexeme == 'decisions',
      orElse: () => Token(
        type: TokenType.error,
        lexeme: 'not_found',
        value: null,
        position: const SourcePosition(0, 0, 0),
      ),
    );

    // (logging removed)

    // Check that they're recognized as the correct token types
    expect(docToken.type, TokenType.documentation,
        reason:
            'documentation should be recognized as TokenType.documentation');
    expect(decisionsToken.type, TokenType.decisions,
        reason: 'decisions should be recognized as TokenType.decisions');
  });
}
