import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/parser/parser.dart';
import 'package:flutter_structurizr/domain/parser/parser_fixed.dart';
import 'package:flutter_structurizr/domain/parser/ast/ast.dart';
import 'package:flutter_structurizr/domain/parser/lexer/lexer.dart';
import 'package:flutter_structurizr/domain/parser/lexer/token.dart';

// This file contains three tests for documentation and decisions parsing
void main() {
  group('DocumentationParser', () {
    // TEST 1: Basic documentation
    test('Basic documentation', () {
      const source = '''
        workspace "Test" {
          documentation {
            content = "This is a test documentation"
          }
        }
      ''';
      
      final parser = FixedParser(source);
      final workspace = parser.parse();
      
      expect(workspace.documentation, isNotNull, reason: "Documentation node should not be null");
      
      // The parser removes quotes, so our expectation should match that
      expect(workspace.documentation!.content, "This is a test documentation", 
          reason: "Content should match");
      expect(workspace.documentation!.format, DocumentationFormat.markdown, 
          reason: "Format should be markdown");
      expect(workspace.documentation!.sections, isEmpty, 
          reason: "Sections should be empty");
    });
    
    // TEST 2: Documentation with format
    test('Documentation with format', () {
      const source = '''
        workspace "Test" {
          documentation format="asciidoc" {
            content = "= Test Document\\n\\nThis is an AsciiDoc document."
          }
        }
      ''';
      
      final parser = FixedParser(source);
      final workspace = parser.parse();
      
      expect(workspace.documentation, isNotNull, reason: "Documentation node should not be null");
      expect(workspace.documentation!.format, DocumentationFormat.asciidoc, 
          reason: "Format should be asciidoc");
      expect(workspace.documentation!.content, "= Test Document\\n\\nThis is an AsciiDoc document.", 
          reason: "Content should match");
    });
    
    // TEST 3: Decisions
    test('Decisions', () {
      const source = '''
        workspace "Test" {
          decisions {
            decision "ADR-001" {
              title = "Use Markdown for documentation"
              status = "Accepted" 
              date = "2023-01-01"
              content = "We will use Markdown for documentation because it's simple and widely supported."
            }
          }
        }
      ''';
      
      final parser = FixedParser(source);
      final workspace = parser.parse();
      
      expect(workspace.decisions, isNotNull, reason: "Decisions should not be null");
      expect(workspace.decisions!.length, 1, reason: "Should have 1 decision");
    });
  });
}