# Documentation Parser Testing Guide

This document outlines the comprehensive testing approach for the documentation parsing functionality in the Dart/Flutter Structurizr implementation.

## Overview

The documentation parser is responsible for parsing documentation blocks and Architecture Decision Records (ADRs) from the Structurizr DSL and converting them to the domain model. This is a critical component of the Structurizr implementation, as it enables rich documentation capabilities within architecture models.

Our testing approach is multi-layered, testing each component of the documentation parsing pipeline independently, as well as testing the integration of these components. This ensures robust functionality and helps isolate issues when they occur.

## Documentation Pipeline Components

The documentation processing pipeline consists of several key components:

1. **Lexer**: Converts DSL text into tokens
2. **Parser**: Transforms tokens into an Abstract Syntax Tree (AST)
3. **Mapper**: Converts AST nodes to domain model objects
4. **Domain Model**: Stores and manipulates documentation in the application

## Testing Components

### 1. Documentation Domain Model

**Purpose**: Test the domain model classes for documentation.

**Test Files**:
- `/test/domain/documentation/documentation_test.dart`

**What's Tested**:
- Creation and serialization of `Documentation` objects
- Creation and serialization of `DocumentationSection` objects
- Creation and serialization of `Decision` (ADR) objects
- Immutability of documentation objects
- Proper date handling for decisions

**Running Tests**:
```bash
flutter test test/domain/documentation/documentation_test.dart
```

### 2. Documentation Lexer

**Purpose**: Test token recognition for documentation-related syntax.

**Test Files**:
- `/test/domain/parser/documentation_lexer_test.dart`

**What's Tested**:
- Recognition of `documentation` keyword
- Recognition of `format` property
- Recognition of `content` property
- Recognition of `section` keyword
- Recognition of `decision` keyword and properties
- String literal parsing for documentation content
- Format specification parsing (markdown, asciidoc, text)
- Proper handling of nested documentation blocks

**Running Tests**:
```bash
flutter test test/domain/parser/documentation_lexer_test.dart
```

### 3. Documentation Parser

**Purpose**: Test AST node creation for documentation blocks.

**Test Files**:
- `/test/domain/parser/documentation_parser_test.dart`

**What's Tested**:
- Basic documentation block parsing
- Documentation with sections
- Documentation with format specification
- Decision records parsing
- Links between decisions
- Error handling for malformed documentation blocks
- Proper source position tracking for error reporting

**Running Tests**:
```bash
flutter test test/domain/parser/documentation_parser_test.dart
```

### 4. Documentation Mapper

**Purpose**: Test the conversion of AST nodes to domain model objects.

**Test Files**:
- `/test/application/dsl/documentation_mapper_test.dart`

**What's Tested**:
- Mapping `DocumentationNode` to `Documentation` domain model
- Creating Overview section from root content
- Mapping `DocumentationSectionNode` to `DocumentationSection`
- Mapping `DecisionNode` to `Decision` with date parsing
- Handling links between decisions
- Proper error reporting during mapping
- Format conversion between AST and domain model

**Running Tests**:
```bash
flutter test test/application/dsl/documentation_mapper_test.dart
```

### 5. Integration Tests

**Purpose**: Test the entire pipeline from DSL parsing to domain model.

**Test Files**:
- `/test/integration/documentation_integration_test.dart`

**What's Tested**:
- End-to-end parsing of documentation blocks
- End-to-end parsing of decision records
- Proper integration with the workspace model
- Full parsing pipeline verification
- Handling of complex, real-world documentation examples
- Combined documentation and decisions in a single workspace

**Running Tests**:
```bash
flutter test test/integration/documentation_integration_test.dart
```

## Testing Tools and Utilities

### DefaultAstVisitor

The `DefaultAstVisitor` is a powerful utility class that provides empty implementations for all visitor methods in the `AstVisitor` interface. This makes testing much easier by allowing test code to only override the methods they need to test.

**Key Benefits**:
- Reduces boilerplate in test code
- Makes tests more focused and readable
- Simplifies creation of test visitors

**Example Usage**:
```dart
class TestVisitor extends DefaultAstVisitor {
  String? documentationContent;
  
  @override
  void visitDocumentationNode(DocumentationNode node) {
    documentationContent = node.content;
  }
}

// In test
final visitor = TestVisitor();
node.accept(visitor);
expect(visitor.documentationContent, 'Expected content');
```

### Test Fixtures

We use consistent test fixtures across test levels to ensure that we're testing the same functionality in different ways:

```dart
const source = '''
  workspace "Test" {
    documentation {
      content = "This is a test documentation"
    }
  }
''';
```

These fixtures are used in lexer tests, parser tests, mapper tests, and integration tests, with slight variations as needed.

## Continuous Testing

### Running All Tests

To run all documentation parser-related tests, use the provided script:

```bash
./scripts/test_documentation_parser.sh
```

This script will:
1. Run all tests related to documentation parsing
2. Report any failures with clear error messages
3. Provide a summary of test results

### Adding to CI/CD Pipeline

The documentation parser tests are integrated into the project's CI/CD pipeline to ensure that any changes to the codebase don't break documentation functionality. These tests run automatically on:

- Pull requests to main branches
- Direct commits to main branches
- Scheduled nightly builds

## Test-Driven Development Workflow

When adding new features to the documentation parser, we recommend following this TDD workflow:

1. Write a failing test for the new feature
2. Implement the minimum code needed to make the test pass
3. Refactor the code while keeping the tests passing
4. Repeat for each new feature

## Troubleshooting Common Issues

### 1. Circular Dependencies

If you encounter circular dependency errors:
- Check the import statements in AST node files
- Use proper import aliases to break dependency cycles
- Consider moving shared interfaces to separate files
- Use `domain.Documentation` as an alias for domain model classes

### 2. Type Conflicts

The documentation system has several classes with similar names in different namespaces:
- AST nodes in `domain/parser/ast/nodes/documentation/`
- Domain model in `domain/documentation/`

To avoid conflicts:
- Use namespace aliases: `import '...' as domain;`
- Use fully qualified names where necessary
- Be consistent with naming conventions

### 3. Test Failures

Common causes of test failures:
- Incorrect AST structure
- Mismatched visitor pattern implementation
- Forgotten visitor method overrides
- Improper handling of null values

Solutions:
- Verify that you're using the latest AST nodes
- Check for proper visitor pattern implementation
- Review the DefaultAstVisitor for missing methods

### 4. Date Parsing Issues

Decision dates must be in ISO format (YYYY-MM-DD) to be properly parsed. Common issues include:
- Incorrect date format in test fixtures
- Missing error handling for invalid dates
- Timezone-related issues when comparing parsed dates

## Extending the Test Suite

When adding new features to the documentation parser, follow this pattern:

1. **Add Lexer Tests**:
   - Add tests for any new tokens in `documentation_lexer_test.dart`
   - Test both valid and invalid token sequences

2. **Add Parser Tests**:
   - Add tests for AST node creation in `documentation_parser_test.dart`
   - Test properties, nesting, and error conditions

3. **Add Mapper Tests**:
   - Add tests for domain model conversion in `documentation_mapper_test.dart`
   - Test property mapping and error conditions

4. **Add Integration Tests**:
   - Add tests for the full pipeline in `documentation_integration_test.dart`
   - Use realistic documentation examples

This ensures comprehensive test coverage at all levels of the implementation and helps maintain a robust documentation system.