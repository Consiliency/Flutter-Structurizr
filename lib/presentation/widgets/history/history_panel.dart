import 'package:flutter/material.dart' hide Element, Container, View, Border;
import 'package:flutter_structurizr/application/command/history_manager.dart';

/// A widget that displays the command history and provides undo/redo controls.
class HistoryPanel extends StatefulWidget {
  /// The history manager to display
  final HistoryManager historyManager;
  
  /// Whether to use a dark theme
  final bool isDarkMode;
  
  /// Creates a new HistoryPanel widget.
  const HistoryPanel({
    Key? key,
    required this.historyManager,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  State<HistoryPanel> createState() => _HistoryPanelState();
}

class _HistoryPanelState extends State<HistoryPanel> {
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
    final textTheme = theme.textTheme;
    
    // Theme-dependent colors
    final backgroundColor = widget.isDarkMode 
        ? const Color(0xFF2D2D2D) 
        : const Color(0xFFF5F5F5);
    final headerColor = widget.isDarkMode 
        ? const Color(0xFF3D3D3D) 
        : const Color(0xFFE5E5E5);
    final textColor = widget.isDarkMode 
        ? Colors.white 
        : Colors.black87;
    final disabledColor = widget.isDarkMode 
        ? Colors.white38 
        : Colors.black38;
    final highlightColor = widget.isDarkMode 
        ? Colors.blueAccent 
        : Colors.blue;
    
    return Material(
      color: backgroundColor,
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with title and undo/redo buttons
          Container(
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
                  tooltip: widget.historyManager.undoDescription != null
                      ? 'Undo: ${widget.historyManager.undoDescription}'
                      : 'Undo',
                  color: widget.historyManager.canUndo
                      ? textColor
                      : disabledColor,
                  onPressed: widget.historyManager.canUndo
                      ? () {
                          widget.historyManager.undo();
                        }
                      : null,
                ),
                // Redo button
                IconButton(
                  icon: const Icon(Icons.redo),
                  tooltip: widget.historyManager.redoDescription != null
                      ? 'Redo: ${widget.historyManager.redoDescription}'
                      : 'Redo',
                  color: widget.historyManager.canRedo
                      ? textColor
                      : disabledColor,
                  onPressed: widget.historyManager.canRedo
                      ? () {
                          widget.historyManager.redo();
                        }
                      : null,
                ),
                // Clear history button
                IconButton(
                  icon: const Icon(Icons.clear_all),
                  tooltip: 'Clear History',
                  color: textColor,
                  onPressed: () {
                    widget.historyManager.clearHistory();
                  },
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    'Undo Stack',
                    style: textTheme.titleSmall?.copyWith(color: textColor),
                  ),
                ),
                if (widget.historyManager.undoDescriptions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'No actions to undo',
                      style: textTheme.bodyMedium?.copyWith(color: disabledColor),
                    ),
                  )
                else
                  ...widget.historyManager.undoDescriptions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final description = entry.value;
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 12,
                        backgroundColor: index == 0 ? highlightColor : headerColor,
                        child: Text(
                          (widget.historyManager.undoDescriptions.length - index).toString(),
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
                          fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        // Undo up to this command
                        for (int i = 0; i <= index; i++) {
                          widget.historyManager.undo();
                        }
                      },
                    );
                  }),
                
                const Divider(),
                
                // Redo stack section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    'Redo Stack',
                    style: textTheme.titleSmall?.copyWith(color: textColor),
                  ),
                ),
                if (widget.historyManager.redoDescriptions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'No actions to redo',
                      style: textTheme.bodyMedium?.copyWith(color: disabledColor),
                    ),
                  )
                else
                  ...widget.historyManager.redoDescriptions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final description = entry.value;
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 12,
                        backgroundColor: index == 0 ? highlightColor : headerColor,
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
                          fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        // Redo up to this command
                        for (int i = 0; i <= index; i++) {
                          widget.historyManager.redo();
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
}