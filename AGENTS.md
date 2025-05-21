# AGENTS.md - Flutter Structurizr for AI Agents

This document provides essential information for AI agents (like Codex) working with the Dart Structurizr codebase. It's specifically structured to help agents understand the repository organization, setup process, and development workflow in an offline environment.

## Development Environment Setup

### Offline Setup for Codex

The repository includes a complete Flutter SDK and all dependencies for offline development in Codex:

```bash
# Run this first when starting a new Codex session
./codex_offline_setup_split.sh
```

This script will:
1. Reassemble split archive files from `.codex/` directory
2. Extract the complete Flutter SDK (704MB) and package cache (387MB)
3. Configure the environment for offline operation
4. Create wrappers for `flutter` and `dart` commands

### Important: Use the Wrapper Commands

After setup, always use the wrapper commands to ensure offline operation:

```bash
# Use these wrapper commands
./flutter [command]  # Flutter commands
./dart [command]     # Dart commands

# Examples
./flutter pub get
./flutter test
./flutter analyze
./dart analyze
```

### Troubleshooting Offline Setup

If you encounter issues with the offline setup:

```bash
# Check if setup completed successfully
test -f .codex_setup_complete && echo "Setup complete" || echo "Setup incomplete"

# Manually extract from archives if needed
cd .codex
cat flutter-sdk.tar.gz.part.* > flutter-sdk.tar.gz
tar -xzf flutter-sdk.tar.gz
cat pub-cache.tar.gz.part.* > pub-cache.tar.gz
tar -xzf pub-cache.tar.gz
```

## Project Structure

### Key Directories

```
lib/
  ├── domain/              # Pure Dart domain models
  │   ├── model/           # Core model elements (Person, SoftwareSystem, etc.)
  │   ├── view/            # View definitions (SystemContextView, etc.)
  │   ├── parser/          # DSL parser components (being refactored)
  │   ├── documentation/   # Documentation model
  │   └── style/           # Styling system
  ├── application/         # Use cases and business logic
  │   ├── workspace/       # Workspace management
  │   ├── dsl/             # DSL parsing
  │   └── command/         # Command pattern for undo/redo
  ├── infrastructure/      # External integrations
  │   ├── serialization/   # JSON serialization
  │   ├── persistence/     # File storage
  │   └── export/          # Export facilities
  ├── presentation/        # Flutter UI components
  │   ├── widgets/         # Reusable widgets
  │   ├── pages/           # Application pages
  │   ├── rendering/       # Canvas rendering
  │   └── layout/          # Layout algorithms

test/                      # Test suite
  ├── domain/              # Domain model tests
  ├── application/         # Application layer tests
  ├── infrastructure/      # Infrastructure tests
  ├── presentation/        # UI component tests
  └── integration/         # End-to-end tests

example/                   # Example applications
  └── lib/                 # Various example implementations
```

### Important Files

- `pubspec.yaml`: Package definition and dependencies
- `analysis_options.yaml`: Linting rules
- `lib/main.dart`: Application entry point
- `CLAUDE.md`: Developer memory and best practices (for AI/developers only)
- `specs/`: Implementation specifications and status
- `.codex/`: Offline cache for Flutter SDK and dependencies

## Testing Instructions

### Running Tests

```bash
# Run all tests
./flutter test

# Run a specific test file
./flutter test test/domain/model/workspace_test.dart

# Run tests with a specific tag/name
./flutter test --name="Workspace should load from json"
```

### Test Structure

- Unit tests for models are in `test/domain/`
- Widget tests for UI components are in `test/presentation/widgets/`
- Integration tests are in `test/integration/`
- Golden tests (pixel-perfect UI testing) are in `test/golden/`

### Writing New Tests

When writing new tests, follow these patterns:

1. Match existing test structure in the corresponding directory
2. For model tests, use factory methods from test helpers
3. For widget tests, always provide bounded context:
   ```dart
   testWidgets('Widget renders correctly', (WidgetTester tester) async {
     await tester.pumpWidget(
       MaterialApp(
         home: SizedBox(  // Bounded context
           width: 400,
           height: 600,
           child: YourWidget(),
         ),
       ),
     );
   });
   ```

4. For mock implementations, ensure they match the interface exactly
5. Run tests frequently to catch regressions

## Running the Application

```bash
# Run the main application
./flutter run -d linux    # Linux
./flutter run -d macos    # macOS
./flutter run -d windows  # Windows
./flutter run -d chrome   # Web

# Run specific example
cd example
./flutter run -d linux

# Run the decision graph example
./run_decision_graph_example.sh

# Run the element explorer example
./run_element_explorer_example.sh
```

## Code Style Guidelines

### Import Conflict Resolution

Flutter's widgets conflict with our domain model classes (Container, Element, View, Border). Always handle these conflicts through explicit import hiding:

```dart
// For Element conflicts
import 'package:flutter/material.dart' hide Element;
import 'package:flutter_structurizr/domain/model/element.dart';

// For Container conflicts
import 'package:flutter/material.dart' hide Container;
import 'package:flutter_structurizr/domain/model/container.dart';

// For multiple conflicts
import 'package:flutter/material.dart' hide Element, Container, View, Border;
```

### Widget Best Practices

1. Always provide bounded constraints for UI components
2. Handle text overflow with `TextOverflow.ellipsis`
3. Use `SingleChildScrollView` for long content
4. Use `Expanded` for flexible sizing within Row/Column
5. Prefer Material components over basic Container widgets

### Error Handling

- Use structured error collectors for parser and model validation
- Implement context-sensitive error messages
- Add robust error handling for file I/O operations

### Performance Optimization

- Use chunking for large document rendering
- Implement progressive loading for large diagrams
- Use debouncing for expensive UI updates (like export preview)

## PR Instructions

When preparing a PR, follow these steps:

1. Focus on a specific feature, fix, or enhancement
2. Run the complete test suite: `./flutter test`
3. Run static analysis: `./flutter analyze`
4. Format the code: `./flutter format .`
5. Verify functionality on at least one platform (preferably Linux for Codex)
6. Ensure no regressions in existing functionality

### PR Title Format

Use `[component] Brief description` format for PR titles.

Examples:
- `[parser] Fix relationship parsing with empty tags`
- `[ui] Add dark mode toggle to documentation viewer`
- `[export] Improve PNG quality settings`

### PR Description

Include:
1. A summary of changes (1-3 sentences)
2. Test plan describing how you verified the changes
3. Screenshots for UI changes (if applicable)
4. Reference to related issues (if applicable)

## Modular Parser Refactor Note

The DSL parser is being refactored into modular, interface-driven components for maintainability and Java parity. All parser work should:

1. Follow interfaces defined in `specs/dart_structurizr_java_audit.md`
2. Use explicit imports to avoid conflicts with Flutter types
3. Implement interfaces first, then fill in logic
4. Document any deviations from the Java reference

## Best Practices for AI Agents

1. **Type Conflicts**: Always check imports when editing files with Element, Container, or View classes
2. **Widget Testing**: When testing UI components, ensure proper constraints and material parent
3. **Parser Work**: Consult the audit tables in specs/ for method interfaces
4. **Flutter Commands**: Always use `./flutter` wrapper, not the system Flutter
5. **Large Files**: Be cautious with large document rendering - use chunking approaches
6. **Error Handling**: Add robust error handling for file I/O and parsing
7. **Layout Issues**: If you encounter "RenderBox was not laid out" errors, check for unbounded Expanded/Flexible widgets

## Workspace Handling and DSL Parsing

The application provides a comprehensive implementation of Structurizr workspaces with:

1. **Model Elements**: Person, SoftwareSystem, Container, Component, etc.
2. **Views**: SystemContext, Container, Component, Deployment, Dynamic views
3. **Styling**: Element and relationship styling with rich configuration
4. **Documentation**: Markdown and AsciiDoc documentation with sections
5. **ADRs**: Architecture Decision Records with visualization

When working with workspace models, use extension methods for immutable operations:

```dart
// Example of immutable model operation
final updatedWorkspace = workspace.addSoftwareSystem("name", "description");
```

### DSL Parsing

The DSL parser handles Structurizr DSL syntax completely:

```
workspace {
  model {
    user = person "User"
    system = softwareSystem "System" {
      webapp = container "Web Application"
    }
    user -> system "Uses"
  }
  
  views {
    systemContext system "SystemContext" {
      include *
      autoLayout
    }
  }
}
```

When working with the parser, consult the examples in `test/domain/parser/` directory.

## Documentation Support

The application provides comprehensive documentation support with:

1. **Markdown Rendering**: Enhanced rendering with syntax highlighting
2. **AsciiDoc Rendering**: Web-based rendering with offline support
3. **Table of Contents**: Navigation with collapsible hierarchy
4. **Search**: Full-text search with result highlighting
5. **Architecture Decision Records**: Decision visualization with graph and timeline views

## Export Capabilities

The application supports exporting diagrams in multiple formats:

1. **PNG**: With configurable resolution and transparency
2. **SVG**: With styling and metadata
3. **PlantUML**: For C4 model compatibility
4. **Mermaid**: For GitHub and documentation embedding
5. **DOT**: For GraphViz compatibility
6. **DSL**: For Structurizr compatibility
7. **JSON/YAML**: For tool interoperability

## Common Commands for Development

```bash
# Install dependencies
./flutter pub get

# Run code generation
./flutter pub run build_runner build --delete-conflicting-outputs

# Run tests
./flutter test

# Run specific test
./flutter test test/domain/model/workspace_test.dart

# Check code quality
./flutter analyze

# Format code
./flutter format .

# Run the application
./flutter run -d linux
```

Remember, all development operations in the Codex environment should use the wrapper commands (`./flutter` and `./dart`) to ensure offline operation.