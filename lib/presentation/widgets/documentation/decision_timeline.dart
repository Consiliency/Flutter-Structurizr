import 'package:flutter/material.dart';
import 'package:flutter_structurizr/domain/documentation/documentation.dart';

/// A widget that displays a timeline of architecture decisions.
class DecisionTimeline extends StatefulWidget {
  /// The list of architecture decisions.
  final List<Decision> decisions;
  
  /// Called when a decision is selected.
  final Function(int) onDecisionSelected;
  
  /// Whether to use dark mode.
  final bool isDarkMode;

  /// Creates a new decision timeline widget.
  const DecisionTimeline({
    Key? key,
    required this.decisions,
    required this.onDecisionSelected,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  State<DecisionTimeline> createState() => _DecisionTimelineState();
}

class _DecisionTimelineState extends State<DecisionTimeline> {
  late ScrollController _scrollController;
  late List<Decision> _sortedDecisions;
  
  // Filtering
  DateTime? _startDate;
  DateTime? _endDate;
  List<String> _selectedStatuses = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _sortedDecisions = List.from(widget.decisions);
    _sortDecisions();
  }
  
  @override
  void didUpdateWidget(DecisionTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.decisions != widget.decisions) {
      _sortedDecisions = List.from(widget.decisions);
      _sortDecisions();
    }
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  /// Sorts decisions by date (newest first).
  void _sortDecisions() {
    _sortedDecisions.sort((a, b) => b.date.compareTo(a.date));
  }
  
  /// Gets the filtered list of decisions.
  List<Decision> _getFilteredDecisions() {
    return _sortedDecisions.where((decision) {
      // Filter by date range
      if (_startDate != null && decision.date.isBefore(_startDate!)) {
        return false;
      }
      
      if (_endDate != null && decision.date.isAfter(_endDate!)) {
        return false;
      }
      
      // Filter by status
      if (_selectedStatuses.isNotEmpty && !_selectedStatuses.contains(decision.status)) {
        return false;
      }
      
      return true;
    }).toList();
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
  
  /// Shows the filter dialog.
  Future<void> _showFilterDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => FilterDialog(
        initialStartDate: _startDate,
        initialEndDate: _endDate,
        statuses: _getUniqueStatuses(),
        selectedStatuses: List.from(_selectedStatuses),
        isDarkMode: widget.isDarkMode,
      ),
    );
    
    if (result != null) {
      setState(() {
        _startDate = result['startDate'];
        _endDate = result['endDate'];
        _selectedStatuses = List<String>.from(result['selectedStatuses']);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredDecisions = _getFilteredDecisions();
    
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
                'Architecture Decision Timeline',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              // Filter button
              IconButton(
                icon: const Icon(Icons.filter_list),
                tooltip: 'Filter decisions',
                color: widget.isDarkMode ? Colors.white : Colors.black87,
                onPressed: _showFilterDialog,
              ),
              // Reset filter button
              if (_startDate != null || _endDate != null || _selectedStatuses.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear filters',
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                  onPressed: () {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                      _selectedStatuses = [];
                    });
                  },
                ),
            ],
          ),
        ),
        
        // Filter summary
        if (_startDate != null || _endDate != null || _selectedStatuses.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: widget.isDarkMode ? Colors.blue.shade900.withOpacity(0.3) : Colors.blue.shade50,
            child: Row(
              children: [
                const Icon(Icons.filter_list, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _buildFilterSummary(),
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        // Timeline content
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
                  controller: _scrollController,
                  itemCount: filteredDecisions.length,
                  itemBuilder: (context, index) {
                    final decision = filteredDecisions[index];
                    final statusColor = _getStatusColor(decision.status);
                    
                    // Check if this is the first decision of a year/month
                    final bool isFirstOfYear = index == 0 || 
                        decision.date.year != filteredDecisions[index - 1].date.year;
                    
                    final bool isFirstOfMonth = isFirstOfYear || 
                        (decision.date.month != filteredDecisions[index - 1].date.month);
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Year header
                        if (isFirstOfYear)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                            child: Text(
                              decision.date.year.toString(),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: widget.isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        
                        // Month header
                        if (isFirstOfMonth)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(32.0, 8.0, 16.0, 8.0),
                            child: Text(
                              _getMonthName(decision.date.month),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        
                        // Decision item
                        InkWell(
                          onTap: () {
                            final originalIndex = widget.decisions.indexOf(decision);
                            widget.onDecisionSelected(originalIndex);
                          },
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(48.0, 0.0, 16.0, 0.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Timeline line and dot
                                SizedBox(
                                  width: 24,
                                  height: 80,
                                  child: CustomPaint(
                                    painter: TimelinePainter(
                                      isFirst: index == 0,
                                      isLast: index == filteredDecisions.length - 1,
                                      color: statusColor,
                                      isDarkMode: widget.isDarkMode,
                                    ),
                                  ),
                                ),
                                
                                // Decision content
                                Expanded(
                                  child: Card(
                                    elevation: 1,
                                    margin: const EdgeInsets.only(
                                      left: 8.0,
                                      right: 0.0,
                                      top: 4.0,
                                      bottom: 12.0,
                                    ),
                                    color: widget.isDarkMode 
                                        ? Colors.grey.shade800 
                                        : Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                      side: BorderSide(
                                        color: statusColor.withOpacity(0.5),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Header with ID and status
                                          Row(
                                            children: [
                                              Text(
                                                decision.id,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: widget.isDarkMode 
                                                      ? Colors.white70 
                                                      : Colors.black87,
                                                ),
                                              ),
                                              const Spacer(),
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
                                            ],
                                          ),
                                          
                                          const SizedBox(height: 8),
                                          
                                          // Title
                                          Text(
                                            decision.title,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: widget.isDarkMode 
                                                  ? Colors.white 
                                                  : Colors.black87,
                                            ),
                                          ),
                                          
                                          const SizedBox(height: 4),
                                          
                                          // Date
                                          Text(
                                            _formatDate(decision.date),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: widget.isDarkMode 
                                                  ? Colors.grey.shade400 
                                                  : Colors.grey.shade700,
                                            ),
                                          ),
                                          
                                          // Links
                                          if (decision.links.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 4.0,
                                              runSpacing: 4.0,
                                              children: decision.links.map((linkId) {
                                                return Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 6.0,
                                                    vertical: 2.0,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: widget.isDarkMode
                                                        ? Colors.blue.shade900.withOpacity(0.3)
                                                        : Colors.blue.shade50,
                                                    borderRadius: BorderRadius.circular(4.0),
                                                  ),
                                                  child: Text(
                                                    linkId,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: widget.isDarkMode
                                                          ? Colors.blue.shade300
                                                          : Colors.blue.shade700,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
  
  /// Gets the month name from a month number.
  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    
    return months[month - 1];
  }
  
  /// Builds a summary of the current filters.
  String _buildFilterSummary() {
    final List<String> parts = [];
    
    if (_startDate != null) {
      parts.add('From: ${_formatDate(_startDate!)}');
    }
    
    if (_endDate != null) {
      parts.add('To: ${_formatDate(_endDate!)}');
    }
    
    if (_selectedStatuses.isNotEmpty) {
      parts.add('Status: ${_selectedStatuses.join(', ')}');
    }
    
    return parts.join(' • ');
  }
}

/// A painter for rendering the timeline line and dots.
class TimelinePainter extends CustomPainter {
  final bool isFirst;
  final bool isLast;
  final Color color;
  final bool isDarkMode;
  
  TimelinePainter({
    required this.isFirst,
    required this.isLast,
    required this.color,
    this.isDarkMode = false,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final dotStrokePaint = Paint()
      ..color = isDarkMode ? Colors.grey.shade900 : Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    // Center x position
    final centerX = size.width / 2;
    
    // Draw timeline line
    if (!isFirst) {
      canvas.drawLine(
        Offset(centerX, 0),
        Offset(centerX, size.height / 2 - 6),
        linePaint,
      );
    }
    
    if (!isLast) {
      canvas.drawLine(
        Offset(centerX, size.height / 2 + 6),
        Offset(centerX, size.height),
        linePaint,
      );
    }
    
    // Draw dot
    final dotRadius = 6.0;
    canvas.drawCircle(
      Offset(centerX, size.height / 2),
      dotRadius,
      dotStrokePaint,
    );
    
    canvas.drawCircle(
      Offset(centerX, size.height / 2),
      dotRadius - 2,
      dotPaint,
    );
  }
  
  @override
  bool shouldRepaint(TimelinePainter oldDelegate) {
    return oldDelegate.isFirst != isFirst ||
           oldDelegate.isLast != isLast ||
           oldDelegate.color != color ||
           oldDelegate.isDarkMode != isDarkMode;
  }
}

/// A dialog for filtering decisions.
class FilterDialog extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final List<String> statuses;
  final List<String> selectedStatuses;
  final bool isDarkMode;
  
  const FilterDialog({
    Key? key,
    this.initialStartDate,
    this.initialEndDate,
    required this.statuses,
    required this.selectedStatuses,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late DateTime? _startDate;
  late DateTime? _endDate;
  late List<String> _selectedStatuses;
  
  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _selectedStatuses = List.from(widget.selectedStatuses);
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Filter Decisions',
        style: TextStyle(
          color: widget.isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      backgroundColor: widget.isDarkMode ? Colors.grey.shade900 : Colors.white,
      content: SizedBox(
        width: 300,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date range
              Text(
                'Date Range',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              
              // Start date
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'From:',
                      style: TextStyle(
                        color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      
                      if (date != null) {
                        setState(() {
                          _startDate = date;
                        });
                      }
                    },
                    child: Text(
                      _startDate != null
                          ? _formatDate(_startDate!)
                          : 'Select date',
                      style: TextStyle(
                        color: widget.isDarkMode ? Colors.blue.shade300 : Colors.blue,
                      ),
                    ),
                  ),
                  if (_startDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        setState(() {
                          _startDate = null;
                        });
                      },
                      color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                ],
              ),
              
              // End date
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'To:',
                      style: TextStyle(
                        color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      
                      if (date != null) {
                        setState(() {
                          _endDate = date;
                        });
                      }
                    },
                    child: Text(
                      _endDate != null
                          ? _formatDate(_endDate!)
                          : 'Select date',
                      style: TextStyle(
                        color: widget.isDarkMode ? Colors.blue.shade300 : Colors.blue,
                      ),
                    ),
                  ),
                  if (_endDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        setState(() {
                          _endDate = null;
                        });
                      },
                      color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                ],
              ),
              
              const Divider(),
              
              // Status filter
              Text(
                'Status',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              
              // Status checkboxes
              ...widget.statuses.map((status) {
                return CheckboxListTile(
                  title: Text(
                    status,
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  value: _selectedStatuses.contains(status),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedStatuses.add(status);
                      } else {
                        _selectedStatuses.remove(status);
                      }
                    });
                  },
                  dense: true,
                  activeColor: widget.isDarkMode ? Colors.blue.shade300 : Colors.blue,
                  checkColor: widget.isDarkMode ? Colors.black : Colors.white,
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            'Cancel',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop({
              'startDate': _startDate,
              'endDate': _endDate,
              'selectedStatuses': _selectedStatuses,
            });
          },
          child: Text(
            'Apply',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.blue.shade300 : Colors.blue,
            ),
          ),
        ),
      ],
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}