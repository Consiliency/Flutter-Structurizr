import 'package:flutter/material.dart';

/// Mobile-optimized dialog for creating a new workspace
class MobileNewWorkspaceDialog extends StatefulWidget {
  final Function(String)? onWorkspaceCreated;

  const MobileNewWorkspaceDialog({
    super.key,
    this.onWorkspaceCreated,
  });

  static Future<String?> show({
    required BuildContext context,
    Function(String)? onWorkspaceCreated,
  }) async {
    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MobileNewWorkspaceDialog(
        onWorkspaceCreated: onWorkspaceCreated,
      ),
    );
  }

  @override
  State<MobileNewWorkspaceDialog> createState() => _MobileNewWorkspaceDialogState();
}

class _MobileNewWorkspaceDialogState extends State<MobileNewWorkspaceDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

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
      ),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surface,
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Row(
                children: [
                  Icon(
                    Icons.create_new_folder,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Create New Workspace',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Workspace Name',
                        hintText: 'Enter a name for your workspace',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.edit),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a workspace name';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Describe your workspace',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isCreating ? null : _createWorkspace,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isCreating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create Workspace'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createWorkspace() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
    });

    try {
      final workspaceName = _nameController.text.trim();
      
      // Create new workspace (this would be implemented in your workspace creation logic)
      // For now, just return the name
      widget.onWorkspaceCreated?.call(workspaceName);
      
      if (mounted) {
        Navigator.of(context).pop(workspaceName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating workspace: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }
}

/// Mobile-optimized workspace import dialog
class MobileWorkspaceImportDialog extends StatefulWidget {
  final Function(String)? onWorkspaceImported;

  const MobileWorkspaceImportDialog({
    super.key,
    this.onWorkspaceImported,
  });

  static Future<void> show({
    required BuildContext context,
    Function(String)? onWorkspaceImported,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MobileWorkspaceImportDialog(
        onWorkspaceImported: onWorkspaceImported,
      ),
    );
  }

  @override
  State<MobileWorkspaceImportDialog> createState() => _MobileWorkspaceImportDialogState();
}

class _MobileWorkspaceImportDialogState extends State<MobileWorkspaceImportDialog> {
  bool _isImporting = false;

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
      ),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surface,
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Row(
                children: [
                  Icon(
                    Icons.file_upload,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Import Workspace',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Import options
              Column(
                children: [
                  _buildImportOption(
                    icon: Icons.description,
                    title: 'JSON Workspace',
                    subtitle: 'Import a JSON workspace file',
                    onTap: () => _importFile('json'),
                    colorScheme: colorScheme,
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  _buildImportOption(
                    icon: Icons.code,
                    title: 'DSL Workspace',
                    subtitle: 'Import a Structurizr DSL file',
                    onTap: () => _importFile('dsl'),
                    colorScheme: colorScheme,
                    theme: theme,
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Cancel button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isImporting ? null : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required ThemeData theme,
  }) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: _isImporting ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  icon,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _importFile(String fileType) async {
    setState(() {
      _isImporting = true;
    });

    try {
      // File import logic would be implemented here
      // For now, just simulate the operation
      await Future.delayed(const Duration(seconds: 1));
      
      widget.onWorkspaceImported?.call(fileType);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$fileType file import initiated'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing file: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }
}

/// Mobile-optimized workspace management dialog
class MobileWorkspaceManagementDialog extends StatelessWidget {
  final String workspaceName;
  final String workspacePath;
  final VoidCallback? onSave;
  final VoidCallback? onBackup;
  final VoidCallback? onExport;
  final VoidCallback? onDelete;
  final VoidCallback? onClose;

  const MobileWorkspaceManagementDialog({
    super.key,
    required this.workspaceName,
    required this.workspacePath,
    this.onSave,
    this.onBackup,
    this.onExport,
    this.onDelete,
    this.onClose,
  });

  static Future<void> show({
    required BuildContext context,
    required String workspaceName,
    required String workspacePath,
    VoidCallback? onSave,
    VoidCallback? onBackup,
    VoidCallback? onExport,
    VoidCallback? onDelete,
    VoidCallback? onClose,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => MobileWorkspaceManagementDialog(
        workspaceName: workspaceName,
        workspacePath: workspacePath,
        onSave: onSave,
        onBackup: onBackup,
        onExport: onExport,
        onDelete: onDelete,
        onClose: onClose,
      ),
    );
  }

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
      ),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surface,
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Row(
                children: [
                  Icon(
                    Icons.folder,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workspaceName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          workspacePath,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Action buttons
              Column(
                children: [
                  _buildActionButton(
                    icon: Icons.save,
                    label: 'Save Workspace',
                    onTap: () {
                      Navigator.of(context).pop();
                      onSave?.call();
                    },
                    colorScheme: colorScheme,
                    theme: theme,
                  ),
                  const SizedBox(height: 8),
                  _buildActionButton(
                    icon: Icons.backup,
                    label: 'Create Backup',
                    onTap: () {
                      Navigator.of(context).pop();
                      onBackup?.call();
                    },
                    colorScheme: colorScheme,
                    theme: theme,
                  ),
                  const SizedBox(height: 8),
                  _buildActionButton(
                    icon: Icons.file_download,
                    label: 'Export Workspace',
                    onTap: () {
                      Navigator.of(context).pop();
                      onExport?.call();
                    },
                    colorScheme: colorScheme,
                    theme: theme,
                  ),
                  const SizedBox(height: 16),
                  _buildActionButton(
                    icon: Icons.delete,
                    label: 'Delete Workspace',
                    onTap: () {
                      Navigator.of(context).pop();
                      onDelete?.call();
                    },
                    colorScheme: colorScheme,
                    theme: theme,
                    isDestructive: true,
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Close button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onClose?.call();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required ThemeData theme,
    bool isDestructive = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(
          icon,
          color: isDestructive ? colorScheme.error : null,
        ),
        label: Text(
          label,
          style: TextStyle(
            color: isDestructive ? colorScheme.error : null,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          side: isDestructive ? BorderSide(color: colorScheme.error) : null,
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
}