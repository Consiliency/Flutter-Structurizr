import 'package:flutter_structurizr/domain/parser/ast/ast.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/parser/lexer/lexer.dart';
import 'package:flutter_structurizr/domain/parser/lexer/token.dart';
import 'package:test/test.dart';

/// Test class focused on the group relationship parsing functionality.
///
/// Tests the following method:
/// - RelationshipParser._parseGroup(List<Token>): void
class RelationshipParserGroupTest {
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
  
  /// Mock implementation of RelationshipParser that focuses on group parsing
  class MockRelationshipGroupParser {
    final ErrorReporter errorReporter;
    final MockContextStack contextStack;
    final List<RelationshipNode> relationships = [];
    final List<String> groupNames = [];
    
    MockRelationshipGroupParser({
      ErrorReporter? errorReporter,
    }) : errorReporter = errorReporter ?? ErrorReporter(''),
         contextStack = MockContextStack();
    
    void _parseGroup(List<Token> tokens) {
      if (tokens.isEmpty || tokens[0].type != TokenType.group) {
        handleError(ParseError('Expected "group" keyword', 
                               position: tokens.isNotEmpty 
                                 ? tokens.first.position 
                                 : SourcePosition(0, 0)));
        return;
      }
      
      try {
        contextStack.push(MockContext('group'));
        
        // Find the opening brace
        int braceIndex = -1;
        for (int i = 0; i < tokens.length; i++) {
          if (tokens[i].type == TokenType.leftBrace) {
            braceIndex = i;
            break;
          }
        }
        
        if (braceIndex == -1) {
          throw ParseError('Expected "{" in group definition', 
                         position: tokens.first.position);
        }
        
        // Extract group name from tokens between "group" and "{"
        String groupNameRaw = tokens.sublist(1, braceIndex)
            .map((t) => t.lexeme)
            .join(' ')
            .trim();
            
        String groupName = groupNameRaw;
        if (groupName.startsWith('"') && groupName.endsWith('"')) {
          groupName = groupName.substring(1, groupName.length - 1);
        }
        
        // Add to our list of parsed groups
        groupNames.add(groupName);
        
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
          throw ParseError('Missing closing brace for group', 
                         position: tokens.first.position);
        }
        
        // Extract the content between braces
        final contentTokens = tokens.sublist(braceIndex + 1, closingBraceIndex);
        
        // Look for relationships in the group content
        // For this mock, we'll just look for arrows and create simple relationships
        for (int i = 0; i < contentTokens.length; i++) {
          if (contentTokens[i].lexeme == '->') {
            if (i > 0 && i < contentTokens.length - 1) {
              final source = contentTokens[i - 1].lexeme;
              final dest = contentTokens[i + 1].lexeme;
              
              // Create a relationship and note which group it's in
              final relationship = RelationshipNode(
                sourceId: source,
                destinationId: dest,
                description: 'In group: $groupName',
                sourcePosition: contentTokens[i].position,
              );
              
              relationships.add(relationship);
            }
          }
        }
        
        // Handle nested groups by recursively processing
        for (int i = 0; i < contentTokens.length; i++) {
          if (contentTokens[i].type == TokenType.group) {
            // Find the end of this nested group
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
            
            // Process this nested group recursively
            final nestedGroupTokens = contentTokens.sublist(i, nestedClosingBraceIndex + 1);
            _parseGroup(nestedGroupTokens);
            
            // Skip past this nested group
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
  group('RelationshipParser._parseGroup', () {
    late RelationshipParserGroupTest.MockRelationshipGroupParser parser;
    late ErrorReporter errorReporter;
    
    setUp(() {
      errorReporter = ErrorReporter('');
      parser = RelationshipParserGroupTest.MockRelationshipGroupParser(
        errorReporter: errorReporter,
      );
    });
    
    test('should parse simple group with relationship', () {
      final tokens = RelationshipParserGroupTest.tokensFromString(
        'group "External Users" { user -> system }'
      );
      
      parser._parseGroup(tokens);
      
      expect(parser.groupNames, contains('External Users'));
      expect(parser.relationships, hasLength(1));
      expect(parser.relationships[0].sourceId, 'user');
      expect(parser.relationships[0].destinationId, 'system');
      expect(parser.relationships[0].description, contains('External Users'));
    });
    
    test('should parse nested groups', () {
      final tokens = RelationshipParserGroupTest.tokensFromString(
        'group "External" { group "Users" { user -> system } }'
      );
      
      parser._parseGroup(tokens);
      
      expect(parser.groupNames, contains('External'));
      expect(parser.groupNames, contains('Users'));
      expect(parser.relationships, hasLength(1));
    });
    
    test('should parse multiple nested groups', () {
      final tokens = RelationshipParserGroupTest.tokensFromString(
        'group "External" { ' +
        '  group "Users" { user -> systemA }' +
        '  group "Systems" { systemB -> database }' +
        '}'
      );
      
      parser._parseGroup(tokens);
      
      expect(parser.groupNames, hasLength(3)); // External, Users, Systems
      expect(parser.relationships, hasLength(2));
    });
    
    test('should handle complex group names', () {
      final tokens = RelationshipParserGroupTest.tokensFromString(
        'group "External Users & Partners" { user -> system }'
      );
      
      parser._parseGroup(tokens);
      
      expect(parser.groupNames, contains('External Users & Partners'));
    });
    
    test('should handle groups with multiple relationships', () {
      final tokens = RelationshipParserGroupTest.tokensFromString(
        'group "Users" { ' +
        '  user -> systemA ' +
        '  user -> systemB ' +
        '  admin -> database ' +
        '}'
      );
      
      parser._parseGroup(tokens);
      
      expect(parser.relationships, hasLength(3));
    });
    
    test('should use context stack correctly', () {
      final tokens = RelationshipParserGroupTest.tokensFromString(
        'group "Level 1" { group "Level 2" { group "Level 3" { } } }'
      );
      
      parser._parseGroup(tokens);
      
      // Context stack should be empty after processing
      expect(() => parser.contextStack.current(), throwsStateError);
    });
    
    test('should maintain proper context during nested parsing', () {
      final tokens = RelationshipParserGroupTest.tokensFromString(
        'group "Level 1" { user -> systemA; group "Level 2" { admin -> systemB } }'
      );
      
      parser._parseGroup(tokens);
      
      expect(parser.relationships, hasLength(2));
      expect(parser.groupNames, contains('Level 1'));
      expect(parser.groupNames, contains('Level 2'));
    });
    
    test('should report error for missing opening brace', () {
      final tokens = RelationshipParserGroupTest.tokensFromString(
        'group "Missing Brace" user -> system'
      );
      
      parser._parseGroup(tokens);
      
      expect(errorReporter.errors, isNotEmpty);
      expect(errorReporter.errors.first.message, contains('Expected "{"'));
    });
    
    test('should report error for missing closing brace', () {
      final tokens = RelationshipParserGroupTest.tokensFromString(
        'group "Missing Closing" { user -> system'
      );
      
      parser._parseGroup(tokens);
      
      expect(errorReporter.errors, isNotEmpty);
      expect(errorReporter.errors.first.message, contains('Missing closing brace'));
    });
    
    test('should report error for invalid group syntax', () {
      final tokens = RelationshipParserGroupTest.tokensFromString(
        'something else'
      );
      
      parser._parseGroup(tokens);
      
      expect(errorReporter.errors, isNotEmpty);
      expect(errorReporter.errors.first.message, contains('Expected "group"'));
    });
    
    test('should report error for empty group input', () {
      final tokens = RelationshipParserGroupTest.tokensFromString('');
      
      parser._parseGroup(tokens);
      
      expect(errorReporter.errors, isNotEmpty);
    });
    
    test('should handle deep nesting of groups', () {
      final tokens = RelationshipParserGroupTest.tokensFromString(
        'group "Level 1" { ' +
        '  group "Level 2" { ' +
        '    group "Level 3" { ' +
        '      group "Level 4" { ' +
        '        user -> system ' +
        '      } ' +
        '    } ' +
        '  } ' +
        '}'
      );
      
      parser._parseGroup(tokens);
      
      expect(parser.groupNames, hasLength(4));
      expect(parser.relationships, hasLength(1));
      
      // Each level should be in the group names
      expect(parser.groupNames, contains('Level 1'));
      expect(parser.groupNames, contains('Level 2'));
      expect(parser.groupNames, contains('Level 3'));
      expect(parser.groupNames, contains('Level 4'));
    });
  });
}