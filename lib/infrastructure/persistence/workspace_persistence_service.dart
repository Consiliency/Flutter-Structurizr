import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../../domain/model/workspace.dart';
import '../preferences/app_preferences.dart';

class WorkspacePersistenceService {
  static WorkspacePersistenceService? _instance;
  static WorkspacePersistenceService get instance => _instance ??= WorkspacePersistenceService._();
  
  WorkspacePersistenceService._();
  
  static const String _metadataExtension = '.meta.json';
  static const String _backupExtension = '.backup';
  
  /// Save workspace to file
  Future<WorkspaceSaveResult> saveWorkspace(
    Workspace workspace,
    String filePath, {
    bool createBackup = true,
    WorkspaceFormat format = WorkspaceFormat.json,
  }) async {
    try {
      // Create backup if requested
      String? backupPath;
      if (createBackup && await File(filePath).exists()) {
        backupPath = await _createBackupFile(filePath);
      }
      
      // Ensure directory exists
      final directory = Directory(path.dirname(filePath));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      final startTime = DateTime.now();
      
      // Save workspace content
      await _saveWorkspaceContent(workspace, filePath, format);
      
      // Save metadata
      await _saveWorkspaceMetadata(workspace, filePath, format);
      
      final endTime = DateTime.now();
      final saveTime = endTime.difference(startTime);
      
      // Get file size
      final fileSize = await _getFileSize(filePath);
      
      return WorkspaceSaveResult(
        success: true,
        filePath: filePath,
        backupPath: backupPath,
        fileSize: fileSize,
        saveTime: saveTime,
        timestamp: endTime,
        format: format,
      );
      
    } catch (e) {
      debugPrint('Error saving workspace: $e');
      return WorkspaceSaveResult(
        success: false,
        filePath: filePath,
        error: e.toString(),
        format: format,
      );
    }
  }
  
  /// Load workspace from file
  Future<WorkspaceLoadResult> loadWorkspace(String filePath) async {
    try {
      // Check if file exists
      final file = File(filePath);
      if (!await file.exists()) {
        return WorkspaceLoadResult(
          success: false,
          filePath: filePath,
          error: 'File not found: $filePath',
        );
      }
      
      final startTime = DateTime.now();
      
      // Determine format from file extension
      final format = _getFormatFromPath(filePath);
      
      // Load workspace content
      final workspace = await _loadWorkspaceContent(filePath, format);
      
      // Load metadata if available
      final metadata = await _loadWorkspaceMetadata(filePath);
      
      final endTime = DateTime.now();
      final loadTime = endTime.difference(startTime);
      
      // Get file info
      final fileSize = await _getFileSize(filePath);
      final lastModified = await _getLastModified(filePath);
      
      return WorkspaceLoadResult(
        success: true,
        workspace: workspace,
        filePath: filePath,
        metadata: metadata,
        fileSize: fileSize,
        lastModified: lastModified,
        loadTime: loadTime,
        format: format,
      );
      
    } catch (e) {
      debugPrint('Error loading workspace: $e');
      return WorkspaceLoadResult(
        success: false,
        filePath: filePath,
        error: e.toString(),
      );
    }
  }
  
  /// Check if workspace file exists
  Future<bool> workspaceExists(String filePath) async {
    try {
      if (kIsWeb) {
        // Web implementation would check browser storage
        return false; // Placeholder
      } else {
        return await File(filePath).exists();
      }
    } catch (e) {
      return false;
    }
  }
  
  /// Delete workspace file and associated metadata
  Future<bool> deleteWorkspace(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
      
      // Delete metadata file
      final metadataPath = _getMetadataPath(filePath);
      final metadataFile = File(metadataPath);
      if (await metadataFile.exists()) {
        await metadataFile.delete();
      }
      
      // Remove from workspace history
      await AppPreferences.instance.removeFromWorkspaceHistory(filePath);
      
      return true;
    } catch (e) {
      debugPrint('Error deleting workspace: $e');
      return false;
    }
  }
  
  /// Get workspace metadata
  Future<WorkspaceMetadata?> getWorkspaceMetadata(String filePath) async {
    return await _loadWorkspaceMetadata(filePath);
  }
  
  /// Update workspace metadata
  Future<bool> updateWorkspaceMetadata(String filePath, WorkspaceMetadata metadata) async {
    try {
      final metadataPath = _getMetadataPath(filePath);
      final metadataJson = jsonEncode(metadata.toJson());
      await File(metadataPath).writeAsString(metadataJson);
      return true;
    } catch (e) {
      debugPrint('Error updating workspace metadata: $e');
      return false;
    }
  }
  
  /// List all workspace files in a directory
  Future<List<WorkspaceFileInfo>> listWorkspaceFiles(String directoryPath) async {
    final workspaceFiles = <WorkspaceFileInfo>[];
    
    try {
      if (kIsWeb) {
        // Web implementation would list from browser storage
        return workspaceFiles;
      }
      
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        return workspaceFiles;
      }
      
      await for (final entity in directory.list()) {
        if (entity is File) {
          final fileName = path.basename(entity.path);
          
          // Check if it's a workspace file
          if (_isWorkspaceFile(fileName)) {
            final format = _getFormatFromPath(entity.path);
            final fileSize = await _getFileSize(entity.path);
            final lastModified = await _getLastModified(entity.path);
            final metadata = await _loadWorkspaceMetadata(entity.path);
            
            workspaceFiles.add(WorkspaceFileInfo(
              filePath: entity.path,
              fileName: fileName,
              format: format,
              fileSize: fileSize,
              lastModified: lastModified,
              metadata: metadata,
            ));
          }
        }
      }
      
      // Sort by last modified (newest first)
      workspaceFiles.sort((a, b) => (b.lastModified ?? DateTime(0))
          .compareTo(a.lastModified ?? DateTime(0)));
      
    } catch (e) {
      debugPrint('Error listing workspace files: $e');
    }
    
    return workspaceFiles;
  }
  
  /// Create backup of workspace
  Future<String?> createWorkspaceBackup(String filePath) async {
    try {
      return await _createBackupFile(filePath);
    } catch (e) {
      debugPrint('Error creating workspace backup: $e');
      return null;
    }
  }
  
  /// Restore workspace from backup
  Future<bool> restoreWorkspaceFromBackup(String backupPath, String targetPath) async {
    try {
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        return false;
      }
      
      // Copy backup to target location
      await backupFile.copy(targetPath);
      
      // Also restore metadata if it exists
      final backupMetadataPath = _getMetadataPath(backupPath);
      final backupMetadataFile = File(backupMetadataPath);
      if (await backupMetadataFile.exists()) {
        final targetMetadataPath = _getMetadataPath(targetPath);
        await backupMetadataFile.copy(targetMetadataPath);
      }
      
      return true;
    } catch (e) {
      debugPrint('Error restoring workspace from backup: $e');
      return false;
    }
  }
  
  /// Get available backup files for a workspace
  Future<List<String>> getWorkspaceBackups(String filePath) async {
    final backups = <String>[];
    
    try {
      final directory = Directory(path.dirname(filePath));
      final baseName = path.basenameWithoutExtension(filePath);
      
      await for (final entity in directory.list()) {
        if (entity is File) {
          final fileName = path.basename(entity.path);
          if (fileName.startsWith('$baseName$_backupExtension')) {
            backups.add(entity.path);
          }
        }
      }
      
      // Sort by creation time (newest first)
      backups.sort((a, b) => b.compareTo(a));
      
    } catch (e) {
      debugPrint('Error getting workspace backups: $e');
    }
    
    return backups;
  }
  
  /// Clean up old backups (keep only specified number)
  Future<void> cleanupOldBackups(String filePath, {int keepCount = 5}) async {
    try {
      final backups = await getWorkspaceBackups(filePath);
      
      if (backups.length > keepCount) {
        final toDelete = backups.skip(keepCount);
        
        for (final backupPath in toDelete) {
          try {
            await File(backupPath).delete();
            // Also delete backup metadata if exists
            final metadataPath = _getMetadataPath(backupPath);
            final metadataFile = File(metadataPath);
            if (await metadataFile.exists()) {
              await metadataFile.delete();
            }
          } catch (e) {
            debugPrint('Error deleting backup $backupPath: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up old backups: $e');
    }
  }
  
  /// Validate workspace file integrity
  Future<WorkspaceValidationResult> validateWorkspaceFile(String filePath) async {
    final issues = <String>[];
    
    try {
      // Check if file exists
      if (!await File(filePath).exists()) {
        issues.add('File does not exist');
        return WorkspaceValidationResult(isValid: false, issues: issues);
      }
      
      // Check file size
      final fileSize = await _getFileSize(filePath);
      if (fileSize == 0) {
        issues.add('File is empty');
      }
      
      // Try to load workspace to check format
      final loadResult = await loadWorkspace(filePath);
      if (!loadResult.success) {
        issues.add('Invalid workspace format: ${loadResult.error}');
      } else {
        // Validate workspace content
        final workspace = loadResult.workspace!;
        
        if (workspace.name.isEmpty) {
          issues.add('Workspace name is empty');
        }
        
        if (workspace.model.people.isEmpty && 
            workspace.model.softwareSystems.isEmpty) {
          issues.add('Workspace contains no model elements');
        }
      }
      
      // Check metadata consistency
      final metadata = await _loadWorkspaceMetadata(filePath);
      if (metadata != null) {
        final actualSize = await _getFileSize(filePath);
        if (metadata.fileSize != null && metadata.fileSize != actualSize) {
          issues.add('Metadata file size mismatch');
        }
      }
      
    } catch (e) {
      issues.add('Validation error: $e');
    }
    
    return WorkspaceValidationResult(
      isValid: issues.isEmpty,
      issues: issues,
    );
  }
  
  // Private helper methods
  
  Future<void> _saveWorkspaceContent(Workspace workspace, String filePath, WorkspaceFormat format) async {
    switch (format) {
      case WorkspaceFormat.json:
        final jsonContent = jsonEncode(workspace.toJson());
        await File(filePath).writeAsString(jsonContent);
        break;
        
      case WorkspaceFormat.dsl:
        // DSL export would be implemented here
        // For now, save as JSON with .dsl extension
        final jsonContent = jsonEncode(workspace.toJson());
        await File(filePath).writeAsString(jsonContent);
        break;
    }
  }
  
  Future<Workspace> _loadWorkspaceContent(String filePath, WorkspaceFormat format) async {
    final content = await File(filePath).readAsString();
    
    switch (format) {
      case WorkspaceFormat.json:
        final jsonData = jsonDecode(content) as Map<String, dynamic>;
        return Workspace.fromJson(jsonData);
        
      case WorkspaceFormat.dsl:
        // DSL parsing would be implemented here
        // For now, try to parse as JSON
        try {
          final jsonData = jsonDecode(content) as Map<String, dynamic>;
          return Workspace.fromJson(jsonData);
        } catch (e) {
          throw Exception('DSL parsing not yet implemented');
        }
    }
  }
  
  Future<void> _saveWorkspaceMetadata(Workspace workspace, String filePath, WorkspaceFormat format) async {
    final metadata = WorkspaceMetadata(
      workspaceName: workspace.name,
      filePath: filePath,
      format: format,
      fileSize: await _getFileSize(filePath),
      lastModified: DateTime.now(),
      version: workspace.version ?? '1.0',
      description: workspace.description,
      createdDate: DateTime.now(),
      elementCount: _countElements(workspace),
      viewCount: _countViews(workspace),
    );
    
    final metadataPath = _getMetadataPath(filePath);
    final metadataJson = jsonEncode(metadata.toJson());
    await File(metadataPath).writeAsString(metadataJson);
  }
  
  Future<WorkspaceMetadata?> _loadWorkspaceMetadata(String filePath) async {
    try {
      final metadataPath = _getMetadataPath(filePath);
      final metadataFile = File(metadataPath);
      
      if (await metadataFile.exists()) {
        final metadataContent = await metadataFile.readAsString();
        final metadataJson = jsonDecode(metadataContent) as Map<String, dynamic>;
        return WorkspaceMetadata.fromJson(metadataJson);
      }
    } catch (e) {
      debugPrint('Error loading workspace metadata: $e');
    }
    return null;
  }
  
  String _getMetadataPath(String filePath) {
    final extension = path.extension(filePath);
    final basePath = filePath.substring(0, filePath.length - extension.length);
    return '$basePath$_metadataExtension';
  }
  
  Future<String> _createBackupFile(String filePath) async {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final extension = path.extension(filePath);
    final basePath = filePath.substring(0, filePath.length - extension.length);
    final backupPath = '$basePath$_backupExtension-$timestamp$extension';
    
    await File(filePath).copy(backupPath);
    
    // Also backup metadata if it exists
    final metadataPath = _getMetadataPath(filePath);
    final metadataFile = File(metadataPath);
    if (await metadataFile.exists()) {
      final backupMetadataPath = _getMetadataPath(backupPath);
      await metadataFile.copy(backupMetadataPath);
    }
    
    return backupPath;
  }
  
  WorkspaceFormat _getFormatFromPath(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.dsl':
        return WorkspaceFormat.dsl;
      case '.json':
      default:
        return WorkspaceFormat.json;
    }
  }
  
  bool _isWorkspaceFile(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    return extension == '.json' || extension == '.dsl';
  }
  
  Future<int> _getFileSize(String filePath) async {
    try {
      return await File(filePath).length();
    } catch (e) {
      return 0;
    }
  }
  
  Future<DateTime?> _getLastModified(String filePath) async {
    try {
      final stat = await File(filePath).stat();
      return stat.modified;
    } catch (e) {
      return null;
    }
  }
  
  int _countElements(Workspace workspace) {
    final model = workspace.model;
    return model.people.length + 
           model.softwareSystems.length +
           model.softwareSystems.fold<int>(0, (sum, system) => sum + system.containers.length) +
           model.softwareSystems.fold<int>(0, (sum, system) => 
               sum + system.containers.fold<int>(0, (containerSum, container) => 
                   containerSum + container.components.length));
  }
  
  int _countViews(Workspace workspace) {
    final views = workspace.views;
    return views.systemContextViews.length +
           views.containerViews.length +
           views.componentViews.length +
           views.dynamicViews.length +
           views.deploymentViews.length;
  }
}

/// Workspace format enumeration
enum WorkspaceFormat {
  json,
  dsl,
}

/// Workspace save result
class WorkspaceSaveResult {
  final bool success;
  final String filePath;
  final String? backupPath;
  final int? fileSize;
  final Duration? saveTime;
  final DateTime? timestamp;
  final String? error;
  final WorkspaceFormat format;
  
  const WorkspaceSaveResult({
    required this.success,
    required this.filePath,
    this.backupPath,
    this.fileSize,
    this.saveTime,
    this.timestamp,
    this.error,
    required this.format,
  });
  
  @override
  String toString() {
    return 'WorkspaceSaveResult(success: $success, filePath: $filePath, '
           'fileSize: $fileSize, saveTime: $saveTime, error: $error)';
  }
}

/// Workspace load result
class WorkspaceLoadResult {
  final bool success;
  final Workspace? workspace;
  final String filePath;
  final WorkspaceMetadata? metadata;
  final int? fileSize;
  final DateTime? lastModified;
  final Duration? loadTime;
  final String? error;
  final WorkspaceFormat? format;
  
  const WorkspaceLoadResult({
    required this.success,
    this.workspace,
    required this.filePath,
    this.metadata,
    this.fileSize,
    this.lastModified,
    this.loadTime,
    this.error,
    this.format,
  });
  
  @override
  String toString() {
    return 'WorkspaceLoadResult(success: $success, workspace: ${workspace?.name}, '
           'filePath: $filePath, fileSize: $fileSize, loadTime: $loadTime, error: $error)';
  }
}

/// Workspace file information
class WorkspaceFileInfo {
  final String filePath;
  final String fileName;
  final WorkspaceFormat format;
  final int? fileSize;
  final DateTime? lastModified;
  final WorkspaceMetadata? metadata;
  
  const WorkspaceFileInfo({
    required this.filePath,
    required this.fileName,
    required this.format,
    this.fileSize,
    this.lastModified,
    this.metadata,
  });
  
  @override
  String toString() {
    return 'WorkspaceFileInfo(fileName: $fileName, format: $format, '
           'fileSize: $fileSize, lastModified: $lastModified)';
  }
}

/// Workspace metadata
class WorkspaceMetadata {
  final String workspaceName;
  final String filePath;
  final WorkspaceFormat format;
  final int? fileSize;
  final DateTime lastModified;
  final String version;
  final String? description;
  final DateTime createdDate;
  final int elementCount;
  final int viewCount;
  
  const WorkspaceMetadata({
    required this.workspaceName,
    required this.filePath,
    required this.format,
    this.fileSize,
    required this.lastModified,
    required this.version,
    this.description,
    required this.createdDate,
    required this.elementCount,
    required this.viewCount,
  });
  
  factory WorkspaceMetadata.fromJson(Map<String, dynamic> json) {
    return WorkspaceMetadata(
      workspaceName: json['workspaceName'] as String,
      filePath: json['filePath'] as String,
      format: WorkspaceFormat.values.firstWhere(
        (f) => f.name == json['format'],
        orElse: () => WorkspaceFormat.json,
      ),
      fileSize: json['fileSize'] as int?,
      lastModified: DateTime.parse(json['lastModified'] as String),
      version: json['version'] as String,
      description: json['description'] as String?,
      createdDate: DateTime.parse(json['createdDate'] as String),
      elementCount: json['elementCount'] as int,
      viewCount: json['viewCount'] as int,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'workspaceName': workspaceName,
      'filePath': filePath,
      'format': format.name,
      'fileSize': fileSize,
      'lastModified': lastModified.toIso8601String(),
      'version': version,
      'description': description,
      'createdDate': createdDate.toIso8601String(),
      'elementCount': elementCount,
      'viewCount': viewCount,
    };
  }
  
  @override
  String toString() {
    return 'WorkspaceMetadata(name: $workspaceName, format: $format, '
           'elements: $elementCount, views: $viewCount, lastModified: $lastModified)';
  }
}

/// Workspace validation result
class WorkspaceValidationResult {
  final bool isValid;
  final List<String> issues;
  
  const WorkspaceValidationResult({
    required this.isValid,
    required this.issues,
  });
  
  @override
  String toString() {
    return 'WorkspaceValidationResult(valid: $isValid, issues: ${issues.length})';
  }
}