import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../application/workspace/workspace_state_manager.dart';

class SaveConfirmationDialog extends StatelessWidget {
  final String workspaceName;
  final String? workspacePath;
  final Duration? timeSinceLastSave;
  final VoidCallback? onSave;
  final VoidCallback? onDiscard;
  final VoidCallback? onCancel;
  final bool isAutoSaveEnabled;
  final Widget? customContent;

  const SaveConfirmationDialog({
    super.key,
    required this.workspaceName,
    this.workspacePath,
    this.timeSinceLastSave,
    this.onSave,
    this.onDiscard,
    this.onCancel,
    this.isAutoSaveEnabled = false,
    this.customContent,
  });

  static Future<SaveConfirmationResult?> show({
    required BuildContext context,
    required String workspaceName,
    String? workspacePath,
    Duration? timeSinceLastSave,
    VoidCallback? onSave,
    VoidCallback? onDiscard,
    VoidCallback? onCancel,
    bool isAutoSaveEnabled = false,
    Widget? customContent,
  }) async {
    // Use bottom sheet on mobile for better UX
    if (_isMobile()) {
      return await showModalBottomSheet<SaveConfirmationResult>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _MobileSaveConfirmationSheet(
          workspaceName: workspaceName,
          workspacePath: workspacePath,
          timeSinceLastSave: timeSinceLastSave,
          onSave: onSave,
          onDiscard: onDiscard,
          onCancel: onCancel,
          isAutoSaveEnabled: isAutoSaveEnabled,
          customContent: customContent,
        ),
      );
    } else {
      // Use dialog on desktop
      return await showDialog<SaveConfirmationResult>(
        context: context,
        barrierDismissible: false,
        builder: (context) => SaveConfirmationDialog(
          workspaceName: workspaceName,
          workspacePath: workspacePath,
          timeSinceLastSave: timeSinceLastSave,
          onSave: onSave,
          onDiscard: onDiscard,
          onCancel: onCancel,
          isAutoSaveEnabled: isAutoSaveEnabled,
          customContent: customContent,
        ),
      );
    }
  }

  static bool _isMobile() {
    return !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return AlertDialog(
      icon: Icon(
        Icons.warning_amber_rounded,
        color: colorScheme.onSurfaceVariant,
        size: 32,
      ),
      title: Text(
        'Unsaved Changes',
        style: theme.textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWorkspaceInfo(theme, colorScheme),
            const SizedBox(height: 16),
            if (customContent != null) ...[
              customContent!,
              const SizedBox(height: 16),
            ],
            _buildTimeInfo(theme, colorScheme),
            if (isAutoSaveEnabled) ...[
              const SizedBox(height: 12),
              _buildAutoSaveInfo(theme, colorScheme),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(SaveConfirmationResult.cancel);
            onCancel?.call();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(SaveConfirmationResult.discard);
            onDiscard?.call();
          },
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.error,
          ),
          child: const Text('Discard Changes'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(SaveConfirmationResult.save);
            onSave?.call();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildWorkspaceInfo(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'The workspace "$workspaceName" has unsaved changes.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        if (workspacePath != null) ...[
          const SizedBox(height: 8),
          Text(
            'Location: ${_truncatePath(workspacePath!, 50)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              fontFamily: 'monospace',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimeInfo(ThemeData theme, ColorScheme colorScheme) {
    if (timeSinceLastSave == null) {
      return Text(
        'This workspace has never been saved.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final timeText = _formatDuration(timeSinceLastSave!);
    return Row(
      children: [
        Icon(
          Icons.schedule,
          size: 16,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 4),
        Text(
          'Last saved $timeText ago',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildAutoSaveInfo(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Auto-save is enabled. Your changes will be automatically saved.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _truncatePath(String path, int maxLength) {
    if (path.length <= maxLength) return path;
    return '...${path.substring(path.length - maxLength + 3)}';
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'a few seconds';
    }
  }
}

class _MobileSaveConfirmationSheet extends StatelessWidget {
  final String workspaceName;
  final String? workspacePath;
  final Duration? timeSinceLastSave;
  final VoidCallback? onSave;
  final VoidCallback? onDiscard;
  final VoidCallback? onCancel;
  final bool isAutoSaveEnabled;
  final Widget? customContent;

  const _MobileSaveConfirmationSheet({
    required this.workspaceName,
    this.workspacePath,
    this.timeSinceLastSave,
    this.onSave,
    this.onDiscard,
    this.onCancel,
    this.isAutoSaveEnabled = false,
    this.customContent,
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
              
              // Icon and title
              Icon(
                Icons.warning_amber_rounded,
                color: colorScheme.onSurfaceVariant,
                size: 40,
              ),
              const SizedBox(height: 16),
              Text(
                'Unsaved Changes',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              // Content
              _buildMobileContent(theme, colorScheme),
              
              const SizedBox(height: 32),
              
              // Action buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop(SaveConfirmationResult.save);
                        onSave?.call();
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Save Changes'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop(SaveConfirmationResult.discard);
                        onDiscard?.call();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: colorScheme.error,
                        side: BorderSide(color: colorScheme.error),
                      ),
                      child: const Text('Discard Changes'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(SaveConfirmationResult.cancel);
                      onCancel?.call();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileContent(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'The workspace "$workspaceName" has unsaved changes.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        
        if (workspacePath != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              workspacePath!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        
        if (timeSinceLastSave != null) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.schedule,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Last saved ${_formatDuration(timeSinceLastSave!)} ago',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
        
        if (customContent != null) ...[
          const SizedBox(height: 16),
          customContent!,
        ],
        
        if (isAutoSaveEnabled) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Auto-save is enabled. Your changes will be automatically saved.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'a few seconds';
    }
  }
}

/// Convenience method to show save confirmation with workspace state
class WorkspaceSaveConfirmationDialog {
  static Future<SaveConfirmationResult?> showFromState({
    required BuildContext context,
    WorkspaceStateManager? stateManager,
    VoidCallback? onSave,
    VoidCallback? onDiscard,
    VoidCallback? onCancel,
    Widget? customContent,
  }) async {
    final manager = stateManager ?? WorkspaceStateManager.instance;
    final summary = manager.getModificationSummary();
    
    return await SaveConfirmationDialog.show(
      context: context,
      workspaceName: summary.workspaceName ?? 'Untitled Workspace',
      workspacePath: summary.workspacePath,
      timeSinceLastSave: summary.timeSinceLastSave,
      onSave: onSave,
      onDiscard: onDiscard,
      onCancel: onCancel,
      isAutoSaveEnabled: manager.isAutoSaveEnabled,
      customContent: customContent,
    );
  }
}

/// Result of save confirmation dialog
enum SaveConfirmationResult {
  save,
  discard,
  cancel,
}

/// Extension for easier handling of save confirmation results
extension SaveConfirmationResultExtension on SaveConfirmationResult {
  bool get shouldSave => this == SaveConfirmationResult.save;
  bool get shouldDiscard => this == SaveConfirmationResult.discard;
  bool get shouldCancel => this == SaveConfirmationResult.cancel;
  bool get shouldProceed => this == SaveConfirmationResult.save || this == SaveConfirmationResult.discard;
}