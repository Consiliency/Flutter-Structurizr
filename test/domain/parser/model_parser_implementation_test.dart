import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/parser/model_parser.dart';
import 'package:flutter_structurizr/domain/parser/lexer/token.dart';
import 'package:flutter_structurizr/domain/parser/lexer/lexer.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/model_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/group_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/enterprise_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/person_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/software_system_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/container_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/component_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/relationship_node.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/source_position.dart';

void main() {
  group('ModelParser Implementation', () {
    late ModelParser modelParser;

    setUp(() {
      modelParser = ModelParser(ErrorReporter('test'));
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
      final modelTokens = tokens
          .where((t) =>
              t.type != TokenType.eof &&
              !(t.type == TokenType.identifier && t.value == 'workspace'))
          .toList();

      final modelNode = modelParser.parse(modelTokens);

      // Verify basic model structure
      expect(modelNode, isA<ModelNode>());
      // Further assertions would depend on how elements are accessed from the model
    });

    test('_parseGroup should create a valid GroupNode from tokens', () {
      // Create test tokens for a group
      final tokens = [
        Token(
            type: TokenType.string,
            lexeme: '"Internal"',
            value: null,
            position: const SourcePosition(1, 1, 0)),
        Token(
            type: TokenType.leftBrace,
            lexeme: '{',
            value: null,
            position: const SourcePosition(1, 11, 0)),
        Token(
            type: TokenType.rightBrace,
            lexeme: '}',
            value: null,
            position: const SourcePosition(1, 12, 0)),
      ];

      final groupNode = modelParser._parseGroup(tokens);

      expect(groupNode, isA<GroupNode>());
      expect(groupNode?.name, equals('Internal'));
    });

    test('_parseEnterprise should create a valid EnterpriseNode from tokens',
        () {
      // Create test tokens for an enterprise
      final tokens = [
        Token(
            type: TokenType.string,
            lexeme: '"MyCompany"',
            value: null,
            position: const SourcePosition(1, 1, 0)),
        Token(
            type: TokenType.leftBrace,
            lexeme: '{',
            value: null,
            position: const SourcePosition(1, 12, 0)),
        Token(
            type: TokenType.rightBrace,
            lexeme: '}',
            value: null,
            position: const SourcePosition(1, 13, 0)),
      ];

      final enterpriseNode = modelParser._parseEnterprise(tokens);

      expect(enterpriseNode, isA<EnterpriseNode>());
      expect(enterpriseNode?.name, equals('MyCompany'));
    });

    test('_parseNestedElement should create valid element nodes from tokens',
        () {
      // Test for person element
      final personTokens = [
        Token(
            type: TokenType.identifier,
            lexeme: 'person',
            value: null,
            position: const SourcePosition(1, 1, 0)),
        Token(
            type: TokenType.string,
            lexeme: '"User"',
            value: null,
            position: const SourcePosition(1, 8, 0)),
        Token(
            type: TokenType.string,
            lexeme: '"A user of the system"',
            value: null,
            position: const SourcePosition(1, 15, 0)),
      ];

      final personNode = modelParser._parseNestedElement(personTokens);

      expect(personNode, isA<PersonNode>());
      expect(personNode?.name, equals('User'));

      // Test for software system element
      final systemTokens = [
        Token(
            type: TokenType.identifier,
            lexeme: 'softwareSystem',
            value: null,
            position: const SourcePosition(2, 1, 0)),
        Token(
            type: TokenType.string,
            lexeme: '"Payment System"',
            value: null,
            position: const SourcePosition(2, 16, 0)),
        Token(
            type: TokenType.string,
            lexeme: '"Handles payments"',
            value: null,
            position: const SourcePosition(2, 33, 0)),
      ];

      final systemNode = modelParser._parseNestedElement(systemTokens);

      expect(systemNode, isA<SoftwareSystemNode>());
      expect(systemNode?.name, equals('Payment System'));

      // Test for container element
      final containerTokens = [
        Token(
            type: TokenType.identifier,
            lexeme: 'container',
            value: null,
            position: const SourcePosition(3, 1, 0)),
        Token(
            type: TokenType.string,
            lexeme: '"Web Application"',
            value: null,
            position: const SourcePosition(3, 11, 0)),
        Token(
            type: TokenType.string,
            lexeme: '"Frontend UI"',
            value: null,
            position: const SourcePosition(3, 28, 0)),
        Token(
            type: TokenType.string,
            lexeme: '"React"',
            value: null,
            position: const SourcePosition(3, 41, 0)),
      ];

      final containerNode = modelParser._parseNestedElement(containerTokens);

      expect(containerNode, isA<ContainerNode>());
      expect(containerNode?.name, equals('Web Application'));

      // Test for component element
      final componentTokens = [
        Token(
            type: TokenType.identifier,
            lexeme: 'component',
            value: null,
            position: const SourcePosition(4, 1, 0)),
        Token(
            type: TokenType.string,
            lexeme: '"Authentication"',
            value: null,
            position: const SourcePosition(4, 11, 0)),
        Token(
            type: TokenType.string,
            lexeme: '"Handles user auth"',
            value: null,
            position: const SourcePosition(4, 28, 0)),
        Token(
            type: TokenType.string,
            lexeme: '"Spring Security"',
            value: null,
            position: const SourcePosition(4, 48, 0)),
      ];

      final componentNode = modelParser._parseNestedElement(componentTokens);

      expect(componentNode, isA<ComponentNode>());
      expect(componentNode?.name, equals('Authentication'));
    });

    test(
        '_parseImpliedRelationship should create a valid RelationshipNode from tokens',
        () {
      // Test for basic relationship
      final basicTokens = [
        Token(
            type: TokenType.identifier,
            lexeme: 'user',
            value: null,
            position: const SourcePosition(1, 1, 0)),
        Token(
            type: TokenType.arrow,
            lexeme: '->',
            value: null,
            position: const SourcePosition(1, 6, 0)),
        Token(
            type: TokenType.identifier,
            lexeme: 'system',
            value: null,
            position: const SourcePosition(1, 9, 0)),
      ];

      final basicNode = modelParser._parseImpliedRelationship(basicTokens);

      expect(basicNode, isA<RelationshipNode>());
      expect(basicNode?.sourceId, equals('user'));
      expect(basicNode?.destinationId, equals('system'));
      expect(basicNode?.description, equals('uses')); // Default description

      // Test for relationship with description
      final descTokens = [
        Token(
            type: TokenType.identifier,
            lexeme: 'user',
            value: null,
            position: const SourcePosition(2, 1, 0)),
        Token(
            type: TokenType.arrow,
            lexeme: '->',
            value: null,
            position: const SourcePosition(2, 6, 0)),
        Token(
            type: TokenType.identifier,
            lexeme: 'system',
            value: null,
            position: const SourcePosition(2, 9, 0)),
        Token(
            type: TokenType.string,
            lexeme: '"Logs into"',
            value: null,
            position: const SourcePosition(2, 16, 0)),
      ];

      final descNode = modelParser._parseImpliedRelationship(descTokens);

      expect(descNode, isA<RelationshipNode>());
      expect(descNode?.sourceId, equals('user'));
      expect(descNode?.destinationId, equals('system'));
      expect(descNode?.description, equals('Logs into'));

      // Test for relationship with description and technology
      final techTokens = [
        Token(
            type: TokenType.identifier,
            lexeme: 'user',
            value: null,
            position: const SourcePosition(3, 1, 0)),
        Token(
            type: TokenType.arrow,
            lexeme: '->',
            value: null,
            position: const SourcePosition(3, 6, 0)),
        Token(
            type: TokenType.identifier,
            lexeme: 'system',
            value: null,
            position: const SourcePosition(3, 9, 0)),
        Token(
            type: TokenType.string,
            lexeme: '"Logs into"',
            value: null,
            position: const SourcePosition(3, 16, 0)),
        Token(
            type: TokenType.string,
            lexeme: '"HTTPS"',
            value: null,
            position: const SourcePosition(3, 28, 0)),
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
      final modelTokens = tokens
          .where((t) =>
              t.type != TokenType.eof &&
              !(t.type == TokenType.identifier && t.value == 'workspace'))
          .toList();

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
      final modelTokens = tokens
          .where((t) =>
              t.type != TokenType.eof &&
              !(t.type == TokenType.identifier && t.value == 'workspace'))
          .toList();

      modelParser.parse(modelTokens);

      // Verify errors are reported
      expect(modelParser.errors.isNotEmpty, isTrue);
    });
  });
}
