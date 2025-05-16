import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Helper class for file system operations.
/// 
/// Provides platform-specific path handling and utility methods for file operations.
class FileSystemHelper {
  /// Gets the application documents directory path.
  static Future<String> getApplicationDocumentsPath() async {
    if (kIsWeb) {
      return '/';
    }
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    } catch (e) {
      return '.';
    }
  }
  
  /// Gets the application support directory path.
  static Future<String> getApplicationSupportPath() async {
    if (kIsWeb) {
      return '/';
    }
    
    try {
      final directory = await getApplicationSupportDirectory();
      return directory.path;
    } catch (e) {
      return '.';
    }
  }
  
  /// Gets the application temporary directory path.
  static Future<String> getTemporaryPath() async {
    if (kIsWeb) {
      return '/';
    }
    
    try {
      final directory = await getTemporaryDirectory();
      return directory.path;
    } catch (e) {
      return '.';
    }
  }
  
  /// Gets the default workspaces directory.
  static Future<String> getDefaultWorkspacesPath() async {
    String basePath;
    
    if (kIsWeb) {
      return '/structurizr/workspaces';
    }
    
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // Use documents directory on mobile platforms
        final directory = await getApplicationDocumentsDirectory();
        basePath = directory.path;
      } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        // Use app data directory on desktop platforms
        final directory = await getApplicationSupportDirectory();
        basePath = directory.path;
      } else {
        // Fallback for other platforms
        final directory = await getTemporaryDirectory();
        basePath = directory.path;
      }
    } catch (e) {
      // If path_provider fails, fall back to a relative path
      return 'structurizr/workspaces';
    }
    
    return path.join(basePath, 'structurizr', 'workspaces');
  }
  
  /// Gets the default backups directory.
  static Future<String> getDefaultBackupsPath() async {
    final workspacesPath = await getDefaultWorkspacesPath();
    return path.join(workspacesPath, 'backups');
  }
  
  /// Gets the default exports directory.
  static Future<String> getDefaultExportsPath() async {
    final workspacesPath = await getDefaultWorkspacesPath();
    return path.join(workspacesPath, 'exports');
  }
  
  /// Gets the default imports directory.
  static Future<String> getDefaultImportsPath() async {
    final workspacesPath = await getDefaultWorkspacesPath();
    return path.join(workspacesPath, 'imports');
  }
  
  /// Ensures a directory exists, creating it if necessary.
  static Future<void> ensureDirectoryExists(String path) async {
    final directory = Directory(path);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }
  
  /// Generates a filename with a timestamp.
  static String generateTimestampedFilename(String basename, String extension) {
    final timestamp = DateTime.now().toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-')
        .replaceAll('T', '_');
    return '$basename-$timestamp.$extension';
  }
  
  /// Copies a file with progress reporting.
  static Future<void> copyFileWithProgress(
    File source,
    File destination, {
    ValueChanged<double>? onProgress,
  }) async {
    try {
      // Get file size
      final fileSize = await source.length();
      
      // Initial progress
      if (onProgress != null) {
        onProgress(0.0);
      }
      
      // Create destination directory if it doesn't exist
      final dir = destination.parent;
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      // Read source file
      final inputStream = source.openRead();
      final outputStream = destination.openWrite();
      
      // Copy with progress reporting
      int bytesWritten = 0;
      await for (final chunk in inputStream) {
        outputStream.add(chunk);
        
        bytesWritten += chunk.length;
        
        // Report progress
        if (onProgress != null) {
          final progress = bytesWritten / fileSize;
          onProgress(progress);
        }
      }
      
      // Flush and close
      await outputStream.flush();
      await outputStream.close();
      
      // Final progress
      if (onProgress != null) {
        onProgress(1.0);
      }
    } catch (e) {
      rethrow;
    }
  }
  
  /// Deletes a file if it exists.
  static Future<void> deleteFileIfExists(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
  
  /// Gets a list of files in a directory matching the given extension.
  static Future<List<File>> getFilesWithExtension(
    String directoryPath,
    String extension,
  ) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      return [];
    }
    
    final files = <File>[];
    
    await for (final entity in directory.list()) {
      if (entity is File && entity.path.endsWith(extension)) {
        files.add(entity);
      }
    }
    
    return files;
  }
  
  /// Gets the file extension from a path.
  static String getFileExtension(String path) {
    return path.split('.').last;
  }
  
  /// Gets the base name (without extension) from a path.
  static String getFileBaseName(String path) {
    return path.split(Platform.pathSeparator).last.split('.').first;
  }
}