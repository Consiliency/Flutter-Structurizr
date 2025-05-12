import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert'; // Add for utf8
import 'package:flutter_structurizr/application/workspace/workspace_repository.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/infrastructure/serialization/json_serialization.dart';
import 'package:flutter_structurizr/infrastructure/persistence/file_workspace_repository.dart'; // Add for FileWorkspaceRepository
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' if (dart.library.html) 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Enhanced file storage for workspaces, extending [FileWorkspaceRepository]
/// with more advanced features such as versioning, backups, and progress reporting.
class FileStorage {
  /// The underlying workspace repository
  final FileWorkspaceRepository _repository;
  
  /// Directory for storing backups
  final String _backupDirectory;
  
  /// Maximum number of backups to keep per workspace
  final int maxBackups;
  
  /// Creates a new [FileStorage] with the given workspace directory
  /// and optional backup settings.
  FileStorage({
    required String workspacesDirectory,
    String? backupDirectory,
    this.maxBackups = 5,
  }) : _repository = FileWorkspaceRepository(workspacesDirectory: workspacesDirectory),
       _backupDirectory = backupDirectory ?? path.join(workspacesDirectory, 'backups');
  
  /// Gets the underlying workspace repository.
  FileWorkspaceRepository get repository => _repository;

  /// Loads a workspace with progress reporting.
  Future<Workspace> loadWorkspace(
    String path, {
    ValueChanged<double>? onProgress,
  }) async {
    if (onProgress != null) {
      onProgress(0.0);
      
      // Get file size to estimate progress
      final file = File(path);
      final fileSize = await file.length();
      final content = await _readFileWithProgress(file, fileSize, onProgress);
      
      // Final progress step for parsing
      onProgress(0.9);
      
      final workspace = _parseWorkspace(path, content);
      onProgress(1.0);
      return workspace;
    } else {
      return _repository.loadWorkspace(path);
    }
  }
  
  /// Saves a workspace with versioning and progress reporting.
  Future<void> saveWorkspace(
    Workspace workspace,
    String path, {
    bool createBackup = true,
    ValueChanged<double>? onProgress,
  }) async {
    if (onProgress != null) {
      onProgress(0.0);
    }
    
    // Create backup if requested and file exists
    if (createBackup && await File(path).exists()) {
      if (onProgress != null) {
        onProgress(0.1);
      }
      await _createBackup(path);
      if (onProgress != null) {
        onProgress(0.3);
      }
    }
    
    // Save the workspace
    if (onProgress != null) {
      // For progress reporting, we need to save manually rather than using repository
      final content = _serializeWorkspace(workspace, path);
      final file = File(path);
      
      // Create directory if it doesn't exist
      final dir = file.parent;
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      // Write file with progress
      await _writeFileWithProgress(file, content, onProgress, startProgress: 0.4, endProgress: 0.9);
      onProgress(1.0);
    } else {
      await _repository.saveWorkspace(workspace, path);
    }
  }
  
  /// Lists all available workspaces.
  Future<List<WorkspaceMetadata>> listWorkspaces() {
    return _repository.listWorkspaces();
  }
  
  /// Lists all available backups for a workspace.
  Future<List<WorkspaceBackup>> listBackups(String workspacePath) async {
    final backups = <WorkspaceBackup>[];
    final basename = path.basename(workspacePath);
    final backupDir = Directory(path.join(_backupDirectory, path.basenameWithoutExtension(basename)));
    
    if (!await backupDir.exists()) {
      return backups;
    }
    
    await for (final entity in backupDir.list()) {
      if (entity is File) {
        final stat = await entity.stat();
        backups.add(WorkspaceBackup(
          path: entity.path,
          originalPath: workspacePath,
          timestamp: stat.modified,
        ));
      }
    }
    
    // Sort by date, newest first
    backups.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return backups;
  }
  
  /// Restores a workspace from a backup.
  Future<Workspace> restoreFromBackup(
    WorkspaceBackup backup, {
    bool overwriteOriginal = true,
    ValueChanged<double>? onProgress,
  }) async {
    if (onProgress != null) {
      onProgress(0.0);
    }
    
    // Load backup
    final workspace = await loadWorkspace(backup.path, onProgress: (progress) {
      if (onProgress != null) {
        onProgress(progress * 0.5); // First half of progress
      }
    });
    
    // Save to original path if requested
    if (overwriteOriginal) {
      await saveWorkspace(
        workspace,
        backup.originalPath,
        createBackup: false, // Don't create another backup
        onProgress: (progress) {
          if (onProgress != null) {
            onProgress(0.5 + progress * 0.5); // Second half of progress
          }
        },
      );
    }
    
    if (onProgress != null) {
      onProgress(1.0);
    }
    
    return workspace;
  }
  
  /// Creates a workspace with the given metadata.
  Future<Workspace> createWorkspace(WorkspaceMetadata metadata) {
    return _repository.createWorkspace(metadata);
  }
  
  /// Deletes a workspace and all its backups.
  Future<void> deleteWorkspace(
    String filePath, {
    bool deleteBackups = true,
  }) async {
    await _repository.deleteWorkspace(filePath);

    if (deleteBackups) {
      final basename = path.basename(filePath);
      final backupDir = Directory(path.join(_backupDirectory, path.basenameWithoutExtension(basename)));

      if (await backupDir.exists()) {
        await backupDir.delete(recursive: true);
      }
    }
  }
  
  /// Creates a backup of the workspace file.
  Future<String> _createBackup(String filePath) async {
    final file = File(filePath);
    
    if (!await file.exists()) {
      throw WorkspaceException('Cannot backup non-existent file', path: filePath);
    }
    
    final basename = path.basename(filePath);
    final extension = path.extension(filePath);
    final baseNameNoExt = path.basenameWithoutExtension(basename);
    
    // Create backup directory if it doesn't exist
    final backupDirPath = path.join(_backupDirectory, baseNameNoExt);
    final backupDir = Directory(backupDirPath);
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    
    // Generate backup file name with timestamp
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
    final backupFileName = '$baseNameNoExt-backup-$timestamp$extension';
    final backupPath = path.join(backupDirPath, backupFileName);
    
    // Copy the file to the backup location
    await file.copy(backupPath);
    
    // Clean up old backups if we have too many
    await _cleanupOldBackups(backupDirPath);
    
    return backupPath;
  }
  
  /// Cleans up old backups, keeping only the most recent [maxBackups].
  Future<void> _cleanupOldBackups(String backupDirPath) async {
    final backupDir = Directory(backupDirPath);
    if (!await backupDir.exists()) return;
    
    final files = await backupDir.list().toList();
    if (files.length <= maxBackups) return;
    
    // Sort files by modification time, oldest first
    final backupFiles = <File>[];
    for (final entity in files) {
      if (entity is File) {
        backupFiles.add(entity);
      }
    }
    
    final fileStat = await Future.wait(backupFiles.map((file) => file.stat()));
    final sortedFiles = List.generate(
      backupFiles.length,
      (index) => MapEntry(backupFiles[index], fileStat[index]),
    )..sort((a, b) => a.value.modified.compareTo(b.value.modified));
    
    // Delete the oldest files
    final filesToDelete = sortedFiles.length - maxBackups;
    if (filesToDelete > 0) {
      for (var i = 0; i < filesToDelete; i++) {
        await sortedFiles[i].key.delete();
      }
    }
  }
  
  /// Parses a workspace from file content.
  Workspace _parseWorkspace(String path, String content) {
    try {
      if (path.endsWith('.json')) {
        return JsonSerialization.workspaceFromJson(content);
      } else if (path.endsWith('.dsl')) {
        throw WorkspaceException('DSL format not yet supported', path: path);
      } else {
        throw WorkspaceException('Unsupported file format', path: path);
      }
    } catch (e) {
      if (e is WorkspaceException) {
        rethrow;
      }
      throw WorkspaceException('Failed to parse workspace', path: path, cause: e);
    }
  }
  
  /// Serializes a workspace to file content.
  String _serializeWorkspace(Workspace workspace, String path) {
    try {
      if (path.endsWith('.json')) {
        return JsonSerialization.workspaceToJson(workspace);
      } else if (path.endsWith('.dsl')) {
        throw WorkspaceException('DSL format not yet supported', path: path);
      } else {
        throw WorkspaceException('Unsupported file format', path: path);
      }
    } catch (e) {
      if (e is WorkspaceException) {
        rethrow;
      }
      throw WorkspaceException('Failed to serialize workspace', path: path, cause: e);
    }
  }
  
  /// Reads a file with progress reporting.
  Future<String> _readFileWithProgress(
    File file,
    int fileSize,
    ValueChanged<double> onProgress,
  ) async {
    try {
      final stream = file.openRead();
      final chunks = <List<int>>[];
      int bytesRead = 0;
      
      // Report initial progress
      onProgress(0.1);
      
      // Read file in chunks and report progress
      await for (final chunk in stream) {
        chunks.add(chunk);
        bytesRead += chunk.length;
        
        // Report progress from 10% to 90% based on bytes read
        final progress = bytesRead / fileSize;
        onProgress(0.1 + progress * 0.8);
      }
      
      // Combine chunks and convert to string
      final bytes = Uint8List(bytesRead);
      int offset = 0;
      for (final chunk in chunks) {
        bytes.setRange(offset, offset + chunk.length, chunk);
        offset += chunk.length;
      }
      
      return utf8.decode(bytes);
    } catch (e) {
      throw WorkspaceException('Failed to read file', path: file.path, cause: e);
    }
  }
  
  /// Writes a file with progress reporting.
  Future<void> _writeFileWithProgress(
    File file,
    String content,
    ValueChanged<double> onProgress,
    {double startProgress = 0.0, double endProgress = 1.0}
  ) async {
    try {
      final bytes = utf8.encode(content);
      final stream = file.openWrite();
      
      // Write in chunks to report progress
      const chunkSize = 1024 * 64; // 64KB chunks
      final totalChunks = (bytes.length / chunkSize).ceil();
      
      for (var i = 0; i < totalChunks; i++) {
        final start = i * chunkSize;
        final end = (i + 1) * chunkSize > bytes.length ? bytes.length : (i + 1) * chunkSize;
        final chunk = bytes.sublist(start, end);
        
        stream.add(chunk);
        
        // Report progress based on chunks written
        final progress = i / totalChunks;
        onProgress(startProgress + (endProgress - startProgress) * progress);
      }
      
      await stream.flush();
      await stream.close();
      
      // Final progress
      onProgress(endProgress);
    } catch (e) {
      throw WorkspaceException('Failed to write file', path: file.path, cause: e);
    }
  }
  
  /// Gets the default workspace directory for the current platform.
  static Future<String> getDefaultWorkspaceDirectory() async {
    try {
      if (kIsWeb) {
        // Web doesn't have file system access in the same way
        // Browser storage is handled differently
        return '/';
      }
      
      if (Platform.isAndroid || Platform.isIOS) {
        // Use documents directory on mobile platforms
        final directory = await getApplicationDocumentsDirectory();
        return path.join(directory.path, 'structurizr', 'workspaces');
      } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        // Use app data directory on desktop platforms
        final directory = await getApplicationSupportDirectory();
        return path.join(directory.path, 'structurizr', 'workspaces');
      } else {
        // Fallback for other platforms
        final directory = await getTemporaryDirectory();
        return path.join(directory.path, 'structurizr', 'workspaces');
      }
    } catch (e) {
      // If path_provider fails, fall back to a relative path
      return 'structurizr/workspaces';
    }
  }
  
  /// Gets the default backup directory for the current platform.
  static Future<String> getDefaultBackupDirectory() async {
    final workspaceDir = await getDefaultWorkspaceDirectory();
    return path.join(workspaceDir, 'backups');
  }
}

/// Represents a backup of a workspace.
class WorkspaceBackup {
  /// The path to the backup file.
  final String path;
  
  /// The path to the original workspace file.
  final String originalPath;
  
  /// When the backup was created.
  final DateTime timestamp;
  
  WorkspaceBackup({
    required this.path,
    required this.originalPath,
    required this.timestamp,
  });
}