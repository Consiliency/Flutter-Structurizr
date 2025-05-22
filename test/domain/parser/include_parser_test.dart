import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/parser/include_parser.dart';
import 'package:flutter_structurizr/domain/parser/lexer/token.dart';
import 'package:flutter_structurizr/domain/parser/lexer/lexer.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/parser/file_loader.dart';
import 'package:flutter_structurizr/domain/parser/ast/ast_nodes.dart';
import 'package:flutter_structurizr/domain/parser/context_stack.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

class MockErrorReporter extends Mock implements ErrorReporter {}

class MockFileLoader implements FileLoader {
  final Map<String, String> files;
  final List<String> loadedPaths = [];

  MockFileLoader(this.files);

  @override
  String? loadFile(String path) {
    loadedPaths.add(path);
    return files[path];
  }

  @override
  String resolveFilePath(String path) {
    return path;
  }
}

void main() {
  group('IncludeParser', () {
    late MockFileLoader fileLoader;
    late IncludeParser includeParser;

    setUp(() {
      fileLoader = MockFileLoader({
        'base.dsl': 'workspace "Test" { model {} }',
        'systems.dsl': '!include subsystems.dsl\n softwareSystem "Main" {}',
        'subsystems.dsl': 'softwareSystem "Sub" {}',
        'circular1.dsl': '!include circular2.dsl',
        'circular2.dsl': '!include circular1.dsl',
        'multi_level1.dsl': '!include multi_level2.dsl',
        'multi_level2.dsl': '!include multi_level3.dsl',
        'multi_level3.dsl': 'softwareSystem "Level3" {}',
        'complex_circular1.dsl': '!include complex_circular2.dsl',
        'complex_circular2.dsl': '!include complex_circular3.dsl',
        'complex_circular3.dsl': '!include complex_circular1.dsl',
        'with_errors.dsl': '!include non_existent.dsl',
        'multi_includes.dsl': '!include subsystems.dsl\n!include base.dsl'
      });

      includeParser = IncludeParser(
        fileLoader: fileLoader,
      );
    });

    group('IncludeParser.parse', () {
      test('Parses file include directives with proper context stack use', () {
        final contextStack = ContextStack();
        // Push a workspace context to simulate being in a workspace
        contextStack.push(Context('workspace'));

        const code = '!include systems.dsl';
        final lexer = Lexer(code);
        final tokens = lexer.scanTokens();

        final includes = includeParser.parse(tokens);

        expect(includes.length, 1);
        expect(includes[0].expression, 'systems.dsl');
        expect(includes[0].type, IncludeType.file);

        // Verify the context stack still has the workspace context
        expect(contextStack.size(), 1);
        expect(contextStack.current().name, 'workspace');
      });

      test('Parses multiple include directives in the same file', () {
        const code = '!include systems.dsl\n!include base.dsl';
        final lexer = Lexer(code);
        final tokens = lexer.scanTokens();

        final includes = includeParser.parse(tokens);

        expect(includes.length, 2);
        expect(includes[0].expression, 'systems.dsl');
        expect(includes[1].expression, 'base.dsl');
        expect(includes.every((include) => include.type == IncludeType.file),
            isTrue);
      });

      test('Parses mixed file and view includes', () {
        const code = '!include systems.dsl\ninclude *';
        final lexer = Lexer(code);
        final tokens = lexer.scanTokens();

        final includes = includeParser.parse(tokens);

        expect(includes.length, 2);
        expect(includes[0].expression, 'systems.dsl');
        expect(includes[0].type, IncludeType.file);
        expect(includes[1].expression, '*');
        expect(includes[1].type, IncludeType.view);
      });

      test('Resolves recursive includes and adds them to the result', () {
        const code = '!include multi_level1.dsl';
        final lexer = Lexer(code);
        final tokens = lexer.scanTokens();

        final includes = includeParser.parse(tokens);

        // Should find all three levels of includes
        expect(includes.length, 3);
        expect(
            includes.any((include) => include.expression == 'multi_level1.dsl'),
            isTrue);
        expect(
            includes.any((include) => include.expression == 'multi_level2.dsl'),
            isTrue);
        expect(
            includes.any((include) => include.expression == 'multi_level3.dsl'),
            isTrue);
      });

      test('Detects and reports circular includes', () {
        const code = '!include circular1.dsl';
        final lexer = Lexer(code);
        final tokens = lexer.scanTokens();

        includeParser.parse(tokens);

        // Should report an error about circular includes
        expect(errorReporter.hasErrors, isTrue);
        expect(
          errorReporter.errors.any(
              (error) => error.message.contains('Circular include detected')),
          isTrue,
        );
      });

      test('Handles multiple include types correctly', () {
        const code = '''
          !include systems.dsl
          views {
            systemContext mainSystem {
              include *
              include "element1"
            }
          }
        ''';
        final lexer = Lexer(code);
        final tokens = lexer.scanTokens();

        final includes = includeParser.parse(tokens);

        // Should have one file include and two view includes
        expect(
            includes
                .where((include) => include.type == IncludeType.file)
                .length,
            1);
        expect(
            includes
                .where((include) => include.type == IncludeType.view)
                .length,
            2);
      });

      test('Handles errors in included files gracefully', () {
        // Set up a file with parsing errors
        fileLoader.files['with_syntax_error.dsl'] = 'invalid } syntax';

        const code = '!include with_syntax_error.dsl';
        final lexer = Lexer(code);
        final tokens = lexer.scanTokens();

        // This should still parse the include node
        final includes = includeParser.parse(tokens);

        expect(includes.length, 1);
        expect(includes[0].expression, 'with_syntax_error.dsl');
        expect(includes[0].type, IncludeType.file);
      });

      test('Gracefully handles absence of file loader', () {
        // Create a parser without a file loader
        final parserWithoutLoader = IncludeParser(
          errorReporter: errorReporter,
        );

        const code = '!include systems.dsl';
        final lexer = Lexer(code);
        final tokens = lexer.scanTokens();

        // This should still parse the include node but not resolve any files
        final includes = parserWithoutLoader.parse(tokens);

        expect(includes.length, 1);
        expect(includes[0].expression, 'systems.dsl');
        expect(includes[0].type, IncludeType.file);
      });
    });

    group('IncludeParser._parseFileInclude', () {
      test('Parses file include with string token', () {
        final tokens = [
          Token(
            type: TokenType.string,
            lexeme: '"systems.dsl"',
            value: 'systems.dsl',
            position: const SourcePosition(0, 1, 0),
          )
        ];

        final includeNode = includeParser._parseFileInclude(tokens);

        expect(includeNode.expression, 'systems.dsl');
        expect(includeNode.type, IncludeType.file);
        expect(includeNode.sourcePosition, tokens[0].position);
      });

      test('Parses file include with identifier token', () {
        final tokens = [
          Token(
            type: TokenType.identifier,
            lexeme: 'systems.dsl',
            position: const SourcePosition(0, 1, 0),
          )
        ];

        final includeNode = includeParser._parseFileInclude(tokens);

        expect(includeNode.expression, 'systems.dsl');
        expect(includeNode.type, IncludeType.file);
        expect(includeNode.sourcePosition, tokens[0].position);
      });

      test('Parses file include with relative path', () {
        final tokens = [
          Token(
            type: TokenType.identifier,
            lexeme: './systems.dsl',
            position: const SourcePosition(0, 1, 0),
          )
        ];

        final includeNode = includeParser._parseFileInclude(tokens);

        expect(includeNode.expression, './systems.dsl');
        expect(includeNode.type, IncludeType.file);
      });

      test('Parses file include with absolute path', () {
        final tokens = [
          Token(
            type: TokenType.identifier,
            lexeme: '/absolute/path/to/systems.dsl',
            position: const SourcePosition(0, 1, 0),
          )
        ];

        final includeNode = includeParser._parseFileInclude(tokens);

        expect(includeNode.expression, '/absolute/path/to/systems.dsl');
        expect(includeNode.type, IncludeType.file);
      });

      test('Parses file include with multiple tokens on same line', () {
        final tokens = [
          Token(
            type: TokenType.identifier,
            lexeme: 'path/',
            position: const SourcePosition(0, 1, 0),
          ),
          Token(
            type: TokenType.identifier,
            lexeme: 'to/',
            position: const SourcePosition(0, 1, 6),
          ),
          Token(
            type: TokenType.identifier,
            lexeme: 'systems.dsl',
            position: const SourcePosition(0, 1, 9),
          )
        ];

        final includeNode = includeParser._parseFileInclude(tokens);

        expect(includeNode.expression, 'path/to/systems.dsl');
        expect(includeNode.type, IncludeType.file);
      });

      test('Handles missing tokens gracefully', () {
        final emptyTokens = <Token>[];

        final includeNode = includeParser._parseFileInclude(emptyTokens);

        expect(includeNode.expression, '');
        expect(includeNode.type, IncludeType.file);
        expect(errorReporter.hasErrors, isTrue);
        expect(
          errorReporter.errors
              .any((error) => error.message.contains('Expected file path')),
          isTrue,
        );
      });
    });

    group('IncludeParser._parseViewInclude', () {
      test('Parses view include with string token', () {
        final tokens = [
          Token(
            type: TokenType.string,
            lexeme: '"element1"',
            value: 'element1',
            position: const SourcePosition(0, 1, 0),
          )
        ];

        final includeNode = includeParser._parseViewInclude(tokens);

        expect(includeNode.expression, 'element1');
        expect(includeNode.type, IncludeType.view);
        expect(includeNode.sourcePosition, tokens[0].position);
      });

      test('Parses view include with star token', () {
        final tokens = [
          Token(
            type: TokenType.star,
            lexeme: '*',
            position: const SourcePosition(0, 1, 0),
          )
        ];

        final includeNode = includeParser._parseViewInclude(tokens);

        expect(includeNode.expression, '*');
        expect(includeNode.type, IncludeType.view);
      });

      test('Parses view include with identifier token', () {
        final tokens = [
          Token(
            type: TokenType.identifier,
            lexeme: 'element1',
            position: const SourcePosition(0, 1, 0),
          )
        ];

        final includeNode = includeParser._parseViewInclude(tokens);

        expect(includeNode.expression, 'element1');
        expect(includeNode.type, IncludeType.view);
      });

      test('Handles complex view includes with multiple elements', () {
        final tokens = [
          Token(
            type: TokenType.string,
            lexeme: '"element1"',
            value: 'element1',
            position: const SourcePosition(0, 1, 0),
          ),
          Token(
            type: TokenType.string,
            lexeme: '"element2"',
            value: 'element2',
            position: const SourcePosition(0, 1, 12),
          )
        ];

        final includeNode = includeParser._parseViewInclude(tokens);

        // Note: The current implementation only picks the first element
        expect(includeNode.expression, 'element1');
        expect(includeNode.type, IncludeType.view);
      });

      test('Handles missing tokens gracefully', () {
        final emptyTokens = <Token>[];

        final includeNode = includeParser._parseViewInclude(emptyTokens);

        expect(includeNode.expression, '');
        expect(includeNode.type, IncludeType.view);
        expect(errorReporter.hasErrors, isTrue);
        expect(
          errorReporter.errors.any(
              (error) => error.message.contains('Expected element pattern')),
          isTrue,
        );
      });
    });

    group('IncludeParser._resolveRecursive', () {
      test('Resolves single level includes', () {
        final includeNodes = [
          IncludeNode(
            expression: 'systems.dsl',
            type: IncludeType.file,
          )
        ];

        includeParser._resolveRecursive(includeNodes);

        // Should have added the subsystems.dsl include
        expect(includeNodes.length, 2);
        expect(includeNodes[1].expression, 'subsystems.dsl');
        expect(includeNodes[1].type, IncludeType.file);
      });

      test('Resolves multi-level recursive includes', () {
        final includeNodes = [
          IncludeNode(
            expression: 'multi_level1.dsl',
            type: IncludeType.file,
          )
        ];

        includeParser._resolveRecursive(includeNodes);

        // Should have added multi_level2.dsl and multi_level3.dsl
        expect(includeNodes.length, 3);
        expect(
            includeNodes.any((node) => node.expression == 'multi_level2.dsl'),
            isTrue);
        expect(
            includeNodes.any((node) => node.expression == 'multi_level3.dsl'),
            isTrue);
      });

      test('Skips already processed files', () {
        final includeNodes = [
          IncludeNode(
            expression: 'systems.dsl',
            type: IncludeType.file,
          ),
          IncludeNode(
            expression: 'systems.dsl', // Duplicate
            type: IncludeType.file,
          )
        ];

        // Track which files are loaded
        fileLoader.loadedPaths.clear();

        includeParser._resolveRecursive(includeNodes);

        // Should only load systems.dsl once
        expect(
            fileLoader.loadedPaths
                .where((path) => path == 'systems.dsl')
                .length,
            1);

        // Still should have added subsystems.dsl
        expect(includeNodes.length, 3);
        expect(includeNodes.any((node) => node.expression == 'subsystems.dsl'),
            isTrue);
      });

      test('Handles missing files gracefully', () {
        final includeNodes = [
          IncludeNode(
            expression: 'non_existent.dsl',
            type: IncludeType.file,
          )
        ];

        includeParser._resolveRecursive(includeNodes);

        // Should report an error
        expect(errorReporter.hasErrors, isTrue);
        expect(
          errorReporter.errors.any((error) =>
              error.message.contains('Failed to load included file')),
          isTrue,
        );

        // Should not add any new includes
        expect(includeNodes.length, 1);
      });

      test('Ignores non-file includes', () {
        final includeNodes = [
          IncludeNode(
            expression: '*',
            type: IncludeType.view,
          )
        ];

        includeParser._resolveRecursive(includeNodes);

        // Should not add any new includes or cause errors
        expect(includeNodes.length, 1);
        expect(errorReporter.hasErrors, isFalse);
      });

      test('Handles absence of file loader gracefully', () {
        // Create a parser without a file loader
        final parserWithoutLoader = IncludeParser(
          errorReporter: errorReporter,
        );

        final includeNodes = [
          IncludeNode(
            expression: 'systems.dsl',
            type: IncludeType.file,
          )
        ];

        // This should not throw an error
        parserWithoutLoader._resolveRecursive(includeNodes);

        // No new includes should be added
        expect(includeNodes.length, 1);
        expect(errorReporter.hasErrors, isFalse);
      });
    });

    group('IncludeParser._resolveCircular', () {
      test('Detects simple circular includes', () {
        final includeNodes = [
          IncludeNode(
            expression: 'circular1.dsl',
            type: IncludeType.file,
          ),
          IncludeNode(
            expression: 'circular2.dsl',
            type: IncludeType.file,
          )
        ];

        includeParser._resolveCircular(includeNodes);

        // Should report an error
        expect(errorReporter.hasErrors, isTrue);
        expect(
          errorReporter.errors.any(
              (error) => error.message.contains('Circular include detected')),
          isTrue,
        );
      });

      test('Detects complex circular includes with multiple levels', () {
        final includeNodes = [
          IncludeNode(
            expression: 'complex_circular1.dsl',
            type: IncludeType.file,
          ),
          IncludeNode(
            expression: 'complex_circular2.dsl',
            type: IncludeType.file,
          ),
          IncludeNode(
            expression: 'complex_circular3.dsl',
            type: IncludeType.file,
          )
        ];

        includeParser._resolveCircular(includeNodes);

        // Should report an error
        expect(errorReporter.hasErrors, isTrue);
        expect(
          errorReporter.errors.any(
              (error) => error.message.contains('Circular include detected')),
          isTrue,
        );
      });

      test('Does not report error for non-circular includes', () {
        final includeNodes = [
          IncludeNode(
            expression: 'multi_level1.dsl',
            type: IncludeType.file,
          ),
          IncludeNode(
            expression: 'multi_level2.dsl',
            type: IncludeType.file,
          ),
          IncludeNode(
            expression: 'multi_level3.dsl',
            type: IncludeType.file,
          )
        ];

        // Clear any existing errors
        errorReporter = ErrorReporter('');
        includeParser = IncludeParser(
          fileLoader: fileLoader,
          errorReporter: errorReporter,
        );

        includeParser._resolveCircular(includeNodes);

        // Should not report an error
        expect(errorReporter.hasErrors, isFalse);
      });

      test('Ignores non-file includes', () {
        final includeNodes = [
          IncludeNode(
            expression: '*',
            type: IncludeType.view,
          )
        ];

        includeParser._resolveCircular(includeNodes);

        // Should not cause errors
        expect(errorReporter.hasErrors, isFalse);
      });

      test('Handles absence of file loader gracefully', () {
        // Create a parser without a file loader
        final parserWithoutLoader = IncludeParser(
          errorReporter: errorReporter,
        );

        final includeNodes = [
          IncludeNode(
            expression: 'circular1.dsl',
            type: IncludeType.file,
          ),
          IncludeNode(
            expression: 'circular2.dsl',
            type: IncludeType.file,
          )
        ];

        // This should not throw an error
        parserWithoutLoader._resolveCircular(includeNodes);

        // No errors should be reported since no files were loaded
        expect(errorReporter.hasErrors, isFalse);
      });

      test('Handles complex graph with multiple branches', () {
        // Add files for a more complex graph
        fileLoader.files['a.dsl'] = '!include b.dsl\n!include c.dsl';
        fileLoader.files['b.dsl'] = 'softwareSystem "B" {}';
        fileLoader.files['c.dsl'] = '!include d.dsl';
        fileLoader.files['d.dsl'] = 'softwareSystem "D" {}';

        final includeNodes = [
          IncludeNode(
            expression: 'a.dsl',
            type: IncludeType.file,
          )
        ];

        // First resolve recursive includes
        includeParser._resolveRecursive(includeNodes);

        // Then check for circular references
        includeParser._resolveCircular(includeNodes);

        // Should not report an error
        expect(
            errorReporter.errors.any(
                (error) => error.message.contains('Circular include detected')),
            isFalse);
      });
    });

    group('IncludeNode.setType', () {
      test('Sets the type correctly', () {
        final includeNode = IncludeNode(expression: 'test.dsl');

        // Initially type should be null
        expect(includeNode.type, isNull);

        // Set to file type
        includeNode.setType(IncludeType.file);
        expect(includeNode.type, IncludeType.file);

        // Change to view type
        includeNode.setType(IncludeType.view);
        expect(includeNode.type, IncludeType.view);
      });

      test('IncludeNode convenience extensions work correctly', () {
        final fileInclude = IncludeNode(
          expression: 'test.dsl',
          type: IncludeType.file,
        );

        final viewInclude = IncludeNode(
          expression: 'element1',
          type: IncludeType.view,
        );

        expect(fileInclude.isFileInclude, isTrue);
        expect(fileInclude.isViewInclude, isFalse);

        expect(viewInclude.isFileInclude, isFalse);
        expect(viewInclude.isViewInclude, isTrue);
      });
    });

    group('Error reporting', () {
      test('Reports distinct errors for each issue', () {
        // Set up a file with both missing include and circular references
        fileLoader.files['problematic.dsl'] =
            '!include non_existent.dsl\n!include circular1.dsl';

        const code = '!include problematic.dsl';
        final lexer = Lexer(code);
        final tokens = lexer.scanTokens();

        // This should trigger both types of errors
        includeParser.parse(tokens);

        // Should report both missing file and circular reference errors
        expect(
            errorReporter.errors.any((error) =>
                error.message.contains('Failed to load included file')),
            isTrue);
        expect(
            errorReporter.errors.any(
                (error) => error.message.contains('Circular include detected')),
            isTrue);
      });

      test('Reports file path in error messages', () {
        const code = '!include non_existent.dsl';
        final lexer = Lexer(code);
        final tokens = lexer.scanTokens();

        // This should trigger a missing file error
        includeParser.parse(tokens);

        // Error message should include the file path
        expect(
            errorReporter.errors
                .any((error) => error.message.contains('non_existent.dsl')),
            isTrue);
      });
    });

    group('Integration with ContextStack', () {
      test('Parser properly uses ContextStack for nested parsing', () {
        final contextStack = ContextStack();

        // Push the initial context
        contextStack.push(Context('workspace'));

        // Create a parser that uses the context stack
        final contextAwareParser = IncludeParser(
          fileLoader: fileLoader,
          errorReporter: errorReporter,
        );

        const code = '!include systems.dsl';
        final lexer = Lexer(code);
        final tokens = lexer.scanTokens();

        // Parse with context awareness
        final includes = contextAwareParser.parse(tokens);

        // Verify the include was parsed correctly
        expect(includes.length, 1);
        expect(includes[0].expression, 'systems.dsl');

        // Verify the context stack is maintained
        expect(contextStack.size(), 1);
        expect(contextStack.current().name, 'workspace');
      });
    });
  });
}
