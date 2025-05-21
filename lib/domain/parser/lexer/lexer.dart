import '../error_reporter.dart';
import 'token.dart';
import 'package:logging/logging.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/source_position.dart';

final _logger = Logger('Lexer');

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
      position: SourcePosition(_line, _column, _current),
    ));

    return _tokens;
  }

  /// Scans a single token and adds it to the token list.
  void _scanToken() {
    final c = _advance();

    switch (c) {
      // Single-character tokens
      case '{':
        _addToken(TokenType.leftBrace);
        break;
      case '}':
        _addToken(TokenType.rightBrace);
        break;
      case '(':
        _addToken(TokenType.leftParen);
        break;
      case ')':
        _addToken(TokenType.rightParen);
        break;
      case ',':
        _addToken(TokenType.comma);
        break;
      case '.':
        _addToken(TokenType.dot);
        break;
      case ';':
        _addToken(TokenType.semicolon);
        break;
      case ':':
        _addToken(TokenType.colon);
        break;
      case '+':
        _addToken(TokenType.plus);
        break;
      case '*':
        _addToken(TokenType.star);
        break;
      case '|':
        _addToken(TokenType.pipe);
        break;
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
      case '#':
        _addToken(TokenType.hash);
        break;
      case '@':
        _addToken(TokenType.at);
        break;
      case '\$':
        // Handle $ as a valid character in identifiers, which is commonly used in various DSLs
        if (_isAlphaNumeric(_peek())) {
          // Treat $ followed by alphanumeric chars as part of an identifier
          _current--; // Back up to include $ in the identifier
          _column--;
          _identifier();
        } else {
          // Otherwise, treat as a regular character (which might be an error later)
          _addToken(TokenType.identifier, '\$');
        }
        break;

      // Arrow token (->)
      case '-':
        if (_match('>')) {
          _addToken(TokenType.arrow);
        } else {
          _addToken(TokenType.minus);
        }
        break;

      // Equals token
      case '=':
        _addToken(TokenType.equals);
        break;

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
      case '"':
        _string();
        break;
      case "'":
        _string("'");
        break;

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

  /// Processes a string literal with enhanced error handling and support for
  /// multi-line strings, block quotes, and all escape sequences defined in the Structurizr DSL.
  void _string([String delimiter = '"']) {
    final startLine = _line;
    final startColumn = _column - 1; // Account for the quote character
    final startOffset =
        _current - 1; // The actual position of the opening quote

    // Check for triple-quoted multiline strings ("""...""" or '''...''')
    final isMultiLine = _checkMultilineString(delimiter);

    // Start with empty string
    final sb = StringBuffer();

    bool isEscaping =
        false; // Track whether we're currently processing an escape sequence
    bool isEscapingUnicode =
        false; // Track whether we're processing a Unicode escape
    String unicodeSequence = ''; // Collect Unicode escape sequence

    while (!_isAtEnd()) {
      // Check for ending delimiter
      if (isMultiLine) {
        // For multiline strings, check for triple delimiter
        if (_peek() == delimiter &&
            _peekNext() == delimiter &&
            _peekNext(2) == delimiter) {
          _advance(); // Consume first delimiter
          _advance(); // Consume second delimiter
          _advance(); // Consume third delimiter
          break;
        }
      } else if (!isEscaping && _peek() == delimiter) {
        // For regular strings, check for single delimiter (when not escaping)
        _advance(); // Consume the closing quote
        break;
      }

      // Process character
      final char = _peek();

      // Handle line breaks
      if (char == '\n') {
        if (!isMultiLine) {
          // Regular strings don't allow unescaped newlines
          errorReporter.reportStandardError(
            'Unescaped newline in string literal - use \\n or a triple-quoted multiline string',
            _current,
          );
          // Add partial string as a recovery measure and return
          _addToken(
            TokenType.string,
            sb.toString(),
            SourcePosition(_line, _column, _current),
          );
          return;
        }

        // Update line tracking and add the newline to the string
        _line++;
        _column = 1;
        sb.write(char);
        _advance();
        continue;
      }

      // Handle escape sequences
      if (isEscaping) {
        isEscaping = false; // Reset escaping flag

        if (isEscapingUnicode) {
          // Collecting Unicode escape sequence characters
          unicodeSequence += char;

          if (unicodeSequence.length < 4) {
            // Still need more hex digits
            _advance();
            continue;
          } else {
            // Process the complete unicode sequence
            isEscapingUnicode = false;

            if (_isHex(unicodeSequence)) {
              try {
                final codePoint = int.parse(unicodeSequence, radix: 16);
                sb.write(String.fromCharCode(codePoint));
              } catch (e) {
                errorReporter.reportStandardError(
                  'Invalid Unicode escape sequence: \\u$unicodeSequence',
                  _current - 4,
                );
                // Add the literal sequence as fallback
                sb.write('u$unicodeSequence');
              }
            } else {
              errorReporter.reportStandardError(
                'Invalid Unicode escape sequence: \\u$unicodeSequence - should be 4 hex digits',
                _current - 4,
              );
              // Add the literal sequence as fallback
              sb.write('u$unicodeSequence');
            }

            unicodeSequence = '';
            _advance();
            continue;
          }
        }

        // Process standard escape sequences
        switch (char) {
          case 'n':
            sb.write('\n');
            break;
          case 'r':
            sb.write('\r');
            break;
          case 't':
            sb.write('\t');
            break;
          case 'b':
            sb.write('\b');
            break;
          case 'f':
            sb.write('\f');
            break;
          case '\'':
            sb.write('\'');
            break;
          case '"':
            sb.write('"');
            break;
          case '\\':
            sb.write('\\');
            break;
          case '\$':
            sb.write('\$');
            break; // Handle $ in string (common issue with Dart string interpolation)
          case 'u':
            // Start of Unicode escape sequence (e.g., \u0061 for 'a')
            isEscapingUnicode = true;
            unicodeSequence = '';
            _advance();
            continue;
          // Additional escape sequences
          case '0':
            sb.write('\0');
            break; // Null character
          case 'v':
            sb.write('\v');
            break; // Vertical tab
          case 'x':
            // Hexadecimal escape sequence \xHH (2 digits)
            if (_isAtEnd() || _isAtEnd(1)) {
              errorReporter.reportStandardError(
                'Incomplete hexadecimal escape sequence',
                _current,
              );
              sb.write('x');
            } else {
              final hexSeq = _peekNext() + _peekNext(2);
              if (_isHex(hexSeq)) {
                sb.write(String.fromCharCode(int.parse(hexSeq, radix: 16)));
                _advance(); // Consume first hex digit
                _advance(); // Consume second hex digit
              } else {
                errorReporter.reportStandardError(
                  'Invalid hexadecimal escape sequence: \\x$hexSeq',
                  _current,
                );
                sb.write('x$hexSeq');
              }
            }
            break;
          case '\n':
            // Line continuation - handle escaped newlines in non-multiline strings
            // Just skip the newline, allowing for line breaks in strings
            _line++;
            _column = 1;
            break;
          default:
            errorReporter.reportWarning(
              'Unknown escape sequence: \\$char - treating as literal character',
              _current - 1,
            );
            // For unknown escape sequences, include the character literally
            sb.write(char);
            break;
        }
      } else if (char == '\\') {
        // Start of an escape sequence
        isEscaping = true;
      } else {
        // Regular character
        sb.write(char);
      }

      _advance();
    }

    if (_isAtEnd()) {
      errorReporter.reportStandardError(
        isMultiLine
            ? 'Unterminated multi-line string literal'
            : 'Unterminated string literal',
        _current,
      );
      // Add partial string as a recovery measure
      _addToken(
        TokenType.string,
        sb.toString(),
        SourcePosition(_line, _column, _current),
      );
      return;
    }

    // Add the string token with the parsed value
    final value = sb.toString();
    _addToken(
      TokenType.string,
      value,
      SourcePosition(_line, _column, _current),
    );
  }

  /// Checks if the current string is a multiline string (triple-quoted)
  /// Returns true if this is a multiline string, false otherwise
  bool _checkMultilineString(String delimiter) {
    // Check if we have two more of the same delimiter character
    if (_peek() == delimiter && _peekNext() == delimiter) {
      // Triple-quoted string - advance past the additional quotes
      _advance(); // Second quote
      _advance(); // Third quote
      return true;
    }
    return false;
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

    // Special handling for documentation and decision keywords
    // Force these to be the correct token types
    if (text == 'documentation') {
      _logger.fine(
          'LEXER DEBUG: Found documentation keyword, forcing TokenType.documentation');
      _addToken(TokenType.documentation);
      return;
    } else if (text == 'decisions') {
      _logger.fine(
          'LEXER DEBUG: Found decisions keyword, forcing TokenType.decisions');
      _addToken(TokenType.decisions);
      return;
    }

    // Check if it's a keyword
    final type = keywords[text] ?? TokenType.identifier;

    // Debug for documentation and decisions keywords
    if (text == 'documentation' || text == 'decisions') {
      _logger.fine(
          'LEXER DEBUG: Found identifier: $text, recognized as token type: $type');
    }

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
    final pos =
        position ?? SourcePosition(_line, _column - (lexeme.length), _start);

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

  /// Checks if the given character is an alphabetic character, underscore, or dollar sign.
  bool _isAlpha(String c) {
    final code = c.codeUnitAt(0);
    return (code >= 'a'.codeUnitAt(0) && code <= 'z'.codeUnitAt(0)) ||
        (code >= 'A'.codeUnitAt(0) && code <= 'Z'.codeUnitAt(0)) ||
        c == '_' ||
        c == '\$'; // Add $ as valid for identifiers
  }

  /// Checks if the given character is alphanumeric, underscore, or dollar sign.
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
  /// If we're at the end of the source, returns null character.
  String _advance() {
    if (_isAtEnd()) {
      return '\0';
    }
    _column++;
    return source[_current++];
  }

  /// Checks if we've reached the end of the source.
  bool _isAtEnd([int offset = 0]) {
    return _current + offset >= source.length;
  }
}
