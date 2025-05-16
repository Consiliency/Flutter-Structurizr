import 'package:flutter/material.dart' hide Container, Border, Element, View;
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/view/model_view.dart';
import 'package:flutter_structurizr/domain/model/model.dart' hide Container, Element;
import 'package:flutter_structurizr/domain/style/styles.dart' hide Border;
import 'package:flutter/material.dart' as flutter;
import 'package:flutter_structurizr/domain/model/model.dart' as structurizr_model;

/// Callback for when an element is selected in the explorer
typedef ElementSelectedCallback = void Function(String elementId, Element element);

/// Callback for when an element is dragged from the explorer
typedef ElementDraggedCallback = void Function(String elementId, Element element);

/// Callback for when a context menu item is selected for an element
typedef ElementContextMenuCallback = void Function(String itemId, String elementId, Element element);

/// Data class for dragged elements
class DraggedElementData {
  /// The ID of the dragged element
  final String elementId;
  
  /// The element being dragged
  final Element element;
  
  /// Creates a new dragged element data object
  const DraggedElementData({
    required this.elementId,
    required this.element,
  });
}

/// Context menu item definition
class ElementContextMenuItem {
  /// Unique ID for the menu item
  final String id;
  
  /// Label to display in the menu
  final String label;
  
  /// Icon to show in the menu
  final IconData? icon;
  
  /// Whether the menu item is enabled
  final bool enabled;
  
  /// Optional filter function to determine if this menu item should be shown
  /// for a specific element
  final bool Function(Element element)? filter;
  
  /// Creates a new context menu item
  const ElementContextMenuItem({
    required this.id,
    required this.label,
    this.icon,
    this.enabled = true,
    this.filter,
  });
}

/// Configuration for the element explorer.
class ElementExplorerConfig {
  /// Whether to show icons for different element types
  final bool showIcons;
  
  /// Whether to show element types as badges
  final bool showTypeBadges;
  
  /// Whether to show element descriptions
  final bool showDescriptions;
  
  /// Whether to show a search box
  final bool showSearchBox;
  
  /// Whether to expand the tree initially
  final bool initiallyExpanded;
  
  /// Whether to show elements by type
  final bool groupByType;
  
  /// Whether to show elements by tag
  final bool groupByTag;
  
  /// Whether to highlight elements that match the current view
  final bool highlightViewElements;
  
  /// Maximum length of description text before truncating
  final int maxDescriptionLength;
  
  /// Width of the explorer panel
  final double width;
  
  /// Background color of the explorer
  final Color? backgroundColor;
  
  /// Selected item color
  final Color? selectedColor;
  
  /// Hover item color
  final Color? hoverColor;
  
  /// Text color
  final Color? textColor;
  
  /// Badge background color
  final Color? badgeColor;
  
  /// Whether to enable drag and drop of elements
  final bool enableDragDrop;
  
  /// Whether to enable context menu on elements
  final bool enableContextMenu;
  
  /// List of context menu items to display
  final List<ElementContextMenuItem> contextMenuItems;
  
  /// Creates a new configuration for the element explorer
  const ElementExplorerConfig({
    this.showIcons = true,
    this.showTypeBadges = true,
    this.showDescriptions = true,
    this.showSearchBox = true,
    this.initiallyExpanded = false,
    this.groupByType = true,
    this.groupByTag = false,
    this.highlightViewElements = true,
    this.maxDescriptionLength = 100,
    this.width = 250.0,
    this.backgroundColor,
    this.selectedColor,
    this.hoverColor,
    this.textColor,
    this.badgeColor,
    this.enableDragDrop = false,
    this.enableContextMenu = false,
    this.contextMenuItems = const [],
  });
  
  /// Creates a copy of this configuration with the given fields replaced with new values
  ElementExplorerConfig copyWith({
    bool? showIcons,
    bool? showTypeBadges,
    bool? showDescriptions,
    bool? showSearchBox,
    bool? initiallyExpanded,
    bool? groupByType,
    bool? groupByTag,
    bool? highlightViewElements,
    int? maxDescriptionLength,
    double? width,
    Color? backgroundColor,
    Color? selectedColor,
    Color? hoverColor,
    Color? textColor,
    Color? badgeColor,
    bool? enableDragDrop,
    bool? enableContextMenu,
    List<ElementContextMenuItem>? contextMenuItems,
  }) {
    return ElementExplorerConfig(
      showIcons: showIcons ?? this.showIcons,
      showTypeBadges: showTypeBadges ?? this.showTypeBadges,
      showDescriptions: showDescriptions ?? this.showDescriptions,
      showSearchBox: showSearchBox ?? this.showSearchBox,
      initiallyExpanded: initiallyExpanded ?? this.initiallyExpanded,
      groupByType: groupByType ?? this.groupByType,
      groupByTag: groupByTag ?? this.groupByTag,
      highlightViewElements: highlightViewElements ?? this.highlightViewElements,
      maxDescriptionLength: maxDescriptionLength ?? this.maxDescriptionLength,
      width: width ?? this.width,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      selectedColor: selectedColor ?? this.selectedColor,
      hoverColor: hoverColor ?? this.hoverColor,
      textColor: textColor ?? this.textColor,
      badgeColor: badgeColor ?? this.badgeColor,
      enableDragDrop: enableDragDrop ?? this.enableDragDrop,
      enableContextMenu: enableContextMenu ?? this.enableContextMenu,
      contextMenuItems: contextMenuItems ?? this.contextMenuItems,
    );
  }
}

/// A widget that displays a hierarchical tree of elements in a Structurizr workspace.
///
/// This widget provides a browsable tree view of elements organized in a hierarchy,
/// optionally grouped by type or tag. It supports features like search, selection,
/// and highlighting based on configuration options.
class ElementExplorer extends StatefulWidget {
  /// The workspace containing the model and views
  final Workspace workspace;
  
  /// The currently selected view, if any
  final ModelView? selectedView;
  
  /// The currently selected element ID, if any
  final String? selectedElementId;
  
  /// Called when an element is selected
  final ElementSelectedCallback? onElementSelected;
  
  /// Called when an element is dragged from the explorer
  final ElementDraggedCallback? onElementDragged;
  
  /// Called when a context menu item is selected for an element
  final ElementContextMenuCallback? onContextMenuItemSelected;
  
  /// Configuration options for the explorer
  final ElementExplorerConfig config;
  
  /// Creates a new element explorer widget
  const ElementExplorer({
    Key? key,
    required this.workspace,
    this.selectedView,
    this.selectedElementId,
    this.onElementSelected,
    this.onElementDragged,
    this.onContextMenuItemSelected,
    this.config = const ElementExplorerConfig(),
  }) : super(key: key);

  @override
  State<ElementExplorer> createState() => _ElementExplorerState();
}

class _ElementExplorerState extends State<ElementExplorer> {
  /// The current search query, if any
  String _searchQuery = '';
  
  /// Map of expanded state by node ID
  Map<String, bool> _expandedNodes = {};
  
  @override
  void initState() {
    super.initState();
    
    // Initialize expanded state based on configuration
    _initializeExpandedState();
  }
  
  @override
  void didUpdateWidget(ElementExplorer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if we need to update expanded state based on configuration changes
    if (oldWidget.config.initiallyExpanded != widget.config.initiallyExpanded ||
        oldWidget.config.groupByType != widget.config.groupByType ||
        oldWidget.config.groupByTag != widget.config.groupByTag) {
      _initializeExpandedState();
    }
    
    // If the view changed, reset search
    if (oldWidget.selectedView != widget.selectedView) {
      setState(() {
        _searchQuery = '';
      });
    }
  }
  
  /// Initialize the expanded state of the tree nodes
  void _initializeExpandedState() {
    _expandedNodes = {};
    
    if (widget.config.initiallyExpanded) {
      // Expand all nodes
      _expandAll();
    } else {
      // Expand only the top level
      _expandTopLevel();
    }
  }
  
  /// Expand all nodes in the tree
  void _expandAll() {
    // Expand category nodes
    if (widget.config.groupByType) {
      _expandedNodes['type_Person'] = true;
      _expandedNodes['type_SoftwareSystem'] = true;
      _expandedNodes['type_Container'] = true;
      _expandedNodes['type_Component'] = true;
      _expandedNodes['type_DeploymentNode'] = true;
      _expandedNodes['type_InfrastructureNode'] = true;
    }
    
    // Expand elements with children
    for (final element in widget.workspace.model.getAllElements()) {
      _expandedNodes[element.id] = true;
    }
    
    // If grouping by tag, expand tag nodes
    if (widget.config.groupByTag) {
      for (final element in widget.workspace.model.getAllElements()) {
        for (final tag in element.tags) {
          _expandedNodes['tag_$tag'] = true;
        }
      }
    }
    
    setState(() {});
  }
  
  /// Expand only the top level nodes
  void _expandTopLevel() {
    // Expand category nodes
    if (widget.config.groupByType) {
      _expandedNodes['type_Person'] = true;
      _expandedNodes['type_SoftwareSystem'] = true;
      
      // Don't expand lower-level type categories
      _expandedNodes['type_Container'] = false;
      _expandedNodes['type_Component'] = false;
      _expandedNodes['type_DeploymentNode'] = false;
      _expandedNodes['type_InfrastructureNode'] = false;
    }
    
    // If grouping by tag, expand only tag nodes
    if (widget.config.groupByTag) {
      // Get common tags to expand
      final topLevelTags = ['External', 'Internal', 'System'];
      for (final tag in topLevelTags) {
        _expandedNodes['tag_$tag'] = true;
      }
    }
    
    // Expand top-level elements (no parent)
    for (final element in widget.workspace.model.getAllElements()) {
      _expandedNodes[element.id] = element.parentId == null;
    }
    
    setState(() {});
  }
  
  /// Toggle the expanded state of a node
  void _toggleExpanded(String nodeId) {
    setState(() {
      _expandedNodes[nodeId] = !(_expandedNodes[nodeId] ?? false);
    });
  }
  
  /// Check if an element matches the current search query
  bool _elementMatchesSearch(Element element) {
    if (_searchQuery.isEmpty) return true;
    
    final query = _searchQuery.toLowerCase();
    
    // Check if name contains the query
    if (element.name.toLowerCase().contains(query)) {
      return true;
    }
    
    // Check if description contains the query
    if (element.description != null && element.description!.toLowerCase().contains(query)) {
      return true;
    }
    
    // Check if type contains the query
    if (element.type.toLowerCase().contains(query)) {
      return true;
    }
    
    // Check if tags contain the query
    for (final tag in element.tags) {
      if (tag.toLowerCase().contains(query)) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Check if an element is in the selected view
  bool _elementInSelectedView(String elementId) {
    if (widget.selectedView == null) return false;
    return widget.selectedView!.containsElement(elementId);
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Use theme colors if not specified in config
    final backgroundColor = widget.config.backgroundColor ?? theme.colorScheme.surface;
    final selectedColor = widget.config.selectedColor ?? theme.colorScheme.primary.withOpacity(0.2);
    final hoverColor = widget.config.hoverColor ?? theme.colorScheme.primary.withOpacity(0.1);
    final textColor = widget.config.textColor ?? theme.colorScheme.onSurface;
    final badgeColor = widget.config.badgeColor ?? theme.colorScheme.primary;
    
    return Material(
      color: backgroundColor,
      child: SizedBox(
        width: widget.config.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search box
            if (widget.config.showSearchBox)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search elements...',
                    prefixIcon: const Icon(Icons.search),
                    border: flutter.OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      
                      // Auto-expand relevant nodes when searching
                      if (value.isNotEmpty) {
                        _expandAll();
                      }
                    });
                  },
                ),
              ),
            
            // Tree view controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Elements',
                    style: theme.textTheme.titleMedium,
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.unfold_less),
                        tooltip: 'Collapse All',
                        onPressed: () {
                          setState(() {
                            _expandedNodes = {};
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.unfold_more),
                        tooltip: 'Expand All',
                        onPressed: _expandAll,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Element tree view
            Expanded(
              child: _buildElementTree(
                context,
                selectedColor,
                hoverColor,
                textColor,
                badgeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build the element tree based on configuration
  Widget _buildElementTree(
    BuildContext context,
    Color selectedColor,
    Color hoverColor,
    Color textColor,
    Color badgeColor,
  ) {
    if (widget.config.groupByType) {
      return _buildElementTreeByType(
        context,
        selectedColor,
        hoverColor,
        textColor,
        badgeColor,
      );
    } else if (widget.config.groupByTag) {
      return _buildElementTreeByTag(
        context,
        selectedColor,
        hoverColor,
        textColor,
        badgeColor,
      );
    } else {
      return _buildElementTreeByHierarchy(
        context,
        selectedColor,
        hoverColor,
        textColor,
        badgeColor,
      );
    }
  }
  
  /// Build the element tree grouped by element type
  Widget _buildElementTreeByType(
    BuildContext context,
    Color selectedColor,
    Color hoverColor,
    Color textColor,
    Color badgeColor,
  ) {
    final theme = Theme.of(context);
    
    // Group elements by type
    final Map<String, List<Element>> elementsByType = {};
    for (final element in widget.workspace.model.getAllElements()) {
      if (_elementMatchesSearch(element)) {
        elementsByType.putIfAbsent(element.type, () => []).add(element);
      }
    }
    
    final typeNodes = <Widget>[];
    
    // Person elements
    if (elementsByType.containsKey('Person')) {
      typeNodes.add(
        _buildTypeNode(
          'Person',
          elementsByType['Person']!,
          Icons.person,
          selectedColor,
          hoverColor,
          textColor,
          badgeColor,
        ),
      );
    }
    
    // SoftwareSystem elements
    if (elementsByType.containsKey('SoftwareSystem')) {
      typeNodes.add(
        _buildTypeNode(
          'SoftwareSystem',
          elementsByType['SoftwareSystem']!,
          Icons.crop_square,
          selectedColor,
          hoverColor,
          textColor,
          badgeColor,
        ),
      );
    }
    
    // Container elements
    if (elementsByType.containsKey('Container')) {
      typeNodes.add(
        _buildTypeNode(
          'Container',
          elementsByType['Container']!,
          Icons.view_in_ar,
          selectedColor,
          hoverColor,
          textColor,
          badgeColor,
        ),
      );
    }
    
    // Component elements
    if (elementsByType.containsKey('Component')) {
      typeNodes.add(
        _buildTypeNode(
          'Component',
          elementsByType['Component']!,
          Icons.settings,
          selectedColor,
          hoverColor,
          textColor,
          badgeColor,
        ),
      );
    }
    
    // DeploymentNode elements
    if (elementsByType.containsKey('DeploymentNode')) {
      typeNodes.add(
        _buildTypeNode(
          'DeploymentNode',
          elementsByType['DeploymentNode']!,
          Icons.dns,
          selectedColor,
          hoverColor,
          textColor,
          badgeColor,
        ),
      );
    }
    
    // InfrastructureNode elements
    if (elementsByType.containsKey('InfrastructureNode')) {
      typeNodes.add(
        _buildTypeNode(
          'InfrastructureNode',
          elementsByType['InfrastructureNode']!,
          Icons.devices,
          selectedColor,
          hoverColor,
          textColor,
          badgeColor,
        ),
      );
    }
    
    // Add any remaining element types
    for (final type in elementsByType.keys) {
      if (!['Person', 'SoftwareSystem', 'Container', 'Component', 'DeploymentNode', 'InfrastructureNode'].contains(type)) {
        typeNodes.add(
          _buildTypeNode(
            type,
            elementsByType[type]!,
            Icons.category,
            selectedColor,
            hoverColor,
            textColor,
            badgeColor,
          ),
        );
      }
    }
    
    if (typeNodes.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty ? 'No elements' : 'No matching elements',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }
    
    return ListView(
      children: typeNodes,
    );
  }
  
  /// Build a node in the tree for a specific element type
  Widget _buildTypeNode(
    String type,
    List<Element> elements,
    IconData icon,
    Color selectedColor,
    Color hoverColor,
    Color textColor,
    Color badgeColor,
  ) {
    final nodeId = 'type_$type';
    final isExpanded = _expandedNodes[nodeId] ?? false;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type header
        InkWell(
          onTap: () => _toggleExpanded(nodeId),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                Icon(
                  isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                  size: 16,
                  color: textColor,
                ),
                const SizedBox(width: 4),
                if (widget.config.showIcons)
                  Icon(icon, size: 16, color: textColor),
                if (widget.config.showIcons)
                  const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    type,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Material(
                  color: badgeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      '${elements.length}',
                      style: TextStyle(
                        fontSize: 10,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Elements of this type
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: elements.map((element) {
                return _buildElementNode(
                  element,
                  selectedColor,
                  hoverColor,
                  textColor,
                  badgeColor,
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
  
  /// Build the element tree grouped by tags
  Widget _buildElementTreeByTag(
    BuildContext context,
    Color selectedColor,
    Color hoverColor,
    Color textColor,
    Color badgeColor,
  ) {
    final theme = Theme.of(context);
    
    // Group elements by tag
    final Map<String, List<Element>> elementsByTag = {};
    for (final element in widget.workspace.model.getAllElements()) {
      if (_elementMatchesSearch(element)) {
        for (final tag in element.tags) {
          elementsByTag.putIfAbsent(tag, () => []).add(element);
        }
      }
    }
    
    final tagNodes = <Widget>[];
    
    // Build a node for each tag
    for (final tag in elementsByTag.keys) {
      tagNodes.add(
        _buildTagNode(
          tag,
          elementsByTag[tag]!,
          selectedColor,
          hoverColor,
          textColor,
          badgeColor,
        ),
      );
    }
    
    if (tagNodes.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty ? 'No tagged elements' : 'No matching elements',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }
    
    return ListView(
      children: tagNodes,
    );
  }
  
  /// Build a node in the tree for a specific tag
  Widget _buildTagNode(
    String tag,
    List<Element> elements,
    Color selectedColor,
    Color hoverColor,
    Color textColor,
    Color badgeColor,
  ) {
    final nodeId = 'tag_$tag';
    final isExpanded = _expandedNodes[nodeId] ?? false;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tag header
        InkWell(
          onTap: () => _toggleExpanded(nodeId),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                Icon(
                  isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                  size: 16,
                  color: textColor,
                ),
                const SizedBox(width: 4),
                if (widget.config.showIcons)
                  Icon(Icons.label, size: 16, color: textColor),
                if (widget.config.showIcons)
                  const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Material(
                  color: badgeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      '${elements.length}',
                      style: TextStyle(
                        fontSize: 10,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Elements with this tag
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: elements.map((element) {
                return _buildElementNode(
                  element,
                  selectedColor,
                  hoverColor,
                  textColor,
                  badgeColor,
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
  
  /// Build the element tree based on the element hierarchy
  Widget _buildElementTreeByHierarchy(
    BuildContext context,
    Color selectedColor,
    Color hoverColor,
    Color textColor,
    Color badgeColor,
  ) {
    final theme = Theme.of(context);
    
    // Find top-level elements (no parent)
    final topLevelElements = widget.workspace.model.getAllElements()
        .where((e) => e.parentId == null && _elementMatchesSearch(e))
        .toList();
    
    if (topLevelElements.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty ? 'No elements' : 'No matching elements',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }
    
    return ListView(
      children: topLevelElements.map((element) {
        return _buildElementNodeWithChildren(
          element,
          selectedColor,
          hoverColor,
          textColor,
          badgeColor,
        );
      }).toList(),
    );
  }
  
  /// Build a node for an element, including its child elements if any
  Widget _buildElementNodeWithChildren(
    Element element,
    Color selectedColor,
    Color hoverColor,
    Color textColor,
    Color badgeColor,
  ) {
    // Get child elements
    final childElements = widget.workspace.model.getAllElements()
        .where((e) => e.parentId == element.id && _elementMatchesSearch(e))
        .toList();
    
    final isExpanded = _expandedNodes[element.id] ?? false;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Element node
        _buildElementNode(
          element,
          selectedColor,
          hoverColor,
          textColor,
          badgeColor,
          hasChildren: childElements.isNotEmpty,
          isExpanded: isExpanded,
          toggleExpanded: () => _toggleExpanded(element.id),
        ),
        
        // Child elements
        if (isExpanded && childElements.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: childElements.map((child) {
                return _buildElementNodeWithChildren(
                  child,
                  selectedColor,
                  hoverColor,
                  textColor,
                  badgeColor,
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
  
  /// Build a node for a single element
  Widget _buildElementNode(
    Element element,
    Color selectedColor,
    Color hoverColor,
    Color textColor,
    Color badgeColor, {
    bool hasChildren = false,
    bool isExpanded = false,
    VoidCallback? toggleExpanded,
  }) {
    final isSelected = element.id == widget.selectedElementId;
    final isInView = widget.config.highlightViewElements && _elementInSelectedView(element.id);
    
    // Create the element node content
    Widget elementContent = InkWell(
      onTap: () {
        if (widget.onElementSelected != null) {
          widget.onElementSelected!(element.id, element);
        }
        
        if (hasChildren && toggleExpanded != null) {
          toggleExpanded();
        }
      },
      hoverColor: hoverColor,
      splashColor: selectedColor,
      child: Material(
        color: isSelected ? selectedColor : isInView ? hoverColor : Colors.transparent,
        borderRadius: BorderRadius.circular(4.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Expand arrow for elements with children
                  if (hasChildren)
                    InkWell(
                      onTap: toggleExpanded,
                      child: Icon(
                        isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                        size: 16,
                        color: textColor,
                      ),
                    )
                  else
                    const SizedBox(width: 16),
                  
                  // Element icon
                  if (widget.config.showIcons)
                    _buildElementIcon(element),
                  if (widget.config.showIcons)
                    const SizedBox(width: 4),
                  
                  // Element name
                  Expanded(
                    child: Text(
                      element.name,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: isSelected || isInView ? FontWeight.bold : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // Type badge
                  if (widget.config.showTypeBadges)
                    Material(
                      color: badgeColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Text(
                          _formatElementType(element.type),
                          style: TextStyle(
                            fontSize: 10,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              
              // Element description
              if (widget.config.showDescriptions && element.description != null && element.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 2.0),
                  child: Text(
                    _truncateDescription(element.description!),
                    style: TextStyle(
                      fontSize: 10,
                      color: textColor.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    
    // Apply context menu if enabled
    if (widget.config.enableContextMenu) {
      elementContent = GestureDetector(
        onSecondaryTapUp: (details) {
          _showContextMenu(context, details.globalPosition, element);
        },
        onLongPress: () {
          final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
          final RenderBox box = context.findRenderObject() as RenderBox;
          final Offset position = box.localToGlobal(Offset.zero, ancestor: overlay);
          
          _showContextMenu(
            context,
            Rect.fromLTWH(position.dx, position.dy, box.size.width, box.size.height).center,
            element,
          );
        },
        child: elementContent,
      );
    }
    
    // Wrap with drag and drop support if enabled
    if (widget.config.enableDragDrop) {
      return Draggable<DraggedElementData>(
        // Drag data
        data: DraggedElementData(
          elementId: element.id,
          element: element,
        ),
        // Feedback widget (what's shown while dragging)
        feedback: Material(
          elevation: 3.0,
          borderRadius: BorderRadius.circular(4.0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: selectedColor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(4.0),
              border: flutter.Border.all(
                color: textColor.withOpacity(0.3),
                width: 1.0,
              ),
            ),
            child: SizedBox(
              width: 250.0,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    if (widget.config.showIcons) ...[
                      _buildElementIcon(element),
                      const SizedBox(width: 8.0),
                    ],
                    Expanded(
                      child: Text(
                        element.name,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Child widget (the actual tree item)
        child: elementContent,
        // Show a different cursor during drag
        childWhenDragging: Opacity(
          opacity: 0.5,
          child: elementContent,
        ),
        // Callback when drag starts
        onDragStarted: () {
          if (widget.onElementDragged != null) {
            widget.onElementDragged!(element.id, element);
          }
        },
        // Add some bouncing animation
        onDragEnd: (details) {
          // Could add custom behavior when drag ends
        },
      );
    }
    
    // Return regular widget if drag and drop is disabled
    return elementContent;
  }
  
  /// Shows the context menu for an element
  void _showContextMenu(BuildContext context, Offset position, Element element) {
    // If no context menu items are defined, don't show the menu
    if (widget.config.contextMenuItems.isEmpty) return;
    
    // Filter menu items based on element
    final filteredItems = widget.config.contextMenuItems
        .where((item) => item.filter == null || item.filter!(element))
        .toList();
    
    if (filteredItems.isEmpty) return;
    
    final theme = Theme.of(context);
    
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: filteredItems.map((item) {
        return PopupMenuItem<String>(
          value: item.id,
          enabled: item.enabled,
          child: Row(
            children: [
              if (item.icon != null) ...[
                Icon(item.icon, size: 16),
                const SizedBox(width: 8),
              ],
              Text(item.label),
            ],
          ),
        );
      }).toList(),
    ).then<void>((String? itemId) {
      if (itemId != null && widget.onContextMenuItemSelected != null) {
        // Find the selected menu item
        final selectedItem = filteredItems.firstWhere((item) => item.id == itemId);
        widget.onContextMenuItemSelected!(itemId, element.id, element);
      }
    });
  }
  
  /// Build an icon for an element based on its type
  Widget _buildElementIcon(Element element) {
    IconData icon;
    
    switch (element.type) {
      case 'Person':
        icon = Icons.person;
        break;
      case 'SoftwareSystem':
        icon = Icons.crop_square;
        break;
      case 'Container':
        icon = Icons.view_in_ar;
        break;
      case 'Component':
        icon = Icons.settings;
        break;
      case 'DeploymentNode':
        icon = Icons.dns;
        break;
      case 'InfrastructureNode':
        icon = Icons.devices;
        break;
      default:
        icon = Icons.circle;
        break;
    }
    
    return Icon(icon, size: 16);
  }
  
  /// Format an element type for display
  String _formatElementType(String type) {
    switch (type) {
      case 'SoftwareSystem':
        return 'System';
      case 'DeploymentNode':
        return 'Deployment';
      case 'InfrastructureNode':
        return 'Infrastructure';
      default:
        return type;
    }
  }
  
  /// Truncate a description to the configured maximum length
  String _truncateDescription(String description) {
    if (description.length <= widget.config.maxDescriptionLength) {
      return description;
    }
    
    return '${description.substring(0, widget.config.maxDescriptionLength)}...';
  }
}