import 'package:flutter/material.dart' hide Element, Container, View;
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/relationship.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';
import 'package:flutter_structurizr/domain/view/view.dart';

/// A panel for viewing and editing properties of Structurizr elements, relationships and views
class PropertyPanel extends StatefulWidget {
  /// The selected element (if any)
  final Element? selectedElement;

  /// The selected relationship (if any)
  final Relationship? selectedRelationship;
  
  /// The current view (optional)
  final ModelView? currentView;
  
  /// The styles for rendering (optional)
  final Styles? styles;
  
  /// Called when an element property is changed
  final void Function(Element element, String property, dynamic value)? onElementPropertyChanged;
  
  /// Called when a relationship property is changed
  final void Function(Relationship relationship, String property, dynamic value)? onRelationshipPropertyChanged;
  
  /// Called when a view property is changed
  final void Function(ModelView view, String property, dynamic value)? onViewPropertyChanged;

  /// Creates a new property panel widget
  const PropertyPanel({
    Key? key,
    this.selectedElement,
    this.selectedRelationship,
    this.currentView,
    this.styles,
    this.onElementPropertyChanged,
    this.onRelationshipPropertyChanged,
    this.onViewPropertyChanged,
  }) : super(key: key);

  @override
  State<PropertyPanel> createState() => _PropertyPanelState();
}

class _PropertyPanelState extends State<PropertyPanel> with SingleTickerProviderStateMixin {
  // Tab controller for properties, styles, and tags
  late TabController _tabController;
  
  // Editing controllers
  final Map<String, TextEditingController> _textControllers = {};
  
  // Track expanded sections
  bool _propertiesExpanded = true;
  bool _stylesExpanded = true;
  bool _tagsExpanded = true;
  bool _additionalInfoExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    // Dispose all text controllers
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  void didUpdateWidget(PropertyPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If selected items changed, dispose old controllers and create new ones
    if (widget.selectedElement != oldWidget.selectedElement ||
        widget.selectedRelationship != oldWidget.selectedRelationship) {
      _disposeControllers();
      _createControllers();
    }
  }
  
  /// Creates text controllers for editing fields
  void _createControllers() {
    if (widget.selectedElement != null) {
      _createElementControllers(widget.selectedElement!);
    } else if (widget.selectedRelationship != null) {
      _createRelationshipControllers(widget.selectedRelationship!);
    } else if (widget.currentView != null) {
      _createViewControllers(widget.currentView!);
    }
  }
  
  /// Creates controllers for element properties
  void _createElementControllers(Element element) {
    _textControllers['name'] = TextEditingController(text: element.name);
    _textControllers['description'] = TextEditingController(text: element.description ?? '');
    
    // Element-specific properties
    final elementProperties = element.properties;
    if (elementProperties != null) {
      for (final key in elementProperties.keys) {
        final value = elementProperties[key];
        if (value != null) {
          _textControllers['property.$key'] = TextEditingController(text: value.toString());
        }
      }
    }
  }
  
  /// Creates controllers for relationship properties
  void _createRelationshipControllers(Relationship relationship) {
    _textControllers['description'] = TextEditingController(text: relationship.description ?? '');
    _textControllers['technology'] = TextEditingController(text: relationship.technology ?? '');
    
    // Relationship-specific properties
    final relationshipProperties = relationship.properties;
    if (relationshipProperties != null) {
      for (final key in relationshipProperties.keys) {
        final value = relationshipProperties[key];
        if (value != null) {
          _textControllers['property.$key'] = TextEditingController(text: value.toString());
        }
      }
    }
  }
  
  /// Creates controllers for view properties
  void _createViewControllers(ModelView view) {
    _textControllers['key'] = TextEditingController(text: view.key);
    _textControllers['name'] = TextEditingController(text: view.name);
    _textControllers['description'] = TextEditingController(text: view.description ?? '');
  }
  
  /// Disposes all text controllers
  void _disposeControllers() {
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    _textControllers.clear();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Show empty panel if nothing is selected
    if (widget.selectedElement == null &&
        widget.selectedRelationship == null &&
        widget.currentView == null) {
      return _buildEmptyPanel(theme);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab bar for properties, styles, and tags
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Properties'),
            Tab(text: 'Styles'),
            Tab(text: 'Tags'),
          ],
          labelColor: theme.primaryColor,
          unselectedLabelColor: theme.textTheme.bodyLarge?.color,
        ),
        
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPropertiesTab(theme),
              _buildStylesTab(theme),
              _buildTagsTab(theme),
            ],
          ),
        ),
      ],
    );
  }
  
  /// Builds the panel when nothing is selected
  Widget _buildEmptyPanel(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app,
            size: 48,
            color: theme.disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Select an element or relationship to edit its properties',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.disabledColor,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Builds the properties tab
  Widget _buildPropertiesTab(ThemeData theme) {
    if (widget.selectedElement != null) {
      return _buildElementProperties(widget.selectedElement!, theme);
    } else if (widget.selectedRelationship != null) {
      return _buildRelationshipProperties(widget.selectedRelationship!, theme);
    } else if (widget.currentView != null) {
      return _buildViewProperties(widget.currentView!, theme);
    } else {
      return Container();
    }
  }
  
  /// Builds the styles tab
  Widget _buildStylesTab(ThemeData theme) {
    if (widget.selectedElement != null) {
      return _buildElementStyles(widget.selectedElement!, theme);
    } else if (widget.selectedRelationship != null) {
      return _buildRelationshipStyles(widget.selectedRelationship!, theme);
    } else {
      return Container();
    }
  }
  
  /// Builds the tags tab
  Widget _buildTagsTab(ThemeData theme) {
    if (widget.selectedElement != null) {
      return _buildElementTags(widget.selectedElement!, theme);
    } else if (widget.selectedRelationship != null) {
      return _buildRelationshipTags(widget.selectedRelationship!, theme);
    } else {
      return Container();
    }
  }
  
  /// Builds properties for an element
  Widget _buildElementProperties(Element element, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Element type
          Text(
            'Element Type: ${element.runtimeType.toString()}',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          
          // Basic properties
          ExpansionTile(
            title: const Text('Basic Properties'),
            initiallyExpanded: _propertiesExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                _propertiesExpanded = expanded;
              });
            },
            children: [
              _buildTextField(
                label: 'ID',
                value: element.id,
                readOnly: true,
                onChanged: null,
              ),
              _buildTextField(
                label: 'Name',
                controller: _textControllers['name'],
                onChanged: (value) {
                  widget.onElementPropertyChanged?.call(element, 'name', value);
                },
              ),
              _buildTextField(
                label: 'Description',
                controller: _textControllers['description'],
                onChanged: (value) {
                  widget.onElementPropertyChanged?.call(element, 'description', value);
                },
              ),
            ],
          ),
          
          // Custom properties
          if (element.properties != null && element.properties!.isNotEmpty)
            ExpansionTile(
              title: const Text('Custom Properties'),
              initiallyExpanded: _additionalInfoExpanded,
              onExpansionChanged: (expanded) {
                setState(() {
                  _additionalInfoExpanded = expanded;
                });
              },
              children: element.properties!.entries.map((entry) {
                return _buildTextField(
                  label: entry.key,
                  controller: _textControllers['property.${entry.key}'],
                  onChanged: (value) {
                    widget.onElementPropertyChanged?.call(
                      element,
                      'property.${entry.key}',
                      value,
                    );
                  },
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
  
  /// Builds properties for a relationship
  Widget _buildRelationshipProperties(Relationship relationship, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Relationship type
          Text(
            'Relationship',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          
          // Basic properties
          ExpansionTile(
            title: const Text('Basic Properties'),
            initiallyExpanded: _propertiesExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                _propertiesExpanded = expanded;
              });
            },
            children: [
              _buildTextField(
                label: 'ID',
                value: relationship.id,
                readOnly: true,
                onChanged: null,
              ),
              _buildTextField(
                label: 'Source',
                value: relationship.sourceId,
                readOnly: true,
                onChanged: null,
              ),
              _buildTextField(
                label: 'Destination',
                value: relationship.destinationId,
                readOnly: true,
                onChanged: null,
              ),
              _buildTextField(
                label: 'Description',
                controller: _textControllers['description'],
                onChanged: (value) {
                  widget.onRelationshipPropertyChanged?.call(relationship, 'description', value);
                },
              ),
              _buildTextField(
                label: 'Technology',
                controller: _textControllers['technology'],
                onChanged: (value) {
                  widget.onRelationshipPropertyChanged?.call(relationship, 'technology', value);
                },
              ),
            ],
          ),
          
          // Custom properties
          if (relationship.properties != null && relationship.properties!.isNotEmpty)
            ExpansionTile(
              title: const Text('Custom Properties'),
              initiallyExpanded: _additionalInfoExpanded,
              onExpansionChanged: (expanded) {
                setState(() {
                  _additionalInfoExpanded = expanded;
                });
              },
              children: relationship.properties!.entries.map((entry) {
                return _buildTextField(
                  label: entry.key,
                  controller: _textControllers['property.${entry.key}'],
                  onChanged: (value) {
                    widget.onRelationshipPropertyChanged?.call(
                      relationship,
                      'property.${entry.key}',
                      value,
                    );
                  },
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
  
  /// Builds properties for a view
  Widget _buildViewProperties(ModelView view, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // View type
          Text(
            'View Type: ${view.runtimeType.toString()}',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          
          // Basic properties
          ExpansionTile(
            title: const Text('Basic Properties'),
            initiallyExpanded: _propertiesExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                _propertiesExpanded = expanded;
              });
            },
            children: [
              _buildTextField(
                label: 'Key',
                controller: _textControllers['key'],
                readOnly: true,
                onChanged: null,
              ),
              _buildTextField(
                label: 'Name',
                controller: _textControllers['name'],
                onChanged: (value) {
                  widget.onViewPropertyChanged?.call(view, 'name', value);
                },
              ),
              _buildTextField(
                label: 'Description',
                controller: _textControllers['description'],
                onChanged: (value) {
                  widget.onViewPropertyChanged?.call(view, 'description', value);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Builds style editor for an element
  Widget _buildElementStyles(Element element, ThemeData theme) {
    if (widget.styles == null) {
      return const Center(
        child: Text('No styles available'),
      );
    }
    
    // Get element style
    final elementStyle = widget.styles!.findElementStyle(element);
    if (elementStyle == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No styles defined for this element',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Create a new style for this element
                // This would be implemented based on the style management system
              },
              child: const Text('Create Style'),
            ),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Element type
          Text(
            'Element Style',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          
          // Style properties
          ExpansionTile(
            title: const Text('Visual Styles'),
            initiallyExpanded: _stylesExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                _stylesExpanded = expanded;
              });
            },
            children: [
              // Color picker
              ListTile(
                title: const Text('Background Color'),
                subtitle: Text(elementStyle.background?.toString() ?? 'Default'),
                trailing: elementStyle.background != null
                    ? Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Color(int.parse(elementStyle.background!.replaceAll('#', '0xFF'))),
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )
                    : null,
                onTap: () {
                  // Open color picker
                  // This would be implemented based on the preferred color picker
                },
              ),
              
              // Shape dropdown
              ListTile(
                title: const Text('Shape'),
                subtitle: Text(elementStyle.shape?.toString() ?? 'Default'),
                onTap: () {
                  // Open shape picker
                  // This would show a dialog with shape options
                },
              ),
              
              // Border style
              ListTile(
                title: const Text('Border Style'),
                subtitle: Text(elementStyle.border?.toString() ?? 'Default'),
                onTap: () {
                  // Open border style picker
                  // This would show a dialog with border style options
                },
              ),
              
              // Icon
              ListTile(
                title: const Text('Icon'),
                subtitle: Text(elementStyle.icon ?? 'None'),
                onTap: () {
                  // Open icon picker
                  // This would show a dialog with icon options
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Builds style editor for a relationship
  Widget _buildRelationshipStyles(Relationship relationship, ThemeData theme) {
    if (widget.styles == null) {
      return const Center(
        child: Text('No styles available'),
      );
    }
    
    // Get relationship style
    final relationshipStyle = widget.styles!.findRelationshipStyle(relationship);
    if (relationshipStyle == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No styles defined for this relationship',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Create a new style for this relationship
                // This would be implemented based on the style management system
              },
              child: const Text('Create Style'),
            ),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Relationship type
          Text(
            'Relationship Style',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          
          // Style properties
          ExpansionTile(
            title: const Text('Visual Styles'),
            initiallyExpanded: _stylesExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                _stylesExpanded = expanded;
              });
            },
            children: [
              // Color picker
              ListTile(
                title: const Text('Line Color'),
                subtitle: Text(relationshipStyle.color?.toString() ?? 'Default'),
                trailing: relationshipStyle.color != null
                    ? Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Color(int.parse(relationshipStyle.color!.replaceAll('#', '0xFF'))),
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )
                    : null,
                onTap: () {
                  // Open color picker
                  // This would be implemented based on the preferred color picker
                },
              ),
              
              // Line style
              ListTile(
                title: const Text('Line Style'),
                subtitle: Text(relationshipStyle.style?.toString() ?? 'Default'),
                onTap: () {
                  // Open line style picker
                  // This would show a dialog with line style options
                },
              ),
              
              // Routing
              ListTile(
                title: const Text('Routing'),
                subtitle: Text(relationshipStyle.routing?.toString() ?? 'Default'),
                onTap: () {
                  // Open routing style picker
                  // This would show a dialog with routing options
                },
              ),
              
              // Position
              ListTile(
                title: const Text('Label Position'),
                subtitle: Text(relationshipStyle.position?.toString() ?? 'Default'),
                onTap: () {
                  // Open position picker
                  // This would show a dialog with position options
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Builds tag editor for an element
  Widget _buildElementTags(Element element, ThemeData theme) {
    final tags = element.tags ?? [];
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with add button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Element Tags',
                style: theme.textTheme.titleMedium,
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  // Show dialog to add a new tag
                  _showAddTagDialog(context, (newTag) {
                    if (widget.onElementPropertyChanged != null && newTag.isNotEmpty) {
                      final updatedTags = List<String>.from(tags)..add(newTag);
                      widget.onElementPropertyChanged?.call(element, 'tags', updatedTags);
                    }
                  });
                },
                tooltip: 'Add Tag',
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Tags list
          Expanded(
            child: tags.isEmpty
                ? Center(
                    child: Text(
                      'No tags defined',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.disabledColor,
                      ),
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          // Remove tag
                          if (widget.onElementPropertyChanged != null) {
                            final updatedTags = List<String>.from(tags)..remove(tag);
                            widget.onElementPropertyChanged?.call(element, 'tags', updatedTags);
                          }
                        },
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
  
  /// Builds tag editor for a relationship
  Widget _buildRelationshipTags(Relationship relationship, ThemeData theme) {
    final tags = relationship.tags ?? [];
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with add button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Relationship Tags',
                style: theme.textTheme.titleMedium,
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  // Show dialog to add a new tag
                  _showAddTagDialog(context, (newTag) {
                    if (widget.onRelationshipPropertyChanged != null && newTag.isNotEmpty) {
                      final updatedTags = List<String>.from(tags)..add(newTag);
                      widget.onRelationshipPropertyChanged?.call(relationship, 'tags', updatedTags);
                    }
                  });
                },
                tooltip: 'Add Tag',
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Tags list
          Expanded(
            child: tags.isEmpty
                ? Center(
                    child: Text(
                      'No tags defined',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.disabledColor,
                      ),
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          // Remove tag
                          if (widget.onRelationshipPropertyChanged != null) {
                            final updatedTags = List<String>.from(tags)..remove(tag);
                            widget.onRelationshipPropertyChanged?.call(relationship, 'tags', updatedTags);
                          }
                        },
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
  
  /// Builds a text field for editing properties
  Widget _buildTextField({
    required String label,
    TextEditingController? controller,
    String? value,
    bool readOnly = false,
    ValueChanged<String>? onChanged,
  }) {
    // If controller is null but value is provided, create a static field
    if (controller == null && value != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextField(
          controller: TextEditingController(text: value),
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          readOnly: true,
          enabled: false,
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        readOnly: readOnly,
        onChanged: onChanged,
      ),
    );
  }
  
  /// Shows a dialog to add a new tag
  void _showAddTagDialog(BuildContext context, ValueChanged<String> onTagAdded) {
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Tag'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(
              labelText: 'Tag',
              hintText: 'Enter tag name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            onSubmitted: (value) {
              Navigator.of(context).pop();
              onTagAdded(value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onTagAdded(textController.text);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}