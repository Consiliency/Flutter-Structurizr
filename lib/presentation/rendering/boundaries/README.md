# Boundary Renderer for Structurizr

This module provides rendering capabilities for boundary elements in Structurizr diagrams, specifically:

1. **Enterprise Boundaries** - Grouping multiple software systems in a single boundary
2. **Container Boundaries** - Grouping components within a container
3. **External System Boundaries** - Visually separating external systems

## Usage

The boundary renderer can be used in your diagram rendering code as follows:

```dart
import 'package:flutter_structurizr/presentation/rendering/boundaries/boundaries.dart';

// Create the renderer
final boundaryRenderer = BoundaryRenderer();

// Render a software system boundary
boundaryRenderer.renderElement(
  canvas: canvas,
  element: softwareSystem,
  elementView: systemView,
  style: systemStyle,
);

// Render an enterprise boundary
boundaryRenderer.renderElement(
  canvas: canvas,
  element: enterpriseElement,
  elementView: enterpriseView,
  style: enterpriseStyle,
);
```

## Features

The boundary renderer supports:

- Container boundaries (Software System boundaries)
- Enterprise boundaries
- Custom styling for boundaries (color, stroke style, opacity)
- Automatic sizing based on contained elements
- Label rendering for boundaries
- Different border styles (solid, dashed, dotted)

## How Boundaries Work

Boundaries are visual elements that group related elements together. They don't represent actual architectural entities but serve to visually organize the diagram.

In Structurizr terms:
- **Enterprise boundaries** group software systems that belong to the same enterprise
- **Software system boundaries** group containers that belong to the same software system
- **Container boundaries** group components that belong to the same container

## Custom Styling

You can customize the appearance of boundaries using the ElementStyle class:

```dart
final boundaryStyle = ElementStyle(
  shape: Shape.roundedBox,        // Shape of the boundary
  background: Colors.grey.shade200, // Background color
  stroke: Colors.grey.shade600,   // Border color
  border: Border.dashed,          // Border style (solid, dashed, dotted)
  opacity: 30,                    // Opacity percentage (0-100)
);
```

## Implementation Details

The boundary renderer:
1. Draws a background area with reduced opacity
2. Applies a border with the specified style
3. Adds a label in the top-left corner
4. Provides hit testing for selection