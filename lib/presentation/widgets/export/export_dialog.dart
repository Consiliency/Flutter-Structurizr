import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' hide Element, Container, View;
import 'package:flutter/foundation.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/view/model_view.dart';
import 'package:flutter_structurizr/infrastructure/export/rendering_pipeline.dart';
import 'package:flutter_structurizr/infrastructure/export/export_manager.dart';
import 'package:flutter_structurizr/infrastructure/export/png_exporter.dart';
import 'package:flutter_structurizr/infrastructure/export/svg_exporter.dart';
import 'package:flutter/material.dart' as flutter;
import 'package:flutter_structurizr/infrastructure/export/diagram_exporter.dart'
    show DiagramReference;

/// A dialog for exporting a diagram to various formats
class ExportDialog extends StatefulWidget {
  /// The workspace containing the diagram
  final Workspace workspace;

  /// The key of the view to export
  final String viewKey;

  /// Currently selected view
  final ModelView? currentView;

  /// On export complete callback - receives the exported data
  final void Function(Uint8List, String)? onExportComplete;

  /// Title for the exported diagram (optional)
  final String? title;

  /// Creates a new export dialog
  const ExportDialog({
    Key? key,
    required this.workspace,
    required this.viewKey,
    this.currentView,
    this.onExportComplete,
    this.title,
  }) : super(key: key);

  /// Shows the export dialog
  static Future<void> show({
    required BuildContext context,
    required Workspace workspace,
    required String viewKey,
    ModelView? currentView,
    void Function(Uint8List, String)? onExportComplete,
    String? title,
  }) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return ExportDialog(
          workspace: workspace,
          viewKey: viewKey,
          currentView: currentView,
          onExportComplete: onExportComplete,
          title: title,
        );
      },
    );
  }

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  // Selected export format
  ExportFormat _selectedFormat = ExportFormat.png;
  ModelView? _selectedView;

  // Export options
  double _width = 1920;
  double _height = 1080;
  double _scale = 1.0;
  bool _includeLegend = true;
  bool _includeTitle = true;
  bool _includeMetadata = true;
  bool _transparentBackground = false;
  Color _backgroundColor = Colors.white;
  bool _useMemoryEfficientRendering = true;

  // Preview options
  bool _showPreview = true;
  Uint8List? _previewData;
  bool _isGeneratingPreview = false;
  String _previewFormat = 'png';
  late Timer _debounceTimer;

  // Export progress
  bool _exporting = false;
  double _progress = 0.0;
  String? _progressMessage;
  String? _error;

  // Export manager
  final _exportManager = ExportManager();

  @override
  void initState() {
    super.initState();
    // Initialize with the current view if provided
    _selectedView = widget.currentView;

    // Generate a preview if possible
    _generatePreview();

    // Set up a debouncer for preview updates
    _debounceTimer = Timer(Duration.zero, () {});
  }

  @override
  void dispose() {
    _debounceTimer.cancel();
    super.dispose();
  }

  /// Generates a preview of the export with debounce
  void _generatePreviewDebounced() {
    // Cancel existing timer
    _debounceTimer.cancel();

    // Set a new timer to generate preview after delay
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _generatePreview();
    });
  }

  /// Generates a preview of the export
  Future<void> _generatePreview() async {
    if (_selectedView == null || !_showPreview) return;
    if (_isGeneratingPreview) return; // Prevent concurrent generations

    try {
      setState(() {
        _isGeneratingPreview = true;
        _progress = 0.0;
        _error = null;
      });

      // Determine the format based on selected export format
      _previewFormat = _selectedFormat == ExportFormat.svg ? 'svg' : 'png';

      final diagramRef = DiagramReference(
        workspace: widget.workspace,
        viewKey: widget.viewKey,
      );

      // Create render parameters
      final renderParams = DiagramRenderParameters(
        width: 400, // Small preview size
        height: 400 * _height / _width, // Maintain aspect ratio
        includeLegend: _includeLegend,
        includeTitle: _includeTitle,
        includeMetadata: _includeMetadata,
        backgroundColor:
            _transparentBackground ? Colors.transparent : _backgroundColor,
        includeElementNames: true,
        includeElementDescriptions: false,
        includeRelationshipDescriptions: true,
        elementScaleFactor: _scale,
      );

      // Configure progress callback
      final progressCallback = (double progress) {
        setState(() {
          _progress = progress;
          _progressMessage =
              'Generating preview... ${(progress * 100).toInt()}%';
        });
      };

      // Generate the preview based on format
      if (_previewFormat == 'svg') {
        final exporter = SvgExporter(
          renderParameters: renderParams,
          includeCss: true,
          interactive: false, // Non-interactive for preview
          onProgress: progressCallback,
        );

        final svgString = await exporter.export(diagramRef);
        setState(() {
          _previewData = Uint8List.fromList(svgString.codeUnits);
          _isGeneratingPreview = false;
          _progressMessage = null;
        });
      } else {
        // Use PNG exporter
        final exporter = PngExporter(
          renderParameters: renderParams,
          transparentBackground: _transparentBackground,
          onProgress: progressCallback,
        );

        final previewData = await exporter.export(diagramRef);

        setState(() {
          _previewData = previewData;
          _isGeneratingPreview = false;
          _progressMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to generate preview: $e';
        _isGeneratingPreview = false;
        _progressMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return AlertDialog(
      title: const Text('Export Diagram'),
      content: SizedBox(
        width: 600,
        height: 600,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildViewSelector(),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column: export options
                Expanded(
                  flex: 3,
                  child: _buildExportOptions(isDarkMode),
                ),

                const SizedBox(width: 16),

                // Right column: preview
                Expanded(
                  flex: 4,
                  child: _buildPreview(),
                ),
              ],
            ),

            // Error message
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),

            // Progress indicator
            if (_exporting || _isGeneratingPreview)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(value: _progress),
                    const SizedBox(height: 4),
                    Text(
                      _progressMessage ?? 'Processing...',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _exporting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _exporting || _selectedView == null ? null : _export,
          child: _exporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Export'),
        ),
      ],
    );
  }

  /// Builds the view selector dropdown
  Widget _buildViewSelector() {
    final views = <ModelView>[];

    // Collect all views from the workspace
    views.addAll(widget.workspace.views.systemLandscapeViews);
    views.addAll(widget.workspace.views.systemContextViews);
    views.addAll(widget.workspace.views.containerViews);
    views.addAll(widget.workspace.views.componentViews);
    views.addAll(widget.workspace.views.deploymentViews);
    views.addAll(widget.workspace.views.dynamicViews);
    views.addAll(widget.workspace.views.filteredViews);

    return Row(
      children: [
        const Text('View:'),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<ModelView>(
            value: _selectedView,
            isExpanded: true,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(),
            ),
            items: views.map((view) {
              final displayName = view.title ?? view.key;
              final viewType =
                  view.runtimeType.toString().replaceAll('View', '');

              return DropdownMenuItem<ModelView>(
                value: view,
                child: Text('$displayName ($viewType)'),
              );
            }).toList(),
            onChanged: (ModelView? newValue) {
              setState(() {
                _selectedView = newValue;
              });

              // Generate a new preview
              _generatePreviewDebounced();
            },
          ),
        ),
      ],
    );
  }

  /// Builds the export options panel
  Widget _buildExportOptions(bool isDarkMode) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Export Options',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Format selector
            const Text('Format:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('PNG Image'),
                  selected: _selectedFormat == ExportFormat.png,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedFormat = ExportFormat.png;
                      });
                      _generatePreviewDebounced();
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('SVG Image'),
                  selected: _selectedFormat == ExportFormat.svg,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedFormat = ExportFormat.svg;
                      });
                      _generatePreviewDebounced();
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('PlantUML'),
                  selected: _selectedFormat == ExportFormat.plantuml,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedFormat = ExportFormat.plantuml;
                      });
                      _generatePreviewDebounced();
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('Mermaid'),
                  selected: _selectedFormat == ExportFormat.mermaid,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedFormat = ExportFormat.mermaid;
                      });
                      _generatePreviewDebounced();
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('DOT/Graphviz'),
                  selected: _selectedFormat == ExportFormat.dot,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedFormat = ExportFormat.dot;
                      });
                      _generatePreviewDebounced();
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('DSL'),
                  selected: _selectedFormat == ExportFormat.dsl,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedFormat = ExportFormat.dsl;
                      });
                      _generatePreviewDebounced();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Format-specific options
            if (_selectedFormat == ExportFormat.png ||
                _selectedFormat == ExportFormat.svg) ...[
              // Size controls
              Text('Width: ${_width.toInt()}px'),
              Slider(
                value: _width,
                min: 800,
                max: 3840,
                divisions: 12,
                label: '${_width.toInt()}px',
                onChanged: (value) {
                  setState(() {
                    _width = value;
                  });
                  _generatePreviewDebounced();
                },
              ),
              Text('Height: ${_height.toInt()}px'),
              Slider(
                value: _height,
                min: 600,
                max: 2160,
                divisions: 8,
                label: '${_height.toInt()}px',
                onChanged: (value) {
                  setState(() {
                    _height = value;
                  });
                  _generatePreviewDebounced();
                },
              ),

              // Scale control
              Text('Scale: ${_scale.toStringAsFixed(1)}x'),
              Slider(
                value: _scale,
                min: 0.5,
                max: 2.0,
                divisions: 6,
                label: '${_scale.toStringAsFixed(1)}x',
                onChanged: (value) {
                  setState(() {
                    _scale = value;
                  });
                  _generatePreviewDebounced();
                },
              ),

              if (_selectedFormat == ExportFormat.png)
                CheckboxListTile(
                  title: const Text('Transparent Background'),
                  value: _transparentBackground,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (value) {
                    setState(() {
                      _transparentBackground = value ?? false;
                    });
                    _generatePreviewDebounced();
                  },
                ),

              CheckboxListTile(
                title: const Text('Memory-Efficient Rendering'),
                subtitle: const Text('For large diagrams'),
                value: _useMemoryEfficientRendering,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (value) {
                  setState(() {
                    _useMemoryEfficientRendering = value ?? true;
                  });
                },
              ),
            ],

            // Common options
            CheckboxListTile(
              title: const Text('Include Title'),
              value: _includeTitle,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (value) {
                setState(() {
                  _includeTitle = value ?? true;
                });
                _generatePreviewDebounced();
              },
            ),
            CheckboxListTile(
              title: const Text('Include Legend'),
              value: _includeLegend,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (value) {
                setState(() {
                  _includeLegend = value ?? true;
                });
                _generatePreviewDebounced();
              },
            ),
            CheckboxListTile(
              title: const Text('Include Metadata'),
              value: _includeMetadata,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (value) {
                setState(() {
                  _includeMetadata = value ?? true;
                });
                _generatePreviewDebounced();
              },
            ),

            // Preview options
            if (_selectedFormat == ExportFormat.png ||
                _selectedFormat == ExportFormat.svg)
              CheckboxListTile(
                title: const Text('Show Preview'),
                value: _showPreview,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (value) {
                  setState(() {
                    _showPreview = value ?? true;
                  });
                  if (_showPreview) {
                    _generatePreviewDebounced();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Builds the preview panel
  Widget _buildPreview() {
    final showablePreview = _showPreview &&
        (_selectedFormat == ExportFormat.png ||
            _selectedFormat == ExportFormat.svg);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Builder(
                  builder: (context) {
                    if (!showablePreview) {
                      return const Center(
                        child: Text(
                          'Preview not available for this format',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    if (_selectedView == null) {
                      return const Center(
                        child: Text(
                          'Select a view to preview',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    if (_exporting || _isGeneratingPreview) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 12),
                            Text(
                              _exporting
                                  ? 'Exporting...'
                                  : 'Generating preview...',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      );
                    }

                    if (_previewData == null) {
                      return Center(
                        child: TextButton.icon(
                          onPressed: () => _generatePreview(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Generate Preview'),
                        ),
                      );
                    }

                    // Display the preview based on format
                    if (_previewFormat == 'svg' && _previewData != null) {
                      // For SVG, we show an image widget with the SVG data
                      return flutter.Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          color: _transparentBackground ? null : Colors.white,
                          image: _transparentBackground
                              ? const DecorationImage(
                                  image: AssetImage(
                                      'assets/images/transparent_background.png'),
                                  repeat: ImageRepeat.repeat,
                                )
                              : null,
                        ),
                        child: SvgPreviewWidget(
                          svgData: String.fromCharCodes(_previewData!),
                        ),
                      );
                    } else if (_previewData != null) {
                      // For PNG, we show a standard image
                      return flutter.Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          color: _transparentBackground ? null : Colors.white,
                          image: _transparentBackground
                              ? const DecorationImage(
                                  image: AssetImage(
                                      'assets/images/transparent_background.png'),
                                  repeat: ImageRepeat.repeat,
                                )
                              : null,
                        ),
                        child: Image.memory(
                          _previewData!,
                          fit: BoxFit.contain,
                        ),
                      );
                    }

                    return const SizedBox();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a color picker dialog for background color selection
  void _showColorPicker() {
    // Show a simplified color picker
    // In a real implementation, you might use a third-party color picker package
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Background Color'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _colorButton(Colors.white),
              _colorButton(Colors.grey.shade100),
              _colorButton(Colors.grey.shade200),
              _colorButton(Colors.blue.shade50),
              _colorButton(Colors.green.shade50),
              _colorButton(Colors.yellow.shade50),
              _colorButton(Colors.orange.shade50),
              _colorButton(Colors.red.shade50),
              _colorButton(Colors.purple.shade50),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _colorButton(Color color) {
    return InkWell(
      onTap: () {
        setState(() {
          _backgroundColor = color;
        });
        Navigator.of(context).pop();
      },
      child: flutter.Container(
        width: 100,
        height: 30,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  /// Exports the diagram with the selected options
  Future<void> _export() async {
    setState(() {
      _exporting = true;
      _progress = 0.0;
      _progressMessage = 'Preparing export...';
      _error = null;
    });

    try {
      // Configure export options
      final options = ExportOptions(
        format: _selectedFormat,
        width: _width,
        height: _height,
        includeLegend: _includeLegend,
        includeTitle: _includeTitle,
        includeMetadata: _includeMetadata,
        backgroundColor: _backgroundColor,
        transparentBackground: _transparentBackground,
        useMemoryEfficientRendering: _useMemoryEfficientRendering,
        onProgress: (progress) {
          setState(() {
            _progress = progress;
            _progressMessage =
                'Exporting diagram... ${(progress * 100).toStringAsFixed(0)}%';
          });
        },
      );

      // Export the diagram
      final result = await _exportManager.exportDiagram(
        workspace: widget.workspace,
        viewKey: widget.viewKey,
        options: options,
        title: widget.title,
      );

      // Get save location from user
      final extension = _getFileExtension(_selectedFormat);
      final defaultFileName = widget.title != null
          ? '${widget.title}.$extension'
          : '${widget.workspace.name}_${widget.viewKey}.$extension';

      setState(() {
        _progressMessage = 'Saving file...';
      });

      if (kIsWeb) {
        // Web download handling would go here
        // Not implementing web download in this version
      } else {
        final savePath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Export',
          fileName: defaultFileName,
          type: FileType.custom,
          allowedExtensions: [extension],
        );

        if (savePath != null) {
          // Save the result to the selected file
          final file = File(savePath);

          if (_selectedFormat == ExportFormat.png) {
            // Binary data
            await file.writeAsBytes(result as List<int>);
          } else {
            // Text data
            await file.writeAsString(result as String);
          }

          if (mounted) {
            Navigator.of(context).pop(true);
          }
        } else {
          // User cancelled save dialog
          setState(() {
            _exporting = false;
            _progressMessage = null;
          });
        }
      }
    } catch (e) {
      setState(() {
        _exporting = false;
        _error = 'Error exporting diagram: $e';
        _progressMessage = null;
      });
    }
  }

  /// Gets the appropriate file extension for the selected format
  String _getFileExtension(ExportFormat format) {
    switch (format) {
      case ExportFormat.png:
        return 'png';
      case ExportFormat.svg:
        return 'svg';
      case ExportFormat.plantuml:
      case ExportFormat.c4plantuml:
        return 'puml';
      case ExportFormat.mermaid:
      case ExportFormat.c4mermaid:
        return 'mmd';
      case ExportFormat.dot:
        return 'dot';
      case ExportFormat.dsl:
        return 'dsl';
      default:
        return 'txt';
    }
  }
}

/// Widget to display SVG preview
class SvgPreviewWidget extends StatelessWidget {
  /// SVG data to display
  final String svgData;

  /// Creates a new SVG preview widget
  const SvgPreviewWidget({Key? key, required this.svgData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // We're using a basic approach here for simplicity
    // A full implementation would use a proper SVG rendering package like flutter_svg

    // Extract some basic info from the SVG for display
    final width = _extractAttribute(svgData, 'width');
    final height = _extractAttribute(svgData, 'height');
    final elementCount = _countElements(svgData);

    return flutter.Container(
      color: Colors.white,
      child: flutter.Center(
        child: flutter.Column(
          mainAxisSize: flutter.MainAxisSize.min,
          children: [
            Icon(
              Icons.image,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            const flutter.SizedBox(height: 16),
            Text(
              'SVG Preview',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const flutter.SizedBox(height: 8),
            Text(
              'Size: ${width}×${height}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Elements: $elementCount',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'SVG Size: ${(svgData.length / 1024).toStringAsFixed(1)} KB',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  /// Extracts an attribute value from SVG markup
  String _extractAttribute(String svg, String attribute) {
    final regex = RegExp('<svg[^>]*$attribute=\"([^\"]*)');
    final match = regex.firstMatch(svg);
    return match?.group(1) ?? 'Unknown';
  }

  /// Counts elements in the SVG document
  int _countElements(String svg) {
    final regex = RegExp('<(?!\\/|\\?|!)[a-zA-Z][^>]*>');
    final matches = regex.allMatches(svg);
    return matches.length;
  }
}
