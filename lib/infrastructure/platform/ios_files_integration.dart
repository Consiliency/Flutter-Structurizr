import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class IOSFilesIntegration {
  static const MethodChannel _channel = MethodChannel('structurizr/ios_files');
  
  static IOSFilesIntegration? _instance;
  static IOSFilesIntegration get instance => _instance ??= IOSFilesIntegration._();
  
  IOSFilesIntegration._();
  
  /// Check if iOS Files app integration is available
  bool get isAvailable => !kIsWeb && Platform.isIOS;
  
  /// Enable Files app access for workspace directory
  Future<bool> enableFilesAppAccess(String workspaceDirectory) async {
    if (!isAvailable) return false;
    
    try {
      final result = await _channel.invokeMethod<bool>('enableFilesAccess', {
        'directory': workspaceDirectory,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Error enabling Files app access: $e');
      return false;
    }
  }
  
  /// Disable Files app access
  Future<bool> disableFilesAppAccess() async {
    if (!isAvailable) return true;
    
    try {
      final result = await _channel.invokeMethod<bool>('disableFilesAccess');
      return result ?? false;
    } catch (e) {
      debugPrint('Error disabling Files app access: $e');
      return false;
    }
  }
  
  /// Check if directory is accessible via Files app
  Future<bool> isDirectoryAccessible(String directory) async {
    if (!isAvailable) return false;
    
    try {
      final result = await _channel.invokeMethod<bool>('isDirectoryAccessible', {
        'directory': directory,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Error checking directory accessibility: $e');
      return false;
    }
  }
  
  /// Create security-scoped bookmark for persistent access
  Future<String?> createBookmark(String filePath) async {
    if (!isAvailable) return null;
    
    try {
      final result = await _channel.invokeMethod<String>('createBookmark', {
        'filePath': filePath,
      });
      return result;
    } catch (e) {
      debugPrint('Error creating bookmark: $e');
      return null;
    }
  }
  
  /// Resolve security-scoped bookmark
  Future<String?> resolveBookmark(String bookmarkData) async {
    if (!isAvailable) return null;
    
    try {
      final result = await _channel.invokeMethod<String>('resolveBookmark', {
        'bookmarkData': bookmarkData,
      });
      return result;
    } catch (e) {
      debugPrint('Error resolving bookmark: $e');
      return null;
    }
  }
  
  /// Start accessing security-scoped resource
  Future<bool> startAccessingSecurityScopedResource(String bookmarkData) async {
    if (!isAvailable) return false;
    
    try {
      final result = await _channel.invokeMethod<bool>('startAccessingResource', {
        'bookmarkData': bookmarkData,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Error starting resource access: $e');
      return false;
    }
  }
  
  /// Stop accessing security-scoped resource
  Future<bool> stopAccessingSecurityScopedResource(String bookmarkData) async {
    if (!isAvailable) return true;
    
    try {
      final result = await _channel.invokeMethod<bool>('stopAccessingResource', {
        'bookmarkData': bookmarkData,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Error stopping resource access: $e');
      return false;
    }
  }
  
  /// Get Files app capabilities
  Future<IOSFilesCapabilities> getCapabilities() async {
    if (!isAvailable) {
      return const IOSFilesCapabilities(
        supportsDocumentProvider: false,
        supportsFileCoordination: false,
        supportsSecurityScopedBookmarks: false,
        supportsDirectoryAccess: false,
      );
    }
    
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getCapabilities');
      
      if (result != null) {
        return IOSFilesCapabilities(
          supportsDocumentProvider: result['documentProvider'] as bool? ?? false,
          supportsFileCoordination: result['fileCoordination'] as bool? ?? false,
          supportsSecurityScopedBookmarks: result['securityScopedBookmarks'] as bool? ?? false,
          supportsDirectoryAccess: result['directoryAccess'] as bool? ?? false,
        );
      }
    } catch (e) {
      debugPrint('Error getting capabilities: $e');
    }
    
    return const IOSFilesCapabilities(
      supportsDocumentProvider: false,
      supportsFileCoordination: false,
      supportsSecurityScopedBookmarks: false,
      supportsDirectoryAccess: false,
    );
  }
  
  /// Configure document provider settings
  Future<bool> configureDocumentProvider({
    required String displayName,
    required String identifier,
    required List<String> supportedFileTypes,
  }) async {
    if (!isAvailable) return false;
    
    try {
      final result = await _channel.invokeMethod<bool>('configureDocumentProvider', {
        'displayName': displayName,
        'identifier': identifier,
        'supportedFileTypes': supportedFileTypes,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Error configuring document provider: $e');
      return false;
    }
  }
  
  /// Handle document provider requests
  Future<void> handleDocumentProviderRequest(String requestType, Map<String, dynamic> parameters) async {
    if (!isAvailable) return;
    
    try {
      await _channel.invokeMethod('handleDocumentProviderRequest', {
        'requestType': requestType,
        'parameters': parameters,
      });
    } catch (e) {
      debugPrint('Error handling document provider request: $e');
    }
  }
  
  /// Monitor Files app access status
  Stream<IOSFilesAccessStatus> get accessStatusStream {
    if (!isAvailable) {
      return Stream.value(const IOSFilesAccessStatus(
        isEnabled: false,
        accessibleDirectories: [],
        activeBookmarks: [],
      ));
    }
    
    return const EventChannel('structurizr/ios_files_events')
        .receiveBroadcastStream()
        .map((data) {
      final map = data as Map<dynamic, dynamic>;
      return IOSFilesAccessStatus(
        isEnabled: map['isEnabled'] as bool? ?? false,
        accessibleDirectories: List<String>.from(map['accessibleDirectories'] ?? []),
        activeBookmarks: List<String>.from(map['activeBookmarks'] ?? []),
      );
    });
  }
}

/// iOS Files app capabilities
class IOSFilesCapabilities {
  final bool supportsDocumentProvider;
  final bool supportsFileCoordination;
  final bool supportsSecurityScopedBookmarks;
  final bool supportsDirectoryAccess;
  
  const IOSFilesCapabilities({
    required this.supportsDocumentProvider,
    required this.supportsFileCoordination,
    required this.supportsSecurityScopedBookmarks,
    required this.supportsDirectoryAccess,
  });
  
  @override
  String toString() {
    return 'IOSFilesCapabilities(documentProvider: $supportsDocumentProvider, '
           'fileCoordination: $supportsFileCoordination, '
           'securityScopedBookmarks: $supportsSecurityScopedBookmarks, '
           'directoryAccess: $supportsDirectoryAccess)';
  }
}

/// iOS Files app access status
class IOSFilesAccessStatus {
  final bool isEnabled;
  final List<String> accessibleDirectories;
  final List<String> activeBookmarks;
  
  const IOSFilesAccessStatus({
    required this.isEnabled,
    required this.accessibleDirectories,
    required this.activeBookmarks,
  });
  
  @override
  String toString() {
    return 'IOSFilesAccessStatus(enabled: $isEnabled, '
           'directories: ${accessibleDirectories.length}, '
           'bookmarks: ${activeBookmarks.length})';
  }
}