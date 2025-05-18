import 'package:flutter_structurizr/domain/parser/lexer/lexer.dart';
import 'package:flutter_structurizr/domain/parser/lexer/token.dart';
import 'package:flutter_structurizr/domain/parser/parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('String Literal Parsing', () {
    test('correctly tokenizes basic strings', () {
      // Arrange
      const source = 'workspace "My Workspace" { }';
      final lexer = Lexer(source);

      // Act
      final tokens = lexer.scanTokens();

      // Assert
      expect(tokens.length, equals(5)); // workspace, string, {, }, EOF
      expect(tokens[0].type, equals(TokenType.workspace));
      expect(tokens[1].type, equals(TokenType.string));
      expect(tokens[1].value, equals('My Workspace'));
    });

    test('correctly tokenizes strings with special characters', () {
      // Arrange
      const source = 'workspace "Workspace with \$pecial ch@rs!" { }';
      final lexer = Lexer(source);

      // Act
      final tokens = lexer.scanTokens();

      // Assert
      expect(tokens.length, equals(5)); // workspace, string, {, }, EOF
      expect(tokens[0].type, equals(TokenType.workspace));
      expect(tokens[1].type, equals(TokenType.string));
      expect(tokens[1].value, equals('Workspace with \$pecial ch@rs!'));
    });

    test('correctly tokenizes strings with escape sequences', () {
      // Arrange
      const source = 'workspace "Line 1\\nLine 2\\tTabbed" { }';
      final lexer = Lexer(source);

      // Act
      final tokens = lexer.scanTokens();

      // Assert
      expect(tokens.length, equals(5)); // workspace, string, {, }, EOF
      expect(tokens[0].type, equals(TokenType.workspace));
      expect(tokens[1].type, equals(TokenType.string));
      expect(tokens[1].value, equals('Line 1\nLine 2\tTabbed'));
    });

    test('correctly parses workspace with special character strings', () {
      // Arrange
      const source =
          'workspace "C4 \$ystem with @special chars!" "This is the \$ystem description" { }';
      final parser = Parser(source);

      // Act
      final ast = parser.parse();

      // Assert
      expect(ast, isNotNull);
      expect(ast.name, equals('C4 \$ystem with @special chars!'));
      expect(ast.description, equals('This is the \$ystem description'));
    });

    test('recovers from errors in string literals', () {
      // Arrange - unterminated string
      const source = 'workspace "Unterminated string { }';
      final parser = Parser(source);

      // Act
      final ast = parser.parse();

      // Assert - should recover and produce some result
      expect(ast, isNotNull);
      // Should have some error but not crash
      expect(ast.name, isNotNull);
    });

    test('handles nested strings in hierarchical structures', () {
      // Arrange
      const source = '''
        workspace "Banking System" {
          model {
            customer = person "Customer with \$pecial chars" "A cu\$tomer of the bank"
          }
        }
      ''';
      final parser = Parser(source);

      // Act
      final ast = parser.parse();

      // Assert
      expect(ast, isNotNull);
      expect(ast.name, equals('Banking System'));
      expect(ast.model, isNotNull);

      // Check person node
      final personNode = ast.model!.people.first;
      expect(personNode.name, equals('Customer with \$pecial chars'));
      expect(personNode.description, equals('A cu\$tomer of the bank'));
    });
  });
}
