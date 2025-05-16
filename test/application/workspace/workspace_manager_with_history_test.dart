import 'package:flutter_structurizr/application/workspace/workspace_manager.dart';
import 'package:flutter_structurizr/application/workspace/workspace_manager_with_history.dart';
import 'package:flutter_structurizr/domain/model/person.dart';
import 'package:flutter_structurizr/domain/model/software_system.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class MockWorkspaceManager extends Mock implements WorkspaceManager {
  @override
  Map<String, Workspace> get loadedWorkspaces => _workspaces;
  
  final Map<String, Workspace> _workspaces = {};
  
  @override
  void updateWorkspace(String path, Workspace workspace) {
    _workspaces[path] = workspace;
  }
}

void main() {
  late MockWorkspaceManager mockWorkspaceManager;
  late WorkspaceManagerWithHistory workspaceManagerWithHistory;
  late Workspace testWorkspace;
  
  const String testPath = '/test/workspace.json';
  
  setUp(() {
    mockWorkspaceManager = MockWorkspaceManager();
    workspaceManagerWithHistory = WorkspaceManagerWithHistory(mockWorkspaceManager);
    testWorkspace = Workspace(
      id: 1,
      name: 'Test Workspace',
      model: const Model(
        people: [],
        softwareSystems: [],
        deploymentEnvironments: [],
      ),
    );
    
    mockWorkspaceManager.updateWorkspace(testPath, testWorkspace);
  });
  
  group('WorkspaceManagerWithHistory', () {
    test('can perform undo/redo operations', () {
      // First update (change name)
      final updatedWorkspace1 = testWorkspace.copyWith(name: 'Updated Workspace');
      workspaceManagerWithHistory.updateWorkspace(testPath, updatedWorkspace1);
      
      // Second update (add a person)
      final person = Person(id: 'person1', name: 'Test Person');
      final updatedModel = updatedWorkspace1.model.copyWith(
        people: [person],
      );
      final updatedWorkspace2 = updatedWorkspace1.updateModel(updatedModel);
      workspaceManagerWithHistory.updateWorkspace(testPath, updatedWorkspace2);
      
      // Verify current state
      expect(mockWorkspaceManager.loadedWorkspaces[testPath]?.name, equals('Updated Workspace'));
      expect(mockWorkspaceManager.loadedWorkspaces[testPath]?.model.people.length, equals(1));
      
      // Undo the second operation (adding a person)
      bool undoResult = workspaceManagerWithHistory.undo(testPath);
      expect(undoResult, isTrue);
      expect(mockWorkspaceManager.loadedWorkspaces[testPath]?.name, equals('Updated Workspace'));
      expect(mockWorkspaceManager.loadedWorkspaces[testPath]?.model.people.length, equals(0));
      
      // Undo the first operation (changing name)
      undoResult = workspaceManagerWithHistory.undo(testPath);
      expect(undoResult, isTrue);
      expect(mockWorkspaceManager.loadedWorkspaces[testPath]?.name, equals('Test Workspace'));
      
      // Cannot undo further
      undoResult = workspaceManagerWithHistory.undo(testPath);
      expect(undoResult, isFalse);
      
      // Redo the first operation (changing name)
      bool redoResult = workspaceManagerWithHistory.redo(testPath);
      expect(redoResult, isTrue);
      expect(mockWorkspaceManager.loadedWorkspaces[testPath]?.name, equals('Updated Workspace'));
      
      // Redo the second operation (adding a person)
      redoResult = workspaceManagerWithHistory.redo(testPath);
      expect(redoResult, isTrue);
      expect(mockWorkspaceManager.loadedWorkspaces[testPath]?.model.people.length, equals(1));
      
      // Cannot redo further
      redoResult = workspaceManagerWithHistory.redo(testPath);
      expect(redoResult, isFalse);
    });
    
    test('can clear history', () {
      // Add some operations
      final updatedWorkspace1 = testWorkspace.copyWith(name: 'Updated Workspace');
      workspaceManagerWithHistory.updateWorkspace(testPath, updatedWorkspace1);
      
      // Verify we can undo
      expect(workspaceManagerWithHistory.canUndo(testPath), isTrue);
      
      // Clear history
      workspaceManagerWithHistory.clearHistory(testPath);
      
      // Verify we can no longer undo
      expect(workspaceManagerWithHistory.canUndo(testPath), isFalse);
    });
    
    test('provides command descriptions', () {
      // Add some operations
      final updatedWorkspace1 = testWorkspace.copyWith(name: 'Updated Workspace');
      workspaceManagerWithHistory.updateWorkspace(testPath, updatedWorkspace1);
      
      // Add a person
      final person = Person(id: 'person1', name: 'Test Person');
      workspaceManagerWithHistory.addPerson(testPath, person);
      
      // Verify undo descriptions
      expect(workspaceManagerWithHistory.undoDescriptions(testPath).length, equals(2));
      expect(workspaceManagerWithHistory.undoDescriptions(testPath)[0], contains('person'));
      expect(workspaceManagerWithHistory.undoDescriptions(testPath)[1], contains('workspace'));
      
      // Undo one operation
      workspaceManagerWithHistory.undo(testPath);
      
      // Verify redo descriptions
      expect(workspaceManagerWithHistory.redoDescriptions(testPath).length, equals(1));
      expect(workspaceManagerWithHistory.redoDescriptions(testPath)[0], contains('person'));
    });
    
    test('supports transactions for grouping operations', () {
      // Begin a transaction
      workspaceManagerWithHistory.beginTransaction(testPath);
      
      // Update name
      final updatedWorkspace1 = testWorkspace.copyWith(name: 'Updated Workspace');
      workspaceManagerWithHistory.updateWorkspace(testPath, updatedWorkspace1);
      
      // Add a person
      final person = Person(id: 'person1', name: 'Test Person');
      final updatedModel = updatedWorkspace1.model.copyWith(
        people: [person],
      );
      final updatedWorkspace2 = updatedWorkspace1.updateModel(updatedModel);
      workspaceManagerWithHistory.updateWorkspace(testPath, updatedWorkspace2);
      
      // Commit transaction
      workspaceManagerWithHistory.commitTransaction(testPath, 'Multiple Updates');
      
      // Verify the current state
      expect(mockWorkspaceManager.loadedWorkspaces[testPath]?.name, equals('Updated Workspace'));
      expect(mockWorkspaceManager.loadedWorkspaces[testPath]?.model.people.length, equals(1));
      
      // Undo the transaction (should undo both operations)
      bool undoResult = workspaceManagerWithHistory.undo(testPath);
      expect(undoResult, isTrue);
      
      // Verify both operations were undone
      expect(mockWorkspaceManager.loadedWorkspaces[testPath]?.name, equals('Test Workspace'));
      expect(mockWorkspaceManager.loadedWorkspaces[testPath]?.model.people.length, equals(0));
      
      // Redo the transaction (should redo both operations)
      bool redoResult = workspaceManagerWithHistory.redo(testPath);
      expect(redoResult, isTrue);
      
      // Verify both operations were redone
      expect(mockWorkspaceManager.loadedWorkspaces[testPath]?.name, equals('Updated Workspace'));
      expect(mockWorkspaceManager.loadedWorkspaces[testPath]?.model.people.length, equals(1));
    });
    
    test('can rollback a transaction', () {
      // Begin a transaction
      workspaceManagerWithHistory.beginTransaction(testPath);
      
      // Update name
      final updatedWorkspace1 = testWorkspace.copyWith(name: 'Updated Workspace');
      workspaceManagerWithHistory.updateWorkspace(testPath, updatedWorkspace1);
      
      // Add a person
      final person = Person(id: 'person1', name: 'Test Person');
      final updatedModel = updatedWorkspace1.model.copyWith(
        people: [person],
      );
      final updatedWorkspace2 = updatedWorkspace1.updateModel(updatedModel);
      workspaceManagerWithHistory.updateWorkspace(testPath, updatedWorkspace2);
      
      // Verify changes have been applied
      expect(mockWorkspaceManager.loadedWorkspaces[testPath]?.name, equals('Updated Workspace'));
      expect(mockWorkspaceManager.loadedWorkspaces[testPath]?.model.people.length, equals(1));
      
      // Rollback transaction
      workspaceManagerWithHistory.rollbackTransaction(testPath);
      
      // Verify changes were undone
      expect(mockWorkspaceManager.loadedWorkspaces[testPath]?.name, equals('Test Workspace'));
      expect(mockWorkspaceManager.loadedWorkspaces[testPath]?.model.people.length, equals(0));
      
      // Verify no history was added
      expect(workspaceManagerWithHistory.canUndo(testPath), isFalse);
    });
    
    test('forwards delegate methods to underlying manager', () {
      // Create a mock workspace metadata
      final metadata = WorkspaceMetadata(
        path: testPath,
        name: 'Test Workspace',
        description: 'Test Description',
        lastModified: DateTime.now(),
      );
      
      // Set up the mock to return a workspace when openWorkspace is called
      when(mockWorkspaceManager.openWorkspace(testPath))
          .thenAnswer((_) => Future.value(testWorkspace));
      
      // Call the method
      final future = workspaceManagerWithHistory.openWorkspace(testPath);
      
      // Verify the call was forwarded
      verify(mockWorkspaceManager.openWorkspace(testPath)).called(1);
      
      // Verify the result
      expect(future, completion(equals(testWorkspace)));
    });
  });
}