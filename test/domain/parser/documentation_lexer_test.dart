import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/parser/lexer/lexer.dart';
import 'package:flutter_structurizr/domain/parser/lexer/token.dart';

void main() {
  group('Documentation Lexer', () {
    test('scans documentation tokens correctly', () {
      const source = '''
        workspace "Test" {
          documentation {
            content = "This is test documentation"
          }
        }
      ''';
      
      final lexer = Lexer(source);
      final tokens = lexer.scanTokens();
      
      // Find all the tokens related to documentation
      final docTokens = tokens.where((token) => 
        token.type == TokenType.documentation || 
        token.type == TokenType.content ||
        token.type == TokenType.format ||
        token.type == TokenType.section
      ).toList();
      
      // We should have at least the 'documentation' token and 'content' token
      expect(docTokens.length, greaterThanOrEqualTo(2));
      expect(docTokens[0].type, equals(TokenType.documentation));
      expect(docTokens[1].type, equals(TokenType.content));
    });
    
    test('scans documentation with format specification', () {
      const source = '''
        workspace "Test" {
          documentation format="asciidoc" {
            content = "This is AsciiDoc content"
          }
        }
      ''';
      
      final lexer = Lexer(source);
      final tokens = lexer.scanTokens();
      
      // Find all the tokens related to documentation
      final docTokens = tokens.where((token) => 
        token.type == TokenType.documentation || 
        token.type == TokenType.content ||
        token.type == TokenType.format ||
        token.type == TokenType.section
      ).toList();
      
      // We should have 'documentation', 'format', and 'content' tokens
      expect(docTokens.length, greaterThanOrEqualTo(3));
      expect(docTokens[0].type, equals(TokenType.documentation));
      expect(docTokens[1].type, equals(TokenType.format));
      expect(docTokens[2].type, equals(TokenType.content));
    });
    
    test('scans documentation with sections', () {
      const source = '''
        workspace "Test" {
          documentation {
            section "Overview" {
              content = "This is an overview"
            }
          }
        }
      ''';
      
      final lexer = Lexer(source);
      final tokens = lexer.scanTokens();
      
      // Find all the tokens related to documentation
      final docTokens = tokens.where((token) => 
        token.type == TokenType.documentation || 
        token.type == TokenType.content ||
        token.type == TokenType.format ||
        token.type == TokenType.section
      ).toList();
      
      // We should have 'documentation', 'section', and 'content' tokens
      expect(docTokens.length, greaterThanOrEqualTo(3));
      expect(docTokens[0].type, equals(TokenType.documentation));
      expect(docTokens[1].type, equals(TokenType.section));
      expect(docTokens[2].type, equals(TokenType.content));
    });
    
    test('scans decision tokens correctly', () {
      const source = '''
        workspace "Test" {
          decisions {
            decision "ADR-001" {
              title = "Use Markdown"
              status = "Accepted"
              date = "2023-01-01"
              content = "We will use Markdown"
            }
          }
        }
      ''';
      
      final lexer = Lexer(source);
      final tokens = lexer.scanTokens();
      
      // Find all the tokens related to decisions
      final decisionTokens = tokens.where((token) => 
        token.type == TokenType.decisions ||
        token.type == TokenType.decision ||
        token.type == TokenType.title ||
        token.type == TokenType.status ||
        token.type == TokenType.date ||
        token.type == TokenType.content
      ).toList();
      
      // We should have the appropriate tokens for an ADR
      expect(decisionTokens.length, greaterThanOrEqualTo(6));
      expect(decisionTokens[0].type, equals(TokenType.decisions));
      expect(decisionTokens[1].type, equals(TokenType.decision));
      expect(decisionTokens[2].type, equals(TokenType.title));
      expect(decisionTokens[3].type, equals(TokenType.status));
      expect(decisionTokens[4].type, equals(TokenType.date));
      expect(decisionTokens[5].type, equals(TokenType.content));
    });
  });
}