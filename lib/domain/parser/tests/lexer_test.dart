import 'package:test/test.dart';
import '../lexer/lexer.dart';
import '../lexer/token.dart';

void main() {
  group('Lexer tests', () {
    test('Empty source produces only EOF token', () {
      final lexer = Lexer('');
      final tokens = lexer.scanTokens();

      expect(tokens.length, equals(1));
      expect(tokens[0].type, equals(TokenType.eof));
    });

    test('White space is ignored', () {
      final lexer = Lexer('   \t\r\n  ');
      final tokens = lexer.scanTokens();

      expect(tokens.length, equals(1));
      expect(tokens[0].type, equals(TokenType.eof));
    });

    test('Single character tokens are recognized', () {
      final lexer = Lexer('{}(),.;:+-*/|!#@');
      final tokens = lexer.scanTokens();

      // Check each token type
      expect(tokens[0].type, equals(TokenType.leftBrace));
      expect(tokens[1].type, equals(TokenType.rightBrace));
      expect(tokens[2].type, equals(TokenType.leftParen));
      expect(tokens[3].type, equals(TokenType.rightParen));
      expect(tokens[4].type, equals(TokenType.comma));
      expect(tokens[5].type, equals(TokenType.dot));
      expect(tokens[6].type, equals(TokenType.semicolon));
      expect(tokens[7].type, equals(TokenType.colon));
      expect(tokens[8].type, equals(TokenType.plus));
      expect(tokens[9].type, equals(TokenType.minus));
      expect(tokens[10].type, equals(TokenType.star));
      expect(tokens[11].type, equals(TokenType.slash));
      expect(tokens[12].type, equals(TokenType.pipe));
      expect(tokens[13].type, equals(TokenType.bang));
      expect(tokens[14].type, equals(TokenType.hash));
      expect(tokens[15].type, equals(TokenType.at));

      // Check total count
      expect(tokens.length, equals(17)); // 16 tokens + EOF
    });

    test('Arrow token is recognized', () {
      final lexer = Lexer('->');
      final tokens = lexer.scanTokens();

      expect(tokens[0].type, equals(TokenType.arrow));
    });

    test('Comments are ignored', () {
      final lexer = Lexer('''
        // Line comment
        /* Block comment */
        /* Nested /* block */ comment */
        code // Comment at end of line
      ''');
      final tokens = lexer.scanTokens();

      // Should only have the 'code' identifier and EOF
      expect(tokens.length, equals(2));
      expect(tokens[0].type, equals(TokenType.identifier));
      expect(tokens[0].lexeme, equals('code'));
    });

    test('String literals are tokenized correctly', () {
      final lexer = Lexer('"This is a string" \'This is also a string\'');
      final tokens = lexer.scanTokens();

      expect(tokens.length, equals(3)); // 2 strings + EOF
      expect(tokens[0].type, equals(TokenType.string));
      expect(tokens[0].value, equals('This is a string'));
      expect(tokens[1].type, equals(TokenType.string));
      expect(tokens[1].value, equals('This is also a string'));
    });

    test('String literals with escape sequences', () {
      final lexer = Lexer('"Line1\\nLine2\\tTabbed\\r\\nCRLF"');
      final tokens = lexer.scanTokens();

      expect(tokens[0].type, equals(TokenType.string));
      expect(tokens[0].value, equals('Line1\nLine2\tTabbed\r\nCRLF'));
    });

    test('Number literals are tokenized correctly', () {
      final lexer = Lexer('123 45.67');
      final tokens = lexer.scanTokens();

      expect(tokens.length, equals(3)); // 2 numbers + EOF
      expect(tokens[0].type, equals(TokenType.integer));
      expect(tokens[0].value, equals(123));
      expect(tokens[1].type, equals(TokenType.double));
      expect(tokens[1].value, equals(45.67));
    });

    test('Identifiers are tokenized correctly', () {
      final lexer = Lexer('identifier _underscore camelCase');
      final tokens = lexer.scanTokens();

      expect(tokens.length, equals(4)); // 3 identifiers + EOF
      expect(tokens[0].type, equals(TokenType.identifier));
      expect(tokens[0].lexeme, equals('identifier'));
      expect(tokens[1].type, equals(TokenType.identifier));
      expect(tokens[1].lexeme, equals('_underscore'));
      expect(tokens[2].type, equals(TokenType.identifier));
      expect(tokens[2].lexeme, equals('camelCase'));
    });

    test('Keywords are recognized', () {
      final lexer = Lexer('workspace model person softwareSystem container component');
      final tokens = lexer.scanTokens();

      expect(tokens.length, equals(7)); // 6 keywords + EOF
      expect(tokens[0].type, equals(TokenType.workspace));
      expect(tokens[1].type, equals(TokenType.model));
      expect(tokens[2].type, equals(TokenType.person));
      expect(tokens[3].type, equals(TokenType.softwareSystem));
      expect(tokens[4].type, equals(TokenType.container));
      expect(tokens[5].type, equals(TokenType.component));
    });

    test('Additional keywords are recognized', () {
      final lexer = Lexer('group enterprise terminology properties url this location');
      final tokens = lexer.scanTokens();

      expect(tokens.length, equals(8)); // 7 keywords + EOF
      expect(tokens[0].type, equals(TokenType.group));
      expect(tokens[1].type, equals(TokenType.enterprise));
      expect(tokens[2].type, equals(TokenType.terminology));
      expect(tokens[3].type, equals(TokenType.properties));
      expect(tokens[4].type, equals(TokenType.url));
      expect(tokens[5].type, equals(TokenType.this_));
      expect(tokens[6].type, equals(TokenType.location));
    });

    test('Shape tokens are recognized', () {
      final lexer = Lexer('shape "Box" shape "Circle" shape "Cylinder" shape "Person"');
      final tokens = lexer.scanTokens();

      // Check for shape keywords (should be tokenized as strings first, then referenced by value)
      final strings = tokens.where((t) => t.type == TokenType.string).map((t) => t.value).toList();
      expect(strings, contains('Box'));
      expect(strings, contains('Circle'));
      expect(strings, contains('Cylinder'));
      expect(strings, contains('Person'));
    });

    test('Boolean literals are tokenized with correct values', () {
      final lexer = Lexer('true false');
      final tokens = lexer.scanTokens();

      expect(tokens.length, equals(3)); // 2 booleans + EOF
      expect(tokens[0].type, equals(TokenType.boolean));
      expect(tokens[0].value, equals(true));
      expect(tokens[1].type, equals(TokenType.boolean));
      expect(tokens[1].value, equals(false));
    });

    test('Directives are tokenized correctly', () {
      final lexer = Lexer('!identifiers hierarchical');
      final tokens = lexer.scanTokens();

      expect(tokens.length, equals(3)); // directive + identifier + EOF
      expect(tokens[0].type, equals(TokenType.identifiers));
      expect(tokens[1].type, equals(TokenType.identifier));
      expect(tokens[1].lexeme, equals('hierarchical'));
    });

    test('Position tracking in tokens', () {
      final lexer = Lexer('line1\nline2\n  indented');
      final tokens = lexer.scanTokens();

      // Check positions
      expect(tokens[0].line, equals(1));
      expect(tokens[0].column, equals(1));
      expect(tokens[1].line, equals(2));
      expect(tokens[1].column, equals(1));
      expect(tokens[2].line, equals(3));
      expect(tokens[2].column, equals(3));
    });

    test('Error reporting for invalid characters', () {
      final lexer = Lexer('valid \$ ~'); // $ and ~ are not valid in the language
      final tokens = lexer.scanTokens();

      expect(lexer.errorReporter.hasErrors, isTrue);
      expect(lexer.errorReporter.errors.length, equals(2));
    });

    test('Error reporting for unterminated string', () {
      final lexer = Lexer('"unterminated');
      final tokens = lexer.scanTokens();

      expect(lexer.errorReporter.hasErrors, isTrue);
      expect(lexer.errorReporter.errors[0].message, contains('Unterminated string'));
    });

    test('Complex DSL example', () {
      const source = '''
        workspace "Banking System" "This is a banking system" {
          model {
            !identifiers hierarchical

            enterprise "Acme Corp" {
              customer = person "Customer" "A customer of the bank" {
                tags "external"
                url "https://example.com/customer"
                properties {
                  "userType" = "retail"
                }
              }
            }

            bank = softwareSystem "Bank" {
              webapp = container "Web Application" "Provides banking functionality" "Java" {
                tags "Web"

                controller = component "Controller" "Handles HTTP requests" "Spring MVC"
                service = component "Service" "Business logic" "Spring"
              }

              database = container "Database" "Stores customer data" "PostgreSQL" {
                tags "Database"
              }

              deploymentEnvironment "Production" {
                aws = deploymentNode "AWS" "Amazon Web Services" {
                  ec2 = deploymentNode "EC2" "Web Server" "Amazon EC2" {
                    containerInstance webapp
                  }

                  rds = infrastructureNode "RDS" "Database Server" "Amazon RDS"
                }
              }
            }

            customer -> webapp "Uses" "HTTPS" {
              tags "Important"
              technology "REST/JSON"
            }
            webapp -> service "Uses"
            service -> database "Reads from and writes to" "JDBC"
          }

          views {
            systemLandscape "landscape" "Enterprise Landscape" {
              include *
              autoLayout "tb" 300 100
            }

            systemContext bank "context" "System Context" {
              include *
              autoLayout
            }

            containerView bank "containers" "Containers" {
              include *
              exclude "Database"
              autoLayout
            }

            styles {
              element "Person" {
                shape "Person"
                background "#08427B"
                color "#FFFFFF"
                fontSize 22
              }

              element "Database" {
                shape "Cylinder"
                background "#E3F2FD"
              }

              relationship "Important" {
                thickness 4
                color "#ff0000"
                style "Solid"
              }
            }

            themes "https://example.com/themes/default.json"
          }

          branding {
            logo "https://example.com/logo.png"
            font "Open Sans"
          }
        }
      ''';

      final lexer = Lexer(source);
      final tokens = lexer.scanTokens().where((t) => t.type != TokenType.eof).toList();

      // Check for specific tokens
      expect(tokens.any((t) => t.type == TokenType.workspace), isTrue);
      expect(tokens.any((t) => t.type == TokenType.model), isTrue);
      expect(tokens.any((t) => t.type == TokenType.identifiers), isTrue);
      expect(tokens.any((t) => t.type == TokenType.enterprise), isTrue);
      expect(tokens.any((t) => t.type == TokenType.person), isTrue);
      expect(tokens.any((t) => t.type == TokenType.softwareSystem), isTrue);
      expect(tokens.any((t) => t.type == TokenType.container), isTrue);
      expect(tokens.any((t) => t.type == TokenType.component), isTrue);
      expect(tokens.any((t) => t.type == TokenType.deploymentEnvironment), isTrue);
      expect(tokens.any((t) => t.type == TokenType.deploymentNode), isTrue);
      expect(tokens.any((t) => t.type == TokenType.infrastructureNode), isTrue);
      expect(tokens.any((t) => t.type == TokenType.containerInstance), isTrue);
      expect(tokens.any((t) => t.type == TokenType.arrow), isTrue);
      expect(tokens.any((t) => t.type == TokenType.views), isTrue);
      expect(tokens.any((t) => t.type == TokenType.systemLandscape), isTrue);
      expect(tokens.any((t) => t.type == TokenType.systemContext), isTrue);
      expect(tokens.any((t) => t.type == TokenType.containerView), isTrue);
      expect(tokens.any((t) => t.type == TokenType.autoLayout), isTrue);
      expect(tokens.any((t) => t.type == TokenType.styles), isTrue);
      expect(tokens.any((t) => t.type == TokenType.themes), isTrue);
      expect(tokens.any((t) => t.type == TokenType.branding), isTrue);

      // Check for string literals
      final strings = tokens.where((t) => t.type == TokenType.string).map((t) => t.value).toList();
      expect(strings, contains('Banking System'));
      expect(strings, contains('This is a banking system'));
      expect(strings, contains('Acme Corp'));
      expect(strings, contains('Customer'));
      expect(strings, contains('Bank'));
      expect(strings, contains('Web Application'));
      expect(strings, contains('AWS'));
      expect(strings, contains('https://example.com/logo.png'));

      // No errors should be reported
      expect(lexer.errorReporter.hasErrors, isFalse);
    });
  });
}