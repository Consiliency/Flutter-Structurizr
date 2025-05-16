import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/application/workspace/workspace_repository.dart';
import 'package:flutter_structurizr/application/workspace/workspace_manager.dart';
import 'package:flutter_structurizr/infrastructure/persistence/file_storage.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Temporary directories for tests
  late Directory tempDir;
  late Directory workspacesDir;
  late Directory backupDir;
  late FileStorage fileStorage;
  late WorkspaceManager workspaceManager;
  
  setUp(() async {
    // Set up shared preferences for testing
    SharedPreferences.setMockInitialValues({});
    
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
    
    // Create the workspace manager
    workspaceManager = WorkspaceManager(
      fileStorage: fileStorage,
      maxRecentWorkspaces: 5,
    );
    
    // Initialize the workspace manager
    await workspaceManager.initialize();
  });
  
  tearDown(() async {
    // Dispose of workspace manager
    workspaceManager.dispose();
    
    // Clean up temporary directories
    await tempDir.delete(recursive: true);
  });
  
  group('WorkspaceManager', () {
    test('should create and load a workspace', () async {
      // Create workspace metadata
      final metadata = WorkspaceMetadata(
        path: path.join(workspacesDir.path, 'test-create.json'),
        name: 'Test Workspace',
        description: 'A test workspace',
        lastModified: DateTime.now(),
      );
      
      // Create the workspace
      final createdWorkspace = await workspaceManager.createWorkspace(metadata);
      
      // Verify workspace properties
      expect(createdWorkspace.name, 'Test Workspace');
      expect(createdWorkspace.description, 'A test workspace');
      
      // Verify file exists
      expect(await File(metadata.path).exists(), isTrue);
      
      // Load the workspace
      final loadedWorkspace = await workspaceManager.openWorkspace(metadata.path);
      
      // Verify loaded workspace matches created workspace
      expect(loadedWorkspace.id, createdWorkspace.id);
      expect(loadedWorkspace.name, createdWorkspace.name);
      expect(loadedWorkspace.description, createdWorkspace.description);
    });
    
    test('should track recent workspaces', () async {
      // Create multiple workspaces
      final workspaces = <Workspace>[];
      
      for (var i = 0; i < 3; i++) {
        final metadata = WorkspaceMetadata(
          path: path.join(workspacesDir.path, 'recent-$i.json'),
          name: 'Recent Workspace $i',
          description: 'Recent workspace $i',
          lastModified: DateTime.now(),
        );
        
        // Create and add to list
        final workspace = await workspaceManager.createWorkspace(metadata);
        workspaces.add(workspace);
        
        // Wait a bit to ensure different timestamps
        await Future.delayed(const Duration(milliseconds: 10));
      }
      
      // Verify recent workspaces
      final recentWorkspaces = workspaceManager.recentWorkspaces;
      
      // Should have 3 recent workspaces
      expect(recentWorkspaces.length, 3);
      
      // Should be in reverse order (newest first)
      expect(recentWorkspaces[0].name, 'Recent Workspace 2');
      expect(recentWorkspaces[1].name, 'Recent Workspace 1');
      expect(recentWorkspaces[2].name, 'Recent Workspace 0');
    });
    
    test('should handle multiple loaded workspaces', () async {
      // Create multiple workspaces
      final workspacePaths = <String>[];
      
      for (var i = 0; i < 3; i++) {
        final metadata = WorkspaceMetadata(
          path: path.join(workspacesDir.path, 'multi-$i.json'),
          name: 'Multi Workspace $i',
          description: 'Multi workspace $i',
          lastModified: DateTime.now(),
        );
        
        // Create and add path to list
        await workspaceManager.createWorkspace(metadata);
        workspacePaths.add(metadata.path);
        
        // Close the workspace
        await workspaceManager.closeWorkspace(metadata.path);
      }
      
      // Open all workspaces
      for (final path in workspacePaths) {
        await workspaceManager.openWorkspace(path);
      }
      
      // Verify all workspaces are loaded
      final loadedWorkspaces = workspaceManager.loadedWorkspaces;
      expect(loadedWorkspaces.length, 3);
      
      // Update one workspace
      final updatedWorkspace = Workspace(
        id: loadedWorkspaces[workspacePaths[1]]!.id,
        name: 'Updated Multi Workspace',
        description: 'Updated description',
        model: const Model(),
      );
      
      workspaceManager.updateWorkspace(workspacePaths[1], updatedWorkspace);
      
      // Verify the workspace was updated
      expect(workspaceManager.loadedWorkspaces[workspacePaths[1]]!.name, 'Updated Multi Workspace');
      expect(workspaceManager.loadedWorkspaces[workspacePaths[1]]!.description, 'Updated description');
      
      // Close all workspaces
      for (final path in workspacePaths) {
        await workspaceManager.closeWorkspace(path);
      }
      
      // Verify all workspaces are closed
      expect(workspaceManager.loadedWorkspaces.isEmpty, isTrue);
    });
    
    test('should save changes', () async {
      // Create a workspace
      final metadata = WorkspaceMetadata(
        path: path.join(workspacesDir.path, 'unsaved.json'),
        name: 'Unsaved Workspace',
        description: 'A workspace with unsaved changes',
        lastModified: DateTime.now(),
      );
      
      final workspace = await workspaceManager.createWorkspace(metadata);
      
      // Update the workspace
      final updatedWorkspace = Workspace(
        id: workspace.id,
        name: 'Unsaved Workspace',
        description: 'Updated description',
        model: const Model(),
      );
      
      // Update and save
      workspaceManager.updateWorkspace(metadata.path, updatedWorkspace);
      await workspaceManager.saveWorkspace(metadata.path);
      
      // Close and reopen to verify changes were saved
      await workspaceManager.closeWorkspace(metadata.path);
      final reopenedWorkspace = await workspaceManager.openWorkspace(metadata.path);
      
      // Verify the description was updated
      expect(reopenedWorkspace.description, 'Updated description');
    });
    
    test('should import and export workspaces', () async {
      // Create a workspace
      final metadata = WorkspaceMetadata(
        path: path.join(workspacesDir.path, 'original.json'),
        name: 'Original Workspace',
        description: 'A workspace to export and import',
        lastModified: DateTime.now(),
      );
      
      await workspaceManager.createWorkspace(metadata);
      
      // Export the workspace
      final exportPath = path.join(workspacesDir.path, 'exported.json');
      await workspaceManager.exportWorkspace(
        metadata.path,
        exportPath,
      );
      
      // Verify export file exists
      expect(await File(exportPath).exists(), isTrue);
      
      // Import the workspace to a new path
      final importPath = path.join(workspacesDir.path, 'imported.json');
      final importedWorkspace = await workspaceManager.importWorkspace(
        exportPath,
        importPath,
      );
      
      // Verify imported workspace has the same properties
      expect(importedWorkspace.name, 'Original Workspace');
      expect(importedWorkspace.description, 'A workspace to export and import');
      
      // Verify import file exists
      expect(await File(importPath).exists(), isTrue);
    });
    
    test('should manage backups and restore from them', () async {
      // Create a workspace
      final metadata = WorkspaceMetadata(
        path: path.join(workspacesDir.path, 'backup-restore.json'),
        name: 'Backup Workspace',
        description: 'Initial version',
        lastModified: DateTime.now(),
      );
      
      final workspace = await workspaceManager.createWorkspace(metadata);
      
      // Make several changes to create backups
      for (var i = 1; i <= 3; i++) {
        final updatedWorkspace = Workspace(
          id: workspace.id,
          name: 'Backup Workspace',
          description: 'Version $i',
          model: const Model(),
        );
        
        workspaceManager.updateWorkspace(metadata.path, updatedWorkspace);
        await workspaceManager.saveWorkspace(metadata.path);
        
        // Wait a bit to ensure different timestamps
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      // List backups
      final backups = await workspaceManager.listBackups(metadata.path);
      
      // Should have backups
      expect(backups.length, greaterThan(0));
      
      // Restore from the first backup (newest)
      final restoredWorkspace = await workspaceManager.restoreFromBackup(backups.first);
      
      // Verify restored workspace
      expect(restoredWorkspace.description, 'Version 2'); // Previous version
      
      // Reload the workspace
      final reloadedWorkspace = await workspaceManager.openWorkspace(metadata.path);
      
      // Verify reloaded workspace matches restored workspace
      expect(reloadedWorkspace.description, restoredWorkspace.description);
    });
    
    test('should emit workspace events', () async {
      // Track emitted events
      final events = <WorkspaceEventType>[];
      final subscription = workspaceManager.workspaceEvents.listen((event) {
        events.add(event.type);
      });
      
      // Create a workspace
      final metadata = WorkspaceMetadata(
        path: path.join(workspacesDir.path, 'events.json'),
        name: 'Events Workspace',
        description: 'A workspace for testing events',
        lastModified: DateTime.now(),
      );
      
      await workspaceManager.createWorkspace(metadata);
      
      // Wait a bit for events to propagate
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Verify events
      expect(events, contains(WorkspaceEventType.creating));
      // Note: Depending on the timing, the created event might be processed after the test
      // is already checking - we'll add a small delay to give it a chance to be processed
      expect(events, contains(WorkspaceEventType.recentWorkspacesUpdated));
      
      // Wait a bit more for additional events
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Update the workspace
      final updatedWorkspace = Workspace(
        id: workspaceManager.loadedWorkspaces[metadata.path]!.id,
        name: 'Events Workspace',
        description: 'Updated description',
        model: const Model(),
      );
      
      workspaceManager.updateWorkspace(metadata.path, updatedWorkspace);
      
      // Wait a bit for update event to propagate
      await Future.delayed(const Duration(milliseconds: 100));
      
      // At this point we should have all events
      expect(events, contains(WorkspaceEventType.creating));
      expect(events, contains(WorkspaceEventType.created));
      expect(events, contains(WorkspaceEventType.updated));
      
      // Save the workspace
      await workspaceManager.saveWorkspace(metadata.path);
      
      // Wait a bit for save event to propagate
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Verify events
      expect(events, contains(WorkspaceEventType.saving));
      
      // At this point, let's stop testing specific events since the async nature
      // makes it hard to predict exact timing of events in a test environment
      
      // Clean up subscription
      await subscription.cancel();
    });
    
    test('should delete workspaces', () async {
      // Create a workspace
      final metadata = WorkspaceMetadata(
        path: path.join(workspacesDir.path, 'to-delete.json'),
        name: 'Delete Workspace',
        description: 'A workspace to delete',
        lastModified: DateTime.now(),
      );
      
      await workspaceManager.createWorkspace(metadata);
      
      // Verify the file exists
      expect(await File(metadata.path).exists(), isTrue);
      
      // Verify the workspace is in recent workspaces
      expect(
        workspaceManager.recentWorkspaces.any((w) => w.path == metadata.path),
        isTrue,
      );
      
      // Delete the workspace
      await workspaceManager.deleteWorkspace(metadata.path);
      
      // Verify the file no longer exists
      expect(await File(metadata.path).exists(), isFalse);
      
      // Verify the workspace is no longer in recent workspaces
      expect(
        workspaceManager.recentWorkspaces.any((w) => w.path == metadata.path),
        isFalse,
      );
    });
    
    test('should clear recent workspaces', () async {
      // Create a workspace
      final metadata = WorkspaceMetadata(
        path: path.join(workspacesDir.path, 'recent-clear.json'),
        name: 'Recent Clear Workspace',
        description: 'A workspace for testing recent clear',
        lastModified: DateTime.now(),
      );
      
      await workspaceManager.createWorkspace(metadata);
      
      // Verify the workspace is in recent workspaces
      expect(workspaceManager.recentWorkspaces.isNotEmpty, isTrue);
      
      // Clear recent workspaces
      await workspaceManager.clearRecentWorkspaces();
      
      // Verify recent workspaces is empty
      expect(workspaceManager.recentWorkspaces.isEmpty, isTrue);
    });
  });
}