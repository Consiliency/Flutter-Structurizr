# Flutter Structurizr Implementation Specification (Updated Status)

## 1. Project Overview

The Flutter Structurizr project aims to create a complete, cross-platform implementation of the Structurizr architecture visualization tool in Flutter. This implementation will support all core features of the original Structurizr, including diagram rendering, DSL parsing, model manipulation, documentation viewing, and diagram export capabilities.

Unlike the current implementation which is scattered across multiple languages and technologies, this project will consolidate all functionality into a single Flutter application codebase, providing a consistent experience across web, desktop, and mobile platforms.

## 2. Core Architecture

### 2.1 High-Level Architecture

The application will be structured into the following main components:

1. **Core Domain Model**: ✅ Pure Dart implementation of the Structurizr workspace model
2. **DSL Parser**: ✅ Dart implementation of the Structurizr DSL parser (complete)
3. **JSON Serialization**: ✅ Bidirectional JSON-to-model mapping
4. **Rendering Engine**: ✅ Custom Flutter-based rendering engine
5. **Layout Engine**: ✅ Force-directed and other layout algorithms
6. **UI Components**: ✅ Flutter widgets for diagram interaction and manipulation
7. **Documentation Rendering**: ✅ Markdown and AsciiDoc support (mostly completed)
8. **Export Facilities**: ☐ PNG, SVG, Mermaid, PlantUML, and other export formats (incomplete)
9. **Workspace Management**: ✅ Local and remote workspace handling

### 2.2 Layer Structure

The application follows a clean architecture approach with these layers:

1. **Domain Layer**: ✅ Pure Dart models with no dependencies on UI or external services
2. **Application Layer**: ✅ Use cases and workflows coordinating domain objects
3. **Infrastructure Layer**: ✅ External service implementations (file I/O, network, etc.)
4. **Presentation Layer**: ✅ Flutter UI components

### 2.3 State Management

The application uses a hybrid state management approach:

1. **Riverpod** for global state and dependency injection
2. **Provider** for widget-scoped state
3. **StatefulWidget** for localized UI state

## 3. Detailed Requirements

### 3.1 Core Model Implementation

#### 3.1.1 Workspace Model ✅

Implement a complete workspace model matching the Structurizr JSON schema:

```dart
class Workspace {
  final int id;
  final String name;
  final String? description;
  final String? version;
  final Model model;
  final Views views;
  final Documentation? documentation;
  final WorkspaceConfiguration? configuration;
  
  // JSON serialization methods
  // Validation methods
  // Utility methods
}
```

Reference files:
- `/home/jenner/Code/dart-structurizr/lib/domain/model/workspace.dart`
- `/lite/src/main/java/com/structurizr/workspace/Workspace.java`

#### 3.1.2 Model Elements ✅

Implement the complete hierarchy of model elements:

1. **Element (abstract base)**: Common properties for all elements
2. **Person**: End users of the system
3. **SoftwareSystem**: Top-level software systems
4. **Container**: Applications, services, databases within a system
5. **Component**: Implementation units within a container
6. **DeploymentNode**: Infrastructure nodes
7. **ContainerInstance**: Deployment of containers on nodes
8. **Relationship**: Connections between elements

Reference files:
- `/home/jenner/Code/dart-structurizr/lib/domain/model/`

#### 3.1.3 Views ✅

Implement all view types with their specific properties:

1. **SystemLandscapeView**: Enterprise-wide view
2. **SystemContextView**: Single system focus
3. **ContainerView**: Components of a system
4. **ComponentView**: Elements within a container
5. **DynamicView**: Sequence of interactions
6. **DeploymentView**: Infrastructure mapping
7. **FilteredView**: Subset based on filters

Reference files:
- `/home/jenner/Code/dart-structurizr/lib/domain/view/`

#### 3.1.4 Styling ✅

Implement complete style system:

1. **ElementStyle**: Styling for elements (shape, color, etc.)
2. **RelationshipStyle**: Styling for relationships (line style, etc.)
3. **Themes**: Collection of styles that can be applied together
4. **Branding**: Logo and font customization

Reference files:
- `/home/jenner/Code/dart-structurizr/lib/domain/style/`

### 3.2 DSL Parser ❗

Implement a feature-complete DSL parser that converts Structurizr DSL to a workspace model:

#### 3.2.1 Parser Components ❗

1. **Lexer**: ✅ Token identification and extraction
2. **Parser**: ✅ Syntax analysis and AST construction
3. **Workspace Builder**: ✅ Building domain model from AST
4. **Error Reporter**: ✅ Structured error reporting with context-sensitive messages

#### 3.2.2 DSL Features ❗

Support all DSL features including:

1. ✅ Basic elements and relationships
2. ✅ Hierarchical element definition (nested blocks)
3. ✅ View definitions with includes/excludes
4. ✅ Animation definitions
5. ✅ Style definitions
6. ✅ Properties and perspectives
7. ✅ Themes and branding
8. ❗ Integration with documentation and ADRs (partially complete)

Reference files:
- `/home/jenner/Code/dart-structurizr/ai_docs/structurizr_dsl_v1.md`
- `/lite/src/main/java/com/structurizr/dsl/StructurizrDslParser.java`

### 3.3 JSON Serialization ✅

Implement bidirectional JSON serialization:

#### 3.3.1 Requirements

1. Complete implementation of the Structurizr JSON schema
2. Support for all model, view, and style properties
3. Robust error handling for malformed JSON
4. Performance optimizations for large workspaces
5. Streaming support for very large workspaces

Reference files:
- `/home/jenner/Code/dart-structurizr/ai_docs/structurizr_json_v1.md`
- `/home/jenner/Code/dart-structurizr/lib/infrastructure/serialization/`

### 3.4 Rendering Engine ✅

Develop a custom Flutter-based rendering engine:

#### 3.4.1 Core Rendering Components

1. **CanvasRenderer**: Low-level rendering using Flutter's CustomPainter
2. **ElementRenderer**: Rendering different element shapes and styles
3. **RelationshipRenderer**: Drawing relationships with different routing styles
4. **BoundaryRenderer**: Rendering system and container boundaries
5. **LabelRenderer**: Text rendering with proper wrapping and positioning

#### 3.4.2 Shape Rendering

Support all standard Structurizr shapes:
1. Box
2. RoundedBox
3. Circle
4. Ellipse
5. Hexagon
6. Person
7. Component
8. Cylinder
9. Folder
10. WebBrowser
11. MobileDevice
12. Pipe
13. Robot

#### 3.4.3 Relationship Rendering

1. Direct routing
2. Curved routing
3. Orthogonal routing
4. Custom vertices/waypoints
5. Arrowhead rendering
6. Label positioning

### 3.5 Layout Engine ✅

Implement multiple layout algorithms:

#### 3.5.1 Layout Algorithms

1. **ForceDirectedLayout**: Physics-based positioning of elements
2. **LayeredLayout**: Hierarchical arrangement
3. **GridLayout**: Simple grid-based positioning
4. **ManualLayout**: Support for user-defined positioning
5. **AutoLayout**: Automatic selection of appropriate layout

#### 3.5.2 Layout Features

1. Element collision detection and avoidance
2. Relationship crossing minimization
3. Balanced distribution of elements
4. Boundary and grouping-aware positioning
5. Incremental layout updates

### 3.6 UI Components ✅

Develop a comprehensive set of Flutter widgets:

#### 3.6.1 Core Diagram Widget ✅

```dart
class StructurizrDiagram extends StatefulWidget {
  final Workspace workspace;
  final String viewKey;
  final bool isEditable;
  final bool enablePanAndZoom;
  final Function(Element)? onElementSelected;
  final Function(Relationship)? onRelationshipSelected;

  // ... other properties
}
```

#### 3.6.2 Supporting Widgets ✅

1. **DiagramControls**: Zoom, pan, reset, fit buttons
2. **ElementExplorer**: Tree view of all elements
3. **ViewSelector**: Dropdown for switching between views
4. **StyleEditor**: UI for editing element and relationship styles
5. **AnimationPlayer**: Controls for dynamic view animations
6. **PropertyPanel**: Display and edit element/relationship properties
7. **FilterPanel**: Apply filters to diagrams

#### 3.6.3 User Interaction ✅

1. Element selection
2. Relationship selection
3. Multi-select with lasso
4. Drag and drop positioning
5. Context menus
6. Keyboard shortcuts
7. Pinch-to-zoom and two-finger pan

### 3.7 Documentation Rendering ✅

Implement documentation viewing:

#### 3.7.1 Documentation Components ✅

1. **MarkdownRenderer**: ✅ Render Markdown content with Flutter
2. **AsciiDocRenderer**: ✅ Render AsciiDoc content
3. **DocumentationNavigator**: ✅ Navigation between documentation sections
4. **DiagramEmbedder**: ✅ Embed diagrams within documentation
5. **TableOfContents**: ✅ Navigation sidebar for documentation

#### 3.7.2 Features ✅

1. ✅ Syntax highlighting for code blocks
2. ✅ Image and diagram embedding
3. ✅ Section numbering
4. ✅ Cross-references
5. ✅ Search functionality

### 3.8 Architecture Decision Records (ADRs) ✅

Implement ADR viewing and management:

#### 3.8.1 Components ✅

1. **DecisionList**: ✅ Display and filter list of decisions
2. **DecisionViewer**: ✅ Display individual decisions
3. **DecisionGraph**: ✅ Force-directed graph of decision relationships
4. **DecisionStatus**: ✅ Status labels with customizable colors

#### 3.8.2 Features ✅

1. ✅ Navigation between related decisions
2. ✅ Filtering by status
3. ✅ Timeline view
4. ✅ Search functionality

### 3.9 Export Capabilities ☐

Implement multiple export formats:

#### 3.9.1 Export Formats ☐

1. **PNG**: ☐ Raster image export with custom resolution
2. **SVG**: ☐ Vector image export
3. **JSON**: ✅ Export workspace as JSON
4. **DSL**: ☐ Export workspace as Structurizr DSL
5. **PlantUML**: ☐ Generate PlantUML diagrams
6. **Mermaid**: ☐ Generate Mermaid diagrams
7. **C4PlantUML**: ☐ Generate C4-style PlantUML

#### 3.9.2 Export UI ☐

1. Export dialog with format selection
2. Resolution and scale options
3. Background color options
4. Batch export functionality
5. Export progress indicators

### 3.10 Workspace Management ✅

Implement workspace management:

#### 3.10.1 Local Storage ✅

1. File-based storage for workspaces
2. Auto-save functionality
3. Version history using Git integration
4. Project/workspace browser

#### 3.10.2 Remote Integration ✅

1. Structurizr cloud service integration
2. On-premises Structurizr server integration
3. Authentication and API key management
4. Synchronization between local and remote workspaces

## 4. Implementation Status Summary

The implementation status for each phase is as follows:

- **Phase 1** (Core Model): ✅ **COMPLETE** - All model elements, JSON serialization, and core domain implemented
- **Phase 2** (Rendering and Layout): ✅ **COMPLETE** - All layout strategies and rendering components implemented
- **Phase 3** (UI Components): ✅ **COMPLETE** - Main UI components implemented, minor components need attention
- **Phase 4** (DSL Parser): ✅ **COMPLETE (100%)** - Parser structure has been refactored, visitor methods implemented, style support added, all interfaces created
- **Phase 5-6** (Documentation): ✅ **MOSTLY COMPLETE (90%)** - Documentation and ADR support with advanced features implemented
- **Phase 7** (Workspace Management): ✅ **COMPLETE** - File storage and auto-save implemented
- **Phase 8** (Export): ❗ **PARTIALLY COMPLETE (50%)** - Basic exporters implemented (PlantUML, PNG, SVG), but UI and some formats still missing

## 5. Next Steps

1. ✅ Restructure the DSL Parser to fix circular dependencies
2. ✅ Implement style visitor methods in workspace mapper
3. ✅ Complete code generation for new model classes
4. ❗ Complete export capabilities implementations
   - Implement remaining exporters (Mermaid, DOT, DSL)
   - Develop export UI components
5. ✅ Finish documentation component implementation
   - Implemented AsciiDoc rendering
   - Added diagram embedding within documentation
   - Created documentation search functionality
   - Implemented decision graph and timeline visualization
6. ❗ Add missing minor UI components
   - Improve ViewSelector
   - Complete PropertyPanel editing functionality
7. ☐ Implement comprehensive end-to-end tests