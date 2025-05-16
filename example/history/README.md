# Structurizr History Example

This example demonstrates the undo/redo functionality implemented in Flutter Structurizr.

## Features

- **Command History**: Tracks all user operations for undo/redo
- **Undo/Redo Controls**: UI controls for navigating the command history
- **Keyboard Shortcuts**: Ctrl+Z for undo, Ctrl+Y for redo
- **History Panel**: Visual display of the command history
- **Transactions**: Grouping multiple operations into a single undoable action
- **Command Merging**: Combining related operations for more intuitive undo/redo
- **Toolbar Integration**: UI components for easy integration into existing apps

## Architecture

The undo/redo system is implemented using the Command Pattern:

1. **Command Interface**: Defines the contract for all commands
2. **Concrete Commands**: Implement specific operations (move, add, remove, etc.)
3. **History Manager**: Tracks command execution and manages undo/redo stacks
4. **UI Components**: Provide user interface for interacting with the history

## Usage

This example demonstrates the following operations with undo/redo support:

- **Add Element**: Add person, system, or container elements
- **Move Element**: Drag elements with the mouse
- **Edit Element**: Change element names
- **Add Relationship**: Create relationships between elements
- **Remove Element**: Delete elements (also removes connected relationships)

All operations can be undone and redone using the toolbar buttons or keyboard shortcuts.

## Running the Example

```bash
cd example/history
flutter pub get
flutter run
```

## Implementation Notes

- The Command pattern is implemented in `lib/application/command/command.dart`
- The HistoryManager is implemented in `lib/application/command/history_manager.dart`
- UI components are in `lib/presentation/widgets/history/`
- The example demonstrates integration with a simple diagram editor