import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/parser/lexer/lexer.dart';
import 'package:flutter_structurizr/domain/parser/lexer/token.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Lexer', () {
    // Helper function to scan tokens from source
    List<Token> scanTokens(String source) {
      final errorReporter = ErrorReporter(source);
      final lexer = Lexer(source);
      return lexer.scanTokens();
    }

    // Helper function to check token types only
    void expectTokenTypes(List<Token> tokens, List<TokenType> expectedTypes) {
      expect(
        tokens.map((t) => t.type).toList(),
        expectedTypes,
        reason: 'Token types should match expected types',
      );
    }

    // Helper function to verify full token details
    void expectToken(
      Token token, {
      required TokenType type,
      required String lexeme,
      Object? value,
      int? line,
      int? column,
    }) {
      expect(token.type, equals(type), reason: 'Token type should match');
      expect(token.lexeme, equals(lexeme), reason: 'Token lexeme should match');
      
      if (value != null) {
        expect(token.value, equals(value), reason: 'Token value should match');
      }
      
      if (line != null) {
        expect(token.line, equals(line), reason: 'Token line should match');
      }
      
      if (column != null) {
        expect(token.column, equals(column), reason: 'Token column should match');
      }
    }

    group('Basic tokens', () {
      test('should scan empty source', () {
        final tokens = scanTokens('');
        expectTokenTypes(tokens, [TokenType.eof]);
      });

      test('should scan basic single-character tokens', () {
        final source = '{}(),.:;+-*/#{@';
        final tokens = scanTokens(source);
        
        expectTokenTypes(tokens, [
          TokenType.leftBrace,
          TokenType.rightBrace,
          TokenType.leftParen,
          TokenType.rightParen,
          TokenType.comma,
          TokenType.dot,
          TokenType.colon,
          TokenType.semicolon,
          TokenType.plus,
          TokenType.minus,
          TokenType.star,
          TokenType.slash,
          TokenType.hash,
          TokenType.leftBrace,
          TokenType.at,
          TokenType.eof,
        ]);
      });

      test('should scan arrow token', () {
        final tokens = scanTokens('->');
        expectTokenTypes(tokens, [TokenType.arrow, TokenType.eof]);
      });

      test('should scan equals token', () {
        final tokens = scanTokens('=');
        expectTokenTypes(tokens, [TokenType.equals, TokenType.eof]);
      });
    });

    group('Whitespace handling', () {
      test('should ignore whitespace', () {
        final source = ' \t\r\n{ }';
        final tokens = scanTokens(source);
        
        expectTokenTypes(tokens, [
          TokenType.leftBrace,
          TokenType.rightBrace,
          TokenType.eof,
        ]);
      });

      test('should track line numbers correctly', () {
        final source = '{\n}\n->';
        final tokens = scanTokens(source);
        
        expect(tokens[0].line, equals(1)); // {
        expect(tokens[1].line, equals(2)); // }
        expect(tokens[2].line, equals(3)); // ->
      });

      test('should track column numbers correctly', () {
        final source = 'abc = 123';
        final tokens = scanTokens(source);
        
        expect(tokens[0].column, equals(1)); // abc
        expect(tokens[1].column, equals(5)); // =
        expect(tokens[2].column, equals(7)); // 123
      });
    });

    group('Comments', () {
      test('should ignore line comments', () {
        final source = '{ // This is a line comment\n}';
        final tokens = scanTokens(source);
        
        expectTokenTypes(tokens, [
          TokenType.leftBrace,
          TokenType.rightBrace,
          TokenType.eof,
        ]);
      });

      test('should ignore block comments', () {
        final source = '{ /* This is a block comment */ }';
        final tokens = scanTokens(source);
        
        expectTokenTypes(tokens, [
          TokenType.leftBrace,
          TokenType.rightBrace,
          TokenType.eof,
        ]);
      });

      test('should handle nested block comments', () {
        final source = '{ /* outer /* nested */ comment */ }';
        final tokens = scanTokens(source);
        
        expectTokenTypes(tokens, [
          TokenType.leftBrace,
          TokenType.rightBrace,
          TokenType.eof,
        ]);
      });

      test('should report error for unterminated block comment', () {
        final source = '{ /* Unterminated comment';
        final lexer = Lexer(source);
        final tokens = lexer.scanTokens();
        
        expect(lexer.errorReporter.hasErrors, isTrue);
        expect(
          lexer.errorReporter.errors.first.message,
          equals('Unterminated block comment'),
        );
      });
    });

    group('Literals', () {
      test('should scan integer literals', () {
        final source = '123 456 789';
        final tokens = scanTokens(source);
        
        expectTokenTypes(tokens, [
          TokenType.integer,
          TokenType.integer,
          TokenType.integer,
          TokenType.eof,
        ]);
        
        expectToken(
          tokens[0],
          type: TokenType.integer,
          lexeme: '123',
          value: 123,
        );
      });

      test('should scan double literals', () {
        final source = '123.456 7.89';
        final tokens = scanTokens(source);
        
        expectTokenTypes(tokens, [
          TokenType.double,
          TokenType.double,
          TokenType.eof,
        ]);
        
        expectToken(
          tokens[0],
          type: TokenType.double,
          lexeme: '123.456',
          value: 123.456,
        );
      });

      test('should scan string literals with double quotes', () {
        final source = '"Hello, world!" "Another string"';
        final tokens = scanTokens(source);
        
        expectTokenTypes(tokens, [
          TokenType.string,
          TokenType.string,
          TokenType.eof,
        ]);
        
        expectToken(
          tokens[0],
          type: TokenType.string,
          lexeme: '"Hello, world!"',
          value: 'Hello, world!',
        );
      });

      test('should scan string literals with single quotes', () {
        final source = "'Hello, world!' 'Another string'";
        final tokens = scanTokens(source);
        
        expectTokenTypes(tokens, [
          TokenType.string,
          TokenType.string,
          TokenType.eof,
        ]);
        
        expectToken(
          tokens[0],
          type: TokenType.string,
          lexeme: "'Hello, world!'",
          value: 'Hello, world!',
        );
      });

      test('should scan boolean literals', () {
        final source = 'true false';
        final tokens = scanTokens(source);
        
        expectTokenTypes(tokens, [
          TokenType.boolean,
          TokenType.boolean,
          TokenType.eof,
        ]);
        
        expectToken(
          tokens[0],
          type: TokenType.boolean,
          lexeme: 'true',
          value: true,
        );
        
        expectToken(
          tokens[1],
          type: TokenType.boolean,
          lexeme: 'false',
          value: false,
        );
      });
    });

    group('String literal features', () {
      test('should process escape sequences in string literals', () {
        final source = '"Line1\\nLine2\\t\\r\\b\\f\\\'\\\"\\\\Test"';
        final tokens = scanTokens(source);
        
        expectToken(
          tokens[0],
          type: TokenType.string,
          lexeme: '"Line1\\nLine2\\t\\r\\b\\f\\\'\\\"\\\\Test"',
          value: 'Line1\nLine2\t\r\b\f\'\"\\Test',
        );
      });

      test('should process Unicode escape sequences', () {
        final source = '"\\u0041\\u0042\\u0043"'; // ABC in Unicode
        final tokens = scanTokens(source);
        
        expectToken(
          tokens[0],
          type: TokenType.string,
          lexeme: '"\\u0041\\u0042\\u0043"',
          value: 'ABC',
        );
      });

      test('should report error for invalid escape sequences', () {
        final source = '"Test\\z"';
        final lexer = Lexer(source);
        final tokens = lexer.scanTokens();
        
        expect(lexer.errorReporter.hasErrors, isTrue);
        expect(
          lexer.errorReporter.errors.first.message,
          contains('Invalid escape sequence'),
        );
      });

      test('should report error for incomplete Unicode escape sequence', () {
        final source = '"\\u004"'; // Incomplete Unicode sequence
        final lexer = Lexer(source);
        final tokens = lexer.scanTokens();
        
        expect(lexer.errorReporter.hasErrors, isTrue);
        expect(
          lexer.errorReporter.errors.first.message,
          equals('Incomplete Unicode escape sequence'),
        );
      });

      test('should report error for invalid Unicode escape sequence', () {
        final source = '"\\u004Z"'; // Invalid Unicode sequence
        final lexer = Lexer(source);
        final tokens = lexer.scanTokens();
        
        expect(lexer.errorReporter.hasErrors, isTrue);
        expect(
          lexer.errorReporter.errors.first.message,
          contains('Invalid Unicode escape sequence'),
        );
      });

      test('should report error for unterminated string', () {
        final source = '"Unterminated string';
        final lexer = Lexer(source);
        final tokens = lexer.scanTokens();
        
        expect(lexer.errorReporter.hasErrors, isTrue);
        expect(
          lexer.errorReporter.errors.first.message,
          equals('Unterminated string literal'),
        );
      });

      test('should handle multi-line strings', () {
        final source = '"Line 1\nLine 2\nLine 3"';
        final tokens = scanTokens(source);
        
        expectToken(
          tokens[0],
          type: TokenType.string,
          lexeme: '"Line 1\nLine 2\nLine 3"',
          value: 'Line 1\nLine 2\nLine 3',
        );
      });
    });

    group('Identifiers and keywords', () {
      test('should scan identifiers', () {
        final source = 'identifier _identifier identifier123';
        final tokens = scanTokens(source);
        
        expectTokenTypes(tokens, [
          TokenType.identifier,
          TokenType.identifier,
          TokenType.identifier,
          TokenType.eof,
        ]);
      });

      test('should recognize all keywords', () {
        // Test a subset of keywords from different categories
        final source = 'workspace model views styles person softwareSystem container relationship tags';
        final tokens = scanTokens(source);
        
        expectTokenTypes(tokens, [
          TokenType.workspace,
          TokenType.model,
          TokenType.views,
          TokenType.styles,
          TokenType.person,
          TokenType.softwareSystem,
          TokenType.container,
          TokenType.relationship,
          TokenType.tags,
          TokenType.eof,
        ]);
      });

      test('should scan view-related keywords', () {
        final source = 'systemLandscape systemContext container component dynamic deployment filtered custom image';
        final tokens = scanTokens(source);
        
        expectTokenTypes(tokens, [
          TokenType.systemLandscape,
          TokenType.systemContext,
          TokenType.containerView,
          TokenType.componentView,
          TokenType.dynamicView,
          TokenType.deploymentView,
          TokenType.filteredView,
          TokenType.customView,
          TokenType.imageView,
          TokenType.eof,
        ]);
      });

      test('should scan styling keywords', () {
        final source = 'shape icon color background stroke fontSize border opacity width height thickness routing position';
        final tokens = scanTokens(source);
        
        expectTokenTypes(tokens, [
          TokenType.shape,
          TokenType.icon,
          TokenType.color,
          TokenType.background,
          TokenType.stroke,
          TokenType.fontSize,
          TokenType.border,
          TokenType.opacity,
          TokenType.width,
          TokenType.height,
          TokenType.thickness,
          TokenType.routing,
          TokenType.position,
          TokenType.eof,
        ]);
      });
    });

    group('Error handling', () {
      test('should report error for unexpected characters', () {
        final source = '~';  // ~ is not a valid token
        final lexer = Lexer(source);
        final tokens = lexer.scanTokens();
        
        expect(lexer.errorReporter.hasErrors, isTrue);
        expect(
          lexer.errorReporter.errors.first.message,
          equals('Unexpected character: ~'),
        );
      });

      test('should continue lexing after errors', () {
        final source = '~ { } ~';  // Contains two invalid characters
        final lexer = Lexer(source);
        final tokens = lexer.scanTokens();
        
        expect(lexer.errorReporter.errors.length, equals(2));
        expectTokenTypes(tokens, [
          TokenType.leftBrace,
          TokenType.rightBrace,
          TokenType.eof,
        ]);
      });
    });

    group('Real-world examples', () {
      test('should lex a simple workspace definition', () {
        final source = '''
workspace {
  model {
    user = person "User"
    system = softwareSystem "System" {
      component = container "Component" {
        description "This is a component"
        technology "Technology"
      }
    }
    
    user -> system "Uses"
  }
}
''';
        final tokens = scanTokens(source);
        
        // Test just the beginning to keep it manageable
        expectTokenTypes(tokens.sublist(0, 5), [
          TokenType.workspace,
          TokenType.leftBrace,
          TokenType.model,
          TokenType.leftBrace,
          TokenType.identifier, // user
        ]);
        
        // Ensure we got a complete token stream by checking EOF
        expect(tokens.last.type, equals(TokenType.eof));
      });

      test('should lex a component definition with properties', () {
        final source = '''
component "Name" {
  description "Description"
  technology "Technology"
  tags "Tag1,Tag2"
  url "http://example.com"
  properties {
    key1 "value1"
    key2 "value2"
  }
}
''';
        final tokens = scanTokens(source);
        
        // Verify we have the right keywords
        expect(tokens.any((t) => t.type == TokenType.component), isTrue);
        expect(tokens.any((t) => t.type == TokenType.description), isTrue);
        expect(tokens.any((t) => t.type == TokenType.technology), isTrue);
        expect(tokens.any((t) => t.type == TokenType.tags), isTrue);
        expect(tokens.any((t) => t.type == TokenType.url), isTrue);
        expect(tokens.any((t) => t.type == TokenType.properties), isTrue);
        
        // Ensure we got a complete token stream by checking EOF
        expect(tokens.last.type, equals(TokenType.eof));
      });
    });
    
    group('Documentation and decisions keywords', () {
      test('should correctly identify documentation and decisions as keywords', () {
        final source = '''
workspace {
  documentation {
    content = "This is documentation"
  }
  
  decisions {
    decision "ADR-001" {
      title = "Test Decision"
    }
  }
  
  // These should be identifiers, not keywords
  myDocumentation = "Not a keyword"
  myDecisions = "Not a keyword"
}
''';
        final tokens = scanTokens(source);
        
        // Print all tokens for debugging
        print('\n--- DEBUG: TOKENS FOR DOCUMENTATION/DECISIONS TEST ---');
        tokens.forEach((token) {
          print('Token: ${token.type} | Lexeme: "${token.lexeme}" | Line: ${token.line} | Column: ${token.column}');
        });
        print('--- END DEBUG ---\n');
        
        // Find documentation and decisions tokens
        final docToken = tokens.firstWhere(
          (t) => t.lexeme == 'documentation', 
          orElse: () => Token(type: TokenType.error, lexeme: 'not found', position: SourcePosition(line: 0, column: 0, offset: 0))
        );
        
        final decisionsToken = tokens.firstWhere(
          (t) => t.lexeme == 'decisions', 
          orElse: () => Token(type: TokenType.error, lexeme: 'not found', position: SourcePosition(line: 0, column: 0, offset: 0))
        );
        
        // Find the identifier tokens for myDocumentation and myDecisions
        final myDocumentationToken = tokens.firstWhere(
          (t) => t.lexeme == 'myDocumentation', 
          orElse: () => Token(type: TokenType.error, lexeme: 'not found', position: SourcePosition(line: 0, column: 0, offset: 0))
        );
        
        final myDecisionsToken = tokens.firstWhere(
          (t) => t.lexeme == 'myDecisions', 
          orElse: () => Token(type: TokenType.error, lexeme: 'not found', position: SourcePosition(line: 0, column: 0, offset: 0))
        );
        
        // Check that the tokens are of the correct type
        expect(docToken.type, equals(TokenType.documentation), 
               reason: "'documentation' should be recognized as a keyword, not an identifier");
               
        expect(decisionsToken.type, equals(TokenType.decisions), 
               reason: "'decisions' should be recognized as a keyword, not an identifier");
               
        expect(myDocumentationToken.type, equals(TokenType.identifier), 
               reason: "'myDocumentation' should be an identifier, not a keyword");
               
        expect(myDecisionsToken.type, equals(TokenType.identifier), 
               reason: "'myDecisions' should be an identifier, not a keyword");
      });
      
      test('should correctly identify isolated documentation and decisions tokens', () {
        // This test tries to isolate the tokens on their own lines to clearly see the lexer's behavior
        final source = '''
documentation
decisions
''';
        final tokens = scanTokens(source);
        
        // Print all tokens for debugging
        print('\n--- DEBUG: TOKENS FOR ISOLATED DOCUMENTATION/DECISIONS TEST ---');
        tokens.forEach((token) {
          print('Token: ${token.type} | Lexeme: "${token.lexeme}" | Line: ${token.line} | Column: ${token.column}');
        });
        print('--- END DEBUG ---\n');
        
        // Check the types
        expect(tokens.length, equals(3), reason: "Should have 2 tokens plus EOF");
        expect(tokens[0].type, equals(TokenType.documentation), reason: "First token should be documentation keyword");
        expect(tokens[1].type, equals(TokenType.decisions), reason: "Second token should be decisions keyword");
      });
    });
  });
}