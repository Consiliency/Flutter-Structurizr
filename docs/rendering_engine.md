# Dart Structurizr Rendering Engine Documentation

This document describes the rendering engine implementation for Dart Structurizr, which is responsible for visualizing C4 architecture diagrams.

## Architecture

The rendering engine is divided into several key components:

1. **Element Renderer** - Renders individual architecture elements (Person, SoftwareSystem, Container, etc.)
2. **Relationship Renderer** - Renders relationships between elements
3. **Layout Engine** - Positions elements on the diagram
4. **Diagram Widget** - Integrates the renderers with Flutter's widget system

## Element Renderer

The element renderer is responsible for drawing different types of architecture elements on the canvas. It supports a wide range of shape types:

- **Box** - Standard rectangular shape
- **RoundedBox** - Rectangular shape with rounded corners
- **Circle** - Perfect circle shape
- **Ellipse** - Oval shape
- **Hexagon** - Six-sided polygon
- **Cylinder** - Database-like shape with curved top and bottom
- **Person** - Person figure with head and body
- **Robot** - Stylized robot shape
- **Folder** - Folder shape with tab
- **Component** - UML component notation
- **Pipe** - Pipe shape for infrastructure nodes
- **WebBrowser** - Browser window with controls
- **MobileDevice** - Smartphone shape

The element renderer also handles:
- Text rendering for names and descriptions
- Metadata display
- Color styling
- Selection indicators

## Relationship Renderer

The relationship renderer draws connections between elements. It supports:

### Line Styles
- **Solid** - Standard solid line
- **Dashed** - Dashed line pattern
- **Dotted** - Dotted line pattern

### Routing Options
- **Direct** - Straight line between points
- **Curved** - Curved path using cubic Bezier curves
- **Orthogonal** - Horizontal and vertical segments only

### Arrow Styles
- **Standard** - Filled triangular arrow
- **Open** - Outline triangular arrow
- **Diamond** - Diamond shape for aggregation
- **FilledDiamond** - Filled diamond for composition
- **Circle** - Circle for feedback loops

The relationship renderer also handles:
- Text rendering for descriptions
- Order numbering for dynamic views
- Path computations with proper error handling

## Usage Example

```dart
// Create an element renderer
final elementRenderer = ElementRenderer(
  element: softwareSystem,
  style: style,
  isSelected: false,
);

// Render the element
elementRenderer.render(canvas, elementBounds);

// Create a relationship renderer
final relationshipRenderer = RelationshipRenderer(
  relationship: relationship,
  style: style,
  isSelected: false,
  start: startPoint,
  end: endPoint,
  description: 'Uses',
  order: '1',
);

// Render the relationship
relationshipRenderer.render(canvas);
```

## Next Steps

The rendering engine is currently being enhanced with:

1. Improved layout algorithms for better element positioning
2. Interactive features like element selection and tooltips
3. Enhanced animation support for dynamic views

See the project completion specification for more details on the roadmap.