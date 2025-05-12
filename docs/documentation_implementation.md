# Documentation Component Implementation

This document summarizes the implementation of the Documentation components for Flutter Structurizr, as specified in Phase 5 of the implementation plan.

## Components Implemented

### Domain Models

1. **Documentation**: Main container model for all documentation content
   - `sections`: List of DocumentationSection objects
   - `decisions`: List of Decision objects (Architecture Decision Records)
   - `images`: List of Image objects

2. **DocumentationSection**: Represents a single section of documentation
   - `title`: Section title
   - `content`: Markdown or AsciiDoc content
   - `format`: Content format (Markdown or AsciiDoc)
   - `order`: Ordering/positioning of sections
   - `filename`: Optional source filename
   - `elementId`: Optional related model element

3. **Decision**: Architecture Decision Record
   - `id`: Unique identifier
   - `date`: Decision date
   - `status`: Decision status (Proposed, Accepted, etc.)
   - `title`: Decision title
   - `content`: Decision content in Markdown or AsciiDoc
   - `links`: References to other decisions

4. **Image**: Images embedded in documentation
   - `name`: Image name/identifier
   - `content`: Base64-encoded image data
   - `type`: MIME type

### Presentation Components

1. **MarkdownRenderer**: Widget to render Markdown content
   - Supports standard Markdown formatting
   - Code syntax highlighting for various languages
   - Section numbering for headers
   - Embedded diagram references with custom syntax `![Title](embed:ViewKey)`
   - Support for light and dark themes

2. **DocumentationNavigator**: Main navigation component
   - Manages navigation between documentation sections and decisions
   - Includes a table of contents sidebar
   - Supports viewing either documentation or decisions
   - Tracks and manages navigation state

3. **TableOfContents**: Sidebar component
   - Displays structured list of documentation sections
   - Displays list of architecture decisions with status indicators
   - Provides tab navigation between documentation and decisions
   - Supports selection and highlighting of current item

## Implementation Details

### Documentation Model

- Added to the Workspace model as an optional property
- Created a DocumentationConverter for JSON serialization
- Added complete JSON serialization support
- Support for validation

### MarkdownRenderer

- Built on top of flutter_markdown
- Added custom extensions for diagram embedding
- Custom code syntax highlighting using flutter_highlight
- Theming support for light and dark modes
- Section numbering for hierarchical content

### DocumentationNavigator

- Stateful navigation between sections and decisions
- Controller-based state management for easy integration
- Responsive layout with side-by-side navigation and content
- Support for linked decisions and cross-references

## Testing

A comprehensive test suite was created for all components:

1. **Domain Model Tests**:
   - Creation and property access
   - JSON serialization/deserialization
   - Default values and optional properties

2. **MarkdownRenderer Tests**:
   - Basic Markdown rendering
   - Section numbering functionality
   - Code syntax highlighting
   - Diagram embedding
   - Light and dark theme support

3. **DocumentationNavigator Tests**:
   - Navigation controller functionality
   - Section and decision navigation
   - View toggling
   - Handling empty or missing documentation

4. **TableOfContents Tests**:
   - Section and decision rendering
   - Selection callbacks
   - Empty state handling
   - Theme support

## Usage Example

```dart
// Create a DocumentationNavigator for a workspace
DocumentationNavigator(
  workspace: workspace,
  initialSectionIndex: 0,
  isDarkMode: Theme.of(context).brightness == Brightness.dark,
  onDiagramSelected: (viewKey) {
    // Handle diagram selection, e.g., show the diagram
    showDiagram(context, workspace, viewKey);
  },
)
```

## Next Steps

1. **AsciiDoc Support**: Implement proper AsciiDoc rendering (currently just shows raw content)
2. **Documentation Editor**: Add editing capabilities for documentation and decisions
3. **Search Functionality**: Implement full-text search across documentation
4. **Responsive Design**: Enhance mobile support and responsive layouts

## Running the Tests

To run the tests for the Documentation components:

```bash
./run_documentation_tests.sh
```

To generate the necessary code files (using Freezed and JSON serialization):

```bash
./generate_code.sh
```