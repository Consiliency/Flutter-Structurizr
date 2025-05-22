import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_structurizr/application/workspace/workspace_repository.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/infrastructure/persistence/auto_save.dart';
import 'package:flutter_structurizr/infrastructure/persistence/file_storage.dart';
import 'package:flutter_structurizr/infrastructure/serialization/json_serialization.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

/// Manager for tracking and handling multiple workspaces.
///
/// This class provides a high-level API for workspace operations including:
/// - Opening, saving, and closing workspaces
/// - Tracking recent workspaces
/// - Handling workspace changes and auto-save
/// - Support for multiple open workspaces
/// - Import and export functionality
class WorkspaceManager {
  /// The underlying file storage.
  final FileStorage _fileStorage;

  /// Auto-save service for each workspace.
  final Map<String, AutoSave> _autoSaveServices = {};

  /// Currently loaded workspaces by their path.
  final Map<String, Workspace> _loadedWorkspaces = {};

  /// Recent workspace history.
  final List<WorkspaceMetadata> _recentWorkspaces = [];

  /// Maximum number of recent workspaces to track.
  final int _maxRecentWorkspaces;

  /// Stream controller for workspace events.
  final _workspaceEvents = StreamController<WorkspaceEvent>.broadcast();

  /// The preferences key for storing recent workspaces.
  static const _recentWorkspacesKey = 'workspace_manager.recent_workspaces';

  /// Storage mode for workspaces.
  final StorageMode _storageMode;

  /// Creates a new workspace manager.
  ///
  /// [fileStorage] - The file storage to use.
  /// [maxRecentWorkspaces] - Maximum number of recent workspaces to track.
  /// [storageMode] - The storage mode for workspaces.
  WorkspaceManager({
    required FileStorage fileStorage,
    int maxRecentWorkspaces = 10,
    StorageMode storageMode = StorageMode.file,
  })  : _fileStorage = fileStorage,
        _maxRecentWorkspaces = maxRecentWorkspaces,
        _storageMode = storageMode;

  /// Stream of workspace events.
  Stream<WorkspaceEvent> get workspaceEvents => _workspaceEvents.stream;

  /// Gets the list of recent workspaces.
  List<WorkspaceMetadata> get recentWorkspaces =>
      List.unmodifiable(_recentWorkspaces);

  /// Gets the list of currently loaded workspaces.
  Map<String, Workspace> get loadedWorkspaces =>
      Map.unmodifiable(_loadedWorkspaces);

  /// Initializes the workspace manager.
  Future<void> initialize() async {
    // Load recent workspaces from preferences
    await _loadRecentWorkspaces();

    // Emit initialized event
    _workspaceEvents.add(WorkspaceEvent(
      type: WorkspaceEventType.initialized,
    ));
  }

  /// Opens a workspace from the given path.
  ///
  /// If the workspace is already loaded, returns the loaded instance.
  /// Otherwise, loads the workspace and adds it to the list of recent workspaces.
  Future<Workspace> openWorkspace(
    String path, {
    ValueChanged<double>? onProgress,
  }) async {
    // Check if workspace is already loaded
    if (_loadedWorkspaces.containsKey(path)) {
      return _loadedWorkspaces[path]!;
    }

    try {
      // Emit loading event
      _workspaceEvents.add(WorkspaceEvent(
        type: WorkspaceEventType.loading,
        path: path,
      ));

      // Load the workspace
      final workspace = await _fileStorage.loadWorkspace(
        path,
        onProgress: onProgress,
      );

      // Add to loaded workspaces
      _loadedWorkspaces[path] = workspace;

      // Set up auto-save
      _setupAutoSave(path, workspace);

      // Add to recent workspaces
      await _addToRecentWorkspaces(WorkspaceMetadata(
        path: path,
        name: workspace.name,
        description: workspace.description,
        lastModified: DateTime.now(),
      ));

      // Emit loaded event
      _workspaceEvents.add(WorkspaceEvent(
        type: WorkspaceEventType.loaded,
        path: path,
        workspace: workspace,
      ));

      return workspace;
    } catch (e, stackTrace) {
      // Emit error event
      _workspaceEvents.add(WorkspaceEvent(
        type: WorkspaceEventType.error,
        path: path,
        error: e,
        stackTrace: stackTrace,
      ));

      rethrow;
    }
  }

  /// Creates a new workspace with the given metadata.
  Future<Workspace> createWorkspace(
    WorkspaceMetadata metadata, {
    ValueChanged<double>? onProgress,
  }) async {
    try {
      // Emit creating event
      _workspaceEvents.add(WorkspaceEvent(
        type: WorkspaceEventType.creating,
        path: metadata.path,
      ));

      // Create the workspace
      final workspace = await _fileStorage.createWorkspace(metadata);

      // Add to loaded workspaces
      _loadedWorkspaces[metadata.path] = workspace;

      // Set up auto-save
      _setupAutoSave(metadata.path, workspace);

      // Add to recent workspaces
      await _addToRecentWorkspaces(metadata);

      // Emit created event
      _workspaceEvents.add(WorkspaceEvent(
        type: WorkspaceEventType.created,
        path: metadata.path,
        workspace: workspace,
      ));

      return workspace;
    } catch (e, stackTrace) {
      // Emit error event
      _workspaceEvents.add(WorkspaceEvent(
        type: WorkspaceEventType.error,
        path: metadata.path,
        error: e,
        stackTrace: stackTrace,
      ));

      rethrow;
    }
  }

  /// Saves the workspace to the given path.
  ///
  /// If no workspace is provided, saves the currently loaded workspace at the path.
  Future<void> saveWorkspace(
    String path, {
    Workspace? workspace,
    bool createBackup = true,
    ValueChanged<double>? onProgress,
  }) async {
    try {
      // Get the workspace to save
      final workspaceToSave = workspace ?? _loadedWorkspaces[path];

      if (workspaceToSave == null) {
        throw WorkspaceException('No workspace loaded at path', path: path);
      }

      // Emit saving event
      _workspaceEvents.add(WorkspaceEvent(
        type: WorkspaceEventType.saving,
        path: path,
        workspace: workspaceToSave,
      ));

      // Save the workspace
      await _fileStorage.saveWorkspace(
        workspaceToSave,
        path,
        createBackup: createBackup,
        onProgress: onProgress,
      );

      // Update loaded workspace if needed
      if (workspace != null && _loadedWorkspaces.containsKey(path)) {
        _loadedWorkspaces[path] = workspace;

        // Update auto-save
        if (_autoSaveServices.containsKey(path)) {
          _autoSaveServices[path]!.updateWorkspace(workspace);
        }
      }

      // Update recent workspaces
      await _addToRecentWorkspaces(WorkspaceMetadata(
        path: path,
        name: workspaceToSave.name,
        description: workspaceToSave.description,
        lastModified: DateTime.now(),
      ));

      // Emit saved event
      _workspaceEvents.add(WorkspaceEvent(
        type: WorkspaceEventType.saved,
        path: path,
        workspace: workspaceToSave,
      ));
    } catch (e, stackTrace) {
      // Emit error event
      _workspaceEvents.add(WorkspaceEvent(
        type: WorkspaceEventType.error,
        path: path,
        error: e,
        stackTrace: stackTrace,
      ));

      rethrow;
    }
  }

  /// Updates a loaded workspace with a new version.
  ///
  /// This doesn't save the workspace to disk but updates the in-memory version
  /// and triggers auto-save if enabled.
  void updateWorkspace(String path, Workspace workspace) {
    if (!_loadedWorkspaces.containsKey(path)) {
      throw WorkspaceException('No workspace loaded at path', path: path);
    }

    // Update the loaded workspace
    _loadedWorkspaces[path] = workspace;

    // Update auto-save
    if (_autoSaveServices.containsKey(path)) {
      _autoSaveServices[path]!.updateWorkspace(workspace);
    }

    // Emit updated event
    _workspaceEvents.add(WorkspaceEvent(
      type: WorkspaceEventType.updated,
      path: path,
      workspace: workspace,
    ));
  }

  /// Closes a loaded workspace.
  ///
  /// If the workspace has unsaved changes and [saveBeforeClosing] is true,
  /// saves the workspace before closing.
  Future<void> closeWorkspace(
    String path, {
    bool saveBeforeClosing = true,
    ValueChanged<double>? onProgress,
  }) async {
    if (!_loadedWorkspaces.containsKey(path)) {
      return; // Nothing to close
    }

    try {
      // Check for unsaved changes
      if (saveBeforeClosing &&
          _autoSaveServices.containsKey(path) &&
          _autoSaveServices[path]!.hasUnsavedChanges()) {
        // Save the workspace
        await saveWorkspace(
          path,
          onProgress: onProgress,
        );
      }

      // Stop auto-save
      if (_autoSaveServices.containsKey(path)) {
        _autoSaveServices[path]!.stopMonitoring();
        _autoSaveServices[path]!.dispose();
        _autoSaveServices.remove(path);
      }

      // Remove from loaded workspaces
      final workspace = _loadedWorkspaces.remove(path);

      // Emit closed event
      _workspaceEvents.add(WorkspaceEvent(
        type: WorkspaceEventType.closed,
        path: path,
        workspace: workspace,
      ));
    } catch (e, stackTrace) {
      // Emit error event
      _workspaceEvents.add(WorkspaceEvent(
        type: WorkspaceEventType.error,
        path: path,
        error: e,
        stackTrace: stackTrace,
      ));

      rethrow;
    }
  }

  /// Deletes a workspace from disk.
  ///
  /// If the workspace is currently loaded, closes it first.
  Future<void> deleteWorkspace(
    String path, {
    bool deleteBackups = true,
  }) async {
    try {
      // Close if loaded
      if (_loadedWorkspaces.containsKey(path)) {
        await closeWorkspace(path, saveBeforeClosing: false);
      }

      // Emit deleting event
      _workspaceEvents.add(WorkspaceEvent(
        type: WorkspaceEventType.deleting,
        path: path,
      ));

      // Delete the workspace
      await _fileStorage.deleteWorkspace(path, deleteBackups: deleteBackups);

      // Remove from recent workspaces
      await _removeFromRecentWorkspaces(path);

      // Emit deleted event
      _workspaceEvents.add(WorkspaceEvent(
        type: WorkspaceEventType.deleted,
        path: path,
      ));
    } catch (e, stackTrace) {
      // Emit error event
      _workspaceEvents.add(WorkspaceEvent(
        type: WorkspaceEventType.error,
        path: path,
        error: e,
        stackTrace: stackTrace,
      ));

      rethrow;
    }
  }

  /// Lists all available workspaces in the workspace directory.
  Future<List<WorkspaceMetadata>> listWorkspaces() {
    return _fileStorage.listWorkspaces();
  }

  /// Lists backups for a workspace.
  Future<List<WorkspaceBackup>> listBackups(String path) {
    return _fileStorage.listBackups(path);
  }

  /// Restores a workspace from a backup.
  Future<Workspace> restoreFromBackup(
    WorkspaceBackup backup, {
    bool overwriteOriginal = true,
    ValueChanged<double>? onProgress,
  }) async {
    try {
      // Emit restoring event
      _workspaceEvents.add(WorkspaceEvent(
        type: WorkspaceEventType.restoring,
        path: backup.originalPath,
      ));

      // Restore from backup
      final workspace = await _fileStorage.restoreFromBackup(
        backup,
        overwriteOriginal: overwriteOriginal,
        onProgress: onProgress,
      );

      // Update loaded workspace if needed
      if (overwriteOriginal &&
          _loadedWorkspaces.containsKey(backup.originalPath)) {
        _loadedWorkspaces[backup.originalPath] = workspace;

        // Update auto-save
        if (_autoSaveServices.containsKey(backup.originalPath)) {
          _autoSaveServices[backup.originalPath]!.updateWorkspace(workspace);
        }
      }

      // Emit restored event
      _workspaceEvents.add(WorkspaceEvent(
        type: WorkspaceEventType.restored,
        path: backup.originalPath,
        workspace: workspace,
      ));

      return workspace;
    } catch (e, stackTrace) {
      // Emit error event
      _workspaceEvents.add(WorkspaceEvent(
        type: WorkspaceEventType.error,
        path: backup.originalPath,
        error: e,
        stackTrace: stackTrace,
      ));

      rethrow;
    }
  }

  /// Imports a workspace from a file.
  ///
  /// The file can be in JSON format or DSL format.
  Future<Workspace> importWorkspace(
    String sourcePath,
    String destinationPath, {
    ValueChanged<double>? onProgress,
  }) async {
    try {
      // Verify source file exists
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw WorkspaceException('Source file does not exist',
            path: sourcePath);
      }

      // Emit importing event
      _workspaceEvents.add(WorkspaceEvent(
        type: WorkspaceEventType.importing,
        path: sourcePath,
      ));

      // Determine the file format
      final String extension = path.extension(sourcePath).toLowerCase();
      Workspace workspace;

      if (extension == '.json') {
        // Load the JSON workspace
        final content = await sourceFile.readAsString();
        try {
          workspace = await compute<String, Workspace>(
            (content) => JsonWorkspaceParser.parse(content),
            content,
          );
        } catch (e) {
          throw WorkspaceException('Failed to parse JSON workspace',
              path: sourcePath, cause: e);
        }
      } else if (extension == '.dsl') {
        throw WorkspaceException('DSL import not yet supported',
            path: sourcePath);
      } else {
        throw WorkspaceException('Unsupported file format', path: sourcePath);
      }

      // Save to destination
      await saveWorkspace(
        destinationPath,
        workspace: workspace,
        createBackup: false,
        onProgress: onProgress,
      );

      // Emit imported event
      _workspaceEvents.add(WorkspaceEvent(
        type: WorkspaceEventType.imported,
        path: destinationPath,
        workspace: workspace,
      ));

      return workspace;
    } catch (e, stackTrace) {
      // Emit error event
      _workspaceEvents.add(WorkspaceEvent(
        type: WorkspaceEventType.error,
        path: sourcePath,
        error: e,
        stackTrace: stackTrace,
      ));

      rethrow;
    }
  }

  /// Exports a workspace to a file.
  ///
  /// The file can be in JSON format or DSL format.
  Future<void> exportWorkspace(
    String sourcePath,
    String destinationPath, {
    ExportFormat format = ExportFormat.json,
    ValueChanged<double>? onProgress,
  }) async {
    try {
      // Get the workspace to export
      final workspace = _loadedWorkspaces[sourcePath];
      if (workspace == null) {
        throw WorkspaceException('No workspace loaded at path',
            path: sourcePath);
      }

      // Emit exporting event
      _workspaceEvents.add(WorkspaceEvent(
        type: WorkspaceEventType.exporting,
        path: sourcePath,
        workspace: workspace,
      ));

      final destinationFile = File(destinationPath);
      final extension = path.extension(destinationPath).toLowerCase();

      // Create directory if it doesn't exist
      final dir = destinationFile.parent;
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Export based on format
      if (format == ExportFormat.json || extension == '.json') {
        // Export as JSON
        final json = JsonWorkspaceParser.serialize(workspace);

        // Report progress: 50%
        if (onProgress != null) {
          onProgress(0.5);
        }

        await destinationFile.writeAsString(json, flush: true);
      } else if (format == ExportFormat.dsl || extension == '.dsl') {
        throw WorkspaceException('DSL export not yet supported',
            path: destinationPath);
      } else {
        throw WorkspaceException('Unsupported export format',
            path: destinationPath);
      }

      // Report progress: 100%
      if (onProgress != null) {
        onProgress(1.0);
      }

      // Emit exported event
      _workspaceEvents.add(WorkspaceEvent(
        type: WorkspaceEventType.exported,
        path: destinationPath,
        workspace: workspace,
      ));
    } catch (e, stackTrace) {
      // Emit error event
      _workspaceEvents.add(WorkspaceEvent(
        type: WorkspaceEventType.error,
        path: sourcePath,
        error: e,
        stackTrace: stackTrace,
      ));

      rethrow;
    }
  }

  /// Checks if a workspace has unsaved changes.
  bool hasUnsavedChanges(String path) {
    if (!_loadedWorkspaces.containsKey(path)) {
      return false;
    }

    if (!_autoSaveServices.containsKey(path)) {
      return false;
    }

    return _autoSaveServices[path]!.hasUnsavedChanges();
  }

  /// Enables or disables auto-save for a workspace.
  void setAutoSaveEnabled(String path, bool enabled) {
    if (!_autoSaveServices.containsKey(path)) {
      return;
    }

    _autoSaveServices[path]!.setEnabled(enabled);
  }

  /// Sets the auto-save interval for a workspace.
  void setAutoSaveInterval(String path, int intervalMs) {
    if (!_autoSaveServices.containsKey(path)) {
      return;
    }

    _autoSaveServices[path]!.setInterval(intervalMs);
  }

  /// Sets up auto-save for a workspace.
  void _setupAutoSave(String path, Workspace workspace) {
    // Clean up existing auto-save if any
    if (_autoSaveServices.containsKey(path)) {
      _autoSaveServices[path]!.dispose();
    }

    // Create new auto-save
    final autoSave = AutoSave(
      storage: _fileStorage,
      enabled: true,
    );

    // Start monitoring
    autoSave.startMonitoring(
      workspace,
      path,
      onWorkspaceChanged: (updatedWorkspace) {
        // Update loaded workspace
        _loadedWorkspaces[path] = updatedWorkspace;

        // Emit updated event
        _workspaceEvents.add(WorkspaceEvent(
          type: WorkspaceEventType.updated,
          path: path,
          workspace: updatedWorkspace,
        ));
      },
    );

    // Add to auto-save services
    _autoSaveServices[path] = autoSave;

    // Listen to auto-save events
    autoSave.autoSaveEvents.listen((event) {
      if (event.type == AutoSaveEventType.saveCompleted) {
        // Update recent workspaces with new last modified time
        _addToRecentWorkspaces(WorkspaceMetadata(
          path: path,
          name: workspace.name,
          description: workspace.description,
          lastModified: DateTime.now(),
        ));
      }
    });
  }

  /// Adds a workspace to the list of recent workspaces.
  Future<void> _addToRecentWorkspaces(WorkspaceMetadata metadata) async {
    // Remove if already exists
    _recentWorkspaces.removeWhere((w) => w.path == metadata.path);

    // Add to front of list
    _recentWorkspaces.insert(0, metadata);

    // Trim to max size
    if (_recentWorkspaces.length > _maxRecentWorkspaces) {
      _recentWorkspaces.removeRange(
          _maxRecentWorkspaces, _recentWorkspaces.length);
    }

    // Save to preferences
    await _saveRecentWorkspaces();

    // Emit event
    _workspaceEvents.add(WorkspaceEvent(
      type: WorkspaceEventType.recentWorkspacesUpdated,
    ));
  }

  /// Removes a workspace from the list of recent workspaces.
  Future<void> _removeFromRecentWorkspaces(String path) async {
    // Remove if exists
    final initialLength = _recentWorkspaces.length;
    _recentWorkspaces.removeWhere((w) => w.path == path);
    final removed = initialLength != _recentWorkspaces.length;

    if (removed) {
      // Save to preferences
      await _saveRecentWorkspaces();

      // Emit event
      _workspaceEvents.add(WorkspaceEvent(
        type: WorkspaceEventType.recentWorkspacesUpdated,
      ));
    }
  }

  /// Loads the list of recent workspaces from preferences.
  Future<void> _loadRecentWorkspaces() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentWorkspacesJson = prefs.getString(_recentWorkspacesKey);

      if (recentWorkspacesJson != null) {
        final List<dynamic> jsonList = jsonDecode(recentWorkspacesJson);

        _recentWorkspaces.clear();
        for (final item in jsonList) {
          try {
            final metadata = WorkspaceMetadata(
              path: item['path'],
              name: item['name'],
              description: item['description'],
              lastModified: DateTime.parse(item['lastModified']),
            );

            // Only add if file exists
            if (await File(metadata.path).exists()) {
              _recentWorkspaces.add(metadata);
            }
          } catch (e) {
            // Skip invalid entries
          }
        }
      }
    } catch (e) {
      // Ignore errors loading preferences
    }
  }

  /// Saves the list of recent workspaces to preferences.
  Future<void> _saveRecentWorkspaces() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final jsonList = _recentWorkspaces
          .map((metadata) => {
                'path': metadata.path,
                'name': metadata.name,
                'description': metadata.description,
                'lastModified': metadata.lastModified.toIso8601String(),
              })
          .toList();

      await prefs.setString(_recentWorkspacesKey, jsonEncode(jsonList));
    } catch (e) {
      // Ignore errors saving preferences
    }
  }

  /// Clears the list of recent workspaces.
  Future<void> clearRecentWorkspaces() async {
    _recentWorkspaces.clear();
    await _saveRecentWorkspaces();

    // Emit event
    _workspaceEvents.add(WorkspaceEvent(
      type: WorkspaceEventType.recentWorkspacesUpdated,
    ));
  }

  /// Disposes of resources.
  void dispose() {
    // Dispose of auto-save services
    for (final autoSave in _autoSaveServices.values) {
      autoSave.dispose();
    }
    _autoSaveServices.clear();

    // Close event stream
    _workspaceEvents.close();
  }
}

/// Helper for parsing and serializing JSON workspaces.
class JsonWorkspaceParser {
  /// Parses a JSON string into a workspace.
  static Workspace parse(String json) {
    final Map<String, dynamic> jsonMap = jsonDecode(json);
    return JsonSerialization.workspaceFromJson(json);
  }

  /// Serializes a workspace to a JSON string.
  static String serialize(Workspace workspace) {
    return JsonSerialization.workspaceToJson(workspace);
  }
}

/// Storage mode for workspaces.
enum StorageMode {
  /// Store workspaces as files on disk.
  file,

  /// Store workspaces in the cloud.
  cloud,
}

/// Types of workspace events.
enum WorkspaceEventType {
  /// Workspace manager has been initialized.
  initialized,

  /// A workspace is being loaded.
  loading,

  /// A workspace has been loaded.
  loaded,

  /// A workspace is being saved.
  saving,

  /// A workspace has been saved.
  saved,

  /// A workspace is being created.
  creating,

  /// A workspace has been created.
  created,

  /// A workspace has been updated.
  updated,

  /// A workspace is being closed.
  closing,

  /// A workspace has been closed.
  closed,

  /// A workspace is being deleted.
  deleting,

  /// A workspace has been deleted.
  deleted,

  /// A workspace is being restored from backup.
  restoring,

  /// A workspace has been restored from backup.
  restored,

  /// A workspace is being imported.
  importing,

  /// A workspace has been imported.
  imported,

  /// A workspace is being exported.
  exporting,

  /// A workspace has been exported.
  exported,

  /// The list of recent workspaces has been updated.
  recentWorkspacesUpdated,

  /// An error occurred during a workspace operation.
  error,
}

/// Event emitted by the workspace manager.
class WorkspaceEvent {
  /// The type of event.
  final WorkspaceEventType type;

  /// The path associated with the event, if any.
  final String? path;

  /// The workspace associated with the event, if any.
  final Workspace? workspace;

  /// The error associated with the event, if any.
  final Object? error;

  /// The stack trace associated with the error, if any.
  final StackTrace? stackTrace;

  WorkspaceEvent({
    required this.type,
    this.path,
    this.workspace,
    this.error,
    this.stackTrace,
  });
}

/// Export format for workspaces.
enum ExportFormat {
  /// Export as JSON.
  json,

  /// Export as DSL.
  dsl,
}

/// Import-export functionality for workspaces.
class WorkspaceImportExport {
  /// Imports a workspace from a file.
  static Future<Workspace> importFromFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw WorkspaceException('File does not exist', path: path);
    }

    final content = await file.readAsString();

    if (path.endsWith('.json')) {
      return JsonWorkspaceParser.parse(content);
    } else if (path.endsWith('.dsl')) {
      throw WorkspaceException('DSL import not yet supported', path: path);
    } else {
      throw WorkspaceException('Unsupported file format', path: path);
    }
  }

  /// Exports a workspace to a file.
  static Future<void> exportToFile(Workspace workspace, String path) async {
    final file = File(path);

    // Create directory if it doesn't exist
    final dir = file.parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    if (path.endsWith('.json')) {
      final json = JsonWorkspaceParser.serialize(workspace);
      await file.writeAsString(json, flush: true);
    } else if (path.endsWith('.dsl')) {
      throw WorkspaceException('DSL export not yet supported', path: path);
    } else {
      throw WorkspaceException('Unsupported file format', path: path);
    }
  }
}
