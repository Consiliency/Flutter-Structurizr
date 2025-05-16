import 'package:flutter_structurizr/application/workspace/workspace_manager.dart';
import 'package:flutter_structurizr/application/workspace/workspace_manager_factory.dart';
import 'package:flutter_structurizr/application/workspace/workspace_manager_with_history.dart';
import 'package:flutter_structurizr/infrastructure/persistence/file_storage.dart';

/// Factory for creating WorkspaceManagerWithHistory instances.
class WorkspaceManagerWithHistoryFactory {
  /// Creates a new WorkspaceManagerWithHistory.
  /// 
  /// This factory creates a standard WorkspaceManager and wraps it with
  /// the WorkspaceManagerWithHistory to add undo/redo support.
  static WorkspaceManagerWithHistory create({
    FileStorage? fileStorage,
    int maxRecentWorkspaces = 10,
    StorageMode storageMode = StorageMode.file,
  }) {
    // Create the base workspace manager
    final workspaceManager = WorkspaceManagerFactory.create(
      fileStorage: fileStorage,
      maxRecentWorkspaces: maxRecentWorkspaces,
      storageMode: storageMode,
    );
    
    // Wrap it with history support
    return WorkspaceManagerWithHistory(workspaceManager);
  }
}