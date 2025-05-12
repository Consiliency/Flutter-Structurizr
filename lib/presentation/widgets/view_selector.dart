import 'package:flutter/material.dart' hide Element, Container, View;
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/domain/view/views.dart';
import 'package:flutter_structurizr/presentation/rendering/base_renderer.dart';
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
    
    // Create render parameters
    final renderParameters = RenderParameters(
      width: width,
      height: height,
      includeLegend: false,
      includeTitle: false,
    );
    
    // Render the view
    try {
      // Use a minimal renderer for thumbnails
      final renderer = BaseRenderer();
      renderer.render(
        canvas: canvas,
        workspace: widget.workspace,
        view: view,
        parameters: renderParameters,
      );
      
      // Convert to a picture
      final picture = recorder.endRecording();
      
      // Convert to an image
      final img = await picture.toImage(width.toInt(), height.toInt());
      
      // Convert to a UI image
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      
      if (bytes != null) {
        return Image.memory(bytes.buffer.asUint8List());
      }
    } catch (e) {
      // Fallback for thumbnail generation errors
    }
    
    // Fallback if rendering fails
    return Image.asset('assets/images/thumbnail_placeholder.png');
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
    
    // Sort views by name
    views.sort((a, b) => a.name.compareTo(b.name));
    
    // Create dropdown items
    final dropdownItems = views.map<DropdownMenuItem<String>>((view) {
      return DropdownMenuItem<String>(
        value: view.key,
        child: Text(
          view.name,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }).toList();
    
    // If no views, show disabled dropdown
    if (dropdownItems.isEmpty) {
      return const SizedBox(
        height: 48,
        child: Center(
          child: Text('No views available'),
        ),
      );
    }
    
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Select View',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      value: _selectedViewKey,
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedViewKey = value;
          });
          widget.onViewSelected?.call(value);
        }
      },
      items: dropdownItems,
    );
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
    
    return ListTile(
      title: Text(
        view.name,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        view.description ?? view.key,
        overflow: TextOverflow.ellipsis,
      ),
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primary.withOpacity(0.1),
      leading: widget.showThumbnails
          ? _thumbnails.containsKey(view.key)
              ? SizedBox(
                  width: 48,
                  height: 48,
                  child: _thumbnails[view.key],
                )
              : const SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
          : null,
      onTap: () {
        setState(() {
          _selectedViewKey = view.key;
        });
        widget.onViewSelected?.call(view.key);
      },
    );
  }
}