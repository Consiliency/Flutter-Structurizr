# Structurizr DSL Abstract Syntax Tree (AST)

This directory contains the AST (Abstract Syntax Tree) classes for the Structurizr DSL parser. The AST provides a structured representation of the Structurizr DSL code, which can be used for analyzing, transforming, and generating code from DSL files.

## Class Hierarchy

The AST classes follow a hierarchical structure that mirrors the structure of Structurizr DSL:

- `AstNode`: Base class for all AST nodes
  - `WorkspaceNode`: Root node representing a Structurizr workspace
    - `ModelNode`: Represents the model section in a workspace
      - `PersonNode`, `SoftwareSystemNode`, `ContainerNode`, etc.: Model elements
    - `ViewsNode`: Represents the views section
      - `SystemLandscapeViewNode`, `SystemContextViewNode`, etc.: View definitions
    - Other workspace-level nodes like `StylesNode`, `ThemeNode`, etc.

## Usage

The AST is typically built by a parser and then processed using the Visitor pattern. To implement a visitor, create a class that implements the `AstVisitor` interface:

```dart
class MyVisitor implements AstVisitor {
  @override
  void visitWorkspaceNode(WorkspaceNode node) {
    // Process workspace node
    
    // Visit model if it exists
    if (node.model != null) {
      node.model!.accept(this);
    }
    
    // Visit views if they exist
    if (node.views != null) {
      // Process views node children manually since ViewsNode doesn't have its own visit method
      for (var view in node.views!.allViews) {
        view.accept(this);
      }
    }
  }
  
  // Implement other visit methods...
}
```

## Key Files

- `ast_node.dart`: Defines the base `AstNode` class and `AstVisitor` interface
- `workspace_node.dart`: Contains workspace-related node classes
- `model_node.dart`: Contains model element node classes
- `relationship_node.dart`: Contains relationship node classes
- `view_node.dart`: Contains view node classes
- `property_node.dart`: Contains property, tag, style, and other attribute node classes

## Creating New Node Types

To add a new node type:

1. Create a class that extends the appropriate base AST node class
2. Add a corresponding visit method to the `AstVisitor` interface
3. Implement the `accept` method to call the appropriate visitor method

## Limitations

- The AST structure is focused on representing the structural elements of the DSL and may not capture all semantic details
- Some advanced DSL features may require additional processing beyond the AST representation