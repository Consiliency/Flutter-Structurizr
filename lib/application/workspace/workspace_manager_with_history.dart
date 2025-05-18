import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_structurizr/application/command/command.dart';
import 'package:flutter_structurizr/application/command/history_manager.dart';
import 'package:flutter_structurizr/application/command/workspace_commands.dart';
import 'package:flutter_structurizr/application/workspace/workspace_manager.dart';
import 'package:flutter_structurizr/application/workspace/workspace_repository.dart';
import 'package:flutter_structurizr/domain/documentation/documentation.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/element.dart'
    as structurizr_model;
import 'package:flutter_structurizr/domain/model/element_alias.dart';
import 'package:flutter_structurizr/domain/model/infrastructure_node.dart';
import 'package:flutter_structurizr/domain/model/relationship.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/domain/view/views.dart';
import 'package:flutter_structurizr/infrastructure/persistence/auto_save.dart';
import 'package:flutter_structurizr/infrastructure/persistence/file_storage.dart';
import 'package:flutter_structurizr/infrastructure/serialization/json_serialization.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' show Offset;

/// Manager for tracking and handling multiple workspaces with history support.
///
/// This class extends the basic WorkspaceManager with undo/redo capabilities
/// by incorporating a HistoryManager for each workspace.
class WorkspaceManagerWithHistory implements WorkspaceManager {
  /// The underlying workspace manager.
  final WorkspaceManager _workspaceManager;

  /// History managers for each workspace path.
  final Map<String, HistoryManager> _historyManagers = {};

  /// Stream controller for history events.
  final _historyEventsController = StreamController<HistoryEvent>.broadcast();

  /// Creates a new workspace manager with history support.
  WorkspaceManagerWithHistory(this._workspaceManager) {
    // Subscribe to workspace events
    _workspaceManager.workspaceEvents.listen(_handleWorkspaceEvent);
  }

  /// Stream of history events.
  Stream<HistoryEvent> get historyEvents => _historyEventsController.stream;

  /// Gets a history manager for a workspace path, creating one if it doesn't exist.
  HistoryManager _getHistoryManager(String path) {
    if (!_historyManagers.containsKey(path)) {
      _historyManagers[path] = HistoryManager();

      // Subscribe to history changes
      _historyManagers[path]!.historyChanges.listen((_) {
        _notifyHistoryChanged(path);
      });
    }
    return _historyManagers[path]!;
  }

  /// Handles workspace events from the underlying workspace manager.
  void _handleWorkspaceEvent(WorkspaceEvent event) {
    switch (event.type) {
      case WorkspaceEventType.closed:
        // Dispose of history manager when workspace is closed
        if (event.path != null && _historyManagers.containsKey(event.path!)) {
          _historyManagers[event.path!]!.dispose();
          _historyManagers.remove(event.path!);
        }
        break;
      case WorkspaceEventType.deleted:
        // Dispose of history manager when workspace is deleted
        if (event.path != null && _historyManagers.containsKey(event.path!)) {
          _historyManagers[event.path!]!.dispose();
          _historyManagers.remove(event.path!);
        }
        break;
      default:
        // No special handling for other event types
        break;
    }
  }

  /// Notifies listeners that the history has changed for a workspace.
  void _notifyHistoryChanged(String path) {
    final historyManager = _historyManagers[path];
    if (historyManager == null) return;

    _historyEventsController.add(HistoryEvent(
      path: path,
      canUndo: historyManager.canUndo,
      canRedo: historyManager.canRedo,
      undoDescription: historyManager.undoDescription,
      redoDescription: historyManager.redoDescription,
    ));
  }

  /// Implements all the WorkspaceManager methods, but forwards them through
  /// the command pattern for undo/redo support

  @override
  Future<Workspace> createWorkspace(WorkspaceMetadata metadata,
      {ValueChanged<double>? onProgress}) {
    return _workspaceManager.createWorkspace(metadata, onProgress: onProgress);
  }

  @override
  Future<void> deleteWorkspace(String path, {bool deleteBackups = true}) {
    return _workspaceManager.deleteWorkspace(path,
        deleteBackups: deleteBackups);
  }

  @override
  void dispose() {
    // Dispose of all history managers
    for (final historyManager in _historyManagers.values) {
      historyManager.dispose();
    }
    _historyManagers.clear();

    // Close history events controller
    _historyEventsController.close();

    // Dispose of underlying workspace manager
    _workspaceManager.dispose();
  }

  @override
  Future<void> exportWorkspace(String sourcePath, String destinationPath,
      {ExportFormat format = ExportFormat.json,
      ValueChanged<double>? onProgress}) {
    return _workspaceManager.exportWorkspace(sourcePath, destinationPath,
        format: format, onProgress: onProgress);
  }

  @override
  bool hasUnsavedChanges(String path) {
    return _workspaceManager.hasUnsavedChanges(path);
  }

  @override
  Future<void> importWorkspace(String sourcePath, String destinationPath,
      {ValueChanged<double>? onProgress}) {
    return _workspaceManager.importWorkspace(sourcePath, destinationPath,
        onProgress: onProgress);
  }

  @override
  Future<void> initialize() {
    return _workspaceManager.initialize();
  }

  @override
  Future<List<WorkspaceBackup>> listBackups(String path) {
    return _workspaceManager.listBackups(path);
  }

  @override
  Future<List<WorkspaceMetadata>> listWorkspaces() {
    return _workspaceManager.listWorkspaces();
  }

  @override
  Map<String, Workspace> get loadedWorkspaces =>
      _workspaceManager.loadedWorkspaces;

  @override
  Future<Workspace> openWorkspace(String path,
      {ValueChanged<double>? onProgress}) {
    return _workspaceManager.openWorkspace(path, onProgress: onProgress);
  }

  @override
  List<WorkspaceMetadata> get recentWorkspaces =>
      _workspaceManager.recentWorkspaces;

  @override
  Future<Workspace> restoreFromBackup(WorkspaceBackup backup,
      {bool overwriteOriginal = true, ValueChanged<double>? onProgress}) {
    return _workspaceManager.restoreFromBackup(backup,
        overwriteOriginal: overwriteOriginal, onProgress: onProgress);
  }

  @override
  Future<void> saveWorkspace(String path,
      {Workspace? workspace,
      bool createBackup = true,
      ValueChanged<double>? onProgress}) {
    return _workspaceManager.saveWorkspace(path,
        workspace: workspace,
        createBackup: createBackup,
        onProgress: onProgress);
  }

  @override
  void setAutoSaveEnabled(String path, bool enabled) {
    _workspaceManager.setAutoSaveEnabled(path, enabled);
  }

  @override
  void setAutoSaveInterval(String path, int intervalMs) {
    _workspaceManager.setAutoSaveInterval(path, intervalMs);
  }

  @override
  Stream<WorkspaceEvent> get workspaceEvents =>
      _workspaceManager.workspaceEvents;

  @override
  Future<void> closeWorkspace(String path,
      {bool saveBeforeClosing = true, ValueChanged<double>? onProgress}) {
    return _workspaceManager.closeWorkspace(path,
        saveBeforeClosing: saveBeforeClosing, onProgress: onProgress);
  }

  @override
  Future<void> clearRecentWorkspaces() {
    return _workspaceManager.clearRecentWorkspaces();
  }

  /// Updates a workspace through the command system for undo/redo support.
  @override
  void updateWorkspace(String path, Workspace workspace) {
    final historyManager = _getHistoryManager(path);

    // Get the current workspace
    final currentWorkspace = _workspaceManager.loadedWorkspaces[path];
    if (currentWorkspace == null) {
      // If there's no current workspace, just forward the call
      _workspaceManager.updateWorkspace(path, workspace);
      return;
    }

    // Create a command to update the workspace
    final command = WorkspaceUpdateCommand(
      currentWorkspace,
      workspace,
      (updatedWorkspace) =>
          _workspaceManager.updateWorkspace(path, updatedWorkspace),
      'Update workspace',
    );

    // Execute the command through the history manager
    historyManager.executeCommand(command);
  }

  // Additional methods for undo/redo functionality

  /// Checks if undo is available for a workspace.
  bool canUndo(String path) {
    if (!_historyManagers.containsKey(path)) return false;
    return _historyManagers[path]!.canUndo;
  }

  /// Checks if redo is available for a workspace.
  bool canRedo(String path) {
    if (!_historyManagers.containsKey(path)) return false;
    return _historyManagers[path]!.canRedo;
  }

  /// Gets the description of the command that would be undone.
  String? undoDescription(String path) {
    if (!_historyManagers.containsKey(path)) return null;
    return _historyManagers[path]!.undoDescription;
  }

  /// Gets the description of the command that would be redone.
  String? redoDescription(String path) {
    if (!_historyManagers.containsKey(path)) return null;
    return _historyManagers[path]!.redoDescription;
  }

  /// Gets the list of undo command descriptions for a workspace.
  List<String> undoDescriptions(String path) {
    if (!_historyManagers.containsKey(path)) return [];
    return _historyManagers[path]!.undoDescriptions;
  }

  /// Gets the list of redo command descriptions for a workspace.
  List<String> redoDescriptions(String path) {
    if (!_historyManagers.containsKey(path)) return [];
    return _historyManagers[path]!.redoDescriptions;
  }

  /// Undoes the last command for a workspace.
  bool undo(String path) {
    if (!_historyManagers.containsKey(path)) return false;
    return _historyManagers[path]!.undo();
  }

  /// Redoes the last undone command for a workspace.
  bool redo(String path) {
    if (!_historyManagers.containsKey(path)) return false;
    return _historyManagers[path]!.redo();
  }

  /// Clears the command history for a workspace.
  void clearHistory(String path) {
    if (!_historyManagers.containsKey(path)) return;
    _historyManagers[path]!.clearHistory();
  }

  /// Begins a transaction for grouping multiple commands.
  void beginTransaction(String path) {
    if (!_historyManagers.containsKey(path)) {
      _getHistoryManager(path);
    }
    _historyManagers[path]!.beginTransaction();
  }

  /// Commits a transaction with a description.
  void commitTransaction(String path, String description) {
    if (!_historyManagers.containsKey(path)) return;
    _historyManagers[path]!.commitTransaction(description);
  }

  /// Rolls back a transaction.
  void rollbackTransaction(String path) {
    if (!_historyManagers.containsKey(path)) return;
    _historyManagers[path]!.rollbackTransaction();
  }

  // Specific commands for common workspace operations

  /// Adds a person to a workspace with undo/redo support.
  void addPerson(String path, Person person) {
    final workspace = _workspaceManager.loadedWorkspaces[path];
    if (workspace == null) return;

    final command = AddPersonCommand(
      workspace,
      person,
      (updatedWorkspace) =>
          _workspaceManager.updateWorkspace(path, updatedWorkspace),
    );

    _getHistoryManager(path).executeCommand(command);
  }

  /// Adds a software system to a workspace with undo/redo support.
  void addSoftwareSystem(String path, SoftwareSystem system) {
    final workspace = _workspaceManager.loadedWorkspaces[path];
    if (workspace == null) return;

    final command = AddSoftwareSystemCommand(
      workspace,
      system,
      (updatedWorkspace) =>
          _workspaceManager.updateWorkspace(path, updatedWorkspace),
    );

    _getHistoryManager(path).executeCommand(command);
  }

  /// Adds a container to a workspace with undo/redo support.
  void addContainer(String path, String parentSystemId,
      structurizr_model.Container container) {
    final workspace = _workspaceManager.loadedWorkspaces[path];
    if (workspace == null) return;

    final command = AddContainerCommand(
      workspace,
      container,
      parentSystemId,
      (updatedWorkspace) =>
          _workspaceManager.updateWorkspace(path, updatedWorkspace),
    );

    _getHistoryManager(path).executeCommand(command);
  }

  /// Adds a component to a workspace with undo/redo support.
  void addComponent(String path, String parentSystemId,
      String parentContainerId, structurizr_model.Component component) {
    final workspace = _workspaceManager.loadedWorkspaces[path];
    if (workspace == null) return;

    final command = AddComponentCommand(
      workspace,
      component,
      parentSystemId,
      parentContainerId,
      (updatedWorkspace) =>
          _workspaceManager.updateWorkspace(path, updatedWorkspace),
    );

    _getHistoryManager(path).executeCommand(command);
  }

  /// Adds a relationship to a workspace with undo/redo support.
  void addRelationship(String path, Relationship relationship) {
    final workspace = _workspaceManager.loadedWorkspaces[path];
    if (workspace == null) return;

    final command = AddRelationshipToWorkspaceCommand(
      workspace,
      relationship,
      (updatedWorkspace) =>
          _workspaceManager.updateWorkspace(path, updatedWorkspace),
    );

    _getHistoryManager(path).executeCommand(command);
  }

  /// Adds a system landscape view to a workspace with undo/redo support.
  void addSystemLandscapeView(String path, SystemLandscapeView view) {
    final workspace = _workspaceManager.loadedWorkspaces[path];
    if (workspace == null) return;

    final command = AddSystemLandscapeViewCommand(
      workspace,
      view,
      (updatedWorkspace) =>
          _workspaceManager.updateWorkspace(path, updatedWorkspace),
    );

    _getHistoryManager(path).executeCommand(command);
  }

  /// Adds a system context view to a workspace with undo/redo support.
  void addSystemContextView(String path, SystemContextView view) {
    final workspace = _workspaceManager.loadedWorkspaces[path];
    if (workspace == null) return;

    final command = AddSystemContextViewCommand(
      workspace,
      view,
      (updatedWorkspace) =>
          _workspaceManager.updateWorkspace(path, updatedWorkspace),
    );

    _getHistoryManager(path).executeCommand(command);
  }

  /// Adds a container view to a workspace with undo/redo support.
  void addContainerView(String path, ContainerView view) {
    final workspace = _workspaceManager.loadedWorkspaces[path];
    if (workspace == null) return;

    final command = AddContainerViewCommand(
      workspace,
      view,
      (updatedWorkspace) =>
          _workspaceManager.updateWorkspace(path, updatedWorkspace),
    );

    _getHistoryManager(path).executeCommand(command);
  }

  /// Adds a component view to a workspace with undo/redo support.
  void addComponentView(String path, ComponentView view) {
    final workspace = _workspaceManager.loadedWorkspaces[path];
    if (workspace == null) return;

    final command = AddComponentViewCommand(
      workspace,
      view,
      (updatedWorkspace) =>
          _workspaceManager.updateWorkspace(path, updatedWorkspace),
    );

    _getHistoryManager(path).executeCommand(command);
  }

  /// Adds a dynamic view to a workspace with undo/redo support.
  void addDynamicView(String path, DynamicView view) {
    final workspace = _workspaceManager.loadedWorkspaces[path];
    if (workspace == null) return;

    final command = AddDynamicViewCommand(
      workspace,
      view,
      (updatedWorkspace) =>
          _workspaceManager.updateWorkspace(path, updatedWorkspace),
    );

    _getHistoryManager(path).executeCommand(command);
  }

  /// Adds a deployment view to a workspace with undo/redo support.
  void addDeploymentView(String path, DeploymentView view) {
    final workspace = _workspaceManager.loadedWorkspaces[path];
    if (workspace == null) return;

    final command = AddDeploymentViewCommand(
      workspace,
      view,
      (updatedWorkspace) =>
          _workspaceManager.updateWorkspace(path, updatedWorkspace),
    );

    _getHistoryManager(path).executeCommand(command);
  }

  /// Updates view positions with undo/redo support.
  void updateViewPositions(String path, String viewKey,
      Map<String, Offset> oldPositions, Map<String, Offset> newPositions) {
    final workspace = _workspaceManager.loadedWorkspaces[path];
    if (workspace == null) return;

    final command = UpdateViewPositionsCommand(
      workspace,
      viewKey,
      oldPositions,
      newPositions,
      (updatedWorkspace) =>
          _workspaceManager.updateWorkspace(path, updatedWorkspace),
    );

    _getHistoryManager(path).executeCommand(command);
  }

  /// Updates styles with undo/redo support.
  void updateStyles(String path, Styles oldStyles, Styles newStyles) {
    final workspace = _workspaceManager.loadedWorkspaces[path];
    if (workspace == null) return;

    final command = UpdateStylesCommand(
      workspace,
      oldStyles,
      newStyles,
      (updatedWorkspace) =>
          _workspaceManager.updateWorkspace(path, updatedWorkspace),
    );

    _getHistoryManager(path).executeCommand(command);
  }

  /// Updates documentation with undo/redo support.
  void updateDocumentation(String path, Documentation? oldDocumentation,
      Documentation newDocumentation) {
    final workspace = _workspaceManager.loadedWorkspaces[path];
    if (workspace == null) return;

    final command = UpdateDocumentationCommand(
      workspace,
      oldDocumentation,
      newDocumentation,
      (updatedWorkspace) =>
          _workspaceManager.updateWorkspace(path, updatedWorkspace),
    );

    _getHistoryManager(path).executeCommand(command);
  }

  /// Removes an element with undo/redo support.
  void removeElement(
    String path,
    structurizr_model.Element element, {
    SoftwareSystem? parentSystem,
    structurizr_model.Container? parentContainer,
    List<Relationship> incomingRelationships = const [],
    List<Relationship> outgoingRelationships = const [],
  }) {
    final workspace = _workspaceManager.loadedWorkspaces[path];
    if (workspace == null) return;

    final command = RemoveElementCommand(
      workspace,
      element,
      (updatedWorkspace) =>
          _workspaceManager.updateWorkspace(path, updatedWorkspace),
      parentSystem: parentSystem,
      parentContainer: parentContainer,
      incomingRelationships: incomingRelationships,
      outgoingRelationships: outgoingRelationships,
    );

    _getHistoryManager(path).executeCommand(command);
  }

  /// Removes a view with undo/redo support.
  void removeView(String path, View view) {
    final workspace = _workspaceManager.loadedWorkspaces[path];
    if (workspace == null) return;

    final command = RemoveViewCommand(
      workspace,
      view,
      (updatedWorkspace) =>
          _workspaceManager.updateWorkspace(path, updatedWorkspace),
    );

    _getHistoryManager(path).executeCommand(command);
  }
}

/// Event emitted by the history manager.
class HistoryEvent {
  /// The path of the workspace.
  final String path;

  /// Whether undo is available.
  final bool canUndo;

  /// Whether redo is available.
  final bool canRedo;

  /// Description of the command that would be undone.
  final String? undoDescription;

  /// Description of the command that would be redone.
  final String? redoDescription;

  HistoryEvent({
    required this.path,
    required this.canUndo,
    required this.canRedo,
    this.undoDescription,
    this.redoDescription,
  });
}
