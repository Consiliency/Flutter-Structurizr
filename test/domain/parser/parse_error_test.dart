import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/parser/parse_error.dart';
import 'package:flutter_structurizr/domain/parser/parser.dart';
import 'package:flutter_structurizr/domain/parser/lexer/token.dart';

void main() {
  group('Parse Error Handling', () {
    late Parser parser;
    
    setUp(() {
      // Create a simple parser instance for testing
      parser = Parser('workspace "Test" { }');
    });
    
    test('handleError adds error to error reporter', () {
      final error = ParseError('Test error message');
      
      // Mock the error reporter to track if handleError is called
      var errorReported = false;
      parser.setErrorReporter((err) {
        errorReported = true;
        expect(err.message, equals('Test error message'));
      });
      
      parser.handleError(error);
      
      expect(errorReported, isTrue);
    });
    
    test('handleError with token location includes position information', () {
      final token = Token(
        type: TokenType.identifier, 
        lexeme: 'test',
        position: SourcePosition(10, 5, 42)
      );
      
      final error = ParseError('Test error with location', token: token);
      
      var locationCaptured = false;
      parser.setErrorReporter((err) {
        locationCaptured = true;
        expect(err.message, equals('Test error with location'));
        expect(err.token.position.line, equals(10));
        expect(err.token.position.column, equals(5));
        expect(err.token.position.offset, equals(42));
      });
      
      parser.handleError(error);
      
      expect(locationCaptured, isTrue);
    });
    
    test('handleError increments error count', () {
      final initialCount = parser.errorCount();
      
      parser.handleError(ParseError('Error 1'));
      expect(parser.errorCount(), equals(initialCount + 1));
      
      parser.handleError(ParseError('Error 2'));
      expect(parser.errorCount(), equals(initialCount + 2));
    });
    
    test('handleError puts parser in panic mode', () {
      expect(parser.isInPanicMode(), isFalse);
      
      parser.handleError(ParseError('Error'));
      
      expect(parser.isInPanicMode(), isTrue);
    });
    
    test('handleError limits number of reported errors', () {
      // Set a maximum error count limit for testing
      parser.setMaxErrorCount(3);
      
      // Report errors up to the limit
      for (var i = 0; i < 3; i++) {
        expect(parser.handleError(ParseError('Error ${i+1}')), isTrue);
      }
      
      // The next error should not be reported
      expect(parser.handleError(ParseError('Error 4')), isFalse);
    });
    
    test('handleError with source code snippet shows context', () {
      final token = Token(
        type: TokenType.identifier,
        lexeme: 'invalid',
        position: SourcePosition(1, 10, 10)
      );
      
      final error = ParseError('Invalid syntax', token: token);
      
      var contextCaptured = false;
      parser.setErrorReporter((err) {
        contextCaptured = true;
        expect(err.sourceSnippet, isNotNull);
        expect(err.sourceSnippet, contains('workspace'));
      });
      
      parser.handleError(error);
      
      expect(contextCaptured, isTrue);
    });
    
    test('handleError with file info includes source file', () {
      parser = Parser('workspace "Test" { }', filePath: '/path/to/test.dsl');
      
      final error = ParseError('Error in file');
      
      var fileInfoCaptured = false;
      parser.setErrorReporter((err) {
        fileInfoCaptured = true;
        expect(err.filePath, equals('/path/to/test.dsl'));
      });
      
      parser.handleError(error);
      
      expect(fileInfoCaptured, isTrue);
    });
    
    test('handleError triggers synchronization to recover from error', () {
      var syncCalled = false;
      parser.setSynchronizeHook(() {
        syncCalled = true;
      });
      
      parser.handleError(ParseError('Error requiring sync'));
      
      expect(syncCalled, isTrue);
    });
    
    test('handleError provides detailed information for syntax errors', () {
      final token = Token(
        type: TokenType.leftBrace, 
        lexeme: '{',
        position: SourcePosition(1, 15, 15)
      );
      
      final expectedToken = Token(
        type: TokenType.string,
        lexeme: '""',
        position: SourcePosition(1, 15, 15)
      );
      
      final error = ParseError.expected(
        'Expected workspace name as string',
        found: token,
        expected: expectedToken
      );
      
      var errorDetailsCaptured = false;
      parser.setErrorReporter((err) {
        errorDetailsCaptured = true;
        expect(err.message, contains('Expected workspace name as string'));
        expect(err.message, contains('Expected'));
        expect(err.message, contains('but found'));
      });
      
      parser.handleError(error);
      
      expect(errorDetailsCaptured, isTrue);
    });
    
    test('handleError clears panic mode after synchronizing', () {
      parser.handleError(ParseError('Error causing panic'));
      
      // After handleError completes, panic mode should be cleared
      expect(parser.isInPanicMode(), isFalse);
    });
    
    test('handleError ignores cascading errors in panic mode', () {
      // Put parser in panic mode
      parser.enterPanicMode();
      
      var errorReported = false;
      parser.setErrorReporter((err) {
        errorReported = true;
      });
      
      // This should be ignored because we're already in panic mode
      parser.handleError(ParseError('Cascading error'));
      
      expect(errorReported, isFalse);
    });
  });
  
  group('ParseError', () {
    test('ParseError creation with message only', () {
      final error = ParseError('Test message');
      
      expect(error.message, equals('Test message'));
      expect(error.token, isNull);
    });
    
    test('ParseError creation with message and token', () {
      final token = Token(
        type: TokenType.identifier,
        lexeme: 'test',
        position: SourcePosition(1, 1, 0)
      );
      
      final error = ParseError('Test with token', token: token);
      
      expect(error.message, equals('Test with token'));
      expect(error.token, equals(token));
    });
    
    test('ParseError.expected factory creates error with expected/found info', () {
      final found = Token(
        type: TokenType.identifier,
        lexeme: 'identifier',
        position: SourcePosition(1, 1, 0)
      );
      
      final expected = Token(
        type: TokenType.string,
        lexeme: 'string',
        position: SourcePosition(1, 1, 0)
      );
      
      final error = ParseError.expected(
        'Expected string',
        found: found,
        expected: expected
      );
      
      expect(error.message, contains('Expected string'));
      expect(error.message, contains('identifier'));
      expect(error.message, contains('string'));
      expect(error.token, equals(found));
    });
    
    test('ParseError.fileNotFound factory creates appropriate error', () {
      final error = ParseError.fileNotFound('missing.dsl');
      
      expect(error.message, contains('File not found'));
      expect(error.message, contains('missing.dsl'));
      expect(error.isFileError, isTrue);
    });
    
    test('ParseError.toString provides formatted error message', () {
      final token = Token(
        type: TokenType.identifier,
        lexeme: 'test',
        position: SourcePosition(5, 10, 42)
      );
      
      final error = ParseError('Test error', token: token);
      final errorString = error.toString();
      
      expect(errorString, contains('Test error'));
      expect(errorString, contains('line 5'));
      expect(errorString, contains('column 10'));
    });
  });
}