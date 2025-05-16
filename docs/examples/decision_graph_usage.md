# Decision Graph Visualization

This document provides guidance on using the enhanced decision graph visualization component to display architecture decision records (ADRs) and their relationships.

## Basic Usage

The `EnhancedDecisionGraph` widget provides a visual representation of architecture decisions and their relationships. It supports:

- Force-directed layout for natural positioning
- Interactive controls for zooming and panning
- Visual indicators for decision status
- Visualization of relationships between decisions
- Clustering for complex decision networks
- Detailed tooltips for relationships

### Basic Example

Here's a simple example of using the `EnhancedDecisionGraph`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_structurizr/domain/documentation/documentation.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/decision_graph_enhanced.dart';

class DecisionGraphScreen extends StatelessWidget {
  final List<Decision> decisions;
  
  const DecisionGraphScreen({Key? key, required this.decisions}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Architecture Decisions')),
      body: EnhancedDecisionGraph(
        decisions: decisions,
        onDecisionSelected: (index) {
          // Handle decision selection, e.g., navigate to decision details
          print('Selected decision: ${decisions[index].id}');
        },
        isDarkMode: Theme.of(context).brightness == Brightness.dark,
      ),
    );
  }
}
```

## Advanced Features

### Custom Relationship Types

The enhanced decision graph supports custom relationship types between decisions:

```dart
final relationships = [
  DecisionRelationship(
    sourceId: 'ADR-001',
    targetId: 'ADR-002',
    type: DecisionRelationshipType.supersedes,
  ),
  DecisionRelationship(
    sourceId: 'ADR-002',
    targetId: 'ADR-003',
    type: DecisionRelationshipType.depends,
  ),
];

EnhancedDecisionGraph(
  decisions: decisions,
  onDecisionSelected: (index) { /* ... */ },
  relationships: relationships,
)
```

Available relationship types:
- `related`: Generic relationship
- `supersedes`: Decision supersedes another
- `supersededBy`: Decision is superseded by another
- `depends`: Decision depends on another
- `dependedBy`: Decision is depended on by another
- `conflicts`: Decision conflicts with another
- `enables`: Decision enables another

### Clustering

For complex decision networks, clustering can be used to group related decisions:

```dart
final clusters = [
  DecisionCluster(
    decisionIds: ['ADR-001', 'ADR-002'],
    label: 'Infrastructure',
    color: Colors.blue,
  ),
  DecisionCluster(
    decisionIds: ['ADR-003', 'ADR-004', 'ADR-005'],
    label: 'Security',
    color: Colors.red,
  ),
];

EnhancedDecisionGraph(
  decisions: decisions,
  onDecisionSelected: (index) { /* ... */ },
  clusters: clusters,
)
```

### Tooltips

Tooltips that show relationship details are enabled by default. They can be disabled if needed:

```dart
EnhancedDecisionGraph(
  decisions: decisions,
  onDecisionSelected: (index) { /* ... */ },
  enableTooltips: false,  // Disable tooltips
)
```

## Customizing Appearance

### Dark Mode Support

The decision graph automatically adapts to light and dark modes:

```dart
EnhancedDecisionGraph(
  decisions: decisions,
  onDecisionSelected: (index) { /* ... */ },
  isDarkMode: true,  // For dark mode
)
```

## Interactive Controls

### Simulation Controls

The force-directed layout includes simulation controls:
- Play/pause: Toggle the animation of the force-directed layout
- Zoom in/out: Control the zoom level
- Reset: Reset zoom and pan position

Users can interact with the graph in several ways:
- Drag nodes to reposition them
- Zoom and pan using gestures or control buttons
- Tap on nodes to select them
- Hover over relationships to see detailed tooltips

## Integration with Documentation System

The decision graph can be integrated with the broader documentation system:

```dart
DocumentationNavigator(
  workspace: workspace,
  showDecisionGraph: true,
  onDecisionSelected: (decision) {
    // Navigate to decision details
  },
)
```

## Best Practices

1. **Limit Node Count**: For optimal performance, limit the number of decisions displayed simultaneously to 20-30. For larger sets, consider using clustering or filtering.

2. **Use Descriptive Titles**: Keep decision titles concise but descriptive to make the graph more readable.

3. **Organize with Clusters**: For complex decision networks, use clustering to group related decisions by theme, subsystem, or chronology.

4. **Specify Relationship Types**: Whenever possible, explicitly define relationship types rather than relying on inferred relationships for clearer visualization.

5. **Provide Sufficient Space**: The graph needs adequate space to render effectively. Ensure the container is at least 800x600 pixels.

## Performance Considerations

The force-directed layout is computationally intensive. For large decision sets (>50 decisions), consider:

1. Disabling automatic simulation after initial layout
2. Using clustering to reduce visual complexity
3. Implementing filtering to show only decisions relevant to the current context

## Accessibility

The decision graph component implements several accessibility features:

1. Color contrast ratios meet WCAG AA guidelines
2. Interactive elements have appropriate focus indicators
3. Keyboard navigation support for essential functions
4. Screen reader support for decision nodes

## Troubleshooting

### Common Issues

1. **Unstable Layout**: If the graph layout is unstable or oscillates, try:
   - Reducing the spring strength parameter
   - Increasing the damping parameter
   - Pausing the simulation after initial stabilization

2. **Overlapping Nodes**: For graphs with many nodes, consider:
   - Increasing the repulsion strength
   - Using clustering to create more structured layouts
   - Manually adjusting initial positions

3. **Performance Issues**: If performance is slow:
   - Reduce the number of visible decisions
   - Disable automatic simulation
   - Use clustering to simplify visualization