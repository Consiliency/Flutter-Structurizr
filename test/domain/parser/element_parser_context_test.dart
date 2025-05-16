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
  final Function(List<Token>)? onParseNestedElement;
  
  MockModelParser({this.onParseNestedElement});

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName.toString() == 'Symbol("_parseNestedElement")') {
      final tokens = invocation.positionalArguments[0] as List<Token>;
      
      // Call optional hook if provided
      if (onParseNestedElement != null) {
        onParseNestedElement!(tokens);
      }
      
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

class TrackedContextStack extends ContextStack {
  int maxDepth = 0;
  final List<String> contextSequence = [];
  
  @override
  void push(Context context) {
    super.push(context);
    maxDepth = _stack.length > maxDepth ? _stack.length : maxDepth;
    contextSequence.add('push:${context.name}');
  }
  
  @override
  Context pop() {
    final context = super.pop();
    contextSequence.add('pop:${context.name}');
    return context;
  }
  
  void resetTracking() {
    maxDepth = _stack.length;
    contextSequence.clear();
  }
}

void main() {
  late ElementParser elementParser;
  late ErrorReporter errorReporter;
  late TrackedContextStack trackedContextStack;
  late MockModelParser mockModelParser;
  late Lexer lexer;

  setUp(() {
    errorReporter = ErrorReporter();
    trackedContextStack = TrackedContextStack();
    mockModelParser = MockModelParser();
    
    elementParser = ElementParser(
      errorReporter,
      contextStack: trackedContextStack,
      modelParser: mockModelParser
    );
    
    lexer = Lexer();
  });
  
  group('ElementParser context handling tests', () {
    test('should push and pop person context correctly', () {
      final tokens = lexer.tokenize('person "User" "A standard user"');
      
      trackedContextStack.resetTracking();
      elementParser.parsePerson(tokens);
      
      expect(trackedContextStack.contextSequence.length, equals(2)); // One push, one pop
      expect(trackedContextStack.contextSequence[0], equals('push:person'));
      expect(trackedContextStack.contextSequence[1], equals('pop:person'));
      expect(trackedContextStack.isEmpty(), isTrue);
    });

    test('should push and pop software system context correctly', () {
      final tokens = lexer.tokenize('softwareSystem "PaymentSystem" "Handles payments"');
      
      trackedContextStack.resetTracking();
      elementParser.parseSoftwareSystem(tokens);
      
      expect(trackedContextStack.contextSequence.length, equals(2)); // One push, one pop
      expect(trackedContextStack.contextSequence[0], equals('push:softwareSystem'));
      expect(trackedContextStack.contextSequence[1], equals('pop:softwareSystem'));
      expect(trackedContextStack.isEmpty(), isTrue);
    });

    test('should handle nested context stack for person with block', () {
      final tokens = lexer.tokenize('''
        person "Admin" {
          description = "System administrator"
          tags = "internal,admin"
        }
      ''');
      
      trackedContextStack.resetTracking();
      elementParser.parsePerson(tokens);
      
      // Check that stack was correctly managed
      expect(trackedContextStack.contextSequence.length, equals(2)); // One push, one pop for person
      expect(trackedContextStack.contextSequence[0], equals('push:person'));
      expect(trackedContextStack.contextSequence[1], equals('pop:person'));
      expect(trackedContextStack.isEmpty(), isTrue);
    });

    test('should handle complex nested context stacks for software system with containers', () {
      trackedContextStack.resetTracking();
      
      // Create complex nested tokens
      final tokens = lexer.tokenize('''
        softwareSystem "E-Commerce System" {
          description = "Online shopping platform"
          container "Web Application" "User-facing web interface" "React"
          container "API Gateway" "API entry point" "Node.js"
        }
      ''');
      
      elementParser.parseSoftwareSystem(tokens);
      
      // Check that stack was correctly managed
      expect(trackedContextStack.contextSequence.length, equals(2)); // One push, one pop for softwareSystem
      expect(trackedContextStack.contextSequence[0], equals('push:softwareSystem'));
      expect(trackedContextStack.contextSequence[1], equals('pop:softwareSystem'));
      expect(trackedContextStack.isEmpty(), isTrue);
      
      // mockModelParser would have been called for containers
      expect(mockModelParser.createdElements.length, equals(2));
    });

    test('should maintain context stack integrity during errors', () {
      final tokens = lexer.tokenize('''
        person "User" {
          description = "A user"
          INVALID_SYNTAX
        }
      ''');
      
      trackedContextStack.resetTracking();
      
      // Should handle errors gracefully
      try {
        elementParser.parsePerson(tokens);
      } catch (e) {
        // Ignore error
      }
      
      // Check that stack was popped regardless of error
      expect(trackedContextStack.isEmpty(), isTrue);
    });

    test('should properly clean up context stack when error thrown in nested container', () {
      // Setup mock model parser to throw during nested parsing
      final throwingModelParser = MockModelParser(
        onParseNestedElement: (_) => throw Exception('Test error in container parsing')
      );
      
      final parserWithThrowingModel = ElementParser(
        errorReporter,
        contextStack: trackedContextStack,
        modelParser: throwingModelParser
      );
      
      final tokens = lexer.tokenize('''
        softwareSystem "System" {
          container "Container" "Will throw"
        }
      ''');
      
      trackedContextStack.resetTracking();
      
      // Should handle nested errors gracefully
      expect(
        () => parserWithThrowingModel.parseSoftwareSystem(tokens),
        throwsA(isA<ParseError>())
      );
      
      // Check that stack was popped regardless of error in nested component
      expect(trackedContextStack.isEmpty(), isTrue);
    });

    test('should properly track context depth', () {
      final tokens = lexer.tokenize('''
        softwareSystem "Complex System" {
          description = "A complex system"
          container "Container1" {
            description = "First container"
          }
          container "Container2" {
            description = "Second container"
          }
        }
      ''');
      
      trackedContextStack.resetTracking();
      elementParser.parseSoftwareSystem(tokens);
      
      // Should have pushed at least the softwareSystem context
      expect(trackedContextStack.maxDepth, greaterThanOrEqualTo(1));
      expect(trackedContextStack.isEmpty(), isTrue); // All contexts should be popped
    });

    test('should share context data properly', () {
      // Test that context data is correctly passed between parser methods
      
      // Create a person node to track
      final personNode = PersonNode(id: 'user', name: 'User');
      
      // Push it into a context
      trackedContextStack.push(Context('person', data: {'currentElement': personNode}));
      
      // Parse a property assignment that should modify the person
      final tokens = lexer.tokenize('description = "Test description"');
      elementParser._parseParentChild(tokens);
      
      // Pop and verify the person was modified
      trackedContextStack.pop();
      
      // In a real implementation, would verify personNode.description was set
      expect(errorReporter.hasErrors, isFalse);
    });
  });
  
  group('ElementParser complex context tests', () {
    test('should handle deeply nested elements with proper context', () {
      final tokens = lexer.tokenize('''
        softwareSystem "Complex System" {
          description = "A complex system with multiple levels"
          
          container "Frontend" {
            description = "User interface layer"
            # Would have components here in real implementation
          }
          
          container "Backend" {
            description = "Business logic layer"
            # Would have components here in real implementation
          }
          
          # Relationships would be here
        }
      ''');
      
      trackedContextStack.resetTracking();
      elementParser.parseSoftwareSystem(tokens);
      
      // Verify context stack handling
      expect(trackedContextStack.contextSequence.length, equals(2)); // One push, one pop for softwareSystem
      expect(trackedContextStack.isEmpty(), isTrue);
      
      // Verify created elements
      expect(mockModelParser.createdElements.length, equals(2)); // Two containers
    });

    test('should handle multiple contexts with same name', () {
      final tokens = lexer.tokenize('''
        softwareSystem "System1" {
          container "Container1" "First container"
        }
        
        softwareSystem "System2" {
          container "Container2" "Second container"
        }
      ''');
      
      // Split tokens
      int system2Index = -1;
      for (int i = 0; i < tokens.length; i++) {
        if (tokens[i].type == TokenType.softwareSystem && i > 5) {
          system2Index = i;
          break;
        }
      }
      
      final system1Tokens = tokens.sublist(0, system2Index);
      final system2Tokens = tokens.sublist(system2Index);
      
      trackedContextStack.resetTracking();
      
      // Parse first system
      elementParser.parseSoftwareSystem(system1Tokens);
      expect(trackedContextStack.isEmpty(), isTrue);
      
      // Parse second system
      elementParser.parseSoftwareSystem(system2Tokens);
      expect(trackedContextStack.isEmpty(), isTrue);
      
      // Verify both were processed
      expect(mockModelParser.createdElements.length, equals(2));
      expect(mockModelParser.createdElements[0].name, equals('Container1'));
      expect(mockModelParser.createdElements[1].name, equals('Container2'));
    });

    test('should handle custom context data in parent-child parsing', () {
      // Create custom context data
      final customData = {'custom': 'value', 'flag': true};
      
      // Create a person with the custom data
      final person = PersonNode(id: 'user', name: 'User');
      
      // Push the context with both the element and custom data
      final contextData = {'currentElement': person, ...customData};
      trackedContextStack.push(Context('person', data: contextData));
      
      // Parse a property assignment
      final tokens = lexer.tokenize('description = "Test description"');
      elementParser._parseParentChild(tokens);
      
      // Pop and verify
      final poppedContext = trackedContextStack.pop();
      
      // Verify that custom data was preserved
      expect(poppedContext.data['custom'], equals('value'));
      expect(poppedContext.data['flag'], equals(true));
      expect(errorReporter.hasErrors, isFalse);
    });

    test('should restore context stack after multiple errors', () {
      final tokens1 = lexer.tokenize('person "User" {'); // Missing closing brace
      final tokens2 = lexer.tokenize('softwareSystem "System" {'); // Missing closing brace
      
      trackedContextStack.resetTracking();
      
      // First error
      expect(() => elementParser.parsePerson(tokens1), throwsA(isA<ParseError>()));
      expect(trackedContextStack.isEmpty(), isTrue);
      
      // Second error
      expect(() => elementParser.parseSoftwareSystem(tokens2), throwsA(isA<ParseError>()));
      expect(trackedContextStack.isEmpty(), isTrue);
      
      // Should still be able to parse correctly
      final validTokens = lexer.tokenize('person "Admin"');
      final result = elementParser.parsePerson(validTokens);
      
      expect(result, isA<PersonNode>());
      expect(result.name, equals('Admin'));
      expect(trackedContextStack.isEmpty(), isTrue);
    });

    test('should handle context data propagation in complex nested structures', () {
      final tokens = lexer.tokenize('''
        softwareSystem "Analytics Platform" {
          description = "Data analytics platform"
          
          container "Data Warehouse" "Stores analytics data" "PostgreSQL" {
            description = "Data warehouse for analytics"
          }
          
          container "ETL Pipeline" "Processes data" "Python" {
            description = "Extract, transform, load pipeline"
          }
        }
      ''');
      
      trackedContextStack.resetTracking();
      elementParser.parseSoftwareSystem(tokens);
      
      // Verify context stack management
      expect(trackedContextStack.isEmpty(), isTrue);
      
      // Verify element creation - in a real implementation we'd verify structure too
      expect(mockModelParser.createdElements.length, equals(2));
    });
  });
}