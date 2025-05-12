import 'dart:convert';
import 'dart:io';
import 'package:flutter_structurizr/application/workspace/workspace_repository.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/infrastructure/serialization/json_serialization.dart';
import 'package:path/path.dart' as path;

/// Implementation of [WorkspaceRepository] that uses the file system.
class FileWorkspaceRepository implements WorkspaceRepository {
  /// The default directory to store workspaces.
  final String workspacesDirectory;
  
  FileWorkspaceRepository({required this.workspacesDirectory});
  
  @override
  Future<Workspace> loadWorkspace(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        throw WorkspaceException('Workspace file does not exist', path: path);
      }
      
      final content = await file.readAsString();
      
      if (path.endsWith('.json')) {
        try {
          return JsonSerialization.workspaceFromJson(content);
        } catch (e) {
          throw WorkspaceException('Failed to parse workspace JSON', path: path, cause: e);
        }
      } else if (path.endsWith('.dsl')) {
        throw WorkspaceException('DSL format not yet supported', path: path);
      } else {
        throw WorkspaceException('Unsupported file format', path: path);
      }
    } catch (e) {
      if (e is WorkspaceException) {
        rethrow;
      }
      throw WorkspaceException('Failed to load workspace', path: path, cause: e);
    }
  }
  
  @override
  Future<void> saveWorkspace(Workspace workspace, String path) async {
    try {
      final file = File(path);
      final dir = file.parent;
      
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      if (path.endsWith('.json')) {
        final json = JsonSerialization.workspaceToJson(workspace);
        await file.writeAsString(json, flush: true);
      } else if (path.endsWith('.dsl')) {
        throw WorkspaceException('DSL format not yet supported', path: path);
      } else {
        throw WorkspaceException('Unsupported file format', path: path);
      }
    } catch (e) {
      if (e is WorkspaceException) {
        rethrow;
      }
      throw WorkspaceException('Failed to save workspace', path: path, cause: e);
    }
  }
  
  @override
  Future<List<WorkspaceMetadata>> listWorkspaces() async {
    try {
      final dir = Directory(workspacesDirectory);
      
      if (!await dir.exists()) {
        await dir.create(recursive: true);
        return [];
      }
      
      final workspaces = <WorkspaceMetadata>[];
      
      await for (final entity in dir.list(recursive: false)) {
        if (entity is File && 
            (entity.path.endsWith('.json') || entity.path.endsWith('.dsl'))) {
          try {
            final stat = await entity.stat();
            final lastModified = stat.modified;
            
            String? name;
            String? description;
            
            if (entity.path.endsWith('.json')) {
              final content = await entity.readAsString();
              final json = jsonDecode(content) as Map<String, dynamic>;
              
              name = json['name'] as String?;
              description = json['description'] as String?;
            }
            
            name ??= path.basenameWithoutExtension(entity.path);
            
            workspaces.add(WorkspaceMetadata(
              path: entity.path,
              name: name,
              description: description,
              lastModified: lastModified,
            ));
          } catch (e) {
            // Skip files that can't be parsed
            continue;
          }
        }
      }
      
      // Sort by last modified, newest first
      workspaces.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      
      return workspaces;
    } catch (e) {
      throw WorkspaceException(
        'Failed to list workspaces',
        path: workspacesDirectory,
        cause: e,
      );
    }
  }
  
  @override
  Future<bool> workspaceExists(String path) async {
    try {
      final file = File(path);
      return await file.exists();
    } catch (e) {
      throw WorkspaceException('Failed to check if workspace exists', path: path, cause: e);
    }
  }
  
  @override
  Future<Workspace> createWorkspace(WorkspaceMetadata metadata) async {
    final workspace = Workspace(
      id: DateTime.now().millisecondsSinceEpoch,
      name: metadata.name,
      description: metadata.description,
      model: const Model(),
    );
    
    await saveWorkspace(workspace, metadata.path);
    return workspace;
  }
  
  @override
  Future<void> deleteWorkspace(String path) async {
    try {
      final file = File(path);
      
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw WorkspaceException('Failed to delete workspace', path: path, cause: e);
    }
  }
}