import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/parser/model_parser.dart';
import 'package:flutter_structurizr/domain/parser/ast/ast.dart';
import 'package:flutter_structurizr/domain/parser/lexer/token.dart';
import 'package:flutter_structurizr/domain/parser/lexer/lexer.dart';

void main() {
  group('ModelParser Implementation', () {
    late ErrorReporter errorReporter;
    late ModelParser modelParser;
    
    setUp(() {
      errorReporter = ErrorReporter();
      modelParser = ModelParser(errorReporter);
    });
    
    test('parse should create a valid ModelNode from tokens', () {
      // Create test tokens for a simple model
      final lexer = Lexer('''
        model {
          person "User"
          system = softwareSystem "System"
        }
      ''');
      final tokens = lexer.scanTokens();
      
      // Filter tokens for just the model block
      final modelTokens = tokens.where((t) => 
        t.type != TokenType.eof && 
        !(t.type == TokenType.identifier && t.value == 'workspace')).toList();
      
      final modelNode = modelParser.parse(modelTokens);
      
      // Verify basic model structure
      expect(modelNode, isA<ModelNode>());
      // Further assertions would depend on how elements are accessed from the model
    });
    
    test('_parseGroup should create a valid GroupNode from tokens', () {
      // Create test tokens for a group
      final tokens = [
        Token(TokenType.string, '"Internal"', null, 1, 1),
        Token(TokenType.leftBrace, '{', null, 1, 11),
        Token(TokenType.rightBrace, '}', null, 1, 12),
      ];
      
      final groupNode = modelParser._parseGroup(tokens);
      
      expect(groupNode, isA<GroupNode>());
      expect(groupNode?.name, equals('Internal'));
    });
    
    test('_parseEnterprise should create a valid EnterpriseNode from tokens', () {
      // Create test tokens for an enterprise
      final tokens = [
        Token(TokenType.string, '"MyCompany"', null, 1, 1),
        Token(TokenType.leftBrace, '{', null, 1, 12),
        Token(TokenType.rightBrace, '}', null, 1, 13),
      ];
      
      final enterpriseNode = modelParser._parseEnterprise(tokens);
      
      expect(enterpriseNode, isA<EnterpriseNode>());
      expect(enterpriseNode?.name, equals('MyCompany'));
    });
    
    test('_parseNestedElement should create valid element nodes from tokens', () {
      // Test for person element
      final personTokens = [
        Token(TokenType.identifier, 'person', null, 1, 1),
        Token(TokenType.string, '"User"', null, 1, 8),
        Token(TokenType.string, '"A user of the system"', null, 1, 15),
      ];
      
      final personNode = modelParser._parseNestedElement(personTokens);
      
      expect(personNode, isA<PersonNode>());
      expect(personNode?.name, equals('User'));
      
      // Test for software system element
      final systemTokens = [
        Token(TokenType.identifier, 'softwareSystem', null, 2, 1),
        Token(TokenType.string, '"Payment System"', null, 2, 16),
        Token(TokenType.string, '"Handles payments"', null, 2, 33),
      ];
      
      final systemNode = modelParser._parseNestedElement(systemTokens);
      
      expect(systemNode, isA<SoftwareSystemNode>());
      expect(systemNode?.name, equals('Payment System'));
      
      // Test for container element
      final containerTokens = [
        Token(TokenType.identifier, 'container', null, 3, 1),
        Token(TokenType.string, '"Web Application"', null, 3, 11),
        Token(TokenType.string, '"Frontend UI"', null, 3, 28),
        Token(TokenType.string, '"React"', null, 3, 41),
      ];
      
      final containerNode = modelParser._parseNestedElement(containerTokens);
      
      expect(containerNode, isA<ContainerNode>());
      expect(containerNode?.name, equals('Web Application'));
      
      // Test for component element
      final componentTokens = [
        Token(TokenType.identifier, 'component', null, 4, 1),
        Token(TokenType.string, '"Authentication"', null, 4, 11),
        Token(TokenType.string, '"Handles user auth"', null, 4, 28),
        Token(TokenType.string, '"Spring Security"', null, 4, 48),
      ];
      
      final componentNode = modelParser._parseNestedElement(componentTokens);
      
      expect(componentNode, isA<ComponentNode>());
      expect(componentNode?.name, equals('Authentication'));
    });
    
    test('_parseImpliedRelationship should create a valid RelationshipNode from tokens', () {
      // Test for basic relationship
      final basicTokens = [
        Token(TokenType.identifier, 'user', null, 1, 1),
        Token(TokenType.arrow, '->', null, 1, 6),
        Token(TokenType.identifier, 'system', null, 1, 9),
      ];
      
      final basicNode = modelParser._parseImpliedRelationship(basicTokens);
      
      expect(basicNode, isA<RelationshipNode>());
      expect(basicNode?.sourceId, equals('user'));
      expect(basicNode?.destinationId, equals('system'));
      expect(basicNode?.description, equals('uses')); // Default description
      
      // Test for relationship with description
      final descTokens = [
        Token(TokenType.identifier, 'user', null, 2, 1),
        Token(TokenType.arrow, '->', null, 2, 6),
        Token(TokenType.identifier, 'system', null, 2, 9),
        Token(TokenType.string, '"Logs into"', null, 2, 16),
      ];
      
      final descNode = modelParser._parseImpliedRelationship(descTokens);
      
      expect(descNode, isA<RelationshipNode>());
      expect(descNode?.sourceId, equals('user'));
      expect(descNode?.destinationId, equals('system'));
      expect(descNode?.description, equals('Logs into'));
      
      // Test for relationship with description and technology
      final techTokens = [
        Token(TokenType.identifier, 'user', null, 3, 1),
        Token(TokenType.arrow, '->', null, 3, 6),
        Token(TokenType.identifier, 'system', null, 3, 9),
        Token(TokenType.string, '"Logs into"', null, 3, 16),
        Token(TokenType.string, '"HTTPS"', null, 3, 28),
      ];
      
      final techNode = modelParser._parseImpliedRelationship(techTokens);
      
      expect(techNode, isA<RelationshipNode>());
      expect(techNode?.sourceId, equals('user'));
      expect(techNode?.destinationId, equals('system'));
      expect(techNode?.description, equals('Logs into'));
      // Check technology is set as a property
    });
    
    test('parse should handle complex model with all element types', () {
      // Create a complex model with groups, enterprise, elements, and relationships
      final lexer = Lexer('''
        model {
          enterprise "MyCompany" {
            user = person "User" "A user of the system"
            
            group "Internal" {
              system = softwareSystem "System" "Main system"
              db = container "Database" "Stores data" "PostgreSQL" 
            }
            
            group "External" {
              extSys = softwareSystem "External System" "Third-party system"
            }
            
            user -> system "Uses"
            system -> db "Stores data in"
            system -> extSys "Integrates with" "API"
          }
        }
      ''');
      final tokens = lexer.scanTokens();
      
      // Filter tokens for just the model block
      final modelTokens = tokens.where((t) => 
        t.type != TokenType.eof && 
        !(t.type == TokenType.identifier && t.value == 'workspace')).toList();
      
      final modelNode = modelParser.parse(modelTokens);
      
      // Verify model structure is created correctly
      expect(modelNode, isA<ModelNode>());
      // Full verification would require access to internal model structure
    });
    
    test('parse should report errors for invalid syntax', () {
      // Test with invalid syntax
      final lexer = Lexer('''
        model {
          person # Invalid syntax
          -> "Invalid relationship"
        }
      ''');
      final tokens = lexer.scanTokens();
      
      // Filter tokens for just the model block
      final modelTokens = tokens.where((t) => 
        t.type != TokenType.eof && 
        !(t.type == TokenType.identifier && t.value == 'workspace')).toList();
      
      modelParser.parse(modelTokens);
      
      // Verify errors are reported
      expect(errorReporter.errors.isNotEmpty, isTrue);
    });
  });
}