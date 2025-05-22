import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../../domain/model/workspace.dart';
import '../../infrastructure/preferences/app_preferences.dart';
import 'workspace_directory_manager.dart';

class WorkspaceStateManager {
  static WorkspaceStateManager? _instance;
  static WorkspaceStateManager get instance =>
      _instance ??= WorkspaceStateManager._();

  WorkspaceStateManager._();

  // Current workspace state
  Workspace? _currentWorkspace;
  String? _currentWorkspacePath;
  bool _hasUnsavedChanges = false;
  DateTime? _lastSavedTime;
  DateTime? _lastModifiedTime;

  // Auto-save configuration
  bool _autoSaveEnabled = true;
  Duration _autoSaveInterval = const Duration(minutes: 5);
  Timer? _autoSaveTimer;

  // State change notifications
  final StreamController<WorkspaceStateChange> _stateChangeController =
      StreamController.broadcast();
  Stream<WorkspaceStateChange> get stateChanges =>
      _stateChangeController.stream;

  // Lifecycle management
  bool _isInitialized = false;

  /// Initialize the workspace state manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Load auto-save preferences
    final autoSaveEnabled = await AppPreferences.instance.getAutoSaveEnabled();
    _autoSaveEnabled = autoSaveEnabled;

    // Start auto-save timer if enabled
    if (_autoSaveEnabled) {
      _startAutoSaveTimer();
    }

    _isInitialized = true;
  }

  /// Get current workspace
  Workspace? get currentWorkspace => _currentWorkspace;

  /// Get current workspace file path
  String? get currentWorkspacePath => _currentWorkspacePath;

  /// Check if there are unsaved changes
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  /// Get last saved time
  DateTime? get lastSavedTime => _lastSavedTime;

  /// Get last modified time
  DateTime? get lastModifiedTime => _lastModifiedTime;

  /// Check if auto-save is enabled
  bool get isAutoSaveEnabled => _autoSaveEnabled;

  /// Set auto-save enabled state
  Future<void> setAutoSaveEnabled(bool enabled) async {
    _autoSaveEnabled = enabled;
    await AppPreferences.instance.setAutoSaveEnabled(enabled);

    if (enabled) {
      _startAutoSaveTimer();
    } else {
      _stopAutoSaveTimer();
    }

    _notifyStateChange(WorkspaceStateChangeType.autoSaveConfigChanged);
  }

  /// Set auto-save interval
  void setAutoSaveInterval(Duration interval) {
    _autoSaveInterval = interval;

    // Restart timer with new interval if auto-save is enabled
    if (_autoSaveEnabled) {
      _stopAutoSaveTimer();
      _startAutoSaveTimer();
    }

    _notifyStateChange(WorkspaceStateChangeType.autoSaveConfigChanged);
  }

  /// Load workspace and set as current
  Future<void> setCurrentWorkspace(
      Workspace workspace, String? filePath) async {
    await initialize();

    // Check for unsaved changes before switching
    if (_hasUnsavedChanges && _currentWorkspace != null) {
      throw const WorkspaceStateException(
        'Cannot switch workspace with unsaved changes. Save or discard changes first.',
        WorkspaceStateErrorType.unsavedChanges,
      );
    }

    _currentWorkspace = workspace;
    _currentWorkspacePath = filePath;
    _hasUnsavedChanges = false;
    _lastModifiedTime = DateTime.now();

    // Update last opened workspace in preferences
    if (filePath != null) {
      await AppPreferences.instance.setLastOpenWorkspace(filePath);

      // Add to workspace history
      final historyEntry = WorkspaceHistoryEntry(
        filePath: filePath,
        workspaceName: workspace.name,
        lastOpened: DateTime.now(),
        fileType: filePath.endsWith('.dsl') ? 'dsl' : 'json',
        fileSize: await _getFileSize(filePath),
      );
      await AppPreferences.instance.addToWorkspaceHistory(historyEntry);
    }

    _notifyStateChange(WorkspaceStateChangeType.workspaceLoaded);
  }

  /// Mark workspace as modified
  void markAsModified() {
    if (!_hasUnsavedChanges) {
      _hasUnsavedChanges = true;
      _lastModifiedTime = DateTime.now();
      _notifyStateChange(WorkspaceStateChangeType.workspaceModified);
    }
  }

  /// Mark workspace as saved
  void markAsSaved() {
    if (_hasUnsavedChanges) {
      _hasUnsavedChanges = false;
      _lastSavedTime = DateTime.now();
      _notifyStateChange(WorkspaceStateChangeType.workspaceSaved);
    }
  }

  /// Clear current workspace
  Future<void> clearCurrentWorkspace() async {
    // Check for unsaved changes
    if (_hasUnsavedChanges && _currentWorkspace != null) {
      throw const WorkspaceStateException(
        'Cannot clear workspace with unsaved changes. Save or discard changes first.',
        WorkspaceStateErrorType.unsavedChanges,
      );
    }

    _currentWorkspace = null;
    _currentWorkspacePath = null;
    _hasUnsavedChanges = false;
    _lastSavedTime = null;
    _lastModifiedTime = null;

    _notifyStateChange(WorkspaceStateChangeType.workspaceCleared);
  }

  /// Force clear workspace (discarding unsaved changes)
  Future<void> forceCloseWorkspace() async {
    _currentWorkspace = null;
    _currentWorkspacePath = null;
    _hasUnsavedChanges = false;
    _lastSavedTime = null;
    _lastModifiedTime = null;

    _notifyStateChange(WorkspaceStateChangeType.workspaceCleared);
  }

  /// Check if workspace can be closed (no unsaved changes)
  bool canCloseWorkspace() {
    return !_hasUnsavedChanges;
  }

  /// Get workspace modification summary
  WorkspaceModificationSummary getModificationSummary() {
    return WorkspaceModificationSummary(
      hasUnsavedChanges: _hasUnsavedChanges,
      lastModifiedTime: _lastModifiedTime,
      lastSavedTime: _lastSavedTime,
      workspaceName: _currentWorkspace?.name,
      workspacePath: _currentWorkspacePath,
      timeSinceLastSave: _lastSavedTime != null
          ? DateTime.now().difference(_lastSavedTime!)
          : null,
      timeSinceLastModification: _lastModifiedTime != null
          ? DateTime.now().difference(_lastModifiedTime!)
          : null,
    );
  }

  /// Trigger auto-save if conditions are met
  Future<bool> triggerAutoSave() async {
    if (!_autoSaveEnabled || !_hasUnsavedChanges || _currentWorkspace == null) {
      return false;
    }

    try {
      // Auto-save logic would be implemented here
      // For now, just mark as saved and notify
      markAsSaved();
      _notifyStateChange(WorkspaceStateChangeType.autoSaveTriggered);
      return true;
    } catch (e) {
      debugPrint('Auto-save failed: $e');
      _notifyStateChange(WorkspaceStateChangeType.autoSaveFailed);
      return false;
    }
  }

  /// Handle app lifecycle events
  Future<void> handleAppLifecycleEvent(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App going to background - trigger auto-save if needed
        if (_hasUnsavedChanges && _autoSaveEnabled) {
          await triggerAutoSave();
        }
        break;

      case AppLifecycleState.resumed:
        // App coming to foreground - restart auto-save timer
        if (_autoSaveEnabled) {
          _startAutoSaveTimer();
        }
        break;

      case AppLifecycleState.detached:
        // App being terminated - stop timers
        _stopAutoSaveTimer();
        break;

      case AppLifecycleState.hidden:
        // Handle hidden state (mainly for desktop)
        break;
    }
  }

  /// Start auto-save timer
  void _startAutoSaveTimer() {
    _stopAutoSaveTimer(); // Stop existing timer

    if (_autoSaveEnabled) {
      _autoSaveTimer = Timer.periodic(_autoSaveInterval, (timer) {
        triggerAutoSave();
      });
    }
  }

  /// Stop auto-save timer
  void _stopAutoSaveTimer() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
  }

  /// Get file size helper
  Future<int?> _getFileSize(String filePath) async {
    try {
      if (!kIsWeb) {
        final file = File(filePath);
        if (await file.exists()) {
          return await file.length();
        }
      }
    } catch (e) {
      debugPrint('Error getting file size: $e');
    }
    return null;
  }

  /// Notify state change
  void _notifyStateChange(WorkspaceStateChangeType type) {
    final change = WorkspaceStateChange(
      type: type,
      workspace: _currentWorkspace,
      workspacePath: _currentWorkspacePath,
      hasUnsavedChanges: _hasUnsavedChanges,
      timestamp: DateTime.now(),
    );

    _stateChangeController.add(change);
  }

  /// Create backup before major operations
  Future<String?> createBackup() async {
    if (_currentWorkspacePath == null) return null;

    try {
      return await WorkspaceDirectoryManager.instance.createBackup();
    } catch (e) {
      debugPrint('Error creating backup: $e');
      return null;
    }
  }

  /// Restore workspace from backup
  Future<bool> restoreFromBackup(String backupPath) async {
    try {
      // Backup restoration logic would be implemented here
      // This would involve copying files from backup location
      _notifyStateChange(WorkspaceStateChangeType.workspaceRestored);
      return true;
    } catch (e) {
      debugPrint('Error restoring from backup: $e');
      return false;
    }
  }

  /// Get workspace statistics
  WorkspaceStatistics getWorkspaceStatistics() {
    if (_currentWorkspace == null) {
      return WorkspaceStatistics.empty();
    }

    final model = _currentWorkspace!.model;

    return WorkspaceStatistics(
      personCount: model.people.length,
      softwareSystemCount: model.softwareSystems.length,
      containerCount: model.softwareSystems
          .fold(0, (sum, system) => sum + system.containers.length),
      componentCount: model.softwareSystems.fold(
          0,
          (sum, system) =>
              sum +
              system.containers.fold(
                  0,
                  (containerSum, container) =>
                      containerSum + container.components.length)),
      relationshipCount: model.relationships.length,
      viewCount: _currentWorkspace!.views.systemContextViews.length +
          _currentWorkspace!.views.containerViews.length +
          _currentWorkspace!.views.componentViews.length +
          _currentWorkspace!.views.dynamicViews.length +
          _currentWorkspace!.views.deploymentViews.length,
      lastModified: _lastModifiedTime,
      fileSize: null, // Would be populated from file system
    );
  }

  /// Dispose resources
  void dispose() {
    _stopAutoSaveTimer();
    _stateChangeController.close();
    _isInitialized = false;
  }
}

/// Workspace state change types
enum WorkspaceStateChangeType {
  workspaceLoaded,
  workspaceModified,
  workspaceSaved,
  workspaceCleared,
  workspaceRestored,
  autoSaveTriggered,
  autoSaveFailed,
  autoSaveConfigChanged,
}

/// Workspace state change event
class WorkspaceStateChange {
  final WorkspaceStateChangeType type;
  final Workspace? workspace;
  final String? workspacePath;
  final bool hasUnsavedChanges;
  final DateTime timestamp;

  const WorkspaceStateChange({
    required this.type,
    this.workspace,
    this.workspacePath,
    required this.hasUnsavedChanges,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'WorkspaceStateChange(type: $type, hasUnsavedChanges: $hasUnsavedChanges, '
        'workspace: ${workspace?.name}, timestamp: $timestamp)';
  }
}

/// Workspace modification summary
class WorkspaceModificationSummary {
  final bool hasUnsavedChanges;
  final DateTime? lastModifiedTime;
  final DateTime? lastSavedTime;
  final String? workspaceName;
  final String? workspacePath;
  final Duration? timeSinceLastSave;
  final Duration? timeSinceLastModification;

  const WorkspaceModificationSummary({
    required this.hasUnsavedChanges,
    this.lastModifiedTime,
    this.lastSavedTime,
    this.workspaceName,
    this.workspacePath,
    this.timeSinceLastSave,
    this.timeSinceLastModification,
  });

  @override
  String toString() {
    return 'WorkspaceModificationSummary(hasUnsavedChanges: $hasUnsavedChanges, '
        'workspace: $workspaceName, timeSinceLastSave: $timeSinceLastSave)';
  }
}

/// Workspace statistics
class WorkspaceStatistics {
  final int personCount;
  final int softwareSystemCount;
  final int containerCount;
  final int componentCount;
  final int relationshipCount;
  final int viewCount;
  final DateTime? lastModified;
  final int? fileSize;

  const WorkspaceStatistics({
    required this.personCount,
    required this.softwareSystemCount,
    required this.containerCount,
    required this.componentCount,
    required this.relationshipCount,
    required this.viewCount,
    this.lastModified,
    this.fileSize,
  });

  factory WorkspaceStatistics.empty() {
    return const WorkspaceStatistics(
      personCount: 0,
      softwareSystemCount: 0,
      containerCount: 0,
      componentCount: 0,
      relationshipCount: 0,
      viewCount: 0,
    );
  }

  @override
  String toString() {
    return 'WorkspaceStatistics(people: $personCount, systems: $softwareSystemCount, '
        'containers: $containerCount, components: $componentCount, '
        'relationships: $relationshipCount, views: $viewCount)';
  }
}

/// Workspace state exception
class WorkspaceStateException implements Exception {
  final String message;
  final WorkspaceStateErrorType type;

  const WorkspaceStateException(this.message, this.type);

  @override
  String toString() => 'WorkspaceStateException($type): $message';
}

/// Workspace state error types
enum WorkspaceStateErrorType {
  unsavedChanges,
  fileNotFound,
  permissionDenied,
  corruptedFile,
  unknownError,
}
