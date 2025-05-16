import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/parser/lexer/lexer.dart';
import 'package:flutter_structurizr/domain/parser/lexer/token.dart';
import 'package:flutter_structurizr/domain/parser/parser.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/documentation/documentation_node.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Documentation Parser Tests', () {
    test('should parse documentation and decisions blocks', () {
      const source = '''
        workspace "Documentation Test" {
          documentation {
            content = "This is the main documentation content"
            section "Getting Started" {
              content = "This is how to get started with the system"
            }
          }
          
          decisions {
            decision "ADR-001" {
              title = "Use C4 model"
              status = "Accepted"
              date = "2023-05-15"
              content = "We will use the C4 model for our architecture documentation."
            }
          }
        }
      ''';
      
      // First test the lexer directly
      final lexer = Lexer(source);
      final tokens = lexer.scanTokens();
      
      // Print all tokens for better debugging
      print('\n--- DEBUG TOKENS ---');
      for (final token in tokens) {
        print('Token: ${token.type} | Lexeme: "${token.lexeme}" | Line: ${token.line} | Column: ${token.column}');
      }
      print('--- END DEBUG TOKENS ---\n');
      
      // Verify documentation and decisions tokens are present
      expect(tokens.any((t) => t.type == TokenType.documentation), isTrue);
      expect(tokens.any((t) => t.type == TokenType.decisions), isTrue);
      
      // Now test the parser
      final parser = Parser(source);
      final workspaceNode = parser.parse();
      
      // Print debugging info
      print('Documentation test: workspaceNode has documentation: ${workspaceNode.documentation != null}');
      print('Documentation test: workspaceNode has decisions: ${workspaceNode.decisions != null ? workspaceNode.decisions!.length : 0}');
      
      // Verify the parser created the documentation and decisions nodes
      expect(workspaceNode.documentation, isNotNull);
      expect(workspaceNode.decisions, isNotNull);
      expect(workspaceNode.decisions!.isNotEmpty, isTrue);
    });
  });
}