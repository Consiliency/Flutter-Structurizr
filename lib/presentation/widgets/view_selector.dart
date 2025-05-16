import 'package:flutter/material.dart' hide Element, Container, View, Border;
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/view/model_view.dart';
import 'package:flutter_structurizr/domain/view/views.dart';
import 'package:flutter_structurizr/presentation/rendering/base_renderer.dart';
import 'package:flutter_structurizr/domain/style/styles.dart' hide Border;
import 'dart:ui' as ui;

/// A widget for selecting different views from a workspace
class ViewSelector extends StatefulWidget {
  /// The workspace containing the views
  final Workspace workspace;

  /// Currently selected view key
  final String? selectedViewKey;

  /// Called when a view is selected
  final ValueChanged<String>? onViewSelected;

  /// Whether to show thumbnails for each view
  final bool showThumbnails;

  /// Whether to group views by type
  final bool groupByType;

  /// Whether to show the dropdown in a compact mode
  final bool compact;

  /// Creates a new view selector widget
  const ViewSelector({
    Key? key,
    required this.workspace,
    this.selectedViewKey,
    this.onViewSelected,
    this.showThumbnails = true,
    this.groupByType = true,
    this.compact = false,
  }) : super(key: key);

  @override
  State<ViewSelector> createState() => _ViewSelectorState();
}

class _ViewSelectorState extends State<ViewSelector> {
  // Currently selected view key
  String? _selectedViewKey;
  
  // Map of view thumbnails (cached)
  final Map<String, Image> _thumbnails = {};
  
  // Whether thumbnails are being generated
  bool _generatingThumbnails = false;

  @override
  void initState() {
    super.initState();
    _selectedViewKey = widget.selectedViewKey;
    
    if (widget.showThumbnails) {
      _generateThumbnails();
    }
  }

  @override
  void didUpdateWidget(ViewSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update selected view if changed externally
    if (widget.selectedViewKey != oldWidget.selectedViewKey) {
      _selectedViewKey = widget.selectedViewKey;
    }
    
    // Regenerate thumbnails if workspace changed
    if (widget.workspace != oldWidget.workspace && widget.showThumbnails) {
      _thumbnails.clear();
      _generateThumbnails();
    }
  }

  /// Generates thumbnails for all views in the workspace
  Future<void> _generateThumbnails() async {
    if (_generatingThumbnails) return;
    
    setState(() {
      _generatingThumbnails = true;
    });
    
    // Generate thumbnails in the background
    for (final view in _getAllViews()) {
      if (_thumbnails.containsKey(view.key)) continue;
      
      try {
        // Small size for thumbnails
        const thumbnailSize = 160.0;
        final thumbnail = await _generateViewThumbnail(view, thumbnailSize, thumbnailSize);
        
        if (mounted) {
          setState(() {
            _thumbnails[view.key] = thumbnail;
          });
        }
      } catch (e) {
        // Ignore thumbnail generation errors
      }
    }
    
    if (mounted) {
      setState(() {
        _generatingThumbnails = false;
      });
    }
  }

  /// Generates a thumbnail for a single view
  Future<Image> _generateViewThumbnail(ModelView view, double width, double height) async {
    // Create a recorder
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Clear the canvas with a white background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, height),
      Paint()..color = Colors.white,
    );
    
    // Create render parameters with simplified settings for thumbnails
    final renderParameters = RenderParameters(
      width: width,
      height: height,
      includeLegend: false,
      includeTitle: false,
      includeNames: true,
      includeBoundaries: true,
      scale: 0.8, // Scale down slightly to ensure padding
      highlightedElementIds: null,
      hiddenElementIds: null,
      hiddenRelationshipIds: null,
    );
    
    // Render the view
    try {
      // Use a minimal renderer for thumbnails
      final renderer = BaseRenderer();
      
      // Apply special styling for thumbnails
      final thumbnailStyles = widget.workspace.views.configuration?.styles?.copy() ?? Styles();
      // Simplify the styling for thumbnails if needed
      thumbnailStyles.elements.forEach((element) {
        element.opacity = 1.0; // Ensure full opacity for clarity
        element.metadata = false; // Hide metadata for cleaner thumbnails
      });
      
      // Render with optimized parameters
      renderer.render(
        canvas: canvas,
        workspace: widget.workspace,
        view: view,
        parameters: renderParameters,
        styles: thumbnailStyles,
      );
      
      // Add a title at the top if there's no preview content
      bool hasElements = view.elements.isNotEmpty;
      
      if (!hasElements) {
        // Draw a centered label for views without elements
        final textPainter = TextPainter(
          text: TextSpan(
            text: view.name,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );
        
        textPainter.layout(maxWidth: width);
        textPainter.paint(
          canvas,
          Offset(
            (width - textPainter.width) / 2,
            (height - textPainter.height) / 2,
          ),
        );
      }
      
      // Draw a border around the thumbnail
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width, height),
        Paint()
          ..color = Colors.grey.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
      
      // Convert to a picture
      final picture = recorder.endRecording();
      
      // Convert to an image
      final img = await picture.toImage(width.toInt(), height.toInt());
      
      // Convert to a UI image
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      
      if (bytes != null) {
        return Image.memory(
          bytes.buffer.asUint8List(),
          width: width,
          height: height,
          fit: BoxFit.contain,
        );
      }
    } catch (e) {
      // Log error but don't crash
      print('Error generating thumbnail for view ${view.key}: $e');
    }
    
    // Create a fallback placeholder thumbnail
    return _createPlaceholderThumbnail(view, width, height);
  }
  
  /// Create a simple placeholder thumbnail with the view type and name
  Image _createPlaceholderThumbnail(ModelView view, double width, double height) {
    // Create a recorder
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Fill background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, height),
      Paint()..color = Colors.grey.withOpacity(0.1),
    );
    
    // Draw border
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, height),
      Paint()
        ..color = Colors.grey.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    
    // Determine view type text
    String viewType = 'View';
    if (view is SystemContextView) {
      viewType = 'System Context';
    } else if (view is ContainerView) {
      viewType = 'Container';
    } else if (view is ComponentView) {
      viewType = 'Component';
    } else if (view is DynamicView) {
      viewType = 'Dynamic';
    } else if (view is DeploymentView) {
      viewType = 'Deployment';
    }
    
    // Draw view type
    final typeTextPainter = TextPainter(
      text: TextSpan(
        text: viewType,
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 12,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    
    typeTextPainter.layout(maxWidth: width - 16);
    typeTextPainter.paint(
      canvas,
      Offset(
        (width - typeTextPainter.width) / 2,
        height / 2 - typeTextPainter.height - 4,
      ),
    );
    
    // Draw view name
    final nameTextPainter = TextPainter(
      text: TextSpan(
        text: view.name,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    
    nameTextPainter.layout(maxWidth: width - 16);
    nameTextPainter.paint(
      canvas,
      Offset(
        (width - nameTextPainter.width) / 2,
        height / 2 + 4,
      ),
    );
    
    // Draw an icon based on view type
    IconData iconData = Icons.view_module;
    
    if (view is SystemContextView) {
      iconData = Icons.language;
    } else if (view is ContainerView) {
      iconData = Icons.widgets;
    } else if (view is ComponentView) {
      iconData = Icons.integration_instructions;
    } else if (view is DynamicView) {
      iconData = Icons.play_circle_outline;
    } else if (view is DeploymentView) {
      iconData = Icons.dns;
    }
    
    // We can't directly draw Flutter icons on canvas, so we'll use basic shapes instead
    // For a proper implementation, consider pre-rendering icons to images
    
    // Draw a circle in the top-right as a visual indicator
    canvas.drawCircle(
      Offset(width - 16, 16),
      8,
      Paint()..color = Colors.blue.withOpacity(0.7),
    );
    
    // Convert to a picture
    final picture = recorder.endRecording();
    
    // Convert to an image synchronously
    final img = picture.toImageSync(width.toInt(), height.toInt());
    
    // Convert to bytes
    final bytes = img.toByteData(format: ui.ImageByteFormat.png)!;
    
    // Return the image
    return Image.memory(
      bytes.buffer.asUint8List(),
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }

  /// Gets all views from the workspace
  List<ModelView> _getAllViews() {
    final views = <ModelView>[];
    final workspaceViews = widget.workspace.views;
    
    // Add all view types
    views.addAll(workspaceViews.systemContextViews);
    views.addAll(workspaceViews.containerViews);
    views.addAll(workspaceViews.componentViews);
    views.addAll(workspaceViews.dynamicViews);
    views.addAll(workspaceViews.deploymentViews);
    views.addAll(workspaceViews.filteredViews);
    views.addAll(workspaceViews.customViews);
    views.addAll(workspaceViews.imageViews);
    
    return views;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (widget.compact) {
      return _buildCompactSelector(theme);
    } else if (widget.groupByType) {
      return _buildGroupedSelector(theme);
    } else {
      return _buildFlatSelector(theme);
    }
  }

  /// Builds a compact view selector with just a dropdown
  Widget _buildCompactSelector(ThemeData theme) {
    final views = _getAllViews();
    
    // Sort views by type, then by name
    views.sort((a, b) {
      // First sort by view type
      final typeOrderA = _getViewTypeOrder(a);
      final typeOrderB = _getViewTypeOrder(b);
      
      if (typeOrderA != typeOrderB) {
        return typeOrderA.compareTo(typeOrderB);
      }
      
      // Then sort by name within the same type
      return a.name.compareTo(b.name);
    });
    
    // Group views by type for the dropdown
    final Map<String, List<ModelView>> groupedViews = {};
    
    for (final view in views) {
      final viewType = _getViewTypeName(view);
      groupedViews.putIfAbsent(viewType, () => []).add(view);
    }
    
    // Create dropdown items with optional grouping
    final dropdownItems = <DropdownMenuItem<String>>[];
    
    groupedViews.forEach((viewType, viewList) {
      // Add a header for the group (disabled item)
      dropdownItems.add(DropdownMenuItem<String>(
        value: null,
        enabled: false,
        child: Text(
          viewType,
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ));
      
      // Add items for this group
      for (final view in viewList) {
        // Determine icon for this view type
        IconData typeIcon = _getViewTypeIcon(view);
        
        // Create the dropdown item
        dropdownItems.add(DropdownMenuItem<String>(
          value: view.key,
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Row(
              children: [
                // View type icon
                Icon(
                  typeIcon,
                  size: 16,
                  color: theme.colorScheme.primary.withOpacity(0.7),
                ),
                const SizedBox(width: 8),
                
                // View name with optional description tooltip
                Expanded(
                  child: Tooltip(
                    message: view.description ?? view.name,
                    child: Text(
                      view.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                
                // Element count as a small chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${view.elements.length}',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
      }
      
      // Add a divider after each group except the last one
      if (viewType != groupedViews.keys.last) {
        dropdownItems.add(const DropdownMenuItem<String>(
          enabled: false,
          child: Divider(),
        ));
      }
    });
    
    // If no views, show disabled dropdown
    if (dropdownItems.isEmpty) {
      return Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Center(
          child: Text('No views available'),
        ),
      );
    }
    
    // Current view details for the dropdown button text
    final currentView = views.firstWhere(
      (view) => view.key == _selectedViewKey,
      orElse: () => views.first,
    );
    final currentViewIcon = _getViewTypeIcon(currentView);
    
    // Create the enhanced dropdown
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label text
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            'View',
            style: theme.textTheme.labelMedium,
          ),
        ),
        
        // Custom dropdown with icon and better styling
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(4),
            color: theme.cardColor,
          ),
          child: DropdownButtonHideUnderline(
            child: ButtonTheme(
              alignedDropdown: true,
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedViewKey ?? (views.isNotEmpty ? views.first.key : null),
                icon: const Icon(Icons.arrow_drop_down),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedViewKey = value;
                    });
                    widget.onViewSelected?.call(value);
                  }
                },
                items: dropdownItems,
                selectedItemBuilder: (context) {
                  return views.map<Widget>((view) {
                    return Row(
                      children: [
                        Icon(
                          _getViewTypeIcon(view),
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            view.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  /// Get the icon for a view type
  IconData _getViewTypeIcon(ModelView view) {
    if (view is SystemContextView) {
      return Icons.language;
    } else if (view is ContainerView) {
      return Icons.widgets;
    } else if (view is ComponentView) {
      return Icons.integration_instructions;
    } else if (view is DynamicView) {
      return Icons.play_circle_outline;
    } else if (view is DeploymentView) {
      return Icons.dns;
    } else if (view is FilteredView) {
      return Icons.filter_alt;
    } else if (view is ImageView) {
      return Icons.image;
    } else {
      return Icons.view_module;
    }
  }
  
  /// Get an integer value representing the view type order for sorting
  int _getViewTypeOrder(ModelView view) {
    if (view is SystemContextView) {
      return 1;
    } else if (view is ContainerView) {
      return 2;
    } else if (view is ComponentView) {
      return 3;
    } else if (view is DynamicView) {
      return 4;
    } else if (view is DeploymentView) {
      return 5;
    } else if (view is FilteredView) {
      return 6;
    } else if (view is ImageView) {
      return 7;
    } else {
      return 99; // Any other view type comes last
    }
  }

  /// Builds a flat view selector with all views in a single list
  Widget _buildFlatSelector(ThemeData theme) {
    final views = _getAllViews();
    
    // Sort views by name
    views.sort((a, b) => a.name.compareTo(b.name));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Select View',
            style: theme.textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: views.length,
            itemBuilder: (context, index) {
              final view = views[index];
              return _buildViewTile(view, theme);
            },
          ),
        ),
      ],
    );
  }

  /// Builds a grouped view selector with views organized by type
  Widget _buildGroupedSelector(ThemeData theme) {
    final workspaceViews = widget.workspace.views;
    
    // Group views by type
    final viewGroups = <String, List<ModelView>>{
      'System Context': workspaceViews.systemContextViews,
      'Container': workspaceViews.containerViews,
      'Component': workspaceViews.componentViews,
      'Dynamic': workspaceViews.dynamicViews,
      'Deployment': workspaceViews.deploymentViews,
      'Filtered': workspaceViews.filteredViews,
      'Custom': workspaceViews.customViews,
      'Image': workspaceViews.imageViews,
    };
    
    // Remove empty groups
    viewGroups.removeWhere((key, value) => value.isEmpty);
    
    // If no views, show empty message
    if (viewGroups.isEmpty) {
      return const Center(
        child: Text('No views available'),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Views',
            style: theme.textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: viewGroups.length,
            itemBuilder: (context, index) {
              final groupName = viewGroups.keys.elementAt(index);
              final groupViews = viewGroups[groupName]!;
              
              return ExpansionTile(
                title: Text(
                  '$groupName Views (${groupViews.length})',
                  style: theme.textTheme.titleSmall,
                ),
                initiallyExpanded: index == 0,
                children: groupViews.map((view) => _buildViewTile(view, theme)).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Builds a tile for a single view
  Widget _buildViewTile(ModelView view, ThemeData theme) {
    final isSelected = view.key == _selectedViewKey;
    
    // Determine icon based on view type
    IconData typeIcon = Icons.view_module;
    if (view is SystemContextView) {
      typeIcon = Icons.language;
    } else if (view is ContainerView) {
      typeIcon = Icons.widgets;
    } else if (view is ComponentView) {
      typeIcon = Icons.integration_instructions;
    } else if (view is DynamicView) {
      typeIcon = Icons.play_circle_outline;
    } else if (view is DeploymentView) {
      typeIcon = Icons.dns;
    } else if (view is FilteredView) {
      typeIcon = Icons.filter_alt;
    }
    
    // Build the leading thumbnail or loading indicator
    Widget? leading;
    if (widget.showThumbnails) {
      if (_thumbnails.containsKey(view.key)) {
        // Show thumbnail
        leading = ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: _thumbnails[view.key],
              ),
              // Add a subtle overlay if selected
              if (isSelected)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
            ],
          ),
        );
      } else {
        // Show loading indicator or placeholder
        leading = Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.grey.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: _generatingThumbnails
                ? const CircularProgressIndicator(strokeWidth: 2)
                : Icon(
                    typeIcon,
                    size: 24,
                    color: theme.colorScheme.primary.withOpacity(0.5),
                  ),
          ),
        );
      }
    } else {
      // Just show an icon if thumbnails are disabled
      leading = Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Icon(
            typeIcon,
            size: 24,
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }
    
    return Card(
      elevation: isSelected ? 2 : 0,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: isSelected
          ? theme.colorScheme.primary.withOpacity(0.1)
          : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 1)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          setState(() {
            _selectedViewKey = view.key;
          });
          widget.onViewSelected?.call(view.key);
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leading thumbnail or icon
              if (leading != null) leading,
              const SizedBox(width: 12),
              
              // Title and description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title with overflow handling
                    Text(
                      view.name,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // View type
                    Text(
                      _getViewTypeName(view),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    
                    // Description with overflow handling
                    if (view.description != null && view.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        view.description!,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    
                    // Element count
                    const SizedBox(height: 4),
                    Text(
                      '${view.elements.length} elements, ${view.relationships.length} relationships',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 10,
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
  
  /// Get the human-readable type name for a view
  String _getViewTypeName(ModelView view) {
    if (view is SystemContextView) {
      return 'System Context View';
    } else if (view is ContainerView) {
      return 'Container View';
    } else if (view is ComponentView) {
      return 'Component View';
    } else if (view is DynamicView) {
      return 'Dynamic View';
    } else if (view is DeploymentView) {
      return 'Deployment View';
    } else if (view is FilteredView) {
      return 'Filtered View';
    } else if (view is ImageView) {
      return 'Image View';
    } else {
      return 'View';
    }
  }
}