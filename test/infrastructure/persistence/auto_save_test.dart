import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/infrastructure/persistence/file_storage.dart';
import 'package:flutter_structurizr/infrastructure/persistence/auto_save.dart';
import 'package:path/path.dart' as path;

void main() {
  // Temporary directories for tests
  late Directory tempDir;
  late Directory workspacesDir;
  late Directory backupDir;
  late FileStorage fileStorage;
  late AutoSave autoSave;
  
  setUp(() async {
    // Create temporary directories for tests
    tempDir = await Directory.systemTemp.createTemp('flutter_structurizr_test_');
    workspacesDir = Directory(path.join(tempDir.path, 'workspaces'));
    backupDir = Directory(path.join(tempDir.path, 'backups'));
    
    await workspacesDir.create();
    await backupDir.create();
    
    // Create the file storage
    fileStorage = FileStorage(
      workspacesDirectory: workspacesDir.path,
      backupDirectory: backupDir.path,
      maxBackups: 3,
    );
    
    // Create the auto-save with a short interval for testing
    autoSave = AutoSave(
      storage: fileStorage,
      intervalMs: 100, // 100ms for faster testing
      enabled: true,
    );
  });
  
  tearDown(() async {
    // Dispose of the auto-save
    autoSave.dispose();
    
    // Clean up temporary directories
    await tempDir.delete(recursive: true);
  });
  
  group('AutoSave', () {
    test('should automatically save workspace when changed', () async {
      // Create a simple workspace
      final workspace = Workspace(
        id: 1,
        name: 'Auto-Save Test',
        description: 'Initial version',
        model: const Model(),
      );
      
      // File to save to
      final workspacePath = path.join(workspacesDir.path, 'auto-save-test.json');
      
      // Start monitoring
      autoSave.startMonitoring(workspace, workspacePath);
      
      // File should not exist yet since we haven't changed the workspace
      await Future.delayed(const Duration(milliseconds: 200));
      expect(await File(workspacePath).exists(), isFalse);
      
      // Update the workspace
      final updatedWorkspace = Workspace(
        id: 1,
        name: 'Auto-Save Test',
        description: 'Updated version',
        model: const Model(),
      );
      
      autoSave.updateWorkspace(updatedWorkspace);
      
      // Wait for auto-save to kick in
      await Future.delayed(const Duration(milliseconds: 200));
      
      // File should now exist
      expect(await File(workspacePath).exists(), isTrue);
      
      // Load the file and check its contents
      final loadedWorkspace = await fileStorage.loadWorkspace(workspacePath);
      expect(loadedWorkspace.description, 'Updated version');
    });
    
    test('should toggle auto-save on and off', () async {
      // Create a workspace
      final workspace = Workspace(
        id: 1,
        name: 'Toggle Test',
        description: 'Initial version',
        model: const Model(),
      );
      
      final workspacePath = path.join(workspacesDir.path, 'toggle-test.json');
      
      // Start monitoring with auto-save enabled
      autoSave.startMonitoring(workspace, workspacePath);
      
      // Update the workspace
      final updatedWorkspace1 = Workspace(
        id: 1,
        name: 'Toggle Test',
        description: 'First update',
        model: const Model(),
      );
      
      autoSave.updateWorkspace(updatedWorkspace1);
      
      // Wait for auto-save
      await Future.delayed(const Duration(milliseconds: 200));
      expect(await File(workspacePath).exists(), isTrue);
      
      // Disable auto-save
      autoSave.setEnabled(false);
      
      // Update the workspace again
      final updatedWorkspace2 = Workspace(
        id: 1,
        name: 'Toggle Test',
        description: 'Second update',
        model: const Model(),
      );
      
      autoSave.updateWorkspace(updatedWorkspace2);
      
      // Wait to ensure auto-save doesn't kick in
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Load the file and check its contents - should still be the first update
      final loadedWorkspace = await fileStorage.loadWorkspace(workspacePath);
      expect(loadedWorkspace.description, 'First update');
      
      // Re-enable auto-save
      autoSave.setEnabled(true);
      
      // Wait for auto-save
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Now the file should have the second update
      final updatedLoadedWorkspace = await fileStorage.loadWorkspace(workspacePath);
      expect(updatedLoadedWorkspace.description, 'Second update');
    });
    
    test('should detect unsaved changes', () async {
      // Create a workspace
      final workspace = Workspace(
        id: 1,
        name: 'Unsaved Changes Test',
        description: 'Initial version',
        model: const Model(),
      );
      
      final workspacePath = path.join(workspacesDir.path, 'unsaved-test.json');
      
      // Start monitoring but disable auto-save
      autoSave.setEnabled(false);
      autoSave.startMonitoring(workspace, workspacePath);
      
      // Save manually
      await autoSave.saveNow();
      
      // No unsaved changes yet
      expect(autoSave.hasUnsavedChanges(), isFalse);
      
      // Update the workspace
      final updatedWorkspace = Workspace(
        id: 1,
        name: 'Unsaved Changes Test',
        description: 'Updated version',
        model: const Model(),
      );
      
      autoSave.updateWorkspace(updatedWorkspace);
      
      // Should have unsaved changes now
      expect(autoSave.hasUnsavedChanges(), isTrue);
      
      // Save manually
      await autoSave.saveNow();
      
      // No unsaved changes again
      expect(autoSave.hasUnsavedChanges(), isFalse);
    });
    
    test('should emit events during auto-save lifecycle', () async {
      // Create a workspace
      final workspace = Workspace(
        id: 1,
        name: 'Events Test',
        description: 'Initial version',
        model: const Model(),
      );
      
      final workspacePath = path.join(workspacesDir.path, 'events-test.json');
      
      // Track emitted events
      final events = <AutoSaveEventType>[];
      final subscription = autoSave.autoSaveEvents.listen((event) {
        events.add(event.type);
      });
      
      // Start monitoring
      autoSave.startMonitoring(workspace, workspacePath);

      // Wait a moment for events to be processed
      await Future.delayed(const Duration(milliseconds: 50));

      // Should have emitted a monitoring started event
      expect(events, contains(AutoSaveEventType.monitoringStarted));
      
      // Update the workspace
      final updatedWorkspace = Workspace(
        id: 1,
        name: 'Events Test',
        description: 'Updated version',
        model: const Model(),
      );

      autoSave.updateWorkspace(updatedWorkspace);

      // Wait a moment for events to be processed
      await Future.delayed(const Duration(milliseconds: 50));

      // Should have emitted a workspace updated event
      expect(events, contains(AutoSaveEventType.workspaceUpdated));
      
      // Wait for auto-save
      await Future.delayed(const Duration(milliseconds: 250));
      
      // Should have emitted saving started and completed events
      expect(events, contains(AutoSaveEventType.savingStarted));
      expect(events, contains(AutoSaveEventType.saveCompleted));
      
      // Test toggling enabled state
      autoSave.setEnabled(false);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(events, contains(AutoSaveEventType.disabled));

      autoSave.setEnabled(true);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(events, contains(AutoSaveEventType.enabled));

      // Test changing interval
      autoSave.setInterval(200);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(events, contains(AutoSaveEventType.intervalChanged));

      // Test stopping monitoring
      autoSave.stopMonitoring();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(events, contains(AutoSaveEventType.monitoringStopped));
      
      // Clean up subscription
      await subscription.cancel();
    });
    
    test('should handle failed saves gracefully', () async {
      // Create a workspace
      final workspace = Workspace(
        id: 1,
        name: 'Error Test',
        description: 'Initial version',
        model: const Model(),
      );
      
      // Use an invalid path that will cause an error
      final invalidPath = '///?/invalid/path/error-test.json';
      
      // Track emitted events
      final events = <AutoSaveEvent>[];
      final subscription = autoSave.autoSaveEvents.listen((event) {
        events.add(event);
      });
      
      // Start monitoring
      autoSave.startMonitoring(workspace, invalidPath);
      await Future.delayed(const Duration(milliseconds: 50));

      // Update the workspace
      final updatedWorkspace = Workspace(
        id: 1,
        name: 'Error Test',
        description: 'Updated version',
        model: const Model(),
      );

      autoSave.updateWorkspace(updatedWorkspace);
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Wait for auto-save to attempt and fail
      await Future.delayed(const Duration(milliseconds: 250));
      
      // Should have emitted a save failed event
      final failedEvent = events.firstWhere(
        (event) => event.type == AutoSaveEventType.saveFailed,
        orElse: () => throw StateError('Should have emitted a saveFailed event'),
      );
      
      expect(failedEvent.error, isNotNull);
      
      // Clean up subscription
      await subscription.cancel();
    });
    
    test('should save immediately when requested', () async {
      // Create a workspace
      final workspace = Workspace(
        id: 1,
        name: 'Immediate Save Test',
        description: 'Initial version',
        model: const Model(),
      );
      
      final workspacePath = path.join(workspacesDir.path, 'immediate-save-test.json');
      
      // Disable auto-save
      autoSave.setEnabled(false);
      
      // Start monitoring
      autoSave.startMonitoring(workspace, workspacePath);
      
      // Update the workspace
      final updatedWorkspace = Workspace(
        id: 1,
        name: 'Immediate Save Test',
        description: 'Updated version',
        model: const Model(),
      );
      
      autoSave.updateWorkspace(updatedWorkspace);
      
      // File should not exist yet
      expect(await File(workspacePath).exists(), isFalse);
      
      // Save immediately
      final saveResult = await autoSave.saveNow();
      expect(saveResult, isTrue);
      
      // File should now exist
      expect(await File(workspacePath).exists(), isTrue);
      
      // Load the file and check its contents
      final loadedWorkspace = await fileStorage.loadWorkspace(workspacePath);
      expect(loadedWorkspace.description, 'Updated version');
    });
  });
}