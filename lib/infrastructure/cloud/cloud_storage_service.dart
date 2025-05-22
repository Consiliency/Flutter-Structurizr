abstract class CloudStorageService {
  String get serviceId;
  String get displayName;
  
  Future<bool> isAvailable();
  Future<bool> authenticate();
  Future<bool> isAuthenticated();
  Future<void> signOut();
  
  Future<CloudUploadResult> uploadFile(String localPath, String remotePath, {Map<String, String>? metadata});
  Future<CloudDownloadResult> downloadFile(String remotePath, String localPath);
  Future<CloudFileInfo?> getFileInfo(String remotePath);
  Future<List<CloudFileInfo>> listFiles(String remotePath);
  Future<bool> deleteFile(String remotePath);
  
  Future<CloudSyncResult> syncDirectory(String localPath, String remotePath);
  Future<CloudQuotaInfo> getQuotaInfo();
}

class CloudStorageManager {
  static CloudStorageManager? _instance;
  static CloudStorageManager get instance => _instance ??= CloudStorageManager._();
  
  CloudStorageManager._();
  
  final Map<String, CloudStorageService> _services = {};
  
  void registerService(CloudStorageService service) {
    _services[service.serviceId] = service;
  }
  
  CloudStorageService? getService(String serviceId) {
    return _services[serviceId];
  }
  
  Future<List<CloudStorageService>> getAvailableServices() async {
    final availableServices = <CloudStorageService>[];
    for (final service in _services.values) {
      if (await service.isAvailable()) {
        availableServices.add(service);
      }
    }
    return availableServices;
  }
  
  Future<List<CloudStorageService>> getAuthenticatedServices() async {
    final authenticatedServices = <CloudStorageService>[];
    
    for (final service in _services.values) {
      if (await service.isAvailable() && await service.isAuthenticated()) {
        authenticatedServices.add(service);
      }
    }
    
    return authenticatedServices;
  }
}

/// Cloud file information
class CloudFileInfo {
  final String id;
  final String name;
  final int size;
  final DateTime modifiedTime;
  final String? checksum;
  
  const CloudFileInfo({
    required this.id,
    required this.name,
    required this.size,
    required this.modifiedTime,
    this.checksum,
  });
  
  @override
  String toString() {
    return 'CloudFileInfo(id: $id, name: $name, size: $size, modifiedTime: $modifiedTime)';
  }
}

/// Cloud upload result
class CloudUploadResult {
  final bool success;
  final String? fileId;
  final String? url;
  final int? size;
  final String? error;
  
  const CloudUploadResult({
    required this.success,
    this.fileId,
    this.url,
    this.size,
    this.error,
  });
  
  @override
  String toString() {
    return 'CloudUploadResult(success: $success, fileId: $fileId, '
           'size: $size, error: $error)';
  }
}

/// Cloud download result
class CloudDownloadResult {
  final bool success;
  final String? localPath;
  final int? size;
  final String? error;
  
  const CloudDownloadResult({
    required this.success,
    this.localPath,
    this.size,
    this.error,
  });
  
  @override
  String toString() {
    return 'CloudDownloadResult(success: $success, localPath: $localPath, '
           'size: $size, error: $error)';
  }
}

/// Cloud sync result
class CloudSyncResult {
  final bool success;
  final List<String> uploadedFiles;
  final List<String> downloadedFiles;
  final List<CloudSyncConflict> conflicts;
  final String? error;
  
  const CloudSyncResult({
    required this.success,
    required this.uploadedFiles,
    required this.downloadedFiles,
    required this.conflicts,
    this.error,
  });
  
  @override
  String toString() {
    return 'CloudSyncResult(success: $success, uploaded: ${uploadedFiles.length}, '
           'downloaded: ${downloadedFiles.length}, conflicts: ${conflicts.length})';
  }
}

/// Cloud sync conflict
class CloudSyncConflict {
  final String filePath;
  final String localContent;
  final String remoteContent;
  final DateTime timestamp;
  
  const CloudSyncConflict({
    required this.filePath,
    required this.localContent,
    required this.remoteContent,
    required this.timestamp,
  });
}

/// Cloud quota information
class CloudQuotaInfo {
  final int totalBytes;
  final int usedBytes;
  final int availableBytes;
  
  const CloudQuotaInfo({
    required this.totalBytes,
    required this.usedBytes,
    required this.availableBytes,
  });
  
  double get usagePercentage => totalBytes > 0 ? (usedBytes / totalBytes) * 100 : 0;
}