import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/parser/context_stack.dart';
import 'package:flutter_structurizr/domain/parser/parser.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/parser/lexer/token.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/model_element_node.dart';

void main() {
  group('Parse Error Handler', () {
    late Parser parser;
    late ContextStack contextStack;

    setUp(() {
      const testSource = 'workspace "Test" { model { } }';
      contextStack = ContextStack();
      parser = Parser(testSource);

      // Setup initial context
      contextStack.push(Context('workspace', data: {'name': 'Test'}));
    });

    test('handleError reports errors with context information', () {
      final error = ParseError('Test error message');

      // Set up parser to use our test contextStack
      parser.setContextStack(contextStack);

      // Track if error was reported
      var errorReported = false;
      int errorLine = 0;
      int errorColumn = 0;
      String errorMessage = '';
      String contextName = '';

      parser.setErrorReporterCallback((err) {
        errorReported = true;
        errorMessage = err.message;
        if (err.token != null) {
          errorLine = err.token!.position.line;
          errorColumn = err.token!.position.column;
        }

        // Verify context is used
        if (err.context != null) {
          contextName = err.context!.name;
        }
      });

      parser.handleError(error);

      expect(errorReported, isTrue);
      expect(errorMessage, equals('Test error message'));
      expect(contextName, equals('workspace'));
    });

    test('handleError includes current context from contextStack', () {
      // Setup nested contexts to simulate a real parsing situation
      contextStack.push(Context('model'));
      contextStack
          .push(Context('element', data: {'type': 'person', 'id': 'user'}));

      final error = ParseError('Error in element');

      parser.setContextStack(contextStack);

      var contextCaptured = false;
      Context? capturedContext;

      parser.setErrorReporterCallback((err) {
        contextCaptured = true;
        capturedContext = err.context;
      });

      parser.handleError(error);

      expect(contextCaptured, isTrue);
      expect(capturedContext, isNotNull);
      expect(capturedContext!.name, equals('element'));
      expect(capturedContext!.data['type'], equals('person'));
      expect(capturedContext!.data['id'], equals('user'));
    });

    test('handleError with token location includes position information', () {
      final token = Token(
          type: TokenType.identifier,
          lexeme: 'test',
          position: const SourcePosition(10, 5, 42));

      final error = ParseError('Test error with location', token: token);

      var positionCaptured = false;
      parser.setErrorReporterCallback((err) {
        positionCaptured = true;
        expect(err.token!.position.line, equals(10));
        expect(err.token!.position.column, equals(5));
        expect(err.token!.position.offset, equals(42));
      });

      parser.handleError(error);

      expect(positionCaptured, isTrue);
    });

    test('handleError with complex context provides detailed error information',
        () {
      // Setup a realistic parsing scenario with nested contexts
      contextStack.clear();
      contextStack.push(Context('workspace', data: {'name': 'Banking System'}));
      contextStack.push(Context('model'));
      contextStack.push(Context('softwareSystem',
          data: {'id': 'banking', 'name': 'Banking System'}));
      contextStack.push(
          Context('container', data: {'id': 'api', 'name': 'API Application'}));

      final token = Token(
          type: TokenType.identifier,
          lexeme: 'component',
          position: const SourcePosition(15, 3, 250));

      final error = ParseError('Invalid component declaration', token: token);

      parser.setContextStack(contextStack);

      var complexErrorCaptured = false;
      String? fullErrorPath;

      parser.setErrorReporterCallback((err) {
        complexErrorCaptured = true;
        fullErrorPath =
            err.getContextPath(); // Assuming this method exists or is similar
      });

      parser.handleError(error);

      expect(complexErrorCaptured, isTrue);
      expect(fullErrorPath, contains('workspace'));
      expect(fullErrorPath, contains('model'));
      expect(fullErrorPath, contains('softwareSystem'));
      expect(fullErrorPath, contains('container'));
    });

    test('handleError tracks number of reported errors', () {
      parser.resetErrorCount(); // Reset error count for test

      expect(parser.errorCount(), equals(0));

      parser.handleError(ParseError('Error 1'));
      expect(parser.errorCount(), equals(1));

      parser.handleError(ParseError('Error 2'));
      expect(parser.errorCount(), equals(2));
    });

    test('handleError can limit number of reported errors', () {
      parser.resetErrorCount();
      parser.setMaxErrorCount(3);

      // First three errors should be processed
      for (var i = 0; i < 3; i++) {
        expect(parser.handleError(ParseError('Error ${i + 1}')), isTrue);
      }

      // Fourth error should be ignored
      expect(parser.handleError(ParseError('Error 4')), isFalse);
      expect(parser.errorCount(), equals(3)); // Count stays at 3
    });

    test('handleError can recover from panic mode', () {
      parser.enterPanicMode();
      expect(parser.isInPanicMode(), isTrue);

      // Configure parser to exit panic mode
      parser.setRecoveryStrategy(() {
        parser.exitPanicMode();
        return true; // Indicate successful recovery
      });

      parser.handleError(ParseError('Error in panic mode'));

      expect(parser.isInPanicMode(), isFalse);
    });

    test('handleError properly categorizes errors by severity', () {
      var reportedSeverity = ErrorSeverity.info;

      parser.setErrorReporterCallback((err) {
        reportedSeverity = err.severity;
      });

      // Test with different severities
      parser
          .handleError(ParseError('Warning', severity: ErrorSeverity.warning));
      expect(reportedSeverity, equals(ErrorSeverity.warning));

      parser.handleError(ParseError('Error', severity: ErrorSeverity.error));
      expect(reportedSeverity, equals(ErrorSeverity.error));

      parser.handleError(
          ParseError('Fatal error', severity: ErrorSeverity.fatal));
      expect(reportedSeverity, equals(ErrorSeverity.fatal));
    });

    test('handleError gracefully handles null tokens', () {
      final error = ParseError('Error without token');

      var errorHandled = false;
      var hasToken = true;

      parser.setErrorReporterCallback((err) {
        errorHandled = true;
        hasToken = err.token != null;
      });

      parser.handleError(error);

      expect(errorHandled, isTrue);
      expect(hasToken, isFalse);
    });

    test('handleError respects file path from context', () {
      contextStack.clear();
      contextStack.push(Context('file', data: {'path': 'test/fixture.dsl'}));
      contextStack.push(Context('workspace'));

      parser.setContextStack(contextStack);

      var filePathCaptured = false;
      String? capturedPath;

      parser.setErrorReporterCallback((err) {
        filePathCaptured = true;
        capturedPath = err.filePath;
      });

      parser.handleError(ParseError('Error in file'));

      expect(filePathCaptured, isTrue);
      expect(capturedPath, equals('test/fixture.dsl'));
    });

    test('handleError adds source snippet for context', () {
      final token = Token(
          type: TokenType.leftBrace,
          lexeme: '{',
          position: const SourcePosition(1, 17, 16));

      final error = ParseError('Expected name', token: token);

      var snippetCaptured = false;
      String? capturedSnippet;

      parser.setErrorReporterCallback((err) {
        snippetCaptured = true;
        capturedSnippet = err.sourceSnippet;
      });

      parser.handleError(error);

      expect(snippetCaptured, isTrue);
      expect(capturedSnippet, isNotNull);
      expect(capturedSnippet, contains('workspace "Test"'));
    });

    test('handleError enriches error with expected/found information', () {
      final found = Token(
          type: TokenType.identifier,
          lexeme: 'workspace',
          position: const SourcePosition(1, 1, 0));

      final expected = Token(
          type: TokenType.string,
          lexeme: 'string',
          position: const SourcePosition(1, 1, 0));

      final error = ParseError.expected(
          'Expected string literal as workspace name',
          found: found,
          expected: expected);

      var enrichedMessageCaptured = false;
      String? capturedMessage;

      parser.setErrorReporterCallback((err) {
        enrichedMessageCaptured = true;
        capturedMessage = err.message;
      });

      parser.handleError(error);

      expect(enrichedMessageCaptured, isTrue);
      expect(capturedMessage,
          contains('Expected string literal as workspace name'));
      expect(capturedMessage, contains('Expected'));
      expect(capturedMessage, contains('but found'));
    });

    test('handleError synchronizes to recover from error', () {
      var syncCalled = false;

      parser.setSynchronizeHook(() {
        syncCalled = true;
        // Simulate recovery actions
        contextStack.clear();
        contextStack.push(Context('workspace'));
      });

      parser.handleError(ParseError('Error requiring synchronization'));

      expect(syncCalled, isTrue);
      expect(contextStack.size(), equals(1));
      expect(contextStack.current().name, equals('workspace'));
    });
  });

  group('Parser Error Integration', () {
    test('parser handles syntax errors during parsing', () {
      const source = '''
        workspace "Banking System" {
          model {
            user = person "User"
            // Missing closing quote
            system = softwareSystem "Banking System
          }
        }
      ''';

      final parser = Parser(source);

      // Parse should return some result but report errors
      final workspace = parser.parse();

      expect(workspace, isNotNull);
      expect(parser.hasErrors(), isTrue);
      expect(parser.errorCount(), greaterThan(0));

      // Check error contains info about the missing quote
      final errors = parser.getErrors();
      expect(
          errors.any((e) =>
              e.message.contains('quote') || e.message.contains('string')),
          isTrue);
    });

    test('parser handles semantic errors with proper context', () {
      const source = '''
        workspace "Banking System" {
          model {
            user = person "User" "A user of the system"
            system = softwareSystem "Banking System" "Core banking system"
            
            // Relationship references non-existent element
            user -> nonexistent "Uses"
          }
        }
      ''';

      final parser = Parser(source);

      final workspace = parser.parse();

      expect(workspace, isNotNull);
      expect(parser.hasErrors(), isTrue);

      // Check error contains info about the non-existent element
      final errors = parser.getErrors();
      expect(
          errors.any((e) =>
              e.message.contains('nonexistent') ||
              e.message.contains('element') ||
              e.message.contains('not found')),
          isTrue);
    });

    test('parser handles circular references gracefully', () {
      const source = '''
        workspace "Test" {
          model {
            // Circular reference in element definition
            a = softwareSystem "A" "A system" {
              b = container "B" "B container"
            }
            
            // This references container b directly which should be referenced as a.b
            b -> a "Uses"
          }
        }
      ''';

      final parser = Parser(source);

      final workspace = parser.parse();

      expect(workspace, isNotNull);
      expect(parser.hasErrors(), isTrue);

      // Should report error about invalid reference
      final errors = parser.getErrors();
      expect(errors.any((e) => e.message.contains('reference')), isTrue);
    });

    test('parser reports multiple errors with proper context', () {
      const source = '''
        workspace "Test" {
          model {
            // Missing description
            user = person "User"
            
            // Invalid property
            system = softwareSystem "System" "Description" {
              invalid-property = "value"
            }
            
            // Invalid relationship syntax
            user system "Uses"
          }
        }
      ''';

      final parser = Parser(source);

      final workspace = parser.parse();

      expect(workspace, isNotNull);
      expect(parser.errorCount(), greaterThanOrEqualTo(3));

      final errors = parser.getErrors();

      // Check errors for different contexts
      expect(
          errors.any((e) =>
              e.message.contains('person') ||
              e.getContextPath()?.contains('person') == true),
          isTrue);
      expect(
          errors.any((e) =>
              e.message.contains('property') ||
              e.message.contains('invalid-property')),
          isTrue);
      expect(
          errors.any((e) =>
              e.message.contains('relationship') ||
              e.message.contains('syntax')),
          isTrue);
    });
  });
}
