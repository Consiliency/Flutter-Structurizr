import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class MobilePermissionsManager {
  static MobilePermissionsManager? _instance;
  static MobilePermissionsManager get instance =>
      _instance ??= MobilePermissionsManager._();

  MobilePermissionsManager._();

  late final DeviceInfoPlugin _deviceInfo;

  /// Initialize the permissions manager
  Future<void> initialize() async {
    _deviceInfo = DeviceInfoPlugin();
  }

  /// Check if storage permissions are required for the current platform
  Future<bool> requiresStoragePermissions() async {
    if (kIsWeb) return false;
    if (Platform.isIOS) {
      return false; // iOS uses app sandbox, no explicit permissions
    }
    if (Platform.isAndroid) {
      // Android 11+ uses scoped storage, different permission model
      final androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.version.sdkInt < 30; // API level 30 = Android 11
    }
    return false;
  }

  /// Get the storage permission status
  Future<PermissionStatus> getStoragePermissionStatus() async {
    if (!await requiresStoragePermissions()) {
      return PermissionStatus.granted;
    }

    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;

      // For Android 11+ (API 30+), check if we need MANAGE_EXTERNAL_STORAGE
      if (androidInfo.version.sdkInt >= 30) {
        return await Permission.manageExternalStorage.status;
      } else {
        // For older Android versions, check regular storage permission
        return await Permission.storage.status;
      }
    }

    return PermissionStatus.granted;
  }

  /// Request storage permissions
  Future<PermissionStatus> requestStoragePermissions() async {
    if (!await requiresStoragePermissions()) {
      return PermissionStatus.granted;
    }

    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;

      if (androidInfo.version.sdkInt >= 30) {
        // Android 11+ - Request MANAGE_EXTERNAL_STORAGE for broad access
        return await Permission.manageExternalStorage.request();
      } else {
        // Older Android - Request standard storage permission
        return await Permission.storage.request();
      }
    }

    return PermissionStatus.granted;
  }

  /// Check if we have sufficient permissions for file operations
  Future<bool> hasFileAccessPermissions() async {
    final status = await getStoragePermissionStatus();
    return status == PermissionStatus.granted;
  }

  /// Request all necessary permissions for file operations
  Future<Map<Permission, PermissionStatus>> requestAllFilePermissions() async {
    final permissions = <Permission>[];

    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;

      if (androidInfo.version.sdkInt >= 30) {
        // Android 11+
        permissions.add(Permission.manageExternalStorage);
      } else {
        // Older Android
        permissions.add(Permission.storage);
      }
    }

    if (permissions.isEmpty) {
      return {}; // No permissions needed
    }

    return await permissions.request();
  }

  /// Get permission explanation for user
  Future<PermissionExplanation> getPermissionExplanation() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;

      if (androidInfo.version.sdkInt >= 30) {
        return const PermissionExplanation(
          title: 'File Management Permission Required',
          description:
              'This app needs permission to manage files on your device to save and load workspaces.',
          isRequired: true,
          alternativeApproach:
              'You can choose a specific folder using the folder picker instead.',
          settingsInstructions:
              'Go to Settings > Apps > Structurizr > Permissions > Files and media > Allow management of all files',
        );
      } else {
        return const PermissionExplanation(
          title: 'Storage Permission Required',
          description:
              'This app needs storage permission to save and load workspace files.',
          isRequired: true,
          alternativeApproach:
              'Files will be saved to the app\'s private directory only.',
          settingsInstructions:
              'Go to Settings > Apps > Structurizr > Permissions > Storage > Allow',
        );
      }
    }

    // iOS or other platforms
    return const PermissionExplanation(
      title: 'No Permissions Required',
      description: 'This platform uses app-specific storage directories.',
      isRequired: false,
      alternativeApproach: null,
      settingsInstructions: null,
    );
  }

  /// Check if permission is permanently denied
  Future<bool> isPermissionPermanentlyDenied(Permission permission) async {
    final status = await permission.status;
    return status == PermissionStatus.permanentlyDenied;
  }

  /// Open app settings for permission management
  Future<bool> openAppSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      debugPrint('Error opening app settings: $e');
      return false;
    }
  }

  /// Get available storage options based on permissions
  Future<List<StorageOption>> getAvailableStorageOptions() async {
    final options = <StorageOption>[];

    // App-specific storage (always available)
    options.add(const StorageOption(
      type: StorageType.appSpecific,
      displayName: 'App Storage',
      description: 'Private app directory (always accessible)',
      requiresPermission: false,
      isRecommended: true,
    ));

    if (Platform.isAndroid) {
      final hasStoragePermission = await hasFileAccessPermissions();

      // External storage option
      options.add(StorageOption(
        type: StorageType.external,
        displayName: 'Device Storage',
        description: 'Accessible from file manager and other apps',
        requiresPermission: true,
        isRecommended: hasStoragePermission,
        isAvailable: hasStoragePermission,
      ));

      // Storage Access Framework option (Android 5+)
      final androidInfo = await _deviceInfo.androidInfo;
      if (androidInfo.version.sdkInt >= 21) {
        options.add(const StorageOption(
          type: StorageType.saf,
          displayName: 'Choose Folder',
          description: 'Select any folder using the system picker',
          requiresPermission: false,
          isRecommended: true,
          isAvailable: true,
        ));
      }
    } else if (Platform.isIOS) {
      // iOS Files app integration
      options.add(const StorageOption(
        type: StorageType.documentsDirectory,
        displayName: 'Files App',
        description: 'Accessible via the Files app',
        requiresPermission: false,
        isRecommended: true,
        isAvailable: true,
      ));
    }

    return options;
  }

  /// Handle permission denial scenarios
  Future<PermissionHandlingResult> handlePermissionDenial(
      Permission permission) async {
    final isPermanent = await isPermissionPermanentlyDenied(permission);

    if (isPermanent) {
      return const PermissionHandlingResult(
        canRetry: false,
        shouldShowSettings: true,
        fallbackOption: StorageType.appSpecific,
        message:
            'Permission permanently denied. Use app settings to enable, or continue with limited storage access.',
      );
    } else {
      return const PermissionHandlingResult(
        canRetry: true,
        shouldShowSettings: false,
        fallbackOption: StorageType.appSpecific,
        message:
            'Permission denied. You can retry or continue with app-specific storage.',
      );
    }
  }

  /// Get platform-specific storage information
  Future<PlatformStorageCapabilities> getStorageCapabilities() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;

      return PlatformStorageCapabilities(
        platform: 'Android',
        version:
            '${androidInfo.version.release} (API ${androidInfo.version.sdkInt})',
        supportsScopedStorage: androidInfo.version.sdkInt >= 29,
        supportsStorageAccessFramework: androidInfo.version.sdkInt >= 21,
        requiresManageExternalStorage: androidInfo.version.sdkInt >= 30,
        hasExternalStorage: true,
        supportsDirectoryPicker: true,
      );
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;

      return PlatformStorageCapabilities(
        platform: 'iOS',
        version: iosInfo.systemVersion,
        supportsScopedStorage: true, // iOS always uses app sandbox
        supportsStorageAccessFramework: false,
        requiresManageExternalStorage: false,
        hasExternalStorage: false,
        supportsDirectoryPicker: true, // UIDocumentPickerViewController
      );
    }

    return const PlatformStorageCapabilities(
      platform: 'Unknown',
      version: 'Unknown',
      supportsScopedStorage: false,
      supportsStorageAccessFramework: false,
      requiresManageExternalStorage: false,
      hasExternalStorage: false,
      supportsDirectoryPicker: false,
    );
  }
}

/// Permission explanation for users
class PermissionExplanation {
  final String title;
  final String description;
  final bool isRequired;
  final String? alternativeApproach;
  final String? settingsInstructions;

  const PermissionExplanation({
    required this.title,
    required this.description,
    required this.isRequired,
    this.alternativeApproach,
    this.settingsInstructions,
  });
}

/// Storage option types
enum StorageType {
  appSpecific,
  external,
  saf, // Storage Access Framework
  documentsDirectory,
}

/// Available storage option
class StorageOption {
  final StorageType type;
  final String displayName;
  final String description;
  final bool requiresPermission;
  final bool isRecommended;
  final bool isAvailable;

  const StorageOption({
    required this.type,
    required this.displayName,
    required this.description,
    required this.requiresPermission,
    required this.isRecommended,
    this.isAvailable = true,
  });
}

/// Result of permission handling
class PermissionHandlingResult {
  final bool canRetry;
  final bool shouldShowSettings;
  final StorageType fallbackOption;
  final String message;

  const PermissionHandlingResult({
    required this.canRetry,
    required this.shouldShowSettings,
    required this.fallbackOption,
    required this.message,
  });
}

/// Platform storage capabilities
class PlatformStorageCapabilities {
  final String platform;
  final String version;
  final bool supportsScopedStorage;
  final bool supportsStorageAccessFramework;
  final bool requiresManageExternalStorage;
  final bool hasExternalStorage;
  final bool supportsDirectoryPicker;

  const PlatformStorageCapabilities({
    required this.platform,
    required this.version,
    required this.supportsScopedStorage,
    required this.supportsStorageAccessFramework,
    required this.requiresManageExternalStorage,
    required this.hasExternalStorage,
    required this.supportsDirectoryPicker,
  });

  @override
  String toString() {
    return 'PlatformStorageCapabilities(platform: $platform, version: $version, '
        'scopedStorage: $supportsScopedStorage, saf: $supportsStorageAccessFramework, '
        'manageExternal: $requiresManageExternalStorage, external: $hasExternalStorage, '
        'directoryPicker: $supportsDirectoryPicker)';
  }
}
