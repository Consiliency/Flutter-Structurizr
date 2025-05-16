import 'package:flutter/material.dart';
import 'package:flutter_structurizr/domain/documentation/documentation.dart';

/// A widget that displays a table of contents for documentation.
class TableOfContents extends StatefulWidget {
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
  State<TableOfContents> createState() => _TableOfContentsState();
}

class _TableOfContentsState extends State<TableOfContents> {
  /// Tracks which sections are expanded
  final Map<int, bool> _expandedSections = {};
  
  @override
  void initState() {
    super.initState();
    // Initialize all root sections as expanded
    for (int i = 0; i < widget.sections.length; i++) {
      _expandedSections[i] = true;
    }
  }
  
  /// Toggle the expanded state of a section
  void _toggleSection(int index) {
    setState(() {
      _expandedSections[index] = !(_expandedSections[index] ?? false);
    });
  }
  
  /// Compute the parent-child relationships between sections based on title structure
  /// Returns a map of parent indices to lists of child indices
  Map<int, List<int>> _computeSectionHierarchy() {
    final Map<int, List<int>> hierarchy = {};
    final List<int> sectionLevels = [];
    
    // Determine section levels based on title prefixes (e.g., "1.", "1.1.", etc.)
    for (var section in widget.sections) {
      final parts = section.title.split('.');
      sectionLevels.add(parts.length);
    }
    
    // Build parent-child relationships
    for (int i = 0; i < widget.sections.length; i++) {
      final currentLevel = sectionLevels[i];
      
      // Find potential parents (sections that come before this one with lower level)
      int parentIndex = -1;
      for (int j = i - 1; j >= 0; j--) {
        if (sectionLevels[j] < currentLevel) {
          parentIndex = j;
          break;
        }
      }
      
      if (parentIndex != -1) {
        hierarchy.putIfAbsent(parentIndex, () => []).add(i);
      }
    }
    
    return hierarchy;
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSections = widget.sections.isNotEmpty;
    final hasDecisions = widget.decisions.isNotEmpty;
    
    // Compute the section hierarchy for nested display
    final sectionHierarchy = _computeSectionHierarchy();
    
    // If there's neither sections nor decisions, show a message
    if (!hasSections && !hasDecisions) {
      return Center(
        child: Text(
          'No documentation available',
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white70 : Colors.black54,
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
                  color: widget.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                ),
              ),
              color: widget.isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: widget.viewingDecisions ? widget.onToggleView : null,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: !widget.viewingDecisions 
                                ? (widget.isDarkMode ? Colors.blue.shade300 : Colors.blue)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        color: !widget.viewingDecisions
                            ? (widget.isDarkMode ? Colors.blue.withOpacity(0.1) : Colors.blue.withOpacity(0.05))
                            : Colors.transparent,
                      ),
                      child: Text(
                        'Documentation',
                        style: TextStyle(
                          color: !widget.viewingDecisions
                              ? (widget.isDarkMode ? Colors.blue.shade300 : Colors.blue)
                              : (widget.isDarkMode ? Colors.white70 : Colors.black54),
                          fontWeight: !widget.viewingDecisions
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: !widget.viewingDecisions ? widget.onToggleView : null,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: widget.viewingDecisions 
                                ? (widget.isDarkMode ? Colors.blue.shade300 : Colors.blue)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        color: widget.viewingDecisions
                            ? (widget.isDarkMode ? Colors.blue.withOpacity(0.1) : Colors.blue.withOpacity(0.05))
                            : Colors.transparent,
                      ),
                      child: Text(
                        'Decisions',
                        style: TextStyle(
                          color: widget.viewingDecisions
                              ? (widget.isDarkMode ? Colors.blue.shade300 : Colors.blue)
                              : (widget.isDarkMode ? Colors.white70 : Colors.black54),
                          fontWeight: widget.viewingDecisions
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
                  color: widget.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                ),
              ),
              color: widget.isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
            ),
            child: Text(
              hasSections ? 'Documentation' : 'Decisions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
          
        // Main scrollable content list
        Expanded(
          child: Container(
            color: widget.isDarkMode ? Colors.grey.shade900.withOpacity(0.7) : Colors.grey.shade50,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: widget.viewingDecisions
                    ? _buildDecisionsList(theme)
                    : _buildSectionsList(theme, sectionHierarchy),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a list of documentation sections with collapsible hierarchy.
  List<Widget> _buildSectionsList(ThemeData theme, Map<int, List<int>> hierarchy) {
    if (widget.sections.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No documentation sections available',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white70 : Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ];
    }

    // Build list with root sections first
    List<Widget> result = [];
    List<bool> isChildSection = List.filled(widget.sections.length, false);
    
    // Mark all children as non-root
    hierarchy.forEach((parentIndex, children) {
      for (final childIndex in children) {
        isChildSection[childIndex] = true;
      }
    });
    
    // Add root sections first
    for (int i = 0; i < widget.sections.length; i++) {
      if (!isChildSection[i]) {
        result.addAll(_buildSectionWithChildren(i, 0, theme, hierarchy));
      }
    }
    
    return result;
  }
  
  /// Recursively builds a section and its children with proper indentation
  List<Widget> _buildSectionWithChildren(
    int sectionIndex, 
    int depth, 
    ThemeData theme, 
    Map<int, List<int>> hierarchy
  ) {
    final section = widget.sections[sectionIndex];
    final isSelected = sectionIndex == widget.currentSectionIndex && !widget.viewingDecisions;
    final hasChildren = hierarchy.containsKey(sectionIndex) && hierarchy[sectionIndex]!.isNotEmpty;
    final isExpanded = _expandedSections[sectionIndex] ?? false;
    
    List<Widget> result = [];
    
    // Add this section
    result.add(
      Padding(
        padding: EdgeInsets.only(left: depth * 16.0),
        child: ListTile(
          leading: hasChildren
            ? InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _toggleSection(sectionIndex),
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  child: Icon(
                    isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                    size: 16,
                    color: widget.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                ),
              )
            : SizedBox(width: 24),
          title: Text(
            section.title,
            style: TextStyle(
              color: isSelected
                  ? (widget.isDarkMode ? Colors.blue.shade300 : theme.primaryColor)
                  : (widget.isDarkMode ? Colors.white : Colors.black87),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: section.elementId != null
              ? Text(
                  'Related to: ${section.elementId}',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                )
              : null,
          tileColor: isSelected
              ? (widget.isDarkMode ? Colors.blue.withOpacity(0.1) : theme.primaryColor.withOpacity(0.05))
              : Colors.transparent,
          onTap: () => widget.onSectionSelected(sectionIndex),
          selected: isSelected,
          dense: true,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
    
    // Add children if expanded
    if (hasChildren && isExpanded) {
      for (final childIndex in hierarchy[sectionIndex]!) {
        result.addAll(_buildSectionWithChildren(childIndex, depth + 1, theme, hierarchy));
      }
    }
    
    return result;
  }

  List<Widget> _buildDecisionsList(ThemeData theme) {
    if (widget.decisions.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No architecture decisions available',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white70 : Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ];
    }

    return widget.decisions.asMap().entries.map((entry) {
      final index = entry.key;
      final decision = entry.value;
      final isSelected = index == widget.currentDecisionIndex && widget.viewingDecisions;

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
                ? (widget.isDarkMode ? Colors.blue.shade300 : theme.primaryColor)
                : (widget.isDarkMode ? Colors.white : Colors.black87),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          '${decision.id} • ${_formatDate(decision.date)}',
          style: TextStyle(
            fontSize: 12,
            color: widget.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
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
            ? (widget.isDarkMode ? Colors.blue.withOpacity(0.1) : theme.primaryColor.withOpacity(0.05))
            : Colors.transparent,
        onTap: () => widget.onDecisionSelected(index),
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