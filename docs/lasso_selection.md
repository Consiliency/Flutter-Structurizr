# Lasso Selection in Flutter Structurizr

## Overview

The lasso selection feature allows users to select multiple elements and relationships in a diagram by drawing a free-form selection area. This document explains how the lasso selection works and how to integrate it with other components.

## Key Features

- **Free-form Selection**: Draw any arbitrary shape to select diagram elements
- **Multi-selection**: Select multiple elements and relationships in a single operation
- **Keyboard Modifiers**: Use Ctrl/Cmd to add to existing selection
- **Visual Feedback**: Clear visual indication of the lasso area and selected items
- **Group Operations**: Move, copy, or delete multiple selected elements

## Implementation Details

### Core Components

1. **LassoSelection Class**: 
   - Manages the lasso state, path, and selection logic
   - Provides accurate hit-testing for elements and relationships
   - Maintains sets of selected element and relationship IDs

2. **DiagramPainter Integration**:
   - Enhanced to support relationship hit testing
   - Provides methods to find elements and relationships within geometric shapes
   - Handles multi-selection rendering

3. **StructurizrDiagram Widget**:
   - Handles gesture recognition for lasso operations
   - Manages the selection state
   - Provides callbacks for multi-selection events

### Selection Modes

The selection system operates in three modes:

1. **Normal Mode**: Standard point-and-click selection
2. **Lasso Mode**: Drawing a free-form selection area
3. **Dragging Mode**: Moving selected elements

### Key Interactions

- **Start Lasso**: Pan gesture on empty area of diagram
- **Draw Lasso**: Continue pan gesture to draw the selection shape
- **Complete Lasso**: Release to finalize the selection
- **Add to Selection**: Hold Ctrl/Cmd while performing lasso selection
- **Move Selection**: Drag any selected element to move the entire selection
- **Context Menu**: Right-click on selection for additional operations

## Usage Examples

### Basic Usage

```dart
StructurizrDiagram(
  workspace: workspace,
  view: view,
  isEditable: true,
  onElementSelected: (id, element) {
    // Handle single element selection
  },
  onMultipleItemsSelected: (elementIds, relationshipIds) {
    // Handle multi-selection
    print('Selected ${elementIds.length} elements and ${relationshipIds.length} relationships');
  },
)
```

### Handling Element Movement

```dart
StructurizrDiagram(
  workspace: workspace,
  view: view,
  isEditable: true,
  onElementsMoved: (Map<String, Offset> newPositions) {
    // Update element positions in your model
    for (final entry in newPositions.entries) {
      final elementId = entry.key;
      final newPosition = entry.value;
      
      // Update the element's position in your model
      updateElementPosition(elementId, newPosition);
    }
  },
)
```

## Technical Details

### Hit Testing Algorithm

The lasso selection uses precise hit testing algorithms:

1. **Point-in-Polygon**: Ray casting algorithm to determine if a point is inside the lasso
2. **Line Intersection**: Line segment intersection tests for relationships
3. **Rectangle Intersection**: Hybrid approach for fast element hit testing

### Performance Considerations

- Optimized for large diagrams with many elements
- Efficient point collection during lasso drawing
- Simplified polygon for hit testing for smooth performance
- Cached relationship paths for faster intersection testing

## Integration with Other Features

### Context Menu

Right-clicking on a multi-selection shows a context menu with options like:
- Copy selected elements
- Delete selected elements
- Align selected elements
- Group selected elements

### Keyboard Shortcuts

- **Ctrl+A**: Select all elements in the view
- **Delete/Backspace**: Delete selected elements
- **Escape**: Cancel current selection or operation
- **Ctrl+C/Ctrl+V**: Copy/paste selected elements

## Future Enhancements

- Rectangular selection in addition to lasso selection
- Selection filtering by element type
- Selection saving and recall
- Improved visual styling for selection feedback
- Animation for selection operations