import 'package:test/test.dart';
import '../error_reporter.dart';

void main() {
  group('SourcePosition tests', () {
    test('Constructor initializes values correctly', () {
      const position = SourcePosition(line: 10, column: 20, offset: 100);

      expect(position.line, equals(10));
      expect(position.column, equals(20));
      expect(position.offset, equals(100));
    });

    test('fromOffset calculates correct line and column', () {
      const source = 'line1\nline2\nline3';

      // Test position at start of first line
      final pos1 = SourcePosition.fromOffset(source, 0);
      expect(pos1.line, equals(1));
      expect(pos1.column, equals(1));
      expect(pos1.offset, equals(0));

      // Test position in middle of first line
      final pos2 = SourcePosition.fromOffset(source, 3);
      expect(pos2.line, equals(1));
      expect(pos2.column, equals(4));
      expect(pos2.offset, equals(3));

      // Test position at start of second line
      final pos3 = SourcePosition.fromOffset(source, 6);
      expect(pos3.line, equals(2));
      expect(pos3.column, equals(1));
      expect(pos3.offset, equals(6));

      // Test position at end of source
      final pos4 = SourcePosition.fromOffset(source, source.length);
      expect(pos4.line, equals(3));
      expect(pos4.column, equals(6));
      expect(pos4.offset, equals(source.length));
    });

    test('fromOffset throws ArgumentError for invalid offset', () {
      const source = 'test';

      // Negative offset
      expect(() => SourcePosition.fromOffset(source, -1),
          throwsA(isA<ArgumentError>()));

      // Offset beyond source length
      expect(() => SourcePosition.fromOffset(source, source.length + 1),
          throwsA(isA<ArgumentError>()));
    });

    test('toString returns formatted position', () {
      const position = SourcePosition(line: 10, column: 20, offset: 100);
      expect(position.toString(), equals('line 10, column 20'));
    });
  });

  group('ParserError tests', () {
    const source = 'line1\nline2\nline3';

    test('Constructor initializes values correctly', () {
      final position = SourcePosition(line: 2, column: 3, offset: 8);
      final error = ParserError(
        severity: ErrorSeverity.error,
        message: 'Test error message',
        position: position,
        source: source,
      );

      expect(error.severity, equals(ErrorSeverity.error));
      expect(error.message, equals('Test error message'));
      expect(error.position, equals(position));
      expect(error.source, equals(source));
    });

    test('errorLine returns correct line of source', () {
      final position = SourcePosition(line: 2, column: 3, offset: 8);
      final error = ParserError(
        severity: ErrorSeverity.error,
        message: 'Test error message',
        position: position,
        source: source,
      );

      expect(error.errorLine, equals('line2'));
    });

    test('format returns formatted error message with context', () {
      final position = SourcePosition(line: 2, column: 3, offset: 8);
      final error = ParserError(
        severity: ErrorSeverity.error,
        message: 'Test error message',
        position: position,
        source: source,
      );

      final formatted = error.format();
      expect(formatted, contains('ERROR: Test error message'));
      expect(formatted, contains('line 2, column 3'));
      expect(formatted, contains('2 | line2'));
      expect(formatted, contains('  ^'));
    });

    test('format handles different error severities', () {
      final position = SourcePosition(line: 2, column: 3, offset: 8);

      final error1 = ParserError(
        severity: ErrorSeverity.fatal,
        message: 'Fatal error',
        position: position,
        source: source,
      );
      expect(error1.format(), contains('FATAL: Fatal error'));

      final error2 = ParserError(
        severity: ErrorSeverity.warning,
        message: 'Warning',
        position: position,
        source: source,
      );
      expect(error2.format(), contains('WARNING: Warning'));

      final error3 = ParserError(
        severity: ErrorSeverity.info,
        message: 'Info',
        position: position,
        source: source,
      );
      expect(error3.format(), contains('INFO: Info'));
    });
  });

  group('ErrorReporter tests', () {
    const source = 'line1\nline2\nline3';

    test('Constructor initializes with source', () {
      final reporter = ErrorReporter(source);
      expect(reporter.source, equals(source));
      expect(reporter.hasErrors, isFalse);
      expect(reporter.errorCount, equals(0));
    });

    test('reportError adds error with correct position', () {
      final reporter = ErrorReporter(source);

      reporter.reportError(
        severity: ErrorSeverity.error,
        message: 'Test error',
        offset: 8, // Line 2, column 3
      );

      expect(reporter.errorCount, equals(1));
      expect(reporter.hasErrors, isTrue);
      expect(reporter.hasFatalErrors, isFalse);

      final error = reporter.errors.first;
      expect(error.message, equals('Test error'));
      expect(error.severity, equals(ErrorSeverity.error));
      expect(error.position.line, equals(2));
      expect(error.position.column, equals(3));
    });

    test('Convenience methods report correct severity', () {
      final reporter = ErrorReporter(source);

      reporter.reportFatalError('Fatal error', 0);
      reporter.reportStandardError('Standard error', 6);
      reporter.reportWarning('Warning', 12);
      reporter.reportInfo('Info', 17);

      expect(reporter.errorCount, equals(4));
      expect(reporter.hasErrors, isTrue);
      expect(reporter.hasFatalErrors, isTrue);

      expect(reporter.errors[0].severity, equals(ErrorSeverity.fatal));
      expect(reporter.errors[1].severity, equals(ErrorSeverity.error));
      expect(reporter.errors[2].severity, equals(ErrorSeverity.warning));
      expect(reporter.errors[3].severity, equals(ErrorSeverity.info));
    });

    test('hasErrors only counts error and fatal severities', () {
      final reporter = ErrorReporter(source);

      // Add only warning and info
      reporter.reportWarning('Warning', 0);
      reporter.reportInfo('Info', 6);

      expect(reporter.errorCount, equals(2));
      expect(reporter.hasErrors, isFalse);

      // Add an error
      reporter.reportStandardError('Error', 12);

      expect(reporter.errorCount, equals(3));
      expect(reporter.hasErrors, isTrue);
    });

    test('formatErrors returns formatted report of all errors', () {
      final reporter = ErrorReporter(source);

      reporter.reportFatalError('Fatal error', 0);
      reporter.reportStandardError('Standard error', 6);

      final report = reporter.formatErrors();

      expect(report, contains('2 error(s) found:'));
      expect(report, contains('FATAL: Fatal error'));
      expect(report, contains('ERROR: Standard error'));
    });

    test('formatErrors handles no errors', () {
      final reporter = ErrorReporter(source);

      expect(reporter.formatErrors(), equals('No errors reported.'));
    });

    test('getSourceSnippet extracts context around position', () {
      final reporter = ErrorReporter('''line1
line2
line3
line4
line5''');

      final position = SourcePosition(line: 3, column: 3, offset: 14);
      final snippet = reporter.getSourceSnippet(position, contextLines: 1);

      expect(snippet, contains('  2 | line2'));
      expect(snippet, contains('> 3 | line3'));
      expect(snippet, contains('    |   ^'));
      expect(snippet, contains('  4 | line4'));
    });
  });
}
