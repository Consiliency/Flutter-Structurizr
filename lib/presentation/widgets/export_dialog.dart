import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Element, Container, View, Border;
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/view/model_view.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/infrastructure/export/diagram_exporter.dart';
import 'package:flutter_structurizr/infrastructure/export/export_manager.dart';
import 'package:flutter_structurizr/infrastructure/export/mermaid_exporter.dart';
import 'package:flutter_structurizr/infrastructure/export/plantuml_exporter.dart';
import 'package:flutter_structurizr/infrastructure/export/png_exporter.dart';
import 'package:flutter_structurizr/infrastructure/export/svg_exporter.dart';
import 'package:flutter_structurizr/infrastructure/export/dot_exporter.dart';
import 'package:flutter_structurizr/infrastructure/export/dsl_exporter.dart';
import 'package:flutter_structurizr/infrastructure/persistence/file_storage.dart';

/// The available formats for export
enum ExportFormat {
  png('PNG Image', 'png'),
  svg('SVG Image', 'svg'),
  plantuml('PlantUML', 'puml'),
  mermaid('Mermaid', 'mmd'),
  dot('DOT/Graphviz', 'dot'),
  dsl('Structurizr DSL', 'dsl');

  final String displayName;
  final String extension;
  
  const ExportFormat(this.displayName, this.extension);
}

/// Dialog for exporting diagrams to various formats
class ExportDialog extends StatefulWidget {
  /// The workspace containing the diagrams to export
  final Workspace workspace;
  
  /// Currently selected view
  final ModelView? currentView;
  
  /// On export complete callback - receives the exported data
  final void Function(Uint8List, String)? onExportComplete;
  
  /// Dialog title
  final String title;
  
  /// Creates a new export dialog
  const ExportDialog({
    super.key,
    required this.workspace,
    this.currentView,
    this.onExportComplete,
    this.title = 'Export Diagram',
  });

  /// Shows the export dialog
  static Future<void> show({
    required BuildContext context,
    required Workspace workspace,
    ModelView? currentView,
    void Function(Uint8List, String)? onExportComplete,
    String title = 'Export Diagram',
  }) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return ExportDialog(
          workspace: workspace,
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
  ExportFormat _selectedFormat = ExportFormat.png;
  ModelView? _selectedView;
  
  bool _includeTitle = true;
  bool _includeLegend = true;
  bool _includeMetadata = true;
  bool _transparent = false;
  double _width = 1920;
  double _height = 1080;
  double _scale = 1.0;
  
  bool _isExporting = false;
  double _exportProgress = 0.0;
  String _errorMessage = '';
  
  Uint8List? _previewData;
  bool _showPreview = true;
  bool _isGeneratingPreview = false;
  String _previewFormat = 'png';
  late Timer _debounceTimer;
  
  final ExportManager _exportManager = ExportManager();
  
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
        _exportProgress = 0.0;
        _errorMessage = '';
      });
      
      // Determine the format based on selected export format
      _previewFormat = _selectedFormat == ExportFormat.svg ? 'svg' : 'png';
      
      final diagramRef = DiagramReference(
        workspace: widget.workspace,
        viewKey: _selectedView!.key,
      );
      
      // Create render parameters
      final renderParams = DiagramRenderParameters(
        width: 400, // Small preview size
        height: 400 * _height / _width, // Maintain aspect ratio
        includeLegend: _includeLegend,
        includeTitle: _includeTitle,
        includeMetadata: _includeMetadata,
        elementScaleFactor: _scale,
        includeElementNames: true,
        includeElementDescriptions: false,
        includeRelationshipDescriptions: true,
      );
      
      // Configure progress callback
      final progressCallback = (double progress) {
        setState(() {
          _exportProgress = progress;
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
        });
      } else {
        // Use PNG exporter
        final exporter = PngExporter(
          renderParameters: renderParams,
          transparentBackground: _transparent,
          scaleFactor: 1.0, // Lower scale factor for preview
          onProgress: progressCallback,
        );
        
        final previewData = await exporter.export(diagramRef);
        
        setState(() {
          _previewData = previewData;
          _isGeneratingPreview = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to generate preview: $e';
        _isGeneratingPreview = false;
      });
    }
  }
  
  /// Exports the diagram to the selected format
  Future<void> _exportDiagram() async {
    if (_selectedView == null) {
      setState(() {
        _errorMessage = 'No view selected for export';
      });
      return;
    }
    
    try {
      setState(() {
        _isExporting = true;
        _exportProgress = 0.0;
        _errorMessage = '';
      });
      
      // Create exporter based on selected format
      final diagramRef = DiagramReference(
        workspace: widget.workspace,
        viewKey: _selectedView!.key,
      );
      
      // Create render parameters
      final renderParams = DiagramRenderParameters(
        width: _width,
        height: _height,
        includeLegend: _includeLegend,
        includeTitle: _includeTitle,
        includeMetadata: _includeMetadata,
        elementScaleFactor: _scale,
      );
      
      // Export the diagram
      dynamic exportedData;
      
      // Progress callback for the export operation
      final progressCallback = (double progress) {
        setState(() {
          _exportProgress = progress;
        });
      };
      
      switch (_selectedFormat) {
        case ExportFormat.png:
          final exporter = PngExporter(
            renderParameters: renderParams,
            transparentBackground: _transparent,
            scaleFactor: 2.0, // High quality for final export
            onProgress: progressCallback,
          );
          exportedData = await exporter.export(diagramRef);
          break;
          
        case ExportFormat.svg:
          final exporter = SvgExporter(
            renderParameters: renderParams,
            includeCss: true,
            interactive: true,
            onProgress: progressCallback,
          );
          final svgString = await exporter.export(diagramRef);
          exportedData = Uint8List.fromList(svgString.codeUnits);
          break;
          
        case ExportFormat.plantuml:
          final exporter = PlantUmlExporter(
            includeLegend: _includeLegend,
            includeMetadata: _includeMetadata,
            onProgress: progressCallback,
          );
          final pumlString = await exporter.export(diagramRef);
          exportedData = Uint8List.fromList(pumlString.codeUnits);
          break;
          
        case ExportFormat.mermaid:
          final exporter = MermaidExporter(
            includeLegend: _includeLegend,
            includeMetadata: _includeMetadata,
            onProgress: progressCallback,
          );
          final mmdString = await exporter.export(diagramRef);
          exportedData = Uint8List.fromList(mmdString.codeUnits);
          break;
          
        case ExportFormat.dot:
          final exporter = DotExporter(
            includeLegend: _includeLegend,
            includeMetadata: _includeMetadata,
            onProgress: progressCallback,
          );
          final dotString = await exporter.export(diagramRef);
          exportedData = Uint8List.fromList(dotString.codeUnits);
          break;
          
        case ExportFormat.dsl:
          final exporter = DslExporter(
            includeMetadata: _includeMetadata,
            includeDocumentation: true,
            includeStyles: true,
            includeViews: true,
            onProgress: progressCallback,
          );
          final dslString = await exporter.export(diagramRef);
          exportedData = Uint8List.fromList(dslString.codeUnits);
          break;
      }
      
      // Generate a filename
      final filename = '${_selectedView!.key}.${_selectedFormat.extension}';
      
      // Call the onExportComplete callback if provided
      if (widget.onExportComplete != null && exportedData != null) {
        widget.onExportComplete!(exportedData, filename);
      }
      
      // Save the exported data to file
      if (kIsWeb) {
        // Web download handler would go here
        // We'll need to implement file download for web
      } else {
        // Native platforms - use FileStorage to save
        await _saveToFile(exportedData, filename);
      }
      
      setState(() {
        _isExporting = false;
      });
      
      // Close the dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Export failed: $e';
        _isExporting = false;
      });
    }
  }
  
  /// Saves the exported data to a file
  Future<void> _saveToFile(Uint8List data, String filename) async {
    try {
      // Use FileStorage to save the file
      final storage = FileStorage();
      final path = await storage.saveExportedDiagram(data, filename);
      
      // Show a success snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to $path'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save file: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Text(widget.title),
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
                  child: _buildExportOptions(),
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
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
              
            // Progress indicator
            if (_isExporting)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(value: _exportProgress),
                    const SizedBox(height: 4),
                    Text(
                      'Exporting... ${(_exportProgress * 100).toInt()}%',
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
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isExporting || _selectedView == null ? null : _exportDiagram,
          child: const Text('Export'),
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
              final viewType = view.runtimeType.toString().replaceAll('View', '');
              
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
              _generatePreview();
            },
          ),
        ),
      ],
    );
  }
  
  /// Builds the export options panel
  Widget _buildExportOptions() {
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
              children: ExportFormat.values.map((format) {
                return ChoiceChip(
                  label: Text(format.displayName),
                  selected: _selectedFormat == format,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedFormat = format;
                      });
                      _generatePreviewDebounced();
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            
            // Format-specific options
            if (_selectedFormat == ExportFormat.png || _selectedFormat == ExportFormat.svg) ...[
              // Size controls
              Row(
                children: [
                  const Text('Width:'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Slider(
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
                  ),
                  SizedBox(
                    width: 60,
                    child: Text('${_width.toInt()}px'),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('Height:'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Slider(
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
                  ),
                  SizedBox(
                    width: 60,
                    child: Text('${_height.toInt()}px'),
                  ),
                ],
              ),
              
              // Scale control
              Row(
                children: [
                  const Text('Scale:'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Slider(
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
                  ),
                  SizedBox(
                    width: 60,
                    child: Text('${_scale.toStringAsFixed(1)}x'),
                  ),
                ],
              ),
              
              if (_selectedFormat == ExportFormat.png)
                CheckboxListTile(
                  title: const Text('Transparent Background'),
                  value: _transparent,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (value) {
                    setState(() {
                      _transparent = value ?? false;
                    });
                    _generatePreviewDebounced();
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
            if (_selectedFormat == ExportFormat.png || _selectedFormat == ExportFormat.svg)
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
        (_selectedFormat == ExportFormat.png || _selectedFormat == ExportFormat.svg);
        
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
                    
                    if (_isExporting || _isGeneratingPreview) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 12),
                            Text(
                              _isExporting 
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
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          color: _transparent 
                              ? null 
                              : Colors.white,
                          image: _transparent 
                              ? const DecorationImage(
                                  image: AssetImage('assets/images/transparent_background.png'),
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
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          color: _transparent 
                              ? null 
                              : Colors.white,
                          image: _transparent 
                              ? const DecorationImage(
                                  image: AssetImage('assets/images/transparent_background.png'),
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
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
    
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'SVG Preview',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
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
    final regex = RegExp('<svg[^>]*$attribute="([^"]*)');
    final match = regex.firstMatch(svg);
    return match?.group(1) ?? 'Unknown';
  }
  
  /// Counts elements in the SVG document
  int _countElements(String svg) {
    final regex = RegExp('<(?!\/|\?|!)[a-zA-Z][^>]*>');
    final matches = regex.allMatches(svg);
    return matches.length;
  }
}