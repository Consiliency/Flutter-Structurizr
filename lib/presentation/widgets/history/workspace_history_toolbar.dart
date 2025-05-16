import 'package:flutter/material.dart' hide Element, Container, View, Border;
import 'package:flutter/services.dart';
import 'package:flutter_structurizr/application/workspace/workspace_manager_with_history.dart';

/// A toolbar widget that provides undo/redo controls for a workspace.
class WorkspaceHistoryToolbar extends StatefulWidget {
  /// The workspace path
  final String workspacePath;
  
  /// The workspace manager with history support
  final WorkspaceManagerWithHistory workspaceManager;
  
  /// Whether to show text labels next to icons
  final bool showLabels;
  
  /// Whether to use a dark theme
  final bool isDarkMode;
  
  /// Creates a new WorkspaceHistoryToolbar widget.
  const WorkspaceHistoryToolbar({
    Key? key,
    required this.workspacePath,
    required this.workspaceManager,
    this.showLabels = false,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  State<WorkspaceHistoryToolbar> createState() => _WorkspaceHistoryToolbarState();
}

class _WorkspaceHistoryToolbarState extends State<WorkspaceHistoryToolbar> {
  late final StreamSubscription<HistoryEvent> _subscription;
  
  @override
  void initState() {
    super.initState();
    
    // Listen for history events related to this workspace
    _subscription = widget.workspaceManager.historyEvents.listen((event) {
      if (event.path == widget.workspacePath && mounted) {
        setState(() {});
      }
    });
  }
  
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Theme-dependent colors
    final textColor = widget.isDarkMode ? Colors.white : Colors.black87;
    final disabledColor = widget.isDarkMode ? Colors.white38 : Colors.black38;
    
    final canUndo = widget.workspaceManager.canUndo(widget.workspacePath);
    final canRedo = widget.workspaceManager.canRedo(widget.workspacePath);
    final undoDescription = widget.workspaceManager.undoDescription(widget.workspacePath);
    final redoDescription = widget.workspaceManager.redoDescription(widget.workspacePath);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Undo button
        Tooltip(
          message: undoDescription != null
              ? 'Undo: $undoDescription (Ctrl+Z)'
              : 'Undo (Ctrl+Z)',
          child: InkWell(
            onTap: canUndo
                ? () {
                    widget.workspaceManager.undo(widget.workspacePath);
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.undo,
                    size: 20,
                    color: canUndo
                        ? textColor
                        : disabledColor,
                  ),
                  if (widget.showLabels)
                    const SizedBox(width: 4),
                  if (widget.showLabels)
                    Text(
                      'Undo',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: canUndo
                            ? textColor
                            : disabledColor,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        
        // Redo button
        Tooltip(
          message: redoDescription != null
              ? 'Redo: $redoDescription (Ctrl+Y)'
              : 'Redo (Ctrl+Y)',
          child: InkWell(
            onTap: canRedo
                ? () {
                    widget.workspaceManager.redo(widget.workspacePath);
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.redo,
                    size: 20,
                    color: canRedo
                        ? textColor
                        : disabledColor,
                  ),
                  if (widget.showLabels)
                    const SizedBox(width: 4),
                  if (widget.showLabels)
                    Text(
                      'Redo',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: canRedo
                            ? textColor
                            : disabledColor,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        
        // History menu button
        PopupMenuButton<String>(
          icon: Icon(
            Icons.history,
            size: 20,
            color: textColor,
          ),
          tooltip: 'History',
          itemBuilder: (context) {
            final undoDescriptions = widget.workspaceManager.undoDescriptions(widget.workspacePath);
            final redoDescriptions = widget.workspaceManager.redoDescriptions(widget.workspacePath);
            
            return [
              // Undo section
              if (undoDescriptions.isNotEmpty)
                PopupMenuItem<String>(
                  enabled: false,
                  child: Text(
                    'Undo History',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              
              // Undo items
              for (int i = 0; i < undoDescriptions.length; i++)
                PopupMenuItem<String>(
                  value: 'undo:$i',
                  child: Text(
                    undoDescriptions[i],
                    style: i == 0
                        ? const TextStyle(fontWeight: FontWeight.bold)
                        : null,
                  ),
                ),
              
              // Divider if both sections have items
              if (undoDescriptions.isNotEmpty && redoDescriptions.isNotEmpty)
                const PopupMenuDivider(),
              
              // Redo section
              if (redoDescriptions.isNotEmpty)
                PopupMenuItem<String>(
                  enabled: false,
                  child: Text(
                    'Redo History',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
              
              // Redo items
              for (int i = 0; i < redoDescriptions.length; i++)
                PopupMenuItem<String>(
                  value: 'redo:$i',
                  child: Text(
                    redoDescriptions[i],
                    style: i == 0
                        ? const TextStyle(fontWeight: FontWeight.bold)
                        : null,
                  ),
                ),
              
              // Divider before clear option
              if (undoDescriptions.isNotEmpty || redoDescriptions.isNotEmpty)
                const PopupMenuDivider(),
              
              // Clear history option
              if (undoDescriptions.isNotEmpty || redoDescriptions.isNotEmpty)
                PopupMenuItem<String>(
                  value: 'clear',
                  child: Text(
                    'Clear History',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
            ];
          },
          onSelected: (value) {
            if (value == 'clear') {
              _showClearHistoryDialog(context);
            } else if (value.startsWith('undo:')) {
              final index = int.parse(value.split(':')[1]);
              _undoToIndex(index);
            } else if (value.startsWith('redo:')) {
              final index = int.parse(value.split(':')[1]);
              _redoToIndex(index);
            }
          },
        ),
      ],
    );
  }
  
  /// Shows a dialog to confirm clearing the history.
  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History?'),
        content: const Text(
          'This will clear all undo and redo history for this workspace. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.workspaceManager.clearHistory(widget.workspacePath);
              Navigator.of(context).pop();
            },
            child: Text(
              'Clear',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Undoes commands up to the specified index.
  void _undoToIndex(int index) {
    // Undo the specified number of commands
    for (int i = 0; i <= index; i++) {
      if (!widget.workspaceManager.canUndo(widget.workspacePath)) break;
      widget.workspaceManager.undo(widget.workspacePath);
    }
  }
  
  /// Redoes commands up to the specified index.
  void _redoToIndex(int index) {
    // Redo the specified number of commands
    for (int i = 0; i <= index; i++) {
      if (!widget.workspaceManager.canRedo(widget.workspacePath)) break;
      widget.workspaceManager.redo(widget.workspacePath);
    }
  }
}

/// A widget that adds keyboard shortcuts for undo/redo with a workspace.
class WorkspaceHistoryKeyboardShortcuts extends StatelessWidget {
  /// The workspace path
  final String workspacePath;
  
  /// The workspace manager with history support
  final WorkspaceManagerWithHistory workspaceManager;
  
  /// The child widget
  final Widget child;
  
  /// Creates a new WorkspaceHistoryKeyboardShortcuts widget.
  const WorkspaceHistoryKeyboardShortcuts({
    Key? key,
    required this.workspacePath,
    required this.workspaceManager,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(skipTraversal: true),
      onKeyEvent: (keyEvent) {
        if (keyEvent is KeyDownEvent) {
          // Check for Ctrl+Z (Undo)
          if (keyEvent.logicalKey == LogicalKeyboardKey.keyZ && 
              keyEvent.isControlPressed) {
            if (workspaceManager.canUndo(workspacePath)) {
              workspaceManager.undo(workspacePath);
            }
          }
          
          // Check for Ctrl+Y (Redo)
          else if (keyEvent.logicalKey == LogicalKeyboardKey.keyY && 
                   keyEvent.isControlPressed) {
            if (workspaceManager.canRedo(workspacePath)) {
              workspaceManager.redo(workspacePath);
            }
          }

          // Check for Ctrl+Shift+Z (Redo - alternative)
          else if (keyEvent.logicalKey == LogicalKeyboardKey.keyZ && 
                   keyEvent.isControlPressed && 
                   keyEvent.isShiftPressed) {
            if (workspaceManager.canRedo(workspacePath)) {
              workspaceManager.redo(workspacePath);
            }
          }
        }
      },
      child: child,
    );
  }
}