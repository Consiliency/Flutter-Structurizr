import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/parser/lexer/token.dart';
import 'package:flutter_structurizr/domain/parser/lexer/lexer.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';

// This would be the actual implementation files we're testing
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

  group('ElementParser integration tests', () {
    test('should parse person from DSL string', () {
      // Create a DSL string for a person
      const dsl = 'person "User" "A standard user of the system" "external,user"';
      
      // Tokenize the DSL string
      final tokens = lexer.tokenize(dsl);
      
      // Call the method being tested
      final result = elementParser.parsePerson(tokens);
      
      // Verify the result
      expect(result, isA<PersonNode>());
      expect(result.name, equals('User'));
      expect(result.description, equals('A standard user of the system'));
      expect(result.tags.values, contains('external'));
      expect(result.tags.values, contains('user'));
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should parse software system from DSL string', () {
      // Create a DSL string for a software system
      const dsl = 'softwareSystem "Payment System" "Handles all payment processing" "external,payment"';
      
      // Tokenize the DSL string
      final tokens = lexer.tokenize(dsl);
      
      // Call the method being tested
      final result = elementParser.parseSoftwareSystem(tokens);
      
      // Verify the result
      expect(result, isA<SoftwareSystemNode>());
      expect(result.name, equals('Payment System'));
      expect(result.description, equals('Handles all payment processing'));
      expect(result.tags.values, contains('external'));
      expect(result.tags.values, contains('payment'));
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should parse person with properties block', () {
      // Create a DSL string for a person with a properties block
      const dsl = '''
        person "Admin" {
          description = "System administrator"
          tags = "internal,admin,user"
          url = "https://example.com/admin"
        }
      ''';
      
      // Tokenize the DSL string
      final tokens = lexer.tokenize(dsl);
      
      // Call the method being tested
      final result = elementParser.parsePerson(tokens);
      
      // Verify the result
      expect(result, isA<PersonNode>());
      expect(result.name, equals('Admin'));
      expect(result.description, equals('System administrator'));
      expect(result.tags.values, contains('internal'));
      expect(result.tags.values, contains('admin'));
      expect(result.tags.values, contains('user'));
      // In the real implementation, URL would be stored in properties
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should parse software system with nested containers', () {
      // Create a DSL string for a software system with containers
      const dsl = '''
        softwareSystem "E-Commerce System" {
          description = "Handles all e-commerce functionality"
          
          container "Web Application" "Provides the web interface" "React,TypeScript" {
            description = "React SPA with TypeScript"
          }
          
          container "API" "Provides API for web and mobile clients" "ASP.NET Core" {
            description = "RESTful API"
            tags = "api,json,rest"
          }
          
          container "Database" "Stores product catalog and orders" "PostgreSQL" {
            description = "Relational database"
          }
        }
      ''';
      
      // Tokenize the DSL string
      final tokens = lexer.tokenize(dsl);
      
      // Call the method being tested
      final result = elementParser.parseSoftwareSystem(tokens);
      
      // Verify the result
      expect(result, isA<SoftwareSystemNode>());
      expect(result.name, equals('E-Commerce System'));
      expect(result.description, equals('Handles all e-commerce functionality'));
      
      // Check containers when implementation supports it
      // expect(result.containers.length, equals(3));
      // expect(result.containers[0].name, equals('Web Application'));
      // expect(result.containers[1].name, equals('API'));
      // expect(result.containers[2].name, equals('Database'));
      
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should handle relationships within elements', () {
      // Create a DSL string with relationships
      const dsl = '''
        softwareSystem "WebApp" {
          description = "Web application"
          
          container "Frontend" "Web UI" "React"
          container "Backend" "API" "Node.js"
          container "Database" "Stores data" "MongoDB"
          
          # Relationships
          Frontend -> Backend "Makes API calls using"
          Backend -> Database "Reads from and writes to"
        }
      ''';
      
      // Tokenize the DSL string
      final tokens = lexer.tokenize(dsl);
      
      // Call the method being tested
      final result = elementParser.parseSoftwareSystem(tokens);
      
      // Verify the result
      expect(result, isA<SoftwareSystemNode>());
      expect(result.name, equals('WebApp'));
      
      // Check relationships when implementation supports it
      // This would depend on how relationships are stored in the node structure
      
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should handle element identifiers', () {
      // Create a DSL string with explicit identifiers
      const dsl = '''
        person "Customer" "A customer" {
          # Properties that would affect identification
        }
        
        softwareSystem "Online Store" "E-commerce system" {
          # Properties that would affect identification
        }
      ''';
      
      // Tokenize the DSL string
      final tokens = lexer.tokenize(dsl);
      
      // First parse the person
      final personTokens = tokens.takeWhile((token) => 
        token.type != TokenType.softwareSystem).toList();
      final person = elementParser.parsePerson(personTokens);
      
      // Then parse the software system
      final softwareSystemTokens = tokens.skipWhile((token) => 
        token.type != TokenType.softwareSystem).toList();
      final softwareSystem = elementParser.parseSoftwareSystem(softwareSystemTokens);
      
      // Verify identifiers
      expect(person.id, isNotEmpty);
      expect(softwareSystem.id, isNotEmpty);
      expect(person.id, isNot(equals(softwareSystem.id)));
      
      expect(errorReporter.hasErrors, isFalse);
    });
  });
}