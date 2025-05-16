import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/parser/lexer/token.dart';
import 'package:flutter_structurizr/domain/parser/lexer/lexer.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/parser/ast/ast_nodes.dart';
import 'package:flutter_structurizr/domain/parser/context_stack.dart';
import 'package:flutter_structurizr/domain/parser/element_parser.dart';
import 'package:flutter_structurizr/domain/parser/model_parser.dart';
import 'package:flutter_structurizr/domain/parser/relationship_parser.dart';

/// Comprehensive mock model parser that can handle nested containers and components
class DetailedMockModelParser implements ModelParser {
  final List<ModelElementNode> createdElements = [];
  final Map<String, List<ModelElementNode>> childrenByParent = {};
  final ContextStack contextStack;
  
  DetailedMockModelParser(this.contextStack);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName.toString() == 'Symbol("_parseNestedElement")') {
      final tokens = invocation.positionalArguments[0] as List<Token>;
      
      if (tokens.isEmpty) return null;
      
      // Get current context
      final currentContext = contextStack.current();
      final parentElement = currentContext.data['currentElement'] as ModelElementNode?;
      if (parentElement == null) return null;
      
      if (tokens[0].lexeme == 'container' && tokens.length >= 2) {
        // Parse container
        final name = tokens[1].value as String? ?? tokens[1].lexeme.replaceAll('"', '');
        final containerId = name.replaceAll(' ', '');
        
        final container = ContainerNode(
          id: containerId,
          parentId: parentElement.id,
          name: name,
          description: tokens.length > 2 && tokens[2].type == TokenType.string 
              ? tokens[2].value as String?
              : null,
        );
        
        createdElements.add(container);
        
        // Check for block to parse children
        int blockStartIndex = -1;
        for (int i = 2; i < tokens.length; i++) {
          if (tokens[i].type == TokenType.leftBrace) {
            blockStartIndex = i;
            break;
          }
        }
        
        if (blockStartIndex != -1) {
          // Find matching right brace
          int blockEnd = blockStartIndex + 1;
          int braceCount = 1;
          
          while (blockEnd < tokens.length && braceCount > 0) {
            if (tokens[blockEnd].type == TokenType.leftBrace) {
              braceCount++;
            } else if (tokens[blockEnd].type == TokenType.rightBrace) {
              braceCount--;
            }
            
            if (braceCount > 0) {
              blockEnd++;
            }
          }
          
          if (braceCount == 0) {
            // Process container block - in a real parser, this would parse components
            // For mock, just add to children map
            childrenByParent[containerId] = [];
          }
        }
        
        return container;
      } else if (tokens[0].lexeme == 'component' && tokens.length >= 2) {
        // Parse component
        final name = tokens[1].value as String? ?? tokens[1].lexeme.replaceAll('"', '');
        final componentId = name.replaceAll(' ', '');
        
        final component = ComponentNode(
          id: componentId,
          parentId: parentElement.id,
          name: name,
          description: tokens.length > 2 && tokens[2].type == TokenType.string 
              ? tokens[2].value as String?
              : null,
        );
        
        createdElements.add(component);
        
        // Add to parent's children
        final children = childrenByParent[parentElement.id] ?? [];
        children.add(component);
        childrenByParent[parentElement.id] = children;
        
        return component;
      }
    }
    
    return null;
  }
}

/// Comprehensive mock relationship parser
class DetailedMockRelationshipParser implements RelationshipParser {
  final List<RelationshipNode> createdRelationships = [];
  bool shouldFailNextParse = false;
  
  @override
  RelationshipNode? parse(List<Token> tokens) {
    if (shouldFailNextParse) {
      shouldFailNextParse = false;
      throw Exception('Simulated relationship parsing failure');
    }
    
    if (tokens.length >= 3 && tokens[1].type == TokenType.arrow) {
      final source = tokens[0].lexeme;
      final destination = tokens[2].lexeme;
      
      final description = tokens.length > 3 && tokens[3].type == TokenType.string
          ? tokens[3].value as String?
          : null;
          
      final technology = tokens.length > 4 && tokens[4].type == TokenType.string
          ? tokens[4].value as String?
          : null;
      
      final relationship = RelationshipNode(
        sourceId: source,
        destinationId: destination,
        description: description,
        technology: technology
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
  late DetailedMockModelParser detailedMockModelParser;
  late DetailedMockRelationshipParser detailedMockRelationshipParser;
  late Lexer lexer;

  setUp(() {
    errorReporter = ErrorReporter();
    contextStack = ContextStack();
    detailedMockModelParser = DetailedMockModelParser(contextStack);
    detailedMockRelationshipParser = DetailedMockRelationshipParser();
    
    elementParser = ElementParser(
      errorReporter,
      contextStack: contextStack,
      modelParser: detailedMockModelParser,
      relationshipParser: detailedMockRelationshipParser
    );
    
    lexer = Lexer();
  });
  
  group('ElementParser complex integration tests', () {
    test('should parse complex software system with multiple containers and relationships', () {
      final tokens = lexer.tokenize('''
        softwareSystem "E-Commerce System" {
          description = "Online shopping platform"
          
          container "Web Application" "User-facing web interface" "React,TypeScript" {
            component "Login Form" "User authentication UI" "React" 
            component "Product Catalog" "Displays products" "React"
            component "Shopping Cart" "Manages cart items" "React"
          }
          
          container "API Gateway" "API entry point" "Node.js" {
            component "Auth Controller" "Handles authentication" "Express"
            component "Product Controller" "Product management" "Express"
            component "Order Controller" "Order processing" "Express"
          }
          
          container "Database" "Stores product and order data" "PostgreSQL"
          
          WebApplication -> APIGateway "Makes API calls using" "JSON/HTTPS"
          APIGateway -> Database "Reads from and writes to" "SQL"
        }
      ''');
      
      final result = elementParser.parseSoftwareSystem(tokens);
      
      expect(result, isA<SoftwareSystemNode>());
      expect(result.name, equals('E-Commerce System'));
      expect(result.properties?['description'], equals('Online shopping platform'));
      
      // Verify all containers were created
      expect(detailedMockModelParser.createdElements.length, equals(9)); // 3 containers + 6 components
      
      // Verify containers
      final containers = detailedMockModelParser.createdElements.whereType<ContainerNode>().toList();
      expect(containers.length, equals(3));
      expect(containers[0].name, equals('Web Application'));
      expect(containers[1].name, equals('API Gateway'));
      expect(containers[2].name, equals('Database'));
      
      // Verify components (in a real implementation)
      // This would verify the component structure and hierarchy
      
      // Verify relationships
      expect(detailedMockRelationshipParser.createdRelationships.length, equals(2));
      expect(detailedMockRelationshipParser.createdRelationships[0].sourceId, equals('WebApplication'));
      expect(detailedMockRelationshipParser.createdRelationships[0].destinationId, equals('APIGateway'));
      expect(detailedMockRelationshipParser.createdRelationships[0].description, equals('Makes API calls using'));
      expect(detailedMockRelationshipParser.createdRelationships[0].technology, equals('JSON/HTTPS'));
      
      expect(detailedMockRelationshipParser.createdRelationships[1].sourceId, equals('APIGateway'));
      expect(detailedMockRelationshipParser.createdRelationships[1].destinationId, equals('Database'));
      expect(detailedMockRelationshipParser.createdRelationships[1].description, equals('Reads from and writes to'));
      expect(detailedMockRelationshipParser.createdRelationships[1].technology, equals('SQL'));
      
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should handle relationship parsing failures gracefully', () {
      // Set the relationship parser to fail on the next parse
      detailedMockRelationshipParser.shouldFailNextParse = true;
      
      final tokens = lexer.tokenize('''
        softwareSystem "System" {
          container "Frontend" "UI" "React"
          container "Backend" "API" "Node.js"
          
          Frontend -> Backend "Makes API calls"
        }
      ''');
      
      // Should handle relationship parsing error
      elementParser.parseSoftwareSystem(tokens);
      
      // Verify error was reported
      expect(errorReporter.hasErrors, isTrue);
      
      // Still should have parsed containers
      expect(detailedMockModelParser.createdElements.length, equals(2));
    });

    test('should handle system with international characters in names and descriptions', () {
      final tokens = lexer.tokenize('''
        softwareSystem "Système de Réservation" {
          description = "Système de réservation d'hôtels et vols"
          
          container "Interface Utilisateur" "Interface pour les réservations" "Vue.js"
          container "Service API" "API pour les réservations" "Node.js"
          container "Base de Données" "Stockage des réservations" "PostgreSQL"
          
          InterfaceUtilisateur -> ServiceAPI "Fait des appels API"
          ServiceAPI -> BasedeDonnées "Lit et écrit des données"
        }
      ''');
      
      final result = elementParser.parseSoftwareSystem(tokens);
      
      expect(result, isA<SoftwareSystemNode>());
      expect(result.name, equals('Système de Réservation'));
      expect(result.properties?['description'], equals("Système de réservation d'hôtels et vols"));
      
      // Verify containers with international characters
      expect(detailedMockModelParser.createdElements.length, equals(3));
      expect(detailedMockModelParser.createdElements[0].name, equals('Interface Utilisateur'));
      expect(detailedMockModelParser.createdElements[1].name, equals('Service API'));
      expect(detailedMockModelParser.createdElements[2].name, equals('Base de Données'));
      
      // Verify relationships with international characters
      expect(detailedMockRelationshipParser.createdRelationships.length, equals(2));
      expect(detailedMockRelationshipParser.createdRelationships[0].sourceId, equals('InterfaceUtilisateur'));
      expect(detailedMockRelationshipParser.createdRelationships[0].destinationId, equals('ServiceAPI'));
      expect(detailedMockRelationshipParser.createdRelationships[0].description, equals('Fait des appels API'));
      
      expect(detailedMockRelationshipParser.createdRelationships[1].sourceId, equals('ServiceAPI'));
      expect(detailedMockRelationshipParser.createdRelationships[1].destinationId, equals('BasedeDonnées'));
      expect(detailedMockRelationshipParser.createdRelationships[1].description, equals('Lit et écrit des données'));
      
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should handle relationships with property blocks', () {
      final tokens = lexer.tokenize('''
        softwareSystem "System" {
          container "Frontend" "UI" "React"
          container "Backend" "API" "Node.js"
          
          Frontend -> Backend "Makes API calls" {
            tags = "rest,json,https"
            technology = "REST/HTTPS"
            url = "https://api.example.com"
          }
        }
      ''');
      
      elementParser.parseSoftwareSystem(tokens);
      
      // Verify containers
      expect(detailedMockModelParser.createdElements.length, equals(2));
      
      // Verify relationship with properties
      expect(detailedMockRelationshipParser.createdRelationships.length, equals(1));
      expect(detailedMockRelationshipParser.createdRelationships[0].sourceId, equals('Frontend'));
      expect(detailedMockRelationshipParser.createdRelationships[0].destinationId, equals('Backend'));
      expect(detailedMockRelationshipParser.createdRelationships[0].description, equals('Makes API calls'));
      
      // In a real implementation, relationship properties would be verified here
      
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should handle complex multi-level relationships properly', () {
      final tokens = lexer.tokenize('''
        softwareSystem "System" {
          container "Frontend" {
            component "LoginComponent" "Handles login"
            component "DashboardComponent" "Shows dashboard"
          }
          
          container "Backend" {
            component "AuthService" "Authentication service"
            component "DataService" "Data service"
          }
          
          LoginComponent -> AuthService "Authenticates users"
          DashboardComponent -> DataService "Fetches data"
        }
      ''');
      
      elementParser.parseSoftwareSystem(tokens);
      
      // Verify elements
      expect(detailedMockModelParser.createdElements.length, equals(6)); // 2 containers + 4 components
      
      // Verify relationships
      expect(detailedMockRelationshipParser.createdRelationships.length, equals(2));
      expect(detailedMockRelationshipParser.createdRelationships[0].sourceId, equals('LoginComponent'));
      expect(detailedMockRelationshipParser.createdRelationships[0].destinationId, equals('AuthService'));
      
      expect(detailedMockRelationshipParser.createdRelationships[1].sourceId, equals('DashboardComponent'));
      expect(detailedMockRelationshipParser.createdRelationships[1].destinationId, equals('DataService'));
      
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should handle properties with complex values', () {
      final tokens = lexer.tokenize('''
        softwareSystem "DocumentSystem" {
          description = "Document management system with complex property values"
          
          container "Frontend" {
            description = "A description with special chars: !@#$%^&*()_+-=[]{}|;:'\\",./<>?"
            url = "https://example.com/docs?id=123&format=pdf#section"
            tags = "ui,web,frontend,responsive,interactive"
          }
        }
      ''');
      
      final result = elementParser.parseSoftwareSystem(tokens);
      
      expect(result, isA<SoftwareSystemNode>());
      expect(result.name, equals('DocumentSystem'));
      
      // Verify container with complex properties
      expect(detailedMockModelParser.createdElements.length, equals(1));
      expect(detailedMockModelParser.createdElements[0].name, equals('Frontend'));
      
      // In a real implementation, would verify properties were set correctly
      
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should handle large system with many elements', () {
      // Generate a large system with many containers
      final StringBuilder = StringBuffer();
      StringBuilder.writeln('softwareSystem "Large System" {');
      StringBuilder.writeln('  description = "A large system with many elements"');
      
      // Add 20 containers
      for (int i = 1; i <= 20; i++) {
        StringBuilder.writeln('  container "Container$i" "Description for Container$i" "Tech$i"');
      }
      
      // Add some relationships
      StringBuilder.writeln('  Container1 -> Container2 "Uses"');
      StringBuilder.writeln('  Container2 -> Container3 "Depends on"');
      StringBuilder.writeln('  Container4 -> Container5 "Communicates with"');
      
      StringBuilder.writeln('}');
      
      final tokens = lexer.tokenize(StringBuilder.toString());
      
      // Should parse without errors
      final result = elementParser.parseSoftwareSystem(tokens);
      
      expect(result, isA<SoftwareSystemNode>());
      expect(result.name, equals('Large System'));
      
      // Verify all containers were created
      expect(detailedMockModelParser.createdElements.length, equals(20));
      
      // Verify relationships
      expect(detailedMockRelationshipParser.createdRelationships.length, equals(3));
      
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should handle deeply nested elements with components and relationships', () {
      final tokens = lexer.tokenize('''
        softwareSystem "DeepSystem" {
          container "FrontendContainer" {
            component "HeaderComponent" "Header UI" "React"
            component "MainComponent" "Main content" "React" {
              # In a real parser, this might support further nesting
              # But we'll treat this as a property block for the component
              description = "Main content area with routing"
              tags = "ui,core,routing"
            }
            component "FooterComponent" "Footer UI" "React"
          }
          
          container "BackendContainer" {
            component "APIComponent" "API handlers" "Node.js"
            component "DatabaseAccessComponent" "DB interactions" "TypeORM"
          }
          
          HeaderComponent -> APIComponent "Fetches user info"
          MainComponent -> APIComponent "Fetches data"
          FooterComponent -> APIComponent "Sends analytics"
        }
      ''');
      
      elementParser.parseSoftwareSystem(tokens);
      
      // Verify elements
      expect(detailedMockModelParser.createdElements.length, greaterThan(5)); // 2 containers + at least 5 components
      
      // Verify relationships
      expect(detailedMockRelationshipParser.createdRelationships.length, equals(3));
      
      expect(errorReporter.hasErrors, isFalse);
    });
  });
  
  group('ElementParser performance and boundary tests', () {
    test('should handle element with extremely long description', () {
      final veryLongDescription = 'D' * 10000; // 10,000 characters
      
      final tokens = lexer.tokenize('''
        person "User" "${veryLongDescription}"
      ''');
      
      final result = elementParser.parsePerson(tokens);
      
      expect(result, isA<PersonNode>());
      expect(result.name, equals('User'));
      expect(result.properties?['description']?.length, equals(10000));
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should handle system with very long name', () {
      final veryLongName = 'S' * 1000; // 1,000 characters
      
      final tokens = lexer.tokenize('''
        softwareSystem "${veryLongName}" "A system with a very long name"
      ''');
      
      final result = elementParser.parseSoftwareSystem(tokens);
      
      expect(result, isA<SoftwareSystemNode>());
      expect(result.name, equals(veryLongName));
      expect(result.id.length, equals(1000));
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should handle many properties in block', () {
      // Generate a block with many properties
      final StringBuilder = StringBuffer();
      StringBuilder.writeln('person "User" {');
      
      // Add 50 properties
      for (int i = 1; i <= 50; i++) {
        StringBuilder.writeln('  property$i = "Value $i"');
      }
      
      StringBuilder.writeln('}');
      
      final tokens = lexer.tokenize(StringBuilder.toString());
      
      // Should parse without errors
      final result = elementParser.parsePerson(tokens);
      
      expect(result, isA<PersonNode>());
      expect(result.name, equals('User'));
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should handle many nested elements efficiently', () {
      // Generate a system with many nested elements
      final StringBuilder = StringBuffer();
      StringBuilder.writeln('softwareSystem "NestedSystem" {');
      
      // Add 20 containers, each with 5 components
      for (int i = 1; i <= 20; i++) {
        StringBuilder.writeln('  container "Container$i" "Container $i" "Tech" {');
        
        for (int j = 1; j <= 5; j++) {
          StringBuilder.writeln('    component "Component${i}_$j" "Component $j of Container $i" "Tech"');
        }
        
        StringBuilder.writeln('  }');
      }
      
      StringBuilder.writeln('}');
      
      final tokens = lexer.tokenize(StringBuilder.toString());
      
      // Should parse without errors
      final result = elementParser.parseSoftwareSystem(tokens);
      
      expect(result, isA<SoftwareSystemNode>());
      expect(result.name, equals('NestedSystem'));
      
      // In this test, we focus on successful parsing without errors,
      // not on verifying all elements which would be too verbose
      expect(errorReporter.hasErrors, isFalse);
    });
  });
}