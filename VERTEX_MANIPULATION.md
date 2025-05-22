# Vertex Manipulation Guide

This guide explains how to add and remove vertices (waypoints) on relationship edges in the Flutter Structurizr diagram.

## Adding Vertices

There are two ways to add a vertex to a relationship:

### Method 1: Drag and Drop
1. Click and drag on any point along a relationship line
2. Drop at the desired location
3. A new vertex will be added at the drop position

### Method 2: Shift+Click
1. Hold the **Shift** key
2. Click on any point along a relationship line
3. A new vertex will be added at that location

The vertex will be inserted at the appropriate position in the relationship path to maintain a smooth flow.

## Deleting Vertices

To delete a vertex:

### Method 1: Right-click Context Menu
1. Right-click on a vertex (the blue circle on a selected relationship)
2. Select "Delete Vertex" from the context menu

### Method 2: Keyboard Shortcut (TODO)
1. Select a relationship to show its vertices
2. Click on a vertex to select it
3. Press the Delete key

## Visual Feedback

- Selected relationships show their vertices as blue circles with white borders
- Vertices can be clicked and dragged (drag functionality to be implemented)
- When hovering over a vertex, the cursor changes to indicate it's clickable

## Technical Details

Vertices are stored as part of the `RelationshipView` in the Structurizr model. Each vertex has:
- `x`: X coordinate in diagram space
- `y`: Y coordinate in diagram space

The vertices are rendered by the DiagramPainter and hit testing is performed to allow interaction.