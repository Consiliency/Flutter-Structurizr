import 'dart:math';

/// Represents the severity level of a parser error.
enum ErrorSeverity {
  /// Fatal errors that prevent further processing
  fatal,
  
  /// Standard errors that indicate incorrect syntax or semantics
  error,
  
  /// Warnings that indicate potential issues but don't prevent processing
  warning,
  
  /// Informational messages that don't indicate errors
  info,
}

/// Represents a position in the source code.
class SourcePosition {
  /// The line number (1-based)
  final int line;
  
  /// The column number (1-based)
  final int column;
  
  /// The character offset from the start of the source (0-based)
  final int offset;

  /// Creates a new source position with line, column, and offset.
  const SourcePosition({
    required this.line,
    required this.column,
    required this.offset,
  });

  /// Creates a source position from a character offset by counting lines and columns.
  factory SourcePosition.fromOffset(String source, int offset) {
    if (offset < 0 || offset > source.length) {
      throw ArgumentError('Offset $offset is out of bounds for source of length ${source.length}');
    }

    int line = 1;
    int lastLineStart = 0;

    for (int i = 0; i < offset; i++) {
      if (source[i] == '\n') {
        line++;
        lastLineStart = i + 1;
      }
    }

    int column = offset - lastLineStart + 1;

    return SourcePosition(
      line: line,
      column: column,
      offset: offset,
    );
  }

  /// Returns a string representation of this position.
  @override
  String toString() => 'line $line, column $column';
}

/// Represents an error that occurred during parsing.
class ParserError {
  /// The severity level of the error
  final ErrorSeverity severity;
  
  /// The error message
  final String message;
  
  /// The position in source where the error occurred
  final SourcePosition position;
  
  /// The original source code
  final String source;
  
  /// Creates a new parser error.
  ParserError({
    required this.severity,
    required this.message,
    required this.position,
    required this.source,
  });
}

/// Represents a simple parse error that can be passed around.
/// This class is a simplified version of ParserError that can be used
/// for error handling and reporting in the parser.
class ParseError {
  /// The error message
  final String message;
  
  /// The position in source where the error occurred (may be null)
  final SourcePosition? position;
  
  /// Creates a new parse error with a message and optional position.
  ParseError(this.message, [this.position]);
  
  @override
  String toString() => position != null 
    ? '$message at $position'
    : message;
}

/// A class for collecting and reporting parsing errors.
class ErrorReporter {
  /// The original source code
  final String source;
  
  /// List of collected errors
  final List<ParserError> _errors = [];

  /// Creates a new error reporter for the given source.
  ErrorReporter(this.source);

  /// Returns true if any errors (excluding warnings and info) have been reported.
  bool get hasErrors => _errors.any((e) => 
      e.severity == ErrorSeverity.error || 
      e.severity == ErrorSeverity.fatal);

  /// Returns true if any fatal errors have been reported.
  bool get hasFatalErrors => _errors.any((e) => e.severity == ErrorSeverity.fatal);

  /// Returns the number of errors collected.
  int get errorCount => _errors.length;

  /// Adds a new error with the given parameters.
  void reportError({
    required ErrorSeverity severity,
    required String message,
    required int offset,
  }) {
    final position = SourcePosition.fromOffset(source, offset);
    final error = ParserError(
      severity: severity,
      message: message,
      position: position,
      source: source,
    );
    _errors.add(error);
  }

  /// Reports a fatal error.
  void reportFatalError(String message, int offset) {
    reportError(
      severity: ErrorSeverity.fatal,
      message: message,
      offset: offset,
    );
  }

  /// Reports a standard error.
  void reportStandardError(String message, int offset) {
    reportError(
      severity: ErrorSeverity.error,
      message: message,
      offset: offset,
    );
  }

  /// Reports a warning.
  void reportWarning(String message, int offset) {
    reportError(
      severity: ErrorSeverity.warning,
      message: message,
      offset: offset,
    );
  }

  /// Reports an informational message.
  void reportInfo(String message, int offset) {
    reportError(
      severity: ErrorSeverity.info,
      message: message,
      offset: offset,
    );
  }

  /// Returns all collected errors.
  List<ParserError> get errors => List.unmodifiable(_errors);

  /// Returns a formatted report of all errors.
  String formatErrors() {
    if (_errors.isEmpty) {
      return 'No errors reported.';
    }

    // Sort errors by position
    final sortedErrors = List<ParserError>.from(_errors)
      ..sort((a, b) => a.position.offset.compareTo(b.position.offset));

    final sb = StringBuffer();
    sb.writeln('${_errors.length} error(s) found:');
    sb.writeln();

    for (var error in sortedErrors) {
      sb.writeln(error.format());
    }

    return sb.toString();
  }

  /// Extracts a snippet of source code around the given position.
  String getSourceSnippet(SourcePosition position, {int contextLines = 2}) {
    final lines = source.split('\n');
    final lineIndex = position.line - 1;
    
    if (lineIndex < 0 || lineIndex >= lines.length) {
      return '';
    }
    
    final startLine = max(0, lineIndex - contextLines);
    final endLine = min(lines.length - 1, lineIndex + contextLines);
    
    final sb = StringBuffer();
    for (var i = startLine; i <= endLine; i++) {
      final lineNum = (i + 1).toString().padLeft(4);
      final marker = i == lineIndex ? '>' : ' ';
      sb.writeln('$marker $lineNum | ${lines[i]}');
      
      if (i == lineIndex) {
        // Add pointer to the error position
        sb.write('  ');
        sb.write(' ' * 4);
        sb.write('| ');
        sb.write(' ' * (position.column - 1));
        sb.writeln('^');
      }
    }
    
    return sb.toString();
  }
}