import 'package:flutter/material.dart';
import 'package:flutter_structurizr/domain/documentation/documentation.dart';

/// A widget that displays a table of contents for documentation.
class TableOfContents extends StatelessWidget {
  /// The list of documentation sections.
  final List<DocumentationSection> sections;
  
  /// The list of architecture decision records.
  final List<Decision> decisions;
  
  /// The index of the currently selected section.
  final int currentSectionIndex;
  
  /// The index of the currently selected decision.
  final int currentDecisionIndex;
  
  /// Whether decisions or documentation is being viewed.
  final bool viewingDecisions;
  
  /// Called when a section is selected.
  final Function(int) onSectionSelected;
  
  /// Called when a decision is selected.
  final Function(int) onDecisionSelected;
  
  /// Called when toggling between documentation and decisions.
  final VoidCallback onToggleView;
  
  /// Whether to use dark mode.
  final bool isDarkMode;

  /// Creates a new table of contents widget.
  const TableOfContents({
    Key? key,
    required this.sections,
    required this.decisions,
    required this.currentSectionIndex,
    required this.currentDecisionIndex,
    required this.viewingDecisions,
    required this.onSectionSelected,
    required this.onDecisionSelected,
    required this.onToggleView,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSections = sections.isNotEmpty;
    final hasDecisions = decisions.isNotEmpty;
    
    // If there's neither sections nor decisions, show a message
    if (!hasSections && !hasDecisions) {
      return Center(
        child: Text(
          'No documentation available',
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black54,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tab bar to switch between Documentation and Decisions
        if (hasSections && hasDecisions)
          Container(
            height: 48,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                ),
              ),
              color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: viewingDecisions ? onToggleView : null,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: !viewingDecisions 
                                ? (isDarkMode ? Colors.blue.shade300 : Colors.blue)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        color: !viewingDecisions
                            ? (isDarkMode ? Colors.blue.withOpacity(0.1) : Colors.blue.withOpacity(0.05))
                            : Colors.transparent,
                      ),
                      child: Text(
                        'Documentation',
                        style: TextStyle(
                          color: !viewingDecisions
                              ? (isDarkMode ? Colors.blue.shade300 : Colors.blue)
                              : (isDarkMode ? Colors.white70 : Colors.black54),
                          fontWeight: !viewingDecisions
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: !viewingDecisions ? onToggleView : null,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: viewingDecisions 
                                ? (isDarkMode ? Colors.blue.shade300 : Colors.blue)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        color: viewingDecisions
                            ? (isDarkMode ? Colors.blue.withOpacity(0.1) : Colors.blue.withOpacity(0.05))
                            : Colors.transparent,
                      ),
                      child: Text(
                        'Decisions',
                        style: TextStyle(
                          color: viewingDecisions
                              ? (isDarkMode ? Colors.blue.shade300 : Colors.blue)
                              : (isDarkMode ? Colors.white70 : Colors.black54),
                          fontWeight: viewingDecisions
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
        // Title for single content type (if only one is available)
        if (hasSections && !hasDecisions || !hasSections && hasDecisions)
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                ),
              ),
              color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
            ),
            child: Text(
              hasSections ? 'Documentation' : 'Decisions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
          
        // Main scrollable content list
        Expanded(
          child: Container(
            color: isDarkMode ? Colors.grey.shade900.withOpacity(0.7) : Colors.grey.shade50,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: viewingDecisions
                    ? _buildDecisionsList(theme)
                    : _buildSectionsList(theme),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSectionsList(ThemeData theme) {
    if (sections.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No documentation sections available',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ];
    }

    return sections.asMap().entries.map((entry) {
      final index = entry.key;
      final section = entry.value;
      final isSelected = index == currentSectionIndex && !viewingDecisions;
      
      return ListTile(
        title: Text(
          section.title,
          style: TextStyle(
            color: isSelected
                ? (isDarkMode ? Colors.blue.shade300 : theme.primaryColor)
                : (isDarkMode ? Colors.white : Colors.black87),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: section.elementId != null
            ? Text(
                'Related to: ${section.elementId}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              )
            : null,
        tileColor: isSelected
            ? (isDarkMode ? Colors.blue.withOpacity(0.1) : theme.primaryColor.withOpacity(0.05))
            : Colors.transparent,
        onTap: () => onSectionSelected(index),
        selected: isSelected,
        dense: true,
        visualDensity: VisualDensity.compact,
      );
    }).toList();
  }

  List<Widget> _buildDecisionsList(ThemeData theme) {
    if (decisions.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No architecture decisions available',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ];
    }

    return decisions.asMap().entries.map((entry) {
      final index = entry.key;
      final decision = entry.value;
      final isSelected = index == currentDecisionIndex && viewingDecisions;

      // Map common decision statuses to colors
      Color statusColor;
      switch (decision.status.toLowerCase()) {
        case 'proposed':
          statusColor = Colors.orange;
          break;
        case 'accepted':
          statusColor = Colors.green;
          break;
        case 'superseded':
          statusColor = Colors.purple;
          break;
        case 'deprecated':
          statusColor = Colors.red;
          break;
        case 'rejected':
          statusColor = Colors.red.shade900;
          break;
        default:
          statusColor = Colors.blue;
      }
      
      return ListTile(
        title: Text(
          decision.title,
          style: TextStyle(
            color: isSelected
                ? (isDarkMode ? Colors.blue.shade300 : theme.primaryColor)
                : (isDarkMode ? Colors.white : Colors.black87),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          '${decision.id} • ${_formatDate(decision.date)}',
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        leading: Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(left: 4.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: statusColor.withOpacity(0.7),
            border: Border.all(
              color: statusColor,
              width: 1.5,
            ),
          ),
        ),
        tileColor: isSelected
            ? (isDarkMode ? Colors.blue.withOpacity(0.1) : theme.primaryColor.withOpacity(0.05))
            : Colors.transparent,
        onTap: () => onDecisionSelected(index),
        selected: isSelected,
        dense: true,
        visualDensity: VisualDensity.compact,
      );
    }).toList();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}