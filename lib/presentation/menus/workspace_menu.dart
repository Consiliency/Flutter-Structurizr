import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../application/workspace/workspace_state_manager.dart';
import '../../infrastructure/preferences/app_preferences.dart';
import '../../infrastructure/repositories/enhanced_file_workspace_repository.dart';
import '../settings/workspace_settings_panel.dart';
import '../dialogs/save_confirmation_dialog.dart';

class WorkspaceMenu extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback? onNewWorkspace;
  final VoidCallback? onLoadWorkspace;
  final VoidCallback? onSaveWorkspace;
  final VoidCallback? onCloseWorkspace;
  final VoidCallback? onSettingsChanged;

  const WorkspaceMenu({
    super.key,
    this.isDarkMode = false,
    this.onNewWorkspace,
    this.onLoadWorkspace,
    this.onSaveWorkspace,
    this.onCloseWorkspace,
    this.onSettingsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) => _handleMenuSelection(context, value),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'new',
          child: ListTile(
            leading: Icon(Icons.create_new_folder),
            title: Text('New Workspace'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'load',
          child: ListTile(
            leading: Icon(Icons.folder_open),
            title: Text('Load Workspace'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'recent',
          child: ListTile(
            leading: Icon(Icons.history),
            title: Text('Recent Workspaces'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'save',
          child: ListTile(
            leading: Icon(Icons.save),
            title: Text('Save Workspace'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'save_as',
          child: ListTile(
            leading: Icon(Icons.save_as),
            title: Text('Save As...'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'settings',
          child: ListTile(
            leading: Icon(Icons.settings),
            title: Text('Workspace Settings'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'backup',
          child: ListTile(
            leading: Icon(Icons.backup),
            title: Text('Create Backup'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'close',
          child: ListTile(
            leading: Icon(Icons.close),
            title: Text('Close Workspace'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  void _handleMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'new':
        _handleNewWorkspace(context);
        break;
      case 'load':
        _handleLoadWorkspace(context);
        break;
      case 'recent':
        _showRecentWorkspaces(context);
        break;
      case 'save':
        _handleSaveWorkspace(context);
        break;
      case 'save_as':
        _handleSaveAsWorkspace(context);
        break;
      case 'settings':
        _showWorkspaceSettings(context);
        break;
      case 'backup':
        _handleCreateBackup(context);
        break;
      case 'close':
        _handleCloseWorkspace(context);
        break;
    }
  }

  Future<void> _handleNewWorkspace(BuildContext context) async {
    // Check for unsaved changes
    if (WorkspaceStateManager.instance.hasUnsavedChanges) {
      final result = await WorkspaceSaveConfirmationDialog.showFromState(
        context: context,
        onSave: onSaveWorkspace,
        customContent: const Text('Creating a new workspace will close the current one.'),
      );
      
      if (result == null || result.shouldCancel) return;
    }
    
    onNewWorkspace?.call();
  }

  Future<void> _handleLoadWorkspace(BuildContext context) async {
    // Check for unsaved changes
    if (WorkspaceStateManager.instance.hasUnsavedChanges) {
      final result = await WorkspaceSaveConfirmationDialog.showFromState(
        context: context,
        onSave: onSaveWorkspace,
        customContent: const Text('Loading a workspace will close the current one.'),
      );
      
      if (result == null || result.shouldCancel) return;
    }
    
    onLoadWorkspace?.call();
  }

  void _handleSaveWorkspace(BuildContext context) {
    onSaveWorkspace?.call();
  }

  void _handleSaveAsWorkspace(BuildContext context) {
    // Implementation for Save As functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Save As functionality not implemented yet'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleCloseWorkspace(BuildContext context) async {
    // Check for unsaved changes
    if (WorkspaceStateManager.instance.hasUnsavedChanges) {
      final result = await WorkspaceSaveConfirmationDialog.showFromState(
        context: context,
        onSave: onSaveWorkspace,
        customContent: const Text('Closing will discard any unsaved changes.'),
      );
      
      if (result == null || result.shouldCancel) return;
    }
    
    onCloseWorkspace?.call();
  }

  Future<void> _handleCreateBackup(BuildContext context) async {
    try {
      final backupPath = await WorkspaceStateManager.instance.createBackup();
      
      if (backupPath != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Backup created: $backupPath'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create backup'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating backup: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showWorkspaceSettings(BuildContext context) {
    if (_isMobile()) {
      MobileWorkspaceSettingsPanel.show(
        context: context,
        isDarkMode: isDarkMode,
        onSettingsChanged: onSettingsChanged,
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Workspace Settings'),
          content: SizedBox(
            width: 600,
            height: 500,
            child: WorkspaceSettingsPanel(
              isDarkMode: isDarkMode,
              onSettingsChanged: onSettingsChanged,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _showRecentWorkspaces(BuildContext context) async {
    final recentWorkspaces = await AppPreferences.instance.getWorkspaceHistory();
    
    if (!context.mounted) return;
    
    if (recentWorkspaces.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No recent workspaces found'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    if (_isMobile()) {
      _showMobileRecentWorkspaces(context, recentWorkspaces);
    } else {
      _showDesktopRecentWorkspaces(context, recentWorkspaces);
    }
  }

  void _showDesktopRecentWorkspaces(BuildContext context, List<WorkspaceHistoryEntry> workspaces) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recent Workspaces'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: RecentWorkspacesList(
            workspaces: workspaces,
            onWorkspaceSelected: (workspace) async {
              Navigator.of(context).pop();
              await _loadWorkspaceFromHistory(context, workspace);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showMobileRecentWorkspaces(BuildContext context, List<WorkspaceHistoryEntry> workspaces) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MobileRecentWorkspacesSheet(
        workspaces: workspaces,
        onWorkspaceSelected: (workspace) async {
          Navigator.of(context).pop();
          await _loadWorkspaceFromHistory(context, workspace);
        },
      ),
    );
  }

  Future<void> _loadWorkspaceFromHistory(BuildContext context, WorkspaceHistoryEntry workspace) async {
    try {
      // Check for unsaved changes first
      if (WorkspaceStateManager.instance.hasUnsavedChanges) {
        final result = await WorkspaceSaveConfirmationDialog.showFromState(
          context: context,
          onSave: onSaveWorkspace,
          customContent: Text('Loading "${workspace.workspaceName}" will close the current workspace.'),
        );
        
        if (result == null || result.shouldCancel) return;
      }

      // Check if file still exists
      if (!await File(workspace.filePath).exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File not found: ${workspace.filePath}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Load workspace using repository
      final repository = EnhancedFileWorkspaceRepository.instance;
      final loadResult = await repository.loadWorkspace(workspace.filePath);
      
      if (loadResult.success && loadResult.workspace != null) {
        await WorkspaceStateManager.instance.setCurrentWorkspace(
          loadResult.workspace!,
          workspace.filePath,
        );
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Workspace "${workspace.workspaceName}" loaded successfully'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading workspace: ${loadResult.error}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading workspace: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  bool _isMobile() {
    return !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  }
}

/// Recent workspaces list widget
class RecentWorkspacesList extends StatelessWidget {
  final List<WorkspaceHistoryEntry> workspaces;
  final Function(WorkspaceHistoryEntry) onWorkspaceSelected;

  const RecentWorkspacesList({
    super.key,
    required this.workspaces,
    required this.onWorkspaceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: workspaces.length,
      itemBuilder: (context, index) {
        final workspace = workspaces[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                workspace.fileType == 'dsl' ? Icons.code : Icons.description,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(
              workspace.workspaceName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workspace.filePath,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(workspace.lastOpened),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (workspace.fileSize != null) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.storage,
                        size: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatFileSize(workspace.fileSize!),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () => onWorkspaceSelected(workspace),
              tooltip: 'Open workspace',
            ),
            onTap: () => onWorkspaceSelected(workspace),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

/// Mobile recent workspaces bottom sheet
class MobileRecentWorkspacesSheet extends StatelessWidget {
  final List<WorkspaceHistoryEntry> workspaces;
  final Function(WorkspaceHistoryEntry) onWorkspaceSelected;

  const MobileRecentWorkspacesSheet({
    super.key,
    required this.workspaces,
    required this.onWorkspaceSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);
    
    return Container(
      margin: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 16 + mediaQuery.viewInsets.bottom,
        top: mediaQuery.padding.top + 16,
      ),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surface,
        elevation: 8,
        child: Column(
          children: [
            // Handle bar and header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.history,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Recent Workspaces',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Workspaces list
            Expanded(
              child: RecentWorkspacesList(
                workspaces: workspaces,
                onWorkspaceSelected: onWorkspaceSelected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}