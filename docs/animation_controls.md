# Animation Controls for Structurizr Diagrams

This document explains how to use the animation controls for dynamic views in the Dart Structurizr library.

## Overview

The `AnimationControls` widget provides a UI for controlling animations in dynamic views. It offers functionality for:

- Stepping through animation steps sequentially
- Auto-playing animations with configurable speed
- Different playback modes (play once, loop, ping-pong)
- A visual timeline for navigating to specific steps
- Configurable appearance and behavior

## Usage

### Basic Usage

```dart
import 'package:flutter_structurizr/flutter_structurizr.dart';

// Inside your widget build method
AnimationControls(
  animationSteps: view.animations,
  initialStep: 0,
  onStepChanged: (step) {
    setState(() {
      currentStep = step;
    });
  },
)
```

### Integration with StructurizrDiagram

The animation controls are designed to work seamlessly with the `StructurizrDiagram` widget:

```dart
class DynamicViewPage extends StatefulWidget {
  final Workspace workspace;
  final DynamicView view;
  
  const DynamicViewPage({
    Key? key,
    required this.workspace,
    required this.view,
  }) : super(key: key);
  
  @override
  State<DynamicViewPage> createState() => _DynamicViewPageState();
}

class _DynamicViewPageState extends State<DynamicViewPage> {
  int _currentStep = 0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.view.title ?? 'Dynamic View'),
      ),
      body: Column(
        children: [
          // The main diagram with current animation step
          Expanded(
            child: StructurizrDiagram(
              workspace: widget.workspace,
              view: widget.view,
              animationStep: _currentStep,
            ),
          ),
          
          // Animation controls at the bottom
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AnimationControls(
              animationSteps: widget.view.animations,
              initialStep: _currentStep,
              onStepChanged: (step) {
                setState(() {
                  _currentStep = step;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

### Customization

The appearance and behavior of the controls can be customized using the `AnimationControlsConfig` class:

```dart
AnimationControls(
  animationSteps: view.animations,
  initialStep: currentStep,
  onStepChanged: (step) {
    setState(() {
      currentStep = step;
    });
  },
  config: const AnimationControlsConfig(
    autoPlay: true,                    // Start playing automatically
    defaultMode: AnimationMode.loop,   // Loop the animation
    fps: 2.0,                          // Play at 2 frames per second
    showStepLabels: true,              // Show step numbers
    showTimingControls: true,          // Show speed controls
    showModeControls: true,            // Show playback mode controls
    height: 100.0,                     // Custom height
    backgroundColor: Colors.black12,   // Custom background color
    textColor: Colors.blue,            // Custom text color
    iconColor: Colors.blue,            // Custom icon color
    activeColor: Colors.blue,          // Color for active elements
    inactiveColor: Colors.grey,        // Color for inactive elements
  ),
)
```

## Animation Modes

The controls support three playback modes:

1. **Play Once**: Plays through the animation steps once and stops at the end
2. **Loop**: Continuously loops from the beginning after reaching the end
3. **Ping-Pong**: Alternates between going forward and backward

## Creating Animation Steps

Animation steps are defined in the `View` model as a list of `AnimationStep` objects:

```dart
final animations = [
  // Step 1: Show initial elements and relationships
  AnimationStep(
    order: 1,
    elements: ['user', 'webApp'],
    relationships: ['user-uses-webApp'],
  ),
  
  // Step 2: Add more elements and relationships
  AnimationStep(
    order: 2,
    elements: ['user', 'webApp', 'api'],
    relationships: ['user-uses-webApp', 'webApp-calls-api'],
  ),
  
  // Step 3: Complete the flow
  AnimationStep(
    order: 3,
    elements: ['user', 'webApp', 'api', 'database'],
    relationships: ['user-uses-webApp', 'webApp-calls-api', 'api-uses-database'],
  ),
];

// Add to dynamic view
final dynamicView = DynamicView(
  key: 'userFlow',
  title: 'User Request Flow',
  // ... other properties
  animations: animations,
);
```

## Best Practices

1. **Progressive Disclosure**: Design animation steps to gradually reveal more of the system
2. **Storytelling**: Use animation to tell a story about how your system works
3. **Consistent Timing**: Adjust the animation speed based on the complexity of each step
4. **Visual Cues**: Use highlighting or other visual indicators to focus attention on the current step
5. **Responsiveness**: Place the controls at the bottom of the screen for mobile-friendly layouts

## Examples

See the `example/lib/animation_example.dart` file for a complete working example of the animation controls.