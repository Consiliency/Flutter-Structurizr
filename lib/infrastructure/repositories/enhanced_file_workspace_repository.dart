import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../domain/model/workspace.dart';
import '../../application/workspace/workspace_directory_manager.dart';
import '../../infrastructure/persistence/workspace_persistence_service.dart';
import '../preferences/app_preferences.dart';

class EnhancedFileWorkspaceRepository {
  static EnhancedFileWorkspaceRepository? _instance;
  static EnhancedFileWorkspaceRepository get instance =>
      _instance ??= EnhancedFileWorkspaceRepository._();

  EnhancedFileWorkspaceRepository._();

  final WorkspaceDirectoryManager _directoryManager =
      WorkspaceDirectoryManager.instance;
  final WorkspacePersistenceService _persistenceService =
      WorkspacePersistenceService.instance;

  /// Save workspace with automatic directory management
  Future<WorkspaceSaveResult> saveWorkspace(
    Workspace workspace, {
    String? customPath,
    bool createBackup = true,
    WorkspaceFormat format = WorkspaceFormat.json,
  }) async {
    try {
      String savePath;

      if (customPath != null) {
        savePath = customPath;
      } else {
        // Use workspace directory manager to get appropriate path
        final workspaceDir =
            await _directoryManager.getCurrentWorkspaceDirectory();
        final fileName = _generateFileName(workspace.name, format);
        savePath = _combinePath(workspaceDir, fileName);
      }

      // Ensure directory exists
      final directory = File(savePath).parent;
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Save using persistence service
      final result = await _persistenceService.saveWorkspace(
        workspace,
        savePath,
        createBackup: createBackup,
        format: format,
      );

      // Update preferences if successful
      if (result.success) {
        await AppPreferences.instance.setLastOpenWorkspace(savePath);

        // Add to workspace history
        final historyEntry = WorkspaceHistoryEntry(
          filePath: savePath,
          workspaceName: workspace.name,
          lastOpened: DateTime.now(),
          fileType: format == WorkspaceFormat.dsl ? 'dsl' : 'json',
          fileSize: result.fileSize,
        );
        await AppPreferences.instance.addToWorkspaceHistory(historyEntry);
      }

      return result;
    } catch (e) {
      return WorkspaceSaveResult(
        success: false,
        filePath: customPath ?? 'unknown',
        error: e.toString(),
        format: format,
      );
    }
  }

  /// Load workspace with automatic path resolution
  Future<WorkspaceLoadResult> loadWorkspace(String filePath) async {
    try {
      // Validate file exists
      if (!await _persistenceService.workspaceExists(filePath)) {
        return WorkspaceLoadResult(
          success: false,
          filePath: filePath,
          error: 'Workspace file not found: $filePath',
        );
      }

      // Load using persistence service
      final result = await _persistenceService.loadWorkspace(filePath);

      // Update preferences if successful
      if (result.success) {
        await AppPreferences.instance.setLastOpenWorkspace(filePath);

        // Add to workspace history
        if (result.workspace != null) {
          final historyEntry = WorkspaceHistoryEntry(
            filePath: filePath,
            workspaceName: result.workspace!.name,
            lastOpened: DateTime.now(),
            fileType: result.format?.name ?? 'json',
            fileSize: result.fileSize,
          );
          await AppPreferences.instance.addToWorkspaceHistory(historyEntry);
        }
      }

      return result;
    } catch (e) {
      return WorkspaceLoadResult(
        success: false,
        filePath: filePath,
        error: e.toString(),
      );
    }
  }

  /// Get last opened workspace
  Future<WorkspaceLoadResult?> loadLastWorkspace() async {
    try {
      final lastPath = await AppPreferences.instance.getLastOpenWorkspace();
      if (lastPath == null) return null;

      if (await _persistenceService.workspaceExists(lastPath)) {
        return await loadWorkspace(lastPath);
      } else {
        // Clean up invalid path from preferences
        await AppPreferences.instance.setLastOpenWorkspace(null);
        return null;
      }
    } catch (e) {
      debugPrint('Error loading last workspace: $e');
      return null;
    }
  }

  /// List all workspaces in current directory
  Future<List<WorkspaceFileInfo>> listWorkspaces() async {
    try {
      final workspaceDir =
          await _directoryManager.getCurrentWorkspaceDirectory();
      return await _persistenceService.listWorkspaceFiles(workspaceDir);
    } catch (e) {
      debugPrint('Error listing workspaces: $e');
      return [];
    }
  }

  /// Get workspace history
  Future<List<WorkspaceHistoryEntry>> getWorkspaceHistory() async {
    try {
      return await AppPreferences.instance.getWorkspaceHistory();
    } catch (e) {
      debugPrint('Error getting workspace history: $e');
      return [];
    }
  }

  /// Delete workspace
  Future<bool> deleteWorkspace(String filePath) async {
    try {
      return await _persistenceService.deleteWorkspace(filePath);
    } catch (e) {
      debugPrint('Error deleting workspace: $e');
      return false;
    }
  }

  /// Create workspace backup
  Future<String?> createBackup(String filePath) async {
    try {
      return await _persistenceService.createWorkspaceBackup(filePath);
    } catch (e) {
      debugPrint('Error creating backup: $e');
      return null;
    }
  }

  /// Restore workspace from backup
  Future<bool> restoreFromBackup(String backupPath, String targetPath) async {
    try {
      return await _persistenceService.restoreWorkspaceFromBackup(
          backupPath, targetPath);
    } catch (e) {
      debugPrint('Error restoring from backup: $e');
      return false;
    }
  }

  /// Get workspace metadata
  Future<WorkspaceMetadata?> getWorkspaceMetadata(String filePath) async {
    try {
      return await _persistenceService.getWorkspaceMetadata(filePath);
    } catch (e) {
      debugPrint('Error getting workspace metadata: $e');
      return null;
    }
  }

  /// Validate workspace file
  Future<WorkspaceValidationResult> validateWorkspace(String filePath) async {
    try {
      return await _persistenceService.validateWorkspaceFile(filePath);
    } catch (e) {
      return WorkspaceValidationResult(
        isValid: false,
        issues: ['Validation error: $e'],
      );
    }
  }

  /// Change workspace directory
  Future<bool> changeWorkspaceDirectory(String newDirectoryPath) async {
    try {
      await _directoryManager.setWorkspaceDirectory(newDirectoryPath);
      return true;
    } catch (e) {
      debugPrint('Error changing workspace directory: $e');
      return false;
    }
  }

  /// Get current workspace directory
  Future<String> getCurrentWorkspaceDirectory() async {
    return await _directoryManager.getCurrentWorkspaceDirectory();
  }

  /// Get platform storage information
  Future<PlatformStorageInfo> getStorageInfo() async {
    return await _directoryManager.getStorageInfo();
  }

  /// Import workspace from external location
  Future<WorkspaceSaveResult> importWorkspace(
    String sourcePath,
    String? targetName, {
    WorkspaceFormat? targetFormat,
  }) async {
    try {
      // Load workspace from source
      final loadResult = await _persistenceService.loadWorkspace(sourcePath);
      if (!loadResult.success || loadResult.workspace == null) {
        return WorkspaceSaveResult(
          success: false,
          filePath: sourcePath,
          error: 'Failed to load source workspace: ${loadResult.error}',
          format: targetFormat ?? WorkspaceFormat.json,
        );
      }

      // Create new workspace with updated name if provided
      final workspace = targetName != null
          ? loadResult.workspace!.copyWith(name: targetName)
          : loadResult.workspace!;

      // Save to workspace directory
      return await saveWorkspace(
        workspace,
        format: targetFormat ?? loadResult.format ?? WorkspaceFormat.json,
      );
    } catch (e) {
      return WorkspaceSaveResult(
        success: false,
        filePath: sourcePath,
        error: 'Import error: $e',
        format: targetFormat ?? WorkspaceFormat.json,
      );
    }
  }

  /// Export workspace to external location
  Future<WorkspaceSaveResult> exportWorkspace(
    Workspace workspace,
    String targetPath, {
    WorkspaceFormat format = WorkspaceFormat.json,
    bool createBackup = false,
  }) async {
    try {
      return await _persistenceService.saveWorkspace(
        workspace,
        targetPath,
        createBackup: createBackup,
        format: format,
      );
    } catch (e) {
      return WorkspaceSaveResult(
        success: false,
        filePath: targetPath,
        error: 'Export error: $e',
        format: format,
      );
    }
  }

  /// Clean up old backups
  Future<void> cleanupOldBackups(String filePath, {int keepCount = 5}) async {
    try {
      await _persistenceService.cleanupOldBackups(filePath,
          keepCount: keepCount);
    } catch (e) {
      debugPrint('Error cleaning up old backups: $e');
    }
  }

  /// Get workspace statistics
  Future<WorkspaceRepositoryStatistics> getRepositoryStatistics() async {
    try {
      final workspaceDir =
          await _directoryManager.getCurrentWorkspaceDirectory();
      final workspaceFiles =
          await _persistenceService.listWorkspaceFiles(workspaceDir);
      final history = await AppPreferences.instance.getWorkspaceHistory();

      int totalSize = 0;
      DateTime? lastModified;
      final formatCounts = <WorkspaceFormat, int>{};

      for (final file in workspaceFiles) {
        totalSize += file.fileSize ?? 0;

        if (lastModified == null ||
            (file.lastModified != null &&
                file.lastModified!.isAfter(lastModified))) {
          lastModified = file.lastModified;
        }

        formatCounts[file.format] = (formatCounts[file.format] ?? 0) + 1;
      }

      return WorkspaceRepositoryStatistics(
        totalWorkspaces: workspaceFiles.length,
        totalSizeBytes: totalSize,
        lastModified: lastModified,
        workspaceDirectory: workspaceDir,
        formatCounts: formatCounts,
        historyCount: history.length,
      );
    } catch (e) {
      debugPrint('Error getting repository statistics: $e');
      return const WorkspaceRepositoryStatistics(
        totalWorkspaces: 0,
        totalSizeBytes: 0,
        lastModified: null,
        workspaceDirectory: 'unknown',
        formatCounts: {},
        historyCount: 0,
      );
    }
  }

  // Private helper methods

  String _generateFileName(String workspaceName, WorkspaceFormat format) {
    final sanitized = workspaceName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();

    final extension = format == WorkspaceFormat.dsl ? 'dsl' : 'json';
    return '$sanitized.$extension';
  }

  String _combinePath(String directory, String fileName) {
    if (kIsWeb) {
      return '$directory/$fileName';
    } else {
      final separator = Platform.isWindows ? '\\' : '/';
      return '$directory$separator$fileName';
    }
  }
}

/// Repository statistics
class WorkspaceRepositoryStatistics {
  final int totalWorkspaces;
  final int totalSizeBytes;
  final DateTime? lastModified;
  final String workspaceDirectory;
  final Map<WorkspaceFormat, int> formatCounts;
  final int historyCount;

  const WorkspaceRepositoryStatistics({
    required this.totalWorkspaces,
    required this.totalSizeBytes,
    this.lastModified,
    required this.workspaceDirectory,
    required this.formatCounts,
    required this.historyCount,
  });

  @override
  String toString() {
    return 'WorkspaceRepositoryStatistics(workspaces: $totalWorkspaces, '
        'size: ${(totalSizeBytes / 1024).toStringAsFixed(1)}KB, '
        'directory: $workspaceDirectory, history: $historyCount)';
  }
}
