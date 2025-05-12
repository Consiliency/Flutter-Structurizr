import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/application/workspace/workspace_repository.dart';
import 'package:flutter_structurizr/infrastructure/persistence/file_storage.dart';
import 'package:path/path.dart' as path;

void main() {
  // Temporary directories for tests
  late Directory tempDir;
  late Directory workspacesDir;
  late Directory backupDir;
  late FileStorage fileStorage;
  
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
  });
  
  tearDown(() async {
    // Clean up temporary directories
    await tempDir.delete(recursive: true);
  });
  
  group('FileStorage', () {
    test('should save and load workspace', () async {
      // Create a simple workspace
      final workspace = Workspace(
        id: 1,
        name: 'Test Workspace',
        description: 'Test workspace description',
        model: const Model(),
      );
      
      // Save the workspace
      final workspacePath = path.join(workspacesDir.path, 'test-workspace.json');
      await fileStorage.saveWorkspace(workspace, workspacePath);
      
      // Check that the file exists
      expect(File(workspacePath).exists(), completion(isTrue));
      
      // Load the workspace
      final loadedWorkspace = await fileStorage.loadWorkspace(workspacePath);
      
      // Verify the loaded workspace matches the original
      expect(loadedWorkspace.id, workspace.id);
      expect(loadedWorkspace.name, workspace.name);
      expect(loadedWorkspace.description, workspace.description);
    });
    
    test('should create and manage backups', () async {
      // Create a workspace
      final workspace = Workspace(
        id: 1,
        name: 'Test Workspace',
        description: 'Initial version',
        model: const Model(),
      );
      
      // Save the workspace
      final workspacePath = path.join(workspacesDir.path, 'backup-test.json');
      await fileStorage.saveWorkspace(workspace, workspacePath);
      
      // Modify and save again several times to create backups
      for (var i = 0; i < 5; i++) {
        // Wait a bit to ensure different timestamps
        await Future.delayed(const Duration(milliseconds: 100));
        
        final updatedWorkspace = Workspace(
          id: 1,
          name: 'Test Workspace',
          description: 'Version ${i + 1}',
          model: const Model(),
        );
        
        await fileStorage.saveWorkspace(updatedWorkspace, workspacePath);
      }
      
      // List backups
      final backups = await fileStorage.listBackups(workspacePath);
      
      // Should have maxBackups backups (3 in this case)
      expect(backups.length, fileStorage.maxBackups);
      
      // Verify backups are sorted newest first
      for (var i = 0; i < backups.length - 1; i++) {
        expect(backups[i].timestamp.isAfter(backups[i + 1].timestamp), isTrue);
      }
      
      // Restore from the newest backup
      final restoredWorkspace = await fileStorage.restoreFromBackup(backups.first);
      
      // Verify the restored workspace
      expect(restoredWorkspace.id, 1);
      expect(restoredWorkspace.name, 'Test Workspace');
      expect(restoredWorkspace.description, 'Version 4'); // Second-to-last version
    });
    
    test('should report progress during save and load', () async {
      // Create a workspace
      final workspace = Workspace(
        id: 1,
        name: 'Test Workspace',
        description: 'Test workspace description',
        model: const Model(),
      );
      
      final workspacePath = path.join(workspacesDir.path, 'progress-test.json');
      
      // Track progress during save
      final saveProgress = <double>[];
      await fileStorage.saveWorkspace(
        workspace,
        workspacePath,
        onProgress: (progress) => saveProgress.add(progress),
      );
      
      // Verify save progress reporting
      expect(saveProgress, isNotEmpty);
      expect(saveProgress.first, 0.0);
      expect(saveProgress.last, 1.0);
      
      // Track progress during load
      final loadProgress = <double>[];
      await fileStorage.loadWorkspace(
        workspacePath,
        onProgress: (progress) => loadProgress.add(progress),
      );
      
      // Verify load progress reporting
      expect(loadProgress, isNotEmpty);
      expect(loadProgress.first, 0.0);
      expect(loadProgress.last, 1.0);
    });
    
    test('should handle errors gracefully', () async {
      // Test loading a non-existent file
      final nonExistentPath = path.join(workspacesDir.path, 'does-not-exist.json');
      expect(
        () => fileStorage.loadWorkspace(nonExistentPath),
        throwsA(isA<WorkspaceException>()),
      );
      
      // Test loading an invalid file
      final invalidPath = path.join(workspacesDir.path, 'invalid.json');
      await File(invalidPath).writeAsString('not valid json');
      
      expect(
        () => fileStorage.loadWorkspace(invalidPath),
        throwsA(isA<WorkspaceException>()),
      );
      
      // Test loading an unsupported format
      final unsupportedPath = path.join(workspacesDir.path, 'unsupported.txt');
      final workspace = Workspace(
        id: 1,
        name: 'Test Workspace',
        description: 'Test workspace description',
        model: const Model(),
      );
      
      expect(
        () => fileStorage.saveWorkspace(workspace, unsupportedPath),
        throwsA(isA<WorkspaceException>()),
      );
    });
    
    test('should list workspaces', () async {
      // Create a few workspaces
      for (var i = 0; i < 3; i++) {
        final workspace = Workspace(
          id: i,
          name: 'Workspace $i',
          description: 'Description $i',
          model: const Model(),
        );
        
        await fileStorage.saveWorkspace(
          workspace,
          path.join(workspacesDir.path, 'workspace-$i.json'),
        );
        
        // Wait a bit to ensure different timestamps
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      // List workspaces
      final workspaces = await fileStorage.listWorkspaces();
      
      // Should have 3 workspaces
      expect(workspaces.length, 3);
      
      // Verify workspaces are sorted by last modified, newest first
      for (var i = 0; i < workspaces.length - 1; i++) {
        expect(
          workspaces[i].lastModified.isAfter(workspaces[i + 1].lastModified),
          isTrue,
        );
      }
      
      // Verify workspace metadata
      for (final metadata in workspaces) {
        expect(metadata.name, contains('Workspace'));
        expect(metadata.description, contains('Description'));
        expect(metadata.path, contains('workspace-'));
      }
    });
    
    test('should delete workspace and its backups', () async {
      // Create a workspace and some backups
      final workspace = Workspace(
        id: 1,
        name: 'Delete Test',
        description: 'Initial version',
        model: const Model(),
      );
      
      final workspacePath = path.join(workspacesDir.path, 'delete-test.json');
      
      // Save multiple versions to create backups
      for (var i = 0; i < 3; i++) {
        final updatedWorkspace = Workspace(
          id: 1,
          name: 'Delete Test',
          description: 'Version $i',
          model: const Model(),
        );
        
        await fileStorage.saveWorkspace(updatedWorkspace, workspacePath);
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      // Verify backups exist
      expect(await fileStorage.listBackups(workspacePath), isNotEmpty);
      
      // Delete the workspace and its backups
      await fileStorage.deleteWorkspace(workspacePath, deleteBackups: true);
      
      // Verify workspace file is gone
      expect(await File(workspacePath).exists(), isFalse);
      
      // Verify backups are gone
      expect(await fileStorage.listBackups(workspacePath), isEmpty);
    });
  });
}