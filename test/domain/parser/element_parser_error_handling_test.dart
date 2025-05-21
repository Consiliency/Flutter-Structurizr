// Refactored for exception-based error handling and current parser API.
import 'package:test/test.dart';
import 'package:flutter_structurizr/domain/parser/lexer/token.dart';
import 'package:flutter_structurizr/domain/parser/lexer/lexer.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/model_element_node.dart';
import 'package:flutter_structurizr/domain/parser/context_stack.dart';
import 'package:flutter_structurizr/domain/parser/element_parser.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart' show ParseError;
import 'package:flutter_structurizr/domain/parser/model_parser.dart';

// Add a ModelParserStub for tests that require a modelParser
class ModelParserStub implements ModelParser {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw ParseError('ModelParserStub called', null);
}

// Add a FakeModelParser for tests that require successful nested parsing
class FakeModelParser implements ModelParser {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  @override
  ModelElementNode? parseNestedElement(List<Token> tokens) {
    // Return a dummy ContainerNode or ComponentNode based on tokens
    final typeToken = tokens.isNotEmpty ? tokens[0] : null;
    final nameToken = tokens.length > 1 ? tokens[1] : null;
    final name = nameToken != null ? (nameToken.value as String? ?? nameToken.lexeme.replaceAll('"', '')) : 'Dummy';
    if (typeToken != null && (typeToken.lexeme == 'container' || typeToken.type.toString().contains('container'))) {
      return ContainerNode(id: name, parentId: '', name: name);
    } else if (typeToken != null && (typeToken.lexeme == 'component' || typeToken.type.toString().contains('component'))) {
      return ComponentNode(id: name, parentId: '', name: name);
    }
    return null;
  }
}

void main() {
  late ElementParser elementParser;
  late ContextStack contextStack;
  late Lexer lexer;

  setUp(() {
    contextStack = ContextStack();
    // Use ModelParserStub for tests that require nested parsing
    elementParser = ElementParser(contextStack: contextStack, modelParser: ModelParserStub());
    lexer = Lexer('');
  });

  group('ElementParser error handling tests', () {
    test('should handle empty tokens list', () {
      final List<Token> tokens = <Token>[];
      expect(() => elementParser.parsePerson(tokens), throwsA(isA<ParseError>()));
      expect(() => elementParser.parseSoftwareSystem(tokens), throwsA(isA<ParseError>()));
    });

    test('should throw for incorrect token type for person', () {
      final List<Token> tokens = [
        Token(type: TokenType.softwareSystem, lexeme: 'softwareSystem', position: const SourcePosition(1, 1)),
        Token(type: TokenType.string, lexeme: '"User"', value: 'User', position: const SourcePosition(1, 15)),
      ];
      expect(() => elementParser.parsePerson(tokens), throwsA(isA<ParseError>()));
    });

    test('should throw for incorrect token type for software system', () {
      final List<Token> tokens = [
        Token(type: TokenType.person, lexeme: 'person', position: const SourcePosition(1, 1)),
        Token(type: TokenType.string, lexeme: '"PaymentSystem"', value: 'PaymentSystem', position: const SourcePosition(1, 8)),
      ];
      expect(() => elementParser.parseSoftwareSystem(tokens), throwsA(isA<ParseError>()));
    });

    test('should handle missing person name', () {
      final List<Token> tokens = [
        Token(type: TokenType.person, lexeme: 'person', position: const SourcePosition(1, 1)),
      ];
      expect(() => elementParser.parsePerson(tokens), throwsA(isA<ParseError>()));
    });

    test('should handle missing software system name', () {
      final List<Token> tokens = [
        Token(type: TokenType.softwareSystem, lexeme: 'softwareSystem', position: const SourcePosition(1, 1)),
      ];
      expect(() => elementParser.parseSoftwareSystem(tokens), throwsA(isA<ParseError>()));
    });

    test('should handle unmatched braces in person', () {
      final List<Token> tokens = [
        Token(type: TokenType.person, lexeme: 'person', position: const SourcePosition(1, 1)),
        Token(type: TokenType.string, lexeme: '"Administrator"', value: 'Administrator', position: const SourcePosition(1, 8)),
        Token(type: TokenType.leftBrace, lexeme: '{', position: const SourcePosition(1, 24)),
        Token(type: TokenType.identifier, lexeme: 'description', position: const SourcePosition(2, 3)),
        Token(type: TokenType.equals, lexeme: '=', position: const SourcePosition(2, 15)),
        Token(type: TokenType.string, lexeme: '"System administrator"', value: 'System administrator', position: const SourcePosition(2, 17)),
      ];
      expect(() => elementParser.parsePerson(tokens), throwsA(isA<ParseError>()));
    });

    test('should handle unmatched braces in software system', () {
      final List<Token> tokens = [
        Token(type: TokenType.softwareSystem, lexeme: 'softwareSystem', position: const SourcePosition(1, 1)),
        Token(type: TokenType.string, lexeme: '"Authentication Service"', value: 'Authentication Service', position: const SourcePosition(1, 17)),
        Token(type: TokenType.leftBrace, lexeme: '{', position: const SourcePosition(1, 43)),
        Token(type: TokenType.identifier, lexeme: 'description', position: const SourcePosition(2, 3)),
        Token(type: TokenType.equals, lexeme: '=', position: const SourcePosition(2, 15)),
        Token(type: TokenType.string, lexeme: '"Handles user authentication"', value: 'Handles user authentication', position: const SourcePosition(2, 17)),
      ];
      expect(() => elementParser.parseSoftwareSystem(tokens), throwsA(isA<ParseError>()));
    });

    test('should handle extremely long names', () {
      final veryLongName = 'A' * 10000;
      final List<Token> tokens = [
        Token(type: TokenType.person, lexeme: 'person', position: const SourcePosition(1, 1)),
        Token(type: TokenType.string, lexeme: '"$veryLongName"', value: veryLongName, position: const SourcePosition(1, 8)),
      ];
      final result = elementParser.parsePerson(tokens);
      expect(result, isA<PersonNode>());
      expect(result.name, equals(veryLongName));
      expect(result.id.length, equals(veryLongName.length));
    });

    test('should handle multiple model parsing errors in sequence', () {
      final List<Token> tokensWithError = [
        Token(type: TokenType.person, lexeme: 'person', position: const SourcePosition(1, 1)),
        Token(type: TokenType.string, lexeme: '"User"', value: 'User', position: const SourcePosition(1, 8)),
        Token(type: TokenType.leftBrace, lexeme: '{', position: const SourcePosition(1, 14)),
      ];
      expect(() => elementParser.parsePerson(tokensWithError), throwsA(isA<ParseError>()));
      final List<Token> validTokens = [
        Token(type: TokenType.person, lexeme: 'person', position: const SourcePosition(1, 1)),
        Token(type: TokenType.string, lexeme: '"User"', value: 'User', position: const SourcePosition(1, 8)),
      ];
      final result = elementParser.parsePerson(validTokens);
      expect(result, isA<PersonNode>());
      expect(result.name, equals('User'));
    });

    test('should handle nested parsing errors', () {
      final List<Token> tokens = [
        Token(type: TokenType.softwareSystem, lexeme: 'softwareSystem', position: const SourcePosition(1, 1)),
        Token(type: TokenType.string, lexeme: '"System"', value: 'System', position: const SourcePosition(1, 17)),
        Token(type: TokenType.leftBrace, lexeme: '{', position: const SourcePosition(1, 25)),
        Token(type: TokenType.identifier, lexeme: 'description', position: const SourcePosition(2, 3)),
        Token(type: TokenType.equals, lexeme: '=', position: const SourcePosition(2, 15)),
        Token(type: TokenType.string, lexeme: '"Valid description"', value: 'Valid description', position: const SourcePosition(2, 17)),
        Token(type: TokenType.identifier, lexeme: 'container', position: const SourcePosition(3, 3)),
        Token(type: TokenType.string, lexeme: '"Frontend"', value: 'Frontend', position: const SourcePosition(3, 13)),
        Token(type: TokenType.leftBrace, lexeme: '{', position: const SourcePosition(3, 23)),
        Token(type: TokenType.identifier, lexeme: 'description', position: const SourcePosition(4, 5)),
        Token(type: TokenType.equals, lexeme: '=', position: const SourcePosition(4, 17)),
        Token(type: TokenType.string, lexeme: '"Missing closing brace for container"', value: 'Missing closing brace for container', position: const SourcePosition(4, 19)),
      ];
      expect(() => elementParser.parseSoftwareSystem(tokens), throwsA(isA<ParseError>()));
      expect(contextStack.isEmpty(), isTrue);
    });

    test('should handle overlapping braces in block structure', () {
      final List<Token> tokens = [
        Token(type: TokenType.softwareSystem, lexeme: 'softwareSystem', position: const SourcePosition(1, 1)),
        Token(type: TokenType.string, lexeme: '"System"', value: 'System', position: const SourcePosition(1, 17)),
        Token(type: TokenType.leftBrace, lexeme: '{', position: const SourcePosition(1, 25)),
        Token(type: TokenType.identifier, lexeme: 'container', position: const SourcePosition(2, 3)),
        Token(type: TokenType.string, lexeme: '"Container1"', value: 'Container1', position: const SourcePosition(2, 13)),
        Token(type: TokenType.leftBrace, lexeme: '{', position: const SourcePosition(2, 25)),
        Token(type: TokenType.identifier, lexeme: 'description', position: const SourcePosition(3, 5)),
        Token(type: TokenType.equals, lexeme: '=', position: const SourcePosition(3, 17)),
        Token(type: TokenType.string, lexeme: '"Description"', value: 'Description', position: const SourcePosition(3, 19)),
        Token(type: TokenType.rightBrace, lexeme: '}', position: const SourcePosition(4, 3)),
        Token(type: TokenType.identifier, lexeme: 'container', position: const SourcePosition(5, 3)),
        Token(type: TokenType.string, lexeme: '"Container2"', value: 'Container2', position: const SourcePosition(5, 13)),
        Token(type: TokenType.leftBrace, lexeme: '{', position: const SourcePosition(5, 25)),
        Token(type: TokenType.identifier, lexeme: 'description', position: const SourcePosition(6, 5)),
        Token(type: TokenType.equals, lexeme: '=', position: const SourcePosition(6, 17)),
        Token(type: TokenType.string, lexeme: '"Description"', value: 'Description', position: const SourcePosition(6, 19)),
        Token(type: TokenType.rightBrace, lexeme: '}', position: const SourcePosition(7, 3)),
        Token(type: TokenType.rightBrace, lexeme: '}', position: const SourcePosition(8, 1)),
      ];
      // Use FakeModelParser for this test
      final parser = ElementParser(contextStack: contextStack, modelParser: FakeModelParser());
      final result = parser.parseSoftwareSystem(tokens);
      expect(result, isA<SoftwareSystemNode>());
      expect(result.name, equals('System'));
    });

    test('should handle reserved keywords as identifiers', () {
      final List<Token> tokens = [
        Token(type: TokenType.person, lexeme: 'person', position: const SourcePosition(1, 1)),
        Token(type: TokenType.string, lexeme: '"model"', value: 'model', position: const SourcePosition(1, 8)),
        Token(type: TokenType.string, lexeme: '"A person with a reserved keyword name"', value: 'A person with a reserved keyword name', position: const SourcePosition(1, 16)),
      ];
      final result = elementParser.parsePerson(tokens);
      expect(result, isA<PersonNode>());
      expect(result.name, equals('model'));
      expect(result.id, equals('model'));
    });

    test('should handle special characters in property values', () {
      final List<Token> tokens = [
        Token(type: TokenType.person, lexeme: 'person', position: const SourcePosition(1, 1)),
        Token(type: TokenType.string, lexeme: '"Admin"', value: 'Admin', position: const SourcePosition(1, 8)),
        Token(type: TokenType.leftBrace, lexeme: '{', position: const SourcePosition(1, 15)),
        Token(type: TokenType.identifier, lexeme: 'description', position: const SourcePosition(2, 3)),
        Token(type: TokenType.equals, lexeme: '=', position: const SourcePosition(2, 15)),
        Token(type: TokenType.string, lexeme: '"Person with special chars: <>&\"\'[]{}%\$#@!~`"', value: 'Person with special chars: <>&"\'[]{}%\$#@!~`', position: const SourcePosition(2, 17)),
        Token(type: TokenType.rightBrace, lexeme: '}', position: const SourcePosition(3, 1)),
      ];
      final result = elementParser.parsePerson(tokens);
      expect(result, isA<PersonNode>());
      expect(result.name, equals('Admin'));
    });
  });

  group('ElementParser state consistency tests', () {
    test('should maintain parser state across multiple parse calls', () {
      final List<Token> personTokens = [
        Token(type: TokenType.person, lexeme: 'person', position: const SourcePosition(1, 1)),
        Token(type: TokenType.string, lexeme: '"User"', value: 'User', position: const SourcePosition(1, 8)),
        Token(type: TokenType.string, lexeme: '"A user"', value: 'A user', position: const SourcePosition(1, 15)),
      ];
      final person = elementParser.parsePerson(personTokens);
      expect(person, isA<PersonNode>());
      expect(person.name, equals('User'));
      final List<Token> systemTokens = [
        Token(type: TokenType.softwareSystem, lexeme: 'softwareSystem', position: const SourcePosition(2, 1)),
        Token(type: TokenType.string, lexeme: '"System"', value: 'System', position: const SourcePosition(2, 8)),
        Token(type: TokenType.string, lexeme: '"A system"', value: 'A system', position: const SourcePosition(2, 15)),
      ];
      final system = elementParser.parseSoftwareSystem(systemTokens);
      expect(system, isA<SoftwareSystemNode>());
      expect(system.name, equals('System'));
    });

    test('should handle parse errors without corrupting parser state', () {
      final List<Token> invalidTokens = [
        Token(type: TokenType.person, lexeme: 'person', position: const SourcePosition(1, 1)),
        Token(type: TokenType.leftBrace, lexeme: '{', position: const SourcePosition(1, 8)),
      ];
      expect(() => elementParser.parsePerson(invalidTokens), throwsA(isA<ParseError>()));
      final List<Token> validTokens = [
        Token(type: TokenType.person, lexeme: 'person', position: const SourcePosition(2, 1)),
        Token(type: TokenType.string, lexeme: '"User"', value: 'User', position: const SourcePosition(2, 8)),
      ];
      final result = elementParser.parsePerson(validTokens);
      expect(result, isA<PersonNode>());
      expect(result.name, equals('User'));
    });

    test('should reset context stack properly after parsing', () {
      final List<Token> tokens = [
        Token(type: TokenType.person, lexeme: 'person', position: const SourcePosition(1, 1)),
        Token(type: TokenType.string, lexeme: '"User"', value: 'User', position: const SourcePosition(1, 8)),
      ];
      final initialDepth = contextStack.size();
      elementParser.parsePerson(tokens);
      expect(contextStack.size(), equals(initialDepth));
    });

    test('should handle re-entrant parsing', () {
      final List<Token> tokens = [
        Token(type: TokenType.softwareSystem, lexeme: 'softwareSystem', position: const SourcePosition(1, 1)),
        Token(type: TokenType.string, lexeme: '"Nested"', value: 'Nested', position: const SourcePosition(1, 17)),
        Token(type: TokenType.leftBrace, lexeme: '{', position: const SourcePosition(1, 25)),
        Token(type: TokenType.identifier, lexeme: 'container', position: const SourcePosition(2, 3)),
        Token(type: TokenType.string, lexeme: '"Inner"', value: 'Inner', position: const SourcePosition(2, 13)),
        Token(type: TokenType.leftBrace, lexeme: '{', position: const SourcePosition(2, 20)),
        Token(type: TokenType.identifier, lexeme: 'description', position: const SourcePosition(3, 5)),
        Token(type: TokenType.equals, lexeme: '=', position: const SourcePosition(3, 17)),
        Token(type: TokenType.string, lexeme: '"Inner description"', value: 'Inner description', position: const SourcePosition(3, 19)),
        Token(type: TokenType.rightBrace, lexeme: '}', position: const SourcePosition(4, 3)),
        Token(type: TokenType.rightBrace, lexeme: '}', position: const SourcePosition(5, 1)),
      ];
      // Use FakeModelParser for this test
      final parser = ElementParser(contextStack: contextStack, modelParser: FakeModelParser());
      final initialDepth = contextStack.size();
      final result1 = parser.parseSoftwareSystem(tokens);
      expect(result1, isA<SoftwareSystemNode>());
      expect(contextStack.size(), equals(initialDepth));
      final result2 = parser.parseSoftwareSystem(tokens);
      expect(result2, isA<SoftwareSystemNode>());
      expect(contextStack.size(), equals(initialDepth));
    });
  });
}