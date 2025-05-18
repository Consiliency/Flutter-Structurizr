import 'dart:async';

import 'package:flutter/material.dart' hide Element, Container, View, Border;
import 'package:flutter/material.dart' as flutter;
import 'package:flutter_structurizr/application/workspace/workspace_manager_with_history.dart';

/// A widget that displays the command history for a workspace and provides undo/redo controls.
class WorkspaceHistoryPanel extends StatefulWidget {
  /// The workspace path
  final String workspacePath;

  /// The workspace manager with history support
  final WorkspaceManagerWithHistory workspaceManager;

  /// Whether to use a dark theme
  final bool isDarkMode;

  /// Creates a new WorkspaceHistoryPanel widget.
  const WorkspaceHistoryPanel({
    Key? key,
    required this.workspacePath,
    required this.workspaceManager,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  State<WorkspaceHistoryPanel> createState() => _WorkspaceHistoryPanelState();
}

class _WorkspaceHistoryPanelState extends State<WorkspaceHistoryPanel> {
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
    final textTheme = theme.textTheme;

    // Theme-dependent colors
    final backgroundColor =
        widget.isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF5F5F5);
    final headerColor =
        widget.isDarkMode ? const Color(0xFF3D3D3D) : const Color(0xFFE5E5E5);
    final textColor = widget.isDarkMode ? Colors.white : Colors.black87;
    final disabledColor = widget.isDarkMode ? Colors.white38 : Colors.black38;
    final highlightColor = widget.isDarkMode ? Colors.blueAccent : Colors.blue;

    final undoDescriptions =
        widget.workspaceManager.undoDescriptions(widget.workspacePath);
    final redoDescriptions =
        widget.workspaceManager.redoDescriptions(widget.workspacePath);
    final canUndo = widget.workspaceManager.canUndo(widget.workspacePath);
    final canRedo = widget.workspaceManager.canRedo(widget.workspacePath);

    return Material(
      color: backgroundColor,
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with title and undo/redo buttons
          flutter.Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: headerColor,
            child: Row(
              children: [
                Text(
                  'Command History',
                  style: textTheme.titleMedium?.copyWith(color: textColor),
                ),
                const Spacer(),
                // Undo button
                IconButton(
                  icon: const Icon(Icons.undo),
                  tooltip: widget.workspaceManager
                              .undoDescription(widget.workspacePath) !=
                          null
                      ? 'Undo: ${widget.workspaceManager.undoDescription(widget.workspacePath)}'
                      : 'Undo',
                  color: canUndo ? textColor : disabledColor,
                  onPressed: canUndo
                      ? () {
                          widget.workspaceManager.undo(widget.workspacePath);
                        }
                      : null,
                ),
                // Redo button
                IconButton(
                  icon: const Icon(Icons.redo),
                  tooltip: widget.workspaceManager
                              .redoDescription(widget.workspacePath) !=
                          null
                      ? 'Redo: ${widget.workspaceManager.redoDescription(widget.workspacePath)}'
                      : 'Redo',
                  color: canRedo ? textColor : disabledColor,
                  onPressed: canRedo
                      ? () {
                          widget.workspaceManager.redo(widget.workspacePath);
                        }
                      : null,
                ),
                // Clear history button
                IconButton(
                  icon: const Icon(Icons.clear_all),
                  tooltip: 'Clear History',
                  color: textColor,
                  onPressed:
                      undoDescriptions.isNotEmpty || redoDescriptions.isNotEmpty
                          ? () {
                              _showClearHistoryDialog(context);
                            }
                          : null,
                ),
              ],
            ),
          ),

          // History list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Undo stack section
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    'Undo Stack',
                    style: textTheme.titleSmall?.copyWith(color: textColor),
                  ),
                ),
                if (undoDescriptions.isEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'No actions to undo',
                      style:
                          textTheme.bodyMedium?.copyWith(color: disabledColor),
                    ),
                  )
                else
                  ...undoDescriptions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final description = entry.value;
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 12,
                        backgroundColor:
                            index == 0 ? highlightColor : headerColor,
                        child: Text(
                          (undoDescriptions.length - index).toString(),
                          style: TextStyle(
                            color: index == 0 ? Colors.white : textColor,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      title: Text(
                        description,
                        style: textTheme.bodyMedium?.copyWith(
                          color: textColor,
                          fontWeight:
                              index == 0 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        // Undo up to this command
                        for (int i = 0; i <= index; i++) {
                          widget.workspaceManager.undo(widget.workspacePath);
                        }
                      },
                    );
                  }),

                const Divider(),

                // Redo stack section
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    'Redo Stack',
                    style: textTheme.titleSmall?.copyWith(color: textColor),
                  ),
                ),
                if (redoDescriptions.isEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'No actions to redo',
                      style:
                          textTheme.bodyMedium?.copyWith(color: disabledColor),
                    ),
                  )
                else
                  ...redoDescriptions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final description = entry.value;
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 12,
                        backgroundColor:
                            index == 0 ? highlightColor : headerColor,
                        child: Text(
                          (index + 1).toString(),
                          style: TextStyle(
                            color: index == 0 ? Colors.white : textColor,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      title: Text(
                        description,
                        style: textTheme.bodyMedium?.copyWith(
                          color: textColor,
                          fontWeight:
                              index == 0 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        // Redo up to this command
                        for (int i = 0; i <= index; i++) {
                          widget.workspaceManager.redo(widget.workspacePath);
                        }
                      },
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
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
}
