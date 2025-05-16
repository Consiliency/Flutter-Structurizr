import 'package:flutter_structurizr/application/workspace/workspace_manager.dart';
import 'package:flutter_structurizr/infrastructure/persistence/file_storage.dart';
import 'package:flutter_structurizr/infrastructure/persistence/file_system_helper.dart';

/// Factory for creating [WorkspaceManager] instances.
class WorkspaceManagerFactory {
  /// Creates a [WorkspaceManager] with default settings.
  static Future<WorkspaceManager> createDefault() async {
    // Get default paths
    final workspacesPath = await FileSystemHelper.getDefaultWorkspacesPath();
    final backupsPath = await FileSystemHelper.getDefaultBackupsPath();
    
    // Ensure directories exist
    await FileSystemHelper.ensureDirectoryExists(workspacesPath);
    await FileSystemHelper.ensureDirectoryExists(backupsPath);
    
    // Create file storage
    final fileStorage = FileStorage(
      workspacesDirectory: workspacesPath,
      backupDirectory: backupsPath,
      maxBackups: 5,
    );
    
    // Create workspace manager
    final workspaceManager = WorkspaceManager(
      fileStorage: fileStorage,
      maxRecentWorkspaces: 10,
      storageMode: StorageMode.file,
    );
    
    // Initialize workspace manager
    await workspaceManager.initialize();
    
    return workspaceManager;
  }
  
  /// Creates a [WorkspaceManager] with custom settings.
  static Future<WorkspaceManager> createCustom({
    String? workspacesPath,
    String? backupsPath,
    int maxBackups = 5,
    int maxRecentWorkspaces = 10,
    StorageMode storageMode = StorageMode.file,
  }) async {
    // Get paths
    final resolvedWorkspacesPath = workspacesPath ?? 
        await FileSystemHelper.getDefaultWorkspacesPath();
    final resolvedBackupsPath = backupsPath ?? 
        await FileSystemHelper.getDefaultBackupsPath();
    
    // Ensure directories exist
    await FileSystemHelper.ensureDirectoryExists(resolvedWorkspacesPath);
    await FileSystemHelper.ensureDirectoryExists(resolvedBackupsPath);
    
    // Create file storage
    final fileStorage = FileStorage(
      workspacesDirectory: resolvedWorkspacesPath,
      backupDirectory: resolvedBackupsPath,
      maxBackups: maxBackups,
    );
    
    // Create workspace manager
    final workspaceManager = WorkspaceManager(
      fileStorage: fileStorage,
      maxRecentWorkspaces: maxRecentWorkspaces,
      storageMode: storageMode,
    );
    
    // Initialize workspace manager
    await workspaceManager.initialize();
    
    return workspaceManager;
  }
  
  /// Creates a [WorkspaceManager] for testing.
  static Future<WorkspaceManager> createForTesting({
    required String workspacesPath,
    required String backupsPath,
  }) async {
    // Ensure directories exist
    await FileSystemHelper.ensureDirectoryExists(workspacesPath);
    await FileSystemHelper.ensureDirectoryExists(backupsPath);
    
    // Create file storage
    final fileStorage = FileStorage(
      workspacesDirectory: workspacesPath,
      backupDirectory: backupsPath,
      maxBackups: 3,
    );
    
    // Create workspace manager
    final workspaceManager = WorkspaceManager(
      fileStorage: fileStorage,
      maxRecentWorkspaces: 5,
      storageMode: StorageMode.file,
    );
    
    // Initialize workspace manager
    await workspaceManager.initialize();
    
    return workspaceManager;
  }
}