import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static const String _workspaceHistoryKey = 'workspace_history';
  static const String _appConfigKey = 'app_config';
  static const String _userPreferencesKey = 'user_preferences';
  static const String _autoSaveKey = 'auto_save_enabled';
  static const String _backupSettingsKey = 'backup_settings';
  static const String _themeKey = 'theme_mode';
  static const String _lastOpenWorkspaceKey = 'last_open_workspace';
  
  static AppPreferences? _instance;
  static AppPreferences get instance => _instance ??= AppPreferences._();
  
  AppPreferences._();
  
  SharedPreferences? _prefs;
  
  /// Initialize the preferences service
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }
  
  /// Workspace History Management
  
  /// Get workspace history
  Future<List<WorkspaceHistoryEntry>> getWorkspaceHistory() async {
    await initialize();
    final historyJson = _prefs?.getString(_workspaceHistoryKey);
    
    if (historyJson == null) return [];
    
    try {
      final List<dynamic> historyList = jsonDecode(historyJson) as List<dynamic>;
      return historyList
          .map((json) => WorkspaceHistoryEntry.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading workspace history: $e');
      return [];
    }
  }
  
  /// Add workspace to history
  Future<void> addToWorkspaceHistory(WorkspaceHistoryEntry entry) async {
    final history = await getWorkspaceHistory();
    
    // Remove existing entry with same path to avoid duplicates
    history.removeWhere((item) => item.filePath == entry.filePath);
    
    // Add new entry at the beginning
    history.insert(0, entry);
    
    // Keep only the last 20 entries
    if (history.length > 20) {
      history.removeRange(20, history.length);
    }
    
    await _saveWorkspaceHistory(history);
  }
  
  /// Remove workspace from history
  Future<void> removeFromWorkspaceHistory(String filePath) async {
    final history = await getWorkspaceHistory();
    history.removeWhere((item) => item.filePath == filePath);
    await _saveWorkspaceHistory(history);
  }
  
  /// Clear workspace history
  Future<void> clearWorkspaceHistory() async {
    await initialize();
    await _prefs?.remove(_workspaceHistoryKey);
  }
  
  /// Save workspace history
  Future<void> _saveWorkspaceHistory(List<WorkspaceHistoryEntry> history) async {
    await initialize();
    final historyJson = jsonEncode(history.map((entry) => entry.toJson()).toList());
    await _prefs?.setString(_workspaceHistoryKey, historyJson);
  }
  
  /// App Configuration Management
  
  /// Get app configuration
  Future<AppConfiguration> getAppConfiguration() async {
    await initialize();
    final configJson = _prefs?.getString(_appConfigKey);
    
    if (configJson == null) {
      return AppConfiguration.defaultConfig();
    }
    
    try {
      final configMap = jsonDecode(configJson) as Map<String, dynamic>;
      return AppConfiguration.fromJson(configMap);
    } catch (e) {
      debugPrint('Error loading app configuration: $e');
      return AppConfiguration.defaultConfig();
    }
  }
  
  /// Save app configuration
  Future<void> saveAppConfiguration(AppConfiguration config) async {
    await initialize();
    final configJson = jsonEncode(config.toJson());
    await _prefs?.setString(_appConfigKey, configJson);
  }
  
  /// User Preferences Management
  
  /// Get user preferences
  Future<UserPreferences> getUserPreferences() async {
    await initialize();
    final prefsJson = _prefs?.getString(_userPreferencesKey);
    
    if (prefsJson == null) {
      return UserPreferences.defaultPreferences();
    }
    
    try {
      final prefsMap = jsonDecode(prefsJson) as Map<String, dynamic>;
      return UserPreferences.fromJson(prefsMap);
    } catch (e) {
      debugPrint('Error loading user preferences: $e');
      return UserPreferences.defaultPreferences();
    }
  }
  
  /// Save user preferences
  Future<void> saveUserPreferences(UserPreferences preferences) async {
    await initialize();
    final prefsJson = jsonEncode(preferences.toJson());
    await _prefs?.setString(_userPreferencesKey, prefsJson);
  }
  
  /// Auto-save Settings
  
  /// Get auto-save enabled state
  Future<bool> getAutoSaveEnabled() async {
    await initialize();
    return _prefs?.getBool(_autoSaveKey) ?? true; // Default to enabled
  }
  
  /// Set auto-save enabled state
  Future<void> setAutoSaveEnabled(bool enabled) async {
    await initialize();
    await _prefs?.setBool(_autoSaveKey, enabled);
  }
  
  /// Backup Settings
  
  /// Get backup settings
  Future<BackupSettings> getBackupSettings() async {
    await initialize();
    final backupJson = _prefs?.getString(_backupSettingsKey);
    
    if (backupJson == null) {
      return BackupSettings.defaultSettings();
    }
    
    try {
      final backupMap = jsonDecode(backupJson) as Map<String, dynamic>;
      return BackupSettings.fromJson(backupMap);
    } catch (e) {
      debugPrint('Error loading backup settings: $e');
      return BackupSettings.defaultSettings();
    }
  }
  
  /// Save backup settings
  Future<void> saveBackupSettings(BackupSettings settings) async {
    await initialize();
    final backupJson = jsonEncode(settings.toJson());
    await _prefs?.setString(_backupSettingsKey, backupJson);
  }
  
  /// Theme Management
  
  /// Get theme mode
  Future<String> getThemeMode() async {
    await initialize();
    return _prefs?.getString(_themeKey) ?? 'system'; // Default to system theme
  }
  
  /// Set theme mode
  Future<void> setThemeMode(String themeMode) async {
    await initialize();
    await _prefs?.setString(_themeKey, themeMode);
  }
  
  /// Last Open Workspace
  
  /// Get last open workspace path
  Future<String?> getLastOpenWorkspace() async {
    await initialize();
    return _prefs?.getString(_lastOpenWorkspaceKey);
  }
  
  /// Set last open workspace path
  Future<void> setLastOpenWorkspace(String? workspacePath) async {
    await initialize();
    if (workspacePath != null) {
      await _prefs?.setString(_lastOpenWorkspaceKey, workspacePath);
    } else {
      await _prefs?.remove(_lastOpenWorkspaceKey);
    }
  }
  
  /// Platform-specific Preferences
  
  /// Save platform-specific preference
  Future<void> setPlatformPreference(String key, dynamic value) async {
    await initialize();
    
    if (value is String) {
      await _prefs?.setString(key, value);
    } else if (value is bool) {
      await _prefs?.setBool(key, value);
    } else if (value is int) {
      await _prefs?.setInt(key, value);
    } else if (value is double) {
      await _prefs?.setDouble(key, value);
    } else if (value is List<String>) {
      await _prefs?.setStringList(key, value);
    } else {
      // Store as JSON for complex objects
      await _prefs?.setString(key, jsonEncode(value));
    }
  }
  
  /// Get platform-specific preference
  Future<T?> getPlatformPreference<T>(String key) async {
    await initialize();
    
    if (T == String) {
      return _prefs?.getString(key) as T?;
    } else if (T == bool) {
      return _prefs?.getBool(key) as T?;
    } else if (T == int) {
      return _prefs?.getInt(key) as T?;
    } else if (T == double) {
      return _prefs?.getDouble(key) as T?;
    } else {
      final value = _prefs?.getString(key);
      if (value != null) {
        try {
          return jsonDecode(value) as T;
        } catch (e) {
          debugPrint('Error decoding platform preference $key: $e');
        }
      }
    }
    
    return null;
  }
  
  /// Clear all preferences (for testing or reset)
  Future<void> clearAllPreferences() async {
    await initialize();
    await _prefs?.clear();
  }
  
  /// Export preferences for backup
  Future<Map<String, dynamic>> exportPreferences() async {
    await initialize();
    final keys = _prefs?.getKeys() ?? <String>{};
    final exported = <String, dynamic>{};
    
    for (final key in keys) {
      final value = _prefs?.get(key);
      if (value != null) {
        exported[key] = value;
      }
    }
    
    return exported;
  }
  
  /// Import preferences from backup
  Future<void> importPreferences(Map<String, dynamic> preferences) async {
    await initialize();
    
    for (final entry in preferences.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (value is String) {
        await _prefs?.setString(key, value);
      } else if (value is bool) {
        await _prefs?.setBool(key, value);
      } else if (value is int) {
        await _prefs?.setInt(key, value);
      } else if (value is double) {
        await _prefs?.setDouble(key, value);
      } else if (value is List<String>) {
        await _prefs?.setStringList(key, value);
      }
    }
  }
}

/// Workspace history entry
class WorkspaceHistoryEntry {
  final String filePath;
  final String workspaceName;
  final DateTime lastOpened;
  final String fileType; // 'json' or 'dsl'
  final int? fileSize;
  
  const WorkspaceHistoryEntry({
    required this.filePath,
    required this.workspaceName,
    required this.lastOpened,
    required this.fileType,
    this.fileSize,
  });
  
  factory WorkspaceHistoryEntry.fromJson(Map<String, dynamic> json) {
    return WorkspaceHistoryEntry(
      filePath: json['filePath'] as String,
      workspaceName: json['workspaceName'] as String,
      lastOpened: DateTime.parse(json['lastOpened'] as String),
      fileType: json['fileType'] as String,
      fileSize: json['fileSize'] as int?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'workspaceName': workspaceName,
      'lastOpened': lastOpened.toIso8601String(),
      'fileType': fileType,
      'fileSize': fileSize,
    };
  }
}

/// App configuration
class AppConfiguration {
  final String version;
  final Map<String, dynamic> settings;
  final DateTime lastUpdated;
  
  const AppConfiguration({
    required this.version,
    required this.settings,
    required this.lastUpdated,
  });
  
  factory AppConfiguration.defaultConfig() {
    return AppConfiguration(
      version: '1.0.0',
      settings: {
        'defaultLanguage': 'en',
        'maxRecentWorkspaces': 20,
        'enableAnalytics': false,
        'enableCrashReporting': false,
      },
      lastUpdated: DateTime.now(),
    );
  }
  
  factory AppConfiguration.fromJson(Map<String, dynamic> json) {
    return AppConfiguration(
      version: json['version'] as String,
      settings: Map<String, dynamic>.from(json['settings'] as Map<dynamic, dynamic>),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'settings': settings,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

/// User preferences
class UserPreferences {
  final String theme;
  final bool enableNotifications;
  final bool enableSounds;
  final double uiScale;
  final Map<String, dynamic> customSettings;
  
  const UserPreferences({
    required this.theme,
    required this.enableNotifications,
    required this.enableSounds,
    required this.uiScale,
    required this.customSettings,
  });
  
  factory UserPreferences.defaultPreferences() {
    return const UserPreferences(
      theme: 'system',
      enableNotifications: true,
      enableSounds: true,
      uiScale: 1.0,
      customSettings: {},
    );
  }
  
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      theme: json['theme'] as String,
      enableNotifications: json['enableNotifications'] as bool,
      enableSounds: json['enableSounds'] as bool,
      uiScale: (json['uiScale'] as num).toDouble(),
      customSettings: Map<String, dynamic>.from(json['customSettings'] as Map<dynamic, dynamic>),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'enableNotifications': enableNotifications,
      'enableSounds': enableSounds,
      'uiScale': uiScale,
      'customSettings': customSettings,
    };
  }
}

/// Backup settings
class BackupSettings {
  final bool autoBackupEnabled;
  final int backupIntervalHours;
  final int maxBackupCount;
  final bool includeWorkspaceFiles;
  final bool includePreferences;
  final String backupLocation;
  
  const BackupSettings({
    required this.autoBackupEnabled,
    required this.backupIntervalHours,
    required this.maxBackupCount,
    required this.includeWorkspaceFiles,
    required this.includePreferences,
    required this.backupLocation,
  });
  
  factory BackupSettings.defaultSettings() {
    return const BackupSettings(
      autoBackupEnabled: true,
      backupIntervalHours: 24,
      maxBackupCount: 7,
      includeWorkspaceFiles: true,
      includePreferences: false,
      backupLocation: 'default',
    );
  }
  
  factory BackupSettings.fromJson(Map<String, dynamic> json) {
    return BackupSettings(
      autoBackupEnabled: json['autoBackupEnabled'] as bool,
      backupIntervalHours: json['backupIntervalHours'] as int,
      maxBackupCount: json['maxBackupCount'] as int,
      includeWorkspaceFiles: json['includeWorkspaceFiles'] as bool,
      includePreferences: json['includePreferences'] as bool,
      backupLocation: json['backupLocation'] as String,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'autoBackupEnabled': autoBackupEnabled,
      'backupIntervalHours': backupIntervalHours,
      'maxBackupCount': maxBackupCount,
      'includeWorkspaceFiles': includeWorkspaceFiles,
      'includePreferences': includePreferences,
      'backupLocation': backupLocation,
    };
  }
}