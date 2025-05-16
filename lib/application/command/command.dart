import 'package:flutter/foundation.dart';

/// A command represents a reversible action in the application.
/// 
/// Commands follow the Command pattern to enable undo/redo functionality.
/// Each command encapsulates both the action to perform (execute)
/// and how to reverse it (undo).
abstract class Command {
  /// Executes the command, performing the action.
  void execute();
  
  /// Undoes the command, reversing the action.
  void undo();
  
  /// A human-readable description of the command.
  /// 
  /// This is used in the UI to describe the action in history lists
  /// and undo/redo controls.
  String get description;
  
  /// Whether this command can be merged with the previous command
  /// to create a single undoable action.
  /// 
  /// This is useful for actions like dragging, where multiple move
  /// operations should be treated as a single action from the user's perspective.
  bool get canMerge => false;
  
  /// Attempts to merge this command with another command.
  /// 
  /// Returns null if the commands cannot be merged, or a new command
  /// that represents the merged operation.
  Command? mergeWith(Command other) => null;
}

/// A command that modifies a model element's property.
class PropertyChangeCommand<T> implements Command {
  final String elementId;
  final String propertyName;
  final T oldValue;
  final T newValue;
  final Function(String, String, T) updateProperty;
  
  PropertyChangeCommand(
    this.elementId, 
    this.propertyName, 
    this.oldValue, 
    this.newValue, 
    this.updateProperty
  );
  
  @override
  void execute() {
    updateProperty(elementId, propertyName, newValue);
  }
  
  @override
  void undo() {
    updateProperty(elementId, propertyName, oldValue);
  }
  
  @override
  String get description => 'Change $propertyName';
  
  @override
  bool get canMerge => true;
  
  @override
  Command? mergeWith(Command other) {
    // Can only merge with another PropertyChangeCommand
    if (other is PropertyChangeCommand<T> &&
        other.elementId == elementId &&
        other.propertyName == propertyName) {
      // Create a new command that goes from our old value to their new value
      return PropertyChangeCommand<T>(
        elementId,
        propertyName,
        oldValue,
        other.newValue,
        updateProperty,
      );
    }
    return null;
  }
}

/// A command that moves an element to a new position.
class MoveElementCommand implements Command {
  final String elementId;
  final Offset oldPosition;
  final Offset newPosition;
  final Function(String, Offset) updatePosition;
  
  MoveElementCommand(
    this.elementId, 
    this.oldPosition, 
    this.newPosition, 
    this.updatePosition
  );
  
  @override
  void execute() {
    updatePosition(elementId, newPosition);
  }
  
  @override
  void undo() {
    updatePosition(elementId, oldPosition);
  }
  
  @override
  String get description => 'Move element';
  
  @override
  bool get canMerge => true;
  
  @override
  Command? mergeWith(Command other) {
    // Can only merge with another MoveElementCommand for the same element
    if (other is MoveElementCommand && other.elementId == elementId) {
      // Create a new command that goes from our old position to their new position
      return MoveElementCommand(
        elementId,
        oldPosition,
        other.newPosition,
        updatePosition,
      );
    }
    return null;
  }
}

/// A command that adds an element to the model.
class AddElementCommand implements Command {
  final String elementId;
  final Function(String) addElement;
  final Function(String) removeElement;
  
  AddElementCommand(
    this.elementId, 
    this.addElement, 
    this.removeElement
  );
  
  @override
  void execute() {
    addElement(elementId);
  }
  
  @override
  void undo() {
    removeElement(elementId);
  }
  
  @override
  String get description => 'Add element';
}

/// A command that removes an element from the model.
class RemoveElementCommand implements Command {
  final String elementId;
  final Function(String) removeElement;
  final Function(String) addElement;
  
  RemoveElementCommand(
    this.elementId, 
    this.removeElement, 
    this.addElement
  );
  
  @override
  void execute() {
    removeElement(elementId);
  }
  
  @override
  void undo() {
    addElement(elementId);
  }
  
  @override
  String get description => 'Remove element';
}

/// A command that creates a relationship between elements.
class AddRelationshipCommand implements Command {
  final String relationshipId;
  final String sourceId;
  final String destinationId;
  final Function(String, String, String) addRelationship;
  final Function(String) removeRelationship;
  
  AddRelationshipCommand(
    this.relationshipId,
    this.sourceId,
    this.destinationId,
    this.addRelationship,
    this.removeRelationship,
  );
  
  @override
  void execute() {
    addRelationship(relationshipId, sourceId, destinationId);
  }
  
  @override
  void undo() {
    removeRelationship(relationshipId);
  }
  
  @override
  String get description => 'Add relationship';
}

/// A command that removes a relationship.
class RemoveRelationshipCommand implements Command {
  final String relationshipId;
  final String sourceId;
  final String destinationId;
  final Function(String) removeRelationship;
  final Function(String, String, String) addRelationship;
  
  RemoveRelationshipCommand(
    this.relationshipId,
    this.sourceId,
    this.destinationId,
    this.removeRelationship,
    this.addRelationship,
  );
  
  @override
  void execute() {
    removeRelationship(relationshipId);
  }
  
  @override
  void undo() {
    addRelationship(relationshipId, sourceId, destinationId);
  }
  
  @override
  String get description => 'Remove relationship';
}

/// A composite command that groups multiple commands into a single undoable action.
/// 
/// This is useful for operations that affect multiple elements or properties
/// but should be treated as a single action from the user's perspective.
class CompositeCommand implements Command {
  final List<Command> commands;
  final String _description;
  
  CompositeCommand(this.commands, this._description);
  
  @override
  void execute() {
    for (final command in commands) {
      command.execute();
    }
  }
  
  @override
  void undo() {
    // Undo in reverse order
    for (final command in commands.reversed) {
      command.undo();
    }
  }
  
  @override
  String get description => _description;
}