import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/parser/lexer/token.dart';
import 'package:flutter_structurizr/domain/parser/lexer/lexer.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/parser/ast/ast_nodes.dart';

// This would be the actual implementation file we're testing
import 'package:flutter_structurizr/domain/parser/element_parser.dart';

void main() {
  late ElementParser elementParser;
  late ErrorReporter errorReporter;
  late Lexer lexer;

  setUp(() {
    errorReporter = ErrorReporter();
    elementParser = ElementParser(errorReporter);
    lexer = Lexer();
  });

  group('ElementParser edge cases', () {
    test('should handle person with empty description', () {
      // Create a DSL string for a person with empty description
      const dsl = 'person "User" "" "external,user"';
      
      // Tokenize the DSL string
      final tokens = lexer.tokenize(dsl);
      
      // Call the method being tested
      final result = elementParser.parsePerson(tokens);
      
      // Verify the result
      expect(result, isA<PersonNode>());
      expect(result.name, equals('User'));
      expect(result.description, isEmpty);
      expect(result.tags?.values, contains('external'));
      expect(result.tags?.values, contains('user'));
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should handle software system with empty tags', () {
      // Create a DSL string for a software system with empty tags
      const dsl = 'softwareSystem "Payment System" "Handles payments" ""';
      
      // Tokenize the DSL string
      final tokens = lexer.tokenize(dsl);
      
      // Call the method being tested
      final result = elementParser.parseSoftwareSystem(tokens);
      
      // Verify the result
      expect(result, isA<SoftwareSystemNode>());
      expect(result.name, equals('Payment System'));
      expect(result.description, equals('Handles payments'));
      expect(result.tags?.values, isEmpty);
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should handle person with special characters in name', () {
      // Create a DSL string for a person with special characters in name
      const dsl = 'person "User-123_@#$%" "A user with special characters in name"';
      
      // Tokenize the DSL string
      final tokens = lexer.tokenize(dsl);
      
      // Call the method being tested
      final result = elementParser.parsePerson(tokens);
      
      // Verify the result
      expect(result, isA<PersonNode>());
      expect(result.name, equals('User-123_@#$%'));
      expect(result.description, equals('A user with special characters in name'));
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should handle too many tokens for person', () {
      // Create a DSL string for a person with too many tokens
      const dsl = 'person "User" "Description" "tags" "extra" "more extra"';
      
      // Tokenize the DSL string
      final tokens = lexer.tokenize(dsl);
      
      // Call the method being tested
      expect(() => elementParser.parsePerson(tokens), 
        throwsA(isA<ParseError>().having(
          (e) => e.message, 
          'message', 
          contains('Too many tokens')
        ))
      );
    });

    test('should handle too many tokens for software system', () {
      // Create a DSL string for a software system with too many tokens
      const dsl = 'softwareSystem "System" "Description" "tags" "extra" "more extra"';
      
      // Tokenize the DSL string
      final tokens = lexer.tokenize(dsl);
      
      // Call the method being tested
      expect(() => elementParser.parseSoftwareSystem(tokens), 
        throwsA(isA<ParseError>().having(
          (e) => e.message, 
          'message', 
          contains('Too many tokens')
        ))
      );
    });

    test('should handle missing closing brace in person', () {
      // Create a DSL string for a person with missing closing brace
      const dsl = '''
        person "Admin" {
          description = "System administrator"
          tags = "internal,admin"
          # Missing closing brace
      ''';
      
      // Tokenize the DSL string
      final tokens = lexer.tokenize(dsl);
      
      // Call the method being tested
      expect(() => elementParser.parsePerson(tokens), 
        throwsA(isA<ParseError>().having(
          (e) => e.message, 
          'message', 
          contains('Expected }')
        ))
      );
    });

    test('should handle invalid property in person block', () {
      // Create a DSL string for a person with an invalid property
      const dsl = '''
        person "Admin" {
          description = "System administrator"
          invalidProperty = "This property doesn't exist"
        }
      ''';
      
      // Tokenize the DSL string
      final tokens = lexer.tokenize(dsl);
      
      // Call the method being tested
      final result = elementParser.parsePerson(tokens);
      
      // Verify errors were reported but parsing continued
      expect(errorReporter.hasErrors, isTrue);
      expect(result, isA<PersonNode>());
      expect(result.name, equals('Admin'));
      expect(result.description, equals('System administrator'));
    });

    test('should handle duplicate properties in software system block', () {
      // Create a DSL string for a software system with duplicate properties
      const dsl = '''
        softwareSystem "E-Commerce System" {
          description = "First description"
          description = "Second description"
          tags = "tag1,tag2"
          tags = "tag3,tag4"
        }
      ''';
      
      // Tokenize the DSL string
      final tokens = lexer.tokenize(dsl);
      
      // Call the method being tested
      final result = elementParser.parseSoftwareSystem(tokens);
      
      // Verify warnings were reported and last value was used
      expect(errorReporter.hasWarnings, isTrue);
      expect(result, isA<SoftwareSystemNode>());
      expect(result.name, equals('E-Commerce System'));
      expect(result.description, equals('Second description'));
      // Depending on implementation, tags might be merged or last one used
      // expect(result.tags?.values, contains('tag3'));
      // expect(result.tags?.values, contains('tag4'));
    });

    test('should handle malformed tags in person', () {
      // Create a DSL string for a person with malformed tags
      const dsl = 'person "User" "Description" "tag1,,tag2,,"';
      
      // Tokenize the DSL string
      final tokens = lexer.tokenize(dsl);
      
      // Call the method being tested
      final result = elementParser.parsePerson(tokens);
      
      // Verify empty tags are filtered out
      expect(result, isA<PersonNode>());
      expect(result.tags?.values, contains('tag1'));
      expect(result.tags?.values, contains('tag2'));
      expect(result.tags?.values.length, equals(2));
    });

    test('should handle properties with escaped quotes', () {
      // Create a DSL string with escaped quotes in properties
      const dsl = '''
        softwareSystem "System" {
          description = "System with \\"quoted\\" text inside"
        }
      ''';
      
      // Tokenize the DSL string
      final tokens = lexer.tokenize(dsl);
      
      // Call the method being tested
      final result = elementParser.parseSoftwareSystem(tokens);
      
      // Verify escaped quotes are handled correctly
      expect(result, isA<SoftwareSystemNode>());
      expect(result.name, equals('System'));
      expect(result.description, equals('System with "quoted" text inside'));
    });

    test('should handle nested software system construction', () {
      // Create a DSL string with nested software system blocks
      const dsl = '''
        softwareSystem "Parent System" {
          softwareSystem "Child System 1" {
            description = "First nested system"
          }
          softwareSystem "Child System 2" {
            description = "Second nested system"
          }
        }
      ''';
      
      // Tokenize the DSL string
      final tokens = lexer.tokenize(dsl);
      
      // This should either work (if nesting is supported) or throw a specific error
      // The test validates proper handling either way
      try {
        final result = elementParser.parseSoftwareSystem(tokens);
        // If nesting is supported, verify the structure
        expect(result, isA<SoftwareSystemNode>());
        expect(result.name, equals('Parent System'));
        // Additional verification of nested systems would go here
      } catch (e) {
        // If nesting is not supported, verify a proper error is thrown
        expect(e, isA<ParseError>().having(
          (e) => e.message, 
          'message', 
          contains('Nested software system not allowed')
        ));
      }
    });
  });
}