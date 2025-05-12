import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/infrastructure/persistence/file_storage.dart';
import 'package:flutter_structurizr/infrastructure/persistence/auto_save.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Example application demonstrating the use of FileStorage and AutoSave.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize file storage
  final workspacesDirectory = await FileStorage.getDefaultWorkspaceDirectory();
  final backupDirectory = await FileStorage.getDefaultBackupDirectory();
  
  final fileStorage = FileStorage(
    workspacesDirectory: workspacesDirectory,
    backupDirectory: backupDirectory,
  );
  
  final autoSave = AutoSave(
    storage: fileStorage,
    intervalMs: 5000, // Auto-save every 5 seconds
  );
  
  runApp(StorageExampleApp(
    fileStorage: fileStorage,
    autoSave: autoSave,
  ));
}

/// Main app widget for the storage example.
class StorageExampleApp extends StatelessWidget {
  final FileStorage fileStorage;
  final AutoSave autoSave;
  
  const StorageExampleApp({
    Key? key,
    required this.fileStorage,
    required this.autoSave,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Structurizr Storage Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: StorageExampleHome(
        fileStorage: fileStorage,
        autoSave: autoSave,
      ),
    );
  }
}

/// Home screen for the storage example.
class StorageExampleHome extends StatefulWidget {
  final FileStorage fileStorage;
  final AutoSave autoSave;
  
  const StorageExampleHome({
    Key? key,
    required this.fileStorage,
    required this.autoSave,
  }) : super(key: key);
  
  @override
  _StorageExampleHomeState createState() => _StorageExampleHomeState();
}

class _StorageExampleHomeState extends State<StorageExampleHome> {
  List<WorkspaceMetadata> _workspaces = [];
  Workspace? _currentWorkspace;
  String? _currentWorkspacePath;
  bool _autoSaveEnabled = true;
  double _saveProgress = 0.0;
  bool _isSaving = false;
  List<String> _events = [];
  
  @override
  void initState() {
    super.initState();
    
    // Listen for auto-save events
    widget.autoSave.autoSaveEvents.listen(_handleAutoSaveEvent);
    
    // Load workspaces
    _loadWorkspaces();
  }
  
  @override
  void dispose() {
    // Stop auto-save and dispose resources
    widget.autoSave.dispose();
    super.dispose();
  }
  
  /// Loads the list of available workspaces.
  Future<void> _loadWorkspaces() async {
    final workspaces = await widget.fileStorage.listWorkspaces();
    
    setState(() {
      _workspaces = workspaces;
    });
  }
  
  /// Creates a new workspace.
  Future<void> _createWorkspace() async {
    // Show a dialog to get the workspace name
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _NewWorkspaceDialog(),
    );
    
    if (name != null && name.isNotEmpty) {
      // Create a new workspace
      final tempDir = await getTemporaryDirectory();
      final workspacePath = path.join(
        widget.fileStorage.repository.workspacesDirectory,
        '${name.toLowerCase().replaceAll(' ', '-')}.json',
      );
      
      final metadata = WorkspaceMetadata(
        path: workspacePath,
        name: name,
        description: 'A new workspace',
        lastModified: DateTime.now(),
      );
      
      final workspace = await widget.fileStorage.createWorkspace(metadata);
      
      // Reload workspaces
      await _loadWorkspaces();
      
      // Open the new workspace
      _openWorkspace(workspacePath);
    }
  }
  
  /// Opens a workspace.
  Future<void> _openWorkspace(String path) async {
    setState(() {
      _isSaving = false;
      _saveProgress = 0.0;
    });
    
    try {
      // Load the workspace
      final workspace = await widget.fileStorage.loadWorkspace(
        path,
        onProgress: (progress) {
          setState(() {
            _saveProgress = progress;
          });
        },
      );
      
      setState(() {
        _currentWorkspace = workspace;
        _currentWorkspacePath = path;
        _saveProgress = 0.0;
      });
      
      // Start auto-save
      widget.autoSave.startMonitoring(
        workspace,
        path,
        onWorkspaceChanged: (workspace) {
          setState(() {
            _currentWorkspace = workspace;
          });
        },
      );
      
      // Enable auto-save
      widget.autoSave.setEnabled(_autoSaveEnabled);
      
      _logEvent('Opened workspace: ${workspace.name}');
    } catch (e) {
      _showError('Failed to open workspace', e);
    }
  }
  
  /// Saves the current workspace.
  Future<void> _saveWorkspace() async {
    if (_currentWorkspace == null || _currentWorkspacePath == null) {
      return;
    }
    
    setState(() {
      _isSaving = true;
      _saveProgress = 0.0;
    });
    
    try {
      await widget.autoSave.saveNow(
        onProgress: (progress) {
          setState(() {
            _saveProgress = progress;
          });
        },
      );
      
      _logEvent('Manually saved workspace: ${_currentWorkspace!.name}');
    } catch (e) {
      _showError('Failed to save workspace', e);
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
  
  /// Updates the current workspace with a new description.
  void _updateCurrentWorkspace() {
    if (_currentWorkspace == null) {
      return;
    }
    
    // Create a new workspace with an updated description
    final updatedWorkspace = Workspace(
      id: _currentWorkspace!.id,
      name: _currentWorkspace!.name,
      description: '${_currentWorkspace!.description ?? ''} (Updated: ${DateTime.now()})',
      model: _currentWorkspace!.model,
    );
    
    // Update the workspace in auto-save
    widget.autoSave.updateWorkspace(updatedWorkspace);
    
    _logEvent('Updated workspace: ${updatedWorkspace.name}');
  }
  
  /// Toggles auto-save on or off.
  void _toggleAutoSave() {
    setState(() {
      _autoSaveEnabled = !_autoSaveEnabled;
    });
    
    widget.autoSave.setEnabled(_autoSaveEnabled);
    
    _logEvent('Auto-save ${_autoSaveEnabled ? 'enabled' : 'disabled'}');
  }
  
  /// Handles auto-save events.
  void _handleAutoSaveEvent(AutoSaveEvent event) {
    String message;
    
    switch (event.type) {
      case AutoSaveEventType.saveCompleted:
        message = 'Auto-save completed';
        setState(() {
          _saveProgress = 0.0;
        });
        break;
      case AutoSaveEventType.savingStarted:
        message = 'Auto-save started';
        setState(() {
          _saveProgress = 0.1;
        });
        break;
      case AutoSaveEventType.saveFailed:
        message = 'Auto-save failed: ${event.error}';
        setState(() {
          _saveProgress = 0.0;
        });
        break;
      case AutoSaveEventType.enabled:
        message = 'Auto-save enabled';
        break;
      case AutoSaveEventType.disabled:
        message = 'Auto-save disabled';
        break;
      case AutoSaveEventType.intervalChanged:
        message = 'Auto-save interval changed to ${event.intervalMs}ms';
        break;
      case AutoSaveEventType.monitoringStarted:
        message = 'Started monitoring workspace: ${event.workspace?.name}';
        break;
      case AutoSaveEventType.monitoringStopped:
        message = 'Stopped monitoring workspace';
        break;
      case AutoSaveEventType.workspaceUpdated:
        message = 'Workspace updated';
        break;
      default:
        message = 'Unknown event: ${event.type}';
    }
    
    _logEvent(message);
  }
  
  /// Logs an event to the UI.
  void _logEvent(String message) {
    setState(() {
      _events.insert(0, '[${DateTime.now().toIso8601String()}] $message');
      
      // Limit to 100 events
      if (_events.length > 100) {
        _events = _events.sublist(0, 100);
      }
    });
  }
  
  /// Shows an error dialog.
  void _showError(String message, Object error) {
    _logEvent('ERROR: $message - $error');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text('$message\n\n$error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Structurizr Storage Example'),
        actions: [
          if (_currentWorkspace != null)
            IconButton(
              icon: Icon(_autoSaveEnabled ? Icons.sync : Icons.sync_disabled),
              tooltip: _autoSaveEnabled ? 'Disable Auto-Save' : 'Enable Auto-Save',
              onPressed: _toggleAutoSave,
            ),
          if (_currentWorkspace != null)
            IconButton(
              icon: Icon(Icons.save),
              tooltip: 'Save Workspace',
              onPressed: _isSaving ? null : _saveWorkspace,
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isSaving || _saveProgress > 0)
            LinearProgressIndicator(value: _saveProgress),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Workspace list
                SizedBox(
                  width: 300,
                  child: Card(
                    margin: EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Text(
                                'Workspaces',
                                style: Theme.of(context).textTheme.headline6,
                              ),
                              Spacer(),
                              IconButton(
                                icon: Icon(Icons.refresh),
                                tooltip: 'Refresh',
                                onPressed: _loadWorkspaces,
                              ),
                              IconButton(
                                icon: Icon(Icons.add),
                                tooltip: 'New Workspace',
                                onPressed: _createWorkspace,
                              ),
                            ],
                          ),
                        ),
                        Divider(),
                        Expanded(
                          child: _workspaces.isEmpty
                              ? Center(
                                  child: Text('No workspaces found'),
                                )
                              : ListView.builder(
                                  itemCount: _workspaces.length,
                                  itemBuilder: (context, index) {
                                    final workspace = _workspaces[index];
                                    return ListTile(
                                      title: Text(workspace.name),
                                      subtitle: Text(workspace.description ?? ''),
                                      selected: _currentWorkspacePath == workspace.path,
                                      onTap: () => _openWorkspace(workspace.path),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Workspace details
                Expanded(
                  child: Card(
                    margin: EdgeInsets.all(8),
                    child: _currentWorkspace == null
                        ? Center(
                            child: Text('No workspace open'),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currentWorkspace!.name,
                                      style: Theme.of(context).textTheme.headline5,
                                    ),
                                    if (_currentWorkspace!.description != null)
                                      Padding(
                                        padding: EdgeInsets.only(top: 8),
                                        child: Text(_currentWorkspace!.description!),
                                      ),
                                    SizedBox(height: 16),
                                    Row(
                                      children: [
                                        ElevatedButton(
                                          onPressed: _updateCurrentWorkspace,
                                          child: Text('Update Description'),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          widget.autoSave.hasUnsavedChanges()
                                              ? 'Unsaved changes'
                                              : 'No unsaved changes',
                                          style: TextStyle(
                                            color: widget.autoSave.hasUnsavedChanges()
                                                ? Colors.red
                                                : Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Divider(),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Text(
                                  'Event Log',
                                  style: Theme.of(context).textTheme.subtitle1,
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: _events.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: EdgeInsets.symmetric(vertical: 4),
                                      child: Text(
                                        _events[index],
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 12,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog for creating a new workspace.
class _NewWorkspaceDialog extends StatefulWidget {
  @override
  _NewWorkspaceDialogState createState() => _NewWorkspaceDialogState();
}

class _NewWorkspaceDialogState extends State<_NewWorkspaceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('New Workspace'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Workspace Name',
                hintText: 'Enter a name for the workspace',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
              autofocus: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(_nameController.text);
            }
          },
          child: Text('Create'),
        ),
      ],
    );
  }
}