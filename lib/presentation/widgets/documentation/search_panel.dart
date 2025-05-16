import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/documentation_search_controller.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/documentation_search_index.dart';

/// A widget for displaying and managing documentation search
class SearchPanel extends StatefulWidget {
  /// The search controller
  final DocumentationSearchController controller;
  
  /// Called when a search result is selected
  final Function(DocumentationSearchResult)? onResultSelected;
  
  /// Whether to use dark mode styling
  final bool isDarkMode;
  
  /// Whether to show filter options
  final bool showFilters;
  
  /// Creates a new search panel
  const SearchPanel({
    Key? key,
    required this.controller,
    this.onResultSelected,
    this.isDarkMode = false,
    this.showFilters = true,
  }) : super(key: key);

  @override
  State<SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends State<SearchPanel> {
  late TextEditingController _textController;
  late FocusNode _searchFocusNode;
  
  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.controller.query);
    _searchFocusNode = FocusNode();
    
    // Update text controller when query changes
    widget.controller.addListener(_updateFromController);
  }
  
  void _updateFromController() {
    if (_textController.text != widget.controller.query) {
      _textController.text = widget.controller.query;
    }
  }
  
  @override
  void dispose() {
    widget.controller.removeListener(_updateFromController);
    _textController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: widget.controller.isExpanded ? 360 : 240,
      constraints: BoxConstraints(
        maxHeight: widget.controller.isExpanded && widget.controller.results.isNotEmpty 
            ? 400 
            : 56,
      ),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: widget.isDarkMode 
                ? Colors.black.withOpacity(0.3) 
                : Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search input field
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Icon(
                  Icons.search,
                  color: widget.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _textController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Search documentation...',
                    hintStyle: TextStyle(
                      color: widget.isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black87,
                  ),
                  onChanged: (value) {
                    widget.controller.query = value;
                  },
                  onTap: () {
                    widget.controller.isExpanded = true;
                  },
                  onSubmitted: (_) {
                    if (widget.controller.results.isNotEmpty) {
                      widget.onResultSelected?.call(widget.controller.results.first);
                    }
                  },
                  // Keyboard shortcuts for search navigation
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent) {
                      if (event.logicalKey == LogicalKeyboardKey.escape) {
                        _searchFocusNode.unfocus();
                        widget.controller.isExpanded = false;
                        return KeyEventResult.handled;
                      }
                    }
                    return KeyEventResult.ignored;
                  },
                ),
              ),
              if (_textController.text.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: widget.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _textController.clear();
                      widget.controller.query = '';
                    });
                  },
                ),
              if (widget.showFilters && widget.controller.isExpanded)
                IconButton(
                  icon: Icon(
                    Icons.filter_list,
                    color: widget.controller.filters.isNotEmpty
                        ? (widget.isDarkMode ? Colors.blue.shade300 : Colors.blue)
                        : (widget.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
                    size: 20,
                  ),
                  onPressed: () {
                    _showFilterDialog(context);
                  },
                ),
            ],
          ),
          
          // Search results
          if (widget.controller.isExpanded)
            Flexible(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: widget.controller.results.isEmpty ? 0 : null,
                child: Builder(
                  builder: (context) {
                    if (widget.controller.isSearching) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.isDarkMode ? Colors.blue.shade300 : Colors.blue,
                            ),
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    }
                    
                    if (widget.controller.results.isEmpty && widget.controller.query.isNotEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'No results found',
                            style: TextStyle(
                              color: widget.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: widget.controller.results.length,
                      itemBuilder: (context, index) {
                        final result = widget.controller.results[index];
                        return _buildResultItem(result, index);
                      },
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildResultItem(DocumentationSearchResult result, int index) {
    // Determine result icon based on type
    IconData icon;
    Color iconColor;
    
    if (result.type == 'decision') {
      icon = Icons.assignment;
      final status = result.metadata['status']?.toLowerCase() ?? '';
      
      // Color based on decision status
      if (status == 'accepted') {
        iconColor = Colors.green;
      } else if (status == 'rejected') {
        iconColor = Colors.red;
      } else if (status == 'superseded') {
        iconColor = Colors.orange;
      } else if (status == 'deprecated') {
        iconColor = Colors.amber;
      } else if (status == 'proposed') {
        iconColor = Colors.blue;
      } else {
        iconColor = widget.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700;
      }
    } else {
      icon = Icons.article;
      iconColor = widget.isDarkMode ? Colors.blue.shade300 : Colors.blue;
    }
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          widget.onResultSelected?.call(result);
          _searchFocusNode.unfocus();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2.0, right: 12.0),
                child: Icon(
                  icon,
                  size: 18,
                  color: iconColor,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: widget.isDarkMode ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.path,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.content,
                      style: TextStyle(
                        fontSize: 13,
                        color: widget.isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (result.metadata.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: _buildMetadataTags(result.metadata),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  List<Widget> _buildMetadataTags(Map<String, String> metadata) {
    final tags = <Widget>[];
    
    // Add decision ID tag
    if (metadata.containsKey('id')) {
      tags.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: widget.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            metadata['id']!,
            style: TextStyle(
              fontSize: 11,
              color: widget.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ),
      );
    }
    
    // Add status tag if present
    if (metadata.containsKey('status')) {
      final status = metadata['status']!;
      Color statusColor;
      
      // Determine color based on status
      if (status.toLowerCase() == 'accepted') {
        statusColor = Colors.green;
      } else if (status.toLowerCase() == 'rejected') {
        statusColor = Colors.red;
      } else if (status.toLowerCase() == 'superseded') {
        statusColor = Colors.orange;
      } else if (status.toLowerCase() == 'deprecated') {
        statusColor = Colors.amber;
      } else if (status.toLowerCase() == 'proposed') {
        statusColor = Colors.blue;
      } else {
        statusColor = widget.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700;
      }
      
      tags.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(widget.isDarkMode ? 0.3 : 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: statusColor.withOpacity(widget.isDarkMode ? 0.5 : 0.4),
              width: 1,
            ),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 11,
              color: widget.isDarkMode 
                  ? statusColor.shade300 
                  : statusColor.shade700,
            ),
          ),
        ),
      );
    }
    
    // Add date tag if present
    if (metadata.containsKey('date')) {
      tags.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: widget.isDarkMode ? Colors.blue.shade900.withOpacity(0.3) : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today,
                size: 10,
                color: widget.isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
              ),
              const SizedBox(width: 4),
              Text(
                metadata['date']!,
                style: TextStyle(
                  fontSize: 11,
                  color: widget.isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return tags;
  }
  
  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Search Filters',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          backgroundColor: widget.isDarkMode ? Colors.grey.shade800 : Colors.white,
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Document type filter
                Text(
                  'Document Type',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildFilterChip(
                      label: 'Documentation',
                      isSelected: widget.controller.filters['type'] == 'documentation',
                      onSelected: (selected) {
                        if (selected) {
                          widget.controller.addFilter('type', 'documentation');
                        } else {
                          widget.controller.removeFilter('type');
                        }
                        Navigator.pop(context);
                      },
                    ),
                    _buildFilterChip(
                      label: 'Decisions',
                      isSelected: widget.controller.filters['type'] == 'decision',
                      onSelected: (selected) {
                        if (selected) {
                          widget.controller.addFilter('type', 'decision');
                        } else {
                          widget.controller.removeFilter('type');
                        }
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Decision status filter
                Text(
                  'Decision Status',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFilterChip(
                      label: 'Accepted',
                      isSelected: widget.controller.filters['status'] == 'accepted',
                      color: Colors.green,
                      onSelected: (selected) {
                        if (selected) {
                          widget.controller.addFilter('status', 'accepted');
                        } else {
                          widget.controller.removeFilter('status');
                        }
                        Navigator.pop(context);
                      },
                    ),
                    _buildFilterChip(
                      label: 'Proposed',
                      isSelected: widget.controller.filters['status'] == 'proposed',
                      color: Colors.blue,
                      onSelected: (selected) {
                        if (selected) {
                          widget.controller.addFilter('status', 'proposed');
                        } else {
                          widget.controller.removeFilter('status');
                        }
                        Navigator.pop(context);
                      },
                    ),
                    _buildFilterChip(
                      label: 'Rejected',
                      isSelected: widget.controller.filters['status'] == 'rejected',
                      color: Colors.red,
                      onSelected: (selected) {
                        if (selected) {
                          widget.controller.addFilter('status', 'rejected');
                        } else {
                          widget.controller.removeFilter('status');
                        }
                        Navigator.pop(context);
                      },
                    ),
                    _buildFilterChip(
                      label: 'Superseded',
                      isSelected: widget.controller.filters['status'] == 'superseded',
                      color: Colors.orange,
                      onSelected: (selected) {
                        if (selected) {
                          widget.controller.addFilter('status', 'superseded');
                        } else {
                          widget.controller.removeFilter('status');
                        }
                        Navigator.pop(context);
                      },
                    ),
                    _buildFilterChip(
                      label: 'Deprecated',
                      isSelected: widget.controller.filters['status'] == 'deprecated',
                      color: Colors.amber,
                      onSelected: (selected) {
                        if (selected) {
                          widget.controller.addFilter('status', 'deprecated');
                        } else {
                          widget.controller.removeFilter('status');
                        }
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                widget.controller.clearFilters();
                Navigator.pop(context);
              },
              child: Text(
                'Clear All',
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.red.shade300 : Colors.red,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required Function(bool) onSelected,
    Color? color,
  }) {
    final chipColor = color ?? Colors.blue;
    
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected
              ? (widget.isDarkMode ? Colors.white : Colors.white)
              : (widget.isDarkMode ? Colors.white : Colors.black87),
        ),
      ),
      selected: isSelected,
      selectedColor: chipColor.withOpacity(widget.isDarkMode ? 0.7 : 0.8),
      backgroundColor: widget.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
      checkmarkColor: widget.isDarkMode ? Colors.white : Colors.white,
      onSelected: onSelected,
    );
  }
}