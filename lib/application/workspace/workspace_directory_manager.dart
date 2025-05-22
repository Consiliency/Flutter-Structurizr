import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkspaceDirectoryManager {
  static const String _lastWorkspaceDirectoryKey = 'last_workspace_directory';
  static const String _defaultWorkspaceNameKey = 'default_workspace_name';

  static WorkspaceDirectoryManager? _instance;
  static WorkspaceDirectoryManager get instance =>
      _instance ??= WorkspaceDirectoryManager._();

  WorkspaceDirectoryManager._();

  SharedPreferences? _prefs;

  /// Initialize the workspace directory manager
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get the last used workspace directory path
  Future<String?> getLastWorkspaceDirectory() async {
    await initialize();
    return _prefs?.getString(_lastWorkspaceDirectoryKey);
  }

  /// Set the default workspace directory
  Future<void> setWorkspaceDirectory(String directoryPath) async {
    await initialize();

    // Validate directory exists and is accessible
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      throw WorkspaceDirectoryException(
          'Directory does not exist: $directoryPath');
    }

    // Check permissions
    if (!await _hasDirectoryPermissions(directoryPath)) {
      throw WorkspaceDirectoryException(
          'Insufficient permissions for directory: $directoryPath');
    }

    await _prefs?.setString(_lastWorkspaceDirectoryKey, directoryPath);
  }

  /// Get the current workspace directory or create a default one
  Future<String> getCurrentWorkspaceDirectory() async {
    final lastDirectory = await getLastWorkspaceDirectory();

    if (lastDirectory != null && await _isDirectoryValid(lastDirectory)) {
      return lastDirectory;
    }

    // Create platform-specific default directory
    return await _createDefaultWorkspaceDirectory();
  }

  /// Create a platform-specific default workspace directory
  Future<String> _createDefaultWorkspaceDirectory() async {
    String defaultPath;

    if (kIsWeb) {
      // Web: Use browser storage, return a virtual path
      defaultPath = '/workspaces';
    } else if (Platform.isAndroid) {
      defaultPath = await _getAndroidDefaultDirectory();
    } else if (Platform.isIOS) {
      defaultPath = await _getIOSDefaultDirectory();
    } else if (Platform.isWindows) {
      defaultPath = await _getWindowsDefaultDirectory();
    } else if (Platform.isMacOS) {
      defaultPath = await _getMacOSDefaultDirectory();
    } else if (Platform.isLinux) {
      defaultPath = await _getLinuxDefaultDirectory();
    } else {
      // Fallback
      final documentsDir = await getApplicationDocumentsDirectory();
      defaultPath = '${documentsDir.path}/Structurizr Workspaces';
    }

    // Create directory if it doesn't exist
    if (!kIsWeb) {
      final directory = Directory(defaultPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    }

    return defaultPath;
  }

  /// Get Android-specific default directory
  Future<String> _getAndroidDefaultDirectory() async {
    try {
      // Try to use external storage directory
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        return '${externalDir.path}/Structurizr Workspaces';
      }
    } catch (e) {
      // Fall back to app-specific directory
    }

    // Fallback to app documents directory
    final documentsDir = await getApplicationDocumentsDirectory();
    return '${documentsDir.path}/Structurizr Workspaces';
  }

  /// Get iOS-specific default directory
  Future<String> _getIOSDefaultDirectory() async {
    // iOS: Use Documents directory (accessible via Files app)
    final documentsDir = await getApplicationDocumentsDirectory();
    return '${documentsDir.path}/Structurizr Workspaces';
  }

  /// Get Windows-specific default directory
  Future<String> _getWindowsDefaultDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    return '${documentsDir.path}\\Structurizr Workspaces';
  }

  /// Get macOS-specific default directory
  Future<String> _getMacOSDefaultDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    return '${documentsDir.path}/Structurizr Workspaces';
  }

  /// Get Linux-specific default directory
  Future<String> _getLinuxDefaultDirectory() async {
    // Follow XDG Base Directory specification
    final home = Platform.environment['HOME'];
    if (home != null) {
      final xdgDocuments =
          Platform.environment['XDG_DOCUMENTS_DIR'] ?? '$home/Documents';
      return '$xdgDocuments/Structurizr Workspaces';
    }

    // Fallback
    final documentsDir = await getApplicationDocumentsDirectory();
    return '${documentsDir.path}/Structurizr Workspaces';
  }

  /// Check if directory is valid and accessible
  Future<bool> _isDirectoryValid(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      return await directory.exists() &&
          await _hasDirectoryPermissions(directoryPath);
    } catch (e) {
      return false;
    }
  }

  /// Check if we have permissions for the directory
  Future<bool> _hasDirectoryPermissions(String directoryPath) async {
    if (kIsWeb) return true;

    try {
      final directory = Directory(directoryPath);

      // Try to list contents to check read permission
      await directory.list().first.timeout(const Duration(seconds: 1));

      // Try to create a temp file to check write permission
      final tempFile = File(
          '$directoryPath/.structurizr_temp_${DateTime.now().millisecondsSinceEpoch}');
      await tempFile.writeAsString('test');
      await tempFile.delete();

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get workspace file path within the current workspace directory
  Future<String> getWorkspaceFilePath(String workspaceName) async {
    final workspaceDir = await getCurrentWorkspaceDirectory();

    // Sanitize workspace name for file system
    final sanitizedName = _sanitizeFileName(workspaceName);

    if (kIsWeb) {
      return '$workspaceDir/$sanitizedName.json';
    } else {
      final separator = Platform.isWindows ? '\\' : '/';
      return '$workspaceDir$separator$sanitizedName.json';
    }
  }

  /// Get metadata file path for workspace
  Future<String> getWorkspaceMetadataPath(String workspaceName) async {
    final workspaceDir = await getCurrentWorkspaceDirectory();
    final sanitizedName = _sanitizeFileName(workspaceName);

    if (kIsWeb) {
      return '$workspaceDir/.$sanitizedName.metadata.json';
    } else {
      final separator = Platform.isWindows ? '\\' : '/';
      return '$workspaceDir$separator.$sanitizedName.metadata.json';
    }
  }

  /// List all workspace files in the current directory
  Future<List<String>> listWorkspaceFiles() async {
    final workspaceDir = await getCurrentWorkspaceDirectory();

    if (kIsWeb) {
      // For web, this would need to be implemented differently
      // using browser storage APIs
      return [];
    }

    final directory = Directory(workspaceDir);
    if (!await directory.exists()) {
      return [];
    }

    final files = <String>[];
    await for (final entity in directory.list()) {
      if (entity is File) {
        final fileName =
            entity.path.split(Platform.isWindows ? '\\' : '/').last;
        if (fileName.endsWith('.json') || fileName.endsWith('.dsl')) {
          if (!fileName.startsWith('.')) {
            files.add(fileName);
          }
        }
      }
    }

    return files;
  }

  /// Create a backup of the workspace directory
  Future<String> createBackup() async {
    final workspaceDir = await getCurrentWorkspaceDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupDir = '$workspaceDir.backup.$timestamp';

    if (!kIsWeb) {
      final source = Directory(workspaceDir);
      final destination = Directory(backupDir);

      await _copyDirectory(source, destination);
    }

    return backupDir;
  }

  /// Copy directory recursively
  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);

    await for (final entity in source.list()) {
      if (entity is File) {
        final fileName =
            entity.path.split(Platform.isWindows ? '\\' : '/').last;
        await entity.copy(
            '${destination.path}${Platform.isWindows ? '\\' : '/'}$fileName');
      } else if (entity is Directory) {
        final dirName = entity.path.split(Platform.isWindows ? '\\' : '/').last;
        await _copyDirectory(
            entity,
            Directory(
                '${destination.path}${Platform.isWindows ? '\\' : '/'}$dirName'));
      }
    }
  }

  /// Sanitize file name for cross-platform compatibility
  String _sanitizeFileName(String fileName) {
    // Remove or replace invalid characters
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
  }

  /// Clear stored workspace directory (for testing or reset)
  Future<void> clearStoredDirectory() async {
    await initialize();
    await _prefs?.remove(_lastWorkspaceDirectoryKey);
    await _prefs?.remove(_defaultWorkspaceNameKey);
  }

  /// Get platform-specific storage info
  Future<PlatformStorageInfo> getStorageInfo() async {
    return PlatformStorageInfo(
      platform: _getCurrentPlatform(),
      isExternalStorageAvailable: await _isExternalStorageAvailable(),
      requiresPermissions: await _requiresStoragePermissions(),
      supportsDirectoryPicker: _supportsDirectoryPicker(),
      defaultPath: await _createDefaultWorkspaceDirectory(),
    );
  }

  String _getCurrentPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  Future<bool> _isExternalStorageAvailable() async {
    if (Platform.isAndroid) {
      try {
        final externalDir = await getExternalStorageDirectory();
        return externalDir != null;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  Future<bool> _requiresStoragePermissions() async {
    return Platform.isAndroid;
  }

  bool _supportsDirectoryPicker() {
    // Directory picker support varies by platform
    if (kIsWeb) return false; // Limited support
    if (Platform.isIOS) return true; // UIDocumentPickerViewController
    if (Platform.isAndroid) return true; // Storage Access Framework
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return true; // Native dialogs
    }
    return false;
  }
}

/// Exception thrown when workspace directory operations fail
class WorkspaceDirectoryException implements Exception {
  final String message;

  const WorkspaceDirectoryException(this.message);

  @override
  String toString() => 'WorkspaceDirectoryException: $message';
}

/// Information about platform-specific storage capabilities
class PlatformStorageInfo {
  final String platform;
  final bool isExternalStorageAvailable;
  final bool requiresPermissions;
  final bool supportsDirectoryPicker;
  final String defaultPath;

  const PlatformStorageInfo({
    required this.platform,
    required this.isExternalStorageAvailable,
    required this.requiresPermissions,
    required this.supportsDirectoryPicker,
    required this.defaultPath,
  });

  @override
  String toString() {
    return 'PlatformStorageInfo(platform: $platform, externalStorage: $isExternalStorageAvailable, '
        'permissions: $requiresPermissions, directoryPicker: $supportsDirectoryPicker, '
        'defaultPath: $defaultPath)';
  }
}
