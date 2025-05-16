import 'package:flutter/material.dart';

/// A dialog that displays available keyboard shortcuts for documentation navigation.
class KeyboardShortcutsHelp extends StatelessWidget {
  /// Whether to use dark mode.
  final bool isDarkMode;

  /// Creates a new keyboard shortcuts help dialog.
  const KeyboardShortcutsHelp({
    Key? key,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color backgroundColor = isDarkMode ? Colors.grey.shade900 : Colors.white;
    final Color dividerColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300;

    return Dialog(
      backgroundColor: backgroundColor,
      child: Container(
        padding: const EdgeInsets.all(24.0),
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Keyboard Shortcuts',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: dividerColor),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShortcutSection(
                      'Navigation',
                      [
                        _ShortcutItem('↑', 'Previous section/decision'),
                        _ShortcutItem('↓', 'Next section/decision'),
                        _ShortcutItem('Alt + ←', 'Back in history'),
                        _ShortcutItem('Alt + →', 'Forward in history'),
                        _ShortcutItem('Home', 'Go to first section/decision'),
                        _ShortcutItem('End', 'Go to last section/decision'),
                        _ShortcutItem('Alt + 1-9', 'Go to specific section/decision by index'),
                      ],
                      textColor: textColor,
                      dividerColor: dividerColor,
                    ),
                    _buildShortcutSection(
                      'View Controls',
                      [
                        _ShortcutItem('Ctrl + D', 'Toggle between documentation and decisions'),
                        _ShortcutItem('Ctrl + G', 'Show decision graph'),
                        _ShortcutItem('Ctrl + T', 'Show decision timeline'),
                        _ShortcutItem('Ctrl + S', 'Show search'),
                        _ShortcutItem('Ctrl + F', 'Toggle fullscreen content view'),
                        _ShortcutItem('Ctrl + ?', 'Show this help dialog'),
                      ],
                      textColor: textColor,
                      dividerColor: dividerColor,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: dividerColor),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Close',
                  style: TextStyle(
                    color: isDarkMode ? Colors.blue.shade300 : Colors.blue,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutSection(
    String title,
    List<_ShortcutItem> shortcuts,
    {required Color textColor, required Color dividerColor}
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        ...shortcuts.map((shortcut) => _buildShortcutRow(shortcut, textColor)),
        const SizedBox(height: 16),
        Divider(color: dividerColor),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildShortcutRow(_ShortcutItem shortcut, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4.0),
              border: Border.all(
                color: textColor.withOpacity(0.3),
              ),
            ),
            child: Text(
              shortcut.key,
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              shortcut.description,
              style: TextStyle(color: textColor),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutItem {
  final String key;
  final String description;

  _ShortcutItem(this.key, this.description);
}