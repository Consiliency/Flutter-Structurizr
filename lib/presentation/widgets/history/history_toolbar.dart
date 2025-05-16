import 'package:flutter/material.dart' hide Element, Container, View, Border;
import 'package:flutter/services.dart';
import 'package:flutter_structurizr/application/command/history_manager.dart';

/// A toolbar widget that provides undo/redo controls.
class HistoryToolbar extends StatefulWidget {
  /// The history manager to control
  final HistoryManager historyManager;
  
  /// Whether to show text labels next to icons
  final bool showLabels;
  
  /// Whether to use a dark theme
  final bool isDarkMode;
  
  /// Creates a new HistoryToolbar widget.
  const HistoryToolbar({
    Key? key,
    required this.historyManager,
    this.showLabels = false,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  State<HistoryToolbar> createState() => _HistoryToolbarState();
}

class _HistoryToolbarState extends State<HistoryToolbar> {
  @override
  void initState() {
    super.initState();
    
    // Listen for history changes
    widget.historyManager.historyChanges.listen((_) {
      if (mounted) setState(() {});
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Theme-dependent colors
    final textColor = widget.isDarkMode ? Colors.white : Colors.black87;
    final disabledColor = widget.isDarkMode ? Colors.white38 : Colors.black38;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Undo button
        Tooltip(
          message: widget.historyManager.undoDescription != null
              ? 'Undo: ${widget.historyManager.undoDescription} (Ctrl+Z)'
              : 'Undo (Ctrl+Z)',
          child: InkWell(
            onTap: widget.historyManager.canUndo
                ? () {
                    widget.historyManager.undo();
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
                    color: widget.historyManager.canUndo
                        ? textColor
                        : disabledColor,
                  ),
                  if (widget.showLabels)
                    const SizedBox(width: 4),
                  if (widget.showLabels)
                    Text(
                      'Undo',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: widget.historyManager.canUndo
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
          message: widget.historyManager.redoDescription != null
              ? 'Redo: ${widget.historyManager.redoDescription} (Ctrl+Y)'
              : 'Redo (Ctrl+Y)',
          child: InkWell(
            onTap: widget.historyManager.canRedo
                ? () {
                    widget.historyManager.redo();
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
                    color: widget.historyManager.canRedo
                        ? textColor
                        : disabledColor,
                  ),
                  if (widget.showLabels)
                    const SizedBox(width: 4),
                  if (widget.showLabels)
                    Text(
                      'Redo',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: widget.historyManager.canRedo
                            ? textColor
                            : disabledColor,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A widget that adds keyboard shortcuts for undo/redo.
/// 
/// This widget captures Ctrl+Z and Ctrl+Y keyboard shortcuts and
/// triggers undo/redo operations on the provided history manager.
class HistoryKeyboardShortcuts extends StatelessWidget {
  /// The history manager to control
  final HistoryManager historyManager;
  
  /// The child widget
  final Widget child;
  
  /// Creates a new HistoryKeyboardShortcuts widget.
  const HistoryKeyboardShortcuts({
    Key? key,
    required this.historyManager,
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
            if (historyManager.canUndo) {
              historyManager.undo();
            }
          }
          
          // Check for Ctrl+Y (Redo)
          else if (keyEvent.logicalKey == LogicalKeyboardKey.keyY && 
                   keyEvent.isControlPressed) {
            if (historyManager.canRedo) {
              historyManager.redo();
            }
          }

          // Check for Ctrl+Shift+Z (Redo - alternative)
          else if (keyEvent.logicalKey == LogicalKeyboardKey.keyZ && 
                   keyEvent.isControlPressed && 
                   keyEvent.isShiftPressed) {
            if (historyManager.canRedo) {
              historyManager.redo();
            }
          }
        }
      },
      child: child,
    );
  }
}