import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/parser/lexer/token.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/parser/ast/ast_nodes.dart';
import 'package:flutter_structurizr/domain/parser/context_stack.dart';
import 'package:flutter_structurizr/domain/parser/element_parser.dart';

void main() {
  late ElementParser elementParser;
  late ErrorReporter errorReporter;
  late ContextStack contextStack;

  setUp(() {
    errorReporter = ErrorReporter('');
    contextStack = ContextStack();
    elementParser = ElementParser(errorReporter, contextStack: contextStack);
  });

  group('ElementParser._parseIdentifier', () {
    test('should parse valid identifier', () {
      // Create input tokens
      final tokens = [
        Token(
          type: TokenType.identifier,
          lexeme: 'myIdentifier',
          position: SourcePosition(line: 1, column: 1, offset: 0),
        ),
      ];
      
      // Call the method being tested
      final result = elementParser._parseIdentifier(tokens);
      
      // Verify expectations
      expect(result, equals('myIdentifier'));
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should parse string as identifier', () {
      // Create input tokens
      final tokens = [
        Token(
          type: TokenType.string,
          lexeme: '"myStringIdentifier"',
          position: SourcePosition(line: 1, column: 1, offset: 0),
          value: 'myStringIdentifier',
        ),
      ];
      
      // Call the method being tested
      final result = elementParser._parseIdentifier(tokens);
      
      // Verify expectations
      expect(result, equals('myStringIdentifier'));
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should handle missing identifier', () {
      // Create input tokens with no identifier
      final tokens = <Token>[];
      
      // Call the method being tested
      expect(() => elementParser._parseIdentifier(tokens), 
        throwsA(isA<ParseError>().having(
          (e) => e.message, 
          'message', 
          contains('Expected identifier')
        ))
      );
    });

    test('should handle invalid token type', () {
      // Create input tokens with wrong type
      final tokens = [
        Token(
          type: TokenType.leftBrace,
          lexeme: '{',
          position: SourcePosition(line: 1, column: 1, offset: 0),
        ),
      ];
      
      // Call the method being tested
      expect(() => elementParser._parseIdentifier(tokens), 
        throwsA(isA<ParseError>().having(
          (e) => e.message, 
          'message', 
          contains('Expected identifier or string')
        ))
      );
    });
  });

  group('ElementParser._parseParentChild', () {
    test('should handle valid property assignment', () {
      // Create a mock element to receive properties
      final mockElement = PersonNode(id: 'test', name: 'Test Person');
      
      // Set up the context with the mock element
      contextStack.push(Context('person', data: {'currentElement': mockElement}));
      
      // Create input tokens for a property assignment
      final tokens = [
        Token(
          type: TokenType.identifier,
          lexeme: 'description',
          position: SourcePosition(line: 1, column: 1, offset: 0),
        ),
        Token(
          type: TokenType.equals,
          lexeme: '=',
          position: SourcePosition(line: 1, column: 12, offset: 11),
        ),
        Token(
          type: TokenType.string,
          lexeme: '"A test person"',
          position: SourcePosition(line: 1, column: 14, offset: 13),
          value: 'A test person',
        ),
      ];
      
      // Call the method being tested
      elementParser._parseParentChild(tokens);
      
      // Verify the property was set on the mock element
      expect(mockElement.description, equals('A test person'));
      expect(errorReporter.hasErrors, isFalse);
      
      // Cleanup
      contextStack.pop();
    });

    test('should handle missing tokens gracefully', () {
      // Create input tokens with no content
      final tokens = <Token>[];
      
      // Call the method being tested
      expect(() => elementParser._parseParentChild(tokens), 
        throwsA(isA<ParseError>().having(
          (e) => e.message, 
          'message', 
          contains('No tokens provided')
        ))
      );
    });

    test('should handle property assignment with missing current element', () {
      // Create a context without a current element
      contextStack.push(Context('person'));
      
      // Create input tokens for a property assignment
      final tokens = [
        Token(
          type: TokenType.identifier,
          lexeme: 'description',
          position: SourcePosition(line: 1, column: 1, offset: 0),
        ),
        Token(
          type: TokenType.equals,
          lexeme: '=',
          position: SourcePosition(line: 1, column: 12, offset: 11),
        ),
        Token(
          type: TokenType.string,
          lexeme: '"A test person"',
          position: SourcePosition(line: 1, column: 14, offset: 13),
          value: 'A test person',
        ),
      ];
      
      // Call the method being tested
      expect(() => elementParser._parseParentChild(tokens), 
        throwsA(isA<ParseError>().having(
          (e) => e.message, 
          'message', 
          contains('No current element')
        ))
      );
      
      // Cleanup
      contextStack.pop();
    });
  });

  group('ElementParser.parsePerson', () {
    test('should parse person with name only', () {
      // Simulate a DSL input like: person "User"
      final tokens = [
        Token(
          type: TokenType.person,
          lexeme: 'person',
          position: SourcePosition(line: 1, column: 1, offset: 0),
        ),
        Token(
          type: TokenType.string,
          lexeme: '"User"',
          position: SourcePosition(line: 1, column: 8, offset: 7),
          value: 'User',
        ),
      ];
      
      // Call the method being tested
      final result = elementParser.parsePerson(tokens);
      
      // Verify the result
      expect(result, isA<PersonNode>());
      expect(result.name, equals('User'));
      expect(result.description, isNull);
      expect(result.tags, isNull);
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should parse person with name and description', () {
      // Simulate a DSL input like: person "User" "A standard user"
      final tokens = [
        Token(
          type: TokenType.person,
          lexeme: 'person',
          position: SourcePosition(line: 1, column: 1, offset: 0),
        ),
        Token(
          type: TokenType.string,
          lexeme: '"User"',
          position: SourcePosition(line: 1, column: 8, offset: 7),
          value: 'User',
        ),
        Token(
          type: TokenType.string,
          lexeme: '"A standard user"',
          position: SourcePosition(line: 1, column: 15, offset: 14),
          value: 'A standard user',
        ),
      ];
      
      // Call the method being tested
      final result = elementParser.parsePerson(tokens);
      
      // Verify the result
      expect(result, isA<PersonNode>());
      expect(result.name, equals('User'));
      expect(result.description, equals('A standard user'));
      expect(result.tags, isNull);
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should parse person with all attributes', () {
      // Simulate a DSL input like: person "User" "A standard user" "external,user"
      final tokens = [
        Token(
          type: TokenType.person,
          lexeme: 'person',
          position: SourcePosition(line: 1, column: 1, offset: 0),
        ),
        Token(
          type: TokenType.string,
          lexeme: '"User"',
          position: SourcePosition(line: 1, column: 8, offset: 7),
          value: 'User',
        ),
        Token(
          type: TokenType.string,
          lexeme: '"A standard user"',
          position: SourcePosition(line: 1, column: 15, offset: 14),
          value: 'A standard user',
        ),
        Token(
          type: TokenType.string,
          lexeme: '"external,user"',
          position: SourcePosition(line: 1, column: 32, offset: 31),
          value: 'external,user',
        ),
      ];
      
      // Call the method being tested
      final result = elementParser.parsePerson(tokens);
      
      // Verify the result
      expect(result, isA<PersonNode>());
      expect(result.name, equals('User'));
      expect(result.description, equals('A standard user'));
      expect(result.properties?['tags'], equals('external,user'));
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should handle missing person name', () {
      // Simulate a DSL input with missing name: person 
      final tokens = [
        Token(
          type: TokenType.person,
          lexeme: 'person',
          position: SourcePosition(line: 1, column: 1, offset: 0),
        ),
      ];
      
      // Call the method being tested
      expect(() => elementParser.parsePerson(tokens), 
        throwsA(isA<ParseError>().having(
          (e) => e.message, 
          'message', 
          contains('Expected person name')
        ))
      );
    });

    test('should parse person with block content', () {
      // Simulate a DSL input like: person "User" { description = "A standard user" }
      final tokens = [
        Token(
          type: TokenType.person,
          lexeme: 'person',
          position: SourcePosition(line: 1, column: 1, offset: 0),
        ),
        Token(
          type: TokenType.string,
          lexeme: '"User"',
          position: SourcePosition(line: 1, column: 8, offset: 7),
          value: 'User',
        ),
        Token(
          type: TokenType.leftBrace,
          lexeme: '{',
          position: SourcePosition(line: 1, column: 15, offset: 14),
        ),
        Token(
          type: TokenType.identifier,
          lexeme: 'description',
          position: SourcePosition(line: 2, column: 3, offset: 18),
        ),
        Token(
          type: TokenType.equals,
          lexeme: '=',
          position: SourcePosition(line: 2, column: 15, offset: 30),
        ),
        Token(
          type: TokenType.string,
          lexeme: '"A standard user"',
          position: SourcePosition(line: 2, column: 17, offset: 32),
          value: 'A standard user',
        ),
        Token(
          type: TokenType.rightBrace,
          lexeme: '}',
          position: SourcePosition(line: 3, column: 1, offset: 49),
        ),
      ];
      
      // Create a mock element to receive properties
      final mockElement = PersonNode(id: 'User', name: 'User');
      
      // Mock the context stack behavior for this test
      contextStack.push = (Context context) {
        // When pushing a person context, immediately add the mockElement
        if (context.name == 'person') {
          final updatedContext = Context(context.name, data: {'currentElement': mockElement});
          contextStack._stack.add(updatedContext);
        } else {
          contextStack._stack.add(context);
        }
      };
      
      // Call the method being tested
      final result = elementParser.parsePerson(tokens);
      
      // Verify the result
      expect(result, isA<PersonNode>());
      expect(result.name, equals('User'));
      expect(mockElement.properties?['description'], equals('A standard user'));
      expect(errorReporter.hasErrors, isFalse);
    });
  });

  group('ElementParser.parseSoftwareSystem', () {
    test('should parse software system with name only', () {
      // Simulate a DSL input like: softwareSystem "PaymentSystem"
      final tokens = [
        Token(
          type: TokenType.softwareSystem,
          lexeme: 'softwareSystem',
          position: SourcePosition(line: 1, column: 1, offset: 0),
        ),
        Token(
          type: TokenType.string,
          lexeme: '"PaymentSystem"',
          position: SourcePosition(line: 1, column: 15, offset: 14),
          value: 'PaymentSystem',
        ),
      ];
      
      // Call the method being tested
      final result = elementParser.parseSoftwareSystem(tokens);
      
      // Verify the result
      expect(result, isA<SoftwareSystemNode>());
      expect(result.name, equals('PaymentSystem'));
      expect(result.description, isNull);
      expect(result.tags, isNull);
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should parse software system with name and description', () {
      // Simulate a DSL input like: softwareSystem "PaymentSystem" "Handles all payments"
      final tokens = [
        Token(
          type: TokenType.softwareSystem,
          lexeme: 'softwareSystem',
          position: SourcePosition(line: 1, column: 1, offset: 0),
        ),
        Token(
          type: TokenType.string,
          lexeme: '"PaymentSystem"',
          position: SourcePosition(line: 1, column: 15, offset: 14),
          value: 'PaymentSystem',
        ),
        Token(
          type: TokenType.string,
          lexeme: '"Handles all payments"',
          position: SourcePosition(line: 1, column: 31, offset: 30),
          value: 'Handles all payments',
        ),
      ];
      
      // Call the method being tested
      final result = elementParser.parseSoftwareSystem(tokens);
      
      // Verify the result
      expect(result, isA<SoftwareSystemNode>());
      expect(result.name, equals('PaymentSystem'));
      expect(result.description, equals('Handles all payments'));
      expect(result.tags, isNull);
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should parse software system with all attributes', () {
      // Simulate a DSL input like: softwareSystem "PaymentSystem" "Handles all payments" "external,payments"
      final tokens = [
        Token(
          type: TokenType.softwareSystem,
          lexeme: 'softwareSystem',
          position: SourcePosition(line: 1, column: 1, offset: 0),
        ),
        Token(
          type: TokenType.string,
          lexeme: '"PaymentSystem"',
          position: SourcePosition(line: 1, column: 15, offset: 14),
          value: 'PaymentSystem',
        ),
        Token(
          type: TokenType.string,
          lexeme: '"Handles all payments"',
          position: SourcePosition(line: 1, column: 31, offset: 30),
          value: 'Handles all payments',
        ),
        Token(
          type: TokenType.string,
          lexeme: '"external,payments"',
          position: SourcePosition(line: 1, column: 53, offset: 52),
          value: 'external,payments',
        ),
      ];
      
      // Call the method being tested
      final result = elementParser.parseSoftwareSystem(tokens);
      
      // Verify the result
      expect(result, isA<SoftwareSystemNode>());
      expect(result.name, equals('PaymentSystem'));
      expect(result.description, equals('Handles all payments'));
      expect(result.properties?['tags'], equals('external,payments'));
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should handle missing software system name', () {
      // Simulate a DSL input with missing name: softwareSystem 
      final tokens = [
        Token(
          type: TokenType.softwareSystem,
          lexeme: 'softwareSystem',
          position: SourcePosition(line: 1, column: 1, offset: 0),
        ),
      ];
      
      // Call the method being tested
      expect(() => elementParser.parseSoftwareSystem(tokens), 
        throwsA(isA<ParseError>().having(
          (e) => e.message, 
          'message', 
          contains('Expected software system name')
        ))
      );
    });

    test('should parse software system with block content', () {
      // Simulate a DSL input like: softwareSystem "PaymentSystem" { description = "Handles all payments" }
      final tokens = [
        Token(
          type: TokenType.softwareSystem,
          lexeme: 'softwareSystem',
          position: SourcePosition(line: 1, column: 1, offset: 0),
        ),
        Token(
          type: TokenType.string,
          lexeme: '"PaymentSystem"',
          position: SourcePosition(line: 1, column: 15, offset: 14),
          value: 'PaymentSystem',
        ),
        Token(
          type: TokenType.leftBrace,
          lexeme: '{',
          position: SourcePosition(line: 1, column: 30, offset: 29),
        ),
        Token(
          type: TokenType.identifier,
          lexeme: 'description',
          position: SourcePosition(line: 2, column: 3, offset: 33),
        ),
        Token(
          type: TokenType.equals,
          lexeme: '=',
          position: SourcePosition(line: 2, column: 15, offset: 45),
        ),
        Token(
          type: TokenType.string,
          lexeme: '"Handles all payments"',
          position: SourcePosition(line: 2, column: 17, offset: 47),
          value: 'Handles all payments',
        ),
        Token(
          type: TokenType.rightBrace,
          lexeme: '}',
          position: SourcePosition(line: 3, column: 1, offset: 69),
        ),
      ];
      
      // Create a mock element to receive properties
      final mockElement = SoftwareSystemNode(id: 'PaymentSystem', name: 'PaymentSystem');
      
      // Mock the context stack behavior for this test
      contextStack.push = (Context context) {
        // When pushing a softwareSystem context, immediately add the mockElement
        if (context.name == 'softwareSystem') {
          final updatedContext = Context(context.name, data: {'currentElement': mockElement});
          contextStack._stack.add(updatedContext);
        } else {
          contextStack._stack.add(context);
        }
      };
      
      // Call the method being tested
      final result = elementParser.parseSoftwareSystem(tokens);
      
      // Verify the result
      expect(result, isA<SoftwareSystemNode>());
      expect(result.name, equals('PaymentSystem'));
      expect(mockElement.properties?['description'], equals('Handles all payments'));
      expect(errorReporter.hasErrors, isFalse);
    });
  });
}