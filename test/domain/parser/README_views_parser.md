# ViewsParser Tests

This directory contains tests for the ViewsParser implementation, which is responsible for parsing the views section of the Structurizr DSL.

## Test Files

- **views_parser_test.dart**: Unit tests for the ViewsParser methods (Table 6 from the refactored_method_relationship.md)
- **views_parser_integration_test.dart**: Integration tests that verify the ViewsParser works correctly with the rest of the Parser infrastructure

## Test Coverage

The tests cover the following methods from Table 6:

1. `ViewsParser.parse(List<Token>)`: Parses a views block from a token stream and returns a ViewsNode
2. `ViewsParser._parseViewBlock(List<Token>)`: Parses a view block (system context, container, etc.)
3. `ViewsParser._parseViewProperty(List<Token>)`: Parses a view property (title, description, etc.)
4. `ViewsParser._parseInheritance(List<Token>)`: Parses inheritance between views
5. `ViewsParser._parseIncludeExclude(List<Token>)`: Parses include/exclude statements in views
6. `ViewsNode.addView(ViewNode)`: Adds a view to the appropriate collection
7. `ViewNode.setProperty(ViewPropertyNode)`: Updates a view's property

## Implementation Status

- [x] Unit tests for all methods
- [x] Integration tests for all methods
- [ ] Implementation of methods (pending)

## How to Run the Tests

Unit tests:
```bash
flutter test test/domain/parser/views_parser_test.dart
```

Integration tests (currently skipped until implementation is complete):
```bash
flutter test test/domain/parser/views_parser_integration_test.dart
```

## Implementation Notes

- The ViewsParser should be implemented in `lib/domain/parser/views_parser.dart`.
- The current implementation contains stubs that throw UnimplementedError.
- When implementing, follow the original Java Structurizr DSL implementation as a reference (see `references/dsl/dsl/src/main/java/com/structurizr/dsl/`).
- The ViewPropertyNode class is defined in the ViewsParser file, which may need to be moved to its own file or the main AST nodes file later.
- Extensions for ViewsNode and ViewNode have been added to help with testing and functionality.
- Integration tests are skipped until the implementation is complete. Remove the `skip: true` parameter when ready.

## DSL Syntax Examples

### Basic Views Block

```
views {
  systemContext system "SystemContext" {
    include *
    autoLayout
  }
  
  containerView system "Containers" {
    include *
    autoLayout
  }
}
```

### View Properties

```
systemContext system "SystemContext" "System Context diagram" {
  include *
  autoLayout tb 300 150
}
```

### Include/Exclude Statements

```
systemContext system "SystemContext" {
  include user
  include system
  exclude admin
}
```

### Animation Steps

```
systemContext system "SystemContext" {
  include *
  animation {
    user
  }
  
  animation {
    system
  }
}
```

### View Inheritance

```
filteredView "UserOnly" {
  baseOn "SystemContext"
  include user
}
```