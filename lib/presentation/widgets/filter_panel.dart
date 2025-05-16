import 'package:flutter/material.dart' hide Container, Border, Element, View;
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/model/model.dart' hide Container, Element;
import 'package:flutter_structurizr/domain/style/styles.dart' hide Border;
import 'package:flutter/material.dart' as flutter;
import 'package:flutter_structurizr/domain/model/model.dart' as structurizr_model;

/// A panel for filtering diagram elements based on various criteria
class FilterPanel extends StatefulWidget {
  /// The workspace containing the elements to filter
  final Workspace workspace;
  
  /// Currently active filters
  final List<String> activeFilters;
  
  /// Called when filters are changed
  final Function(List<String>) onFiltersChanged;

  /// Creates a new filter panel widget
  const FilterPanel({
    Key? key,
    required this.workspace,
    required this.activeFilters,
    required this.onFiltersChanged,
  }) : super(key: key);

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  late List<String> _activeFilters;
  late TextEditingController _searchController;
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _activeFilters = List.from(widget.activeFilters);
    _searchController = TextEditingController();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Collect all potential filter options
    final List<String> allTags = _getAllTagsFromWorkspace();
    final List<String> allElementTypes = _getAllElementTypesFromWorkspace();
    
    // Filter the options based on search query
    final List<String> filteredTags = _searchQuery.isEmpty
      ? allTags
      : allTags.where((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    
    final List<String> filteredElementTypes = _searchQuery.isEmpty
      ? allElementTypes
      : allElementTypes.where((type) => type.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    
    return Material(
      color: theme.cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header and search
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Filter Diagram', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search filters',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ],
            ),
          ),
          
          // Active filters
          if (_activeFilters.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Active Filters', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _activeFilters.map((filter) => Chip(
                      label: Text(filter),
                      onDeleted: () => _removeFilter(filter),
                      deleteIcon: const Icon(Icons.close, size: 18),
                    )).toList(),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear All Filters'),
                    onPressed: _activeFilters.isEmpty ? null : _clearAllFilters,
                  ),
                  const Divider(height: 24),
                ],
              ),
            ),
          ],
          
          // Filter options
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                // Element Type Filters
                if (filteredElementTypes.isNotEmpty) ...[
                  ExpansionTile(
                    title: const Text('Element Types'),
                    initiallyExpanded: true,
                    children: filteredElementTypes.map((type) => CheckboxListTile(
                      title: Text(type),
                      value: _activeFilters.contains('type:$type'),
                      onChanged: (selected) {
                        final filterValue = 'type:$type';
                        if (selected == true) {
                          _addFilter(filterValue);
                        } else {
                          _removeFilter(filterValue);
                        }
                      },
                    )).toList(),
                  ),
                ],
                
                // Tag Filters
                if (filteredTags.isNotEmpty) ...[
                  ExpansionTile(
                    title: const Text('Tags'),
                    initiallyExpanded: true,
                    children: filteredTags.map((tag) => CheckboxListTile(
                      title: Text(tag),
                      value: _activeFilters.contains('tag:$tag'),
                      onChanged: (selected) {
                        final filterValue = 'tag:$tag';
                        if (selected == true) {
                          _addFilter(filterValue);
                        } else {
                          _removeFilter(filterValue);
                        }
                      },
                    )).toList(),
                  ),
                ],
                
                // Custom Filter Section
                ExpansionTile(
                  title: const Text('Custom Filters'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Add a custom filter expression:'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: const InputDecoration(
                                    labelText: 'Filter expression',
                                    hintText: 'e.g., name:contains:Service',
                                    border: OutlineInputBorder(),
                                  ),
                                  onSubmitted: (value) {
                                    if (value.isNotEmpty) {
                                      _addFilter(value);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  // Show predefined filter templates
                                  _showFilterTemplateMenu(context);
                                },
                                child: const Text('Templates'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Syntax: property:operator:value\n'
                            'Examples:\n'
                            '- name:contains:Service\n'
                            '- tag:equals:Database\n'
                            '- type:not:Person',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Bottom action buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    // Reset to default filters (empty)
                    setState(() {
                      _activeFilters = [];
                    });
                    widget.onFiltersChanged(_activeFilters);
                  },
                  child: const Text('Reset to Default'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    // Apply the current filter selections
                    widget.onFiltersChanged(_activeFilters);
                  },
                  child: const Text('Apply Filters'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper Methods
  
  void _addFilter(String filter) {
    if (!_activeFilters.contains(filter)) {
      setState(() {
        _activeFilters.add(filter);
      });
    }
  }
  
  void _removeFilter(String filter) {
    setState(() {
      _activeFilters.remove(filter);
    });
  }
  
  void _clearAllFilters() {
    setState(() {
      _activeFilters.clear();
    });
  }
  
  List<String> _getAllTagsFromWorkspace() {
    final Set<String> allTags = {};
    
    // Add tags from all elements
    final model = widget.workspace.model;
    if (model != null) {
      final allElements = model.getAllElements();
      for (final element in allElements) {
        allTags.addAll(element.tags);
      }
    }
    
    return allTags.toList()..sort();
  }
  
  List<String> _getAllElementTypesFromWorkspace() {
    final Set<String> elementTypes = {};
    
    // Add element types
    final model = widget.workspace.model;
    if (model != null) {
      final allElements = model.getAllElements();
      for (final element in allElements) {
        // Add the runtime type (without the package prefix)
        String typeName = element.runtimeType.toString();
        if (typeName.contains('.')) {
          typeName = typeName.split('.').last;
        }
        elementTypes.add(typeName);
      }
    }
    
    return elementTypes.toList()..sort();
  }
  
  void _showFilterTemplateMenu(BuildContext context) {
    final templates = [
      {
        'name': 'Database elements',
        'filter': 'tag:contains:Database',
      },
      {
        'name': 'External elements',
        'filter': 'tag:contains:External',
      },
      {
        'name': 'Elements with technology',
        'filter': 'property:exists:technology',
      },
      {
        'name': 'Person elements',
        'filter': 'type:equals:Person',
      },
      {
        'name': 'Container elements',
        'filter': 'type:equals:Container',
      },
    ];
    
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    
    showMenu<String>(
      context: context,
      position: position,
      items: templates.map((template) {
        return PopupMenuItem<String>(
          value: template['filter'],
          child: Text(template['name']!),
        );
      }).toList(),
    ).then((value) {
      if (value != null) {
        _addFilter(value);
      }
    });
  }
}

/// Shows the filter panel in a dialog
void showFilterPanel(BuildContext context, Workspace workspace, List<String> activeFilters, Function(List<String>) onFiltersChanged) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      child: SizedBox(
        width: 600,
        height: 700,
        child: FilterPanel(
          workspace: workspace,
          activeFilters: activeFilters,
          onFiltersChanged: (filters) {
            onFiltersChanged(filters);
            Navigator.of(context).pop();
          },
        ),
      ),
    ),
  );
}

/// Shows the filter panel in a drawer
void showFilterPanelInDrawer(BuildContext context, Workspace workspace, List<String> activeFilters, Function(List<String>) onFiltersChanged) {
  Scaffold.of(context).openEndDrawer();
  
  // Note: The drawer would be defined in the main scaffold as:
  // endDrawer: FilterPanel(
  //   workspace: workspace,
  //   activeFilters: activeFilters,
  //   onFiltersChanged: onFiltersChanged,
  // ),
}