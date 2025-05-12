import '../error_reporter.dart';
import 'token.dart';

/// A lexer for Structurizr DSL that converts source text into tokens.
class Lexer {
  /// The source code being lexed
  final String source;

  /// The error reporter for reporting lexical errors
  final ErrorReporter errorReporter;

  /// The current position in the source code
  int _current = 0;

  /// The start position of the current token
  int _start = 0;

  /// The current line number (1-based)
  int _line = 1;

  /// The current column number (1-based)
  int _column = 1;

  /// The list of tokens that have been scanned
  final List<Token> _tokens = [];

  /// Creates a new lexer for the given source code.
  Lexer(this.source) : errorReporter = ErrorReporter(source);

  /// Scans all tokens in the source and returns them.
  List<Token> scanTokens() {
    while (!_isAtEnd()) {
      _start = _current;
      _scanToken();
    }

    // Add EOF token
    _tokens.add(Token(
      type: TokenType.eof,
      lexeme: '',
      position: SourcePosition(
        line: _line,
        column: _column,
        offset: _current,
      ),
    ));

    return _tokens;
  }

  /// Scans a single token and adds it to the token list.
  void _scanToken() {
    final c = _advance();

    switch (c) {
      // Single-character tokens
      case '{': _addToken(TokenType.leftBrace); break;
      case '}': _addToken(TokenType.rightBrace); break;
      case '(': _addToken(TokenType.leftParen); break;
      case ')': _addToken(TokenType.rightParen); break;
      case ',': _addToken(TokenType.comma); break;
      case '.': _addToken(TokenType.dot); break;
      case ';': _addToken(TokenType.semicolon); break;
      case ':': _addToken(TokenType.colon); break;
      case '+': _addToken(TokenType.plus); break;
      case '*': _addToken(TokenType.star); break;
      case '|': _addToken(TokenType.pipe); break;
      case '!':
        // Check for directives like !identifiers
        if (_isAlpha(_peek())) {
          _directive();
        } else {
          _addToken(TokenType.bang);
        }
        break;
      case '/':
        if (_match('/')) {
          // Line comment
          while (_peek() != '\n' && !_isAtEnd()) {
            _advance();
          }
        } else if (_match('*')) {
          // Block comment
          _blockComment();
        } else {
          _addToken(TokenType.slash);
        }
        break;
      case '#': _addToken(TokenType.hash); break;
      case '@': _addToken(TokenType.at); break;

      // Arrow token (->)
      case '-':
        if (_match('>')) {
          _addToken(TokenType.arrow);
        } else {
          _addToken(TokenType.minus);
        }
        break;

      // Equals token
      case '=': _addToken(TokenType.equals); break;

      // Whitespace - ignore
      case ' ':
      case '\r':
      case '\t':
        // Ignore whitespace
        break;

      // Newline - update line counter
      case '\n':
        _line++;
        _column = 1; // Reset column on new line
        break;

      // String literals
      case '"': _string(); break;
      case "'": _string("'"); break;

      // Numbers, identifiers, and keywords
      default:
        if (_isDigit(c)) {
          _number();
        } else if (_isAlpha(c)) {
          _identifier();
        } else {
          errorReporter.reportStandardError(
            'Unexpected character: $c',
            _start,
          );
        }
        break;
    }
  }

  /// Processes a directive (e.g., !identifiers).
  void _directive() {
    while (_isAlphaNumeric(_peek())) {
      _advance();
    }

    // Get the directive name without the ! prefix
    final text = source.substring(_start + 1, _current);

    // Map to the corresponding directive token type
    if (text == 'identifiers') {
      _addToken(TokenType.identifiers);
    } else {
      // Unknown directive - treat as identifier with ! prefix
      _addToken(TokenType.identifier);
    }
  }

  /// Processes a block comment.
  void _blockComment() {
    var nesting = 1;

    while (nesting > 0) {
      if (_isAtEnd()) {
        errorReporter.reportStandardError(
          'Unterminated block comment',
          _start,
        );
        return;
      }

      if (_peek() == '\n') {
        _line++;
        _column = 1;
      } else if (_peek() == '/' && _peekNext() == '*') {
        // Nested comment starts
        _advance();
        _advance();
        nesting++;
        continue;
      } else if (_peek() == '*' && _peekNext() == '/') {
        // Comment ends
        _advance();
        _advance();
        nesting--;
        continue;
      }

      _advance();
    }
  }

  /// Processes a string literal.
  void _string([String delimiter = '"']) {
    final startLine = _line;
    final startColumn = _column - 1; // Account for the quote character

    // Start with empty string
    final sb = StringBuffer();

    while (_peek() != delimiter && !_isAtEnd()) {
      final char = _peek();

      if (char == '\n') {
        _line++;
        _column = 1;
      }

      // Handle escape sequences
      if (char == '\\') {
        _advance(); // Consume backslash

        switch (_peek()) {
          case 'n': sb.write('\n'); break;
          case 'r': sb.write('\r'); break;
          case 't': sb.write('\t'); break;
          case 'b': sb.write('\b'); break;
          case 'f': sb.write('\f'); break;
          case '\'': sb.write('\''); break;
          case '"': sb.write('"'); break;
          case '\\': sb.write('\\'); break;
          case 'u':
            // Unicode escape sequence (e.g., \u0061 for 'a')
            if (_isAtEnd() || _isAtEnd(1) || _isAtEnd(2) || _isAtEnd(3)) {
              errorReporter.reportStandardError(
                'Incomplete Unicode escape sequence',
                _current,
              );
              break;
            }

            final unicodeHex = _peek() + _peekNext() +
                               _peekNext(2) + _peekNext(3);

            if (_isHex(unicodeHex)) {
              sb.write(String.fromCharCode(int.parse(unicodeHex, radix: 16)));
              _advance(); // Consume all 4 hex digits
              _advance();
              _advance();
              _advance();
            } else {
              errorReporter.reportStandardError(
                'Invalid Unicode escape sequence: \\u$unicodeHex',
                _current,
              );
            }
            break;
          default:
            errorReporter.reportStandardError(
              'Invalid escape sequence: \\${_peek()}',
              _current,
            );
            break;
        }
      } else {
        sb.write(char);
      }

      _advance();
    }

    if (_isAtEnd()) {
      errorReporter.reportStandardError(
        'Unterminated string literal',
        _start,
      );
      return;
    }

    // Consume the closing quote
    _advance();

    // Add the string token with the parsed value
    final value = sb.toString();
    _addToken(
      TokenType.string,
      value,
      SourcePosition(
        line: startLine,
        column: startColumn,
        offset: _start,
      ),
    );
  }

  /// Processes a number literal.
  void _number() {
    while (_isDigit(_peek())) {
      _advance();
    }

    // Look for a decimal point
    if (_peek() == '.' && _isDigit(_peekNext())) {
      // Consume the decimal point
      _advance();

      // Consume decimal digits
      while (_isDigit(_peek())) {
        _advance();
      }

      // Create a double token
      final value = double.parse(source.substring(_start, _current));
      _addToken(TokenType.double, value);
    } else {
      // Create an integer token
      final value = int.parse(source.substring(_start, _current));
      _addToken(TokenType.integer, value);
    }
  }

  /// Processes an identifier or keyword.
  void _identifier() {
    while (_isAlphaNumeric(_peek())) {
      _advance();
    }

    // Get the identifier text
    final text = source.substring(_start, _current);

    // Check if it's a keyword
    final type = keywords[text] ?? TokenType.identifier;

    // Special handling for 'this' keyword to avoid Dart reserved word conflict
    if (type == TokenType.this_) {
      _addToken(TokenType.this_);
    }
    // For boolean literals, parse the value
    else if (type == TokenType.boolean) {
      _addToken(type, text == 'true');
    } else {
      _addToken(type);
    }
  }

  /// Adds a token of the given type to the token list.
  void _addToken(TokenType type, [Object? value, SourcePosition? position]) {
    final lexeme = source.substring(_start, _current);
    final pos = position ?? SourcePosition(
      line: _line,
      column: _column - (lexeme.length),
      offset: _start,
    );

    _tokens.add(Token(
      type: type,
      lexeme: lexeme,
      position: pos,
      value: value,
    ));
  }

  /// Checks if the next character matches the expected character, and if so, consumes it.
  bool _match(String expected) {
    if (_isAtEnd()) return false;
    if (source[_current] != expected) return false;

    _current++;
    _column++;
    return true;
  }

  /// Returns the current character without consuming it.
  String _peek([int offset = 0]) {
    if (_isAtEnd(offset)) return '\0';
    return source[_current + offset];
  }

  /// Returns the character after the current character without consuming it.
  String _peekNext([int offset = 1]) {
    return _peek(offset);
  }

  /// Checks if the given character is a digit.
  bool _isDigit(String c) {
    return c.codeUnitAt(0) >= '0'.codeUnitAt(0) &&
           c.codeUnitAt(0) <= '9'.codeUnitAt(0);
  }

  /// Checks if the given character is an alphabetic character or underscore.
  bool _isAlpha(String c) {
    final code = c.codeUnitAt(0);
    return (code >= 'a'.codeUnitAt(0) && code <= 'z'.codeUnitAt(0)) ||
           (code >= 'A'.codeUnitAt(0) && code <= 'Z'.codeUnitAt(0)) ||
           c == '_';
  }

  /// Checks if the given character is alphanumeric or underscore.
  bool _isAlphaNumeric(String c) {
    return _isAlpha(c) || _isDigit(c);
  }

  /// Checks if the given string consists of hexadecimal digits.
  bool _isHex(String s) {
    for (int i = 0; i < s.length; i++) {
      final c = s[i].toLowerCase();
      if (!_isDigit(c) &&
          !(c.codeUnitAt(0) >= 'a'.codeUnitAt(0) &&
            c.codeUnitAt(0) <= 'f'.codeUnitAt(0))) {
        return false;
      }
    }
    return true;
  }

  /// Consumes the current character and returns it.
  String _advance() {
    _column++;
    return source[_current++];
  }

  /// Checks if we've reached the end of the source.
  bool _isAtEnd([int offset = 0]) {
    return _current + offset >= source.length;
  }
}