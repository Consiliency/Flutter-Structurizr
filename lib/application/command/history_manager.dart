import 'dart:async';

import 'command.dart';

/// Manages the history of executed commands and provides undo/redo functionality.
/// 
/// The HistoryManager tracks commands as they are executed and maintains
/// separate stacks for undo and redo operations. It also provides functionality
/// for command merging and transaction grouping.
class HistoryManager {
  /// Maximum number of commands to keep in history
  final int maxHistorySize;
  
  /// The stack of commands that can be undone
  final List<Command> _undoStack = [];
  
  /// The stack of commands that can be redone
  final List<Command> _redoStack = [];
  
  /// Whether a transaction is currently in progress
  bool _inTransaction = false;
  
  /// Commands accumulated during the current transaction
  final List<Command> _transactionCommands = [];
  
  /// Stream controller for notifying about history changes
  final _historyChangesController = StreamController<void>.broadcast();
  
  /// Creates a new HistoryManager with optional parameters.
  /// 
  /// [maxHistorySize] specifies the maximum number of commands to keep in history.
  /// The default is 100.
  HistoryManager({this.maxHistorySize = 100});
  
  /// Stream of history change events.
  /// 
  /// Listeners are notified whenever the history changes (commands executed,
  /// undone, or redone).
  Stream<void> get historyChanges => _historyChangesController.stream;
  
  /// Whether there are commands that can be undone.
  bool get canUndo => _undoStack.isNotEmpty;
  
  /// Whether there are commands that can be redone.
  bool get canRedo => _redoStack.isNotEmpty;
  
  /// The description of the command that would be undone by calling [undo].
  String? get undoDescription => 
      canUndo ? _undoStack.last.description : null;
  
  /// The description of the command that would be redone by calling [redo].
  String? get redoDescription => 
      canRedo ? _redoStack.last.description : null;
  
  /// List of descriptions for the undo stack, most recent first.
  List<String> get undoDescriptions => 
      _undoStack.reversed.map((cmd) => cmd.description).toList();
  
  /// List of descriptions for the redo stack, most recent first.
  List<String> get redoDescriptions => 
      _redoStack.map((cmd) => cmd.description).toList();
  
  /// Executes a command and adds it to the history.
  /// 
  /// If a transaction is in progress, the command is added to the transaction.
  /// Otherwise, it is executed immediately and added to the undo stack.
  /// The redo stack is cleared when a new command is executed outside of
  /// undo/redo operations.
  void executeCommand(Command command) {
    if (_inTransaction) {
      _transactionCommands.add(command);
      command.execute();
    } else {
      _addToHistory(command);
      command.execute();
      _notifyHistoryChanged();
    }
  }
  
  /// Adds a command to the history.
  /// 
  /// Attempts to merge the command with the last command if possible.
  /// Clears the redo stack and ensures the undo stack doesn't exceed
  /// the maximum history size.
  void _addToHistory(Command command) {
    // Try to merge with the last command if possible
    if (_undoStack.isNotEmpty) {
      final lastCommand = _undoStack.last;
      if (lastCommand.canMerge && command.canMerge) {
        final mergedCommand = lastCommand.mergeWith(command);
        if (mergedCommand != null) {
          _undoStack[_undoStack.length - 1] = mergedCommand;
          _clearRedoStack();
          return;
        }
      }
    }
    
    // Add the command to the undo stack
    _undoStack.add(command);
    
    // Ensure undo stack doesn't exceed max size
    if (_undoStack.length > maxHistorySize) {
      _undoStack.removeAt(0);
    }
    
    // Clear the redo stack
    _clearRedoStack();
  }
  
  /// Clears the redo stack.
  void _clearRedoStack() {
    _redoStack.clear();
  }
  
  /// Notifies listeners that the history has changed.
  void _notifyHistoryChanged() {
    _historyChangesController.add(null);
  }
  
  /// Undoes the last executed command.
  /// 
  /// Returns true if a command was undone, false if the undo stack was empty.
  bool undo() {
    if (!canUndo) return false;
    
    final command = _undoStack.removeLast();
    command.undo();
    _redoStack.add(command);
    _notifyHistoryChanged();
    return true;
  }
  
  /// Redoes the last undone command.
  /// 
  /// Returns true if a command was redone, false if the redo stack was empty.
  bool redo() {
    if (!canRedo) return false;
    
    final command = _redoStack.removeLast();
    command.execute();
    _undoStack.add(command);
    _notifyHistoryChanged();
    return true;
  }
  
  /// Begins a transaction.
  /// 
  /// Commands executed during a transaction are grouped together as a single
  /// undoable action. Transactions can be committed or rolled back.
  /// 
  /// Throws an exception if a transaction is already in progress.
  void beginTransaction() {
    if (_inTransaction) {
      throw StateError('Transaction already in progress');
    }
    _inTransaction = true;
    _transactionCommands.clear();
  }
  
  /// Commits the current transaction.
  /// 
  /// Groups all commands executed during the transaction into a single
  /// composite command and adds it to the history.
  /// 
  /// Throws an exception if no transaction is in progress.
  void commitTransaction(String description) {
    if (!_inTransaction) {
      throw StateError('No transaction in progress');
    }
    
    if (_transactionCommands.isNotEmpty) {
      final compositeCommand = CompositeCommand(
        List.from(_transactionCommands),
        description,
      );
      _addToHistory(compositeCommand);
    }
    
    _transactionCommands.clear();
    _inTransaction = false;
    _notifyHistoryChanged();
  }
  
  /// Rolls back the current transaction.
  /// 
  /// Undoes all commands executed during the transaction and discards them.
  /// 
  /// Throws an exception if no transaction is in progress.
  void rollbackTransaction() {
    if (!_inTransaction) {
      throw StateError('No transaction in progress');
    }
    
    // Undo commands in reverse order
    for (final command in _transactionCommands.reversed) {
      command.undo();
    }
    
    _transactionCommands.clear();
    _inTransaction = false;
    _notifyHistoryChanged();
  }
  
  /// Clears the entire command history.
  /// 
  /// This discards all undo and redo history.
  void clearHistory() {
    _undoStack.clear();
    _redoStack.clear();
    _notifyHistoryChanged();
  }
  
  /// Disposes the history manager.
  /// 
  /// This closes the history changes stream.
  void dispose() {
    _historyChangesController.close();
  }
}

/// Extension methods for executing commands with a HistoryManager.
extension HistoryCommandExtension on HistoryManager {
  /// Updates a property value with an undoable command.
  void updateProperty<T>(String elementId, String propertyName, T oldValue, T newValue, Function(String, String, T) updateFunction) {
    final command = PropertyChangeCommand<T>(
      elementId,
      propertyName,
      oldValue,
      newValue,
      updateFunction,
    );
    executeCommand(command);
  }
  
  /// Moves an element with an undoable command.
  void moveElement(String elementId, Offset oldPosition, Offset newPosition, Function(String, Offset) updateFunction) {
    final command = MoveElementCommand(
      elementId,
      oldPosition,
      newPosition,
      updateFunction,
    );
    executeCommand(command);
  }
  
  /// Adds an element with an undoable command.
  void addElement(String elementId, Function(String) addFunction, Function(String) removeFunction) {
    final command = AddElementCommand(
      elementId,
      addFunction,
      removeFunction,
    );
    executeCommand(command);
  }
  
  /// Removes an element with an undoable command.
  void removeElement(String elementId, Function(String) removeFunction, Function(String) addFunction) {
    final command = RemoveElementCommand(
      elementId,
      removeFunction,
      addFunction,
    );
    executeCommand(command);
  }
  
  /// Adds a relationship with an undoable command.
  void addRelationship(
    String relationshipId, 
    String sourceId, 
    String destinationId, 
    Function(String, String, String) addFunction, 
    Function(String) removeFunction
  ) {
    final command = AddRelationshipCommand(
      relationshipId,
      sourceId,
      destinationId,
      addFunction,
      removeFunction,
    );
    executeCommand(command);
  }
  
  /// Removes a relationship with an undoable command.
  void removeRelationship(
    String relationshipId, 
    String sourceId, 
    String destinationId, 
    Function(String) removeFunction, 
    Function(String, String, String) addFunction
  ) {
    final command = RemoveRelationshipCommand(
      relationshipId,
      sourceId,
      destinationId,
      removeFunction,
      addFunction,
    );
    executeCommand(command);
  }
}