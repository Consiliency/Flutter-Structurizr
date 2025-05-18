import 'package:flutter/material.dart' hide Container, Border, Element, View;
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/view/model_view.dart';
import 'package:flutter_structurizr/domain/style/styles.dart'
    as structurizr_style;
import 'package:flutter_structurizr/domain/style/styles.dart'
    show ElementStyle, RelationshipStyle, Styles;
import 'package:flutter/material.dart' as flutter;
import 'package:flutter_structurizr/util/color.dart';

// Enum for border style selection in the UI
enum BorderStyleOption { solid, dashed, dotted }

// ===== Minimal custom painters for line and routing previews =====
class LineStylePreviewPainter extends CustomPainter {
  final dynamic lineStyle;
  final Color color;
  final double thickness;
  LineStylePreviewPainter(
      {required this.lineStyle, required this.color, required this.thickness});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness;
    canvas.drawLine(
        Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;
    double dashWidth = 5, dashSpace = 3, startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, size.height / 2),
          Offset(startX + dashWidth, size.height / 2), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;
    double dotSpacing = 4, startX = 0;
    while (startX < size.width) {
      canvas.drawCircle(Offset(startX, size.height / 2), 1.5, paint);
      startX += dotSpacing;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class OrthogonalRoutingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, size.height / 2),
        Offset(size.width / 2, size.height / 2), paint);
    canvas.drawLine(Offset(size.width / 2, size.height / 2),
        Offset(size.width / 2, size.height), paint);
    canvas.drawLine(Offset(size.width / 2, size.height),
        Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CurvedRoutingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;
    final path = Path();
    path.moveTo(0, size.height / 2);
    path.quadraticBezierTo(size.width / 2, 0, size.width, size.height / 2);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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
  final void Function(Element element, String property, dynamic value)?
      onElementPropertyChanged;

  /// Called when a relationship property is changed
  final void Function(
          Relationship relationship, String property, dynamic value)?
      onRelationshipPropertyChanged;

  /// Called when a view property is changed
  final void Function(ModelView view, String property, dynamic value)?
      onViewPropertyChanged;

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

class _PropertyPanelState extends State<PropertyPanel>
    with SingleTickerProviderStateMixin {
  // Tab controller for properties, styles, and tags
  late TabController _tabController;

  // Editing controllers
  final Map<String, TextEditingController> _textControllers = {};

  // Track expanded sections
  bool _propertiesExpanded = true;
  bool _stylesExpanded = true;
  final bool _tagsExpanded = true;
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
    _textControllers['description'] =
        TextEditingController(text: element.description ?? '');

    // Element-specific properties
    final elementProperties = element.properties;
    for (final key in elementProperties.keys) {
      final value = elementProperties[key];
      if (value != null) {
        _textControllers['property.$key'] =
            TextEditingController(text: value.toString());
      }
    }
  }

  /// Creates controllers for relationship properties
  void _createRelationshipControllers(Relationship relationship) {
    _textControllers['description'] =
        TextEditingController(text: relationship.description ?? '');
    _textControllers['technology'] =
        TextEditingController(text: relationship.technology ?? '');

    // Relationship-specific properties
    final relationshipProperties = relationship.properties;
    for (final key in relationshipProperties.keys) {
      final value = relationshipProperties[key];
      if (value != null) {
        _textControllers['property.$key'] =
            TextEditingController(text: value.toString());
      }
    }
  }

  /// Creates controllers for view properties
  void _createViewControllers(ModelView view) {
    _textControllers['key'] = TextEditingController(text: view.key);
    _textControllers['name'] =
        TextEditingController(text: view.title ?? view.key);
    _textControllers['description'] =
        TextEditingController(text: view.description ?? '');
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
      return const SizedBox();
    }
  }

  /// Builds the styles tab
  Widget _buildStylesTab(ThemeData theme) {
    if (widget.selectedElement != null) {
      return _buildElementStyles(widget.selectedElement!, theme);
    } else if (widget.selectedRelationship != null) {
      return _buildRelationshipStyles(widget.selectedRelationship!, theme);
    } else {
      return const SizedBox();
    }
  }

  /// Builds the tags tab
  Widget _buildTagsTab(ThemeData theme) {
    if (widget.selectedElement != null) {
      return _buildElementTags(widget.selectedElement!, theme);
    } else if (widget.selectedRelationship != null) {
      return _buildRelationshipTags(widget.selectedRelationship!, theme);
    } else {
      return const SizedBox();
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
                  widget.onElementPropertyChanged
                      ?.call(element, 'description', value);
                },
              ),
            ],
          ),

          // Custom properties
          if (element.properties.isNotEmpty)
            ExpansionTile(
              title: const Text('Custom Properties'),
              initiallyExpanded: _additionalInfoExpanded,
              onExpansionChanged: (expanded) {
                setState(() {
                  _additionalInfoExpanded = expanded;
                });
              },
              children: element.properties.entries.map((entry) {
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
  Widget _buildRelationshipProperties(
      Relationship relationship, ThemeData theme) {
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
                  widget.onRelationshipPropertyChanged
                      ?.call(relationship, 'description', value);
                },
              ),
              _buildTextField(
                label: 'Technology',
                controller: _textControllers['technology'],
                onChanged: (value) {
                  widget.onRelationshipPropertyChanged
                      ?.call(relationship, 'technology', value);
                },
              ),
            ],
          ),

          // Custom properties
          if (relationship.properties.isNotEmpty)
            ExpansionTile(
              title: const Text('Custom Properties'),
              initiallyExpanded: _additionalInfoExpanded,
              onExpansionChanged: (expanded) {
                setState(() {
                  _additionalInfoExpanded = expanded;
                });
              },
              children: relationship.properties.entries.map((entry) {
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
                  widget.onViewPropertyChanged
                      ?.call(view, 'description', value);
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
                final newStyle = structurizr_style.ElementStyle(
                    tag: element.tags.isNotEmpty
                        ? element.tags.first
                        : 'default');
                // Call the style creation function (implementation needed)
                if (widget.onElementPropertyChanged != null) {
                  widget.onElementPropertyChanged
                      ?.call(element, 'style', newStyle);
                }
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
          // Element type and style preview
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Element Style',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              // Preview container
              SizedBox(
                width: 60,
                height: 40,
                child: DecoratedBox(
                  decoration: flutter.BoxDecoration(
                    color: parseColor(elementStyle.background) ?? Colors.white,
                    border: flutter.BoxBorder.lerp(
                      flutter.Border.all(
                        color: parseColor(elementStyle.stroke) ?? Colors.grey,
                        width: (elementStyle.strokeWidth ?? 1).toDouble(),
                      ),
                      flutter.Border.all(
                        color: parseColor(elementStyle.stroke) ?? Colors.grey,
                        width: (elementStyle.strokeWidth ?? 1).toDouble(),
                      ),
                      1.0,
                    ),
                    borderRadius:
                        elementStyle.shape == structurizr_style.Shape.roundedBox
                            ? flutter.BorderRadius.circular(8)
                            : null,
                    shape: elementStyle.shape == structurizr_style.Shape.circle
                        ? flutter.BoxShape.circle
                        : flutter.BoxShape.rectangle,
                  ),
                  child: Center(
                    child: Text(
                      'Aa',
                      style: TextStyle(
                        fontSize: (elementStyle.fontSize ?? 12).toDouble(),
                        color: parseColor(elementStyle.color) ?? Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Colors section
          ExpansionTile(
            title: const Text('Colors'),
            initiallyExpanded: _stylesExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                _stylesExpanded = expanded;
              });
            },
            children: [
              // Background color picker
              ListTile(
                title: const Text('Background Color'),
                subtitle:
                    Text(elementStyle.background?.toString() ?? 'Default'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (elementStyle.background != null)
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: DecoratedBox(
                          decoration: flutter.BoxDecoration(
                            color: parseColor(elementStyle.background) ??
                                Colors.white,
                            border: flutter.BoxBorder.lerp(
                              flutter.Border.all(color: Colors.grey),
                              flutter.Border.all(color: Colors.grey),
                              1.0,
                            ),
                            borderRadius: flutter.BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    const Icon(Icons.colorize),
                  ],
                ),
                onTap: () {
                  _showColorPicker(
                    context,
                    'Background Color',
                    parseColor(elementStyle.background) ?? Colors.white,
                    (Color newColor) {
                      if (widget.onElementPropertyChanged != null) {
                        final updatedStyle = elementStyle.copyWith(
                          background: newColor.toString(),
                        );
                        widget.onElementPropertyChanged
                            ?.call(element, 'style', updatedStyle);
                      }
                    },
                  );
                },
              ),

              // Text color picker
              ListTile(
                title: const Text('Text Color'),
                subtitle: Text(elementStyle.color?.toString() ?? 'Default'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (elementStyle.color != null)
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: DecoratedBox(
                          decoration: flutter.BoxDecoration(
                            color:
                                parseColor(elementStyle.color) ?? Colors.black,
                            border: flutter.BoxBorder.lerp(
                              flutter.Border.all(color: Colors.grey),
                              flutter.Border.all(color: Colors.grey),
                              1.0,
                            ),
                            borderRadius: flutter.BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    const Icon(Icons.format_color_text),
                  ],
                ),
                onTap: () {
                  _showColorPicker(
                    context,
                    'Text Color',
                    parseColor(elementStyle.color) ?? Colors.black,
                    (Color newColor) {
                      if (widget.onElementPropertyChanged != null) {
                        final updatedStyle = elementStyle.copyWith(
                          color: newColor.toString(),
                        );
                        widget.onElementPropertyChanged
                            ?.call(element, 'style', updatedStyle);
                      }
                    },
                  );
                },
              ),

              // Border color picker
              ListTile(
                title: const Text('Border Color'),
                subtitle: Text(elementStyle.stroke?.toString() ?? 'Default'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (elementStyle.stroke != null)
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: DecoratedBox(
                          decoration: flutter.BoxDecoration(
                            color:
                                parseColor(elementStyle.stroke) ?? Colors.grey,
                            border: flutter.BoxBorder.lerp(
                              flutter.Border.all(color: Colors.grey),
                              flutter.Border.all(color: Colors.grey),
                              1.0,
                            ),
                            borderRadius: flutter.BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    const Icon(Icons.border_color),
                  ],
                ),
                onTap: () {
                  _showColorPicker(
                    context,
                    'Border Color',
                    parseColor(elementStyle.stroke) ?? Colors.grey,
                    (Color newColor) {
                      if (widget.onElementPropertyChanged != null) {
                        final updatedStyle = elementStyle.copyWith(
                          stroke: newColor.toString(),
                        );
                        widget.onElementPropertyChanged
                            ?.call(element, 'style', updatedStyle);
                      }
                    },
                  );
                },
              ),

              // Opacity slider
              ListTile(
                title: const Text('Opacity'),
                subtitle: Slider(
                  value: elementStyle.opacity.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 100,
                  label: '${elementStyle.opacity}%',
                  onChanged: (value) {
                    if (widget.onElementPropertyChanged != null) {
                      final updatedStyle = elementStyle.copyWith(
                        opacity: value.round(),
                      );
                      widget.onElementPropertyChanged
                          ?.call(element, 'style', updatedStyle);
                    }
                  },
                ),
              ),
            ],
          ),

          // Shape and Size section
          ExpansionTile(
            title: const Text('Shape & Size'),
            children: [
              // Shape selector
              ListTile(
                title: const Text('Shape'),
                subtitle: Text(_getShapeName(elementStyle.shape)),
                trailing: _getShapeIcon(elementStyle.shape),
                onTap: () {
                  _showShapeSelector(
                    context,
                    elementStyle.shape,
                    (structurizr_style.Shape newShape) {
                      if (widget.onElementPropertyChanged != null) {
                        final updatedStyle = elementStyle.copyWith(
                          shape: newShape,
                        );
                        widget.onElementPropertyChanged
                            ?.call(element, 'style', updatedStyle);
                      }
                    },
                  );
                },
              ),

              // Border style
              ListTile(
                title: const Text('Border Style'),
                subtitle: Text(_getBorderStyleName(
                    mapInternalBorderToOption(elementStyle.border))),
                trailing: _getBorderStyleIcon(
                    mapInternalBorderToOption(elementStyle.border)),
                onTap: () {
                  _showBorderStyleSelector(
                    context,
                    mapInternalBorderToOption(elementStyle.border),
                    (BorderStyleOption newBorder) {
                      if (widget.onElementPropertyChanged != null) {
                        final updatedStyle = elementStyle.copyWith(
                          border: mapOptionToInternalBorder(newBorder),
                        );
                        widget.onElementPropertyChanged
                            ?.call(element, 'style', updatedStyle);
                      }
                    },
                  );
                },
              ),

              // Width and Height
              ListTile(
                title: const Text('Size'),
                subtitle: Text(
                    '${elementStyle.width ?? 'Auto'} \u00d7 ${elementStyle.height ?? 'Auto'}'),
                trailing: const Icon(Icons.aspect_ratio),
                onTap: () {
                  _showSizeDialog(
                    context,
                    elementStyle.width,
                    elementStyle.height,
                    (int? newWidth, int? newHeight) {
                      if (widget.onElementPropertyChanged != null) {
                        final updatedStyle = elementStyle.copyWith(
                          width: newWidth,
                          height: newHeight,
                        );
                        widget.onElementPropertyChanged
                            ?.call(element, 'style', updatedStyle);
                      }
                    },
                  );
                },
              ),

              // Border width
              ListTile(
                title: const Text('Border Width'),
                subtitle: Text('${elementStyle.strokeWidth ?? 1} px'),
                trailing: const Icon(Icons.line_weight),
                onTap: () {
                  _showStrokeWidthDialog(
                    context,
                    elementStyle.strokeWidth ?? 1,
                    (int newWidth) {
                      if (widget.onElementPropertyChanged != null) {
                        final updatedStyle = elementStyle.copyWith(
                          strokeWidth: newWidth,
                        );
                        widget.onElementPropertyChanged
                            ?.call(element, 'style', updatedStyle);
                      }
                    },
                  );
                },
              ),
            ],
          ),

          // Text and Icon section
          ExpansionTile(
            title: const Text('Text & Icons'),
            children: [
              // Font size
              ListTile(
                title: const Text('Font Size'),
                subtitle: Text('${elementStyle.fontSize ?? 'Default'} px'),
                trailing: const Icon(Icons.format_size),
                onTap: () {
                  _showFontSizeDialog(
                    context,
                    elementStyle.fontSize,
                    (int? newSize) {
                      if (widget.onElementPropertyChanged != null) {
                        final updatedStyle = elementStyle.copyWith(
                          fontSize: newSize,
                        );
                        widget.onElementPropertyChanged
                            ?.call(element, 'style', updatedStyle);
                      }
                    },
                  );
                },
              ),

              // Icon
              ListTile(
                title: const Text('Icon'),
                subtitle: Text(elementStyle.icon ?? 'None'),
                trailing: const Icon(Icons.image),
                onTap: () {
                  _showIconDialog(
                    context,
                    elementStyle.icon,
                    (String? newIcon) {
                      if (widget.onElementPropertyChanged != null) {
                        final updatedStyle = elementStyle.copyWith(
                          icon: newIcon,
                        );
                        widget.onElementPropertyChanged
                            ?.call(element, 'style', updatedStyle);
                      }
                    },
                  );
                },
              ),
            ],
          ),

          // Metadata section
          ExpansionTile(
            title: const Text('Metadata'),
            children: [
              // Show metadata
              SwitchListTile(
                title: const Text('Show Metadata'),
                value: elementStyle.metadata ?? false,
                onChanged: (bool value) {
                  if (widget.onElementPropertyChanged != null) {
                    final updatedStyle = elementStyle.copyWith(
                      metadata: value,
                    );
                    widget.onElementPropertyChanged
                        ?.call(element, 'style', updatedStyle);
                  }
                },
              ),

              // Show description
              SwitchListTile(
                title: const Text('Show Description'),
                value: elementStyle.description ?? false,
                onChanged: (bool value) {
                  if (widget.onElementPropertyChanged != null) {
                    final updatedStyle = elementStyle.copyWith(
                      description: value,
                    );
                    widget.onElementPropertyChanged
                        ?.call(element, 'style', updatedStyle);
                  }
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
    final relationshipStyle =
        widget.styles!.findRelationshipStyle(relationship);
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
                final newStyle = structurizr_style.RelationshipStyle(
                    tag: relationship.tags.isNotEmpty
                        ? relationship.tags.first
                        : 'default');
                // Call the style creation function
                if (widget.onRelationshipPropertyChanged != null) {
                  widget.onRelationshipPropertyChanged
                      ?.call(relationship, 'style', newStyle);
                }
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
          // Relationship type and style preview
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Relationship Style',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              // Preview container for relationship
              SizedBox(
                width: 60,
                height: 24,
                child: CustomPaint(
                  painter: LineStylePreviewPainter(
                    lineStyle: relationshipStyle.style,
                    color: parseColor(relationshipStyle.color) ?? Colors.black,
                    thickness: relationshipStyle.thickness.toDouble(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Line Appearance section
          ExpansionTile(
            title: const Text('Line Appearance'),
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
                subtitle:
                    Text(relationshipStyle.color?.toString() ?? 'Default'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (relationshipStyle.color != null)
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: DecoratedBox(
                          decoration: flutter.BoxDecoration(
                            color: parseColor(relationshipStyle.color) ??
                                Colors.black,
                            border: flutter.BoxBorder.lerp(
                              flutter.Border.all(color: Colors.grey),
                              flutter.Border.all(color: Colors.grey),
                              1.0,
                            ),
                            borderRadius: flutter.BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    const Icon(Icons.colorize),
                  ],
                ),
                onTap: () {
                  _showColorPicker(
                    context,
                    'Line Color',
                    parseColor(relationshipStyle.color) ?? Colors.black,
                    (Color newColor) {
                      if (widget.onRelationshipPropertyChanged != null) {
                        final updatedStyle = relationshipStyle.copyWith(
                          color: newColor.toString(),
                        );
                        widget.onRelationshipPropertyChanged
                            ?.call(relationship, 'style', updatedStyle);
                      }
                    },
                  );
                },
              ),

              // Line style
              ListTile(
                title: const Text('Line Style'),
                subtitle: Text(_getLineStyleName(relationshipStyle.style)),
                trailing: _getLineStyleIcon(relationshipStyle.style),
                onTap: () {
                  _showLineStyleSelector(
                    context,
                    relationshipStyle.style,
                    (structurizr_style.LineStyle newStyle) {
                      if (widget.onRelationshipPropertyChanged != null) {
                        final updatedStyle = relationshipStyle.copyWith(
                          style: newStyle,
                        );
                        widget.onRelationshipPropertyChanged
                            ?.call(relationship, 'style', updatedStyle);
                      }
                    },
                  );
                },
              ),

              // Thickness
              ListTile(
                title: const Text('Line Thickness'),
                subtitle: Text('${relationshipStyle.thickness} px'),
                trailing: const Icon(Icons.line_weight),
                onTap: () {
                  _showThicknessDialog(
                    context,
                    relationshipStyle.thickness,
                    (int newThickness) {
                      if (widget.onRelationshipPropertyChanged != null) {
                        final updatedStyle = relationshipStyle.copyWith(
                          thickness: newThickness,
                        );
                        widget.onRelationshipPropertyChanged
                            ?.call(relationship, 'style', updatedStyle);
                      }
                    },
                  );
                },
              ),

              // Opacity slider
              ListTile(
                title: const Text('Opacity'),
                subtitle: Slider(
                  value: relationshipStyle.opacity.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 100,
                  label: '${relationshipStyle.opacity}%',
                  onChanged: (value) {
                    if (widget.onRelationshipPropertyChanged != null) {
                      final updatedStyle = relationshipStyle.copyWith(
                        opacity: value.round(),
                      );
                      widget.onRelationshipPropertyChanged
                          ?.call(relationship, 'style', updatedStyle);
                    }
                  },
                ),
              ),
            ],
          ),

          // Routing section
          ExpansionTile(
            title: const Text('Routing'),
            children: [
              // Routing style
              ListTile(
                title: const Text('Routing'),
                subtitle: Text(_getRoutingName(relationshipStyle.routing)),
                trailing: _getRoutingIcon(relationshipStyle.routing),
                onTap: () {
                  _showRoutingSelector(
                    context,
                    relationshipStyle.routing,
                    (structurizr_style.StyleRouting newRouting) {
                      if (widget.onRelationshipPropertyChanged != null) {
                        final updatedStyle = relationshipStyle.copyWith(
                          routing: newRouting,
                        );
                        widget.onRelationshipPropertyChanged
                            ?.call(relationship, 'style', updatedStyle);
                      }
                    },
                  );
                },
              ),
            ],
          ),

          // Text and Label section
          ExpansionTile(
            title: const Text('Label'),
            children: [
              // Font size
              ListTile(
                title: const Text('Font Size'),
                subtitle: Text('${relationshipStyle.fontSize ?? 'Default'} px'),
                trailing: const Icon(Icons.format_size),
                onTap: () {
                  _showFontSizeDialog(
                    context,
                    relationshipStyle.fontSize,
                    (int? newSize) {
                      if (widget.onRelationshipPropertyChanged != null) {
                        final updatedStyle = relationshipStyle.copyWith(
                          fontSize: newSize,
                        );
                        widget.onRelationshipPropertyChanged
                            ?.call(relationship, 'style', updatedStyle);
                      }
                    },
                  );
                },
              ),

              // Label width
              ListTile(
                title: const Text('Label Width'),
                subtitle: Text('${relationshipStyle.width ?? 'Auto'} px'),
                trailing: const Icon(Icons.format_line_spacing),
                onTap: () {
                  _showLabelWidthDialog(
                    context,
                    relationshipStyle.width,
                    (int? newWidth) {
                      if (widget.onRelationshipPropertyChanged != null) {
                        final updatedStyle = relationshipStyle.copyWith(
                          width: newWidth,
                        );
                        widget.onRelationshipPropertyChanged
                            ?.call(relationship, 'style', updatedStyle);
                      }
                    },
                  );
                },
              ),

              // Position slider
              ListTile(
                title: const Text('Label Position'),
                subtitle: Slider(
                  value: relationshipStyle.position.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 100,
                  label: '${relationshipStyle.position}%',
                  onChanged: (value) {
                    if (widget.onRelationshipPropertyChanged != null) {
                      final updatedStyle = relationshipStyle.copyWith(
                        position: value.round(),
                      );
                      widget.onRelationshipPropertyChanged
                          ?.call(relationship, 'style', updatedStyle);
                    }
                  },
                ),
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
                    if (widget.onElementPropertyChanged != null &&
                        newTag.isNotEmpty) {
                      final updatedTags = List<String>.from(tags)..add(newTag);
                      widget.onElementPropertyChanged
                          ?.call(element, 'tags', updatedTags);
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
                            final updatedTags = List<String>.from(tags)
                              ..remove(tag);
                            widget.onElementPropertyChanged
                                ?.call(element, 'tags', updatedTags);
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
                    if (widget.onRelationshipPropertyChanged != null &&
                        newTag.isNotEmpty) {
                      final updatedTags = List<String>.from(tags)..add(newTag);
                      widget.onRelationshipPropertyChanged
                          ?.call(relationship, 'tags', updatedTags);
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
                            final updatedTags = List<String>.from(tags)
                              ..remove(tag);
                            widget.onRelationshipPropertyChanged
                                ?.call(relationship, 'tags', updatedTags);
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        readOnly: readOnly,
        onChanged: onChanged,
      ),
    );
  }

  /// Shows a dialog to add a new tag
  void _showAddTagDialog(
      BuildContext context, ValueChanged<String> onTagAdded) {
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

  /// Shows a color picker dialog
  void _showColorPicker(BuildContext context, String title, Color initialColor,
      ValueChanged<Color> onColorSelected) {
    // A list of material colors to choose from
    final List<Color> materialColors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
      Colors.black,
      Colors.white,
    ];

    // Selected color
    Color selectedColor = initialColor;

    // Show the color picker dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Preview of selected color
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: DecoratedBox(
                        decoration: flutter.BoxDecoration(
                          color: selectedColor,
                          border: flutter.BoxBorder.lerp(
                            flutter.Border.all(color: Colors.grey),
                            flutter.Border.all(color: Colors.grey),
                            1.0,
                          ),
                          borderRadius: flutter.BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Color grid
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: materialColors.map((color) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedColor = color;
                            });
                          },
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: DecoratedBox(
                              decoration: flutter.BoxDecoration(
                                color: color,
                                border: flutter.BoxBorder.lerp(
                                  flutter.Border.all(
                                    color: selectedColor == color
                                        ? Colors.blue
                                        : Colors.grey,
                                    width: selectedColor == color ? 2 : 1,
                                  ),
                                  flutter.Border.all(
                                    color: selectedColor == color
                                        ? Colors.blue
                                        : Colors.grey,
                                    width: selectedColor == color ? 2 : 1,
                                  ),
                                  1.0,
                                ),
                                borderRadius: flutter.BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    // Transparency slider
                    const SizedBox(height: 16),
                    const Text('Transparency'),
                    Slider(
                      value: 1.0 - (selectedColor.a / 255),
                      min: 0.0,
                      max: 1.0,
                      onChanged: (value) {
                        setState(() {
                          selectedColor =
                              selectedColor.withValues(alpha: ((1.0 - value)));
                        });
                      },
                    ),
                  ],
                ),
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
                    onColorSelected(selectedColor);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Shows a shape selector dialog
  void _showShapeSelector(
      BuildContext context,
      structurizr_style.Shape currentShape,
      ValueChanged<structurizr_style.Shape> onShapeSelected) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Shape'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: structurizr_style.Shape.values.map((shape) {
              final isSelected = shape == currentShape;
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  onShapeSelected(shape);
                },
                child: flutter.Container(
                  decoration: flutter.BoxDecoration(
                    border: flutter.BoxBorder.lerp(
                      flutter.Border.all(
                        color: isSelected ? Colors.blue : Colors.grey,
                        width: isSelected ? 2 : 1,
                      ),
                      flutter.Border.all(
                        color: isSelected ? Colors.blue : Colors.grey,
                        width: isSelected ? 2 : 1,
                      ),
                      1.0,
                    ),
                    borderRadius: flutter.BorderRadius.circular(4),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _getShapeIcon(shape),
                      const SizedBox(height: 4),
                      Text(
                        _getShapeName(shape),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Shows a line style selector dialog
  void _showLineStyleSelector(
      BuildContext context,
      structurizr_style.LineStyle currentStyle,
      ValueChanged<structurizr_style.LineStyle> onStyleSelected) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Line Style'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: structurizr_style.LineStyle.values.map((style) {
            final isSelected = style == currentStyle;
            return ListTile(
              leading: _getLineStyleIcon(style),
              title: Text(_getLineStyleName(style)),
              selected: isSelected,
              onTap: () {
                Navigator.of(context).pop();
                onStyleSelected(style);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Shows a border style selector dialog
  void _showBorderStyleSelector(
      BuildContext context,
      BorderStyleOption currentStyle,
      ValueChanged<BorderStyleOption> onStyleSelected) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Border Style'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: BorderStyleOption.values.map((style) {
            final isSelected = style == currentStyle;
            return ListTile(
              leading: _getBorderStyleIcon(style),
              title: Text(_getBorderStyleName(style)),
              selected: isSelected,
              onTap: () {
                Navigator.of(context).pop();
                onStyleSelected(style);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Shows a routing selector dialog
  void _showRoutingSelector(
      BuildContext context,
      structurizr_style.StyleRouting currentRouting,
      ValueChanged<structurizr_style.StyleRouting> onRoutingSelected) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Routing'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: structurizr_style.StyleRouting.values.map((routing) {
            final isSelected = routing == currentRouting;
            return ListTile(
              leading: _getRoutingIcon(routing),
              title: Text(_getRoutingName(routing)),
              selected: isSelected,
              onTap: () {
                Navigator.of(context).pop();
                onRoutingSelected(routing);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Shows a font size dialog
  void _showFontSizeDialog(BuildContext context, int? currentSize,
      ValueChanged<int?> onSizeSelected) {
    final textController =
        TextEditingController(text: currentSize?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Font Size'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Font Size (px)',
            hintText: 'Leave empty for default',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
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
              final text = textController.text.trim();
              if (text.isEmpty) {
                onSizeSelected(null);
              } else {
                final size = int.tryParse(text);
                if (size != null && size > 0) {
                  onSizeSelected(size);
                }
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  /// Shows a size editing dialog
  void _showSizeDialog(BuildContext context, int? currentWidth,
      int? currentHeight, Function(int?, int?) onSizeSelected) {
    final widthController =
        TextEditingController(text: currentWidth?.toString() ?? '');
    final heightController =
        TextEditingController(text: currentHeight?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: widthController,
              decoration: const InputDecoration(
                labelText: 'Width (px)',
                hintText: 'Leave empty for auto',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: heightController,
              decoration: const InputDecoration(
                labelText: 'Height (px)',
                hintText: 'Leave empty for auto',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
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

              final widthText = widthController.text.trim();
              final heightText = heightController.text.trim();

              final width = widthText.isEmpty ? null : int.tryParse(widthText);
              final height =
                  heightText.isEmpty ? null : int.tryParse(heightText);

              onSizeSelected(width, height);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  /// Shows a stroke width dialog
  void _showStrokeWidthDialog(BuildContext context, int currentWidth,
      ValueChanged<int> onWidthSelected) {
    int width = currentWidth;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Set Border Width'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${width}px', style: const TextStyle(fontSize: 16)),
                Slider(
                  value: width.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  onChanged: (value) {
                    setState(() {
                      width = value.round();
                    });
                  },
                ),
              ],
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
                  onWidthSelected(width);
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Shows a thickness dialog
  void _showThicknessDialog(BuildContext context, int currentThickness,
      ValueChanged<int> onThicknessSelected) {
    int thickness = currentThickness;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Set Line Thickness'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${thickness}px', style: const TextStyle(fontSize: 16)),
                Slider(
                  value: thickness.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  onChanged: (value) {
                    setState(() {
                      thickness = value.round();
                    });
                  },
                ),
              ],
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
                  onThicknessSelected(thickness);
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Shows a label width dialog
  void _showLabelWidthDialog(BuildContext context, int? currentWidth,
      ValueChanged<int?> onWidthSelected) {
    final textController =
        TextEditingController(text: currentWidth?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Label Width'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Width (px)',
            hintText: 'Leave empty for auto',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
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
              final text = textController.text.trim();
              if (text.isEmpty) {
                onWidthSelected(null);
              } else {
                final width = int.tryParse(text);
                if (width != null && width > 0) {
                  onWidthSelected(width);
                }
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  /// Shows a dialog for setting an icon
  void _showIconDialog(BuildContext context, String? currentIcon,
      ValueChanged<String?> onIconSelected) {
    final textController = TextEditingController(text: currentIcon ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Icon'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                labelText: 'Icon Path or URL',
                hintText: 'Enter path to icon or URL',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            const Text(
              'Provide a URL to an image or a path to a local asset.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onIconSelected(null);
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              final text = textController.text.trim();
              if (text.isNotEmpty) {
                onIconSelected(text);
              } else {
                onIconSelected(null);
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  // ===== Helper methods for UI elements =====

  /// Gets a shape icon based on the shape type
  Widget _getShapeIcon(structurizr_style.Shape shape) {
    switch (shape) {
      case structurizr_style.Shape.box:
        return flutter.Container(
          width: 24,
          height: 24,
          color: Colors.grey.shade300,
        );
      case structurizr_style.Shape.roundedBox:
        return flutter.Container(
          width: 24,
          height: 24,
          decoration: flutter.BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: flutter.BorderRadius.circular(6),
          ),
        );
      case structurizr_style.Shape.circle:
        return flutter.Container(
          width: 24,
          height: 24,
          decoration: flutter.BoxDecoration(
            color: Colors.grey.shade300,
            shape: flutter.BoxShape.circle,
          ),
        );
      case structurizr_style.Shape.ellipse:
        return flutter.Container(
          width: 24,
          height: 18,
          decoration: flutter.BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: flutter.BorderRadius.circular(12),
          ),
        );
      case structurizr_style.Shape.hexagon:
        return const Icon(Icons.hexagon, size: 24);
      case structurizr_style.Shape.cylinder:
        return const Icon(Icons.panorama_vertical, size: 24);
      case structurizr_style.Shape.pipe:
        return const Icon(Icons.priority_high, size: 24);
      case structurizr_style.Shape.person:
        return const Icon(Icons.person, size: 24);
      case structurizr_style.Shape.robot:
        return const Icon(Icons.smart_toy, size: 24);
      case structurizr_style.Shape.folder:
        return const Icon(Icons.folder, size: 24);
      case structurizr_style.Shape.webBrowser:
        return const Icon(Icons.web, size: 24);
      case structurizr_style.Shape.mobileDevicePortrait:
        return const Icon(Icons.smartphone, size: 24);
      case structurizr_style.Shape.mobileDeviceLandscape:
        return const Icon(Icons.smartphone, size: 24);
      case structurizr_style.Shape.component:
        return const Icon(Icons.settings, size: 24);
      default:
        return const Icon(Icons.square, size: 24);
    }
  }

  /// Gets a line style icon based on the style type
  Widget _getLineStyleIcon(structurizr_style.LineStyle style) {
    switch (style) {
      case structurizr_style.LineStyle.solid:
        return flutter.Container(
          width: 30,
          height: 2,
          color: Colors.black,
        );
      case structurizr_style.LineStyle.dashed:
        return CustomPaint(
          size: const Size(30, 2),
          painter: DashedLinePainter(),
        );
      case structurizr_style.LineStyle.dotted:
        return CustomPaint(
          size: const Size(30, 2),
          painter: DottedLinePainter(),
        );
      default:
        return flutter.Container(
          width: 30,
          height: 2,
          color: Colors.black,
        );
    }
  }

  /// Gets a border style icon based on the style type
  Widget _getBorderStyleIcon(BorderStyleOption style) {
    switch (style) {
      case BorderStyleOption.solid:
        return flutter.Container(
          width: 24,
          height: 24,
          decoration: flutter.BoxDecoration(
            border: flutter.BoxBorder.lerp(
              flutter.Border.all(color: Colors.black),
              flutter.Border.all(color: Colors.black),
              1.0,
            ),
            borderRadius: flutter.BorderRadius.circular(4),
          ),
        );
      case BorderStyleOption.dashed:
        return flutter.Container(
          width: 24,
          height: 24,
          decoration: flutter.BoxDecoration(
            border: flutter.BoxBorder.lerp(
              flutter.Border.all(color: Colors.black),
              flutter.Border.all(color: Colors.black),
              1.0,
            ),
            borderRadius: flutter.BorderRadius.circular(4),
          ),
        );
      case BorderStyleOption.dotted:
        return flutter.Container(
          width: 24,
          height: 24,
          decoration: flutter.BoxDecoration(
            border: flutter.BoxBorder.lerp(
              flutter.Border.all(color: Colors.black),
              flutter.Border.all(color: Colors.black),
              1.0,
            ),
            borderRadius: flutter.BorderRadius.circular(4),
          ),
        );
      default:
        return flutter.Container(
          width: 24,
          height: 24,
          decoration: flutter.BoxDecoration(
            border: flutter.BoxBorder.lerp(
              flutter.Border.all(color: Colors.black),
              flutter.Border.all(color: Colors.black),
              1.0,
            ),
            borderRadius: flutter.BorderRadius.circular(4),
          ),
        );
    }
  }

  /// Gets a routing icon based on the routing type
  Widget _getRoutingIcon(structurizr_style.StyleRouting routing) {
    switch (routing) {
      case structurizr_style.StyleRouting.direct:
        return const Icon(Icons.arrow_forward);
      case structurizr_style.StyleRouting.orthogonal:
        return CustomPaint(
          size: const Size(24, 24),
          painter: OrthogonalRoutingPainter(),
        );
      case structurizr_style.StyleRouting.curved:
        return CustomPaint(
          size: const Size(24, 24),
          painter: CurvedRoutingPainter(),
        );
      default:
        return const Icon(Icons.arrow_forward);
    }
  }

  /// Gets a shape name from a Shape enum value
  String _getShapeName(structurizr_style.Shape shape) {
    return shape.toString().split('.').last;
  }

  /// Gets a line style name from a LineStyle enum value
  String _getLineStyleName(structurizr_style.LineStyle style) {
    return style.toString().split('.').last;
  }

  /// Gets a border style name from a Border enum value
  String _getBorderStyleName(BorderStyleOption style) {
    return style.toString().split('.').last;
  }

  /// Gets a routing name from a StyleRouting enum value
  String _getRoutingName(structurizr_style.StyleRouting routing) {
    return routing.toString().split('.').last;
  }

  // ===== Helper methods for border and line style mapping =====
  BorderStyleOption mapInternalBorderToOption(dynamic border) {
    // TODO: Map internal border representation to BorderStyleOption
    // For now, just return solid as a placeholder
    return BorderStyleOption.solid;
  }

  String mapOptionToInternalBorder(BorderStyleOption option) {
    // TODO: Map BorderStyleOption to internal border string
    // For now, just return 'solid' as a placeholder
    return 'solid';
  }
}
