import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AndroidShareIntegration {
  static const MethodChannel _channel = MethodChannel('structurizr/android_share');
  
  static AndroidShareIntegration? _instance;
  static AndroidShareIntegration get instance => _instance ??= AndroidShareIntegration._();
  
  AndroidShareIntegration._();
  
  /// Check if Android share integration is available
  bool get isAvailable => !kIsWeb && Platform.isAndroid;
  
  /// Initialize share target integration
  Future<bool> initialize() async {
    if (!isAvailable) return false;
    
    try {
      final result = await _channel.invokeMethod<bool>('initialize');
      return result ?? false;
    } catch (e) {
      debugPrint('Error initializing Android share integration: $e');
      return false;
    }
  }
  
  /// Handle incoming shared files
  Future<List<SharedFile>?> getSharedFiles() async {
    if (!isAvailable) return null;
    
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getSharedFiles');
      
      if (result != null) {
        return result.map((item) {
          final map = item as Map<dynamic, dynamic>;
          return SharedFile(
            path: map['path'] as String,
            name: map['name'] as String,
            mimeType: map['mimeType'] as String?,
            size: map['size'] as int?,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Error getting shared files: $e');
    }
    
    return null;
  }
  
  /// Clear shared files after processing
  Future<bool> clearSharedFiles() async {
    if (!isAvailable) return true;
    
    try {
      final result = await _channel.invokeMethod<bool>('clearSharedFiles');
      return result ?? false;
    } catch (e) {
      debugPrint('Error clearing shared files: $e');
      return false;
    }
  }
  
  /// Share workspace file
  Future<bool> shareWorkspace(String filePath, {String? title, String? subject}) async {
    if (!isAvailable) return false;
    
    try {
      final result = await _channel.invokeMethod<bool>('shareWorkspace', {
        'filePath': filePath,
        'title': title ?? 'Share Workspace',
        'subject': subject ?? 'Structurizr Workspace',
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Error sharing workspace: $e');
      return false;
    }
  }
  
  /// Share multiple workspace files
  Future<bool> shareMultipleWorkspaces(List<String> filePaths, {String? title, String? subject}) async {
    if (!isAvailable) return false;
    
    try {
      final result = await _channel.invokeMethod<bool>('shareMultipleWorkspaces', {
        'filePaths': filePaths,
        'title': title ?? 'Share Workspaces',
        'subject': subject ?? 'Structurizr Workspaces',
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Error sharing multiple workspaces: $e');
      return false;
    }
  }
  
  /// Configure share target settings
  Future<bool> configureShareTarget({
    required List<String> supportedMimeTypes,
    required List<String> supportedFileExtensions,
    String? activityLabel,
  }) async {
    if (!isAvailable) return false;
    
    try {
      final result = await _channel.invokeMethod<bool>('configureShareTarget', {
        'supportedMimeTypes': supportedMimeTypes,
        'supportedFileExtensions': supportedFileExtensions,
        'activityLabel': activityLabel ?? 'Import to Structurizr',
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Error configuring share target: $e');
      return false;
    }
  }
  
  /// Get share integration capabilities
  Future<AndroidShareCapabilities> getCapabilities() async {
    if (!isAvailable) {
      return const AndroidShareCapabilities(
        supportsShareTarget: false,
        supportsFileSharing: false,
        supportsMultipleFiles: false,
        supportsCustomMimeTypes: false,
      );
    }
    
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getCapabilities');
      
      if (result != null) {
        return AndroidShareCapabilities(
          supportsShareTarget: result['shareTarget'] as bool? ?? false,
          supportsFileSharing: result['fileSharing'] as bool? ?? false,
          supportsMultipleFiles: result['multipleFiles'] as bool? ?? false,
          supportsCustomMimeTypes: result['customMimeTypes'] as bool? ?? false,
        );
      }
    } catch (e) {
      debugPrint('Error getting capabilities: $e');
    }
    
    return const AndroidShareCapabilities(
      supportsShareTarget: false,
      supportsFileSharing: false,
      supportsMultipleFiles: false,
      supportsCustomMimeTypes: false,
    );
  }
  
  /// Check if app was opened via share intent
  Future<bool> wasOpenedViaShare() async {
    if (!isAvailable) return false;
    
    try {
      final result = await _channel.invokeMethod<bool>('wasOpenedViaShare');
      return result ?? false;
    } catch (e) {
      debugPrint('Error checking share intent: $e');
      return false;
    }
  }
  
  /// Get share intent details
  Future<ShareIntentData?> getShareIntentData() async {
    if (!isAvailable) return null;
    
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getShareIntentData');
      
      if (result != null) {
        return ShareIntentData(
          action: result['action'] as String?,
          type: result['type'] as String?,
          text: result['text'] as String?,
          subject: result['subject'] as String?,
          files: (result['files'] as List<dynamic>?)?.map((item) {
            final map = item as Map<dynamic, dynamic>;
            return SharedFile(
              path: map['path'] as String,
              name: map['name'] as String,
              mimeType: map['mimeType'] as String?,
              size: map['size'] as int?,
            );
          }).toList(),
        );
      }
    } catch (e) {
      debugPrint('Error getting share intent data: $e');
    }
    
    return null;
  }
  
  /// Register for share intent events
  Stream<ShareIntentEvent> get shareIntentStream {
    if (!isAvailable) {
      return const Stream.empty();
    }
    
    return const EventChannel('structurizr/android_share_events')
        .receiveBroadcastStream()
        .map((data) {
      final map = data as Map<dynamic, dynamic>;
      return ShareIntentEvent(
        type: ShareIntentEventType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => ShareIntentEventType.unknown,
        ),
        data: map['data'] as Map<dynamic, dynamic>?,
      );
    });
  }
  
  /// Create workspace shortcut on home screen
  Future<bool> createWorkspaceShortcut({
    required String workspaceName,
    required String workspacePath,
    String? iconPath,
  }) async {
    if (!isAvailable) return false;
    
    try {
      final result = await _channel.invokeMethod<bool>('createWorkspaceShortcut', {
        'workspaceName': workspaceName,
        'workspacePath': workspacePath,
        'iconPath': iconPath,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Error creating workspace shortcut: $e');
      return false;
    }
  }
  
  /// Check if shortcuts are supported
  Future<bool> supportsShortcuts() async {
    if (!isAvailable) return false;
    
    try {
      final result = await _channel.invokeMethod<bool>('supportsShortcuts');
      return result ?? false;
    } catch (e) {
      debugPrint('Error checking shortcut support: $e');
      return false;
    }
  }
}

/// Shared file information
class SharedFile {
  final String path;
  final String name;
  final String? mimeType;
  final int? size;
  
  const SharedFile({
    required this.path,
    required this.name,
    this.mimeType,
    this.size,
  });
  
  @override
  String toString() {
    return 'SharedFile(name: $name, path: $path, mimeType: $mimeType, size: $size)';
  }
}

/// Share intent data
class ShareIntentData {
  final String? action;
  final String? type;
  final String? text;
  final String? subject;
  final List<SharedFile>? files;
  
  const ShareIntentData({
    this.action,
    this.type,
    this.text,
    this.subject,
    this.files,
  });
  
  @override
  String toString() {
    return 'ShareIntentData(action: $action, type: $type, text: $text, '
           'subject: $subject, files: ${files?.length})';
  }
}

/// Android share capabilities
class AndroidShareCapabilities {
  final bool supportsShareTarget;
  final bool supportsFileSharing;
  final bool supportsMultipleFiles;
  final bool supportsCustomMimeTypes;
  
  const AndroidShareCapabilities({
    required this.supportsShareTarget,
    required this.supportsFileSharing,
    required this.supportsMultipleFiles,
    required this.supportsCustomMimeTypes,
  });
  
  @override
  String toString() {
    return 'AndroidShareCapabilities(shareTarget: $supportsShareTarget, '
           'fileSharing: $supportsFileSharing, multipleFiles: $supportsMultipleFiles, '
           'customMimeTypes: $supportsCustomMimeTypes)';
  }
}

/// Share intent event types
enum ShareIntentEventType {
  fileReceived,
  textReceived,
  multipleFilesReceived,
  shareTargetActivated,
  unknown,
}

/// Share intent event
class ShareIntentEvent {
  final ShareIntentEventType type;
  final Map<dynamic, dynamic>? data;
  
  const ShareIntentEvent({
    required this.type,
    this.data,
  });
  
  @override
  String toString() {
    return 'ShareIntentEvent(type: $type, data: $data)';
  }
}