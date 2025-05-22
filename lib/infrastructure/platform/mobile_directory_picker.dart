import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

class MobileDirectoryPicker {
  static const MethodChannel _channel = MethodChannel('structurizr/directory_picker');
  
  static MobileDirectoryPicker? _instance;
  static MobileDirectoryPicker get instance => _instance ??= MobileDirectoryPicker._();
  
  MobileDirectoryPicker._();
  
  /// Pick a directory using platform-specific implementation
  Future<DirectoryPickerResult?> pickDirectory({
    String? initialDirectory,
    String? dialogTitle,
  }) async {
    if (kIsWeb) {
      return await _pickDirectoryWeb(dialogTitle: dialogTitle);
    } else if (Platform.isAndroid) {
      return await _pickDirectoryAndroid(
        initialDirectory: initialDirectory,
        dialogTitle: dialogTitle,
      );
    } else if (Platform.isIOS) {
      return await _pickDirectoryIOS(
        dialogTitle: dialogTitle,
      );
    } else {
      // Desktop platforms - use file_picker
      return await _pickDirectoryDesktop(
        initialDirectory: initialDirectory,
        dialogTitle: dialogTitle,
      );
    }
  }
  
  /// Android-specific directory picker using Storage Access Framework
  Future<DirectoryPickerResult?> _pickDirectoryAndroid({
    String? initialDirectory,
    String? dialogTitle,
  }) async {
    try {
      // Use Storage Access Framework (SAF) for Android
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('pickDirectoryAndroid', {
        'initialDirectory': initialDirectory,
        'dialogTitle': dialogTitle ?? 'Select Workspace Directory',
      });
      
      if (result != null) {
        return DirectoryPickerResult(
          path: result['path'] as String,
          uri: result['uri'] as String?,
          displayName: result['displayName'] as String?,
          isWritable: result['isWritable'] as bool? ?? false,
          persistentPermission: result['persistentPermission'] as bool? ?? false,
        );
      }
    } catch (e) {
      debugPrint('Error picking directory on Android: $e');
      
      // Fallback to file_picker if native implementation fails
      try {
        String? directoryPath = await FilePicker.platform.getDirectoryPath(
          dialogTitle: dialogTitle,
          initialDirectory: initialDirectory,
        );
        
        if (directoryPath != null) {
          return DirectoryPickerResult(
            path: directoryPath,
            uri: null,
            displayName: directoryPath.split('/').last,
            isWritable: await _checkDirectoryWritable(directoryPath),
            persistentPermission: false,
          );
        }
      } catch (fallbackError) {
        debugPrint('Fallback directory picker also failed: $fallbackError');
      }
    }
    
    return null;
  }
  
  /// iOS-specific directory picker using UIDocumentPickerViewController
  Future<DirectoryPickerResult?> _pickDirectoryIOS({
    String? dialogTitle,
  }) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('pickDirectoryIOS', {
        'dialogTitle': dialogTitle ?? 'Select Workspace Directory',
      });
      
      if (result != null) {
        return DirectoryPickerResult(
          path: result['path'] as String,
          uri: result['bookmarkData'] as String?, // iOS bookmark for persistent access
          displayName: result['displayName'] as String?,
          isWritable: result['isWritable'] as bool? ?? false,
          persistentPermission: true, // iOS uses security-scoped bookmarks
        );
      }
    } catch (e) {
      debugPrint('Error picking directory on iOS: $e');
      
      // iOS doesn't have a good fallback for directory picking
      // The app would need to use the Documents directory
      return null;
    }
    
    return null;
  }
  
  /// Web-specific directory picker using File System Access API
  Future<DirectoryPickerResult?> _pickDirectoryWeb({
    String? dialogTitle,
  }) async {
    try {
      // Web File System Access API (limited browser support)
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('pickDirectoryWeb', {
        'dialogTitle': dialogTitle ?? 'Select Workspace Directory',
      });
      
      if (result != null) {
        return DirectoryPickerResult(
          path: result['path'] as String, // Virtual path for web
          uri: result['handle'] as String?, // FileSystemDirectoryHandle reference
          displayName: result['displayName'] as String?,
          isWritable: result['isWritable'] as bool? ?? false,
          persistentPermission: result['persistentPermission'] as bool? ?? false,
        );
      }
    } catch (e) {
      debugPrint('Error picking directory on Web: $e');
      // Web fallback would be to use browser downloads directory or IndexedDB
    }
    
    return null;
  }
  
  /// Desktop directory picker using file_picker
  Future<DirectoryPickerResult?> _pickDirectoryDesktop({
    String? initialDirectory,
    String? dialogTitle,
  }) async {
    try {
      String? directoryPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: dialogTitle,
        initialDirectory: initialDirectory,
      );
      
      if (directoryPath != null) {
        return DirectoryPickerResult(
          path: directoryPath,
          uri: null,
          displayName: directoryPath.split(Platform.isWindows ? '\\' : '/').last,
          isWritable: await _checkDirectoryWritable(directoryPath),
          persistentPermission: true, // Desktop has persistent file system access
        );
      }
    } catch (e) {
      debugPrint('Error picking directory on desktop: $e');
    }
    
    return null;
  }
  
  /// Check if directory is writable
  Future<bool> _checkDirectoryWritable(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        return false;
      }
      
      // Try to create a test file
      final testFile = File('$directoryPath/.structurizr_write_test_${DateTime.now().millisecondsSinceEpoch}');
      await testFile.writeAsString('test');
      await testFile.delete();
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Get directory picker capabilities for current platform
  Future<DirectoryPickerCapabilities> getCapabilities() async {
    if (kIsWeb) {
      return const DirectoryPickerCapabilities(
        supportsDirectoryPicker: true, // With File System Access API
        supportsPersistentAccess: false,
        supportsInitialDirectory: false,
        requiresPermissions: false,
        platformName: 'Web',
      );
    } else if (Platform.isAndroid) {
      return const DirectoryPickerCapabilities(
        supportsDirectoryPicker: true, // Storage Access Framework
        supportsPersistentAccess: true,
        supportsInitialDirectory: false, // SAF doesn't support initial directory
        requiresPermissions: false, // SAF handles permissions
        platformName: 'Android',
      );
    } else if (Platform.isIOS) {
      return const DirectoryPickerCapabilities(
        supportsDirectoryPicker: true, // UIDocumentPickerViewController
        supportsPersistentAccess: true, // Security-scoped bookmarks
        supportsInitialDirectory: false,
        requiresPermissions: false, // Uses app sandbox
        platformName: 'iOS',
      );
    } else {
      return DirectoryPickerCapabilities(
        supportsDirectoryPicker: true,
        supportsPersistentAccess: true,
        supportsInitialDirectory: true,
        requiresPermissions: false,
        platformName: Platform.operatingSystem,
      );
    }
  }
  
  /// Validate picked directory access
  Future<DirectoryValidationResult> validateDirectoryAccess(DirectoryPickerResult result) async {
    final issues = <String>[];
    
    // Check if path exists (for non-web platforms)
    if (!kIsWeb && !await Directory(result.path).exists()) {
      issues.add('Directory does not exist or is not accessible');
    }
    
    // Check if writable
    if (!result.isWritable) {
      issues.add('Directory is not writable');
    }
    
    // Platform-specific validations
    if (Platform.isAndroid && result.uri == null) {
      issues.add('No persistent URI provided for Android directory');
    }
    
    if (Platform.isIOS && result.uri == null) {
      issues.add('No bookmark data provided for iOS directory');
    }
    
    // Check available space (if possible)
    int? availableSpace;
    try {
      if (!kIsWeb) {
        final stat = await Directory(result.path).stat();
        // Note: Dart doesn't provide direct disk space API
        // This would need platform-specific implementation
      }
    } catch (e) {
      // Ignore space check errors
    }
    
    return DirectoryValidationResult(
      isValid: issues.isEmpty,
      issues: issues,
      availableSpaceBytes: availableSpace,
      recommendedAction: issues.isEmpty 
          ? 'Directory is ready to use'
          : 'Please select a different directory or check permissions',
    );
  }
  
  /// Create subdirectory in picked directory
  Future<String?> createWorkspaceSubdirectory(
    DirectoryPickerResult parentResult,
    String subdirectoryName,
  ) async {
    try {
      String subdirectoryPath;
      
      if (kIsWeb) {
        subdirectoryPath = '${parentResult.path}/$subdirectoryName';
        // Web would need to handle this through File System Access API
        // Implementation would be in the native web component
        return subdirectoryPath;
      } else {
        final separator = Platform.isWindows ? '\\' : '/';
        subdirectoryPath = '${parentResult.path}$separator$subdirectoryName';
        
        final subdirectory = Directory(subdirectoryPath);
        if (!await subdirectory.exists()) {
          await subdirectory.create(recursive: true);
        }
        
        return subdirectoryPath;
      }
    } catch (e) {
      debugPrint('Error creating workspace subdirectory: $e');
      return null;
    }
  }
  
  /// Convert directory picker result to persistent reference
  Future<String?> createPersistentReference(DirectoryPickerResult result) async {
    if (result.persistentPermission && result.uri != null) {
      return result.uri;
    }
    
    // For platforms without persistent references, return the path
    return result.path;
  }
  
  /// Restore directory access from persistent reference
  Future<DirectoryPickerResult?> restoreFromPersistentReference(String reference) async {
    try {
      if (Platform.isAndroid) {
        // Restore Android SAF URI
        final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('restoreAndroidDirectory', {
          'uri': reference,
        });
        
        if (result != null) {
          return DirectoryPickerResult(
            path: result['path'] as String,
            uri: reference,
            displayName: result['displayName'] as String?,
            isWritable: result['isWritable'] as bool? ?? false,
            persistentPermission: true,
          );
        }
      } else if (Platform.isIOS) {
        // Restore iOS security-scoped bookmark
        final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('restoreIOSDirectory', {
          'bookmarkData': reference,
        });
        
        if (result != null) {
          return DirectoryPickerResult(
            path: result['path'] as String,
            uri: reference,
            displayName: result['displayName'] as String?,
            isWritable: result['isWritable'] as bool? ?? false,
            persistentPermission: true,
          );
        }
      } else {
        // Desktop: reference is just the path
        if (await Directory(reference).exists()) {
          return DirectoryPickerResult(
            path: reference,
            uri: null,
            displayName: reference.split(Platform.isWindows ? '\\' : '/').last,
            isWritable: await _checkDirectoryWritable(reference),
            persistentPermission: true,
          );
        }
      }
    } catch (e) {
      debugPrint('Error restoring directory from persistent reference: $e');
    }
    
    return null;
  }
}

/// Result of directory picker operation
class DirectoryPickerResult {
  final String path;
  final String? uri; // Platform-specific URI or bookmark
  final String? displayName;
  final bool isWritable;
  final bool persistentPermission;
  
  const DirectoryPickerResult({
    required this.path,
    this.uri,
    this.displayName,
    required this.isWritable,
    required this.persistentPermission,
  });
  
  @override
  String toString() {
    return 'DirectoryPickerResult(path: $path, displayName: $displayName, '
           'writable: $isWritable, persistent: $persistentPermission)';
  }
}

/// Directory picker capabilities for current platform
class DirectoryPickerCapabilities {
  final bool supportsDirectoryPicker;
  final bool supportsPersistentAccess;
  final bool supportsInitialDirectory;
  final bool requiresPermissions;
  final String platformName;
  
  const DirectoryPickerCapabilities({
    required this.supportsDirectoryPicker,
    required this.supportsPersistentAccess,
    required this.supportsInitialDirectory,
    required this.requiresPermissions,
    required this.platformName,
  });
  
  @override
  String toString() {
    return 'DirectoryPickerCapabilities(platform: $platformName, '
           'picker: $supportsDirectoryPicker, persistent: $supportsPersistentAccess, '
           'initialDir: $supportsInitialDirectory, permissions: $requiresPermissions)';
  }
}

/// Result of directory validation
class DirectoryValidationResult {
  final bool isValid;
  final List<String> issues;
  final int? availableSpaceBytes;
  final String recommendedAction;
  
  const DirectoryValidationResult({
    required this.isValid,
    required this.issues,
    this.availableSpaceBytes,
    required this.recommendedAction,
  });
  
  @override
  String toString() {
    return 'DirectoryValidationResult(valid: $isValid, issues: ${issues.length}, '
           'space: ${availableSpaceBytes != null ? '${availableSpaceBytes! ~/ (1024 * 1024)}MB' : 'unknown'})';
  }
}