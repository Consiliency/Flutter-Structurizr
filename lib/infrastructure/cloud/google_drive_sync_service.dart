import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'cloud_storage_service.dart';

/// Google Drive cloud storage service implementation
/// Provides Google Drive integration for workspace synchronization
class GoogleDriveSyncService extends CloudStorageService {
  static const _channel = MethodChannel('com.structurizr.flutter/google_drive');

  String? _accessToken;
  DateTime? _tokenExpiry;
  final String _clientId;
  final String _clientSecret;

  GoogleDriveSyncService({
    required String clientId,
    required String clientSecret,
  })  : _clientId = clientId,
        _clientSecret = clientSecret;

  @override
  String get serviceId => 'google_drive';

  @override
  String get displayName => 'Google Drive';

  @override
  Future<bool> isAvailable() async {
    try {
      // Check if Google Play Services are available on Android
      final result = await _channel.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> authenticate() async {
    try {
      final result =
          await _channel.invokeMethod<Map<String, dynamic>>('authenticate', {
        'clientId': _clientId,
        'scopes': ['https://www.googleapis.com/auth/drive.file'],
      });

      if (result != null) {
        _accessToken = result['accessToken'] as String?;
        final expiresIn = result['expiresIn'] as int?;
        if (expiresIn != null) {
          _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
        }
        return _accessToken != null;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    if (_accessToken == null || _tokenExpiry == null) {
      return false;
    }

    // Check if token is still valid (with 5 minute buffer)
    final now = DateTime.now();
    final bufferTime = _tokenExpiry!.subtract(const Duration(minutes: 5));

    if (now.isAfter(bufferTime)) {
      // Try to refresh token
      return await _refreshToken();
    }

    return true;
  }

  @override
  Future<void> signOut() async {
    try {
      await _channel.invokeMethod('signOut');
      _accessToken = null;
      _tokenExpiry = null;
    } catch (e) {
      // Ignore errors during sign out
    }
  }

  @override
  Future<CloudUploadResult> uploadFile(String localPath, String remotePath,
      {Map<String, String>? metadata}) async {
    if (!await isAuthenticated()) {
      return const CloudUploadResult(
        success: false,
        error: 'Not authenticated with Google Drive',
      );
    }

    try {
      final file = File(localPath);
      if (!await file.exists()) {
        return CloudUploadResult(
          success: false,
          error: 'Local file does not exist: $localPath',
        );
      }

      final fileBytes = await file.readAsBytes();
      final fileName = remotePath.split('/').last;

      // Create or update file on Google Drive
      final fileId = await _findOrCreateFile(fileName, remotePath);

      final response = await http.patch(
        Uri.parse(
            'https://www.googleapis.com/upload/drive/v3/files/$fileId?uploadType=media'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/octet-stream',
        },
        body: fileBytes,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return CloudUploadResult(
          success: true,
          fileId: responseData['id'] as String?,
          url: 'https://drive.google.com/file/d/${responseData['id']}/view',
          size: fileBytes.length,
        );
      } else {
        return CloudUploadResult(
          success: false,
          error:
              'Upload failed: ${response.statusCode} ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return CloudUploadResult(
        success: false,
        error: 'Upload error: $e',
      );
    }
  }

  @override
  Future<CloudDownloadResult> downloadFile(
      String remotePath, String localPath) async {
    if (!await isAuthenticated()) {
      return const CloudDownloadResult(
        success: false,
        error: 'Not authenticated with Google Drive',
      );
    }

    try {
      final fileName = remotePath.split('/').last;
      final fileId = await _findFileByName(fileName);

      if (fileId == null) {
        return CloudDownloadResult(
          success: false,
          error: 'File not found: $remotePath',
        );
      }

      final response = await http.get(
        Uri.parse(
            'https://www.googleapis.com/drive/v3/files/$fileId?alt=media'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final localFile = File(localPath);
        await localFile.parent.create(recursive: true);
        await localFile.writeAsBytes(response.bodyBytes);

        return CloudDownloadResult(
          success: true,
          localPath: localPath,
          size: response.bodyBytes.length,
        );
      } else {
        return CloudDownloadResult(
          success: false,
          error:
              'Download failed: ${response.statusCode} ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return CloudDownloadResult(
        success: false,
        error: 'Download error: $e',
      );
    }
  }

  @override
  Future<CloudFileInfo?> getFileInfo(String remotePath) async {
    if (!await isAuthenticated()) {
      return null;
    }

    try {
      final fileName = remotePath.split('/').last;
      final fileId = await _findFileByName(fileName);

      if (fileId == null) {
        return null;
      }

      final response = await http.get(
        Uri.parse(
            'https://www.googleapis.com/drive/v3/files/$fileId?fields=id,name,size,modifiedTime,md5Checksum'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CloudFileInfo(
          id: data['id'] as String,
          name: data['name'] as String,
          size: int.tryParse(data['size']?.toString() ?? '0') ?? 0,
          modifiedTime: DateTime.parse(data['modifiedTime'] as String),
          checksum: data['md5Checksum'] as String?,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<CloudFileInfo>> listFiles(String remotePath) async {
    if (!await isAuthenticated()) {
      return [];
    }

    try {
      String query = 'trashed=false';
      if (remotePath.isNotEmpty) {
        // In Google Drive, we'll use the app data folder or a specific folder
        query += " and parents in 'appDataFolder'";
      }

      final response = await http.get(
        Uri.parse(
            'https://www.googleapis.com/drive/v3/files?q=${Uri.encodeQueryComponent(query)}&fields=files(id,name,size,modifiedTime,md5Checksum)'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final files = data['files'] as List;

        return files
            .map((file) => CloudFileInfo(
                  id: file['id'] as String,
                  name: file['name'] as String,
                  size: int.tryParse(file['size']?.toString() ?? '0') ?? 0,
                  modifiedTime: DateTime.parse(file['modifiedTime'] as String),
                  checksum: file['md5Checksum'] as String?,
                ))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<bool> deleteFile(String remotePath) async {
    if (!await isAuthenticated()) {
      return false;
    }

    try {
      final fileName = remotePath.split('/').last;
      final fileId = await _findFileByName(fileName);

      if (fileId == null) {
        return false;
      }

      final response = await http.delete(
        Uri.parse('https://www.googleapis.com/drive/v3/files/$fileId'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      return response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<CloudSyncResult> syncDirectory(
      String localPath, String remotePath) async {
    if (!await isAuthenticated()) {
      return const CloudSyncResult(
        success: false,
        error: 'Not authenticated with Google Drive',
        uploadedFiles: [],
        downloadedFiles: [],
        conflicts: [],
      );
    }

    final localDir = Directory(localPath);
    if (!await localDir.exists()) {
      return CloudSyncResult(
        success: false,
        error: 'Local directory does not exist: $localPath',
        uploadedFiles: [],
        downloadedFiles: [],
        conflicts: [],
      );
    }

    try {
      final uploadedFiles = <String>[];
      final downloadedFiles = <String>[];
      final conflicts = <CloudSyncConflict>[];

      // Get local files
      final localFiles = await localDir
          .list(recursive: true)
          .where((entity) => entity is File)
          .cast<File>()
          .toList();

      // Get remote files
      final remoteFiles = await listFiles(remotePath);
      final remoteFileMap = <String, CloudFileInfo>{};
      for (final file in remoteFiles) {
        remoteFileMap[file.name] = file;
      }

      // Upload local files that are newer or don't exist remotely
      for (final localFile in localFiles) {
        final relativePath = localFile.path.substring(localPath.length + 1);
        final fileName = localFile.path.split('/').last;
        final localStat = await localFile.stat();

        final remoteFile = remoteFileMap[fileName];

        if (remoteFile == null) {
          // File doesn't exist remotely, upload it
          final result = await uploadFile(localFile.path, relativePath);
          if (result.success) {
            uploadedFiles.add(relativePath);
          }
        } else {
          // File exists remotely, check for conflicts
          final localModified = localStat.modified;
          final remoteModified = remoteFile.modifiedTime;

          if (localModified.isAfter(remoteModified)) {
            // Local is newer, upload
            final result = await uploadFile(localFile.path, relativePath);
            if (result.success) {
              uploadedFiles.add(relativePath);
            }
          } else if (remoteModified.isAfter(localModified)) {
            // Remote is newer, download
            final result = await downloadFile(relativePath, localFile.path);
            if (result.success) {
              downloadedFiles.add(relativePath);
            }
          }
          // If times are equal, no sync needed

          remoteFileMap.remove(fileName);
        }
      }

      // Download remote files that don't exist locally
      for (final remoteFile in remoteFileMap.values) {
        final localPath = '${localDir.path}/${remoteFile.name}';
        final result = await downloadFile(remoteFile.name, localPath);
        if (result.success) {
          downloadedFiles.add(remoteFile.name);
        }
      }

      return CloudSyncResult(
        success: true,
        uploadedFiles: uploadedFiles,
        downloadedFiles: downloadedFiles,
        conflicts: conflicts,
      );
    } catch (e) {
      return CloudSyncResult(
        success: false,
        error: 'Sync error: $e',
        uploadedFiles: [],
        downloadedFiles: [],
        conflicts: [],
      );
    }
  }

  @override
  Future<CloudQuotaInfo> getQuotaInfo() async {
    if (!await isAuthenticated()) {
      return const CloudQuotaInfo(
        totalBytes: 0,
        usedBytes: 0,
        availableBytes: 0,
      );
    }

    try {
      final response = await http.get(
        Uri.parse(
            'https://www.googleapis.com/drive/v3/about?fields=storageQuota'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final quota = data['storageQuota'];

        return CloudQuotaInfo(
          totalBytes: int.tryParse(quota['limit']?.toString() ?? '0') ?? 0,
          usedBytes: int.tryParse(quota['usage']?.toString() ?? '0') ?? 0,
          availableBytes:
              (int.tryParse(quota['limit']?.toString() ?? '0') ?? 0) -
                  (int.tryParse(quota['usage']?.toString() ?? '0') ?? 0),
        );
      }

      return const CloudQuotaInfo(
        totalBytes: 0,
        usedBytes: 0,
        availableBytes: 0,
      );
    } catch (e) {
      return const CloudQuotaInfo(
        totalBytes: 0,
        usedBytes: 0,
        availableBytes: 0,
      );
    }
  }

  /// Refresh the access token
  Future<bool> _refreshToken() async {
    try {
      final result =
          await _channel.invokeMethod<Map<String, dynamic>>('refreshToken');

      if (result != null) {
        _accessToken = result['accessToken'] as String?;
        final expiresIn = result['expiresIn'] as int?;
        if (expiresIn != null) {
          _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
        }
        return _accessToken != null;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Find a file by name or create it if it doesn't exist
  Future<String> _findOrCreateFile(String fileName, String remotePath) async {
    final existingFileId = await _findFileByName(fileName);
    if (existingFileId != null) {
      return existingFileId;
    }

    // Create new file
    final response = await http.post(
      Uri.parse('https://www.googleapis.com/drive/v3/files'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'name': fileName,
        'parents': ['appDataFolder'], // Store in app data folder
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['id'] as String;
    } else {
      throw Exception(
          'Failed to create file: ${response.statusCode} ${response.reasonPhrase}');
    }
  }

  /// Find a file by name
  Future<String?> _findFileByName(String fileName) async {
    final query =
        "name='$fileName' and trashed=false and parents in 'appDataFolder'";

    final response = await http.get(
      Uri.parse(
          'https://www.googleapis.com/drive/v3/files?q=${Uri.encodeQueryComponent(query)}&fields=files(id)'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final files = data['files'] as List;

      if (files.isNotEmpty) {
        return files.first['id'] as String;
      }
    }

    return null;
  }
}
