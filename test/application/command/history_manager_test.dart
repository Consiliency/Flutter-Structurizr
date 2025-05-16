import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/application/command/command.dart';
import 'package:flutter_structurizr/application/command/history_manager.dart';

void main() {
  group('HistoryManager Tests', () {
    late HistoryManager historyManager;
    
    setUp(() {
      historyManager = HistoryManager();
    });
    
    tearDown(() {
      historyManager.dispose();
    });
    
    test('should execute command', () {
      // Arrange
      int value = 0;
      final command = TestCommand(
        execute: () => value = 1,
        undo: () => value = 0,
        description: 'Test Command',
      );
      
      // Act
      historyManager.executeCommand(command);
      
      // Assert
      expect(value, 1);
      expect(historyManager.canUndo, true);
      expect(historyManager.canRedo, false);
      expect(historyManager.undoDescription, 'Test Command');
      expect(historyManager.redoDescription, null);
    });
    
    test('should undo command', () {
      // Arrange
      int value = 0;
      final command = TestCommand(
        execute: () => value = 1,
        undo: () => value = 0,
        description: 'Test Command',
      );
      historyManager.executeCommand(command);
      
      // Act
      final result = historyManager.undo();
      
      // Assert
      expect(result, true);
      expect(value, 0);
      expect(historyManager.canUndo, false);
      expect(historyManager.canRedo, true);
      expect(historyManager.undoDescription, null);
      expect(historyManager.redoDescription, 'Test Command');
    });
    
    test('should redo command', () {
      // Arrange
      int value = 0;
      final command = TestCommand(
        execute: () => value = 1,
        undo: () => value = 0,
        description: 'Test Command',
      );
      historyManager.executeCommand(command);
      historyManager.undo();
      
      // Act
      final result = historyManager.redo();
      
      // Assert
      expect(result, true);
      expect(value, 1);
      expect(historyManager.canUndo, true);
      expect(historyManager.canRedo, false);
      expect(historyManager.undoDescription, 'Test Command');
      expect(historyManager.redoDescription, null);
    });
    
    test('should return false when undoing with empty stack', () {
      // Act
      final result = historyManager.undo();
      
      // Assert
      expect(result, false);
      expect(historyManager.canUndo, false);
    });
    
    test('should return false when redoing with empty stack', () {
      // Act
      final result = historyManager.redo();
      
      // Assert
      expect(result, false);
      expect(historyManager.canRedo, false);
    });
    
    test('should clear redo stack when new command is executed', () {
      // Arrange
      int value = 0;
      final command1 = TestCommand(
        execute: () => value = 1,
        undo: () => value = 0,
        description: 'Command 1',
      );
      final command2 = TestCommand(
        execute: () => value = 2,
        undo: () => value = 1,
        description: 'Command 2',
      );
      historyManager.executeCommand(command1);
      historyManager.undo();
      
      // Act
      historyManager.executeCommand(command2);
      
      // Assert
      expect(value, 2);
      expect(historyManager.canUndo, true);
      expect(historyManager.canRedo, false);
      expect(historyManager.undoDescription, 'Command 2');
    });
    
    test('should limit history size', () {
      // Arrange
      int value = 0;
      final historyManager = HistoryManager(maxHistorySize: 2);
      
      // Act
      for (int i = 1; i <= 3; i++) {
        historyManager.executeCommand(TestCommand(
          execute: () => value = i,
          undo: () => value = i - 1,
          description: 'Command $i',
        ));
      }
      
      // Assert
      expect(historyManager.undoDescriptions.length, 2);
      expect(historyManager.undoDescriptions.first, 'Command 3');
      expect(historyManager.undoDescriptions.last, 'Command 2');
      
      // First undo should go back to 2
      historyManager.undo();
      expect(value, 2);
      
      // Second undo should go back to 1
      historyManager.undo();
      expect(value, 1);
      
      // No more undos available
      expect(historyManager.canUndo, false);
    });
    
    test('should handle transactions', () {
      // Arrange
      int value = 0;
      
      // Act
      historyManager.beginTransaction();
      
      historyManager.executeCommand(TestCommand(
        execute: () => value = 1,
        undo: () => value = 0,
        description: 'Command 1',
      ));
      
      historyManager.executeCommand(TestCommand(
        execute: () => value = 2,
        undo: () => value = 1,
        description: 'Command 2',
      ));
      
      historyManager.commitTransaction('Transaction');
      
      // Assert
      expect(value, 2);
      expect(historyManager.canUndo, true);
      expect(historyManager.undoDescription, 'Transaction');
      
      // Undo should revert both commands
      historyManager.undo();
      expect(value, 0);
    });
    
    test('should rollback transaction', () {
      // Arrange
      int value = 0;
      
      // Act
      historyManager.beginTransaction();
      
      historyManager.executeCommand(TestCommand(
        execute: () => value = 1,
        undo: () => value = 0,
        description: 'Command 1',
      ));
      
      historyManager.executeCommand(TestCommand(
        execute: () => value = 2,
        undo: () => value = 1,
        description: 'Command 2',
      ));
      
      historyManager.rollbackTransaction();
      
      // Assert
      expect(value, 0);
      expect(historyManager.canUndo, false);
    });
    
    test('should throw when beginning transaction while one is in progress', () {
      // Arrange
      historyManager.beginTransaction();
      
      // Act & Assert
      expect(() => historyManager.beginTransaction(), throwsStateError);
    });
    
    test('should throw when committing transaction while none is in progress', () {
      // Act & Assert
      expect(() => historyManager.commitTransaction('Test'), throwsStateError);
    });
    
    test('should throw when rolling back transaction while none is in progress', () {
      // Act & Assert
      expect(() => historyManager.rollbackTransaction(), throwsStateError);
    });
    
    test('should merge mergeable commands', () {
      // Arrange
      final values = <int>[0];
      
      final command1 = MergeableTestCommand(
        execute: () => values.add(1),
        undo: () => values.removeLast(),
        description: 'Command 1',
        value: 1,
      );
      
      final command2 = MergeableTestCommand(
        execute: () => values.add(2),
        undo: () => values.removeLast(),
        description: 'Command 2',
        value: 2,
      );
      
      // Act
      historyManager.executeCommand(command1);
      historyManager.executeCommand(command2);
      
      // Assert
      expect(values, [0, 2]);
      expect(historyManager.undoDescriptions.length, 1);
      expect(historyManager.undoDescription, 'Merged Command');
      
      // Undo should revert to the initial state
      historyManager.undo();
      expect(values, [0]);
    });
    
    test('should not merge non-mergeable commands', () {
      // Arrange
      int value1 = 0;
      int value2 = 0;
      
      final command1 = TestCommand(
        execute: () => value1 = 1,
        undo: () => value1 = 0,
        description: 'Command 1',
      );
      
      final command2 = TestCommand(
        execute: () => value2 = 2,
        undo: () => value2 = 0,
        description: 'Command 2',
      );
      
      // Act
      historyManager.executeCommand(command1);
      historyManager.executeCommand(command2);
      
      // Assert
      expect(historyManager.undoDescriptions.length, 2);
      
      // Undo should revert commands in reverse order
      historyManager.undo();
      expect(value2, 0);
      expect(value1, 1);
      
      historyManager.undo();
      expect(value1, 0);
    });
    
    test('should clear history', () {
      // Arrange
      int value = 0;
      historyManager.executeCommand(TestCommand(
        execute: () => value = 1,
        undo: () => value = 0,
        description: 'Command 1',
      ));
      
      // Act
      historyManager.clearHistory();
      
      // Assert
      expect(historyManager.canUndo, false);
      expect(historyManager.canRedo, false);
      expect(historyManager.undoDescriptions.isEmpty, true);
      expect(historyManager.redoDescriptions.isEmpty, true);
    });
    
    test('should notify listeners when history changes', () {
      // Arrange
      int notificationCount = 0;
      historyManager.historyChanges.listen((_) {
        notificationCount++;
      });
      
      // Act
      historyManager.executeCommand(TestCommand(
        execute: () {},
        undo: () {},
        description: 'Command 1',
      ));
      
      historyManager.undo();
      historyManager.redo();
      historyManager.clearHistory();
      
      // Assert
      expect(notificationCount, 4);
    });
  });
  
  group('HistoryCommandExtension Tests', () {
    late HistoryManager historyManager;
    
    setUp(() {
      historyManager = HistoryManager();
    });
    
    tearDown(() {
      historyManager.dispose();
    });
    
    test('should update property', () {
      // Arrange
      String elementName = 'Old Name';
      
      void updateFunction(String id, String property, String value) {
        if (id == 'element1' && property == 'name') {
          elementName = value;
        }
      }
      
      // Act
      historyManager.updateProperty<String>(
        'element1',
        'name',
        'Old Name',
        'New Name',
        updateFunction,
      );
      
      // Assert
      expect(elementName, 'New Name');
      expect(historyManager.canUndo, true);
      
      // Undo should revert the property
      historyManager.undo();
      expect(elementName, 'Old Name');
    });
    
    test('should move element', () {
      // Arrange
      Offset elementPosition = const Offset(0, 0);
      
      void updateFunction(String id, Offset newPosition) {
        if (id == 'element1') {
          elementPosition = newPosition;
        }
      }
      
      // Act
      historyManager.moveElement(
        'element1',
        const Offset(0, 0),
        const Offset(100, 100),
        updateFunction,
      );
      
      // Assert
      expect(elementPosition, const Offset(100, 100));
      expect(historyManager.canUndo, true);
      
      // Undo should revert the position
      historyManager.undo();
      expect(elementPosition, const Offset(0, 0));
    });
    
    test('should add element', () {
      // Arrange
      final elements = <String>[];
      
      void addFunction(String id) {
        elements.add(id);
      }
      
      void removeFunction(String id) {
        elements.remove(id);
      }
      
      // Act
      historyManager.addElement(
        'element1',
        addFunction,
        removeFunction,
      );
      
      // Assert
      expect(elements, ['element1']);
      expect(historyManager.canUndo, true);
      
      // Undo should remove the element
      historyManager.undo();
      expect(elements, isEmpty);
    });
    
    test('should remove element', () {
      // Arrange
      final elements = <String>['element1'];
      
      void removeFunction(String id) {
        elements.remove(id);
      }
      
      void addFunction(String id) {
        elements.add(id);
      }
      
      // Act
      historyManager.removeElement(
        'element1',
        removeFunction,
        addFunction,
      );
      
      // Assert
      expect(elements, isEmpty);
      expect(historyManager.canUndo, true);
      
      // Undo should add the element back
      historyManager.undo();
      expect(elements, ['element1']);
    });
    
    test('should add relationship', () {
      // Arrange
      final relationships = <String, Map<String, String>>{};
      
      void addFunction(String id, String sourceId, String destinationId) {
        relationships[id] = {
          'sourceId': sourceId,
          'destinationId': destinationId,
        };
      }
      
      void removeFunction(String id) {
        relationships.remove(id);
      }
      
      // Act
      historyManager.addRelationship(
        'rel1',
        'source1',
        'dest1',
        addFunction,
        removeFunction,
      );
      
      // Assert
      expect(relationships.keys, ['rel1']);
      expect(relationships['rel1'], {
        'sourceId': 'source1',
        'destinationId': 'dest1',
      });
      expect(historyManager.canUndo, true);
      
      // Undo should remove the relationship
      historyManager.undo();
      expect(relationships, isEmpty);
    });
    
    test('should remove relationship', () {
      // Arrange
      final relationships = <String, Map<String, String>>{
        'rel1': {
          'sourceId': 'source1',
          'destinationId': 'dest1',
        },
      };
      
      void removeFunction(String id) {
        relationships.remove(id);
      }
      
      void addFunction(String id, String sourceId, String destinationId) {
        relationships[id] = {
          'sourceId': sourceId,
          'destinationId': destinationId,
        };
      }
      
      // Act
      historyManager.removeRelationship(
        'rel1',
        'source1',
        'dest1',
        removeFunction,
        addFunction,
      );
      
      // Assert
      expect(relationships, isEmpty);
      expect(historyManager.canUndo, true);
      
      // Undo should add the relationship back
      historyManager.undo();
      expect(relationships.keys, ['rel1']);
    });
  });
}

/// A simple command for testing
class TestCommand implements Command {
  final Function() execute;
  final Function() undo;
  final String description;
  
  TestCommand({
    required this.execute,
    required this.undo,
    required this.description,
  });
  
  @override
  void execute() => this.execute();
  
  @override
  void undo() => this.undo();
  
  @override
  String get description => this.description;
}

/// A command that supports merging for testing
class MergeableTestCommand implements Command {
  final Function() execute;
  final Function() undo;
  final String description;
  final int value;
  
  MergeableTestCommand({
    required this.execute,
    required this.undo,
    required this.description,
    required this.value,
  });
  
  @override
  void execute() => this.execute();
  
  @override
  void undo() => this.undo();
  
  @override
  String get description => this.description;
  
  @override
  bool get canMerge => true;
  
  @override
  Command? mergeWith(Command other) {
    if (other is MergeableTestCommand) {
      return MergeableTestCommand(
        execute: other.execute,
        undo: this.undo,
        description: 'Merged Command',
        value: other.value,
      );
    }
    return null;
  }
}