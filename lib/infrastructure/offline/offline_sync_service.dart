import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../cloud/cloud_storage_service.dart';

/// Offline capability service with sync conflict resolution
/// Manages offline workspace storage and synchronization when connectivity returns
class OfflineSyncService {
  final CloudStorageService? _cloudService;
  final String _offlineStoragePath;
  final String _conflictStoragePath;
  final Duration _syncTimeout;
  
  OfflineSyncService({
    CloudStorageService? cloudService,
    required String offlineStoragePath,
    Duration? syncTimeout,
  }) : _cloudService = cloudService,
       _offlineStoragePath = offlineStoragePath,
       _conflictStoragePath = path.join(offlineStoragePath, '.conflicts'),
       _syncTimeout = syncTimeout ?? const Duration(minutes: 5);

  /// Check if currently online and can sync with cloud
  Future<bool> isOnline() async {
    if (_cloudService == null) return false;
    
    try {
      return await _cloudService!.isAvailable();
    } catch (e) {
      return false;
    }
  }

  /// Save workspace offline with metadata
  Future<OfflineSaveResult> saveWorkspaceOffline(
    String workspaceId,
    String content,
    Map<String, dynamic> metadata,
  ) async {
    try {
      final workspaceDir = Directory(path.join(_offlineStoragePath, workspaceId));
      await workspaceDir.create(recursive: true);
      
      final contentFile = File(path.join(workspaceDir.path, 'workspace.dsl'));
      final metadataFile = File(path.join(workspaceDir.path, 'metadata.json'));
      
      // Save content and metadata
      await contentFile.writeAsString(content);
      
      final offlineMetadata = {
        ...metadata,
        'lastModified': DateTime.now().toIso8601String(),
        'offlineId': _generateOfflineId(),
        'conflictResolution': 'pending',
      };
      
      await metadataFile.writeAsString(json.encode(offlineMetadata));
      
      return OfflineSaveResult(
        success: true,
        offlineId: offlineMetadata['offlineId'],
        localPath: contentFile.path,
      );
    } catch (e) {
      return OfflineSaveResult(
        success: false,
        error: 'Failed to save offline: $e',
      );
    }
  }

  /// Load workspace from offline storage
  Future<OfflineLoadResult> loadWorkspaceOffline(String workspaceId) async {
    try {
      final workspaceDir = Directory(path.join(_offlineStoragePath, workspaceId));
      if (!await workspaceDir.exists()) {
        return OfflineLoadResult(
          success: false,
          error: 'Workspace not found offline: $workspaceId',
        );
      }
      
      final contentFile = File(path.join(workspaceDir.path, 'workspace.dsl'));
      final metadataFile = File(path.join(workspaceDir.path, 'metadata.json'));
      
      if (!await contentFile.exists()) {
        return OfflineLoadResult(
          success: false,
          error: 'Workspace content not found: $workspaceId',
        );
      }
      
      final content = await contentFile.readAsString();
      Map<String, dynamic> metadata = {};
      
      if (await metadataFile.exists()) {
        final metadataJson = await metadataFile.readAsString();
        metadata = json.decode(metadataJson);
      }
      
      return OfflineLoadResult(
        success: true,
        content: content,
        metadata: metadata,
        localPath: contentFile.path,
      );
    } catch (e) {
      return OfflineLoadResult(
        success: false,
        error: 'Failed to load offline workspace: $e',
      );
    }
  }

  /// List all offline workspaces
  Future<List<OfflineWorkspaceInfo>> listOfflineWorkspaces() async {
    final offlineDir = Directory(_offlineStoragePath);
    if (!await offlineDir.exists()) {
      return [];
    }
    
    final workspaces = <OfflineWorkspaceInfo>[];
    
    await for (final entity in offlineDir.list()) {
      if (entity is Directory) {
        final workspaceId = path.basename(entity.path);
        final metadataFile = File(path.join(entity.path, 'metadata.json'));
        
        Map<String, dynamic> metadata = {};
        if (await metadataFile.exists()) {
          try {
            final metadataJson = await metadataFile.readAsString();
            metadata = json.decode(metadataJson);
          } catch (e) {
            // Skip invalid metadata
            continue;
          }
        }
        
        final contentFile = File(path.join(entity.path, 'workspace.dsl'));
        final hasContent = await contentFile.exists();
        final contentSize = hasContent ? await contentFile.length() : 0;
        
        workspaces.add(OfflineWorkspaceInfo(
          workspaceId: workspaceId,
          name: metadata['name'] ?? workspaceId,
          lastModified: DateTime.tryParse(metadata['lastModified'] ?? '') ?? DateTime.now(),
          hasConflicts: await _hasConflicts(workspaceId),
          contentSize: contentSize,
          syncStatus: _parseSyncStatus(metadata['conflictResolution']),
        ));
      }
    }
    
    // Sort by last modified (newest first)
    workspaces.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    
    return workspaces;
  }

  /// Sync offline workspaces with cloud when online
  Future<OfflineSyncResult> syncWithCloud() async {
    if (_cloudService == null || !await isOnline()) {
      return OfflineSyncResult(
        success: false,
        error: 'No cloud service available or offline',
        syncedWorkspaces: [],
        conflicts: [],
      );
    }

    final offlineWorkspaces = await listOfflineWorkspaces();
    final syncedWorkspaces = <String>[];
    final conflicts = <SyncConflict>[];
    
    for (final workspace in offlineWorkspaces) {
      try {
        final syncResult = await _syncWorkspace(workspace.workspaceId);
        
        if (syncResult.success) {
          syncedWorkspaces.add(workspace.workspaceId);
        } else if (syncResult.hasConflict) {
          conflicts.add(syncResult.conflict!);
        }
      } catch (e) {
        conflicts.add(SyncConflict(
          workspaceId: workspace.workspaceId,
          type: ConflictType.error,
          localContent: '',
          remoteContent: '',
          error: 'Sync error: $e',
        ));
      }
    }
    
    return OfflineSyncResult(
      success: conflicts.isEmpty,
      syncedWorkspaces: syncedWorkspaces,
      conflicts: conflicts,
    );
  }

  /// Resolve a sync conflict with user choice
  Future<ConflictResolutionResult> resolveConflict(
    String workspaceId,
    ConflictResolution resolution,
    {String? mergedContent}
  ) async {
    try {
      final conflictFile = File(path.join(_conflictStoragePath, '$workspaceId.json'));
      
      if (!await conflictFile.exists()) {
        return ConflictResolutionResult(
          success: false,
          error: 'Conflict not found: $workspaceId',
        );
      }
      
      final conflictJson = await conflictFile.readAsString();
      final conflictData = json.decode(conflictJson);
      final conflict = SyncConflict.fromJson(conflictData);
      
      String finalContent;
      
      switch (resolution) {
        case ConflictResolution.useLocal:
          finalContent = conflict.localContent;
          break;
        case ConflictResolution.useRemote:
          finalContent = conflict.remoteContent;
          break;
        case ConflictResolution.useMerged:
          if (mergedContent == null) {
            return ConflictResolutionResult(
              success: false,
              error: 'Merged content required for merge resolution',
            );
          }
          finalContent = mergedContent;
          break;
      }
      
      // Save resolved content locally
      final saveResult = await saveWorkspaceOffline(
        workspaceId,
        finalContent,
        {'conflictResolution': 'resolved'},
      );
      
      if (!saveResult.success) {
        return ConflictResolutionResult(
          success: false,
          error: 'Failed to save resolved content: ${saveResult.error}',
        );
      }
      
      // Upload to cloud if online
      if (await isOnline() && _cloudService != null) {
        final uploadResult = await _cloudService!.uploadFile(
          saveResult.localPath!,
          '$workspaceId/workspace.dsl',
        );
        
        if (!uploadResult.success) {
          return ConflictResolutionResult(
            success: false,
            error: 'Failed to upload resolved content: ${uploadResult.error}',
          );
        }
      }
      
      // Remove conflict file
      await conflictFile.delete();
      
      return ConflictResolutionResult(
        success: true,
        resolvedContent: finalContent,
      );
    } catch (e) {
      return ConflictResolutionResult(
        success: false,
        error: 'Conflict resolution error: $e',
      );
    }
  }

  /// Generate a three-way merge for conflict resolution
  Future<MergeResult> generateThreeWayMerge(
    String workspaceId,
    String localContent,
    String remoteContent,
    String? baseContent,
  ) async {
    try {
      // Simple line-based three-way merge
      final localLines = localContent.split('\n');
      final remoteLines = remoteContent.split('\n');
      final baseLines = baseContent?.split('\n') ?? <String>[];
      
      final mergedLines = <String>[];
      final conflicts = <MergeConflict>[];
      
      int localIndex = 0;
      int remoteIndex = 0;
      int baseIndex = 0;
      
      while (localIndex < localLines.length || remoteIndex < remoteLines.length) {
        final localLine = localIndex < localLines.length ? localLines[localIndex] : null;
        final remoteLine = remoteIndex < remoteLines.length ? remoteLines[remoteIndex] : null;
        final baseLine = baseIndex < baseLines.length ? baseLines[baseIndex] : null;
        
        if (localLine == remoteLine) {
          // No conflict, both sides are the same
          if (localLine != null) {
            mergedLines.add(localLine);
          }
          localIndex++;
          remoteIndex++;
          baseIndex++;
        } else if (localLine == baseLine) {
          // Local unchanged, use remote
          if (remoteLine != null) {
            mergedLines.add(remoteLine);
          }
          localIndex++;
          remoteIndex++;
          baseIndex++;
        } else if (remoteLine == baseLine) {
          // Remote unchanged, use local
          if (localLine != null) {
            mergedLines.add(localLine);
          }
          localIndex++;
          remoteIndex++;
          baseIndex++;
        } else {
          // Conflict - both sides changed
          final conflictStart = mergedLines.length;
          
          mergedLines.add('<<<<<<< LOCAL');
          if (localLine != null) {
            mergedLines.add(localLine);
          }
          mergedLines.add('=======');
          if (remoteLine != null) {
            mergedLines.add(remoteLine);
          }
          mergedLines.add('>>>>>>> REMOTE');
          
          conflicts.add(MergeConflict(
            startLine: conflictStart,
            endLine: mergedLines.length - 1,
            localContent: localLine ?? '',
            remoteContent: remoteLine ?? '',
            baseContent: baseLine ?? '',
          ));
          
          localIndex++;
          remoteIndex++;
          baseIndex++;
        }
      }
      
      return MergeResult(
        success: true,
        mergedContent: mergedLines.join('\n'),
        conflicts: conflicts,
        hasConflicts: conflicts.isNotEmpty,
      );
    } catch (e) {
      return MergeResult(
        success: false,
        error: 'Merge error: $e',
        mergedContent: localContent,
        conflicts: [],
        hasConflicts: false,
      );
    }
  }

  /// Delete offline workspace
  Future<bool> deleteOfflineWorkspace(String workspaceId) async {
    try {
      final workspaceDir = Directory(path.join(_offlineStoragePath, workspaceId));
      if (await workspaceDir.exists()) {
        await workspaceDir.delete(recursive: true);
      }
      
      // Also delete any conflicts
      final conflictFile = File(path.join(_conflictStoragePath, '$workspaceId.json'));
      if (await conflictFile.exists()) {
        await conflictFile.delete();
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clear all offline data
  Future<bool> clearOfflineData() async {
    try {
      final offlineDir = Directory(_offlineStoragePath);
      if (await offlineDir.exists()) {
        await offlineDir.delete(recursive: true);
      }
      
      final conflictDir = Directory(_conflictStoragePath);
      if (await conflictDir.exists()) {
        await conflictDir.delete(recursive: true);
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Sync a single workspace with conflict detection
  Future<WorkspaceSyncResult> _syncWorkspace(String workspaceId) async {
    try {
      final localResult = await loadWorkspaceOffline(workspaceId);
      if (!localResult.success) {
        return WorkspaceSyncResult(
          success: false,
          error: localResult.error,
        );
      }
      
      // Try to get remote version
      final remoteInfo = await _cloudService!.getFileInfo('$workspaceId/workspace.dsl');
      
      if (remoteInfo == null) {
        // File doesn't exist remotely, upload local version
        final uploadResult = await _cloudService!.uploadFile(
          localResult.localPath!,
          '$workspaceId/workspace.dsl',
        );
        
        return WorkspaceSyncResult(
          success: uploadResult.success,
          error: uploadResult.error,
        );
      }
      
      // Check for conflicts
      final localModified = DateTime.tryParse(localResult.metadata['lastModified'] ?? '') ?? DateTime.now();
      final remoteModified = remoteInfo.modifiedTime;
      
      if (localModified.isAfter(remoteModified)) {
        // Local is newer, upload
        final uploadResult = await _cloudService!.uploadFile(
          localResult.localPath!,
          '$workspaceId/workspace.dsl',
        );
        
        return WorkspaceSyncResult(
          success: uploadResult.success,
          error: uploadResult.error,
        );
      } else if (remoteModified.isAfter(localModified)) {
        // Remote is newer, check for content differences
        final downloadResult = await _cloudService!.downloadFile(
          '$workspaceId/workspace.dsl',
          '${localResult.localPath!}.remote',
        );
        
        if (!downloadResult.success) {
          return WorkspaceSyncResult(
            success: false,
            error: downloadResult.error,
          );
        }
        
        final remoteContent = await File(downloadResult.localPath!).readAsString();
        
        if (remoteContent != localResult.content) {
          // Content conflict detected
          await _saveConflict(workspaceId, localResult.content!, remoteContent);
          
          return WorkspaceSyncResult(
            success: false,
            hasConflict: true,
            conflict: SyncConflict(
              workspaceId: workspaceId,
              type: ConflictType.contentDifference,
              localContent: localResult.content!,
              remoteContent: remoteContent,
            ),
          );
        } else {
          // Same content, just update local metadata
          await saveWorkspaceOffline(
            workspaceId,
            localResult.content!,
            {
              ...localResult.metadata,
              'lastModified': remoteModified.toIso8601String(),
            },
          );
          
          return WorkspaceSyncResult(success: true);
        }
      } else {
        // Same modification time, assume no sync needed
        return WorkspaceSyncResult(success: true);
      }
    } catch (e) {
      return WorkspaceSyncResult(
        success: false,
        error: 'Sync error: $e',
      );
    }
  }

  /// Save a conflict for later resolution
  Future<void> _saveConflict(String workspaceId, String localContent, String remoteContent) async {
    final conflictDir = Directory(_conflictStoragePath);
    await conflictDir.create(recursive: true);
    
    final conflict = SyncConflict(
      workspaceId: workspaceId,
      type: ConflictType.contentDifference,
      localContent: localContent,
      remoteContent: remoteContent,
      timestamp: DateTime.now(),
    );
    
    final conflictFile = File(path.join(_conflictStoragePath, '$workspaceId.json'));
    await conflictFile.writeAsString(json.encode(conflict.toJson()));
  }

  /// Check if a workspace has unresolved conflicts
  Future<bool> _hasConflicts(String workspaceId) async {
    final conflictFile = File(path.join(_conflictStoragePath, '$workspaceId.json'));
    return await conflictFile.exists();
  }

  /// Generate a unique offline ID
  String _generateOfflineId() {
    return 'offline_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 1000).toString().padLeft(3, '0')}';
  }

  /// Parse sync status from metadata
  SyncStatus _parseSyncStatus(dynamic status) {
    switch (status) {
      case 'resolved':
        return SyncStatus.synced;
      case 'pending':
        return SyncStatus.pendingSync;
      default:
        return SyncStatus.offline;
    }
  }
}

// Data classes for offline sync operations

class OfflineSaveResult {
  final bool success;
  final String? offlineId;
  final String? localPath;
  final String? error;

  OfflineSaveResult({
    required this.success,
    this.offlineId,
    this.localPath,
    this.error,
  });
}

class OfflineLoadResult {
  final bool success;
  final String? content;
  final Map<String, dynamic> metadata;
  final String? localPath;
  final String? error;

  OfflineLoadResult({
    required this.success,
    this.content,
    this.metadata = const {},
    this.localPath,
    this.error,
  });
}

class OfflineWorkspaceInfo {
  final String workspaceId;
  final String name;
  final DateTime lastModified;
  final bool hasConflicts;
  final int contentSize;
  final SyncStatus syncStatus;

  OfflineWorkspaceInfo({
    required this.workspaceId,
    required this.name,
    required this.lastModified,
    required this.hasConflicts,
    required this.contentSize,
    required this.syncStatus,
  });
}

class OfflineSyncResult {
  final bool success;
  final String? error;
  final List<String> syncedWorkspaces;
  final List<SyncConflict> conflicts;

  OfflineSyncResult({
    required this.success,
    this.error,
    required this.syncedWorkspaces,
    required this.conflicts,
  });
}

class WorkspaceSyncResult {
  final bool success;
  final String? error;
  final bool hasConflict;
  final SyncConflict? conflict;

  WorkspaceSyncResult({
    required this.success,
    this.error,
    this.hasConflict = false,
    this.conflict,
  });
}

class SyncConflict {
  final String workspaceId;
  final ConflictType type;
  final String localContent;
  final String remoteContent;
  final DateTime timestamp;
  final String? error;

  SyncConflict({
    required this.workspaceId,
    required this.type,
    required this.localContent,
    required this.remoteContent,
    DateTime? timestamp,
    this.error,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'workspaceId': workspaceId,
    'type': type.toString(),
    'localContent': localContent,
    'remoteContent': remoteContent,
    'timestamp': timestamp.toIso8601String(),
    'error': error,
  };

  static SyncConflict fromJson(Map<String, dynamic> json) => SyncConflict(
    workspaceId: json['workspaceId'],
    type: ConflictType.values.firstWhere((e) => e.toString() == json['type']),
    localContent: json['localContent'],
    remoteContent: json['remoteContent'],
    timestamp: DateTime.parse(json['timestamp']),
    error: json['error'],
  );
}

class ConflictResolutionResult {
  final bool success;
  final String? error;
  final String? resolvedContent;

  ConflictResolutionResult({
    required this.success,
    this.error,
    this.resolvedContent,
  });
}

class MergeResult {
  final bool success;
  final String? error;
  final String mergedContent;
  final List<MergeConflict> conflicts;
  final bool hasConflicts;

  MergeResult({
    required this.success,
    this.error,
    required this.mergedContent,
    required this.conflicts,
    required this.hasConflicts,
  });
}

class MergeConflict {
  final int startLine;
  final int endLine;
  final String localContent;
  final String remoteContent;
  final String baseContent;

  MergeConflict({
    required this.startLine,
    required this.endLine,
    required this.localContent,
    required this.remoteContent,
    required this.baseContent,
  });
}

enum ConflictType {
  contentDifference,
  timestampMismatch,
  error,
}

enum ConflictResolution {
  useLocal,
  useRemote,
  useMerged,
}

enum SyncStatus {
  offline,
  pendingSync,
  synced,
  conflict,
}