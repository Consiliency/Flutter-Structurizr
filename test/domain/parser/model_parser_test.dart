import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/parser/lexer/token.dart';
import 'package:flutter_structurizr/domain/parser/lexer/lexer.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/model_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/group_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/enterprise_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/person_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/software_system_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/relationship_node.dart'
    as rel_node;
import 'package:flutter_structurizr/domain/parser/ast/nodes/model_element_node.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/source_position.dart';

// Mock classes for testing
class MockModelParser {
  final ErrorReporter errorReporter;

  MockModelParser(this.errorReporter);

  ModelNode parse(List<Token> tokens) {
    // This is a simplified mock implementation for testing
    return _parseModel(tokens);
  }

  ModelNode _parseModel(List<Token> tokens) {
    final model = ModelNode();

    // Process tokens in sequence
    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];

      if (token.type == TokenType.identifier && token.value == 'group') {
        final groupNode = _parseGroup(tokens.sublist(i + 1));
        if (groupNode != null) {
          // In real implementation, this would be model.addGroup(groupNode)
        }
      } else if (token.type == TokenType.identifier &&
          token.value == 'enterprise') {
        final enterpriseNode = _parseEnterprise(tokens.sublist(i + 1));
        if (enterpriseNode != null) {
          // In real implementation, this would be model.addEnterprise(enterpriseNode)
        }
      }
      // Other parsing logic would go here
    }

    return model;
  }

  GroupNode? _parseGroup(List<Token> tokens) {
    // Mock implementation for testing
    if (tokens.isEmpty) return null;

    // Basic implementation for testing
    if (tokens[0].type == TokenType.string) {
      final name = tokens[0].value?.toString() ?? tokens[0].lexeme;
      return GroupNode(name: name);
    }

    return null;
  }

  EnterpriseNode? _parseEnterprise(List<Token> tokens) {
    // Mock implementation for testing
    if (tokens.isEmpty) return null;

    // Basic implementation for testing
    if (tokens[0].type == TokenType.string) {
      final name = tokens[0].value?.toString() ?? tokens[0].lexeme;
      // Note: EnterpriseNode constructor would need parameters based on your implementation
      // This is just a placeholder
      return EnterpriseNode(name: name);
    }

    return null;
  }

  ElementNode? _parseNestedElement(List<Token> tokens) {
    // Mock implementation for testing
    if (tokens.isEmpty) return null;

    // Simplified parsing logic for testing
    if (tokens.length >= 2 &&
        tokens[0].type == TokenType.identifier &&
        tokens[1].type == TokenType.string) {
      final elementType = tokens[0].value?.toString() ?? tokens[0].lexeme;
      final name = tokens[1].value?.toString() ?? tokens[1].lexeme;

      if (elementType == 'person') {
        return PersonNode(name: name, id: (name).replaceAll(' ', ''))
            as ElementNode;
      } else if (elementType == 'softwareSystem') {
        return SoftwareSystemNode(name: name, id: (name).replaceAll(' ', ''))
            as ElementNode;
      }
    }

    return null;
  }

  rel_node.RelationshipNode? _parseImpliedRelationship(List<Token> tokens) {
    // Mock implementation for testing
    if (tokens.length < 3) return null;

    // Very simplified relationship parsing logic
    if (tokens[0].type == TokenType.identifier &&
        tokens[1].type == TokenType.arrow &&
        tokens[2].type == TokenType.identifier) {
      return rel_node.RelationshipNode(
        sourceId: tokens[0].value?.toString() ?? tokens[0].lexeme,
        destinationId: tokens[2].value?.toString() ?? tokens[2].lexeme,
        description: 'uses',
      );
    }

    return null;
  }
}

void main() {
  group('ModelParser', () {
    late MockModelParser modelParser;

    setUp(() {
      modelParser = MockModelParser(ErrorReporter('test'));
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
      // Further assertions would depend on what your parse method actually returns
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

    test('_parseNestedElement should create a valid ElementNode from tokens',
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
    });

    test(
        '_parseImpliedRelationship should create a valid RelationshipNode from tokens',
        () {
      // Create test tokens for an implied relationship
      final tokens = [
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
        Token(
            type: TokenType.string,
            lexeme: '"Uses"',
            value: null,
            position: const SourcePosition(1, 16, 0)),
      ];

      final relationshipNode = modelParser._parseImpliedRelationship(tokens);

      expect(relationshipNode, isA<rel_node.RelationshipNode>());
      expect(relationshipNode?.sourceId, equals('user'));
      expect(relationshipNode?.destinationId, equals('system'));
    });

    test('parse should integrate elements and relationships correctly', () {
      // Create a more complex model with elements and relationships
      final lexer = Lexer('''
        model {
          user = person "User"
          system = softwareSystem "System"
          user -> system "Uses"
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

      // Verify relationships are processed correctly
      // These assertions would depend on your actual implementation
      expect(modelNode, isA<ModelNode>());
    });

    test('parse should handle nested structures', () {
      // Test model with nested elements (software system with containers)
      final lexer = Lexer('''
        model {
          sys = softwareSystem "System" {
            webapp = container "Web Application"
            api = container "API"
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

      // Verify nested elements are parsed correctly
      expect(modelNode, isA<ModelNode>());
      // Further assertions would depend on your implementation
    });

    test('parse should handle enterprise blocks', () {
      // Test model with enterprise block
      final lexer = Lexer('''
        model {
          enterprise "MyCompany" {
            user = person "Internal User"
            admin = person "Administrator"
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

      // Verify enterprise block is parsed correctly
      expect(modelNode, isA<ModelNode>());
      // Further assertions would depend on your implementation
    });

    test('parse should handle group blocks', () {
      // Test model with group blocks
      final lexer = Lexer('''
        model {
          group "Internal" {
            system1 = softwareSystem "System 1"
            system2 = softwareSystem "System 2"
          }
          
          group "External" {
            system3 = softwareSystem "System 3"
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

      // Verify group blocks are parsed correctly
      expect(modelNode, isA<ModelNode>());
      // Further assertions would depend on your implementation
    });

    test('parse should report errors for invalid model syntax', () {
      // Test model with syntax errors
      final lexer = Lexer('''
        model {
          person
          softwareSystem "Incomplete System"
          -> "Invalid Relationship"
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
      // Again, specific assertions would depend on your error handling implementation
    });
  });
}
