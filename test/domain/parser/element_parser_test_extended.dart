import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/parser/lexer/token.dart';
import 'package:flutter_structurizr/domain/parser/lexer/lexer.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/parser/ast/ast_nodes.dart';
import 'package:flutter_structurizr/domain/parser/context_stack.dart';
import 'package:flutter_structurizr/domain/parser/element_parser.dart';
import 'package:flutter_structurizr/domain/parser/model_parser.dart';
import 'package:flutter_structurizr/domain/parser/relationship_parser.dart';

class MockModelParser implements ModelParser {
  final List<ModelElementNode> createdElements = [];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName.toString() == 'Symbol("_parseNestedElement")') {
      final tokens = invocation.positionalArguments[0] as List<Token>;
      if (tokens.isNotEmpty && tokens[0].lexeme == 'container' && tokens.length >= 2) {
        final name = tokens[1].value as String? ?? tokens[1].lexeme.replaceAll('"', '');
        final container = ContainerNode(
          id: name.replaceAll(' ', ''),
          parentId: 'parentSystem',
          name: name,
          description: tokens.length > 2 && tokens[2].type == TokenType.string 
              ? tokens[2].value as String? 
              : null,
        );
        createdElements.add(container);
        return container;
      }
    }
    return null;
  }
}

class MockRelationshipParser implements RelationshipParser {
  final List<RelationshipNode> createdRelationships = [];

  @override
  RelationshipNode? parse(List<Token> tokens) {
    if (tokens.length >= 3 && tokens[1].type == TokenType.arrow) {
      final source = tokens[0].lexeme;
      final destination = tokens[2].lexeme;
      
      final relationship = RelationshipNode(
        sourceId: source,
        destinationId: destination,
        description: tokens.length > 3 && tokens[3].type == TokenType.string
            ? tokens[3].value as String?
            : null
      );
      
      createdRelationships.add(relationship);
      return relationship;
    }
    return null;
  }
}

void main() {
  late ElementParser elementParser;
  late ErrorReporter errorReporter;
  late ContextStack contextStack;
  late MockModelParser mockModelParser;
  late MockRelationshipParser mockRelationshipParser;
  late Lexer lexer;

  setUp(() {
    errorReporter = ErrorReporter();
    contextStack = ContextStack();
    mockModelParser = MockModelParser();
    mockRelationshipParser = MockRelationshipParser();
    
    elementParser = ElementParser(
      errorReporter,
      contextStack: contextStack,
      modelParser: mockModelParser,
      relationshipParser: mockRelationshipParser
    );
    
    lexer = Lexer();
  });

  group('ElementParser._parseIdentifier() detailed tests', () {
    test('should handle complex identifiers with special characters', () {
      final tokens = [
        Token(
          type: TokenType.string,
          lexeme: '"System-123_@#\$%"',
          position: SourcePosition(line: 1, column: 1),
          value: 'System-123_@#\$%',
        ),
      ];
      
      final result = elementParser._parseIdentifier(tokens);
      
      expect(result, equals('System-123_@#\$%'));
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should handle very long identifiers', () {
      final veryLongName = 'A' * 500;
      final tokens = [
        Token(
          type: TokenType.string,
          lexeme: '"$veryLongName"',
          position: SourcePosition(line: 1, column: 1),
          value: veryLongName,
        ),
      ];
      
      final result = elementParser._parseIdentifier(tokens);
      
      expect(result, equals(veryLongName));
      expect(result.length, equals(500));
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should handle Unicode characters in identifiers', () {
      final tokens = [
        Token(
          type: TokenType.string,
          lexeme: '"Café☕System"',
          position: SourcePosition(line: 1, column: 1),
          value: 'Café☕System',
        ),
      ];
      
      final result = elementParser._parseIdentifier(tokens);
      
      expect(result, equals('Café☕System'));
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should report accurate error position for invalid identifier', () {
      final tokens = [
        Token(
          type: TokenType.number,
          lexeme: '123',
          position: SourcePosition(line: 10, column: 5, offset: 100),
        ),
      ];
      
      try {
        elementParser._parseIdentifier(tokens);
        fail('Expected ParseError');
      } catch (e) {
        expect(e, isA<ParseError>());
        expect((e as ParseError).position?.line, equals(10));
        expect(e.position?.column, equals(5));
        expect(e.position?.offset, equals(100));
        expect(errorReporter.hasErrors, isTrue);
      }
    });

    test('should handle identifier token with specific lexeme', () {
      final tokens = [
        Token(
          type: TokenType.identifier,
          lexeme: 'CustomIdentifier',
          position: SourcePosition(line: 1, column: 1),
        ),
      ];
      
      final result = elementParser._parseIdentifier(tokens);
      
      expect(result, equals('CustomIdentifier'));
      expect(errorReporter.hasErrors, isFalse);
    });
  });
  
  group('ElementParser._parseParentChild() detailed tests', () {
    test('should handle empty block gracefully', () {
      final tokens = [
        Token(
          type: TokenType.leftBrace,
          lexeme: '{',
          position: SourcePosition(line: 1, column: 1),
        ),
        Token(
          type: TokenType.rightBrace,
          lexeme: '}',
          position: SourcePosition(line: 2, column: 1),
        ),
      ];
      
      // Set up context for test
      final person = PersonNode(id: 'testPerson', name: 'Test Person');
      contextStack.push(Context('person', data: {'currentElement': person}));
      
      elementParser._parseParentChild(tokens);
      
      expect(errorReporter.hasErrors, isFalse);
      contextStack.pop();
    });

    test('should handle complex property assignments', () {
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
          lexeme: '"This is a multi-line\ndescription with special chars: @#$%^&*"',
          position: SourcePosition(line: 1, column: 14),
          value: 'This is a multi-line\ndescription with special chars: @#$%^&*',
        ),
      ];
      
      // Set up context for test
      final person = PersonNode(id: 'testPerson', name: 'Test Person');
      contextStack.push(Context('person', data: {'currentElement': person}));
      
      elementParser._parseParentChild(tokens);
      
      // In real implementation, verify description is set on person
      expect(errorReporter.hasErrors, isFalse);
      contextStack.pop();
    });

    test('should handle multiple property assignments', () {
      final tokens = [
        // First property
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
          lexeme: '"A description"',
          position: SourcePosition(line: 1, column: 14),
          value: 'A description',
        ),
        // Second property
        Token(
          type: TokenType.identifier,
          lexeme: 'tags',
          position: SourcePosition(line: 2, column: 1),
        ),
        Token(
          type: TokenType.equals,
          lexeme: '=',
          position: SourcePosition(line: 2, column: 6),
        ),
        Token(
          type: TokenType.string,
          lexeme: '"tag1,tag2"',
          position: SourcePosition(line: 2, column: 8),
          value: 'tag1,tag2',
        ),
        // Third property
        Token(
          type: TokenType.identifier,
          lexeme: 'url',
          position: SourcePosition(line: 3, column: 1),
        ),
        Token(
          type: TokenType.equals,
          lexeme: '=',
          position: SourcePosition(line: 3, column: 5),
        ),
        Token(
          type: TokenType.string,
          lexeme: '"https://example.com"',
          position: SourcePosition(line: 3, column: 7),
          value: 'https://example.com',
        ),
      ];
      
      // Set up context for test
      final person = PersonNode(id: 'testPerson', name: 'Test Person');
      contextStack.push(Context('person', data: {'currentElement': person}));
      
      elementParser._parseParentChild(tokens);
      
      // In real implementation, verify all properties are set on person
      expect(errorReporter.hasErrors, isFalse);
      contextStack.pop();
    });

    test('should handle nested container elements', () {
      final tokens = [
        Token(
          type: TokenType.container,
          lexeme: 'container',
          position: SourcePosition(line: 1, column: 1),
        ),
        Token(
          type: TokenType.string,
          lexeme: '"Database"',
          position: SourcePosition(line: 1, column: 10),
          value: 'Database',
        ),
        Token(
          type: TokenType.string,
          lexeme: '"Stores data"',
          position: SourcePosition(line: 1, column: 21),
          value: 'Stores data',
        ),
        Token(
          type: TokenType.string,
          lexeme: '"PostgreSQL"',
          position: SourcePosition(line: 1, column: 34),
          value: 'PostgreSQL',
        ),
      ];
      
      // Set up context for test
      final softwareSystem = SoftwareSystemNode(id: 'TestSystem', name: 'Test System');
      contextStack.push(Context('softwareSystem', data: {'currentElement': softwareSystem}));
      
      elementParser._parseParentChild(tokens);
      
      // Verify container was created via mock model parser
      expect(mockModelParser.createdElements.length, equals(1));
      expect(mockModelParser.createdElements[0], isA<ContainerNode>());
      expect(mockModelParser.createdElements[0].name, equals('Database'));
      expect(errorReporter.hasErrors, isFalse);
      
      contextStack.pop();
    });

    test('should handle relationship definitions', () {
      final tokens = [
        Token(
          type: TokenType.identifier,
          lexeme: 'Frontend',
          position: SourcePosition(line: 1, column: 1),
        ),
        Token(
          type: TokenType.arrow,
          lexeme: '->',
          position: SourcePosition(line: 1, column: 10),
        ),
        Token(
          type: TokenType.identifier,
          lexeme: 'Backend',
          position: SourcePosition(line: 1, column: 13),
        ),
        Token(
          type: TokenType.string,
          lexeme: '"Makes API calls"',
          position: SourcePosition(line: 1, column: 21),
          value: 'Makes API calls',
        ),
      ];
      
      // Set up context for test
      final softwareSystem = SoftwareSystemNode(id: 'TestSystem', name: 'Test System');
      contextStack.push(Context('softwareSystem', data: {'currentElement': softwareSystem}));
      
      elementParser._parseParentChild(tokens);
      
      // Verify relationship was created via mock relationship parser
      expect(mockRelationshipParser.createdRelationships.length, equals(1));
      expect(mockRelationshipParser.createdRelationships[0].sourceId, equals('Frontend'));
      expect(mockRelationshipParser.createdRelationships[0].destinationId, equals('Backend'));
      expect(mockRelationshipParser.createdRelationships[0].description, equals('Makes API calls'));
      expect(errorReporter.hasErrors, isFalse);
      
      contextStack.pop();
    });

    test('should handle missing current element gracefully', () {
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
          lexeme: '"A description"',
          position: SourcePosition(line: 1, column: 14),
          value: 'A description',
        ),
      ];
      
      // Create context without current element
      contextStack.push(Context('person'));
      
      expect(() => elementParser._parseParentChild(tokens), 
        throwsA(isA<ParseError>().having(
          (e) => e.message, 
          'message', 
          contains('No current element')
        ))
      );
      
      contextStack.pop();
    });

    test('should handle malformed property assignments', () {
      final tokens = [
        Token(
          type: TokenType.identifier,
          lexeme: 'description',
          position: SourcePosition(line: 1, column: 1),
        ),
        // Missing equals token
        Token(
          type: TokenType.string,
          lexeme: '"A description"',
          position: SourcePosition(line: 1, column: 14),
          value: 'A description',
        ),
      ];
      
      // Set up context for test
      final person = PersonNode(id: 'testPerson', name: 'Test Person');
      contextStack.push(Context('person', data: {'currentElement': person}));
      
      elementParser._parseParentChild(tokens);
      
      // Should skip the malformed property assignment
      contextStack.pop();
    });

    test('should handle nested blocks with different depths', () {
      // Create complex nested tokens with containers and relationships
      final tokens = lexer.tokenize('''
        container "Database" "Stores data" "PostgreSQL" {
          description = "PostgreSQL database server"
          tags = "database,sql"
        }
        container "WebServer" "Serves web content" "Nginx" {
          description = "Web server"
          container "API" "Provides REST API" "Node.js"
        }
        Database -> WebServer "Sends data to"
      ''');
      
      // Set up context for test
      final softwareSystem = SoftwareSystemNode(id: 'TestSystem', name: 'Test System');
      contextStack.push(Context('softwareSystem', data: {'currentElement': softwareSystem}));
      
      elementParser._parseParentChild(tokens);
      
      // Verify nested elements were created
      expect(mockModelParser.createdElements.length, greaterThan(1));
      expect(mockRelationshipParser.createdRelationships.length, equals(1));
      expect(errorReporter.hasErrors, isFalse);
      
      contextStack.pop();
    });

    test('should maintain context stack integrity during errors', () {
      final tokens = lexer.tokenize('''
        description = "Test description"
        missingEquals "This will cause an error"
        container "Database" {
          # Nested context that should be properly handled
        }
      ''');
      
      // Set up context for test and track stack depth
      final person = PersonNode(id: 'testPerson', name: 'Test Person');
      contextStack.push(Context('person', data: {'currentElement': person}));
      final initialDepth = contextStack.size();
      
      // Should not crash even with errors
      elementParser._parseParentChild(tokens);
      
      // Ensure context stack is maintained
      expect(contextStack.size(), equals(initialDepth));
      contextStack.pop();
    });
  });

  group('ElementParser.parsePerson() detailed tests', () {
    test('should parse person with minimal information', () {
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
      
      final result = elementParser.parsePerson(tokens);
      
      expect(result, isA<PersonNode>());
      expect(result.name, equals('User'));
      expect(result.description, isNull);
      expect(result.tags, isNull);
      expect(result.id, equals('User'));
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should parse person with name and description', () {
      final tokens = [
        Token(
          type: TokenType.person,
          lexeme: 'person',
          position: SourcePosition(line: 1, column: 1),
        ),
        Token(
          type: TokenType.string,
          lexeme: '"Administrator"',
          position: SourcePosition(line: 1, column: 8),
          value: 'Administrator',
        ),
        Token(
          type: TokenType.string,
          lexeme: '"System administrator responsible for maintenance"',
          position: SourcePosition(line: 1, column: 22),
          value: 'System administrator responsible for maintenance',
        ),
      ];
      
      final result = elementParser.parsePerson(tokens);
      
      expect(result, isA<PersonNode>());
      expect(result.name, equals('Administrator'));
      expect(result.properties?['description'], equals('System administrator responsible for maintenance'));
      expect(result.tags, isNull);
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should parse person with all attributes', () {
      final tokens = [
        Token(
          type: TokenType.person,
          lexeme: 'person',
          position: SourcePosition(line: 1, column: 1),
        ),
        Token(
          type: TokenType.string,
          lexeme: '"Support Staff"',
          position: SourcePosition(line: 1, column: 8),
          value: 'Support Staff',
        ),
        Token(
          type: TokenType.string,
          lexeme: '"Provides technical support to customers"',
          position: SourcePosition(line: 1, column: 23),
          value: 'Provides technical support to customers',
        ),
        Token(
          type: TokenType.string,
          lexeme: '"internal,support,technical"',
          position: SourcePosition(line: 1, column: 63),
          value: 'internal,support,technical',
        ),
      ];
      
      final result = elementParser.parsePerson(tokens);
      
      expect(result, isA<PersonNode>());
      expect(result.name, equals('Support Staff'));
      expect(result.properties?['description'], equals('Provides technical support to customers'));
      expect(result.properties?['tags'], equals('internal,support,technical'));
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should create person with proper identifier from name', () {
      final tokens = [
        Token(
          type: TokenType.person,
          lexeme: 'person',
          position: SourcePosition(line: 1, column: 1),
        ),
        Token(
          type: TokenType.string,
          lexeme: '"Customer Service Agent"',
          position: SourcePosition(line: 1, column: 8),
          value: 'Customer Service Agent',
        ),
      ];
      
      final result = elementParser.parsePerson(tokens);
      
      expect(result, isA<PersonNode>());
      expect(result.name, equals('Customer Service Agent'));
      expect(result.id, equals('CustomerServiceAgent'));
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should parse person with block content', () {
      final tokens = lexer.tokenize('''
        person "Security Officer" {
          description = "Responsible for system security"
          tags = "internal,security,officer"
          url = "https://example.com/security"
        }
      ''');
      
      final result = elementParser.parsePerson(tokens);
      
      expect(result, isA<PersonNode>());
      expect(result.name, equals('Security Officer'));
      expect(result.id, equals('SecurityOfficer'));
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should handle person with unicode characters in name', () {
      final tokens = lexer.tokenize('person "Café Manager" "Manages the café"');
      
      final result = elementParser.parsePerson(tokens);
      
      expect(result, isA<PersonNode>());
      expect(result.name, equals('Café Manager'));
      expect(result.properties?['description'], equals('Manages the café'));
      expect(result.id, equals('CaféManager'));
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should handle person with empty name properly', () {
      final tokens = [
        Token(
          type: TokenType.person,
          lexeme: 'person',
          position: SourcePosition(line: 1, column: 1),
        ),
        Token(
          type: TokenType.string,
          lexeme: '""',
          position: SourcePosition(line: 1, column: 8),
          value: '',
        ),
      ];
      
      expect(() => elementParser.parsePerson(tokens),
        throwsA(isA<ParseError>().having(
          (e) => e.message,
          'message',
          contains('Empty identifier')
        ))
      );
    });

    test('should maintain context stack integrity during errors', () {
      final initialSize = contextStack.size();
      
      // Create tokens with an error
      final tokens = [
        Token(
          type: TokenType.person,
          lexeme: 'person',
          position: SourcePosition(line: 1, column: 1),
        ),
        // Missing name string
      ];
      
      expect(() => elementParser.parsePerson(tokens), throwsA(isA<ParseError>()));
      
      // Context stack should be restored properly after error
      expect(contextStack.size(), equals(initialSize));
    });

    test('should maintain context stack integrity with unclosed braces', () {
      final initialSize = contextStack.size();
      
      // Create tokens with unclosed braces
      final tokens = lexer.tokenize('''
        person "Administrator" {
          description = "System administrator"
          // Missing closing brace
      ''');
      
      expect(() => elementParser.parsePerson(tokens), throwsA(isA<ParseError>()));
      
      // Context stack should be restored properly after error
      expect(contextStack.size(), equals(initialSize));
    });

    test('should handle too many tokens gracefully', () {
      final tokens = lexer.tokenize(
        'person "User" "A user" "user,external" "extra" "more extra"'
      );
      
      // Should parse correctly but ignore extra tokens
      elementParser.parsePerson(tokens);
      
      // Should at least report a warning
      expect(errorReporter.hasWarnings, isTrue);
    });
  });

  group('ElementParser.parseSoftwareSystem() detailed tests', () {
    test('should parse software system with minimal information', () {
      final tokens = [
        Token(
          type: TokenType.softwareSystem,
          lexeme: 'softwareSystem',
          position: SourcePosition(line: 1, column: 1),
        ),
        Token(
          type: TokenType.string,
          lexeme: '"Billing System"',
          position: SourcePosition(line: 1, column: 15),
          value: 'Billing System',
        ),
      ];
      
      final result = elementParser.parseSoftwareSystem(tokens);
      
      expect(result, isA<SoftwareSystemNode>());
      expect(result.name, equals('Billing System'));
      expect(result.description, isNull);
      expect(result.tags, isNull);
      expect(result.id, equals('BillingSystem'));
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should parse software system with name and description', () {
      final tokens = [
        Token(
          type: TokenType.softwareSystem,
          lexeme: 'softwareSystem',
          position: SourcePosition(line: 1, column: 1),
        ),
        Token(
          type: TokenType.string,
          lexeme: '"Payment Gateway"',
          position: SourcePosition(line: 1, column: 15),
          value: 'Payment Gateway',
        ),
        Token(
          type: TokenType.string,
          lexeme: '"Handles all payment processing"',
          position: SourcePosition(line: 1, column: 32),
          value: 'Handles all payment processing',
        ),
      ];
      
      final result = elementParser.parseSoftwareSystem(tokens);
      
      expect(result, isA<SoftwareSystemNode>());
      expect(result.name, equals('Payment Gateway'));
      expect(result.properties?['description'], equals('Handles all payment processing'));
      expect(result.tags, isNull);
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should parse software system with all attributes', () {
      final tokens = [
        Token(
          type: TokenType.softwareSystem,
          lexeme: 'softwareSystem',
          position: SourcePosition(line: 1, column: 1),
        ),
        Token(
          type: TokenType.string,
          lexeme: '"CRM System"',
          position: SourcePosition(line: 1, column: 15),
          value: 'CRM System',
        ),
        Token(
          type: TokenType.string,
          lexeme: '"Customer Relationship Management System"',
          position: SourcePosition(line: 1, column: 27),
          value: 'Customer Relationship Management System',
        ),
        Token(
          type: TokenType.string,
          lexeme: '"internal,crm,core"',
          position: SourcePosition(line: 1, column: 67),
          value: 'internal,crm,core',
        ),
      ];
      
      final result = elementParser.parseSoftwareSystem(tokens);
      
      expect(result, isA<SoftwareSystemNode>());
      expect(result.name, equals('CRM System'));
      expect(result.properties?['description'], equals('Customer Relationship Management System'));
      expect(result.properties?['tags'], equals('internal,crm,core'));
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should create software system with proper identifier from name', () {
      final tokens = [
        Token(
          type: TokenType.softwareSystem,
          lexeme: 'softwareSystem',
          position: SourcePosition(line: 1, column: 1),
        ),
        Token(
          type: TokenType.string,
          lexeme: '"Internal Messaging Service"',
          position: SourcePosition(line: 1, column: 15),
          value: 'Internal Messaging Service',
        ),
      ];
      
      final result = elementParser.parseSoftwareSystem(tokens);
      
      expect(result, isA<SoftwareSystemNode>());
      expect(result.name, equals('Internal Messaging Service'));
      expect(result.id, equals('InternalMessagingService'));
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should parse software system with block content and containers', () {
      final tokens = lexer.tokenize('''
        softwareSystem "E-Commerce Platform" {
          description = "Online shopping platform"
          tags = "web,ecommerce,core"
          
          container "Web Application" "User-facing web interface" "React,TypeScript"
          container "API Gateway" "API entry point" "Node.js"
          container "Database" "Stores product and order data" "PostgreSQL"
        }
      ''');
      
      final result = elementParser.parseSoftwareSystem(tokens);
      
      expect(result, isA<SoftwareSystemNode>());
      expect(result.name, equals('E-Commerce Platform'));
      expect(mockModelParser.createdElements.length, equals(3));
      expect(mockModelParser.createdElements[0].name, equals('Web Application'));
      expect(mockModelParser.createdElements[1].name, equals('API Gateway'));
      expect(mockModelParser.createdElements[2].name, equals('Database'));
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should parse software system with block content and relationships', () {
      final tokens = lexer.tokenize('''
        softwareSystem "Microservice Architecture" {
          container "Order Service" "Handles orders" "Spring Boot"
          container "User Service" "Manages users" "Spring Boot"
          container "Notification Service" "Sends notifications" "Node.js"
          
          OrderService -> UserService "Fetches user details"
          OrderService -> NotificationService "Sends order notifications"
        }
      ''');
      
      final result = elementParser.parseSoftwareSystem(tokens);
      
      expect(result, isA<SoftwareSystemNode>());
      expect(result.name, equals('Microservice Architecture'));
      expect(mockModelParser.createdElements.length, equals(3));
      expect(mockRelationshipParser.createdRelationships.length, equals(2));
      expect(mockRelationshipParser.createdRelationships[0].sourceId, equals('OrderService'));
      expect(mockRelationshipParser.createdRelationships[0].destinationId, equals('UserService'));
      expect(mockRelationshipParser.createdRelationships[1].sourceId, equals('OrderService'));
      expect(mockRelationshipParser.createdRelationships[1].destinationId, equals('NotificationService'));
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should handle software system with unicode characters in name', () {
      final tokens = lexer.tokenize('softwareSystem "München City Portal" "City services portal"');
      
      final result = elementParser.parseSoftwareSystem(tokens);
      
      expect(result, isA<SoftwareSystemNode>());
      expect(result.name, equals('München City Portal'));
      expect(result.properties?['description'], equals('City services portal'));
      expect(result.id, equals('MünchenCityPortal'));
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should handle software system with empty name properly', () {
      final tokens = [
        Token(
          type: TokenType.softwareSystem,
          lexeme: 'softwareSystem',
          position: SourcePosition(line: 1, column: 1),
        ),
        Token(
          type: TokenType.string,
          lexeme: '""',
          position: SourcePosition(line: 1, column: 15),
          value: '',
        ),
      ];
      
      expect(() => elementParser.parseSoftwareSystem(tokens),
        throwsA(isA<ParseError>().having(
          (e) => e.message,
          'message',
          contains('Empty identifier')
        ))
      );
    });

    test('should maintain context stack integrity during software system errors', () {
      final initialSize = contextStack.size();
      
      // Create tokens with an error
      final tokens = [
        Token(
          type: TokenType.softwareSystem,
          lexeme: 'softwareSystem',
          position: SourcePosition(line: 1, column: 1),
        ),
        // Missing name string
      ];
      
      expect(() => elementParser.parseSoftwareSystem(tokens), throwsA(isA<ParseError>()));
      
      // Context stack should be restored properly after error
      expect(contextStack.size(), equals(initialSize));
    });

    test('should maintain context stack integrity with unclosed software system braces', () {
      final initialSize = contextStack.size();
      
      // Create tokens with unclosed braces
      final tokens = lexer.tokenize('''
        softwareSystem "Authentication Service" {
          description = "Handles user authentication"
          // Missing closing brace
      ''');
      
      expect(() => elementParser.parseSoftwareSystem(tokens), throwsA(isA<ParseError>()));
      
      // Context stack should be restored properly after error
      expect(contextStack.size(), equals(initialSize));
    });

    test('should handle deeply nested software system structure', () {
      final tokens = lexer.tokenize('''
        softwareSystem "Complex System" {
          container "Frontend" "User interface" "React" {
            component "LoginComponent" "Handles user login" "React Hooks"
            component "DashboardComponent" "Main dashboard" "React Hooks"
          }
          container "Backend" "API layer" "Spring Boot" {
            component "AuthController" "Authentication endpoints" "Java"
            component "UserController" "User management endpoints" "Java"
          }
          container "Database" "Data storage" "PostgreSQL"
        }
      ''');
      
      final result = elementParser.parseSoftwareSystem(tokens);
      
      expect(result, isA<SoftwareSystemNode>());
      expect(result.name, equals('Complex System'));
      // This would test that containers and their nested components are handled
      // but our mock implementation doesn't capture the complete structure
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should handle properties with special characters in software system', () {
      final tokens = lexer.tokenize('''
        softwareSystem "Security System" {
          description = "System with \\"quoted\\" text and special chars: @#$%^&*"
          url = "https://example.com/security?param=value&other=123"
        }
      ''');
      
      final result = elementParser.parseSoftwareSystem(tokens);
      
      expect(result, isA<SoftwareSystemNode>());
      expect(result.name, equals('Security System'));
      // In a real implementation, verify the escaped quotes are properly handled
      expect(errorReporter.hasErrors, isFalse);
    });
  });
  
  group('Integration tests with lexer', () {
    test('should parse complete DSL with person and software system', () {
      final dsl = '''
        person "User" "A system user" "external,user" {
          url = "https://example.com/user"
        }
        
        softwareSystem "Payment Processing" "Handles payments" {
          description = "Processes all payment types"
          tags = "payment,core"
          
          container "Payment Gateway" "Integrates with payment providers" "Java"
          container "Transaction Database" "Stores transaction data" "MongoDB"
          
          PaymentGateway -> TransactionDatabase "Stores transaction data in"
        }
        
        User -> PaymentProcessing "Makes payments using"
      ''';
      
      final tokens = lexer.tokenize(dsl);
      
      // Split tokens for person and software system
      int softwareSystemIndex = -1;
      for (int i = 0; i < tokens.length; i++) {
        if (tokens[i].type == TokenType.softwareSystem) {
          softwareSystemIndex = i;
          break;
        }
      }
      
      final personTokens = tokens.sublist(0, softwareSystemIndex);
      final softwareSystemTokens = tokens.sublist(softwareSystemIndex);
      
      // Parse both elements
      final person = elementParser.parsePerson(personTokens);
      final softwareSystem = elementParser.parseSoftwareSystem(softwareSystemTokens);
      
      // Verify results
      expect(person, isA<PersonNode>());
      expect(person.name, equals('User'));
      expect(person.properties?['description'], equals('A system user'));
      
      expect(softwareSystem, isA<SoftwareSystemNode>());
      expect(softwareSystem.name, equals('Payment Processing'));
      expect(softwareSystem.properties?['description'], equals('Processes all payment types'));
      
      expect(mockModelParser.createdElements.length, greaterThan(0));
      expect(mockRelationshipParser.createdRelationships.length, greaterThan(0));
      expect(errorReporter.hasErrors, isFalse);
    });
  });
}