import 'package:flutter_structurizr/domain/parser/ast/ast.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/parser/lexer/lexer.dart';
import 'package:flutter_structurizr/domain/parser/lexer/token.dart';
import 'package:test/test.dart';

/// Test class focused on the nested relationship parsing functionality.
///
/// Tests the following method:
/// - RelationshipParser._parseNested(List<Token>): void
class RelationshipParserNestedTest {
  /// Mock implementation of a Context for testing ContextStack operations
  class MockContext {
    final String name;
    MockContext(this.name);
    
    @override
    String toString() => name;
  }
  
  /// Mock implementation of ContextStack for testing
  class MockContextStack {
    final List<MockContext> _stack = [];
    
    void push(MockContext ctx) {
      _stack.add(ctx);
    }
    
    MockContext pop() {
      if (_stack.isEmpty) {
        throw StateError('Cannot pop from empty stack');
      }
      return _stack.removeLast();
    }
    
    MockContext current() {
      if (_stack.isEmpty) {
        throw StateError('Stack is empty');
      }
      return _stack.last;
    }
    
    void clear() {
      _stack.clear();
    }
    
    int size() => _stack.length;
    
    // For testing inspection
    List<String> get contextNames => _stack.map((ctx) => ctx.name).toList();
  }
  
  /// Mock implementation of RelationshipParser that focuses on nested relationship parsing
  class MockRelationshipNestedParser {
    final ErrorReporter errorReporter;
    final MockContextStack contextStack;
    final List<RelationshipNode> relationships = [];
    final Map<String, String> elementNesting = {};
    
    MockRelationshipNestedParser({
      ErrorReporter? errorReporter,
    }) : errorReporter = errorReporter ?? ErrorReporter(''),
         contextStack = MockContextStack();
    
    void _parseNested(List<Token> tokens) {
      if (tokens.isEmpty) {
        handleError(ParseError('Expected element type keyword', 
                               position: SourcePosition(0, 0)));
        return;
      }
      
      try {
        contextStack.push(MockContext('nested'));
        
        final elementType = tokens[0].type.toString();
        
        // Find the opening brace
        int braceIndex = -1;
        for (int i = 0; i < tokens.length; i++) {
          if (tokens[i].type == TokenType.leftBrace) {
            braceIndex = i;
            break;
          }
        }
        
        if (braceIndex == -1) {
          throw ParseError('Expected "{" in $elementType definition', 
                         position: tokens.first.position);
        }
        
        // Extract element name from tokens between type and "{"
        String elementNameRaw = tokens.sublist(1, braceIndex)
            .map((t) => t.lexeme)
            .join(' ')
            .trim();
            
        String elementName = elementNameRaw;
        if (elementName.startsWith('"') && elementName.endsWith('"')) {
          elementName = elementName.substring(1, elementName.length - 1);
        }
        
        final elementId = tokens[0].lexeme;
        
        // Store this element in our nesting map
        elementNesting[elementId] = elementName;
        
        // Find the closing brace
        int closingBraceIndex = -1;
        int openBraces = 1;
        for (int i = braceIndex + 1; i < tokens.length; i++) {
          if (tokens[i].type == TokenType.leftBrace) {
            openBraces++;
          } else if (tokens[i].type == TokenType.rightBrace) {
            openBraces--;
            if (openBraces == 0) {
              closingBraceIndex = i;
              break;
            }
          }
        }
        
        if (closingBraceIndex == -1) {
          throw ParseError('Missing closing brace for $elementType', 
                         position: tokens.first.position);
        }
        
        // Extract the content between braces
        final contentTokens = tokens.sublist(braceIndex + 1, closingBraceIndex);
        
        // Look for relationships in the nested content
        // First, check for direct -> relationships at this level
        for (int i = 0; i < contentTokens.length; i++) {
          if (contentTokens[i].lexeme == '->') {
            String source = elementId;
            
            if (i == 0) {
              // This is an implicit source with syntax "-> destination"
              source = elementId;
            } else if (contentTokens[i-1].lexeme != '{' && 
                       contentTokens[i-1].lexeme != '}' && 
                       contentTokens[i-1].type != TokenType.leftBrace && 
                       contentTokens[i-1].type != TokenType.rightBrace) {
              // This is an explicit source with syntax "source -> destination"
              source = contentTokens[i-1].lexeme;
            }
            
            if (i + 1 < contentTokens.length) {
              String destination = contentTokens[i+1].lexeme;
              String? description;
              
              // Check for description string
              if (i + 2 < contentTokens.length && contentTokens[i+2].type == TokenType.string) {
                description = contentTokens[i+2].value as String?;
              }
              
              final relationship = RelationshipNode(
                sourceId: source,
                destinationId: destination,
                description: description,
                sourcePosition: contentTokens[i].position,
              );
              
              relationships.add(relationship);
            }
          }
        }
        
        // Now handle nested elements and their relationships
        for (int i = 0; i < contentTokens.length; i++) {
          if (_isElementType(contentTokens[i].type)) {
            // Find the extents of this nested element
            int nestedOpenBraceIndex = -1;
            for (int j = i; j < contentTokens.length; j++) {
              if (contentTokens[j].type == TokenType.leftBrace) {
                nestedOpenBraceIndex = j;
                break;
              }
            }
            
            if (nestedOpenBraceIndex == -1) continue;
            
            int nestedClosingBraceIndex = -1;
            int nestedOpenBraces = 1;
            for (int j = nestedOpenBraceIndex + 1; j < contentTokens.length; j++) {
              if (contentTokens[j].type == TokenType.leftBrace) {
                nestedOpenBraces++;
              } else if (contentTokens[j].type == TokenType.rightBrace) {
                nestedOpenBraces--;
                if (nestedOpenBraces == 0) {
                  nestedClosingBraceIndex = j;
                  break;
                }
              }
            }
            
            if (nestedClosingBraceIndex == -1) continue;
            
            // Process this nested element recursively
            final nestedElementTokens = contentTokens.sublist(i, nestedClosingBraceIndex + 1);
            _parseNested(nestedElementTokens);
            
            // Skip past this nested element
            i = nestedClosingBraceIndex;
          }
        }
      } catch (e) {
        if (e is ParseError) {
          handleError(e);
        } else {
          rethrow;
        }
      } finally {
        contextStack.pop();
      }
    }
    
    bool _isElementType(TokenType type) {
      return type == TokenType.person ||
             type == TokenType.softwareSystem ||
             type == TokenType.container ||
             type == TokenType.component ||
             type == TokenType.deploymentEnvironment ||
             type == TokenType.deploymentNode ||
             type == TokenType.infrastructureNode;
    }
    
    void handleError(ParseError error) {
      errorReporter.addError(error);
    }
  }
  
  /// Helper method to create tokens from a DSL string
  static List<Token> tokensFromString(String source) {
    final lexer = Lexer(source);
    return lexer.scanTokens();
  }
}

void main() {
  group('RelationshipParser._parseNested', () {
    late RelationshipParserNestedTest.MockRelationshipNestedParser parser;
    late ErrorReporter errorReporter;
    
    setUp(() {
      errorReporter = ErrorReporter('');
      parser = RelationshipParserNestedTest.MockRelationshipNestedParser(
        errorReporter: errorReporter,
      );
    });
    
    test('should parse basic nested relationship', () {
      final tokens = RelationshipParserNestedTest.tokensFromString(
        'softwareSystem "Payment System" { -> database "Stores data" }'
      );
      
      parser._parseNested(tokens);
      
      expect(parser.relationships, hasLength(1));
      expect(parser.relationships[0].sourceId, 'softwareSystem');
      expect(parser.relationships[0].destinationId, 'database');
      expect(parser.relationships[0].description, 'Stores data');
    });
    
    test('should parse relationships in deeply nested elements', () {
      final tokens = RelationshipParserNestedTest.tokensFromString(
        'softwareSystem "System" { ' +
        '  container "Web App" { ' +
        '    component "Service" { ' +
        '      -> database "Reads data" ' +
        '    } ' +
        '  } ' +
        '}'
      );
      
      parser._parseNested(tokens);
      
      expect(parser.relationships, hasLength(1));
      expect(parser.relationships[0].sourceId, 'component');
      expect(parser.relationships[0].destinationId, 'database');
    });
    
    test('should handle explicit source in nested relationship', () {
      final tokens = RelationshipParserNestedTest.tokensFromString(
        'softwareSystem "System" { ' +
        '  container "Web App" { ' +
        '    api -> database "Reads data" ' +
        '  } ' +
        '}'
      );
      
      parser._parseNested(tokens);
      
      expect(parser.relationships, hasLength(1));
      expect(parser.relationships[0].sourceId, 'api');
      expect(parser.relationships[0].destinationId, 'database');
    });
    
    test('should record element nesting information', () {
      final tokens = RelationshipParserNestedTest.tokensFromString(
        'softwareSystem "Payment System" { ' +
        '  container "API Gateway" { } ' +
        '  container "Processing Service" { } ' +
        '}'
      );
      
      parser._parseNested(tokens);
      
      expect(parser.elementNesting['softwareSystem'], 'Payment System');
      expect(parser.elementNesting['container'], isNotNull);
    });
    
    test('should handle multiple relationships at different nesting levels', () {
      final tokens = RelationshipParserNestedTest.tokensFromString(
        'softwareSystem "System" { ' +
        '  -> database "System-level relationship" ' +
        '  container "Web" { ' +
        '    -> api "Container-level relationship" ' +
        '  } ' +
        '}'
      );
      
      parser._parseNested(tokens);
      
      expect(parser.relationships, hasLength(2));
    });
    
    test('should use context stack correctly', () {
      final tokens = RelationshipParserNestedTest.tokensFromString(
        'softwareSystem "System" { ' +
        '  container "Web" { ' +
        '    component "UI" { ' +
        '      -> api ' +
        '    } ' +
        '  } ' +
        '}'
      );
      
      parser._parseNested(tokens);
      
      // Context stack should be empty after processing
      expect(() => parser.contextStack.current(), throwsStateError);
    });
    
    test('should report error for missing opening brace', () {
      final tokens = RelationshipParserNestedTest.tokensFromString(
        'softwareSystem "Missing Brace" -> database'
      );
      
      parser._parseNested(tokens);
      
      expect(errorReporter.errors, isNotEmpty);
      expect(errorReporter.errors.first.message, contains('Expected "{"'));
    });
    
    test('should report error for missing closing brace', () {
      final tokens = RelationshipParserNestedTest.tokensFromString(
        'softwareSystem "Missing Closing" { -> database'
      );
      
      parser._parseNested(tokens);
      
      expect(errorReporter.errors, isNotEmpty);
      expect(errorReporter.errors.first.message, contains('Missing closing brace'));
    });
    
    test('should report error for empty input', () {
      final tokens = RelationshipParserNestedTest.tokensFromString('');
      
      parser._parseNested(tokens);
      
      expect(errorReporter.errors, isNotEmpty);
      expect(errorReporter.errors.first.message, contains('Expected element type'));
    });
    
    test('should support multiple element types', () {
      final elementTypes = ['softwareSystem', 'container', 'component', 'person'];
      
      for (final type in elementTypes) {
        final tokens = RelationshipParserNestedTest.tokensFromString(
          '$type "Name" { -> database }'
        );
        
        final localParser = RelationshipParserNestedTest.MockRelationshipNestedParser(
          errorReporter: ErrorReporter(''),
        );
        localParser._parseNested(tokens);
        
        expect(localParser.relationships, isNotEmpty, reason: 'Failed for type: $type');
      }
    });
    
    test('should handle complex nested structures with multiple relationships', () {
      final tokens = RelationshipParserNestedTest.tokensFromString(
        'softwareSystem "System" { ' +
        '  container "Web" { ' +
        '    -> auth "Authenticates" ' +
        '    component "UI" { ' +
        '      -> api "Gets data" ' +
        '    } ' +
        '    component "Service" { ' +
        '      -> database "Stores data" ' +
        '      -> cache "Caches results" ' +
        '    } ' +
        '  } ' +
        '  container "Mobile" { ' +
        '    -> api "Calls API" ' +
        '  } ' +
        '}'
      );
      
      parser._parseNested(tokens);
      
      expect(parser.relationships, hasLength(5));
    });
    
    test('should handle descriptions and technologies in relationships', () {
      final tokens = RelationshipParserNestedTest.tokensFromString(
        'softwareSystem "System" { ' +
        '  -> database "Stores data" "SQL" ' +
        '}'
      );
      
      parser._parseNested(tokens);
      
      expect(parser.relationships, hasLength(1));
      expect(parser.relationships[0].description, 'Stores data');
    });
  });
}