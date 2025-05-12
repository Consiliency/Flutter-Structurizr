import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/infrastructure/persistence/file_storage.dart';

/// AutoSave class that automatically saves workspaces when changes are detected.
class AutoSave {
  /// The file storage to use for saving workspaces.
  final FileStorage _storage;
  
  /// The interval between auto-saves in milliseconds.
  int _intervalMs;
  
  /// Whether auto-save is currently enabled.
  bool _enabled;
  
  /// Timer for scheduling auto-saves.
  Timer? _timer;
  
  /// The last saved workspace state.
  Workspace? _lastSavedWorkspace;
  
  /// The path to the current workspace file.
  String? _currentWorkspacePath;
  
  /// The current workspace being monitored.
  Workspace? _currentWorkspace;
  
  /// Callback for workspace changes.
  ValueChanged<Workspace>? _onWorkspaceChanged;
  
  /// Stream controller for auto-save events.
  final _autoSaveEvents = StreamController<AutoSaveEvent>.broadcast();
  
  /// Stream of auto-save events.
  Stream<AutoSaveEvent> get autoSaveEvents => _autoSaveEvents.stream;
  
  /// Creates a new AutoSave instance.
  /// 
  /// - [storage]: The file storage to use for saving workspaces.
  /// - [intervalMs]: The interval between auto-saves in milliseconds.
  /// - [enabled]: Whether auto-save should be enabled by default.
  AutoSave({
    required FileStorage storage,
    int intervalMs = 30000, // Default to 30 seconds
    bool enabled = true,
  }) : _storage = storage,
       _intervalMs = intervalMs,
       _enabled = enabled;
  
  /// Whether auto-save is currently enabled.
  bool get isEnabled => _enabled;
  
  /// Gets the current workspace being monitored.
  Workspace? get currentWorkspace => _currentWorkspace;
  
  /// Gets the path to the current workspace file.
  String? get currentWorkspacePath => _currentWorkspacePath;
  
  /// Starts monitoring a workspace for changes.
  /// 
  /// - [workspace]: The workspace to monitor.
  /// - [path]: The path to save the workspace to.
  /// - [onWorkspaceChanged]: Optional callback for when the workspace changes.
  void startMonitoring(
    Workspace workspace,
    String path, {
    ValueChanged<Workspace>? onWorkspaceChanged,
  }) {
    _currentWorkspace = workspace;
    _currentWorkspacePath = path;
    _lastSavedWorkspace = workspace;
    _onWorkspaceChanged = onWorkspaceChanged;
    
    // Restart the timer if enabled
    if (_enabled) {
      _restartTimer();
    }
    
    _autoSaveEvents.add(AutoSaveEvent(
      type: AutoSaveEventType.monitoringStarted,
      workspace: workspace,
      path: path,
    ));
  }
  
  /// Stops monitoring the current workspace.
  void stopMonitoring() {
    _cancelTimer();
    _currentWorkspace = null;
    _currentWorkspacePath = null;
    _lastSavedWorkspace = null;
    _onWorkspaceChanged = null;
    
    _autoSaveEvents.add(AutoSaveEvent(
      type: AutoSaveEventType.monitoringStopped,
    ));
  }
  
  /// Updates the current workspace.
  /// 
  /// This should be called whenever the workspace changes to trigger
  /// an auto-save if enabled.
  void updateWorkspace(Workspace workspace) {
    if (_currentWorkspace != workspace) {
      _currentWorkspace = workspace;
      
      // Notify listeners
      _onWorkspaceChanged?.call(workspace);
      
      // Trigger auto-save if enabled
      if (_enabled && _currentWorkspacePath != null) {
        _restartTimer();
      }
      
      _autoSaveEvents.add(AutoSaveEvent(
        type: AutoSaveEventType.workspaceUpdated,
        workspace: workspace,
      ));
    }
  }
  
  /// Enables or disables auto-save.
  void setEnabled(bool enabled) {
    if (_enabled != enabled) {
      _enabled = enabled;
      
      if (enabled && _currentWorkspace != null && _currentWorkspacePath != null) {
        _restartTimer();
      } else {
        _cancelTimer();
      }
      
      _autoSaveEvents.add(AutoSaveEvent(
        type: enabled ? AutoSaveEventType.enabled : AutoSaveEventType.disabled,
      ));
    }
  }
  
  /// Changes the auto-save interval.
  void setInterval(int intervalMs) {
    if (_intervalMs != intervalMs) {
      _intervalMs = intervalMs;
      
      if (_enabled && _timer != null) {
        _restartTimer();
      }
      
      _autoSaveEvents.add(AutoSaveEvent(
        type: AutoSaveEventType.intervalChanged,
        intervalMs: intervalMs,
      ));
    }
  }
  
  /// Manually saves the current workspace.
  /// 
  /// Returns true if the workspace was saved, false otherwise.
  Future<bool> saveNow({
    ValueChanged<double>? onProgress,
  }) async {
    if (_currentWorkspace == null || _currentWorkspacePath == null) {
      return false;
    }
    
    try {
      _cancelTimer();
      
      _autoSaveEvents.add(AutoSaveEvent(
        type: AutoSaveEventType.savingStarted,
        workspace: _currentWorkspace!,
        path: _currentWorkspacePath!,
      ));
      
      await _storage.saveWorkspace(
        _currentWorkspace!,
        _currentWorkspacePath!,
        onProgress: onProgress,
      );
      
      _lastSavedWorkspace = _currentWorkspace;
      
      if (_enabled) {
        _restartTimer();
      }
      
      _autoSaveEvents.add(AutoSaveEvent(
        type: AutoSaveEventType.saveCompleted,
        workspace: _currentWorkspace!,
        path: _currentWorkspacePath!,
      ));
      
      return true;
    } catch (e) {
      _autoSaveEvents.add(AutoSaveEvent(
        type: AutoSaveEventType.saveFailed,
        workspace: _currentWorkspace!,
        path: _currentWorkspacePath!,
        error: e,
      ));
      
      if (_enabled) {
        _restartTimer();
      }
      
      return false;
    }
  }
  
  /// Checks if there are unsaved changes in the current workspace.
  bool hasUnsavedChanges() {
    if (_currentWorkspace == null || _lastSavedWorkspace == null) {
      return false;
    }
    
    // Compare workspaces by serializing them to JSON
    // This is not the most efficient way, but it's reliable
    final currentJson = _currentWorkspace.toString();
    final lastSavedJson = _lastSavedWorkspace.toString();
    
    return currentJson != lastSavedJson;
  }
  
  /// Restarts the auto-save timer.
  void _restartTimer() {
    _cancelTimer();
    _timer = Timer(Duration(milliseconds: _intervalMs), _autoSaveIfNeeded);
  }
  
  /// Cancels the auto-save timer.
  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }
  
  /// Performs an auto-save if needed.
  Future<void> _autoSaveIfNeeded() async {
    if (!_enabled || _currentWorkspace == null || _currentWorkspacePath == null) {
      return;
    }
    
    if (hasUnsavedChanges()) {
      await saveNow();
    }
    
    // Restart the timer for the next auto-save
    _restartTimer();
  }
  
  /// Disposes of resources.
  void dispose() {
    _cancelTimer();
    _autoSaveEvents.close();
  }
}

/// Types of auto-save events.
enum AutoSaveEventType {
  /// Auto-save has been enabled.
  enabled,
  
  /// Auto-save has been disabled.
  disabled,
  
  /// The auto-save interval has changed.
  intervalChanged,
  
  /// Monitoring of a workspace has started.
  monitoringStarted,
  
  /// Monitoring of a workspace has stopped.
  monitoringStopped,
  
  /// The monitored workspace has been updated.
  workspaceUpdated,
  
  /// A save operation has started.
  savingStarted,
  
  /// A save operation has completed successfully.
  saveCompleted,
  
  /// A save operation has failed.
  saveFailed,
}

/// Event emitted by the AutoSave class.
class AutoSaveEvent {
  /// The type of event.
  final AutoSaveEventType type;
  
  /// The workspace associated with the event, if any.
  final Workspace? workspace;
  
  /// The path associated with the event, if any.
  final String? path;
  
  /// The error associated with the event, if any.
  final Object? error;
  
  /// The interval associated with the event, if any.
  final int? intervalMs;
  
  AutoSaveEvent({
    required this.type,
    this.workspace,
    this.path,
    this.error,
    this.intervalMs,
  });
}