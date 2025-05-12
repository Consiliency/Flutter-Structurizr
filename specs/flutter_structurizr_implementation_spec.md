# Flutter Structurizr Implementation Specification

## 1. Project Overview

The Flutter Structurizr project aims to create a complete, cross-platform implementation of the Structurizr architecture visualization tool in Flutter. This implementation will support all core features of the original Structurizr, including diagram rendering, DSL parsing, model manipulation, documentation viewing, and diagram export capabilities.

Unlike the current implementation which is scattered across multiple languages and technologies, this project will consolidate all functionality into a single Flutter application codebase, providing a consistent experience across web, desktop, and mobile platforms.

## 2. Core Architecture

### 2.1 High-Level Architecture

The application will be structured into the following main components:

1. **Core Domain Model**: Pure Dart implementation of the Structurizr workspace model
2. **DSL Parser**: Dart implementation of the Structurizr DSL parser
3. **JSON Serialization**: Bidirectional JSON-to-model mapping
4. **Rendering Engine**: Custom Flutter-based rendering engine
5. **Layout Engine**: Force-directed and other layout algorithms
6. **UI Components**: Flutter widgets for diagram interaction and manipulation
7. **Documentation Rendering**: Markdown and AsciiDoc support
8. **Export Facilities**: PNG, SVG, Mermaid, PlantUML, and other export formats
9. **Workspace Management**: Local and remote workspace handling

### 2.2 Layer Structure

The application will follow a clean architecture approach with these layers:

1. **Domain Layer**: Pure Dart models with no dependencies on UI or external services
2. **Application Layer**: Use cases and workflows coordinating domain objects
3. **Infrastructure Layer**: External service implementations (file I/O, network, etc.)
4. **Presentation Layer**: Flutter UI components

### 2.3 State Management

The application will use a hybrid state management approach:

1. **Riverpod** for global state and dependency injection
2. **Provider** for widget-scoped state
3. **StatefulWidget** for localized UI state

## 3. Detailed Requirements

### 3.1 Core Model Implementation

#### 3.1.1 Workspace Model

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
- `/home/jenner/Code/dart-structurizr/lib/src/core/workspace.dart`
- `/lite/src/main/java/com/structurizr/workspace/Workspace.java`

#### 3.1.2 Model Elements

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
- `/home/jenner/Code/dart-structurizr/lib/src/core/model/`
- `/home/jenner/Code/dart-structurizr/lite/src/main/java/com/structurizr/model/`

#### 3.1.3 Views

Implement all view types with their specific properties:

1. **SystemLandscapeView**: Enterprise-wide view
2. **SystemContextView**: Single system focus
3. **ContainerView**: Components of a system
4. **ComponentView**: Elements within a container
5. **DynamicView**: Sequence of interactions
6. **DeploymentView**: Infrastructure mapping
7. **FilteredView**: Subset based on filters

Reference files:
- `/home/jenner/Code/dart-structurizr/lib/src/core/view/`
- `/home/jenner/Code/dart-structurizr/ui/src/js/structurizr-diagram.js`

#### 3.1.4 Styling

Implement complete style system:

1. **ElementStyle**: Styling for elements (shape, color, etc.)
2. **RelationshipStyle**: Styling for relationships (line style, etc.)
3. **Themes**: Collection of styles that can be applied together
4. **Branding**: Logo and font customization

Reference files:
- `/home/jenner/Code/dart-structurizr/lib/src/core/view/styles.dart`
- `/home/jenner/Code/dart-structurizr/ui/src/js/structurizr-ui.js`

### 3.2 DSL Parser

Implement a feature-complete DSL parser that converts Structurizr DSL to a workspace model:

#### 3.2.1 Parser Components

1. **Lexer**: Token identification and extraction
2. **Parser**: Syntax analysis and AST construction
3. **Workspace Builder**: Building domain model from AST
4. **Error Reporter**: Structured error reporting

#### 3.2.2 DSL Features

Support all DSL features including:

1. Basic elements and relationships
2. Hierarchical element definition (nested blocks)
3. View definitions with includes/excludes
4. Animation definitions
5. Style definitions
6. Properties and perspectives
7. Themes and branding
8. Integration with documentation and ADRs

Reference files:
- `/home/jenner/Code/dart-structurizr/ai_docs/structurizr_dsl_v1.md`
- `/lite/src/main/java/com/structurizr/dsl/StructurizrDslParser.java`

### 3.3 JSON Serialization

Implement bidirectional JSON serialization:

#### 3.3.1 Requirements

1. Complete implementation of the Structurizr JSON schema
2. Support for all model, view, and style properties
3. Robust error handling for malformed JSON
4. Performance optimizations for large workspaces
5. Streaming support for very large workspaces

Reference files:
- `/home/jenner/Code/dart-structurizr/ai_docs/structurizr_json_v1.md`
- `/home/jenner/Code/dart-structurizr/lib/src/core/*.g.dart`

### 3.4 Rendering Engine

Develop a custom Flutter-based rendering engine:

#### 3.4.1 Core Rendering Components

1. **CanvasRenderer**: Low-level rendering using Flutter's CustomPainter
2. **ElementRenderer**: Rendering different element shapes and styles
3. **RelationshipRenderer**: Drawing relationships with different routing styles
4. **BoundaryRenderer**: Rendering system and container boundaries
5. **LabelRenderer**: Text rendering with proper wrapping and positioning

```dart
/// Main CustomPainter class for rendering diagrams
class StructurizrDiagramPainter extends CustomPainter {
  final View view;
  final Workspace workspace;
  final String? selectedElementId;
  final Function(String)? onElementTap;
  final int currentAnimationStep;

  const StructurizrDiagramPainter({
    required this.view,
    required this.workspace,
    this.selectedElementId,
    this.onElementTap,
    this.currentAnimationStep = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Get elements and relationships from the model
    final List<Element> elements = _getElements();
    final Map<String, ElementStyle> styles = _getElementStyles();

    // Calculate layout using force-directed algorithm
    final Map<String, Rect> elementBounds = _calculateElementBounds(elements, size);

    // Extract relationship data
    final List<RelationshipView> relationships = _getRelationships();

    // Rendering order is important:
    // 1. First render boundaries (containers/groups)
    _renderBoundaries(canvas, _identifyBoundaryGroups(elements), elementBounds);

    // 2. Then render relationships (connections between elements)
    _renderRelationships(canvas, relationships, elementBounds);

    // 3. Finally render the elements themselves (on top)
    _renderElements(canvas, elements, styles, elementBounds);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  // Implement hit testing for interactive elements
  @override
  bool? hitTest(Offset position) {
    // Check if position intersects with any element
    // Return true if hit, false otherwise
  }
}
```

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

```dart
/// Renders elements with different shapes based on their type
void _renderBox(Canvas canvas, Rect bounds, Color backgroundColor, Color borderColor, double borderWidth) {
  // Draw the box background
  canvas.drawRect(
    bounds,
    Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill,
  );

  // Draw the box border
  canvas.drawRect(
    bounds,
    Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth,
  );
}

/// Renders a person shape (stick figure)
void _renderPerson(Canvas canvas, Rect bounds, Color backgroundColor, Color borderColor, double borderWidth) {
  // Draw the person shape (a circle for the head and a body)
  final headRadius = bounds.width * 0.15;
  final headCenter = Offset(
    bounds.center.dx,
    bounds.top + bounds.height * 0.2,
  );

  // Draw the head
  canvas.drawCircle(
    headCenter,
    headRadius,
    Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill,
  );

  // Draw the body outline with a path
  final bodyPath = Path()
    ..moveTo(bounds.center.dx, headCenter.dy + headRadius)
    ..lineTo(bounds.center.dx, bounds.center.dy + bounds.height * 0.15)
    ..lineTo(bounds.left + bounds.width * 0.3, bounds.bottom - bounds.height * 0.1)
    ..moveTo(bounds.center.dx, bounds.center.dy + bounds.height * 0.15)
    ..lineTo(bounds.right - bounds.width * 0.3, bounds.bottom - bounds.height * 0.1)
    ..moveTo(bounds.left + bounds.width * 0.25, bounds.center.dy)
    ..lineTo(bounds.right - bounds.width * 0.25, bounds.center.dy);

  canvas.drawPath(
    bodyPath,
    Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth,
  );
}
```

#### 3.4.3 Relationship Rendering

1. Direct routing
2. Curved routing
3. Orthogonal routing
4. Custom vertices/waypoints
5. Arrowhead rendering
6. Label positioning

```dart
/// Renders different types of relationships between elements
class RelationshipRenderer {
  final Relationship relationship;
  final Offset start;
  final Offset end;
  final List<Vertex>? vertices;
  final String? description;

  void render(Canvas canvas) {
    // Calculate the path for the relationship
    final path = _calculatePath();

    // Draw the relationship line
    _drawLine(canvas, path);

    // Draw the arrow at the end
    _drawArrow(canvas, path);

    // Draw the description text
    if (description != null && description!.isNotEmpty) {
      _drawDescription(canvas, path);
    }
  }

  /// Calculate a curved path between elements
  Path _calculateCurvedPath() {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    // If there are vertices, draw curves through them
    if (vertices != null && vertices!.isNotEmpty) {
      // Add cubic bezier curves through provided vertices
    } else {
      // Create a simple curved line
      final midX = (start.dx + end.dx) / 2;
      final midY = (start.dy + end.dy) / 2;
      final controlDist = (end - start).distance * 0.2;

      // Calculate perpendicular offset for control points
      final dx = end.dx - start.dx;
      final dy = end.dy - start.dy;
      final perpendicular = _normalizeOffset(Offset(-dy, dx));

      // Create the curved path
      path.cubicTo(
        start.dx + (end.dx - start.dx) / 3 + perpendicular.dx * controlDist,
        start.dy + (end.dy - start.dy) / 3 + perpendicular.dy * controlDist,
        start.dx + 2 * (end.dx - start.dx) / 3 + perpendicular.dx * controlDist,
        start.dy + 2 * (end.dy - start.dy) / 3 + perpendicular.dy * controlDist,
        end.dx,
        end.dy,
      );
    }

    return path;
  }
}
```

Reference files:
- `/home/jenner/Code/dart-structurizr/ui/src/js/structurizr-diagram.js` (lines 1-800)
- `/home/jenner/Code/dart-structurizr/lib/src/rendering/canvas/` 

### 3.5 Layout Engine

Implement multiple layout algorithms:

#### 3.5.1 Layout Algorithms

1. **ForceDirectedLayout**: Physics-based positioning of elements
2. **LayeredLayout**: Hierarchical arrangement
3. **GridLayout**: Simple grid-based positioning
4. **ManualLayout**: Support for user-defined positioning
5. **AutoLayout**: Automatic selection of appropriate layout

```dart
/// Force-directed layout for positioning diagram elements
class ForceDirectedLayout {
  final double springConstant;
  final double repulsiveConstant;
  final double dampingFactor;
  final int maxIterations;

  Map<String, Rect> layout(
    List<Element> elements,
    List<RelationshipView> relationships,
    Size canvasSize,
  ) {
    // Initialize element positions randomly
    final positions = <String, Offset>{};
    final velocities = <String, Offset>{};
    final forces = <String, Offset>{};

    // Initialize random positions
    for (final element in elements) {
      final x = random.nextDouble() * (canvasSize.width * 0.8) + (canvasSize.width * 0.1);
      final y = random.nextDouble() * (canvasSize.height * 0.8) + (canvasSize.height * 0.1);
      positions[element.id] = Offset(x, y);
      velocities[element.id] = Offset.zero;
    }

    // Run the layout algorithm
    double totalEnergy = double.infinity;
    int iterations = 0;

    while (totalEnergy > energyThreshold && iterations < maxIterations) {
      // Reset forces
      for (final element in elements) {
        forces[element.id] = Offset.zero;
      }

      // Calculate repulsive forces between all pairs of elements
      for (int i = 0; i < elements.length; i++) {
        final element1 = elements[i];
        final pos1 = positions[element1.id]!;

        for (int j = i + 1; j < elements.length; j++) {
          final element2 = elements[j];
          final pos2 = positions[element2.id]!;

          final delta = pos1 - pos2;
          final distance = max(delta.distance, 1.0);

          // Repulsive force inversely proportional to distance squared
          final force = delta * (repulsiveConstant / (distance * distance));

          forces[element1.id] = forces[element1.id]! + force;
          forces[element2.id] = forces[element2.id]! - force;
        }
      }

      // Calculate spring forces for relationships
      for (final relationship in relationships) {
        final sourceId = relationship.sourceId;
        final targetId = relationship.destinationId;

        if (positions.containsKey(sourceId) && positions.containsKey(targetId)) {
          final sourcePos = positions[sourceId]!;
          final targetPos = positions[targetId]!;

          final delta = sourcePos - targetPos;
          final distance = max(delta.distance, 1.0);

          // Spring force proportional to distance
          final force = delta * (-springConstant * distance);

          forces[sourceId] = forces[sourceId]! + force;
          forces[targetId] = forces[targetId]! - force;
        }
      }

      // Update positions and velocities
      totalEnergy = 0.0;
      for (final element in elements) {
        final force = forces[element.id]!;

        // Apply damping to velocity
        velocities[element.id] = velocities[element.id]! * dampingFactor + force * (1 - dampingFactor);

        // Update position
        positions[element.id] = positions[element.id]! + velocities[element.id]!;

        // Calculate energy (velocity magnitude)
        totalEnergy += velocities[element.id]!.distanceSquared;
      }

      iterations++;
    }

    // Convert positions to element bounds
    return _positionsToBounds(positions, elements);
  }
}
```

#### 3.5.2 Layout Features

1. Element collision detection and avoidance
2. Relationship crossing minimization
3. Balanced distribution of elements
4. Boundary and grouping-aware positioning
5. Incremental layout updates

Reference files:
- `/home/jenner/Code/dart-structurizr/lib/src/rendering/layout/`
- `/home/jenner/Code/dart-structurizr/ui/src/js/structurizr-diagram.js` (layout section)

### 3.6 UI Components

Develop a comprehensive set of Flutter widgets:

#### 3.6.1 Core Diagram Widget

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

#### 3.6.2 Supporting Widgets

1. **DiagramControls**: Zoom, pan, reset, fit buttons

```dart
class DiagramControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onResetView;
  final VoidCallback onFitToScreen;
  final bool isVertical;

  const DiagramControls({
    Key? key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onResetView,
    required this.onFitToScreen,
    this.isVertical = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final controls = [
      FloatingActionButton.small(
        onPressed: onZoomIn,
        tooltip: "Zoom In",
        child: const Icon(Icons.add),
      ),
      const SizedBox(height: 8, width: 8),
      FloatingActionButton.small(
        onPressed: onZoomOut,
        tooltip: "Zoom Out",
        child: const Icon(Icons.remove),
      ),
      const SizedBox(height: 8, width: 8),
      FloatingActionButton.small(
        onPressed: onResetView,
        tooltip: "Reset View",
        child: const Icon(Icons.refresh),
      ),
      const SizedBox(height: 8, width: 8),
      FloatingActionButton.small(
        onPressed: onFitToScreen,
        tooltip: "Fit to Screen",
        child: const Icon(Icons.fit_screen),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 5.0,
          ),
        ],
      ),
      child: isVertical
          ? Column(mainAxisSize: MainAxisSize.min, children: controls)
          : Row(mainAxisSize: MainAxisSize.min, children: controls),
    );
  }
}
```

2. **ElementExplorer**: Tree view of all elements
3. **ViewSelector**: Dropdown for switching between views
4. **StyleEditor**: UI for editing element and relationship styles
5. **AnimationPlayer**: Controls for dynamic view animations

```dart
class AnimationPlayer extends StatefulWidget {
  final int totalSteps;
  final int currentStep;
  final Function(int) onStepChanged;
  final bool autoPlay;
  final Duration stepDuration;

  const AnimationPlayer({
    Key? key,
    required this.totalSteps,
    required this.currentStep,
    required this.onStepChanged,
    this.autoPlay = false,
    this.stepDuration = const Duration(seconds: 2),
  }) : super(key: key);

  @override
  State<AnimationPlayer> createState() => _AnimationPlayerState();
}

class _AnimationPlayerState extends State<AnimationPlayer> {
  late Timer? _timer;
  late bool _isPlaying;

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.autoPlay;
    _timer = null;

    if (_isPlaying) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(widget.stepDuration, (timer) {
      final nextStep = (widget.currentStep + 1) % (widget.totalSteps + 1);
      widget.onStepChanged(nextStep);

      // Stop at the end if not looping
      if (nextStep == widget.totalSteps) {
        _stopTimer();
      }
    });
  }

  void _stopTimer() {
    setState(() {
      _timer?.cancel();
      _timer = null;
      _isPlaying = false;
    });
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _startTimer();
      } else {
        _stopTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 5.0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.skip_previous),
            onPressed: () => widget.onStepChanged(0),
            tooltip: 'First Step',
          ),
          IconButton(
            icon: Icon(Icons.navigate_before),
            onPressed: widget.currentStep > 0
                ? () => widget.onStepChanged(widget.currentStep - 1)
                : null,
            tooltip: 'Previous Step',
          ),
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: _togglePlayPause,
            tooltip: _isPlaying ? 'Pause' : 'Play',
          ),
          IconButton(
            icon: Icon(Icons.navigate_next),
            onPressed: widget.currentStep < widget.totalSteps
                ? () => widget.onStepChanged(widget.currentStep + 1)
                : null,
            tooltip: 'Next Step',
          ),
          IconButton(
            icon: Icon(Icons.skip_next),
            onPressed: () => widget.onStepChanged(widget.totalSteps),
            tooltip: 'Last Step',
          ),
          SizedBox(width: 16),
          Text('${widget.currentStep} / ${widget.totalSteps}'),
        ],
      ),
    );
  }
}
```

6. **PropertyPanel**: Display and edit element/relationship properties
7. **FilterPanel**: Apply filters to diagrams

#### 3.6.3 User Interaction

1. Element selection
2. Relationship selection
3. Multi-select with lasso

```dart
class DiagramSelectionManager {
  // Currently selected elements and relationships
  Set<String> selectedElementIds = {};
  Set<String> selectedRelationshipIds = {};

  // Track lasso selection
  Offset? lassoStart;
  Offset? lassoCurrent;
  bool isLassoActive = false;

  // Listeners for selection changes
  final List<Function()> _listeners = [];

  // Start lasso selection at the given point
  void startLasso(Offset position) {
    lassoStart = position;
    lassoCurrent = position;
    isLassoActive = true;
    _notifyListeners();
  }

  // Update the lasso selection
  void updateLasso(Offset position) {
    if (!isLassoActive) return;
    lassoCurrent = position;
    _notifyListeners();
  }

  // Complete lasso selection and select elements within the lasso area
  void completeLasso(Map<String, Rect> elementBounds, {bool addToSelection = false}) {
    if (!isLassoActive || lassoStart == null || lassoCurrent == null) return;

    // Calculate lasso rectangle
    final lassoRect = Rect.fromPoints(lassoStart!, lassoCurrent!);

    // Find elements inside the lasso
    final elementsInLasso = <String>{};
    for (final entry in elementBounds.entries) {
      if (lassoRect.overlaps(entry.value)) {
        elementsInLasso.add(entry.key);
      }
    }

    // Update selection
    if (addToSelection) {
      selectedElementIds.addAll(elementsInLasso);
    } else {
      selectedElementIds = elementsInLasso;
    }

    // Reset lasso state
    isLassoActive = false;
    lassoStart = null;
    lassoCurrent = null;

    _notifyListeners();
  }

  // Cancel lasso selection
  void cancelLasso() {
    isLassoActive = false;
    lassoStart = null;
    lassoCurrent = null;
    _notifyListeners();
  }

  // Draw the lasso on the canvas
  void drawLasso(Canvas canvas) {
    if (!isLassoActive || lassoStart == null || lassoCurrent == null) return;

    final lassoRect = Rect.fromPoints(lassoStart!, lassoCurrent!);

    // Draw semi-transparent fill
    canvas.drawRect(
      lassoRect,
      Paint()
        ..color = Colors.blue.withOpacity(0.1)
        ..style = PaintingStyle.fill,
    );

    // Draw dashed border
    final dashedPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw dashed rectangle (simplified for clarity)
    canvas.drawRect(lassoRect, dashedPaint);
  }

  // Add a listener for selection changes
  void addListener(Function() listener) {
    _listeners.add(listener);
  }

  // Remove a listener
  void removeListener(Function() listener) {
    _listeners.remove(listener);
  }

  // Notify all listeners of changes
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }
}
```

4. Drag and drop positioning
5. Context menus
6. Keyboard shortcuts
7. Pinch-to-zoom and two-finger pan

Reference files:
- `/home/jenner/Code/dart-structurizr/lib/widgets/structurizr_diagram.dart`
- `/home/jenner/Code/dart-structurizr/ui/src/js/structurizr-ui.js`

### 3.7 Documentation Rendering

Implement documentation viewing:

#### 3.7.1 Documentation Components

1. **MarkdownRenderer**: Render Markdown content with Flutter
2. **AsciiDocRenderer**: Render AsciiDoc content
3. **DocumentationNavigator**: Navigation between documentation sections
4. **DiagramEmbedder**: Embed diagrams within documentation
5. **TableOfContents**: Navigation sidebar for documentation

#### 3.7.2 Features

1. Syntax highlighting for code blocks
2. Image and diagram embedding
3. Section numbering
4. Cross-references
5. Search functionality

Reference files:
- `/home/jenner/Code/dart-structurizr/lite/src/main/java/com/structurizr/lite/web/DocumentationController.java`
- `/home/jenner/Code/dart-structurizr/ui/src/js/structurizr-documentation.js`

### 3.8 Architecture Decision Records (ADRs)

Implement ADR viewing and management:

#### 3.8.1 Components

1. **DecisionList**: Display and filter list of decisions
2. **DecisionViewer**: Display individual decisions
3. **DecisionGraph**: Force-directed graph of decision relationships
4. **DecisionStatus**: Status labels with customizable colors

#### 3.8.2 Features

1. Navigation between related decisions
2. Filtering by status
3. Timeline view
4. Search functionality

Reference files:
- `/home/jenner/Code/dart-structurizr/lite/src/main/java/com/structurizr/lite/web/DecisionsController.java`
- `/home/jenner/Code/dart-structurizr/ui/src/js/structurizr-decisions.js`

### 3.9 Export Capabilities

Implement multiple export formats:

#### 3.9.1 Export Formats

1. **PNG**: Raster image export with custom resolution
2. **SVG**: Vector image export
3. **JSON**: Export workspace as JSON
4. **DSL**: Export workspace as Structurizr DSL
5. **PlantUML**: Generate PlantUML diagrams
6. **Mermaid**: Generate Mermaid diagrams
7. **C4PlantUML**: Generate C4-style PlantUML

#### 3.9.2 Export UI

1. Export dialog with format selection
2. Resolution and scale options
3. Background color options
4. Batch export functionality
5. Export progress indicators

Reference files:
- `/home/jenner/Code/dart-structurizr/lib/src/export/`
- `/home/jenner/Code/dart-structurizr/ui/src/js/structurizr-diagram.js` (export section)

### 3.10 Workspace Management

Implement workspace management:

#### 3.10.1 Local Storage

1. File-based storage for workspaces
2. Auto-save functionality
3. Version history using Git integration
4. Project/workspace browser

#### 3.10.2 Remote Integration

1. Structurizr cloud service integration
2. On-premises Structurizr server integration
3. Authentication and API key management
4. Synchronization between local and remote workspaces

Reference files:
- `/home/jenner/Code/dart-structurizr/lite/src/main/java/com/structurizr/lite/component/workspace/`
- `/home/jenner/Code/dart-structurizr/ui/src/js/structurizr-client.js`

## 4. Technical Architecture

### 4.1 Package Structure

```
lib/
  ├── domain/                 # Domain models
  │   ├── core/               # Core model
  │   │   ├── models/         # Model classes
  │   │   └── tests/          # Model unit tests
  │   ├── parser/             # DSL parser
  │   │   ├── ast/            # Abstract syntax tree
  │   │   ├── lexer/          # Lexical analysis
  │   │   └── tests/          # Parser unit tests
  │   └── export/             # Export definitions
  │       ├── formats/        # Export format implementations
  │       └── tests/          # Export unit tests
  ├── application/            # Use cases
  │   ├── workspace/          # Workspace operations
  │   │   └── tests/          # Workspace operations tests
  │   ├── render/             # Rendering logic
  │   │   └── tests/          # Rendering tests
  │   └── layout/             # Layout algorithms
  │       └── tests/          # Layout algorithm tests
  ├── infrastructure/         # External services
  │   ├── persistence/        # Storage implementations
  │   │   └── tests/          # Storage tests
  │   ├── remote/             # API clients
  │   │   └── tests/          # API client tests
  │   └── export/             # Export implementations
  │       └── tests/          # Export implementation tests
  ├── presentation/           # UI components
  │   ├── widgets/            # Reusable widgets
  │   │   └── tests/          # Widget tests
  │   ├── screens/            # Full screens
  │   │   └── tests/          # Screen tests
  │   ├── theme/              # App theming
  │   │   └── tests/          # Theme tests
  │   └── state/              # UI state management
  │       └── tests/          # State management tests
  ├── utils/                  # Utility helpers
  │   └── tests/              # Utility tests
  └── tests/                  # Integration tests
      ├── fixtures/           # Test fixtures
      ├── e2e/                # End-to-end tests
      └── performance/        # Performance tests
```

### 4.2 Key Dependencies

1. **Flutter**: Core UI framework
2. **Riverpod**: State management and dependency injection
3. **freezed**: Immutable models with code generation
4. **json_serializable**: JSON serialization
5. **path_provider**: File system access
6. **petitparser**: Parser combinator for DSL parsing
7. **vector_math**: Vector operations for layout
8. **flutter_markdown**: Markdown rendering
9. **http**: HTTP client for remote API
10. **fl_chart**: Interactive charts
11. **uuid**: Unique ID generation
12. **archive**: ZIP handling for exports
13. **shared_preferences**: Settings storage
14. **file_picker**: File selection dialogs

### 4.3 Performance Considerations

1. **Lazy loading**: Defer loading large sections of the workspace
2. **Canvas optimization**: Clip invisible elements during rendering
3. **Caching**: Cache rendered elements and relationships
4. **Incremental layout**: Only recalculate positions for modified elements
5. **Background processing**: Perform intensive operations in isolates

## 5. Implementation Tasks and Testing

### 5.1 Phase 1: Core Implementation

#### Core Model Implementation

| Task | Implementation Files | Test Files | Testing Strategy |
|------|---------------------|------------|------------------|
| ~~Develop base Element class hierarchy~~ | ~~`lib/domain/model/element.dart`~~ | ~~`test/domain/model/element_test.dart`~~ | ~~Unit test property getters, setters, equals, hashCode~~ |
| ~~Implement Workspace and Model classes~~ | ~~`lib/domain/model/workspace.dart`<br>`lib/domain/model/model.dart`~~ | ~~`test/domain/model/workspace_test.dart`<br>`test/domain/model/model_test.dart`~~ | ~~Unit test workspace creation, model relationships, and validation~~ |
| ~~Create styling system~~ | ~~`lib/domain/style/styles.dart`~~ | ~~`test/domain/style/styles_test.dart`~~ | ~~Unit test style application and inheritance~~ |
| ~~Implement JSON serialization~~ | ~~`lib/infrastructure/serialization/json_serialization.dart`~~ | ~~`test/infrastructure/serialization/json_serialization_test.dart`~~ | ~~Unit test JSON serialization/deserialization roundtrip~~ |
| ~~Create view implementation~~ | ~~`lib/domain/view/view.dart`~~ | ~~`test/domain/view/view_test.dart`~~ | ~~Unit test view creation, element addition/removal~~ |

**AI Assistant Prompt for Element Class Implementation:**
```
Create the base Element class for a Structurizr implementation in Dart. The Element class should be abstract and serve as the foundation for all architectural elements (Person, SoftwareSystem, Container, Component, etc.).

Requirements:
1. Implement core properties: id, name, description, tags, properties, relationships
2. Add methods for relationship management (addRelationship, getRelationships)
3. Implement proper equality comparison based on ID
4. Make the class immutable using freezed annotations
5. Support JSON serialization/deserialization

Please implement the Element class and generate a comprehensive unit test file that tests all functionality including property access, relationship management, equality, and JSON serialization/deserialization. Focus on making the code clean, well-documented, and following Dart best practices.

Once complete, explain how you would approach testing this class and what edge cases should be considered.
```

**AI Assistant Prompt for Workspace Model Test:**
```
Create a comprehensive test suite for the Structurizr Workspace model in Dart. The Workspace class is the root object that contains the entire architecture model, views, and configuration.

Requirements:
1. Test Workspace object creation with valid parameters
2. Test JSON serialization and deserialization
3. Test adding and retrieving elements from the model
4. Test view creation and management
5. Test validation rules (element ID uniqueness, etc.)
6. Test error handling for invalid inputs
7. Include fixtures with sample workspaces of varying complexity

Please create detailed unit tests that cover all edge cases and provide good test coverage. Use mock objects where appropriate, and include tests for expected failure scenarios. Demonstrate how you would structure the tests for readability and maintainability.
```

#### JSON Serialization

| Task | Implementation Files | Test Files | Testing Strategy |
|------|---------------------|------------|------------------|
| ~~Define JSON schema~~ | ~~`lib/domain/model/*.freezed.dart`<br>`lib/domain/model/*.g.dart`~~ | ~~Integration with tests~~ | ~~Validate schema against official specification~~ |
| ~~Create serialization adapters~~ | ~~`lib/infrastructure/serialization/json_serialization.dart`~~ | ~~`test/infrastructure/serialization/json_serialization_test.dart`~~ | ~~Unit test adapters with edge cases~~ |
| ~~Implement error handling~~ | ~~`lib/infrastructure/serialization/json_serialization.dart`<br>(JsonParsingException)~~ | ~~`test/infrastructure/serialization/json_serialization_test.dart`~~ | ~~Test error scenarios with malformed JSON~~ |
| Optimize for performance | `lib/domain/core/json/optimization.dart` | `lib/domain/core/tests/json_performance_test.dart` | Benchmark serialization performance |

**AI Assistant Prompt for JSON Serialization:**
```
Implement the JSON serialization layer for a Structurizr workspace in Dart. The solution should support bidirectional conversion between the domain models and JSON, with proper error handling and performance optimization.

Requirements:
1. Create serialization/deserialization for all model classes (Workspace, Model, Element, Views, etc.)
2. Handle nested objects and lists properly
3. Implement error handling for malformed JSON
4. Add support for custom property serialization
5. Optimize for performance with large workspaces

Please create the serialization layer along with comprehensive unit tests. The tests should cover:
- Successful serialization and deserialization
- Handling of optional fields
- Proper error messages for malformed JSON
- Edge cases (empty collections, null values, etc.)
- Performance testing with large workspaces

Additionally, explain how you'd approach testing this functionality in a real-world scenario.
```

### 5.2 Phase 2: Rendering and Layout

#### Rendering Engine

| Task | Implementation Files | Test Files | Testing Strategy |
|------|---------------------|------------|------------------|
| ~~Implement CustomPainter~~ | `lib/presentation/rendering/base_renderer.dart` | `test/presentation/rendering/base_renderer_test.dart` | Widget test with golden image comparison |
| ~~Create element renderers~~ | `lib/presentation/rendering/elements/` | `test/presentation/rendering/elements/` | Unit test individual shape rendering |
| ~~Implement relationship rendering~~ | `lib/presentation/rendering/relationships/relationship_renderer.dart` | `test/presentation/rendering/relationships/relationship_renderer_test.dart` | Test line styles, routing, and arrowheads |
| ~~Add boundary rendering~~ | `lib/presentation/rendering/boundaries/boundary_renderer.dart` | `test/presentation/rendering/boundaries/boundary_renderer_test.dart` | Test boundary containment and styling |

Example of testing the element renderers with a custom mock canvas:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:structurizr/domain/core/models/element.dart';
import 'package:structurizr/domain/core/models/style.dart';
import 'package:structurizr/presentation/widgets/diagram/renderers/box_renderer.dart';

// Custom MockCanvas implementation for testing drawing operations
class MockCanvas extends Fake implements Canvas {
  final List<Rect> drawnRects = [];
  final List<RRect> drawnRRects = [];
  final List<Path> drawnPaths = [];
  final List<Paint> paints = [];
  final Map<String, List<Offset>> textPositions = {};

  @override
  void drawRect(Rect rect, Paint paint) {
    drawnRects.add(rect);
    paints.add(paint);
  }

  @override
  void drawRRect(RRect rrect, Paint paint) {
    drawnRRects.add(rrect);
    paints.add(paint);
  }

  @override
  void drawPath(Path path, Paint paint) {
    drawnPaths.add(path);
    paints.add(paint);
  }

  // Simplified implementation for testing
  @override
  void drawParagraph(Paragraph paragraph, Offset offset) {
    final text = paragraph.toString();
    textPositions.putIfAbsent(text, () => []).add(offset);
  }

  bool hasDrawnBoxWithColor(Color color, {bool fill = true}) {
    for (int i = 0; i < paints.length; i++) {
      if (paints[i].color == color &&
          paints[i].style == (fill ? PaintingStyle.fill : PaintingStyle.stroke) &&
          (drawnRects.isNotEmpty || drawnRRects.isNotEmpty)) {
        return true;
      }
    }
    return false;
  }

  bool hasDrawnText(String textFragment) {
    return textPositions.keys.any((text) => text.contains(textFragment));
  }
}

void main() {
  group('BoxRenderer tests', () {
    late MockCanvas mockCanvas;
    late BoxRenderer renderer;
    late TestElement element;
    late ElementStyle style;

    setUp(() {
      mockCanvas = MockCanvas();
      element = TestElement(
        id: 'test',
        name: 'Test Element',
        description: 'Test description',
      );

      style = ElementStyle(
        background: '#1168BD',
        color: '#FFFFFF',
        fontSize: 14,
        border: '#000000',
        strokeWidth: 1,
        shape: 'Box',
      );

      renderer = BoxRenderer(
        element: element,
        style: style,
      );
    });

    test('Renders box with correct colors', () {
      final bounds = Rect.fromLTWH(0, 0, 120, 80);

      renderer.render(mockCanvas, bounds);

      // Verify background color
      expect(
        mockCanvas.hasDrawnBoxWithColor(Color(0xFF1168BD), fill: true),
        isTrue,
        reason: 'Background color not rendered correctly',
      );

      // Verify border color
      expect(
        mockCanvas.hasDrawnBoxWithColor(Color(0xFF000000), fill: false),
        isTrue,
        reason: 'Border color not rendered correctly',
      );
    });

    test('Renders text content correctly', () {
      final bounds = Rect.fromLTWH(0, 0, 120, 80);

      renderer.render(mockCanvas, bounds);

      // Verify element name is rendered
      expect(
        mockCanvas.hasDrawnText('Test Element'),
        isTrue,
        reason: 'Element name not rendered',
      );

      // Verify description is rendered
      expect(
        mockCanvas.hasDrawnText('Test description'),
        isTrue,
        reason: 'Element description not rendered',
      );
    });

    test('Renders rounded corners when shape is RoundedBox', () {
      // Update style to use RoundedBox
      style = ElementStyle(
        background: '#1168BD',
        color: '#FFFFFF',
        fontSize: 14,
        border: '#000000',
        strokeWidth: 1,
        shape: 'RoundedBox',
        borderRadius: 10,
      );

      renderer = BoxRenderer(
        element: element,
        style: style,
      );

      final bounds = Rect.fromLTWH(0, 0, 120, 80);
      renderer.render(mockCanvas, bounds);

      // Verify rounded rectangles were drawn
      expect(mockCanvas.drawnRRects.isNotEmpty, isTrue);
      expect(mockCanvas.drawnRRects.first.tlRadius.x, equals(10));
    });

    test('Renders selection indicator when selected', () {
      renderer = BoxRenderer(
        element: element,
        style: style,
        isSelected: true,
      );

      final bounds = Rect.fromLTWH(0, 0, 120, 80);
      renderer.render(mockCanvas, bounds);

      // Verify selection indicator (blue border) is drawn
      expect(
        mockCanvas.hasDrawnBoxWithColor(Colors.blue, fill: false),
        isTrue,
        reason: 'Selection indicator not rendered',
      );
    });
  });
}

// Test implementation for the abstract Element class
class TestElement extends Element {
  TestElement({
    required String id,
    required String name,
    String? description,
    List<String>? tags,
  }) : super(
    id: id,
    name: name,
    description: description,
    tags: tags,
  );
}
```

Example of testing with golden images for the diagram painter:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:structurizr/domain/core/models/element.dart';
import 'package:structurizr/domain/core/models/person.dart';
import 'package:structurizr/domain/core/models/software_system.dart';
import 'package:structurizr/domain/core/models/workspace.dart';
import 'package:structurizr/domain/core/models/view/system_context_view.dart';
import 'package:structurizr/presentation/widgets/diagram/diagram_painter.dart';

void main() {
  // Set up test workspace
  late Workspace workspace;
  late SystemContextView view;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Create test workspace
    workspace = Workspace(
      name: 'Banking System',
      description: 'Sample banking system for tests',
    );

    // Add elements to the model
    final customer = Person(
      id: 'customer',
      name: 'Customer',
      description: 'A customer of the bank',
    );

    final bankingSystem = SoftwareSystem(
      id: 'banking-system',
      name: 'Internet Banking System',
      description: 'Allows customers to view accounts and make payments',
    );

    workspace.model.addElement(customer);
    workspace.model.addElement(bankingSystem);

    // Add relationship
    final relationship = Relationship(
      id: 'rel1',
      sourceId: customer.id,
      destinationId: bankingSystem.id,
      description: 'Uses',
    );
    customer.addRelationship(relationship);

    // Create view
    view = SystemContextView(
      key: 'banking-context',
      softwareSystemId: bankingSystem.id,
      description: 'System context for the banking system',
    );

    // Add elements to view
    view.addAllElements();

    // Add view to workspace
    workspace.views.addView(view);
  });

  testWidgets('StructurizrDiagramPainter renders system context correctly', (WidgetTester tester) async {
    // Create widget with RepaintBoundary for capturing
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RepaintBoundary(
            child: CustomPaint(
              painter: StructurizrDiagramPainter(
                view: view,
                workspace: workspace,
              ),
              size: Size(800, 600),
            ),
          ),
        ),
      ),
    );

    // Let the layout settle
    await tester.pumpAndSettle();

    // Capture the rendered output
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('goldens/system_context_diagram.png'),
    );
  });

  testWidgets('StructurizrDiagramPainter shows selection correctly', (WidgetTester tester) async {
    // Create widget with selection
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RepaintBoundary(
            child: CustomPaint(
              painter: StructurizrDiagramPainter(
                view: view,
                workspace: workspace,
                selectedElementId: 'customer',
              ),
              size: Size(800, 600),
            ),
          ),
        ),
      ),
    );

    // Let the layout settle
    await tester.pumpAndSettle();

    // Capture the rendered output
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('goldens/system_context_diagram_selected.png'),
    );
  });
}
```

**AI Assistant Prompt for Box Shape Renderer:**
```
Implement a Box shape renderer for the Structurizr diagram system in Flutter. The box is a fundamental shape in the C4 model and needs to be rendered with various styles.

Requirements:
1. Create a BoxRenderer class that extends a base ElementRenderer
2. Support the following style properties:
   - Width and height
   - Background color
   - Border color and thickness
   - Border style (solid, dashed, dotted)
   - Rounded corners (optional)
   - Text rendering for name and description
   - Icon placement (if provided)
3. Implement proper text wrapping within the box bounds
4. Add support for selection highlighting
5. Include hit testing for interaction

Please implement the BoxRenderer class and a comprehensive test suite. The tests should cover:
- Rendering with different style combinations
- Text wrapping with different lengths of text
- Selection state rendering
- Hit testing accuracy

Here's an example implementation of the BoxRenderer class:

```dart
class BoxRenderer extends ElementRenderer {
  final Element element;
  final ElementStyle style;
  final bool isSelected;

  BoxRenderer({
    required this.element,
    required this.style,
    this.isSelected = false,
  });

  @override
  void render(Canvas canvas, Rect bounds) {
    // Draw background
    final backgroundColor = _parseColor(style.background) ?? Colors.white;
    final borderColor = _parseColor(style.border) ?? Colors.black;
    final borderWidth = style.strokeWidth ?? 1.0;

    if (style.shape == 'RoundedBox') {
      _renderRoundedBox(
        canvas,
        bounds,
        backgroundColor,
        borderColor,
        borderWidth,
        style.borderRadius ?? 10.0,
      );
    } else {
      _renderBox(
        canvas,
        bounds,
        backgroundColor,
        borderColor,
        borderWidth,
      );
    }

    // Draw text content
    _renderText(canvas, bounds);

    // Draw selection indicator if selected
    if (isSelected) {
      _renderSelectionIndicator(canvas, bounds);
    }
  }

  void _renderBox(Canvas canvas, Rect bounds, Color backgroundColor,
                 Color borderColor, double borderWidth) {
    canvas.drawRect(
      bounds,
      Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.fill,
    );

    canvas.drawRect(
      bounds,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );
  }

  void _renderRoundedBox(Canvas canvas, Rect bounds, Color backgroundColor,
                        Color borderColor, double borderWidth, double radius) {
    final boxRect = RRect.fromRectAndRadius(
      bounds,
      Radius.circular(radius),
    );

    canvas.drawRRect(
      boxRect,
      Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.fill,
    );

    canvas.drawRRect(
      boxRect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );
  }

  void _renderText(Canvas canvas, Rect bounds) {
    final textBounds = Rect.fromLTRB(
      bounds.left + style.padding,
      bounds.top + style.padding,
      bounds.right - style.padding,
      bounds.bottom - style.padding,
    );

    // Draw name (larger, bold)
    final nameTextPainter = TextPainter(
      text: TextSpan(
        text: element.name,
        style: TextStyle(
          color: _parseColor(style.color) ?? Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: style.fontSize ?? 14.0,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    nameTextPainter.layout(maxWidth: textBounds.width);
    nameTextPainter.paint(
      canvas,
      Offset(
        textBounds.left + (textBounds.width - nameTextPainter.width) / 2,
        textBounds.top,
      ),
    );

    // Draw description if present (smaller)
    if (element.description?.isNotEmpty == true) {
      final descriptionTextPainter = TextPainter(
        text: TextSpan(
          text: element.description,
          style: TextStyle(
            color: _parseColor(style.color) ?? Colors.black,
            fontSize: (style.fontSize ?? 14.0) * 0.85,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 3,
        ellipsis: '...',
      );

      descriptionTextPainter.layout(maxWidth: textBounds.width);
      descriptionTextPainter.paint(
        canvas,
        Offset(
          textBounds.left + (textBounds.width - descriptionTextPainter.width) / 2,
          textBounds.top + nameTextPainter.height + 8.0,
        ),
      );
    }
  }

  void _renderSelectionIndicator(Canvas canvas, Rect bounds) {
    final selectionPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final glowPaint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.0);

    final selectionBounds = bounds.inflate(4.0);

    if (style.shape == 'RoundedBox') {
      final roundedRect = RRect.fromRectAndRadius(
        selectionBounds,
        Radius.circular(style.borderRadius ?? 10.0 + 4.0),
      );

      canvas.drawRRect(roundedRect, glowPaint);
      canvas.drawRRect(roundedRect, selectionPaint);
    } else {
      canvas.drawRect(selectionBounds, glowPaint);
      canvas.drawRect(selectionBounds, selectionPaint);
    }
  }

  @override
  bool hitTest(Offset position, Rect bounds) {
    return bounds.contains(position);
  }

  Color? _parseColor(String? colorString) {
    if (colorString == null) return null;
    if (colorString.startsWith('#')) {
      final value = int.tryParse('0xFF${colorString.substring(1)}');
      if (value != null) return Color(value);
    }
    return null;
  }
}
```

Include example code showing how to use this renderer within a CustomPainter.
```

#### Layout Algorithms

| Task | Implementation Files | Test Files | Testing Strategy |
|------|---------------------|------------|------------------|
| ~~Implement force-directed layout~~ | `lib/presentation/layout/force_directed_layout.dart` | `test/presentation/layout/force_directed_layout_test.dart` | Unit test with fixed input, verify expected positions |
| ~~Create grid layout~~ | `lib/presentation/layout/grid_layout.dart` | `test/presentation/layout/grid_layout_test.dart` | Verify grid placement and spacing |
| ~~Implement manual layout~~ | `lib/presentation/layout/manual_layout.dart` | `test/presentation/layout/manual_layout_test.dart` | Test manual position persistence |
| ~~Add automatic layout~~ | `lib/presentation/layout/automatic_layout.dart` | `test/presentation/layout/automatic_layout_test.dart` | Test selection of appropriate layout strategy |
| ~~Add collision detection~~ | Integrated in `force_directed_layout.dart` | `test/presentation/layout/force_directed_layout_test.dart` | Test with overlapping elements, verify separation |

**AI Assistant Prompt for Force-Directed Layout:**
```
Implement a force-directed layout algorithm for positioning elements in a Structurizr diagram using Flutter. The layout should arrange elements based on their relationships while avoiding overlaps.

Requirements:
1. Create a ForceDirectedLayout class that takes elements and relationships as input
2. Implement physics simulation with:
   - Repulsive forces between elements to avoid overlap
   - Spring forces for relationships to keep connected elements close
   - Damping to reach equilibrium
3. Support configuration options (spring strength, repulsion strength, etc.)
4. Include boundary constraints to keep elements within the viewport
5. Optimize performance for large diagrams (50+ elements)

Please implement the layout algorithm and a comprehensive test suite. The tests should cover:
- Basic layout scenarios (2-3 elements with relationships)
- Complex layouts (10+ elements with multiple relationships)
- Boundary handling
- Performance testing with larger diagrams
- Stability (consistent results with same input)

Include example code showing how to use this layout with the diagram rendering system.
```dart
// Example layout usage code would be here
```

### 5.3 Phase 3: UI Components and Interaction

#### UI Components

| Task | Implementation Files | Test Files | Testing Strategy |
|------|---------------------|------------|------------------|
| <del>Implement StructurizrDiagram widget</del> | `lib/presentation/widgets/diagram/structurizr_diagram.dart` | `test/presentation/widgets/structurizr_diagram_test.dart` | Widget test for rendering and basic interaction |
| <del>Create DiagramControls</del> | `lib/presentation/widgets/diagram_controls.dart` | `test/presentation/widgets/diagram_controls_test.dart` | Widget test for control functionality |
| <del>Implement ElementExplorer</del> | `lib/presentation/widgets/element_explorer.dart` | `test/presentation/widgets/element_explorer_test.dart` | Widget test for tree view and selection |
| <del>Create AnimationPlayer</del> | `lib/presentation/widgets/diagram/animation_controls.dart` | `test/presentation/widgets/animation_player_test.dart` | Widget test for animation functionality |

**AI Assistant Prompt for Diagram Widget:**
```
Implement the core StructurizrDiagram widget for a Flutter implementation of Structurizr. This widget will be responsible for rendering and interacting with architecture diagrams.

Requirements:
1. Create a StructurizrDiagram StatefulWidget that takes:
   - A Workspace object
   - A viewKey to identify which view to display
   - Interaction options (pan/zoom enabled, element selection, etc.)
2. Implement rendering using CustomPainter
3. Support user interactions:
   - Pan and zoom
   - Element selection
   - Element highlighting on hover
4. Add callbacks for element selection and other events
5. Support dark mode and theming

Here's an example implementation of the StructurizrDiagram widget:

```dart
class StructurizrDiagram extends StatefulWidget {
  final Workspace workspace;
  final String viewKey;
  final bool enablePanAndZoom;
  final bool showControls;
  final double minScale;
  final double maxScale;
  final Function(String)? onElementSelected;
  final Function(String)? onRelationshipSelected;
  final ThemeMode themeMode;

  const StructurizrDiagram({
    Key? key,
    required this.workspace,
    required this.viewKey,
    this.enablePanAndZoom = true,
    this.showControls = true,
    this.minScale = 0.25,
    this.maxScale = 4.0,
    this.onElementSelected,
    this.onRelationshipSelected,
    this.themeMode = ThemeMode.light,
  }) : super(key: key);

  @override
  State<StructurizrDiagram> createState() => StructurizrDiagramState();
}

class StructurizrDiagramState extends State<StructurizrDiagram> {
  String? _selectedElementId;
  final TransformationController _transformationController = TransformationController();
  late View _view;
  late List<Element> _elements;
  late List<RelationshipView> _relationships;
  late Map<String, ElementStyle> _elementStyles;
  int _currentAnimationStep = 0;

  @override
  void initState() {
    super.initState();
    _initView();
  }

  void _initView() {
    // Get the view from workspace using the viewKey
    _view = widget.workspace.views.getViewByKey(widget.viewKey);

    // Extract elements and relationships
    _elements = _view.getElements(widget.workspace.model);
    _relationships = _view.getRelationships(widget.workspace.model);

    // Get element styles from view
    _elementStyles = _getElementStyles();
  }

  Map<String, ElementStyle> _getElementStyles() {
    final styles = <String, ElementStyle>{};

    // Get global styles first
    final viewSet = widget.workspace.views;

    // Apply view-specific styles
    for (final element in _elements) {
      styles[element.id] = viewSet.getElementStyle(element, _view);
    }

    return styles;
  }

  void _onTapDown(TapDownDetails details) {
    // Convert the tap position to diagram coordinate space
    final localPosition = context.findRenderObject()!.globalToLocal(details.globalPosition);

    // Transform to account for zoom and pan
    final transformedPosition = _transformPointToLocalSpace(localPosition);

    // Hit test to see if an element was tapped
    final hitElement = _hitTestElements(transformedPosition);

    if (hitElement != null) {
      // Element was tapped - select it
      setState(() {
        _selectedElementId = hitElement.id;
      });

      // Call the selection handler
      widget.onElementSelected?.call(hitElement.id);
    } else {
      // No element was hit - deselect
      if (_selectedElementId != null) {
        setState(() {
          _selectedElementId = null;
        });
        widget.onElementSelected?.call('');
      }
    }
  }

  Element? _hitTestElements(Offset position) {
    // Get layout information from the painter
    final painter = StructurizrDiagramPainter(
      view: _view,
      workspace: widget.workspace,
      selectedElementId: _selectedElementId,
      currentAnimationStep: _currentAnimationStep,
    );

    // Get element bounds using the same layout algorithm as the painter
    final elementBounds = painter.calculateElementBounds(Size.infinite);

    // Check each element to see if position is within its bounds
    for (final element in _elements.reversed) {
      final bounds = elementBounds[element.id];
      if (bounds != null && bounds.contains(position)) {
        return element;
      }
    }

    return null;
  }

  Offset _transformPointToLocalSpace(Offset screenPoint) {
    final matrix = _transformationController.value.clone();
    try {
      matrix.invert();
      final Vector3 transformedPoint = matrix.transform3(Vector3(screenPoint.dx, screenPoint.dy, 0));
      return Offset(transformedPoint.x, transformedPoint.y);
    } catch (e) {
      return screenPoint;
    }
  }

  void _zoomIn() {
    setState(() {
      final newScale = _getScaleFactor() * 1.2;
      if (newScale <= widget.maxScale) {
        _transformationController.value = Matrix4.identity()
          ..scale(newScale, newScale)
          ..setTranslation(_transformationController.value.getTranslation());
      }
    });
  }

  void _zoomOut() {
    setState(() {
      final newScale = _getScaleFactor() / 1.2;
      if (newScale >= widget.minScale) {
        _transformationController.value = Matrix4.identity()
          ..scale(newScale, newScale)
          ..setTranslation(_transformationController.value.getTranslation());
      }
    });
  }

  void _resetView() {
    setState(() {
      _transformationController.value = Matrix4.identity();
    });
  }

  double _getScaleFactor() {
    return _transformationController.value.getMaxScaleOnAxis();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTapDown: widget.enablePanAndZoom ? _onTapDown : null,
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: widget.minScale,
            maxScale: widget.maxScale,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            panEnabled: widget.enablePanAndZoom,
            scaleEnabled: widget.enablePanAndZoom,
            child: CustomPaint(
              painter: StructurizrDiagramPainter(
                view: _view,
                workspace: widget.workspace,
                selectedElementId: _selectedElementId,
                currentAnimationStep: _currentAnimationStep,
                isDarkMode: widget.themeMode == ThemeMode.dark,
              ),
              size: Size.infinite,
            ),
          ),
        ),
        if (widget.showControls) _buildControls(),
      ],
    );
  }

  Widget _buildControls() {
    return Positioned(
      right: 16,
      bottom: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            onPressed: _zoomIn,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            onPressed: _zoomOut,
            child: const Icon(Icons.remove),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            onPressed: _resetView,
            child: const Icon(Icons.fit_screen),
          ),
        ],
      ),
    );
  }
}
```

Please implement a comprehensive test suite. The tests should cover:
- Rendering different view types (SystemContext, Container, etc.)
- User interactions (pan, zoom, selection)
- Callbacks are properly triggered
- Widget reacts correctly to state changes
- Theme changes

Here's an example of how you would test this widget:

```dart
testWidgets('StructurizrDiagram renders SystemContext view correctly', (WidgetTester tester) async {
  // Create test workspace with a system context view
  final workspace = createTestWorkspace();

  // Build the widget in a MaterialApp wrapper
  await tester.pumpWidget(
    MaterialApp(
      home: RepaintBoundary(
        child: StructurizrDiagram(
          workspace: workspace,
          viewKey: 'systemContext',
        ),
      ),
    ),
  );

  // Verify it renders without errors
  expect(find.byType(CustomPaint), findsOneWidget);

  // Verify with golden test
  await expectLater(
    find.byType(RepaintBoundary),
    matchesGoldenFile('goldens/system_context_diagram.png'),
  );
});

testWidgets('StructurizrDiagram handles element selection', (WidgetTester tester) async {
  // Track selection
  String? selectedElementId;

  await tester.pumpWidget(
    MaterialApp(
      home: StructurizrDiagram(
        workspace: testWorkspace,
        viewKey: 'systemContext',
        onElementSelected: (id) {
          selectedElementId = id;
        },
      ),
    ),
  );

  // Simulate tap at element position
  await tester.tapAt(Offset(400, 300)); // Position of element in the view
  await tester.pump();

  // Verify selection callback was triggered with the correct ID
  expect(selectedElementId, equals('system1'));
});
```

Include example code showing how to use this widget in a Flutter application:

```dart
class DiagramViewerScreen extends StatelessWidget {
  final Workspace workspace;

  const DiagramViewerScreen({super.key, required this.workspace});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(workspace.name)),
      body: StructurizrDiagram(
        workspace: workspace,
        viewKey: 'systemContext', // Use your specific view key
        showControls: true,
        enablePanAndZoom: true,
        onElementSelected: (elementId) {
          // Handle element selection, e.g. show details panel
          if (elementId.isNotEmpty) {
            showElementDetails(context, workspace.model.getElement(elementId));
          }
        },
      ),
    );
  }

  void showElementDetails(BuildContext context, Element element) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ElementDetailsPanel(element: element),
    );
  }
}
```

#### User Interaction

| Task | Implementation Files | Test Files | Testing Strategy |
|------|---------------------|------------|------------------|
| <del>Implement element selection</del> | `lib/presentation/widgets/diagram/structurizr_diagram.dart` | `test/presentation/widgets/ui_integration_test.dart` | Widget test selection behavior |
| <del>Add pan and zoom interactions</del> | `lib/presentation/widgets/diagram/structurizr_diagram.dart` | `test/presentation/widgets/ui_integration_test.dart` | Widget test with pan and zoom gestures |
| <del>Implement hover and highlighting</del> | `lib/presentation/widgets/diagram/structurizr_diagram.dart` | `test/presentation/widgets/ui_integration_test.dart` | Widget test with hover events |

**AI Assistant Prompt for Element Selection:**
```
Implement element selection functionality for the Structurizr diagram widget in Flutter. This should handle selecting elements by clicking, multi-selection, and selection persistence.

Requirements:
1. Create an ElementSelectionManager class that:
   - Tracks selected elements
   - Provides methods for selecting/deselecting elements
   - Supports single and multi-selection modes
   - Notifies listeners of selection changes
2. Implement hit testing to determine which element was clicked
3. Support keyboard modifiers (Shift for extending selection, Ctrl for toggling)
4. Add visual feedback for selected elements
5. Implement proper state management using Provider or Riverpod

Please implement the selection functionality and a comprehensive test suite. The tests should cover:
- Single element selection
- Multi-element selection with modifiers
- Deselection
- Selection persistence when diagram is redrawn
- Selection cancellation when clicking empty space

Include example code showing how to integrate this with the StructurizrDiagram widget.
```dart
// Example integration code would be here
```

### 5.4 Phase 4: DSL Parser

#### Parser Components

| Task | Implementation Files | Test Files | Testing Strategy |
|------|---------------------|------------|------------------|
| Implement lexer | `lib/domain/parser/lexer/lexer.dart` | `lib/domain/parser/tests/lexer_test.dart` | Unit test token extraction |
| Create parser | `lib/domain/parser/parser.dart` | `lib/domain/parser/tests/parser_test.dart` | Unit test AST generation |
| Build workspace mapper | `lib/domain/parser/mapper.dart` | `lib/domain/parser/tests/mapper_test.dart` | Unit test conversion to model |

**AI Assistant Prompt for DSL Lexer:**
```
Implement a lexer for the Structurizr DSL parser in Dart. The lexer should tokenize Structurizr DSL text into a stream of tokens that can be consumed by a parser.

Requirements:
1. Create a Lexer class that takes DSL text as input
2. Define token types for all DSL elements (identifiers, keywords, operators, strings, numbers, etc.)
3. Implement token extraction for:
   - Keywords (workspace, model, views, person, softwareSystem, etc.)
   - Identifiers and variables
   - String literals (with proper escaping)
   - Special characters and operators (=, ->, {}, etc.)
   - Comments (both line and block comments)
4. Handle whitespace and newlines appropriately
5. Include proper error reporting for invalid tokens

Here's an example implementation of the Structurizr DSL lexer:

```dart
enum TokenType {
  // Keywords
  workspace,
  model,
  views,
  person,
  softwareSystem,
  container,
  component,
  deploymentEnvironment,
  deploymentNode,
  relationship,
  tags,
  description,
  technology,

  // Literals
  identifier,
  string,
  number,

  // Operators and punctuation
  equals,          // =
  arrow,           // ->
  leftBrace,       // {
  rightBrace,      // }
  leftBracket,     // [
  rightBracket,    // ]
  leftParen,       // (
  rightParen,      // )
  comma,           // ,
  dot,             // .

  // Special
  comment,
  whitespace,
  newline,
  eof,             // End of file
}

class Token {
  final TokenType type;
  final String lexeme;
  final int line;
  final int column;

  Token(this.type, this.lexeme, this.line, this.column);

  @override
  String toString() => '$type: "$lexeme" at $line:$column';
}

class LexerError extends Error {
  final String message;
  final int line;
  final int column;

  LexerError(this.message, this.line, this.column);

  @override
  String toString() => 'Lexer error at $line:$column: $message';
}

class StructurizrLexer {
  final String source;
  final List<Token> tokens = [];

  // Current position in the source
  int _start = 0;
  int _current = 0;
  int _line = 1;
  int _column = 1;

  // Keyword lookup map
  static final Map<String, TokenType> _keywords = {
    'workspace': TokenType.workspace,
    'model': TokenType.model,
    'views': TokenType.views,
    'person': TokenType.person,
    'softwareSystem': TokenType.softwareSystem,
    'container': TokenType.container,
    'component': TokenType.component,
    'deploymentEnvironment': TokenType.deploymentEnvironment,
    'deploymentNode': TokenType.deploymentNode,
    'relationship': TokenType.relationship,
    'tags': TokenType.tags,
    'description': TokenType.description,
    'technology': TokenType.technology,
  };

  StructurizrLexer(this.source);

  List<Token> tokenize() {
    while (!_isAtEnd()) {
      _start = _current;
      _scanToken();
    }

    tokens.add(Token(TokenType.eof, '', _line, _column));
    return tokens;
  }

  void _scanToken() {
    final c = _advance();

    switch (c) {
      // Single-character tokens
      case '=':
        _addToken(TokenType.equals);
        break;
      case '{':
        _addToken(TokenType.leftBrace);
        break;
      case '}':
        _addToken(TokenType.rightBrace);
        break;
      case '[':
        _addToken(TokenType.leftBracket);
        break;
      case ']':
        _addToken(TokenType.rightBracket);
        break;
      case '(':
        _addToken(TokenType.leftParen);
        break;
      case ')':
        _addToken(TokenType.rightParen);
        break;
      case ',':
        _addToken(TokenType.comma);
        break;
      case '.':
        _addToken(TokenType.dot);
        break;

      // Comments
      case '/':
        if (_match('/')) {
          // Line comment - consume until end of line
          while (_peek() != '\n' && !_isAtEnd()) {
            _advance();
          }
          _addToken(TokenType.comment);
        } else if (_match('*')) {
          // Block comment - consume until */
          while (!(_peek() == '*' && _peekNext() == '/') && !_isAtEnd()) {
            if (_peek() == '\n') {
              _line++;
              _column = 1;
            }
            _advance();
          }

          // Consume the closing */
          if (!_isAtEnd()) {
            _advance(); // *
            _advance(); // /
          }

          _addToken(TokenType.comment);
        } else {
          // Just a slash
          _addToken(TokenType.identifier);
        }
        break;

      // Whitespace
      case ' ':
      case '\r':
      case '\t':
        // Ignore whitespace
        break;

      // Newlines
      case '\n':
        _addToken(TokenType.newline);
        _line++;
        _column = 1;
        break;

      // Arrow token "->" for relationships
      case '-':
        if (_match('>')) {
          _addToken(TokenType.arrow);
        } else {
          _identifier(); // Treat as part of an identifier
        }
        break;

      // String literals
      case '"':
        _string();
        break;

      default:
        if (_isDigit(c)) {
          _number();
        } else if (_isAlpha(c)) {
          _identifier();
        } else {
          throw LexerError('Unexpected character: $c', _line, _column - 1);
        }
    }
  }

  void _identifier() {
    while (_isAlphaNumeric(_peek())) {
      _advance();
    }

    // Check if the identifier is a keyword
    final text = source.substring(_start, _current);
    final type = _keywords[text] ?? TokenType.identifier;
    _addToken(type);
  }

  void _string() {
    // Consume the string, allowing for escaped quotes
    while (_peek() != '"' && !_isAtEnd()) {
      if (_peek() == '\n') {
        _line++;
        _column = 1;
      } else if (_peek() == '\\' && _peekNext() == '"') {
        // Handle escaped quote
        _advance(); // Consume the backslash
      }
      _advance();
    }

    // Unterminated string
    if (_isAtEnd()) {
      throw LexerError('Unterminated string', _line, _column);
    }

    // Consume the closing quote
    _advance();

    // Extract string value (without the quotes)
    final value = source.substring(_start + 1, _current - 1);
    _addToken(TokenType.string);
  }

  void _number() {
    while (_isDigit(_peek())) {
      _advance();
    }

    // Look for decimal part
    if (_peek() == '.' && _isDigit(_peekNext())) {
      // Consume the '.'
      _advance();

      // Consume decimal digits
      while (_isDigit(_peek())) {
        _advance();
      }
    }

    _addToken(TokenType.number);
  }

  bool _match(String expected) {
    if (_isAtEnd()) return false;
    if (source[_current] != expected) return false;

    _current++;
    _column++;
    return true;
  }

  String _peek() {
    if (_isAtEnd()) return '\0';
    return source[_current];
  }

  String _peekNext() {
    if (_current + 1 >= source.length) return '\0';
    return source[_current + 1];
  }

  bool _isAlpha(String c) {
    return (c.codeUnitAt(0) >= 'a'.codeUnitAt(0) && c.codeUnitAt(0) <= 'z'.codeUnitAt(0)) ||
           (c.codeUnitAt(0) >= 'A'.codeUnitAt(0) && c.codeUnitAt(0) <= 'Z'.codeUnitAt(0)) ||
           c == '_';
  }

  bool _isDigit(String c) {
    return c.codeUnitAt(0) >= '0'.codeUnitAt(0) && c.codeUnitAt(0) <= '9'.codeUnitAt(0);
  }

  bool _isAlphaNumeric(String c) {
    return _isAlpha(c) || _isDigit(c);
  }

  String _advance() {
    final char = source[_current];
    _current++;
    _column++;
    return char;
  }

  void _addToken(TokenType type) {
    final text = source.substring(_start, _current);
    tokens.add(Token(type, text, _line, _column - text.length));
  }

  bool _isAtEnd() {
    return _current >= source.length;
  }
}
```

Please implement a comprehensive test suite. The tests should cover:
- Basic token extraction
- Complex DSL with nested structures
- Edge cases (escaping, comments, etc.)
- Error scenarios (unterminated strings, invalid characters)
- Performance with large DSL files

Here's an example of tests for the lexer:

```dart
test('Lexer handles basic workspace definition', () {
  final input = '''workspace "Banking System" {
  model {
    customer = person "Customer"
  }
}''';

  final lexer = StructurizrLexer(input);
  final tokens = lexer.tokenize();

  // Filter out whitespace and comments
  final significantTokens = tokens.where(
    (t) => t.type != TokenType.whitespace && t.type != TokenType.comment
  ).toList();

  expect(significantTokens[0].type, equals(TokenType.workspace));
  expect(significantTokens[1].type, equals(TokenType.string));
  expect(significantTokens[1].lexeme, equals('"Banking System"'));
  expect(significantTokens[2].type, equals(TokenType.leftBrace));
  // ... more assertions
});

test('Lexer handles comments correctly', () {
  final input = '''
  // This is a line comment
  workspace "Test" { /* This is a block comment */ }
  ''';

  final lexer = StructurizrLexer(input);
  final tokens = lexer.tokenize();

  // Check if comments are tokenized correctly
  final comments = tokens.where((t) => t.type == TokenType.comment).toList();
  expect(comments.length, equals(2));
  expect(comments[0].lexeme, equals('// This is a line comment'));
  expect(comments[1].lexeme, equals('/* This is a block comment */'));
});

test('Lexer reports errors for unterminated strings', () {
  final input = 'workspace "Unterminated';
  final lexer = StructurizrLexer(input);

  try {
    lexer.tokenize();
    fail('Expected LexerError to be thrown');
  } catch (e) {
    expect(e, isA<LexerError>());
    expect((e as LexerError).message, contains('Unterminated string'));
  }
});

test('Lexer handles complex relationships', () {
  final input = 'customer -> internetBankingSystem "Uses"';
  final lexer = StructurizrLexer(input);
  final tokens = lexer.tokenize();

  final significantTokens = tokens.where(
    (t) => t.type != TokenType.whitespace && t.type != TokenType.comment
  ).toList();

  expect(significantTokens[0].type, equals(TokenType.identifier));
  expect(significantTokens[0].lexeme, equals('customer'));
  expect(significantTokens[1].type, equals(TokenType.arrow));
  expect(significantTokens[2].type, equals(TokenType.identifier));
  expect(significantTokens[3].type, equals(TokenType.string));
});
```

Here's how to use this lexer as part of a complete DSL parser:

```dart
class StructurizrDslParser {
  final StructurizrLexer lexer;
  late List<Token> tokens;
  int current = 0;

  StructurizrDslParser(String source) : lexer = StructurizrLexer(source);

  Workspace parse() {
    tokens = lexer.tokenize();

    // Skip comments and whitespace
    _skipNonSignificantTokens();

    // Parse the workspace
    return _parseWorkspace();
  }

  Workspace _parseWorkspace() {
    // Expect workspace keyword
    _consume(TokenType.workspace, "Expected 'workspace' keyword");

    // Parse workspace name
    final nameToken = _consume(TokenType.string, "Expected workspace name as string");
    String name = nameToken.lexeme;
    name = name.substring(1, name.length - 1); // Remove quotes

    // Parse optional description
    String? description;
    if (_check(TokenType.string)) {
      final descToken = _advance();
      description = descToken.lexeme;
      description = description.substring(1, description.length - 1); // Remove quotes
    }

    // Parse workspace body
    _consume(TokenType.leftBrace, "Expected '{' after workspace name");

    // Create the workspace
    final workspace = Workspace(name: name, description: description);

    // Parse workspace contents (model, views, etc.)
    while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
      if (_check(TokenType.model)) {
        _parseModel(workspace);
      } else if (_check(TokenType.views)) {
        _parseViews(workspace);
      } else {
        // Skip unknown section
        _advance();
        if (_check(TokenType.leftBrace)) {
          _skipBlock();
        }
      }

      _skipNonSignificantTokens();
    }

    // Consume the closing brace
    _consume(TokenType.rightBrace, "Expected '}' after workspace definition");

    return workspace;
  }

  // More parsing methods for model, views, etc...

  void _skipNonSignificantTokens() {
    while (!_isAtEnd()) {
      if (_check(TokenType.whitespace) ||
          _check(TokenType.comment) ||
          _check(TokenType.newline)) {
        _advance();
      } else {
        break;
      }
    }
  }

  void _skipBlock() {
    int depth = 0;
    _consume(TokenType.leftBrace, "Expected '{'");
    depth++;

    while (depth > 0 && !_isAtEnd()) {
      if (_check(TokenType.leftBrace)) {
        depth++;
      } else if (_check(TokenType.rightBrace)) {
        depth--;
      }
      _advance();
    }
  }

  Token _peek() {
    return tokens[current];
  }

  bool _check(TokenType type) {
    if (_isAtEnd()) return false;
    return _peek().type == type;
  }

  Token _advance() {
    if (!_isAtEnd()) current++;
    return tokens[current - 1];
  }

  bool _isAtEnd() {
    return _peek().type == TokenType.eof;
  }

  Token _consume(TokenType type, String errorMessage) {
    if (_check(type)) return _advance();

    final token = _peek();
    throw Exception("$errorMessage at line ${token.line}:${token.column}");
  }
}
```


### 5.5 Phase 5: Documentation and ADRs

#### Documentation Components

| Task | Implementation Files | Test Files | Testing Strategy |
|------|---------------------|------------|------------------|
| Implement MarkdownRenderer | `lib/presentation/widgets/documentation/markdown_renderer.dart` | `lib/presentation/widgets/documentation/tests/markdown_renderer_test.dart` | Widget test with sample markdown |
| Create DocumentationNavigator | `lib/presentation/widgets/documentation/documentation_navigator.dart` | `lib/presentation/widgets/documentation/tests/documentation_navigator_test.dart` | Widget test navigation behavior |

**AI Assistant Prompt for Markdown Renderer:**

Implement a Markdown renderer for the Structurizr documentation system in Flutter. This component will display technical documentation with syntax highlighting and embedded diagrams.

Requirements:
1. Create a MarkdownRenderer widget that:
   - Renders Markdown syntax with proper formatting
   - Supports code blocks with syntax highlighting
   - Handles embedded diagrams using special syntax
   - Supports images and links
2. Implement diagram embedding with the format `![Diagram Title](embed:DiagramKey)`
3. Add support for section numbering
4. Include proper styling for headings, lists, tables, etc.
5. Support both light and dark themes

Please implement the MarkdownRenderer widget and a comprehensive test suite. The tests should cover:
- Basic Markdown rendering
- Code blocks with different languages
- Diagram embedding
- Image and link handling
- Section numbering
- Theme changes

Include example code showing how to use this widget within the documentation viewer.
### 5.6 Phase 6: Export Capabilities ✓

#### Export Formats

| Task | Implementation Files | Test Files | Testing Strategy |
|------|---------------------|------------|------------------|
| ~~Implement PNG export~~ ✓ | `lib/infrastructure/export/png_exporter.dart` | `test/infrastructure/export/png_exporter_test.dart` | Unit test with image comparison |
| ~~Create SVG export~~ ✓ | `lib/infrastructure/export/svg_exporter.dart` | `test/infrastructure/export/svg_exporter_test.dart` | Unit test SVG structure |
| ~~Add PlantUML export~~ ✓ | `lib/infrastructure/export/plantuml_exporter.dart` | `test/infrastructure/export/plantuml_exporter_test.dart` | Unit test generated PlantUML syntax |

**AI Assistant Prompt for PNG Exporter:**

Implement a PNG export functionality for the Structurizr diagram system in Flutter. This should take a rendered diagram and export it as a high-quality PNG image.

Requirements:
1. Create a PngExporter class that can:
   - Capture a rendered diagram from a StructurizrDiagram widget
   - Generate a PNG image with configurable resolution
   - Support transparent or colored backgrounds
   - Handle proper scaling of text and lines
2. Implement different resolution options (standard, high, custom DPI)
3. Add progress reporting for larger diagrams
4. Include error handling for export failures
5. Support headless export (without needing to display the diagram)

Here's an example implementation of the PngExporter class:

```dart
class PngExporter implements DiagramExporter<Uint8List> {
  final DiagramRenderParameters? renderParameters;
  final bool transparentBackground;
  final double scaleFactor;
  final double jpegQuality;
  final ValueChanged<double>? onProgress;

  PngExporter({
    this.renderParameters,
    this.transparentBackground = false,
    this.scaleFactor = 2.0, // High quality by default
    this.jpegQuality = 0.9,
    this.onProgress,
  });

  @override
  Future<Uint8List> export(StructurizrDiagram diagram) async {
    try {
      // Create a boundary key for the RepaintBoundary
      final boundaryKey = GlobalKey();

      // Report starting progress
      onProgress?.call(0.1);

      // Create a widget to render offscreen
      final offscreenWidget = MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: transparentBackground ? Colors.transparent : Colors.white,
          body: RepaintBoundary(
            key: boundaryKey,
            child: StructurizrDiagram(
              workspace: diagram.workspace,
              viewKey: diagram.viewKey,
              enablePanAndZoom: false, // Static rendering for export
              showControls: false, // Hide controls
              renderParameters: renderParameters,
            ),
          ),
        ),
      );

      // Render the widget to a virtual display
      final RenderRepaintBoundary boundary = await _renderOffscreen(
        offscreenWidget,
        boundaryKey,
      );

      // Report rendering progress
      onProgress?.call(0.5);

      // Capture image from the boundary
      final image = await boundary.toImage(pixelRatio: scaleFactor);
      final byteData = await image.toByteData(format: transparentBackground
          ? ui.ImageByteFormat.png
          : ui.ImageByteFormat.rawRgba);

      if (byteData == null) {
        throw Exception("Failed to export diagram: couldn't capture image data");
      }

      // Convert to appropriate format
      Uint8List bytes;
      if (transparentBackground) {
        // PNG format for transparency
        bytes = byteData.buffer.asUint8List();
      } else {
        // Convert RGBA to PNG
        final codec = await ui.instantiateImageCodec(
          byteData.buffer.asUint8List(),
          targetHeight: image.height,
          targetWidth: image.width,
        );
        final frameInfo = await codec.getNextFrame();
        final pngByteData = await frameInfo.image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        bytes = pngByteData!.buffer.asUint8List();
      }

      // Report completion
      onProgress?.call(1.0);

      return bytes;
    } catch (e) {
      throw Exception('Failed to export diagram: $e');
    }
  }

  /// Renders the widget offscreen to capture its image
  Future<RenderRepaintBoundary> _renderOffscreen(
    Widget widget,
    GlobalKey boundaryKey,
  ) async {
    // Create a test widget binding
    final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.window.physicalSizeTestValue = Size(1920, 1080);
    binding.window.devicePixelRatioTestValue = 1.0;

    await binding.pumpWidget(widget);
    await binding.pump(Duration(milliseconds: 20));
    await binding.pump(Duration(milliseconds: 20));

    // Get the RenderObject from the boundary key
    RenderRepaintBoundary boundary = boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    return boundary;
  }
}
```

Please implement a comprehensive test suite. The tests should cover:
- Basic export functionality
- Different resolution settings
- Various background options
- Error handling scenarios
- Performance with large diagrams

Here's an example of how to test this exporter:

```dart
testWidgets('PngExporter exports diagram correctly', (WidgetTester tester) async {
  // Create test workspace and diagram
  final workspace = createTestWorkspace();
  final diagram = StructurizrDiagram(
    workspace: workspace,
    viewKey: 'systemContext',
  );

  // Create the exporter
  final exporter = PngExporter(scaleFactor: 2.0);

  // Track progress
  double exportProgress = 0.0;
  final progressExporter = PngExporter(
    scaleFactor: 2.0,
    onProgress: (progress) {
      exportProgress = progress;
    },
  );

  // Export the diagram
  final bytes = await exporter.export(diagram);

  // Verify the export produces valid data
  expect(bytes, isNotNull);
  expect(bytes.length, greaterThan(0));

  // Verify it's a valid PNG
  expect(bytes.sublist(0, 8), equals([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])); // PNG signature

  // Test with progress tracking
  await progressExporter.export(diagram);
  expect(exportProgress, equals(1.0)); // Should complete with 100% progress
});
```

Include example code showing how to integrate this with the StructurizrDiagram widget and trigger exports programmatically:

```dart
void exportDiagramToPng(BuildContext context, Workspace workspace, String viewKey) async {
  // Show progress indicator
  final progressController = StreamController<double>();
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => StreamBuilder<double>(
      stream: progressController.stream,
      builder: (context, snapshot) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Exporting diagram...'),
            LinearProgressIndicator(value: snapshot.data),
          ],
        ),
      ),
    ),
  );

  try {
    // Create exporter with progress reporting
    final exporter = PngExporter(
      scaleFactor: 2.0,
      transparentBackground: false,
      onProgress: (progress) {
        progressController.add(progress);
      },
    );

    // Export the diagram
    final bytes = await exporter.export(
      StructurizrDiagram(
        workspace: workspace,
        viewKey: viewKey,
      ),
    );

    // Save the file
    final fileName = '${workspace.name}_${viewKey}_${DateTime.now().millisecondsSinceEpoch}.png';
    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: bytes,
      mimeType: MimeType.png,
    );

    // Close progress dialog and show success
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Diagram exported successfully')),
    );
  } catch (e) {
    // Handle errors
    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Export Failed'),
        content: Text(e.toString()),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
      ),
    );
  } finally {
    progressController.close();
  }
}
```

### 5.7 Phase 7: Workspace Management ✓

#### Local Storage

| Task | Implementation Files | Test Files | Testing Strategy |
|------|---------------------|------------|------------------|
| ~~Implement file storage~~ ✓ | `lib/infrastructure/persistence/file_storage.dart` | `test/infrastructure/persistence/file_storage_test.dart` | Integration test with file system |
| ~~Create auto-save~~ ✓ | `lib/infrastructure/persistence/auto_save.dart` | `test/infrastructure/persistence/auto_save_test.dart` | Unit test with mocked file system |

**AI Assistant Prompt for Workspace File Storage:**

Implement a file storage system for Structurizr workspaces in Flutter. This should handle saving and loading workspace files in both JSON and DSL formats.

Requirements:
1. Create a WorkspaceStorage class that can:
   - Save workspaces to JSON or DSL files
   - Load workspaces from JSON or DSL files
   - Track file paths for easy saving
   - Handle file system permissions
   - Support multiple platforms (desktop, mobile, web)
2. Implement error handling for file operations
3. Add versioning/backup capabilities
4. Include progress reporting for large files
5. Support both synchronous and asynchronous operations

Please implement the storage system and a comprehensive test suite. The tests should cover:
- Saving and loading workspaces
- Format conversion (JSON to DSL and back)
- Error handling (file not found, permission denied, etc.)
- Platform-specific behavior
- Performance with large workspaces

Include example code showing how to use this storage system in a Flutter application.

## 6. Recommended Flutter Packages

### 6.1 Core Packages

1. **riverpod**: State management and dependency injection
2. **freezed**: Immutable models with code generation
3. **json_serializable**: JSON serialization
4. **equatable**: Value equality
5. **collection**: Additional collection utilities

### 6.2 UI Packages

1. **flutter_hooks**: Reusable component logic
2. **google_fonts**: Expanded font selection
3. **flex_color_picker**: Color selection dialogs
4. **flutter_markdown**: Markdown rendering
5. **contextmenu**: Context menu widget
6. **flutter_svg**: SVG rendering
7. **animated_float_action_button**: UI controls
8. **flutter_fancy_tree_view**: Tree view for model exploration

### 6.3 Parsing Packages

1. **petitparser**: Parser combinator library
2. **yaml**: YAML parsing for configuration
3. **code_text_field**: Code editor with syntax highlighting
4. **highlight**: Syntax highlighting

### 6.4 Storage & Network Packages

1. **hive**: NoSQL database for local storage
2. **path_provider**: File system access
3. **http**: HTTP client
4. **connectivity_plus**: Network connectivity monitoring
5. **shared_preferences**: Settings storage

### 6.5 Export Packages

1. **pdf**: PDF generation
2. **image**: Image processing
3. **vector_graphics**: Vector graphics support
4. **archive**: ZIP file handling
5. **flutter_svg**: SVG generation

## 7. Implementation Plan

### 7.1 Phase 1: Core Implementation

- Core domain model implementation
- JSON serialization
- Basic rendering engine
- Simple force-directed layout
- Basic UI components

### 7.2 Phase 2: Full Feature Set

- DSL parser implementation
- Advanced layout algorithms
- Documentation and ADR viewer
- Export capabilities

### 7.3 Phase 3: Advanced Features

- Workspace management
- Collaboration features
- Theme customization
- Performance optimization

### 7.4 Phase 4: Polish and Deployment

- UI polish and refinement
- Cross-platform testing and packaging

## 8. Testing Strategy

### 8.1 Unit Testing

Each individual component is tested in isolation with comprehensive test cases:

- **Domain Model Tests**: Verify model behavior, relationships, and validation

```dart
test('Element creation and properties', () {
  final person = Person(
    id: 'user',
    name: 'User',
    description: 'A user of the system',
    tags: ['external']
  );

  expect(person.id, 'user');
  expect(person.name, 'User');
  expect(person.hasTag('external'), true);
});

test('Relationship creation and validation', () {
  final source = Person(id: 'user', name: 'User');
  final destination = SoftwareSystem(id: 'system', name: 'System');

  final relationship = Relationship(
    id: 'rel1',
    sourceId: source.id,
    destinationId: destination.id,
    description: 'Uses',
    technology: 'HTTPS',
  );

  expect(relationship.sourceId, 'user');
  expect(relationship.description, 'Uses');
});
```

- **Parser Tests**: Ensure correct parsing of DSL into models

```dart
test('DSL parser handles basic workspace definition', () {
  final parser = StructurizrDslParser();
  final dsl = '''
    workspace "Banking System" "This is a model of my banking system." {
      model {
        customer = person "Customer" "A customer of the bank."
        internetBankingSystem = softwareSystem "Internet Banking System" "Allows customers to view account balances and make payments."

        customer -> internetBankingSystem "Uses"
      }
    }
  ''';

  final workspace = parser.parse(dsl);

  expect(workspace.name, 'Banking System');
  expect(workspace.model.people.length, 1);
  expect(workspace.model.softwareSystems.length, 1);
  expect(workspace.model.relationships.length, 1);
});
```

- **Layout Algorithm Tests**: Verify layout algorithms produce expected positions

```dart
test('Force-directed layout handles edge cases', () {
  // Test with no relationships
  var layout = ForceDirectedLayout(elements: elements, relationships: []);
  var positions = layout.layout();
  expect(positions.length, equals(elements.length));

  // Test with single element
  layout = ForceDirectedLayout(elements: [singleElement], relationships: []);
  positions = layout.layout();
  expect(positions.length, equals(1));

  // Test with disconnected elements (should still position them)
  layout = ForceDirectedLayout(
    elements: disconnectedElements,
    relationships: [],
  );
  positions = layout.layout();
  expect(positions.length, equals(disconnectedElements.length));

  // Test stability - running the layout multiple times should converge
  layout = ForceDirectedLayout(
    elements: elements,
    relationships: relationships,
    iterations: 200,
  );
  final firstPositions = layout.layout();
  final secondPositions = layout.layout();

  // Positions should be similar after convergence
  for (final elementId in firstPositions.keys) {
    final firstPos = firstPositions[elementId]!;
    final secondPos = secondPositions[elementId]!;

    // Allow slight differences due to algorithm randomness
    expect((firstPos - secondPos).distance, lessThan(5.0));
  }
});
```

- **Serialization Tests**: Test JSON serialization and deserialization accuracy

```dart
test('Workspace serialization and deserialization', () {
  final originalWorkspace = Workspace(
    name: 'Test Workspace',
    description: 'Test Description',
  );
  originalWorkspace.model.addPerson('user', 'User');
  originalWorkspace.model.addSoftwareSystem('system', 'System');

  // Serialize to JSON
  final json = jsonEncode(originalWorkspace);

  // Deserialize from JSON
  final deserializedWorkspace = Workspace.fromJson(jsonDecode(json));

  // Verify equality
  expect(deserializedWorkspace.name, equals(originalWorkspace.name));
  expect(deserializedWorkspace.model.people.length, equals(1));
  expect(deserializedWorkspace.model.softwareSystems.length, equals(1));
});
```

### 8.2 Widget Testing

Test UI components in a simulated Flutter environment:

- **Render Tests**: Verify elements and relationships render correctly using golden images

```dart
testWidgets('System Context View renders correctly', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: RepaintBoundary(
        child: StructurizrDiagram(
          workspace: systemContextWorkspace,
          viewKey: 'systemContext',
        ),
      ),
    ),
  );

  await expectLater(
    find.byType(RepaintBoundary),
    matchesGoldenFile('goldens/system_context_diagram.png'),
  );
});
```

```dart
// Setup the golden testing configuration for reliable results
void main() {
  // Configure golden testing to handle differences in rendering across platforms
  goldenFileComparator = CustomGoldenComparator(
    Uri.parse('/path/to/this/test/file.dart'),
    tolerance: 0.01, // 1% pixel difference allowed
  );

  group('Element Renderer Golden Tests', () {
    testWidgets('BoxRenderer renders different styles correctly', (WidgetTester tester) async {
      // Set a fixed size for consistent golden testing
      await tester.binding.setSurfaceSize(const Size(800, 600));

      // Test multiple styles with different configuration combinations
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: RepaintBoundary(
              child: CustomPaint(
                painter: TestRenderer([
                  BoxRenderConfig(
                    element: TestElement('box1', 'Box 1', 'Standard Box'),
                    style: ElementStyle(
                      background: '#1168bd',
                      color: '#ffffff',
                      shape: 'Box',
                    ),
                    position: Rect.fromLTWH(50, 50, 150, 100),
                  ),
                  BoxRenderConfig(
                    element: TestElement('box2', 'Box 2', 'Rounded Box'),
                    style: ElementStyle(
                      background: '#27ae60',
                      color: '#ffffff',
                      shape: 'RoundedBox',
                    ),
                    position: Rect.fromLTWH(250, 50, 150, 100),
                    isSelected: true,
                  ),
                  BoxRenderConfig(
                    element: TestElement('box3', 'Box 3', 'Dashed Border'),
                    style: ElementStyle(
                      background: '#f39c12',
                      color: '#000000',
                      shape: 'Box',
                      stroke: '#d35400',
                      strokeWidth: 2,
                      strokeStyle: 'dashed',
                    ),
                    position: Rect.fromLTWH(50, 200, 150, 100),
                  ),
                  // Additional style variations
                ]),
                size: const Size(800, 600),
              ),
            ),
          ),
        ),
      );

      // Verify rendering matches golden image
      await expectLater(
        find.byType(RepaintBoundary),
        matchesGoldenFile('goldens/box_renderer_styles.png'),
      );
    });

    testWidgets('BoxRenderer handles text correctly', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));

      // Test different text scenarios (short text, long text, etc.)
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: RepaintBoundary(
              child: CustomPaint(
                painter: TextTestRenderer([
                  TextConfig(
                    name: 'Short Name',
                    description: 'Short description',
                    position: Rect.fromLTWH(50, 50, 150, 100),
                  ),
                  TextConfig(
                    name: 'This is a very long name that should wrap correctly inside the box',
                    description: 'This is a very long description that should be properly wrapped within the constraints of the box without overflowing.',
                    position: Rect.fromLTWH(250, 50, 150, 120),
                  ),
                  // Different font sizes and styles
                ]),
                size: const Size(800, 600),
              ),
            ),
          ),
        ),
      );

      // Verify text rendering
      await expectLater(
        find.byType(RepaintBoundary),
        matchesGoldenFile('goldens/box_renderer_text.png'),
      );
    });
  });
}

- **Interaction Tests**: Test touch and mouse interactions

```dart
testWidgets('Diagram responds to zoom controls', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: StructurizrDiagram(
        workspace: testWorkspace,
        viewKey: 'systemContext',
        showControls: true,
      ),
    ),
  );

  final initialScale = getScaleFactor();
  await tester.tap(find.byIcon(Icons.add));
  await tester.pump();
  final newScale = getScaleFactor();

  expect(newScale, greaterThan(initialScale));
});
```

- **Animation Tests**: Verify animations work correctly

```dart
testWidgets('Dynamic View animation steps render correctly', (WidgetTester tester) async {
  final dynamicView = tester.widget<StructurizrDiagram>(find.byType(StructurizrDiagram));

  // Test each animation step with its own golden file
  for (int i = 0; i < dynamicView.animations.length; i++) {
    await tester.tap(find.byIcon(Icons.navigate_next));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(RepaintBoundary),
      matchesGoldenFile('goldens/dynamic_view_step_${i+1}.png'),
    );
  }
});
```

- **Responsiveness Tests**: Test behavior across screen sizes

### 8.3 Integration Testing

Test how components work together:

- **Workflow Tests**: Test complete workflows from creating to viewing diagrams
- **Storage Tests**: Verify persistence and loading from storage

```dart
testWidgets('Save and load workspace from file', (WidgetTester tester) async {
  final workspaceStorage = WorkspaceStorage();
  final originalWorkspace = createTestWorkspace();

  // Save workspace to file
  final filePath = await workspaceStorage.saveWorkspace(originalWorkspace, 'test_workspace.json');

  // Load workspace from file
  final loadedWorkspace = await workspaceStorage.loadWorkspace(filePath);

  // Verify loaded workspace matches original
  expect(loadedWorkspace.name, equals(originalWorkspace.name));
  expect(loadedWorkspace.model.people.length, equals(originalWorkspace.model.people.length));
  expect(loadedWorkspace.views.views.length, equals(originalWorkspace.views.views.length));
});
```

- **Export Tests**: Test export to different formats
- **Cross-component Tests**: Test interaction between diagrams, documentation, and ADRs

### 8.4 Performance Testing

Test application performance under various conditions:

- **Large Diagram Tests**: Test with diagrams containing 100+ elements

```dart
test('Performance benchmark for large system rendering', () {
  final largeWorkspace = createLargeWorkspace(elementCount: 100, relationshipCount: 200);
  final stopwatch = Stopwatch()..start();

  final diagram = StructurizrDiagram(
    workspace: largeWorkspace,
    viewKey: 'systemLandscape',
  );

  // Trigger layout and rendering
  diagram.layout();
  stopwatch.stop();

  // Rendering should complete within reasonable time
  expect(stopwatch.elapsedMilliseconds, lessThan(1000));
});
```

- **Memory Usage Tests**: Monitor memory usage during extended use

```dart
testWidgets('Memory usage during extended use', (WidgetTester tester) async {
  // Setup test
  final workspace = TestData.createLargeWorkspace();

  // Record baseline memory
  final baselineMemory = await getApplicationMemoryInMB();

  // Render diagram
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StructurizrDiagram(
          workspace: workspace,
          viewKey: 'systemLandscape',
        ),
      ),
    ),
  );

  // Perform actions that should trigger memory usage
  for (int i = 0; i < 20; i++) {
    // Simulate zooming and panning
    await tester.drag(find.byType(StructurizrDiagram), Offset(50, 50));
    await tester.pumpAndSettle();

    // Simulate selection
    await tester.tap(find.byType(StructurizrDiagram).first);
    await tester.pumpAndSettle();
  }

  // Record memory after operations
  final peakMemory = await getApplicationMemoryInMB();

  // Memory usage should be within reasonable limits
  final memoryIncrease = peakMemory - baselineMemory;
  print('Memory increase: $memoryIncrease MB');
  expect(memoryIncrease, lessThan(50)); // Adjust threshold based on app size

  // Test for memory leaks by triggering garbage collection
  await Future.delayed(Duration(seconds: 1));
  await triggerGarbageCollection();

  final finalMemory = await getApplicationMemoryInMB();
  final leakedMemory = finalMemory - baselineMemory;

  // Memory should return close to baseline after GC
  expect(leakedMemory, lessThan(10)); // Some overhead is expected
});
```

- **Rendering Performance**: Measure frame rates during pan/zoom

```dart
testWidgets('Frame rate during pan/zoom operations', (WidgetTester tester) async {
  // Setup tracking of frame times
  final frameRateTimes = <Duration>[];
  final FrameTimingSummary summary = FrameTimingSummary();

  // Register frame timing callback
  tester.binding.addTime(summary.frameTimeRecorder);

  // Render diagram
  await tester.pumpWidget(DiagramTestApp(largeWorkspace));
  await tester.pumpAndSettle();

  // Start recording performance
  summary.start();

  // Perform zoom and pan operations
  for (int i = 0; i < 30; i++) {
    await tester.drag(find.byType(StructurizrDiagram), Offset(10, 10));
    await tester.pump(Duration(milliseconds: 16)); // Simulate 60fps

    // For zoom, use scale gesture
    await tester.fling(
      find.byType(StructurizrDiagram),
      Offset(0, 0),
      1000, // Velocity
    );
    await tester.pump(Duration(milliseconds: 16));
  }

  // Stop recording
  summary.stop();

  // Calculate frame statistics
  final avgFrameTime = summary.averageFrameTime;
  final jankyFrames = summary.jankyFramesPercentage;

  // Check performance
  expect(avgFrameTime.inMicroseconds, lessThan(16667)); // 60fps = 16.67ms per frame
  expect(jankyFrames, lessThan(5.0)); // Less than 5% dropped frames
});
```

- **Layout Performance**: Test layout calculation time for large diagrams

```dart
group('Force-directed layout performance', () {
  // Generate test data with increasing sizes
  List<Element> generateElements(int count) {
    return List.generate(count, (index) {
      return Element(
        id: 'element-$index',
        name: 'Element $index',
      );
    });
  }

  List<Relationship> generateRelationships(List<Element> elements, double density) {
    final relationships = <Relationship>[];
    final random = Random(42); // Fixed seed for reproducibility

    // Create relationships based on density (0.0-1.0, percentage of possible connections)
    final maxRelationships = (elements.length * (elements.length - 1)) / 2;
    final targetCount = (maxRelationships * density).round();

    while (relationships.length < targetCount) {
      final sourceIndex = random.nextInt(elements.length);
      var destIndex = random.nextInt(elements.length);

      // Ensure we don't connect an element to itself
      while (destIndex == sourceIndex) {
        destIndex = random.nextInt(elements.length);
      }

      final relationship = Relationship(
        id: 'rel-${relationships.length}',
        sourceId: elements[sourceIndex].id,
        destinationId: elements[destIndex].id,
        description: 'Related to',
      );

      // Add if not a duplicate
      if (!relationships.any((r) =>
            r.sourceId == relationship.sourceId &&
            r.destinationId == relationship.destinationId)) {
        relationships.add(relationship);
      }
    }

    return relationships;
  }

  // Test case scenarios
  final scenarios = [
    {'elements': 10, 'density': 0.3, 'maxTime': 50},
    {'elements': 50, 'density': 0.2, 'maxTime': 200},
    {'elements': 100, 'density': 0.1, 'maxTime': 500},
    {'elements': 200, 'density': 0.05, 'maxTime': 1000},
  ];

  for (final scenario in scenarios) {
    final elementCount = scenario['elements'] as int;
    final density = scenario['density'] as double;
    final maxTimeMs = scenario['maxTime'] as int;

    test('Layout with $elementCount elements at ${(density * 100).toStringAsFixed(1)}% density', () {
      final elements = generateElements(elementCount);
      final relationships = generateRelationships(elements, density);

      final stopwatch = Stopwatch()..start();

      // Create and run layout
      final layout = ForceDirectedLayout(
        elements: elements,
        relationships: relationships,
        canvasSize: const Size(1200, 800),
        maxIterations: 200, // Limit iterations for testing
      );

      final positions = layout.layout();
      stopwatch.stop();

      // Verify performance
      print('Layout with $elementCount elements took ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(maxTimeMs));

      // Verify all elements have positions
      expect(positions.length, elementCount);

      // Check for collisions
      int collisions = 0;
      for (int i = 0; i < elements.length; i++) {
        final element1 = elements[i];
        final bounds1 = positions[element1.id]!;

        for (int j = i + 1; j < elements.length; j++) {
          final element2 = elements[j];
          final bounds2 = positions[element2.id]!;

          if (bounds1.overlaps(bounds2)) {
            collisions++;
          }
        }
      }

      // Allow some collisions in dense layouts
      final allowedCollisions = (elementCount * 0.05).round();
      expect(collisions, lessThanOrEqualTo(allowedCollisions));
    });
  }
});

## 9. References to Original Structurizr Implementation

### 9.1 Java Core Model

Key files to reference from original implementation:
- `structurizr/core/src/main/java/com/structurizr/Workspace.java`
- `structurizr/core/src/main/java/com/structurizr/model/Element.java`
- `structurizr/core/src/main/java/com/structurizr/model/Relationship.java`
- `structurizr/core/src/main/java/com/structurizr/view/View.java`
- `structurizr/core/src/main/java/com/structurizr/view/ViewSet.java`

### 9.2 JavaScript UI

Key files to reference from original UI:
- `structurizr/ui/src/js/structurizr-diagram.js`
- `structurizr/ui/src/js/structurizr-ui.js`
- `structurizr/ui/src/js/structurizr-workspace.js`
- `structurizr/ui/src/js/structurizr-documentation.js`

### 9.3 DSL Parser

Key files to reference for DSL parsing:
- `structurizr/dsl/src/main/java/com/structurizr/dsl/StructurizrDslParser.java`
- `structurizr/dsl/src/main/java/com/structurizr/dsl/DslContext.java`

## 10. Conclusion

This specification provides a comprehensive roadmap for implementing a complete Structurizr architecture visualization tool using Flutter. By following this plan, the development team can create a cross-platform application that maintains all the functionality of the original Structurizr while leveraging Flutter's capabilities for a modern, responsive UI.

The implementation will focus on performance, usability, and feature completeness, with careful attention to maintaining compatibility with existing Structurizr workspaces in both DSL and JSON formats.