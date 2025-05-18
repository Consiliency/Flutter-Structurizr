import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/parser/lexer/lexer.dart';
import 'package:flutter_structurizr/domain/parser/lexer/token.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

final _logger = Logger('TokenDebug');

void main() {
  test('Debug tokens for documentation and decisions', () {
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

    final errorReporter = ErrorReporter(source);
    final lexer = Lexer(source);
    final tokens = lexer.scanTokens();

    _logger.info('\n--- ALL TOKENS ---');
    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      _logger.info('$i: ${token.type}  < /dev/null |  ${token.lexeme}');
    }
    _logger.info('--- END ALL TOKENS ---\n');

    // Check if the documentation and decisions tokens are recognized
    final docTokens =
        tokens.where((t) => t.type == TokenType.documentation).toList();
    final decTokens =
        tokens.where((t) => t.type == TokenType.decisions).toList();

    _logger.info('Documentation tokens found: ${docTokens.length}');
    docTokens.forEach((t) => _logger
        .info('  ${t.type} | ${t.lexeme} at line ${t.line}, col ${t.column}'));

    _logger.info('Decisions tokens found: ${decTokens.length}');
    decTokens.forEach((t) => _logger
        .info('  ${t.type} | ${t.lexeme} at line ${t.line}, col ${t.column}'));

    // Check for identifiers that might be documentation/decisions but weren't recognized
    final identifiers = tokens
        .where((t) =>
            t.type == TokenType.identifier &&
            (t.lexeme == 'documentation' || t.lexeme == 'decisions'))
        .toList();

    _logger.info('Identifiers that should be keywords: ${identifiers.length}');
    identifiers.forEach((t) => _logger
        .info('  ${t.type} | ${t.lexeme} at line ${t.line}, col ${t.column}'));

    // For completeness, here are the assertions
    expect(docTokens.length, greaterThan(0),
        reason: 'Should find documentation tokens');
    expect(decTokens.length, greaterThan(0),
        reason: 'Should find decisions tokens');
    expect(identifiers.length, equals(0),
        reason: 'Should not find documentation/decisions as identifiers');
  });
}
