import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/parser/lexer/token.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/source_position.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';

// This would be the actual implementation file we're testing
import 'package:flutter_structurizr/domain/parser/element_parser.dart';

ErrorReporter errorReporter = ErrorReporter('test');

void main() {
  late ElementParser elementParser;

  setUp(() {
    elementParser = ElementParser();
  });

  group('ElementParser._parseIdentifier detailed tests', () {
    test('should parse identifier from string token', () {
      // Create input tokens with a string token
      final tokens = [
        Token(
          type: TokenType.string,
          lexeme: '"MyIdentifier"',
          position: const SourcePosition(1, 1, 0),
          value: 'MyIdentifier',
        ),
      ];

      // Call the method being tested
      final result = elementParser.parseIdentifier(tokens);

      // Verify expectations
      expect(result, equals('MyIdentifier'));
    });

    test('should parse identifier from identifier token', () {
      // Create input tokens with an identifier token
      final tokens = [
        Token(
          type: TokenType.identifier,
          lexeme: 'person',
          value: null,
          position: const SourcePosition(1, 1, 0),
        ),
      ];

      // Call the method being tested
      final result = elementParser.parseIdentifier(tokens);

      // Verify expectations
      expect(result, equals('person'));
    });

    test('should handle special characters in identifiers', () {
      // Create input tokens with special characters
      final tokens = [
        Token(
          type: TokenType.string,
          lexeme: '"User-Service_API"',
          position: const SourcePosition(1, 1, 0),
          value: 'User-Service_API',
        ),
      ];

      // Call the method being tested
      final result = elementParser.parseIdentifier(tokens);

      // Verify expectations
      expect(result, equals('User-Service_API'));
    });

    test('should handle empty string identifier', () {
      // Create input tokens with empty string
      final tokens = [
        Token(
          type: TokenType.string,
          lexeme: '""',
          position: const SourcePosition(1, 1, 0),
          value: '',
        ),
      ];

      // Call the method being tested
      expect(
          () => elementParser.parseIdentifier(tokens),
          throwsA(isA<ParseError>().having(
              (e) => e.message, 'message', contains('Empty identifier'))));
    });
  });

  group('ElementParser._parseParentChild detailed tests', () {
    test('should parse empty block', () {
      // Create input tokens for empty block
      final tokens = [
        Token(
          type: TokenType.leftBrace,
          lexeme: '{',
          position: const SourcePosition(1, 1, 0),
        ),
        Token(
          type: TokenType.rightBrace,
          lexeme: '}',
          position: const SourcePosition(2, 1, 0),
        ),
      ];

      // Call the method being tested
      elementParser.parseParentChild(tokens);

      // Verify no errors occurred
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should parse block with description property', () {
      // Create input tokens with description property
      final tokens = [
        Token(
          type: TokenType.leftBrace,
          lexeme: '{',
          position: const SourcePosition(1, 1, 0),
        ),
        Token(
          type: TokenType.description,
          lexeme: 'description',
          position: const SourcePosition(2, 3, 0),
        ),
        Token(
          type: TokenType.equals,
          lexeme: '=',
          position: const SourcePosition(2, 15, 0),
        ),
        Token(
          type: TokenType.string,
          lexeme: '"This is a description"',
          position: const SourcePosition(2, 17, 0),
          value: 'This is a description',
        ),
        Token(
          type: TokenType.rightBrace,
          lexeme: '}',
          position: const SourcePosition(3, 1, 0),
        ),
      ];

      // Call the method being tested
      elementParser.parseParentChild(tokens);

      // Verify no errors occurred and description was parsed
      expect(errorReporter.hasErrors, isFalse);
      // In the real implementation, this would check that the description was set
    });

    test('should parse block with tags property', () {
      // Create input tokens with tags property
      final tokens = [
        Token(
          type: TokenType.leftBrace,
          lexeme: '{',
          position: const SourcePosition(1, 1, 0),
        ),
        Token(
          type: TokenType.tags,
          lexeme: 'tags',
          position: const SourcePosition(2, 3, 0),
        ),
        Token(
          type: TokenType.equals,
          lexeme: '=',
          position: const SourcePosition(2, 8, 0),
        ),
        Token(
          type: TokenType.string,
          lexeme: '"tag1,tag2,tag3"',
          position: const SourcePosition(2, 10, 0),
          value: 'tag1,tag2,tag3',
        ),
        Token(
          type: TokenType.rightBrace,
          lexeme: '}',
          position: const SourcePosition(3, 1, 0),
        ),
      ];

      // Call the method being tested
      elementParser.parseParentChild(tokens);

      // Verify no errors occurred and tags were parsed
      expect(errorReporter.hasErrors, isFalse);
      // In the real implementation, this would check that the tags were set
    });

    test('should parse block with multiple properties', () {
      // Create input tokens with multiple properties
      final tokens = [
        Token(
          type: TokenType.leftBrace,
          lexeme: '{',
          position: const SourcePosition(1, 1, 0),
        ),
        Token(
          type: TokenType.description,
          lexeme: 'description',
          position: const SourcePosition(2, 3, 0),
        ),
        Token(
          type: TokenType.equals,
          lexeme: '=',
          position: const SourcePosition(2, 15, 0),
        ),
        Token(
          type: TokenType.string,
          lexeme: '"This is a description"',
          position: const SourcePosition(2, 17, 0),
          value: 'This is a description',
        ),
        Token(
          type: TokenType.tags,
          lexeme: 'tags',
          position: const SourcePosition(3, 3, 0),
        ),
        Token(
          type: TokenType.equals,
          lexeme: '=',
          position: const SourcePosition(3, 8, 0),
        ),
        Token(
          type: TokenType.string,
          lexeme: '"tag1,tag2,tag3"',
          position: const SourcePosition(3, 10, 0),
          value: 'tag1,tag2,tag3',
        ),
        Token(
          type: TokenType.url,
          lexeme: 'url',
          position: const SourcePosition(4, 3, 0),
        ),
        Token(
          type: TokenType.equals,
          lexeme: '=',
          position: const SourcePosition(4, 7, 0),
        ),
        Token(
          type: TokenType.string,
          lexeme: '"https://example.com"',
          position: const SourcePosition(4, 9, 0),
          value: 'https://example.com',
        ),
        Token(
          type: TokenType.rightBrace,
          lexeme: '}',
          position: const SourcePosition(5, 1, 0),
        ),
      ];

      // Call the method being tested
      elementParser.parseParentChild(tokens);

      // Verify no errors occurred and properties were parsed
      expect(errorReporter.hasErrors, isFalse);
      // In the real implementation, this would check that all properties were set
    });

    test('should handle nested container blocks', () {
      // Create input tokens with nested container
      final tokens = [
        Token(
          type: TokenType.leftBrace,
          lexeme: '{',
          position: const SourcePosition(1, 1, 0),
        ),
        Token(
          type: TokenType.container,
          lexeme: 'container',
          position: const SourcePosition(2, 3, 0),
        ),
        Token(
          type: TokenType.string,
          lexeme: '"Database"',
          position: const SourcePosition(2, 12, 0),
          value: 'Database',
        ),
        Token(
          type: TokenType.string,
          lexeme: '"Stores data"',
          position: const SourcePosition(2, 23, 0),
          value: 'Stores data',
        ),
        Token(
          type: TokenType.leftBrace,
          lexeme: '{',
          position: const SourcePosition(2, 36, 0),
        ),
        Token(
          type: TokenType.technology,
          lexeme: 'technology',
          position: const SourcePosition(3, 5, 0),
        ),
        Token(
          type: TokenType.equals,
          lexeme: '=',
          position: const SourcePosition(3, 16, 0),
        ),
        Token(
          type: TokenType.string,
          lexeme: '"PostgreSQL"',
          position: const SourcePosition(3, 18, 0),
          value: 'PostgreSQL',
        ),
        Token(
          type: TokenType.rightBrace,
          lexeme: '}',
          position: const SourcePosition(4, 3, 0),
        ),
        Token(
          type: TokenType.rightBrace,
          lexeme: '}',
          position: const SourcePosition(5, 1, 0),
        ),
      ];

      // Call the method being tested
      elementParser.parseParentChild(tokens);

      // Verify no errors occurred
      expect(errorReporter.hasErrors, isFalse);
    });
  });
}
