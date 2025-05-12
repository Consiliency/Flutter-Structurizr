# Structurizr DSL Parser

This directory contains the implementation of a parser for the Structurizr Domain Specific Language (DSL).

## Components

### Lexer

The lexer is responsible for converting the source text into tokens that can be processed by the parser. It handles:

- Tokenizing keywords, identifiers, literals, and operators
- Tracking line and column numbers for error reporting
- Skipping comments and whitespace
- Handling string and number literals
- Special handling for Structurizr directives (starting with !)

#### Usage

```dart
import 'package:dart_structurizr/domain/parser/lexer/lexer.dart';

void main() {
  final source = '''
    workspace "Example" {
      model {
        user = person "User"
        system = softwareSystem "System"
        
        user -> system "Uses"
      }
    }
  ''';
  
  final lexer = Lexer(source);
  final tokens = lexer.scanTokens();
  
  // Check for lexical errors
  if (lexer.hasErrors) {
    print(lexer.errorReporter.formatErrors());
    return;
  }
  
  // Process tokens
  for (var token in tokens) {
    print(token);
  }
}
```

### Error Reporting

The lexer uses the `ErrorReporter` class to collect and report errors during lexical analysis. This provides:

- Error messages with line and column information
- Source code snippets showing where errors occurred
- Severity levels (error, warning, info)

## Testing

Test files are available in the `tests` directory to verify the lexer's functionality:

- `lexer_test.dart`: Tests for the lexer implementation

## Future Components

The parser will include the following components (to be implemented):

1. **Parser**: Converts tokens into an Abstract Syntax Tree (AST)
2. **AST Nodes**: Represent the structure of the Structurizr DSL
3. **Semantic Analyzer**: Validates the AST and resolves references
4. **Code Generator**: Generates Dart model objects from the AST

## References

For more information about the Structurizr DSL, refer to:

- [Structurizr DSL documentation](https://structurizr.com/dsl)
- Local documentation in `/ai_docs/structurizr_dsl_v1.md`