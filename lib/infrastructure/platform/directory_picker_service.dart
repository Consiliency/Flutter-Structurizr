import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'mobile_directory_picker.dart';

class DirectoryPickerService {
  final MobileDirectoryPicker _mobileDirectoryPicker;
  
  DirectoryPickerService({
    MobileDirectoryPicker? mobileDirectoryPicker,
  }) : _mobileDirectoryPicker = mobileDirectoryPicker ?? MobileDirectoryPicker();

  /// Pick a directory based on platform capabilities
  Future<String?> pickDirectory() async {
    if (kIsWeb) {
      return await _pickWebDirectory();
    }

    if (Platform.isAndroid || Platform.isIOS) {
      return await _pickMobileDirectory();
    }

    return await _pickDesktopDirectory();
  }

  /// Pick directory on desktop platforms
  Future<String?> _pickDesktopDirectory() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      return result;
    } catch (e) {
      debugPrint('Error picking desktop directory: $e');
      return null;
    }
  }

  /// Pick directory on mobile platforms
  Future<String?> _pickMobileDirectory() async {
    return await _mobileDirectoryPicker.pickDirectory();
  }

  /// Handle directory picking on web (limited capabilities)
  Future<String?> _pickWebDirectory() async {
    // Web has limited directory access through File System Access API
    // For now, return a default virtual path
    // In the future, this could use the File System Access API if supported
    return '/workspaces';
  }

  /// Check if directory picking is supported on current platform
  bool get isDirectoryPickingSupported {
    if (kIsWeb) {
      return false; // Limited support on web
    }

    if (Platform.isIOS) {
      return false; // iOS has very limited directory access
    }

    return true; // Android, Windows, macOS, Linux support directory picking
  }

  /// Get platform-specific limitations for directory access
  DirectoryAccessCapabilities get capabilities {
    if (kIsWeb) {
      return DirectoryAccessCapabilities(
        canPickDirectory: false,
        canCreateDirectory: false,
        canWriteToArbitraryLocations: false,
        hasStoragePermissions: true,
        supportedLocations: ['Browser Storage'],
        limitations: ['Limited to browser storage', 'No arbitrary file system access'],
      );
    }

    if (Platform.isIOS) {
      return DirectoryAccessCapabilities(
        canPickDirectory: false,
        canCreateDirectory: true,
        canWriteToArbitraryLocations: false,
        hasStoragePermissions: true,
        supportedLocations: ['App Documents', 'iCloud Drive (if enabled)'],
        limitations: ['Sandbox restrictions', 'Limited to app directories'],
      );
    }

    if (Platform.isAndroid) {
      return DirectoryAccessCapabilities(
        canPickDirectory: true,
        canCreateDirectory: true,
        canWriteToArbitraryLocations: true,
        hasStoragePermissions: false, // Requires permission check
        supportedLocations: ['Internal Storage', 'External Storage', 'SD Card'],
        limitations: ['Requires storage permission', 'Scoped storage on Android 11+'],
      );
    }

    // Desktop platforms (Windows, macOS, Linux)
    return DirectoryAccessCapabilities(
      canPickDirectory: true,
      canCreateDirectory: true,
      canWriteToArbitraryLocations: true,
      hasStoragePermissions: true,
      supportedLocations: ['Any accessible directory'],
      limitations: [],
    );
  }

  /// Get user-friendly error message for directory picking failures
  String getDirectoryPickerErrorMessage(String? error) {
    if (kIsWeb) {
      return 'Directory picking is not fully supported on web browsers. Using default storage location.';
    }

    if (Platform.isIOS) {
      return 'iOS limits directory access to app folders. Using app documents directory.';
    }

    if (Platform.isAndroid) {
      return 'Unable to access directory. Please check storage permissions and try again.';
    }

    return error ?? 'Unable to pick directory. Please try again.';
  }

  /// Get recommended fallback directory for platform
  Future<String?> getRecommendedDirectory() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return await _mobileDirectoryPicker.getRecommendedDirectory();
    }

    // For desktop, there's no single recommended directory
    // The user should choose their preferred location
    return null;
  }

  /// Validate directory access and provide feedback
  Future<DirectoryValidationResult> validateDirectory(String path) async {
    try {
      final directory = Directory(path);
      
      if (!await directory.exists()) {
        return DirectoryValidationResult(
          isValid: false,
          error: 'Directory does not exist',
          canCreate: true,
        );
      }

      // Test write access
      final testFile = File('$path/.structurizr_access_test');
      await testFile.writeAsString('test');
      await testFile.delete();
      
      return DirectoryValidationResult(
        isValid: true,
        error: null,
        canCreate: false,
      );
    } catch (e) {
      return DirectoryValidationResult(
        isValid: false,
        error: 'Cannot write to directory: ${e.toString()}',
        canCreate: false,
      );
    }
  }

  /// Get platform-specific directory picker options
  DirectoryPickerOptions getPickerOptions() {
    return DirectoryPickerOptions(
      dialogTitle: _getDialogTitle(),
      confirmButtonText: _getConfirmButtonText(),
      allowMultipleSelection: false,
      showHiddenFiles: false,
    );
  }

  String _getDialogTitle() {
    if (Platform.isAndroid) {
      return 'Select Workspace Folder';
    } else if (Platform.isIOS) {
      return 'Choose Storage Location';
    } else {
      return 'Choose Workspace Directory';
    }
  }

  String _getConfirmButtonText() {
    if (Platform.isAndroid || Platform.isIOS) {
      return 'Use This Folder';
    } else {
      return 'Select Folder';
    }
  }
}

class DirectoryAccessCapabilities {
  final bool canPickDirectory;
  final bool canCreateDirectory;
  final bool canWriteToArbitraryLocations;
  final bool hasStoragePermissions;
  final List<String> supportedLocations;
  final List<String> limitations;

  DirectoryAccessCapabilities({
    required this.canPickDirectory,
    required this.canCreateDirectory,
    required this.canWriteToArbitraryLocations,
    required this.hasStoragePermissions,
    required this.supportedLocations,
    required this.limitations,
  });
}

class DirectoryValidationResult {
  final bool isValid;
  final String? error;
  final bool canCreate;

  DirectoryValidationResult({
    required this.isValid,
    required this.error,
    required this.canCreate,
  });
}

class DirectoryPickerOptions {
  final String dialogTitle;
  final String confirmButtonText;
  final bool allowMultipleSelection;
  final bool showHiddenFiles;

  DirectoryPickerOptions({
    required this.dialogTitle,
    required this.confirmButtonText,
    required this.allowMultipleSelection,
    required this.showHiddenFiles,
  });
}