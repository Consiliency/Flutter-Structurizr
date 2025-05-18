# CLAUDE.md

> **NOTE:** This file is for developer memory, best practices, and lessons learned only. Do **not** use for app status, user documentation, or implementation progress. All user-facing status and documentation belong in the README and specs.

## Original Structurizr Technical Stack

The original Structurizr implementations that are being ported to Dart/Flutter:

- **Structurizr UI**: JavaScript/TypeScript single-page application
- **Structurizr Lite**: Java-based standalone application
- **Structurizr DSL**: Text-based DSL implemented in Java
- **Structurizr JSON Schema**: JSON schema definition for serialization

## Dart/Flutter Implementation

This project is implemented using:

- **Dart**: Core language for all logic (v3.0.0+)
- **Flutter**: UI framework (v3.10.0+)
- **Riverpod**: State management
- **CustomPainter**: Custom rendering for diagrams
- **WebView**: For complex rendering tasks like AsciiDoc

## Original to Dart Mapping

| Original Component | Dart/Flutter Implementation |
|--------------------|------------------------------|
| `StructurizrClient.java` | `infrastructure/network/structurizr_client.dart` |
| `Workspace.java` | `domain/model/workspace.dart` |
| `Model.java` | `domain/model/model.dart` |
| `StructurizrDslParser.java` | `domain/parser/parser.dart` |
| `Person.java` | Re-export from `domain/model/model.dart` via `domain/model/person.dart` |
| `SoftwareSystem.java` | Re-export from `domain/model/model.dart` via `domain/model/software_system.dart` |
| `Container.java` | Re-export from `domain/model/model.dart` via `domain/model/container.dart` |
| `Documentation.java` | `domain/documentation/documentation.dart` |
| `TableOfContents.js` | `presentation/widgets/documentation/table_of_contents.dart` |
| `MarkdownRenderer.js` | `presentation/widgets/documentation/markdown_renderer.dart` |
| `AsciiDocRenderer.js` | `presentation/widgets/documentation/asciidoc_renderer.dart` |
| JavaScript UI code | `presentation/widgets/` directory |
| Structurizr Styles | `domain/style/styles.dart` |

## Best Practices and Lessons Learned

- **Import Conflict Resolution:**
  - Always use `hide` directives to avoid conflicts with Flutter built-ins (Container, Element, View, Border).
  - Use alias types (ModelElement, ModelContainer, ModelView) for domain model classes.
  - Prefer Material or SizedBox over Container for UI layout when conflicts arise.

- **Widget Testing:**
  - Use mock implementations for abstract classes and platform interfaces (e.g., WebViewPlatform) in tests.
  - For WebView tests, inject a mock platform and use a test controller wrapper if needed for delegate/callback wiring.
  - Use `findsWidgets` instead of `findsOneWidget` for components that may have multiple instances.
  - Use ancestor finders for specific widget hierarchy checks.
  - For context menu and right-click, verify structure rather than simulating clicks.
  - For golden tests, plan for future visual regression coverage.
  - Clean up unused imports and test helpers after refactors.

- **Error Handling:**
  - Implement comprehensive error reporting with context-sensitive messages.
  - Use structured error collectors for parser and model validation.
  - Add robust error handling for file I/O and remote sync.

- **Performance:**
  - Use chunking and caching for large document rendering (AsciiDoc, Markdown).
  - Optimize rendering and layout for large diagrams (level-of-detail, culling, progressive loading).
  - Plan for parallel processing and benchmarking in future phases.

- **UI/UX:**
  - Provide keyboard shortcuts for all navigation-heavy interfaces.
  - Use debouncing for export preview and performance-intensive UI updates.
  - Implement help dialogs for keyboard shortcuts and advanced features.
  - Use chip-based filtering and color coding for status and type indicators.

- **Workspace and Export:**
  - Use platform-specific file system handling for workspace management.
  - Implement auto-save and backup for reliability.
  - Ensure all export formats are tested and previewed in the UI.

- **General:**
  - Always keep specs and status in the `specs/` directory.
  - Do not duplicate status or user documentation in this file.
  - When in doubt, check the latest specs and implementation status for guidance.

## Flutter Import Conflict Resolution Guide

```dart
// For Element conflicts
import 'package:flutter/material.dart' hide Element;
import 'package:flutter_structurizr/domain/model/element.dart';

// For Container conflicts
import 'package:flutter/material.dart' hide Container;
import 'package:flutter_structurizr/domain/model/container.dart';

// For View conflicts
import 'package:flutter/material.dart' hide View;
import 'package:flutter_structurizr/domain/view/view.dart';

// For multiple conflicts
import 'package:flutter/material.dart' hide Element, Container, View, Border;
```

## Widget Testing Best Practices

- Use mock implementations for abstract classes in tests.
- Use factory methods for easy test object creation.
- Prefer Material components over basic Container widgets for layout.
- Use `SingleChildScrollView` for long content and `Expanded` for flexible sizing.
- Handle text overflow with `TextOverflow.ellipsis`.

## Additional Developer Notes

- For large document rendering, use chunking and LRU caching.
- For undo/redo, use the Command pattern and group operations into transactions.
- For export preview, use debouncing and provide real-time feedback.
- For cross-platform file access, use platform detection and standard file locations.
- For error-prone areas (e.g., parsing, file I/O), add extra logging and recovery options.

---

**REMEMBER:**
- This file is for developer memory and best practices only.
- Do **not** use for app status, user documentation, or implementation progress.
- Keep all user-facing status and documentation in the README and specs.

## UI Components Guide

### Element Explorer with Context Menu

The `ElementExplorer` widget has been enhanced with context menu support. When implementing or modifying this component:

1. **Import Conflict Resolution**:
   ```dart
   import 'package:flutter/material.dart' hide Element, Container, View, Border;
   ```

2. **Context Menu Configuration**:
   ```dart
   ElementExplorerConfig(
     enableContextMenu: true,
     contextMenuItems: [
       ElementContextMenuItem(
         id: 'action_id',
         label: 'Menu Label',
         icon: Icons.icon_name,
         filter: (element) => element.type == 'Container', // Optional
       ),
     ],
   )
   ```

3. **Handling Menu Selection**:
   ```dart
   onContextMenuItemSelected: (itemId, elementId, element) {
     // Handle menu action
   },
   ```

4. **Menu Item Filtering**:
   - Use the `filter` function to conditionally show menu items based on element type
   - This allows for context-specific menus that adapt to the selected element

5. **Example Usage**:
   - See `/example/lib/element_explorer_example.dart` for complete implementation
   - Run with `example/run_element_explorer_example.sh`

## Widget Testing Best Practices

When testing UI components in this project, follow these guidelines:

1. **Widget Finder Issues**:
   - Use `findsWidgets` instead of `findsOneWidget` when multiple instances may exist
   - Use ancestor finders to locate specific widgets in the hierarchy:
     ```dart
     final specificWidget = find.ancestor(
       of: find.text('Some Text'),
       matching: find.byWidgetPredicate((widget) =>
         widget is Text && widget.style?.fontWeight == FontWeight.bold
       )
     );
     ```

2. **Container Conflicts in Tests**:
   - Replace Flutter's Container with combination of DecoratedBox + SizedBox + Padding
   - Example:
     ```dart
     // Instead of Container use:
     DecoratedBox(
       decoration: BoxDecoration(...),
       child: SizedBox(
         width: 200,
         child: Padding(
           padding: const EdgeInsets.all(8.0),
           child: childWidget,
         ),
       ),
     )
     ```

3. **Context Menu Testing**:
   - The Flutter test framework has limited support for right-click testing
   - Verify GestureDetector presence and structure instead of fully simulating clicks
   - For manual testing, use the example applications

## DSL Parser Documentation Support

The DSL parser has initial support for parsing documentation blocks and Architecture Decision Records (ADRs).

### Documentation Blocks

Documentation blocks in the DSL support multiple formats:

```dart
workspace "Name" {
  documentation {
    content = "This is basic documentation"
  }
  
  // With format specification
  documentation format="asciidoc" {
    content = "= AsciiDoc Title\n\nContent here."
  }
  
  // With sections
  documentation {
    section "Overview" {
      content = "Overview content"
    }
    section "Details" {
      content = "Detailed content"
    }
  }
}
```

### Architecture Decision Records

ADRs are supported using the decisions block:

```dart
workspace "Name" {
  decisions {
    decision "ADR-001" {
      title = "Use Markdown for documentation"
      status = "Accepted"
      date = "2023-05-20"
      content = "We will use Markdown because..."
      links "ADR-002", "ADR-003" // Related decisions
    }
  }
}
```

### Implementation Status

The documentation parsing implementation is currently in progress:

- ✅ Token definitions for documentation blocks and ADRs
- ✅ Lexer support for scanning documentation tokens
- ✅ AST node types for documentation entities
- ✅ Parser methods for documentation blocks and ADRs
- ✅ Integration with workspace model for basic documentation sections
- ⚠️ AST circular dependencies need to be resolved

### Testing Documentation Parser

To test documentation parsing functionality:

```dart
// Test lexer token recognition
flutter test test/domain/parser/documentation_lexer_test.dart

// Test parser implementation (pending full implementation)
// flutter test test/domain/parser/documentation_parser_test.dart
```

## Documentation Components

The documentation system includes several components for rendering and navigating documentation in different formats:

### TableOfContents

The `TableOfContents` widget displays a hierarchical structure of documentation sections with collapsible hierarchy:

```dart
TableOfContents(
  sections: documentationSections,
  decisions: decisions,
  currentSectionIndex: currentSectionIndex,
  currentDecisionIndex: currentDecisionIndex,
  viewingDecisions: viewingDecisions,
  onSectionSelected: (index) {
    // Handle section selection
  },
  onDecisionSelected: (index) {
    // Handle decision selection
  },
  onToggleView: () {
    // Handle toggle between documentation and decisions
  },
  isDarkMode: false, // Optional
)
```

Key features:
- Collapsible hierarchy with expand/collapse controls
- Visual indentation for nested sections
- Support for both documentation sections and decisions
- Active section highlighting
- Element reference display for documentation sections
- Status indication for decisions with color coding
- Toggle between documentation and decisions views

### MarkdownRenderer

The `MarkdownRenderer` widget renders Markdown content with enhanced features:

```dart
MarkdownRenderer(
  content: markdownContent,
  isDarkMode: false, // Optional
  syntaxHighlighting: true, // Optional
  onLinkTapped: (url) {
    // Handle link taps
  },
)
```

Key features:
- Syntax highlighting with custom github-dark theme
- Section numbering with proper hierarchy
- Diagram embedding support
- Enhanced table rendering
- Custom link handling

### AsciidocRenderer

The `AsciidocRenderer` widget renders AsciiDoc content using WebView with optimization for large documents:

```dart
AsciidocRenderer(
  content: asciidocContent,
  isDarkMode: false, // Optional
  useOfflineMode: true, // Optional
  enableCaching: true, // Optional
  chunkSize: 100000, // Optional, chunk size for large documents
  maxCacheSize: 10240, // Optional, maximum cache size in KB
  onLinkTapped: (url) {
    // Handle link taps
  },
  onDiagramSelected: (key) {
    // Handle embedded diagram selection
  },
)
```

Key features:
- Offline rendering support with local asciidoctor.js and highlight.js
- Error handling with user-friendly messages and retry functionality
- Dark mode styling support with custom CSS
- JavaScript error logging via JS channels
- Custom link handling for navigation and diagram selection
- Progressive rendering for large documents with chunking
- Content caching with LRU eviction strategy
- Performance metrics tracking with detailed stats
- Progress indicators during rendering process

### DocumentationNavigator

The `DocumentationNavigator` widget provides a complete browser-like interface for documentation with keyboard navigation:

```dart
DocumentationNavigator(
  workspace: workspace,
  controller: controller, // Optional
  initialSectionIndex: 0, // Optional
  isDarkMode: false, // Optional
  onDiagramSelected: (key) { // Optional
    // Handle diagram selection
  },
  showToolbar: true, // Optional
)
```

Key features:
- Browser-like navigation (back/forward) with history tracking
- Breadcrumb navigation with click-to-navigate
- Integrated search functionality with result highlighting
- Responsive layout with resizable panels and fullscreen toggle
- Table of contents integration with collapsible hierarchy
- Complete keyboard navigation support:
  - Arrow keys for navigation between sections/decisions
  - Alt+Left/Right for back/forward history navigation
  - Ctrl+D/G/T/S for switching between documentation views
  - Ctrl+F for toggling fullscreen mode
  - Home/End for jumping to first/last section
  - Alt+Number keys for direct navigation to sections
  - Ctrl+? for keyboard shortcuts help dialog

## Architecture Decision Records (ADR) Components

The project includes several components for visualizing and managing Architecture Decision Records:

### DecisionGraph

The `DecisionGraph` widget visualizes relationships between architectural decisions using a force-directed graph:

```dart
DecisionGraph(
  decisions: decisions,
  onDecisionSelected: (index) {
    // Handle selection
  },
  isDarkMode: false, // Optional
)
```

Key features:
- Force-directed layout with physics simulation
- Interactive zoom and pan controls
- Decision nodes with status indicators
- Relationship visualization with arrows
- Simulation controls for pausing/resuming

### DecisionTimeline

The `DecisionTimeline` widget displays decisions chronologically with filtering:

```dart
DecisionTimeline(
  decisions: decisions,
  onDecisionSelected: (index) {
    // Handle selection
  },
  isDarkMode: false, // Optional
)
```

Key features:
- Chronological display with year/month grouping
- Date range filtering with inclusive boundaries
- Status filtering with visual indicators
- Filter dialog with intuitive controls

### DecisionList

The `DecisionList` widget provides a filterable list of architectural decisions:

```dart
DecisionList(
  decisions: decisions,
  onDecisionSelected: (index) {
    // Handle selection
  },
  isDarkMode: false, // Optional
)
```

Key features:
- Status filtering with chip selection
- Full-text search across ID, title, and content
- Date sorting with ascending/descending toggle
- Clean visual hierarchy with status indicators

### Testing ADR Components

When testing ADR components, note these important considerations:

- Use `findsWidgets` instead of `findsOneWidget` for text and widget assertions
- Test filtering functionality with multiple filter combinations
- Verify selection behavior and proper callback execution
- Test both light and dark mode rendering
- Use the example applications for manual testing

## WebView Integration Best Practices

When integrating WebView components for rendering content like AsciiDoc:

1. **JavaScript Communication**:
   - Use JavaScript channels for bidirectional communication
   - Create clear message formats for different event types
   - Handle errors and timeouts gracefully

2. **Performance Optimization**:
   - Implement progressive rendering for large documents
   - Use chunking to break down processing of large content
   - Implement caching with size limits to prevent memory issues
   - Track performance metrics to identify bottlenecks

3. **Offline Support**:
   - Bundle JavaScript libraries in assets directory
   - Implement fallback mechanism for online/offline modes
   - Provide clear error messages when offline content isn't available

4. **Testing WebView Components**:
   - Create mock implementations of WebViewPlatform for testing
   - Simulate JavaScript events and responses in tests
   - Test error handling and recovery paths
   - Focus on widget structure rather than actual rendering in tests

## Keyboard Navigation Guidelines

When implementing keyboard navigation for UI components:

1. **Consistent Shortcuts**:
   - Use standard patterns (arrow keys for navigation, etc.)
   - Group related shortcuts logically (Ctrl for view switching, Alt for history)
   - Provide a help dialog showing available shortcuts

2. **Implementation Approach**:
   - Use KeyboardListener widget to capture key events
   - Handle modifier keys (Ctrl, Alt, Shift) properly
   - Provide visual feedback when shortcuts are activated

3. **Testing Keyboard Navigation**:
   - Use sendKeyEvent in widget tests to simulate keyboard input
   - Test modifier key combinations
   - Verify state changes after key events

## Export Components

The export system includes several components for exporting diagrams and models to various formats.

### DSL Exporter

The `DslExporter` exports workspace models to Structurizr DSL format with comprehensive features:

```dart
DslExporter(
  workspace: workspace,
  options: DslExportOptions(
    indentSize: 2,                  // Optional, defaults to 2
    includeDocumentation: true,     // Optional, defaults to true
    includeDecisions: true,         // Optional, defaults to true
    preserveFormatting: true,       // Optional, defaults to true
    escapeSpecialCharacters: true,  // Optional, defaults to true
  ),
)
```

Key features:
- Complete model-to-DSL transformation with all element types
- Comprehensive documentation export support:
  - Both Markdown and AsciiDoc format preservation
  - Multi-section documents with proper structure
  - Special character escaping for proper rendering
  - Proper indentation and formatting
- Architecture Decision Records (ADR) export:
  - Complete decision metadata (ID, title, status, date)
  - Decision content with proper formatting
  - Decision relationships/links
  - Status preservation
- Style mapping to DSL syntax:
  - Element styling (shape, color, icon, etc.)
  - Relationship styling (thickness, color, dashed, etc.)
  - View-specific styling
- Pretty-printing with configurable indentation
- Batch export support for multiple diagrams
- Integration with workspace documentation model

### ExportDialog

The `ExportDialog` widget provides a comprehensive interface for exporting diagrams with real-time preview:

```dart
ExportDialog.show(
  context: context,
  workspace: workspace,
  viewKey: 'view-key',
  currentView: currentView, // Optional
  title: 'Diagram Title', // Optional
  onExportComplete: (data, extension) {
    // Handle exported data
  },
);
```

Key features:
- Format selection (PNG, SVG, PlantUML, Mermaid, DOT, DSL)
- Format-specific configuration options
- Real-time preview with debounced updates
- Size, scale, and resolution configuration
- Background and transparency options
- Memory-efficient rendering for large diagrams
- Export progress indication
- File system integration for saving exports

### Batch Export Dialog

The `BatchExportDialog` widget enables exporting multiple diagrams at once:

```dart
BatchExportDialog.show(
  context: context,
  workspace: workspace,
  onExportComplete: (success, failedExports) {
    // Handle export completion
  },
);
```

Key features:
- View selection with category organization
- Select all/deselect all functionality
- Destination folder selection
- Format selection with configuration options
- Progress tracking for multiple exports
- Error handling with detailed reporting

### Export Preview

The export preview functionality provides real-time visual feedback:

1. **Debounced Updates**:
   ```dart
   void _generatePreviewDebounced() {
     _debounceTimer.cancel();
     _debounceTimer = Timer(const Duration(milliseconds: 500), () {
       _generatePreview();
     });
   }
   ```

2. **Format-Specific Previews**:
   - PNG: Direct image display with transparency support
   - SVG: Custom widget for SVG metadata and visualization

3. **SVG Preview Widget**:
   ```dart
   SvgPreviewWidget(
     svgContent: svgString,
     transparentBackground: false, // Optional
   )
   ```
   - Displays SVG dimensions, element count, and file size
   - Extracts and displays SVG metadata
   - Supports transparent background visualization

4. **PNG Preview Widget**:
   ```dart
   PngPreviewWidget(
     imageData: pngBytes,
     transparentBackground: true, // Optional
     width: 1920,
     height: 1080,
   )
   ```
   - Displays image dimensions and file size
   - Supports transparent background visualization
   - Shows aspect ratio with proper scaling

5. **Text Preview Widget**:
   ```dart
   TextPreviewWidget(
     content: "workspace {\n  model {\n    ...\n  }\n}",
     format: "DSL",
   )
   ```
   - Displays formatted code with syntax highlighting
   - Shows content size in characters
   - Scrollable content view for large text outputs

6. **Transparent Background Visualization**:
   ```dart
   CheckerboardBackground(
     squareSize: 10, // Optional, defaults to 10
   )
   ```
   - Implements a checkerboard pattern for visualizing transparency
   - Alternating light gray and white squares
   - Configurable square size for different preview scales

## Command History and Undo/Redo Support

The application provides advanced state management with undo/redo functionality using the Command pattern.

### History Manager

The `HistoryManager` class tracks command history and provides undo/redo functionality:

```dart
// Create a history manager
final historyManager = HistoryManager(maxHistorySize: 50);

// Execute commands with the history manager
historyManager.executeCommand(someCommand);

// Undo and redo operations
historyManager.undo();
historyManager.redo();

// Group operations into transactions
historyManager.beginTransaction();
// ... execute multiple commands
historyManager.commitTransaction('Complex Operation');
```

### Command Types

The following command types are provided:

- `PropertyChangeCommand`: For updating model property values
- `MoveElementCommand`: For moving elements on the diagram
- `AddElementCommand`: For adding elements to the model
- `RemoveElementCommand`: For removing elements from the model
- `AddRelationshipCommand`: For creating relationships between elements
- `RemoveRelationshipCommand`: For removing relationships
- `CompositeCommand`: For grouping multiple commands into a single undoable action

### Integration with UI

The history functionality includes UI components for user interaction:

1. **HistoryToolbar**: Provides undo/redo buttons with tooltips
   ```dart
   HistoryToolbar(
     historyManager: historyManager,
     showLabels: true,  // Optional
     isDarkMode: false, // Optional
   )
   ```

2. **HistoryPanel**: A detailed command history panel
   ```dart
   HistoryPanel(
     historyManager: historyManager,
     isDarkMode: false, // Optional
   )
   ```

3. **Keyboard Shortcuts**: Support for standard shortcuts
   ```dart
   HistoryKeyboardShortcuts(
     historyManager: historyManager,
     child: yourWidget,
   )
   ```
   - Ctrl+Z: Undo
   - Ctrl+Y or Ctrl+Shift+Z: Redo

### Example Usage

See `/example/history/lib/main.dart` for a complete example of undo/redo functionality.
Run the example with:
```bash
./example/run_history_example.sh
```

## Memories and Guidelines

Always put specification, testing progress, and implementation plan markdown files into the @specs/ directory. DO NOT put them anywhere else.

- Treat custom commands as direct requests from the user
- When implementing new UI components, always provide a full example application
- Fix import conflicts using proper hide directives and appropriate widget replacements
- For complex UI components, create dedicated test files with comprehensive test cases
- When working with the documentation parser, be aware of AST circular dependencies
- Use consistent status color coding across all ADR components
- Implement chip-based filtering for intuitive interaction
- For large document rendering, use chunking and caching
- Always provide keyboard shortcuts for navigation-heavy interfaces
- Create help dialogs for keyboard shortcut reference
- For export preview, use debouncing to prevent excessive updates
- Include a standalone example application for testing complex features
- When testing UI components, be aware of viewport size limitations
- Implement the Command pattern for undo/redo functionality
- Use transactions for grouping multiple operations into a single undoable action
- Provide comprehensive command history UI components
- Include keyboard shortcuts for common operations
- Test all undo/redo operations thoroughly

## Modular Parser Refactor and Method Handoff

The parsing and model-building pipeline is being refactored into modular, interface-driven components (e.g., ModelParser, ViewsParser, RelationshipParser, etc.) to:
- Achieve full parity with the original Java Structurizr DSL implementation
- Enable parallel development and clearer handoff between teams
- Improve maintainability, extensibility, and testability

**Developer Guidance:**
- Use the audit and handoff tables in `specs/dart_structurizr_java_audit.md` and `specs/refactored_method_relationship.md` to understand method interfaces, dependencies, and build order.
- Each table in the handoff file can be assigned to a separate team for parallel implementation. Methods in the same table have call dependencies and should be coordinated.
- Always implement and maintain the defined interfaces. If an interface must change, coordinate with all affected teams and update the tables.
- Use interface-driven development: implement stubs and contracts first, then fill in logic.
- Document any deviations from the Java reference and update the audit table.
- This modular approach is critical for long-term maintainability and for keeping the Dart implementation in sync with Structurizr Java DSL.

## Recent Batch Fixes, Lessons Learned, and Persistent Memory (2024-06)

### Summary of Recent Progress
- Major batch fixes applied to resolve ambiguous imports, type mismatches, and widget layout errors in tests.
- Modular parser refactor is underway; all parser/model/view files now use explicit imports and type aliases to avoid conflicts with Flutter built-ins.
- Widget layout errors in tests (e.g., "RenderBox was not laid out") are best solved by removing top-level Expanded/Flexible or wrapping in SizedBox with explicit constraints.
- All specs, status, and plans are now strictly maintained in the specs/ directory. Do not duplicate in CLAUDE.md.

### Best Practices (2024-06)
- Always use explicit import prefixes or hide directives for Element, Container, View, Border, etc.
- For widget tests, always provide bounded constraints (e.g., wrap in SizedBox) to avoid layout errors.
- When fixing ambiguous imports, prefer importing from the canonical model file and using show/hide as needed.
- For test mocks, ensure return types match the interface exactly (e.g., Model addElement returns Model, not void).
- When updating specs or status, update only the files in specs/ and not in this file.

### Troubleshooting Tips
- If you see a RenderBox layout error in tests, check for unbounded Expanded/Flexible and wrap the widget in a SizedBox.
- For ambiguous import errors, use explicit import prefixes or show/hide directives.
- If a test fails due to missing methods or type mismatches, check for outdated mocks or missing imports.

### Modular Parser Refactor
- All parser, model, and view files should use interface-driven development and explicit imports.
- Refer to specs/dart_structurizr_java_audit.md and specs/refactored_method_relationship.md for up-to-date interfaces and build order.
- Each table in the handoff file can be assigned to a separate team for parallel implementation.
