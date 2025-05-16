import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/application/command/command.dart';
import 'package:flutter_structurizr/application/command/history_manager.dart';
import 'package:flutter_structurizr/presentation/widgets/history/history_toolbar.dart';

void main() {
  group('HistoryToolbar Widget Tests', () {
    testWidgets('should render undo and redo buttons', (WidgetTester tester) async {
      // Arrange
      final historyManager = HistoryManager();
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryToolbar(
              historyManager: historyManager,
            ),
          ),
        ),
      );
      
      // Assert
      expect(find.byIcon(Icons.undo), findsOneWidget);
      expect(find.byIcon(Icons.redo), findsOneWidget);
      expect(find.text('Undo'), findsNothing); // Labels are hidden by default
      expect(find.text('Redo'), findsNothing);
    });
    
    testWidgets('should show labels when showLabels is true', (WidgetTester tester) async {
      // Arrange
      final historyManager = HistoryManager();
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryToolbar(
              historyManager: historyManager,
              showLabels: true,
            ),
          ),
        ),
      );
      
      // Assert
      expect(find.text('Undo'), findsOneWidget);
      expect(find.text('Redo'), findsOneWidget);
    });
    
    testWidgets('should disable undo button when canUndo is false', (WidgetTester tester) async {
      // Arrange
      final historyManager = HistoryManager();
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryToolbar(
              historyManager: historyManager,
              showLabels: true,
            ),
          ),
        ),
      );
      
      // Assert
      final undoIcon = tester.widget<Icon>(find.byIcon(Icons.undo));
      expect(undoIcon.color, Colors.black38); // Disabled color
      
      // Tap the button and verify it doesn't change the state
      await tester.tap(find.byIcon(Icons.undo));
      await tester.pump();
      expect(historyManager.canUndo, false);
    });
    
    testWidgets('should enable undo button when canUndo is true', (WidgetTester tester) async {
      // Arrange
      final historyManager = HistoryManager();
      historyManager.executeCommand(
        TestCommand(
          execute: () {},
          undo: () {},
          description: 'Test Command',
        ),
      );
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryToolbar(
              historyManager: historyManager,
              showLabels: true,
            ),
          ),
        ),
      );
      
      // Assert
      final undoIcon = tester.widget<Icon>(find.byIcon(Icons.undo));
      expect(undoIcon.color, Colors.black87); // Enabled color
      
      // Tap the button and verify it triggers undo
      await tester.tap(find.byIcon(Icons.undo));
      await tester.pump();
      expect(historyManager.canUndo, false);
      expect(historyManager.canRedo, true);
    });
    
    testWidgets('should disable redo button when canRedo is false', (WidgetTester tester) async {
      // Arrange
      final historyManager = HistoryManager();
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryToolbar(
              historyManager: historyManager,
              showLabels: true,
            ),
          ),
        ),
      );
      
      // Assert
      final redoIcon = tester.widget<Icon>(find.byIcon(Icons.redo));
      expect(redoIcon.color, Colors.black38); // Disabled color
      
      // Tap the button and verify it doesn't change the state
      await tester.tap(find.byIcon(Icons.redo));
      await tester.pump();
      expect(historyManager.canRedo, false);
    });
    
    testWidgets('should enable redo button when canRedo is true', (WidgetTester tester) async {
      // Arrange
      final historyManager = HistoryManager();
      historyManager.executeCommand(
        TestCommand(
          execute: () {},
          undo: () {},
          description: 'Test Command',
        ),
      );
      historyManager.undo();
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryToolbar(
              historyManager: historyManager,
              showLabels: true,
            ),
          ),
        ),
      );
      
      // Assert
      final redoIcon = tester.widget<Icon>(find.byIcon(Icons.redo));
      expect(redoIcon.color, Colors.black87); // Enabled color
      
      // Tap the button and verify it triggers redo
      await tester.tap(find.byIcon(Icons.redo));
      await tester.pump();
      expect(historyManager.canUndo, true);
      expect(historyManager.canRedo, false);
    });
    
    testWidgets('should update when history changes', (WidgetTester tester) async {
      // Arrange
      final historyManager = HistoryManager();
      
      // Act - Initial state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryToolbar(
              historyManager: historyManager,
              showLabels: true,
            ),
          ),
        ),
      );
      
      // Assert - Both buttons should be disabled
      final undoIcon1 = tester.widget<Icon>(find.byIcon(Icons.undo));
      final redoIcon1 = tester.widget<Icon>(find.byIcon(Icons.redo));
      expect(undoIcon1.color, Colors.black38);
      expect(redoIcon1.color, Colors.black38);
      
      // Act - Execute a command
      historyManager.executeCommand(
        TestCommand(
          execute: () {},
          undo: () {},
          description: 'Test Command',
        ),
      );
      await tester.pump();
      
      // Assert - Undo should be enabled, redo should be disabled
      final undoIcon2 = tester.widget<Icon>(find.byIcon(Icons.undo));
      final redoIcon2 = tester.widget<Icon>(find.byIcon(Icons.redo));
      expect(undoIcon2.color, Colors.black87);
      expect(redoIcon2.color, Colors.black38);
      
      // Act - Undo the command
      historyManager.undo();
      await tester.pump();
      
      // Assert - Undo should be disabled, redo should be enabled
      final undoIcon3 = tester.widget<Icon>(find.byIcon(Icons.undo));
      final redoIcon3 = tester.widget<Icon>(find.byIcon(Icons.redo));
      expect(undoIcon3.color, Colors.black38);
      expect(redoIcon3.color, Colors.black87);
    });
  });
  
  group('HistoryKeyboardShortcuts Widget Tests', () {
    testWidgets('should trigger undo on Ctrl+Z', (WidgetTester tester) async {
      // Arrange
      final historyManager = HistoryManager();
      bool undoTriggered = false;
      
      historyManager.executeCommand(
        TestCommand(
          execute: () {},
          undo: () {
            undoTriggered = true;
          },
          description: 'Test Command',
        ),
      );
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryKeyboardShortcuts(
              historyManager: historyManager,
              child: const SizedBox(height: 100, width: 100),
            ),
          ),
        ),
      );
      
      // Send Ctrl+Z key event
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump();
      
      // Assert
      expect(undoTriggered, true);
      expect(historyManager.canUndo, false);
      expect(historyManager.canRedo, true);
    });
    
    testWidgets('should trigger redo on Ctrl+Y', (WidgetTester tester) async {
      // Arrange
      final historyManager = HistoryManager();
      bool redoTriggered = false;
      
      historyManager.executeCommand(
        TestCommand(
          execute: () {
            redoTriggered = true;
          },
          undo: () {},
          description: 'Test Command',
        ),
      );
      historyManager.undo();
      redoTriggered = false; // Reset after initial execution
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryKeyboardShortcuts(
              historyManager: historyManager,
              child: const SizedBox(height: 100, width: 100),
            ),
          ),
        ),
      );
      
      // Send Ctrl+Y key event
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyY);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyY);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump();
      
      // Assert
      expect(redoTriggered, true);
      expect(historyManager.canUndo, true);
      expect(historyManager.canRedo, false);
    });
    
    testWidgets('should trigger redo on Ctrl+Shift+Z', (WidgetTester tester) async {
      // Arrange
      final historyManager = HistoryManager();
      bool redoTriggered = false;
      
      historyManager.executeCommand(
        TestCommand(
          execute: () {
            redoTriggered = true;
          },
          undo: () {},
          description: 'Test Command',
        ),
      );
      historyManager.undo();
      redoTriggered = false; // Reset after initial execution
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryKeyboardShortcuts(
              historyManager: historyManager,
              child: const SizedBox(height: 100, width: 100),
            ),
          ),
        ),
      );
      
      // Send Ctrl+Shift+Z key event
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump();
      
      // Assert
      expect(redoTriggered, true);
      expect(historyManager.canUndo, true);
      expect(historyManager.canRedo, false);
    });
    
    testWidgets('should not trigger undo when canUndo is false', (WidgetTester tester) async {
      // Arrange
      final historyManager = HistoryManager();
      bool undoTriggered = false;
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryKeyboardShortcuts(
              historyManager: historyManager,
              child: const SizedBox(height: 100, width: 100),
            ),
          ),
        ),
      );
      
      // Send Ctrl+Z key event
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump();
      
      // Assert
      expect(undoTriggered, false);
      expect(historyManager.canUndo, false);
      expect(historyManager.canRedo, false);
    });
    
    testWidgets('should not trigger redo when canRedo is false', (WidgetTester tester) async {
      // Arrange
      final historyManager = HistoryManager();
      bool redoTriggered = false;
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryKeyboardShortcuts(
              historyManager: historyManager,
              child: const SizedBox(height: 100, width: 100),
            ),
          ),
        ),
      );
      
      // Send Ctrl+Y key event
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyY);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyY);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump();
      
      // Assert
      expect(redoTriggered, false);
      expect(historyManager.canUndo, false);
      expect(historyManager.canRedo, false);
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