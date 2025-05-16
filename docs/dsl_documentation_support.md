# DSL Documentation Support

This document explains the support for documentation blocks and architecture decision records (ADRs) in the Structurizr DSL parser.

## Documentation Blocks

Documentation blocks in the Structurizr DSL provide a way to add documentation to a workspace, including formatted text, sections, and embedded diagrams.

### Basic Documentation

```
workspace "Name" {
  documentation {
    content = "This is the documentation for the workspace."
  }
}
```

### Formatted Documentation

The documentation format can be specified (default is Markdown):

```
workspace "Name" {
  documentation format="asciidoc" {
    content = "= AsciiDoc Title\n\nContent in AsciiDoc format."
  }
}
```

Supported formats:
- `markdown` (default)
- `asciidoc`
- `text` (plain text)

### Documentation Sections

Documentation can be organized into sections:

```
workspace "Name" {
  documentation {
    section "Overview" {
      content = "This section provides an overview."
    }
    section "Details" {
      content = "This section contains detailed information."
    }
  }
}
```

## Architecture Decision Records (ADRs)

ADRs provide a way to document architecture decisions:

```
workspace "Name" {
  decisions {
    decision "ADR-001" {
      title = "Use Markdown for documentation"
      status = "Accepted"
      date = "2023-05-20"
      content = "We will use Markdown for documentation because it is widely supported..."
    }
    
    decision "ADR-002" {
      title = "Use AsciiDoc for technical documentation"
      status = "Proposed"
      date = "2023-06-15"
      content = "For more complex technical documentation, we should..."
    }
  }
}
```

ADR properties:
- `title`: The title of the decision
- `status`: The current status (e.g., "Proposed", "Accepted", "Superseded")
- `date`: When the decision was made or proposed
- `content`: The detailed content of the decision
- `format`: (optional) The format of the content (default is markdown)

## Embedding Diagrams

Documentation can reference diagrams (implementation in progress):

```
workspace "Name" {
  documentation {
    section "System Context" {
      content = "The system context diagram shows...\n\n![System Context](embed:SystemContext)"
    }
  }
}
```

## Implementation Status

The current implementation status for documentation support:

- ✅ Token definitions for documentation blocks, sections, and ADRs
- ✅ Lexer support for scanning documentation-related tokens
- ✅ AST node structure for documentation entities:
  - DocumentationNode
  - DocumentationSectionNode
  - DiagramReferenceNode
  - DecisionNode
- ✅ Parser methods for documentation blocks and ADRs:
  - _parseDocumentation
  - _parseDocumentationSection
  - _parseDecisions
  - _parseDecision
- ✅ WorkspaceNode updated to include documentation and decisions fields
- ✅ Comprehensive lexer tests for documentation token recognition
- ⚠️ AST integration has circular dependency issues that need resolution
- ❌ Complete integration with workspace model
- ❌ Support for embedded diagram references
- ❌ Full parser tests for documentation blocks

## Technical Challenges

The implementation has encountered several challenges:

1. **AST Circular Dependencies**:
   - The AST structure has circular dependencies that complicate the implementation
   - The visitor pattern implementation needs refinement to handle documentation nodes correctly

2. **Node Type Integration**:
   - Documentation nodes need to be integrated into the existing workspace model
   - Workspace mapper needs to be extended to handle documentation nodes

3. **Format Handling**:
   - Different documentation formats (Markdown, AsciiDoc) need special handling
   - Embedded diagrams require additional processing

## Next Steps

To complete the documentation support:

1. Resolve circular dependencies in the AST structure
2. Complete the integration with workspace model
3. Implement embedded diagram reference support
4. Add comprehensive tests for documentation parsing
5. Create examples showing documentation usage

## Testing

Run documentation tests with:

```bash
# Test lexer token recognition
flutter test test/domain/parser/documentation_lexer_test.dart

# Test parser implementation (pending complete implementation)
# flutter test test/domain/parser/documentation_parser_test.dart
```