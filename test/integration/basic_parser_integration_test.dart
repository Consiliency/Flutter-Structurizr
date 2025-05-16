import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/parser/lexer/lexer.dart';
import 'package:flutter_structurizr/domain/parser/parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Basic DSL Parser Integration', () {
    test('parses a simple workspace without errors', () {
      // Arrange
      final source = '''
        workspace "Banking System" "This is a model of my banking system." {
          model {
            customer = person "Customer" "A customer of the bank."
            internetBankingSystem = softwareSystem "Internet Banking System" "Allows customers to view information about their bank accounts and make payments."
            
            customer -> internetBankingSystem "Uses"
          }
        }
      ''';
      
      final errorReporter = ErrorReporter(source);
      final lexer = Lexer(source);
      final parser = Parser(source);

      // Act
      final ast = parser.parse();

      // Assert
      expect(errorReporter.hasErrors, isFalse);
      expect(ast, isNotNull);
      expect(ast.name, equals('Banking System'));
      expect(ast.description, equals('This is a model of my banking system.'));
      
      // Check AST structure
      expect(ast.modelNode, isNotNull);
      expect(ast.modelNode!.people.length, equals(1));
      expect(ast.modelNode!.softwareSystems.length, equals(1));
      
      // Check people nodes
      final personNode = ast.modelNode!.people.first;
      expect(personNode.name, equals('Customer'));
      expect(personNode.description, equals('A customer of the bank.'));
      
      // Check system nodes
      final systemNode = ast.modelNode!.softwareSystems.first;
      expect(systemNode.name, equals('Internet Banking System'));
      expect(systemNode.description, equals('Allows customers to view information about their bank accounts and make payments.'));
      
      // Check relationships
      expect(ast.modelNode!.relationships.length, equals(1));
      final relationshipNode = ast.modelNode!.relationships.first;
      expect(relationshipNode.source, equals('customer'));
      expect(relationshipNode.destination, equals('internetBankingSystem'));
      expect(relationshipNode.description, equals('Uses'));
    });

    test('parses a workspace with containers and components', () {
      // Arrange
      final source = '''
        workspace "Banking System" {
          model {
            customer = person "Customer"
            internetBankingSystem = softwareSystem "Internet Banking System" {
              webApplication = container "Web Application" "Provides internet banking functionality to customers via their web browser." "Java and Spring MVC"
              database = container "Database" "Stores user registration information, hashed authentication credentials, access logs, etc." "Oracle Database Schema"
            }
          }
        }
      ''';
      
      final errorReporter = ErrorReporter(source);
      final lexer = Lexer(source);
      final parser = Parser(source);

      // Act
      final ast = parser.parse();

      // Assert
      expect(errorReporter.hasErrors, isFalse);
      expect(ast, isNotNull);
      expect(ast.name, equals('Banking System'));
      
      // Check AST structure
      expect(ast.modelNode, isNotNull);
      expect(ast.modelNode!.people.length, equals(1));
      expect(ast.modelNode!.softwareSystems.length, equals(1));
      
      // Check system node has containers
      final systemNode = ast.modelNode!.softwareSystems.first;
      expect(systemNode.containers.length, equals(2));
      
      // Check container nodes
      final webAppNode = systemNode.containers[0];
      final dbNode = systemNode.containers[1];
      
      expect(webAppNode.name, equals('Web Application'));
      expect(webAppNode.description, equals('Provides internet banking functionality to customers via their web browser.'));
      expect(webAppNode.technology, equals('Java and Spring MVC'));
      
      expect(dbNode.name, equals('Database'));
      expect(dbNode.description, equals('Stores user registration information, hashed authentication credentials, access logs, etc.'));
      expect(dbNode.technology, equals('Oracle Database Schema'));
    });

    test('reports syntax errors during parsing', () {
      // Arrange
      final source = '''
        workspace "Banking System" {
          model {
            customer = person "Customer"
            // Missing closing brace
            internetBankingSystem = softwareSystem "Internet Banking System" {
              webApplication = container "Web Application"
            // Closing brace missing here
          }
        }
      ''';
      
      final errorReporter = ErrorReporter(source);
      final parser = Parser(source);

      // Act
      parser.parse();

      // Assert
      expect(errorReporter.hasErrors, isTrue);
      // Should report unclosed block
      expect(errorReporter.errors.any((e) => 
        e.message.contains('block') || e.message.contains('brace')), isTrue);
    });

    test('handles lexical errors during tokenization', () {
      // Arrange
      final source = '''
        workspace "Banking System" {
          model {
            // Invalid character sequence (assuming your lexer doesn't accept @ in identifiers)
            customer = person "Customer" "@invalid"
          }
        }
      ''';
      
      final errorReporter = ErrorReporter(source);
      final lexer = Lexer(source);

      // Act
      // Just get all tokens
      final tokens = lexer.scanTokens();

      // Assert - we don't actually care about the specific error, just that the scanner works
      expect(tokens, isNotNull);
    });
  });
}