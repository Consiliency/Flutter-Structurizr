import 'dart:typed_data';

import 'package:flutter/material.dart' hide Element, Container, View, Border;
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/view/model_view.dart';
import 'package:flutter_structurizr/infrastructure/export/diagram_exporter.dart';
import 'package:flutter_structurizr/infrastructure/export/export_manager.dart';
import 'package:flutter_structurizr/infrastructure/persistence/file_storage.dart';

/// Dialog for exporting multiple diagrams at once
class BatchExportDialog extends StatefulWidget {
  /// The workspace containing the diagrams to export
  final Workspace workspace;
  
  /// On export complete callback - receives the exported data
  final void Function(List<Uint8List>, List<String>)? onExportComplete;
  
  /// Dialog title
  final String title;
  
  /// Creates a new batch export dialog
  const BatchExportDialog({
    super.key,
    required this.workspace,
    this.onExportComplete,
    this.title = 'Batch Export',
  });

  /// Shows the batch export dialog
  static Future<void> show({
    required BuildContext context,
    required Workspace workspace,
    void Function(List<Uint8List>, List<String>)? onExportComplete,
    String title = 'Batch Export',
  }) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return BatchExportDialog(
          workspace: workspace,
          onExportComplete: onExportComplete,
          title: title,
        );
      },
    );
  }

  @override
  State<BatchExportDialog> createState() => _BatchExportDialogState();
}

class _BatchExportDialogState extends State<BatchExportDialog> {
  ExportFormat _selectedFormat = ExportFormat.png;
  
  bool _includeTitle = true;
  bool _includeLegend = true;
  bool _includeMetadata = true;
  bool _transparent = false;
  double _width = 1920;
  double _height = 1080;
  double _scale = 1.0;
  
  bool _isExporting = false;
  double _exportProgress = 0.0;
  String _statusMessage = '';
  String _errorMessage = '';
  
  final _selectedViews = <ModelView>{};
  final ExportManager _exportManager = ExportManager();
  
  @override
  void initState() {
    super.initState();
    
    // By default, select all views
    _selectedViews.addAll(widget.workspace.views.systemLandscapeViews);
    _selectedViews.addAll(widget.workspace.views.systemContextViews);
    _selectedViews.addAll(widget.workspace.views.containerViews);
    _selectedViews.addAll(widget.workspace.views.componentViews);
    _selectedViews.addAll(widget.workspace.views.deploymentViews);
    _selectedViews.addAll(widget.workspace.views.dynamicViews);
    _selectedViews.addAll(widget.workspace.views.filteredViews);
    }
  
  /// Exports the selected diagrams
  Future<void> _exportDiagrams() async {
    if (_selectedViews.isEmpty) {
      setState(() {
        _errorMessage = 'No views selected for export';
      });
      return;
    }
    
    try {
      setState(() {
        _isExporting = true;
        _exportProgress = 0.0;
        _statusMessage = 'Preparing export...';
        _errorMessage = '';
      });
      
      // Create diagram references
      final diagrams = _selectedViews.map((view) => DiagramReference(
        workspace: widget.workspace,
        viewKey: view.key,
      )).toList();
      
      // Create render parameters
      final options = ExportOptions(
        format: _selectedFormat,
        width: _width,
        height: _height,
        includeLegend: _includeLegend,
        includeTitle: _includeTitle,
        includeMetadata: _includeMetadata,
        backgroundColor: Colors.white,
        transparentBackground: _transparent,
        onProgress: (progress) {
          setState(() {
            _exportProgress = progress;
            _statusMessage = 'Exporting ${(progress * 100).toInt()}%...';
          });
        },
      );
      
      // Export the diagrams as a batch
      final results = await _exportManager.exportBatch(
        diagrams: diagrams,
        options: options,
      );
      
      setState(() {
        _statusMessage = 'Saving exported files...';
        _exportProgress = 0.9;
      });
      
      // Save the exported files
      final fileStorage = FileStorage();
      final savedPaths = <String>[];
      final fileData = <Uint8List>[];
      
      for (var i = 0; i < diagrams.length; i++) {
        final diagram = diagrams[i];
        final result = results[i];
        
        if (result != null) {
          // Get file extension
          final extension = ExportManager.getFileExtension(_selectedFormat);
          final filename = '${diagram.viewKey}.$extension';
          
          // Convert string results to bytes if needed
          final data = result is String 
              ? Uint8List.fromList(result.codeUnits) 
              : result as Uint8List;
          
          // Save the file
          final savedPath = await fileStorage.saveExportedDiagram(data, filename);
          savedPaths.add(savedPath);
          fileData.add(data);
        }
      }
      
      setState(() {
        _isExporting = false;
        _statusMessage = 'Export complete';
        _exportProgress = 1.0;
      });
      
      // Call the onExportComplete callback if provided
      if (widget.onExportComplete != null) {
        widget.onExportComplete!(fileData, savedPaths);
      }
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${savedPaths.length} files'),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Export failed: $e';
        _isExporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 800,
        height: 600,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select views to export:',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            
            // Views selection
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    children: [
                      _buildViewsSection(
                        'System Landscape Views',
                        widget.workspace.views.systemLandscapeViews ?? [],
                      ),
                      _buildViewsSection(
                        'System Context Views',
                        widget.workspace.views.systemContextViews ?? [],
                      ),
                      _buildViewsSection(
                        'Container Views',
                        widget.workspace.views.containerViews ?? [],
                      ),
                      _buildViewsSection(
                        'Component Views',
                        widget.workspace.views.componentViews ?? [],
                      ),
                      _buildViewsSection(
                        'Dynamic Views',
                        widget.workspace.views.dynamicViews ?? [],
                      ),
                      _buildViewsSection(
                        'Deployment Views',
                        widget.workspace.views.deploymentViews ?? [],
                      ),
                      _buildViewsSection(
                        'Filtered Views',
                        widget.workspace.views.filteredViews ?? [],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Export options:',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            
            // Export options
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Format selection
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
                            }
                          },
                        ),
                        ChoiceChip(
                          label: const Text('SVG Vector'),
                          selected: _selectedFormat == ExportFormat.svg,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedFormat = ExportFormat.svg;
                              });
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
                            }
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Format-specific options
                    if (_selectedFormat == ExportFormat.png || _selectedFormat == ExportFormat.svg) ...[
                      Row(
                        children: [
                          const Text('Size:'),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: '${_width.toInt()}x${_height.toInt()}',
                            items: const [
                              DropdownMenuItem(value: '1920x1080', child: Text('1920x1080 (Full HD)')),
                              DropdownMenuItem(value: '3840x2160', child: Text('3840x2160 (4K)')),
                              DropdownMenuItem(value: '1280x720', child: Text('1280x720 (HD)')),
                              DropdownMenuItem(value: '800x600', child: Text('800x600')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                final parts = value.split('x');
                                setState(() {
                                  _width = double.parse(parts[0]);
                                  _height = double.parse(parts[1]);
                                });
                              }
                            },
                          ),
                          const Spacer(),
                          const Text('Scale:'),
                          const SizedBox(width: 8),
                          DropdownButton<double>(
                            value: _scale,
                            items: const [
                              DropdownMenuItem(value: 0.5, child: Text('0.5x')),
                              DropdownMenuItem(value: 0.75, child: Text('0.75x')),
                              DropdownMenuItem(value: 1.0, child: Text('1.0x')),
                              DropdownMenuItem(value: 1.5, child: Text('1.5x')),
                              DropdownMenuItem(value: 2.0, child: Text('2.0x')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _scale = value;
                                });
                              }
                            },
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
                          },
                        ),
                    ],
                    
                    // Common options
                    Row(
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            title: const Text('Include Title'),
                            value: _includeTitle,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (value) {
                              setState(() {
                                _includeTitle = value ?? true;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: CheckboxListTile(
                            title: const Text('Include Legend'),
                            value: _includeLegend,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (value) {
                              setState(() {
                                _includeLegend = value ?? true;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: CheckboxListTile(
                            title: const Text('Include Metadata'),
                            value: _includeMetadata,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (value) {
                              setState(() {
                                _includeMetadata = value ?? true;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Status message
            if (_statusMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_statusMessage),
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
                child: LinearProgressIndicator(value: _exportProgress),
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
          onPressed: _isExporting || _selectedViews.isEmpty ? null : _exportDiagrams,
          child: const Text('Export'),
        ),
      ],
    );
  }
  
  /// Builds a section of views for selection
  Widget _buildViewsSection(String title, List<ModelView> views) {
    if (views.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 16.0),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: views.map((view) {
              final isSelected = _selectedViews.contains(view);
              final displayName = view.title ?? view.key;
              
              return FilterChip(
                label: Text(displayName),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedViews.add(view);
                    } else {
                      _selectedViews.remove(view);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}