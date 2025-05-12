# Flutter Structurizr

A cross-platform implementation of the Structurizr architecture visualization tool in Flutter. This project aims to create a complete, feature-rich application for visualizing software architecture using the C4 model.

## Project Status

✅ **IMPLEMENTATION COMPLETE** ✅

This project is a complete Dart/Flutter implementation of Structurizr, providing a cross-platform solution that consolidates all functionality into a single Flutter application codebase. All planned phases (1-8) have been implemented and thoroughly tested.

See the [Implementation Status](specs/implementation_status.md) for the detailed status of each phase and the [Implementation Specification](specs/flutter_structurizr_implementation_spec_updated.md) for the complete project plan.

## Features

Flutter Structurizr provides a modern alternative to the original Structurizr implementation with these advantages:

- A single, unified codebase for all platforms (web, desktop, mobile)
- Complete feature parity with the original Structurizr
- Improved performance and user experience
- Enhanced visualization capabilities
- Comprehensive export options
- Cross-platform compatibility across Windows, macOS, Linux, Android, iOS, and web

## Core Components

1. **Domain Model**: Pure Dart implementation of the Structurizr workspace model
2. **DSL Parser**: Complete Structurizr DSL parser in Dart
3. **JSON Serialization**: Bidirectional JSON-to-model mapping
4. **Rendering Engine**: Custom Flutter-based rendering engine
5. **Layout Engine**: Force-directed and other layout algorithms
6. **UI Components**: Interactive diagram widgets
7. **Documentation and ADR Rendering**: Advanced documentation with Markdown/AsciiDoc support, embedded diagrams, interactive decision visualization, and search functionality
8. **Export Facilities**: PNG, SVG, Mermaid, PlantUML, and others

## Architecture

The application follows a clean architecture approach with:

- **Domain Layer**: Pure Dart models with no dependencies
- **Application Layer**: Use cases and workflows
- **Infrastructure Layer**: External service implementations
- **Presentation Layer**: Flutter UI components

## Implemented Features

The project is fully implemented with all planned phases complete:

### Core Domain Implementation ✅
- Complete workspace model implementation
- JSON serialization
- Element class hierarchy and relationship model
- Styling system with themes and branding

### Rendering Engine ✅
- Canvas-based rendering system using CustomPainter
- Element and relationship rendering for all shapes
- Multiple layout algorithms (force-directed, grid, manual, automatic)
- Boundary rendering for containment visualization

### User Interface ✅
- StructurizrDiagram widget with pan, zoom, and multi-selection
- Navigation controls and property panels
- Documentation viewer with search functionality
- ViewSelector with dropdown and thumbnail previews
- Drag-and-drop for elements with manual layout

### DSL Parser ✅
- Complete parser implementation with AST construction
- Comprehensive reference resolution system
- Enhanced error reporting and diagnostics
- Support for all Structurizr DSL features

### Documentation and ADR Support ✅
- Markdown rendering with syntax highlighting
- AsciiDoc rendering using WebView and Asciidoctor.js
- Diagram embedding in documentation
- Decision graph and timeline visualization
- Documentation search with result highlighting

### Workspace Management and Export ✅
- File-based storage with auto-save and versioning
- Export to multiple formats:
  - PNG and SVG for images
  - PlantUML, Mermaid, and DOT/Graphviz for text-based diagrams
  - DSL export for Structurizr compatibility
- Cross-platform support for all major platforms

## Installation

### Prerequisites
- For development: Flutter SDK 3.10.0 or higher
- For running pre-built binaries: None required

### Option 1: Download Pre-built Binaries
1. Go to the [Releases](https://github.com/yourusername/flutter-structurizr/releases) page
2. Download the appropriate binary for your platform:
   - Windows: `flutter_structurizr_windows.zip`
   - macOS: `flutter_structurizr_macos.dmg`
   - Linux: `flutter_structurizr_linux.tar.gz`
   - Android: `flutter_structurizr.apk`
   - iOS: Available on the App Store

### Option 2: Build from Source
1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/flutter-structurizr.git
   cd flutter-structurizr
   ```

2. Set up the environment:
   ```bash
   source .flutter-env/setup.sh
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Generate necessary code:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

5. Run the application:
   ```bash
   flutter run -d [device]
   ```
   Replace `[device]` with your target device/platform (chrome, windows, linux, macos, etc.)

6. Build for production:
   ```bash
   # For Windows
   flutter build windows

   # For macOS
   flutter build macos

   # For Linux
   flutter build linux

   # For Web
   flutter build web

   # For Android
   flutter build apk

   # For iOS
   flutter build ios
   ```

## Usage

### Opening and Creating Workspaces

1. **Launch the application** - Upon first launch, you'll see the Workspace Manager
2. **Create a new workspace:**
   - Click "New Workspace"
   - Enter a name and description
   - Choose between starting from scratch, using a template, or importing from DSL/JSON

3. **Open an existing workspace:**
   - Click "Open Workspace"
   - Select a workspace file (.json or .dsl)

### Creating Architecture Models

1. **Add elements to your model:**
   - Use the Element Explorer sidebar to add people, systems, containers, and components
   - Configure properties using the Property Panel

2. **Create relationships:**
   - Select the source element, then Ctrl+click on the destination element
   - Use the Property Panel to configure the relationship

3. **Create views:**
   - Use the View Selector to create various diagram types
   - Choose from System Context, Container, Component, and Deployment views

### Using Advanced Features

1. **Documentation:**
   - Navigate to the Documentation tab
   - Create and edit documentation in Markdown or AsciiDoc
   - Embed diagrams using the syntax: `![Title](embed:diagram-key)`

2. **Decision Records (ADRs):**
   - Create architecture decision records
   - Visualize decision relationships using the Decision Graph
   - Filter decisions using the Timeline view

3. **Export:**
   - Click the Export button in the toolbar
   - Choose from various formats: PNG, SVG, PlantUML, Mermaid, etc.
   - Configure export settings and save to your desired location

## Contributing

Contributions are welcome! See the [Implementation Specification](specs/flutter_structurizr_implementation_spec_updated.md) for details on the project architecture and design decisions. For the current state of the project, check the [Implementation Status](specs/implementation_status.md).

## Reference Materials

This project includes reference implementations from the original Structurizr:

- `/ui`: Original JavaScript UI implementation
- `/lite`: Structurizr Lite Java implementation
- `/json`: JSON schema definition
- `/ai_docs`: Documentation about Structurizr formats and components

## License

This project is licensed under the MIT License - see the LICENSE file for details.