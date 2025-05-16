# ElementExplorer Context Menu Usage

> **New in Phase 3** - Complete implementation of context menu functionality

The ElementExplorer widget now supports context menus, allowing users to perform actions on elements through right-click or long-press interactions.

## Basic Setup

To enable context menus in your ElementExplorer widget:

```dart
ElementExplorer(
  workspace: myWorkspace,
  config: ElementExplorerConfig(
    enableContextMenu: true,
    contextMenuItems: [
      // Define your menu items here
    ],
  ),
  onContextMenuItemSelected: (itemId, elementId, element) {
    // Handle menu selection
  },
)
```

## Creating Menu Items

Menu items can be defined with or without filters for specific element types:

```dart
// Basic menu item for all element types
ElementContextMenuItem(
  id: 'view',
  label: 'View Details',
  icon: Icons.info_outline,
),

// Menu item only for Container elements
ElementContextMenuItem(
  id: 'add_component',
  label: 'Add Component',
  icon: Icons.add_circle,
  filter: (element) => element.type == 'Container',
),
```

## Handling Menu Selection

Implement the `onContextMenuItemSelected` callback to handle menu actions:

```dart
onContextMenuItemSelected: (itemId, elementId, element) {
  switch (itemId) {
    case 'view':
      // Show element details
      break;
    case 'edit':
      // Open editor for element
      break;
    case 'delete':
      // Delete the element
      break;
  }
},
```

## Complete Example

```dart
class MyDiagramViewer extends StatelessWidget {
  final Workspace workspace;
  
  const MyDiagramViewer({Key? key, required this.workspace}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Architecture Explorer')),
      body: Row(
        children: [
          // Element Explorer with context menu
          SizedBox(
            width: 300,
            child: ElementExplorer(
              workspace: workspace,
              config: ElementExplorerConfig(
                enableContextMenu: true,
                contextMenuItems: [
                  const ElementContextMenuItem(
                    id: 'view',
                    label: 'View Details',
                    icon: Icons.info_outline,
                  ),
                  const ElementContextMenuItem(
                    id: 'edit',
                    label: 'Edit Element',
                    icon: Icons.edit,
                  ),
                  ElementContextMenuItem(
                    id: 'add_container',
                    label: 'Add Container',
                    icon: Icons.add_box,
                    filter: (element) => element.type == 'SoftwareSystem',
                  ),
                  ElementContextMenuItem(
                    id: 'add_component',
                    label: 'Add Component',
                    icon: Icons.add_circle,
                    filter: (element) => element.type == 'Container',
                  ),
                  ElementContextMenuItem(
                    id: 'delete',
                    label: 'Delete Element',
                    icon: Icons.delete,
                    filter: (element) => element.type != 'Person',
                  ),
                ],
              ),
              onElementSelected: (id, element) {
                // Handle element selection
              },
              onContextMenuItemSelected: (itemId, elementId, element) {
                // Handle menu selection
                print('Menu action: $itemId on element: ${element.name}');
                
                // Implement actions based on menu item
                if (itemId == 'delete') {
                  // Show confirmation dialog and delete element
                }
              },
            ),
          ),
          
          // Main diagram area
          Expanded(
            child: StructurizrDiagram(
              workspace: workspace,
              view: workspace.views.systemLandscapeViews.first,
            ),
          ),
        ],
      ),
    );
  }
}
```

## Best Practices

1. **Filtered Menu Items**: Use the `filter` function to show menu items only for relevant element types
2. **Meaningful Icons**: Use icons that clearly indicate the action purpose
3. **Group Similar Actions**: Order related actions together in the menu
4. **Handle All Actions**: Implement handlers for all menu items to avoid user confusion
5. **Provide Feedback**: Show visual feedback after menu actions are performed

## Implementation Notes

- Context menus are triggered by right-click (secondary tap) on desktop and long-press on mobile
- Menu is positioned at the cursor location for right-click or centered on the element for long-press
- Menu items are filtered based on the element's type when defined with a filter function
- The ElementExplorer must be inside a Material widget for proper menu styling