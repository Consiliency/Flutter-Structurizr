import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'cloud_storage_service.dart';

class ICloudSyncService extends CloudStorageService {
  static const MethodChannel _channel = MethodChannel('structurizr/icloud_sync');
  
  static ICloudSyncService? _instance;
  static ICloudSyncService get instance => _instance ??= ICloudSyncService._();
  
  ICloudSyncService._();
  
  /// Public constructor
  ICloudSyncService();
  
  bool _isInitialized = false;
  bool _isAuthenticated = false;
  
  @override
  String get serviceId => 'icloud';
  
  @override
  String get displayName => 'iCloud';
  
  @override
  Future<bool> isAvailable() async => !kIsWeb && Platform.isIOS;
  
  Future<bool> initialize() async {
    if (!await isAvailable()) return false;
    if (_isInitialized) return true;
    
    try {
      final result = await _channel.invokeMethod<bool>('initialize');
      _isInitialized = result ?? false;
      return _isInitialized;
    } catch (e) {
      debugPrint('Error initializing iCloud sync: $e');
      return false;
    }
  }
  
  @override
  Future<bool> authenticate() async {
    if (!await isAvailable() || !_isInitialized) return false;
    
    try {
      final result = await _channel.invokeMethod<bool>('authenticate');
      _isAuthenticated = result ?? false;
      return _isAuthenticated;
    } catch (e) {
      debugPrint('Error authenticating with iCloud: $e');
      return false;
    }
  }
  
  @override
  Future<bool> isAuthenticated() async {
    if (!await isAvailable()) return false;
    
    try {
      final result = await _channel.invokeMethod<bool>('isAuthenticated');
      _isAuthenticated = result ?? false;
      return _isAuthenticated;
    } catch (e) {
      debugPrint('Error checking iCloud authentication: $e');
      return false;
    }
  }
  
  @override
  Future<void> signOut() async {
    if (!await isAvailable()) return;
    
    try {
      await _channel.invokeMethod('signOut');
      _isAuthenticated = false;
    } catch (e) {
      debugPrint('Error signing out of iCloud: $e');
    }
  }
  
  @override
  Future<CloudUploadResult> uploadFile(String localPath, String remotePath, {Map<String, String>? metadata}) async {
    if (!await isAvailable() || !_isAuthenticated) {
      return const CloudUploadResult(
        success: false,
        error: 'iCloud not available or not authenticated',
      );
    }
    
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('uploadFile', {
        'localPath': localPath,
        'remotePath': remotePath,
        'metadata': metadata,
      });
      
      if (result != null && result['success'] == true) {
        final fileSize = File(localPath).lengthSync();
        
        return CloudUploadResult(
          success: true,
          fileId: result['fileId'] as String?,
          url: result['url'] as String?,
          size: fileSize,
        );
      } else {
        return CloudUploadResult(
          success: false,
          error: result?['error'] as String? ?? 'Upload failed',
        );
      }
    } catch (e) {
      debugPrint('Error uploading file to iCloud: $e');
      return CloudUploadResult(
        success: false,
        error: e.toString(),
      );
    }
  }
  
  @override
  Future<CloudDownloadResult> downloadFile(String remotePath, String localPath) async {
    if (!await isAvailable() || !_isAuthenticated) {
      return const CloudDownloadResult(
        success: false,
        error: 'iCloud not available or not authenticated',
      );
    }
    
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('downloadFile', {
        'remotePath': remotePath,
        'localPath': localPath,
      });
      
      if (result != null && result['success'] == true) {
        final fileSize = await File(localPath).length();
        
        return CloudDownloadResult(
          success: true,
          localPath: localPath,
          size: fileSize,
        );
      } else {
        return CloudDownloadResult(
          success: false,
          error: result?['error'] as String? ?? 'Download failed',
        );
      }
    } catch (e) {
      debugPrint('Error downloading file from iCloud: $e');
      return CloudDownloadResult(
        success: false,
        error: e.toString(),
      );
    }
  }
  
  @override
  Future<CloudFileInfo?> getFileInfo(String remotePath) async {
    if (!await isAvailable() || !_isAuthenticated) return null;
    
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getFileInfo', {
        'remotePath': remotePath,
      });
      
      if (result != null) {
        return CloudFileInfo(
          id: result['id'] as String,
          name: result['name'] as String,
          size: result['size'] as int,
          modifiedTime: DateTime.parse(result['modifiedTime'] as String),
          checksum: result['checksum'] as String?,
        );
      }
    } catch (e) {
      debugPrint('Error getting file info from iCloud: $e');
    }
    
    return null;
  }
  
  @override
  Future<List<CloudFileInfo>> listFiles(String remotePath) async {
    if (!await isAvailable() || !_isAuthenticated) return [];
    
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('listFiles', {
        'remotePath': remotePath,
      });
      
      if (result != null) {
        return result.map((item) {
          final map = item as Map<dynamic, dynamic>;
          return CloudFileInfo(
            id: map['id'] as String,
            name: map['name'] as String,
            size: map['size'] as int,
            modifiedTime: DateTime.parse(map['modifiedTime'] as String),
            checksum: map['checksum'] as String?,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Error listing files from iCloud: $e');
    }
    
    return [];
  }
  
  @override
  Future<bool> deleteFile(String remotePath) async {
    if (!await isAvailable() || !_isAuthenticated) return false;
    
    try {
      final result = await _channel.invokeMethod<bool>('deleteFile', {
        'remotePath': remotePath,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Error deleting file from iCloud: $e');
      return false;
    }
  }
  
  @override
  Future<CloudSyncResult> syncDirectory(String localPath, String remotePath) async {
    if (!await isAvailable() || !_isAuthenticated) {
      return const CloudSyncResult(
        success: false,
        uploadedFiles: [],
        downloadedFiles: [],
        conflicts: [],
        error: 'iCloud not available or not authenticated',
      );
    }
    
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('syncDirectory', {
        'localPath': localPath,
        'remotePath': remotePath,
      });
      
      if (result != null) {
        final conflicts = (result['conflicts'] as List<dynamic>?)?.map((item) {
          final map = item as Map<dynamic, dynamic>;
          return CloudSyncConflict(
            filePath: map['filePath'] as String,
            localContent: map['localContent'] as String,
            remoteContent: map['remoteContent'] as String,
            timestamp: DateTime.now(),
          );
        }).toList() ?? [];
        
        return CloudSyncResult(
          success: result['success'] as bool? ?? false,
          uploadedFiles: List<String>.from((result['uploadedFiles'] as List<dynamic>?) ?? []),
          downloadedFiles: List<String>.from((result['downloadedFiles'] as List<dynamic>?) ?? []),
          conflicts: conflicts,
          error: result['error'] as String?,
        );
      }
    } catch (e) {
      debugPrint('Error syncing directory with iCloud: $e');
    }
    
    return const CloudSyncResult(
      success: false,
      uploadedFiles: [],
      downloadedFiles: [],
      conflicts: [],
      error: 'Sync failed',
    );
  }
  
  @override
  Future<CloudQuotaInfo> getQuotaInfo() async {
    if (!await isAvailable() || !_isAuthenticated) {
      return const CloudQuotaInfo(
        totalBytes: 0,
        usedBytes: 0,
        availableBytes: 0,
      );
    }
    
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getQuotaInfo');
      
      if (result != null) {
        return CloudQuotaInfo(
          totalBytes: result['totalBytes'] as int? ?? 0,
          usedBytes: result['usedBytes'] as int? ?? 0,
          availableBytes: result['availableBytes'] as int? ?? 0,
        );
      }
    } catch (e) {
      debugPrint('Error getting iCloud quota info: $e');
    }
    
    return const CloudQuotaInfo(
      totalBytes: 0,
      usedBytes: 0,
      availableBytes: 0,
    );
  }
  
  /// Check if iCloud Drive is enabled
  Future<bool> isICloudDriveEnabled() async {
    if (!await isAvailable()) return false;
    
    try {
      final result = await _channel.invokeMethod<bool>('isICloudDriveEnabled');
      return result ?? false;
    } catch (e) {
      debugPrint('Error checking iCloud Drive status: $e');
      return false;
    }
  }
  
  /// Enable automatic sync for directory
  Future<bool> enableAutoSync(String localPath, String remotePath) async {
    if (!await isAvailable() || !_isAuthenticated) return false;
    
    try {
      final result = await _channel.invokeMethod<bool>('enableAutoSync', {
        'localPath': localPath,
        'remotePath': remotePath,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Error enabling auto sync: $e');
      return false;
    }
  }
  
  /// Disable automatic sync
  Future<bool> disableAutoSync(String localPath) async {
    if (!await isAvailable()) return true;
    
    try {
      final result = await _channel.invokeMethod<bool>('disableAutoSync', {
        'localPath': localPath,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Error disabling auto sync: $e');
      return false;
    }
  }
}