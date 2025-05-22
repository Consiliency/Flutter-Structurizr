import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../application/workspace/workspace_directory_manager.dart';
import '../../application/workspace/workspace_state_manager.dart';
import '../../infrastructure/preferences/app_preferences.dart';
import '../../infrastructure/platform/mobile_directory_picker.dart';
import '../../infrastructure/platform/mobile_permissions_manager.dart';

class WorkspaceSettingsPanel extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback? onSettingsChanged;

  const WorkspaceSettingsPanel({
    super.key,
    this.isDarkMode = false,
    this.onSettingsChanged,
  });

  @override
  State<WorkspaceSettingsPanel> createState() => _WorkspaceSettingsPanelState();
}

class _WorkspaceSettingsPanelState extends State<WorkspaceSettingsPanel> {
  late bool _autoSaveEnabled;
  late Duration _autoSaveInterval;
  late bool _createBackupsEnabled;
  late int _maxBackupsToKeep;
  String? _currentWorkspaceDirectory;
  bool _isLoading = true;
  PlatformStorageInfo? _storageInfo;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      // Load current settings
      _autoSaveEnabled = await AppPreferences.instance.getAutoSaveEnabled();
      final backupSettings = await AppPreferences.instance.getBackupSettings();
      
      _createBackupsEnabled = backupSettings.autoBackupEnabled;
      _maxBackupsToKeep = backupSettings.maxBackupCount;
      _autoSaveInterval = Duration(hours: backupSettings.backupIntervalHours);
      
      // Get current workspace directory
      _currentWorkspaceDirectory = await WorkspaceDirectoryManager.instance.getCurrentWorkspaceDirectory();
      
      // Get platform storage info
      _storageInfo = await WorkspaceDirectoryManager.instance.getStorageInfo();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading workspace settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    try {
      // Save auto-save settings
      await WorkspaceStateManager.instance.setAutoSaveEnabled(_autoSaveEnabled);
      
      // Save backup settings
      final backupSettings = BackupSettings(
        autoBackupEnabled: _createBackupsEnabled,
        backupIntervalHours: _autoSaveInterval.inHours,
        maxBackupCount: _maxBackupsToKeep,
        includeWorkspaceFiles: true,
        includePreferences: false,
        backupLocation: 'default',
      );
      await AppPreferences.instance.saveBackupSettings(backupSettings);
      
      widget.onSettingsChanged?.call();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme, colorScheme),
            const SizedBox(height: 24),
            _buildWorkspaceDirectorySection(theme, colorScheme),
            const SizedBox(height: 24),
            _buildAutoSaveSection(theme, colorScheme),
            const SizedBox(height: 24),
            _buildBackupSection(theme, colorScheme),
            const SizedBox(height: 24),
            _buildStorageInfoSection(theme, colorScheme),
            const SizedBox(height: 32),
            _buildActionButtons(theme, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(
          Icons.settings,
          color: colorScheme.primary,
          size: 24,
        ),
        const SizedBox(width: 12),
        Text(
          'Workspace Settings',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkspaceDirectorySection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Default Workspace Directory',
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.folder,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentWorkspaceDirectory ?? 'Unknown',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _changeWorkspaceDirectory,
                  icon: const Icon(Icons.folder_open, size: 18),
                  label: const Text('Change Directory'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAutoSaveSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Auto-save Settings',
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Enable Auto-save'),
          subtitle: const Text('Automatically save workspace changes'),
          value: _autoSaveEnabled,
          onChanged: (value) {
            setState(() {
              _autoSaveEnabled = value;
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
        if (_autoSaveEnabled) ...[
          const SizedBox(height: 16),
          Text(
            'Auto-save Interval',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<Duration>(
            value: _autoSaveInterval,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: const [
              DropdownMenuItem(
                value: Duration(minutes: 1),
                child: Text('1 minute'),
              ),
              DropdownMenuItem(
                value: Duration(minutes: 5),
                child: Text('5 minutes'),
              ),
              DropdownMenuItem(
                value: Duration(minutes: 15),
                child: Text('15 minutes'),
              ),
              DropdownMenuItem(
                value: Duration(minutes: 30),
                child: Text('30 minutes'),
              ),
              DropdownMenuItem(
                value: Duration(hours: 1),
                child: Text('1 hour'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _autoSaveInterval = value;
                });
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _buildBackupSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Backup Settings',
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Create Automatic Backups'),
          subtitle: const Text('Create backups before saving changes'),
          value: _createBackupsEnabled,
          onChanged: (value) {
            setState(() {
              _createBackupsEnabled = value;
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
        if (_createBackupsEnabled) ...[
          const SizedBox(height: 16),
          Text(
            'Maximum Backups to Keep',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _maxBackupsToKeep,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: const [
              DropdownMenuItem(value: 3, child: Text('3 backups')),
              DropdownMenuItem(value: 5, child: Text('5 backups')),
              DropdownMenuItem(value: 10, child: Text('10 backups')),
              DropdownMenuItem(value: 20, child: Text('20 backups')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _maxBackupsToKeep = value;
                });
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _buildStorageInfoSection(ThemeData theme, ColorScheme colorScheme) {
    if (_storageInfo == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Storage Information',
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              _buildInfoRow(
                'Platform',
                _storageInfo!.platform.toUpperCase(),
                Icons.computer,
                theme,
                colorScheme,
              ),
              _buildInfoRow(
                'Directory Picker',
                _storageInfo!.supportsDirectoryPicker ? 'Supported' : 'Not Supported',
                _storageInfo!.supportsDirectoryPicker ? Icons.check_circle : Icons.error,
                theme,
                colorScheme,
              ),
              _buildInfoRow(
                'External Storage',
                _storageInfo!.isExternalStorageAvailable ? 'Available' : 'Not Available',
                _storageInfo!.isExternalStorageAvailable ? Icons.sd_storage : Icons.storage,
                theme,
                colorScheme,
              ),
              _buildInfoRow(
                'Permissions Required',
                _storageInfo!.requiresPermissions ? 'Yes' : 'No',
                _storageInfo!.requiresPermissions ? Icons.security : Icons.lock_open,
                theme,
                colorScheme,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _loadSettings,
            child: const Text('Reset to Defaults'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FilledButton(
            onPressed: _saveSettings,
            child: const Text('Save Settings'),
          ),
        ),
      ],
    );
  }

  Future<void> _changeWorkspaceDirectory() async {
    try {
      // Check permissions on mobile platforms
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        final permissionsManager = MobilePermissionsManager.instance;
        await permissionsManager.initialize();
        
        final hasPermission = await permissionsManager.hasFileAccessPermissions();
        if (!hasPermission) {
          final result = await permissionsManager.requestStoragePermissions();
          if (result != PermissionStatus.granted) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Storage permission required to change directory'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            return;
          }
        }
      }

      // Use directory picker
      final directoryPicker = MobileDirectoryPicker.instance;
      final result = await directoryPicker.pickDirectory(
        initialDirectory: _currentWorkspaceDirectory,
        dialogTitle: 'Select Workspace Directory',
      );

      if (result != null && result.isWritable) {
        // Validate directory
        final validationResult = await directoryPicker.validateDirectoryAccess(result);
        
        if (validationResult.isValid) {
          // Update workspace directory
          await WorkspaceDirectoryManager.instance.setWorkspaceDirectory(result.path);
          
          setState(() {
            _currentWorkspaceDirectory = result.path;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Workspace directory changed to ${result.path}'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Invalid directory: ${validationResult.issues.join(', ')}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error changing directory: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

/// Mobile-optimized workspace settings panel
class MobileWorkspaceSettingsPanel extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback? onSettingsChanged;

  const MobileWorkspaceSettingsPanel({
    super.key,
    this.isDarkMode = false,
    this.onSettingsChanged,
  });

  static Future<void> show({
    required BuildContext context,
    bool isDarkMode = false,
    VoidCallback? onSettingsChanged,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MobileWorkspaceSettingsPanel(
        isDarkMode: isDarkMode,
        onSettingsChanged: onSettingsChanged,
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
                        Icons.settings,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Workspace Settings',
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
            
            // Settings content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: WorkspaceSettingsPanel(
                  isDarkMode: isDarkMode,
                  onSettingsChanged: () {
                    onSettingsChanged?.call();
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}