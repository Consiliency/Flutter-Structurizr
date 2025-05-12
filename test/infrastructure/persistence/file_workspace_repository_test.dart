import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/application/workspace/workspace_repository.dart';
import 'package:flutter_structurizr/infrastructure/persistence/file_workspace_repository.dart';
import 'package:path/path.dart' as path;

void main() {
  // Temporary directories for tests
  late Directory tempDir;
  late Directory workspacesDir;
  late FileWorkspaceRepository repository;
  
  setUp(() async {
    // Create temporary directories for tests
    tempDir = await Directory.systemTemp.createTemp('flutter_structurizr_test_');
    workspacesDir = Directory(path.join(tempDir.path, 'workspaces'));
    
    await workspacesDir.create();
    
    // Create the repository
    repository = FileWorkspaceRepository(workspacesDirectory: workspacesDir.path);
  });
  
  tearDown(() async {
    // Clean up temporary directories
    await tempDir.delete(recursive: true);
  });
  
  group('FileWorkspaceRepository', () {
    test('should save and load workspace', () async {
      // Create a simple workspace
      final workspace = Workspace(
        id: 1,
        name: 'Test Workspace',
        description: 'Test description',
        model: const Model(),
      );
      
      // Path to save the workspace
      final workspacePath = path.join(workspacesDir.path, 'test-workspace.json');
      
      // Save the workspace
      await repository.saveWorkspace(workspace, workspacePath);
      
      // Verify the file exists
      expect(await File(workspacePath).exists(), isTrue);
      
      // Load the workspace
      final loadedWorkspace = await repository.loadWorkspace(workspacePath);
      
      // Verify the loaded workspace matches the original
      expect(loadedWorkspace.id, workspace.id);
      expect(loadedWorkspace.name, workspace.name);
      expect(loadedWorkspace.description, workspace.description);
    });
    
    test('should throw when loading non-existent workspace', () async {
      // Path to a non-existent workspace
      final workspacePath = path.join(workspacesDir.path, 'non-existent.json');
      
      // Attempting to load should throw
      expect(
        () => repository.loadWorkspace(workspacePath),
        throwsA(isA<WorkspaceException>().having(
          (e) => e.message,
          'message',
          contains('does not exist'),
        )),
      );
    });
    
    test('should list workspaces', () async {
      // Create some test workspaces
      for (var i = 1; i <= 3; i++) {
        final workspace = Workspace(
          id: i,
          name: 'Workspace $i',
          description: 'Description $i',
          model: const Model(),
        );
        
        final workspacePath = path.join(workspacesDir.path, 'workspace-$i.json');
        await repository.saveWorkspace(workspace, workspacePath);
      }
      
      // List workspaces
      final workspaces = await repository.listWorkspaces();
      
      // Should have 3 workspaces
      expect(workspaces.length, 3);
      
      // Should be sorted by last modified (newest first)
      for (var i = 0; i < workspaces.length - 1; i++) {
        expect(
          workspaces[i].lastModified.isAfter(workspaces[i + 1].lastModified) ||
          workspaces[i].lastModified.isAtSameMomentAs(workspaces[i + 1].lastModified),
          isTrue,
        );
      }
      
      // Verify workspace metadata
      for (final metadata in workspaces) {
        expect(metadata.name, matches(r'Workspace \d'));
        expect(metadata.description, matches(r'Description \d'));
      }
    });
    
    test('should check if workspace exists', () async {
      // Path to a workspace
      final workspacePath = path.join(workspacesDir.path, 'exists-test.json');
      
      // Should not exist yet
      expect(await repository.workspaceExists(workspacePath), isFalse);
      
      // Create a workspace
      final workspace = Workspace(
        id: 1,
        name: 'Exists Test',
        description: 'Testing exists',
        model: const Model(),
      );
      
      await repository.saveWorkspace(workspace, workspacePath);
      
      // Should exist now
      expect(await repository.workspaceExists(workspacePath), isTrue);
    });
    
    test('should create workspace with metadata', () async {
      // Create workspace metadata
      final metadata = WorkspaceMetadata(
        path: path.join(workspacesDir.path, 'created-workspace.json'),
        name: 'Created Workspace',
        description: 'Created from metadata',
        lastModified: DateTime.now(),
      );
      
      // Create the workspace
      final workspace = await repository.createWorkspace(metadata);
      
      // Verify workspace properties
      expect(workspace.name, metadata.name);
      expect(workspace.description, metadata.description);
      
      // Verify file exists
      expect(await File(metadata.path).exists(), isTrue);
      
      // Load and verify
      final loadedWorkspace = await repository.loadWorkspace(metadata.path);
      expect(loadedWorkspace.name, metadata.name);
      expect(loadedWorkspace.description, metadata.description);
    });
    
    test('should delete workspace', () async {
      // Create a workspace
      final workspace = Workspace(
        id: 1,
        name: 'Delete Test',
        description: 'Testing deletion',
        model: const Model(),
      );
      
      final workspacePath = path.join(workspacesDir.path, 'delete-test.json');
      await repository.saveWorkspace(workspace, workspacePath);
      
      // Verify file exists
      expect(await File(workspacePath).exists(), isTrue);
      
      // Delete the workspace
      await repository.deleteWorkspace(workspacePath);
      
      // Verify file no longer exists
      expect(await File(workspacePath).exists(), isFalse);
    });
    
    test('should handle unsupported file formats', () async {
      // Create a workspace
      final workspace = Workspace(
        id: 1,
        name: 'Unsupported Format Test',
        description: 'Testing unsupported format',
        model: const Model(),
      );
      
      final workspacePath = path.join(workspacesDir.path, 'test.unsupported');
      
      // Attempting to save with unsupported format should throw
      expect(
        () => repository.saveWorkspace(workspace, workspacePath),
        throwsA(isA<WorkspaceException>().having(
          (e) => e.message,
          'message',
          contains('Unsupported file format'),
        )),
      );
    });
  });
}