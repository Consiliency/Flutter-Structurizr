import 'package:flutter/material.dart';
import 'package:flutter_structurizr/domain/documentation/documentation.dart';

/// A widget that displays a filterable list of architecture decisions.
class DecisionList extends StatefulWidget {
  /// The list of architecture decisions.
  final List<Decision> decisions;
  
  /// Called when a decision is selected.
  final Function(int) onDecisionSelected;
  
  /// Whether to use dark mode.
  final bool isDarkMode;

  /// Creates a new decision list widget.
  const DecisionList({
    Key? key,
    required this.decisions,
    required this.onDecisionSelected,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  State<DecisionList> createState() => _DecisionListState();
}

class _DecisionListState extends State<DecisionList> {
  late List<Decision> _sortedDecisions;
  List<String> _selectedStatuses = [];
  String _searchQuery = '';
  bool _sortByDateAscending = false;
  
  @override
  void initState() {
    super.initState();
    _sortedDecisions = List.from(widget.decisions);
    _sortDecisions();
  }
  
  @override
  void didUpdateWidget(DecisionList oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.decisions != widget.decisions) {
      _sortedDecisions = List.from(widget.decisions);
      _sortDecisions();
    }
  }
  
  /// Sorts decisions by date based on the current sort direction.
  void _sortDecisions() {
    _sortedDecisions.sort((a, b) {
      if (_sortByDateAscending) {
        return a.date.compareTo(b.date);
      } else {
        return b.date.compareTo(a.date);
      }
    });
  }
  
  /// Gets the filtered list of decisions.
  List<Decision> _getFilteredDecisions() {
    // Start with sorted decisions
    var filtered = List<Decision>.from(_sortedDecisions);
    
    // Apply status filter
    if (_selectedStatuses.isNotEmpty) {
      filtered = filtered.where((decision) => 
        _selectedStatuses.contains(decision.status)
      ).toList();
    }
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((decision) =>
        decision.id.toLowerCase().contains(query) ||
        decision.title.toLowerCase().contains(query) ||
        decision.content.toLowerCase().contains(query)
      ).toList();
    }
    
    return filtered;
  }
  
  /// Gets all unique statuses from the decisions.
  List<String> _getUniqueStatuses() {
    return widget.decisions
        .map((d) => d.status)
        .toSet()
        .toList();
  }
  
  /// Gets the status color for a decision.
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'proposed':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'superseded':
        return Colors.purple;
      case 'deprecated':
        return Colors.red;
      case 'rejected':
        return Colors.red.shade900;
      default:
        return Colors.blue;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final filteredDecisions = _getFilteredDecisions();
    final uniqueStatuses = _getUniqueStatuses();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: widget.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
            border: Border(
              bottom: BorderSide(
                color: widget.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
            ),
          ),
          child: Row(
            children: [
              Text(
                'Architecture Decisions',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              // Sort button
              IconButton(
                icon: Icon(
                  _sortByDateAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                ),
                tooltip: _sortByDateAscending 
                    ? 'Sort by date (oldest first)' 
                    : 'Sort by date (newest first)',
                color: widget.isDarkMode ? Colors.white : Colors.black87,
                onPressed: () {
                  setState(() {
                    _sortByDateAscending = !_sortByDateAscending;
                    _sortDecisions();
                  });
                },
              ),
              // Search field
              SizedBox(
                width: 200,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 8.0,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 18,
                      color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: BorderSide(
                        color: widget.isDarkMode 
                            ? Colors.grey.shade700 
                            : Colors.grey.shade300,
                      ),
                    ),
                    filled: true,
                    fillColor: widget.isDarkMode 
                        ? Colors.grey.shade700 
                        : Colors.white,
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.isDarkMode ? Colors.white : Colors.black87,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        
        // Status filter
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: widget.isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
            border: Border(
              bottom: BorderSide(
                color: widget.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
            ),
          ),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              Text(
                'Filter by status:',
                style: TextStyle(
                  fontSize: 12,
                  color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(width: 8),
              // All statuses option
              FilterChip(
                label: Text(
                  'All',
                  style: TextStyle(
                    fontSize: 12,
                    color: _selectedStatuses.isEmpty
                        ? (widget.isDarkMode ? Colors.white : Colors.black87)
                        : (widget.isDarkMode ? Colors.white70 : Colors.black54),
                  ),
                ),
                selected: _selectedStatuses.isEmpty,
                selectedColor: widget.isDarkMode 
                    ? Colors.blue.shade800 
                    : Colors.blue.shade100,
                backgroundColor: widget.isDarkMode 
                    ? Colors.grey.shade800 
                    : Colors.grey.shade100,
                onSelected: (selected) {
                  setState(() {
                    _selectedStatuses = [];
                  });
                },
              ),
              // Status filters
              ...uniqueStatuses.map((status) {
                final isSelected = _selectedStatuses.contains(status);
                final statusColor = _getStatusColor(status);
                
                return FilterChip(
                  label: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? (widget.isDarkMode ? Colors.white : Colors.black87)
                          : (widget.isDarkMode ? statusColor.withOpacity(0.8) : statusColor),
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: widget.isDarkMode 
                      ? statusColor.withOpacity(0.3) 
                      : statusColor.withOpacity(0.1),
                  backgroundColor: widget.isDarkMode 
                      ? Colors.grey.shade800 
                      : Colors.grey.shade100,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedStatuses.add(status);
                      } else {
                        _selectedStatuses.remove(status);
                      }
                    });
                  },
                );
              }),
            ],
          ),
        ),
        
        // Decision list
        Expanded(
          child: filteredDecisions.isEmpty
              ? Center(
                  child: Text(
                    'No decisions match the current filters',
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: filteredDecisions.length,
                  itemBuilder: (context, index) {
                    final decision = filteredDecisions[index];
                    final statusColor = _getStatusColor(decision.status);
                    
                    return InkWell(
                      onTap: () {
                        final originalIndex = widget.decisions.indexOf(decision);
                        widget.onDecisionSelected(originalIndex);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: widget.isDarkMode 
                                  ? Colors.grey.shade800 
                                  : Colors.grey.shade200,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status indicator
                            Container(
                              width: 12,
                              height: 12,
                              margin: const EdgeInsets.only(top: 4.0, right: 8.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: statusColor,
                              ),
                            ),
                            
                            // Decision content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ID and date
                                  Row(
                                    children: [
                                      Text(
                                        decision.id,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: widget.isDarkMode 
                                              ? Colors.white 
                                              : Colors.black87,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        _formatDate(decision.date),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: widget.isDarkMode 
                                              ? Colors.grey.shade400 
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 4),
                                  
                                  // Title
                                  Text(
                                    decision.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: widget.isDarkMode 
                                          ? Colors.white 
                                          : Colors.black87,
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 8),
                                  
                                  // Status and links
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                          vertical: 4.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12.0),
                                        ),
                                        child: Text(
                                          decision.status,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      
                                      if (decision.links.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          'Links:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: widget.isDarkMode 
                                                ? Colors.grey.shade400 
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        ...decision.links.take(3).map((linkId) {
                                          return Padding(
                                            padding: const EdgeInsets.only(right: 4.0),
                                            child: Chip(
                                              label: Text(
                                                linkId,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: widget.isDarkMode
                                                      ? Colors.blue.shade300
                                                      : Colors.blue.shade700,
                                                ),
                                              ),
                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              padding: EdgeInsets.zero,
                                              labelPadding: const EdgeInsets.symmetric(
                                                horizontal: 6.0,
                                                vertical: 0.0,
                                              ),
                                              backgroundColor: widget.isDarkMode
                                                  ? Colors.blue.shade900.withOpacity(0.3)
                                                  : Colors.blue.shade50,
                                            ),
                                          );
                                        }),
                                        if (decision.links.length > 3)
                                          Text(
                                            '+${decision.links.length - 3} more',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: widget.isDarkMode
                                                  ? Colors.grey.shade400
                                                  : Colors.grey.shade600,
                                            ),
                                          ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
  
  /// Formats a date for display.
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}