import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/parser/lexer/token.dart';
import 'package:flutter_structurizr/domain/parser/lexer/lexer.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/parser/ast/ast_nodes.dart';
import 'package:flutter_structurizr/domain/parser/context_stack.dart';
import 'package:flutter_structurizr/domain/parser/element_parser.dart';

void main() {
  late ElementParser elementParser;
  late ErrorReporter errorReporter;
  late ContextStack contextStack;
  late Lexer lexer;

  setUp(() {
    errorReporter = ErrorReporter();
    contextStack = ContextStack();
    elementParser = ElementParser(errorReporter, contextStack: contextStack);
    lexer = Lexer();
  });

  group('ElementParser error handling tests', () {
    test('should handle empty tokens list', () {
      final tokens = <Token>[];
      
      expect(
        () => elementParser.parsePerson(tokens),
        throwsA(isA<ParseError>().having(
          (e) => e.message,
          'message',
          contains('No tokens provided')
        ))
      );
      
      expect(
        () => elementParser.parseSoftwareSystem(tokens),
        throwsA(isA<ParseError>().having(
          (e) => e.message,
          'message',
          contains('No tokens provided')
        ))
      );
      
      expect(
        () => elementParser._parseIdentifier(tokens),
        throwsA(isA<ParseError>().having(
          (e) => e.message,
          'message',
          contains('Expected identifier')
        ))
      );
      
      expect(
        () => elementParser._parseParentChild(tokens),
        throwsA(isA<ParseError>().having(
          (e) => e.message,
          'message',
          contains('No tokens provided')
        ))
      );
    });

    test('should handle incorrect token type for person', () {
      final tokens = [
        Token(
          type: TokenType.softwareSystem, // Wrong token type, should be person
          lexeme: 'softwareSystem',
          position: SourcePosition(line: 1, column: 1),
        ),
        Token(
          type: TokenType.string,
          lexeme: '"User"',
          position: SourcePosition(line: 1, column: 15),
          value: 'User',
        ),
      ];
      
      // Should throw an error but still return a default PersonNode
      elementParser.parsePerson(tokens);
      
      expect(errorReporter.hasErrors, isTrue);
    });

    test('should handle incorrect token type for software system', () {
      final tokens = [
        Token(
          type: TokenType.person, // Wrong token type, should be softwareSystem
          lexeme: 'person',
          position: SourcePosition(line: 1, column: 1),
        ),
        Token(
          type: TokenType.string,
          lexeme: '"PaymentSystem"',
          position: SourcePosition(line: 1, column: 8),
          value: 'PaymentSystem',
        ),
      ];
      
      // Should throw an error but still return a default SoftwareSystemNode
      elementParser.parseSoftwareSystem(tokens);
      
      expect(errorReporter.hasErrors, isTrue);
    });

    test('should handle missing person name', () {
      final tokens = [
        Token(
          type: TokenType.person,
          lexeme: 'person',
          position: SourcePosition(line: 1, column: 1),
        ),
        // Missing name token
      ];
      
      expect(
        () => elementParser.parsePerson(tokens),
        throwsA(isA<ParseError>().having(
          (e) => e.message,
          'message',
          contains('Expected person name')
        ))
      );
    });

    test('should handle missing software system name', () {
      final tokens = [
        Token(
          type: TokenType.softwareSystem,
          lexeme: 'softwareSystem',
          position: SourcePosition(line: 1, column: 1),
        ),
        // Missing name token
      ];
      
      expect(
        () => elementParser.parseSoftwareSystem(tokens),
        throwsA(isA<ParseError>().having(
          (e) => e.message,
          'message',
          contains('Expected software system name')
        ))
      );
    });

    test('should handle invalid token for name in person', () {
      final tokens = [
        Token(
          type: TokenType.person,
          lexeme: 'person',
          position: SourcePosition(line: 1, column: 1),
        ),
        Token(
          type: TokenType.number, // Wrong token type, should be string
          lexeme: '123',
          position: SourcePosition(line: 1, column: 8),
        ),
      ];
      
      expect(
        () => elementParser.parsePerson(tokens),
        throwsA(isA<ParseError>().having(
          (e) => e.message,
          'message',
          contains('Expected person name')
        ))
      );
    });

    test('should handle invalid token for name in software system', () {
      final tokens = [
        Token(
          type: TokenType.softwareSystem,
          lexeme: 'softwareSystem',
          position: SourcePosition(line: 1, column: 1),
        ),
        Token(
          type: TokenType.number, // Wrong token type, should be string
          lexeme: '123',
          position: SourcePosition(line: 1, column: 15),
        ),
      ];
      
      expect(
        () => elementParser.parseSoftwareSystem(tokens),
        throwsA(isA<ParseError>().having(
          (e) => e.message,
          'message',
          contains('Expected software system name')
        ))
      );
    });

    test('should handle unmatched braces in person', () {
      final tokens = lexer.tokenize('''
        person "Administrator" {
          description = "System administrator"
          // Missing closing brace
      ''');
      
      expect(
        () => elementParser.parsePerson(tokens),
        throwsA(isA<ParseError>().having(
          (e) => e.message,
          'message',
          contains('Unmatched brace')
        ))
      );
    });

    test('should handle unmatched braces in software system', () {
      final tokens = lexer.tokenize('''
        softwareSystem "Authentication Service" {
          description = "Handles user authentication"
          // Missing closing brace
      ''');
      
      expect(
        () => elementParser.parseSoftwareSystem(tokens),
        throwsA(isA<ParseError>().having(
          (e) => e.message,
          'message',
          contains('Unmatched brace')
        ))
      );
    });

    test('should handle property assignment with no equals sign', () {
      final tokens = lexer.tokenize('''
        person "User" {
          description "Missing equals sign"
        }
      ''');
      
      // Should parse but report error or warning
      elementParser.parsePerson(tokens);
      
      expect(errorReporter.hasErrors || errorReporter.hasWarnings, isTrue);
    });

    test('should handle malformed relationship in block', () {
      final tokens = lexer.tokenize('''
        softwareSystem "System" {
          container "Frontend" "UI" "React"
          container "Backend" "API" "Node.js"
          
          Frontend -> // Malformed relationship missing target
        }
      ''');
      
      // Should parse but report error or warning
      elementParser.parseSoftwareSystem(tokens);
      
      expect(errorReporter.hasErrors || errorReporter.hasWarnings, isTrue);
    });

    test('should handle context stack errors during parse', () {
      // Create a version of contextStack that throws on push
      final errorContextStack = ContextStack();
      errorContextStack.push = (_) => throw Exception('Stack error');
      
      final errorElementParser = ElementParser(
        errorReporter, 
        contextStack: errorContextStack
      );
      
      final tokens = [
        Token(
          type: TokenType.person,
          lexeme: 'person',
          position: SourcePosition(line: 1, column: 1),
        ),
        Token(
          type: TokenType.string,
          lexeme: '"User"',
          position: SourcePosition(line: 1, column: 8),
          value: 'User',
        ),
      ];
      
      // Should handle the error gracefully
      final result = errorElementParser.parsePerson(tokens);
      
      expect(result, isA<PersonNode>());
      expect(result.name, equals('Error'));
      expect(errorReporter.hasErrors, isTrue);
    });

    test('should handle extremely long names', () {
      final veryLongName = 'A' * 10000; // Extremely long name
      final tokens = [
        Token(
          type: TokenType.person,
          lexeme: 'person',
          position: SourcePosition(line: 1, column: 1),
        ),
        Token(
          type: TokenType.string,
          lexeme: '"$veryLongName"',
          position: SourcePosition(line: 1, column: 8),
          value: veryLongName,
        ),
      ];
      
      // Should parse without crashing
      final result = elementParser.parsePerson(tokens);
      
      expect(result, isA<PersonNode>());
      expect(result.name, equals(veryLongName));
      expect(result.id.length, equals(veryLongName.length));
    });
    
    test('should report error for property assignment without current element', () {
      final tokens = [
        Token(
          type: TokenType.identifier,
          lexeme: 'description',
          position: SourcePosition(line: 1, column: 1),
        ),
        Token(
          type: TokenType.equals,
          lexeme: '=',
          position: SourcePosition(line: 1, column: 12),
        ),
        Token(
          type: TokenType.string,
          lexeme: '"Description value"',
          position: SourcePosition(line: 1, column: 14),
          value: 'Description value',
        ),
      ];
      
      // Push an empty context without current element
      contextStack.push(Context('test'));
      
      expect(
        () => elementParser._parseParentChild(tokens),
        throwsA(isA<ParseError>().having(
          (e) => e.message,
          'message',
          contains('No current element')
        ))
      );
    });

    test('should handle and report unexpected exceptions during parsing', () {
      // Create tokens that would cause an unexpected exception
      final tokens = [
        Token(
          type: TokenType.person,
          lexeme: 'person',
          position: SourcePosition(line: 1, column: 1),
        ),
        Token(
          type: TokenType.string,
          lexeme: '"User"',
          position: SourcePosition(line: 1, column: 8),
          value: 'User',
        ),
      ];
      
      // Create a version of ContextStack that throws unexpectedly
      final explodingContextStack = ContextStack();
      explodingContextStack.push = (Context context) {
        explodingContextStack._stack.add(context);
        if (context.name == 'person') {
          throw Exception('Unexpected exception');
        }
      };
      
      final explodingElementParser = ElementParser(
        errorReporter,
        contextStack: explodingContextStack
      );
      
      // Should handle unexpected exception and report error
      final result = explodingElementParser.parsePerson(tokens);
      
      expect(result, isA<PersonNode>());
      expect(result.name, equals('Error'));
      expect(errorReporter.hasErrors, isTrue);
    });

    test('should handle multiple model parsing errors in sequence', () {
      // Test that multiple errors don't leave the parser in a bad state
      
      // First parse with error
      final tokensWithError = lexer.tokenize('person "User" {');
      expect(() => elementParser.parsePerson(tokensWithError), throwsA(isA<ParseError>()));
      
      // Then parse something valid to ensure parser recovered
      final validTokens = lexer.tokenize('person "User"');
      final result = elementParser.parsePerson(validTokens);
      
      expect(result, isA<PersonNode>());
      expect(result.name, equals('User'));
    });

    test('should handle nested parsing errors', () {
      final tokens = lexer.tokenize('''
        softwareSystem "System" {
          description = "Valid description"
          
          container "Frontend" {
            description = "Missing closing brace for container"
          
          // Missing closing brace for system
      ''');
      
      expect(
        () => elementParser.parseSoftwareSystem(tokens),
        throwsA(isA<ParseError>().having(
          (e) => e.message,
          'message',
          contains('Unmatched brace')
        ))
      );
      
      // Check that all contexts were correctly popped
      expect(contextStack.isEmpty(), isTrue);
    });

    test('should handle overlapping braces in block structure', () {
      final tokens = lexer.tokenize('''
        softwareSystem "System" {
          container "Container1" {
            description = "Description"
          }
          container "Container2" {
            description = "Description"
          }
        }
      ''');
      
      // Should parse correctly without confusing the brace matching
      final result = elementParser.parseSoftwareSystem(tokens);
      
      expect(result, isA<SoftwareSystemNode>());
      expect(result.name, equals('System'));
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should handle reserved keywords as identifiers', () {
      final tokens = lexer.tokenize('''
        person "model" "A person with a reserved keyword name"
      ''');
      
      final result = elementParser.parsePerson(tokens);
      
      expect(result, isA<PersonNode>());
      expect(result.name, equals('model'));
      expect(result.id, equals('model'));
      expect(errorReporter.hasErrors, isFalse);
    });
    
    test('should handle special characters in property values', () {
      final tokens = lexer.tokenize('''
        person "Admin" {
          description = "Person with special chars: <>&\\"'[]{}%$#@!~`"
        }
      ''');
      
      final result = elementParser.parsePerson(tokens);
      
      expect(result, isA<PersonNode>());
      expect(result.name, equals('Admin'));
      // Verify the description is properly handled with special chars
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should handle missing model parser when parsing nested elements', () {
      // Create element parser without model parser
      final parserWithoutModelParser = ElementParser(errorReporter, contextStack: contextStack);
      
      final tokens = lexer.tokenize('''
        softwareSystem "System" {
          container "Frontend" "UI" "React"
        }
      ''');
      
      // Should parse but report a warning about missing model parser
      final result = parserWithoutModelParser.parseSoftwareSystem(tokens);
      
      expect(result, isA<SoftwareSystemNode>());
      expect(result.name, equals('System'));
      expect(errorReporter.hasWarnings || errorReporter.hasErrors, isTrue);
    });

    test('should handle missing relationship parser when parsing relationships', () {
      // Create element parser without relationship parser
      final parserWithoutRelationshipParser = ElementParser(errorReporter, contextStack: contextStack);
      
      final tokens = lexer.tokenize('''
        softwareSystem "System" {
          container "Frontend" "UI" "React"
          container "Backend" "API" "Node.js"
          Frontend -> Backend "Uses"
        }
      ''');
      
      // Should parse but report a warning about missing relationship parser
      final result = parserWithoutRelationshipParser.parseSoftwareSystem(tokens);
      
      expect(result, isA<SoftwareSystemNode>());
      expect(result.name, equals('System'));
      expect(errorReporter.hasWarnings || errorReporter.hasErrors, isTrue);
    });
  });
  
  group('ElementParser state consistency tests', () {
    test('should maintain parser state across multiple parse calls', () {
      // Parse first element
      final personTokens = lexer.tokenize('person "User" "A user"');
      final person = elementParser.parsePerson(personTokens);
      expect(person, isA<PersonNode>());
      expect(person.name, equals('User'));
      
      // Parse second element
      final systemTokens = lexer.tokenize('softwareSystem "System" "A system"');
      final system = elementParser.parseSoftwareSystem(systemTokens);
      expect(system, isA<SoftwareSystemNode>());
      expect(system.name, equals('System'));
      
      // Verify no unexpected errors
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should handle parse errors without corrupting parser state', () {
      // Parse with error
      final invalidTokens = lexer.tokenize('person {');
      expect(() => elementParser.parsePerson(invalidTokens), throwsA(isA<ParseError>()));
      
      // Verify that subsequent parse succeeds
      final validTokens = lexer.tokenize('person "User"');
      final result = elementParser.parsePerson(validTokens);
      expect(result, isA<PersonNode>());
      expect(result.name, equals('User'));
    });

    test('should reset context stack properly after parsing', () {
      final tokens = lexer.tokenize('person "User"');
      
      final initialDepth = contextStack.size();
      elementParser.parsePerson(tokens);
      
      // Context stack should be back to initial size
      expect(contextStack.size(), equals(initialDepth));
    });

    test('should handle null SourcePosition in error reporting', () {
      final tokens = [
        Token(
          type: TokenType.person,
          lexeme: 'person',
          position: null, // Null position
        ),
        Token(
          type: TokenType.string,
          lexeme: '"User"',
          position: null, // Null position
          value: 'User',
        ),
      ];
      
      // Should handle null positions gracefully
      final result = elementParser.parsePerson(tokens);
      
      expect(result, isA<PersonNode>());
      expect(result.name, equals('User'));
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should handle re-entrant parsing', () {
      // Create tokens for a complex parse
      final tokens = lexer.tokenize('''
        softwareSystem "Nested" {
          container "Inner" {
            description = "Inner description"
          }
        }
      ''');
      
      // Save context stack depth before
      final initialDepth = contextStack.size();
      
      // First parse
      final result1 = elementParser.parseSoftwareSystem(tokens);
      expect(result1, isA<SoftwareSystemNode>());
      expect(contextStack.size(), equals(initialDepth));
      
      // Parse again to test re-entrancy
      final result2 = elementParser.parseSoftwareSystem(tokens);
      expect(result2, isA<SoftwareSystemNode>());
      expect(contextStack.size(), equals(initialDepth));
    });
  });
}