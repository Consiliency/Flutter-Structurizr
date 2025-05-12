import 'dart:async';
import 'package:flutter_structurizr/domain/model/workspace.dart';

/// Defines the interface for workspace persistence operations.
abstract class WorkspaceRepository {
  /// Loads a workspace from storage.
  Future<Workspace> loadWorkspace(String path);
  
  /// Saves a workspace to storage.
  Future<void> saveWorkspace(Workspace workspace, String path);
  
  /// Gets a list of available workspaces.
  Future<List<WorkspaceMetadata>> listWorkspaces();
  
  /// Checks if a workspace exists at the given path.
  Future<bool> workspaceExists(String path);
  
  /// Creates a new workspace with default content.
  Future<Workspace> createWorkspace(WorkspaceMetadata metadata);
  
  /// Deletes a workspace.
  Future<void> deleteWorkspace(String path);
}

/// Metadata about a workspace.
class WorkspaceMetadata {
  /// The path to the workspace file.
  final String path;
  
  /// The name of the workspace.
  final String name;
  
  /// Optional description of the workspace.
  final String? description;
  
  /// When the workspace was last modified.
  final DateTime lastModified;
  
  WorkspaceMetadata({
    required this.path,
    required this.name,
    this.description,
    required this.lastModified,
  });
}

/// Exception thrown when a workspace operation fails.
class WorkspaceException implements Exception {
  final String message;
  final String? path;
  final Object? cause;
  
  WorkspaceException(this.message, {this.path, this.cause});
  
  @override
  String toString() {
    final buffer = StringBuffer('WorkspaceException: $message');
    
    if (path != null) {
      buffer.write(' (path: $path)');
    }
    
    if (cause != null) {
      buffer.write('\nCaused by: $cause');
    }
    
    return buffer.toString();
  }
}