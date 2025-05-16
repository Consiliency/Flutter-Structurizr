# DynamicViewDiagram Widget

The `DynamicViewDiagram` widget provides a comprehensive solution for rendering animated system interactions in Flutter Structurizr. This widget integrates both the `StructurizrDiagram` and `AnimationControls` components into a single, cohesive unit that handles both rendering and playback control.

## Overview

DynamicViewDiagram is specifically designed for visualizing dynamic views that show sequences of interactions between elements in a system. It provides a complete set of controls for:

- Playing/pausing animation sequences
- Stepping forward/backward through interaction steps
- Controlling playback speed and animation modes
- Toggling text rendering options (element names, descriptions, relationship descriptions)

## Usage

### Basic Usage

```dart
DynamicViewDiagram(
  workspace: workspace,
  view: dynamicView,
  config: DynamicViewDiagramConfig(
    showAnimationControls: true,
    autoPlay: false,
    animationMode: AnimationMode.loop,
    fps: 1.0,
    diagramConfig: StructurizrDiagramConfig(
      showGrid: true,
      fitToScreen: true,
      centerOnStart: true,
      showElementNames: true,
      showElementDescriptions: true,
      showRelationshipDescriptions: true,
    ),
    animationControlsConfig: AnimationControlsConfig(
      showStepLabels: true,
      showTimingControls: true,
      showModeControls: true,
    ),
  ),
)
```

### Configuration Options

DynamicViewDiagram's behavior is controlled through the `DynamicViewDiagramConfig` class, which combines configuration options for both the diagram and animation controls:

#### Top-level Options

- `showAnimationControls` - Whether to show animation controls (default: true)
- `autoPlay` - Whether to automatically start playback when mounted (default: false)
- `animationMode` - The animation playback mode (default: AnimationMode.loop)
- `fps` - Frames per second for animation playback (default: 1.0)

#### Diagram Options

The `diagramConfig` field accepts a `StructurizrDiagramConfig` with options including:

- `showGrid` - Whether to show the background grid (default: true)
- `fitToScreen` - Whether to fit diagram to screen on initial load (default: true)
- `centerOnStart` - Whether to center the diagram on initial load (default: true)
- `showElementNames` - Whether to show element names (default: true)
- `showElementDescriptions` - Whether to show element descriptions (default: false)
- `showRelationshipDescriptions` - Whether to show relationship descriptions (default: true)

#### Animation Controls Options

The `animationControlsConfig` field accepts an `AnimationControlsConfig` with options including:

- `showStepLabels` - Whether to show step labels in the timeline (default: true)
- `showTimingControls` - Whether to show speed controls (default: true)
- `showModeControls` - Whether to show animation mode controls (default: true)

## Text Rendering Options

A key feature of `DynamicViewDiagram` is its ability to control which text elements are rendered in the diagram:

1. **Element Names** - The primary identifier for each element (controlled via `showElementNames`)
2. **Element Descriptions** - Additional information about each element (controlled via `showElementDescriptions`)
3. **Relationship Descriptions** - Text describing the relationships between elements (controlled via `showRelationshipDescriptions`)

These options can be toggled to adjust the level of detail in the diagram, which is especially useful for presentations or when focusing on specific aspects of the system.

## Animation Modes

DynamicViewDiagram supports various animation playback modes through the `AnimationMode` enum:

- `AnimationMode.once` - Play through the animation steps once and stop
- `AnimationMode.loop` - Continuously loop the animation from start to finish
- `AnimationMode.pingPong` - Play forward, then backward, continuously

## Creating Example Workspaces

Here's a simple example of creating a workspace with a dynamic view for use with `DynamicViewDiagram`:

```dart
// Create a workspace
final workspace = Workspace(
  name: 'Animation Example',
  description: 'Example workspace showing animation of dynamic views',
);

// Add elements
final user = workspace.model.addPerson(
  id: 'user',
  name: 'User',
  description: 'A user of the system',
);

final webApp = workspace.model.addSoftwareSystem(
  id: 'webApp',
  name: 'Web Application',
  description: 'The web application',
);

final database = workspace.model.addSoftwareSystem(
  id: 'database',
  name: 'Database',
  description: 'The database',
);

// Add relationships
user.uses(
  destination: webApp,
  description: 'Uses',
  technology: 'HTTPS',
);

webApp.uses(
  destination: database,
  description: 'Reads/writes data',
  technology: 'SQL/TCP',
);

// Create a dynamic view
final dynamicView = DynamicView(
  key: 'dynamic',
  title: 'User Request Flow',
  description: 'Shows the flow of a user request through the system',
  autoAnimationInterval: true,
);

// Add elements to the view
dynamicView.addElement(ElementView(id: user.id));
dynamicView.addElement(ElementView(id: webApp.id));
dynamicView.addElement(ElementView(id: database.id));

// Add animation steps
final animations = [
  // Step 1: Show user and web app, with the first relationship
  AnimationStep(
    order: 1,
    elements: [user.id, webApp.id],
    relationships: [user.getRelationships()[0].id],
  ),
  
  // Step 2: Add database and the next relationship
  AnimationStep(
    order: 2,
    elements: [user.id, webApp.id, database.id],
    relationships: [
      user.getRelationships()[0].id,
      webApp.getRelationships()[0].id,
    ],
  ),
];

// Set the animation steps on the view
final finalView = dynamicView.copyWith(animations: animations);

// Add the view to the workspace
workspace.views.add(finalView);
```

## Interactive UI Controls

For a more interactive experience, you can create UI controls to toggle rendering options:

```dart
bool _showElementNames = true;
bool _showElementDescriptions = true;
bool _showRelationshipDescriptions = true;

// Later, in your build method:
Column(
  children: [
    Expanded(
      child: DynamicViewDiagram(
        workspace: workspace,
        view: dynamicView,
        config: DynamicViewDiagramConfig(
          diagramConfig: StructurizrDiagramConfig(
            showElementNames: _showElementNames,
            showElementDescriptions: _showElementDescriptions,
            showRelationshipDescriptions: _showRelationshipDescriptions,
          ),
        ),
      ),
    ),
    // Controls panel
    Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Show Element Names'),
              value: _showElementNames,
              onChanged: (value) {
                setState(() {
                  _showElementNames = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Show Element Descriptions'),
              value: _showElementDescriptions,
              onChanged: (value) {
                setState(() {
                  _showElementDescriptions = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Show Relationship Descriptions'),
              value: _showRelationshipDescriptions,
              onChanged: (value) {
                setState(() {
                  _showRelationshipDescriptions = value;
                });
              },
            ),
          ],
        ),
      ),
    ),
  ],
)
```

## Summary

The `DynamicViewDiagram` widget offers a complete solution for visualizing dynamic system interactions with step-by-step animation playback. Its comprehensive configuration options and integration with the renderer chain make it a powerful tool for creating engaging architecture presentations.

For more details on animation controls specifically, see [Animation Controls](animation_controls.md).