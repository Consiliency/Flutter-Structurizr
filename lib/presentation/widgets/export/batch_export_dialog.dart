import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' hide Element, Container, View;
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/view/views.dart';
import 'package:flutter_structurizr/infrastructure/export/diagram_exporter.dart';
import 'package:flutter_structurizr/infrastructure/export/export_manager.dart';
import 'package:path/path.dart' as path;

/// A dialog for batch exporting multiple diagrams
class BatchExportDialog extends StatefulWidget {
  /// The workspace containing the diagrams
  final Workspace workspace;
  
  /// Creates a new batch export dialog
  const BatchExportDialog({
    Key? key,
    required this.workspace,
  }) : super(key: key);

  @override
  State<BatchExportDialog> createState() => _BatchExportDialogState();
}

class _BatchExportDialogState extends State<BatchExportDialog> {
  // Selected export format
  ExportFormat _selectedFormat = ExportFormat.png;

  // Export options
  double _width = 1920;
  double _height = 1080;
  bool _includeLegend = true;
  bool _includeTitle = true;
  bool _includeMetadata = true;
  bool _transparentBackground = false;
  Color _backgroundColor = Colors.white;
  bool _useMemoryEfficientRendering = true;

  // Selected views for export
  final Map<String, bool> _selectedViews = {};

  // Export progress
  bool _exporting = false;
  double _progress = 0.0;
  String? _progressMessage;
  String? _error;

  // Destination directory
  String? _destinationDirectory;

  // Export manager
  final _exportManager = ExportManager();
  
  @override
  void initState() {
    super.initState();
    _initializeViewSelection();
  }
  
  /// Initialize view selection map with all views initially selected
  void _initializeViewSelection() {
    final views = widget.workspace.views;
    
    // Add system context views
    for (final view in views.systemContextViews) {
      _selectedViews[view.key] = true;
    }
    
    // Add container views
    for (final view in views.containerViews) {
      _selectedViews[view.key] = true;
    }
    
    // Add component views
    for (final view in views.componentViews) {
      _selectedViews[view.key] = true;
    }
    
    // Add deployment views
    for (final view in views.deploymentViews) {
      _selectedViews[view.key] = true;
    }
    
    // Add filtered views
    for (final view in views.filteredViews) {
      _selectedViews[view.key] = true;
    }
    
    // Add dynamic views
    for (final view in views.dynamicViews) {
      _selectedViews[view.key] = true;
    }
    
    // Add custom views
    for (final view in views.customViews) {
      _selectedViews[view.key] = true;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return AlertDialog(
      title: const Text('Batch Export Diagrams'),
      content: SizedBox(
        width: 700,
        height: 600,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Format selection
            DropdownButtonFormField<ExportFormat>(
              decoration: const InputDecoration(
                labelText: 'Export Format',
                border: OutlineInputBorder(),
              ),
              value: _selectedFormat,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedFormat = value;
                  });
                }
              },
              items: const [
                DropdownMenuItem(
                  value: ExportFormat.png,
                  child: Text('PNG Image'),
                ),
                DropdownMenuItem(
                  value: ExportFormat.svg,
                  child: Text('SVG Vector Image'),
                ),
                DropdownMenuItem(
                  value: ExportFormat.plantuml,
                  child: Text('PlantUML Diagram'),
                ),
                DropdownMenuItem(
                  value: ExportFormat.c4plantuml,
                  child: Text('C4-PlantUML Diagram'),
                ),
                DropdownMenuItem(
                  value: ExportFormat.mermaid,
                  child: Text('Mermaid Diagram'),
                ),
                DropdownMenuItem(
                  value: ExportFormat.c4mermaid,
                  child: Text('C4-Mermaid Diagram'),
                ),
                DropdownMenuItem(
                  value: ExportFormat.dot,
                  child: Text('DOT/Graphviz'),
                ),
                DropdownMenuItem(
                  value: ExportFormat.dsl,
                  child: Text('Structurizr DSL'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Common export options
            Row(
              children: [
                // Image size options (for raster/vector formats)
                if (_selectedFormat == ExportFormat.png || _selectedFormat == ExportFormat.svg) ...[
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Width (px)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            controller: TextEditingController(text: _width.toStringAsFixed(0)),
                            onChanged: (value) {
                              setState(() {
                                _width = double.tryParse(value) ?? _width;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Height (px)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            controller: TextEditingController(text: _height.toStringAsFixed(0)),
                            onChanged: (value) {
                              setState(() {
                                _height = double.tryParse(value) ?? _height;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Destination directory picker
                if ((_selectedFormat == ExportFormat.png || _selectedFormat == ExportFormat.svg) && 
                    _selectedViews.values.where((selected) => selected).length > 1) ...[
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Select Destination Folder'),
                    onPressed: _pickDirectory,
                  ),
                ],
              ],
            ),
            
            // Selected directory
            if (_destinationDirectory != null) ...[
              const SizedBox(height: 8),
              Text(
                'Destination: $_destinationDirectory',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Include options
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Include Legend'),
                    value: _includeLegend,
                    onChanged: (value) {
                      setState(() {
                        _includeLegend = value ?? true;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Include Title'),
                    value: _includeTitle,
                    onChanged: (value) {
                      setState(() {
                        _includeTitle = value ?? true;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Include Metadata'),
                    value: _includeMetadata,
                    onChanged: (value) {
                      setState(() {
                        _includeMetadata = value ?? true;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                ),
                if (_selectedFormat == ExportFormat.png || _selectedFormat == ExportFormat.svg)
                  Expanded(
                    child: CheckboxListTile(
                      title: const Text('Memory-Efficient'),
                      value: _useMemoryEfficientRendering,
                      onChanged: (value) {
                        setState(() {
                          _useMemoryEfficientRendering = value ?? true;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),
                  ),
              ],
            ),
            
            // PNG-specific options
            if (_selectedFormat == ExportFormat.png) ...[
              CheckboxListTile(
                title: const Text('Transparent Background'),
                value: _transparentBackground,
                onChanged: (value) {
                  setState(() {
                    _transparentBackground = value ?? false;
                  });
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),
              if (!_transparentBackground) ...[
                Row(
                  children: [
                    const Text('Background Color:'),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () {
                        _showColorPicker();
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _backgroundColor,
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
            
            const SizedBox(height: 16),
            
            // View selection section
            const Text(
              'Select Views to Export',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            // View selection toolbar
            Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.check_box),
                  label: const Text('Select All'),
                  onPressed: _selectAllViews,
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  icon: const Icon(Icons.check_box_outline_blank),
                  label: const Text('Deselect All'),
                  onPressed: _deselectAllViews,
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // View selection list
            Expanded(
              child: _buildViewSelectionLists(isDarkMode),
            ),
            
            // Progress indicator
            if (_exporting) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
              ),
              if (_progressMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _progressMessage!,
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                ),
              ],
            ],
            
            // Error message
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(
                  color: Colors.red.shade800,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _exporting 
              ? null 
              : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _getSelectedViewCount() > 0 && !_exporting
              ? (_selectedFormat == ExportFormat.png || _selectedFormat == ExportFormat.svg) && 
                _getSelectedViewCount() > 1 && 
                _destinationDirectory == null
                  ? _pickDirectory
                  : _exportBatch
              : null,
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
  
  /// Builds the view selection lists, grouped by view type
  Widget _buildViewSelectionLists(bool isDarkMode) {
    final views = widget.workspace.views;
    
    return ListView(
      children: [
        // System Context Views
        if (views.systemContextViews.isNotEmpty) ...[
          _buildViewTypeHeader('System Context Views', isDarkMode),
          ...views.systemContextViews.map((view) => _buildViewCheckbox(view)),
        ],
        
        // Container Views
        if (views.containerViews.isNotEmpty) ...[
          _buildViewTypeHeader('Container Views', isDarkMode),
          ...views.containerViews.map((view) => _buildViewCheckbox(view)),
        ],
        
        // Component Views
        if (views.componentViews.isNotEmpty) ...[
          _buildViewTypeHeader('Component Views', isDarkMode),
          ...views.componentViews.map((view) => _buildViewCheckbox(view)),
        ],
        
        // Deployment Views
        if (views.deploymentViews.isNotEmpty) ...[
          _buildViewTypeHeader('Deployment Views', isDarkMode),
          ...views.deploymentViews.map((view) => _buildViewCheckbox(view)),
        ],
        
        // Filtered Views
        if (views.filteredViews.isNotEmpty) ...[
          _buildViewTypeHeader('Filtered Views', isDarkMode),
          ...views.filteredViews.map((view) => _buildViewCheckbox(view)),
        ],
        
        // Dynamic Views
        if (views.dynamicViews.isNotEmpty) ...[
          _buildViewTypeHeader('Dynamic Views', isDarkMode),
          ...views.dynamicViews.map((view) => _buildViewCheckbox(view)),
        ],
        
        // Custom Views
        if (views.customViews.isNotEmpty) ...[
          _buildViewTypeHeader('Custom Views', isDarkMode),
          ...views.customViews.map((view) => _buildViewCheckbox(view)),
        ],
      ],
    );
  }
  
  /// Builds a header for a view type section
  Widget _buildViewTypeHeader(String title, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
          ),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
        ),
      ),
    );
  }
  
  /// Builds a checkbox for a view
  Widget _buildViewCheckbox(ModelView view) {
    return CheckboxListTile(
      title: Text(view.name),
      subtitle: Text(view.key),
      value: _selectedViews[view.key] ?? false,
      onChanged: (value) {
        setState(() {
          _selectedViews[view.key] = value ?? false;
        });
      },
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
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
      child: Container(
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
  
  /// Selects all views for export
  void _selectAllViews() {
    setState(() {
      for (final key in _selectedViews.keys) {
        _selectedViews[key] = true;
      }
    });
  }
  
  /// Deselects all views for export
  void _deselectAllViews() {
    setState(() {
      for (final key in _selectedViews.keys) {
        _selectedViews[key] = false;
      }
    });
  }
  
  /// Returns the number of selected views
  int _getSelectedViewCount() {
    return _selectedViews.values.where((selected) => selected).length;
  }
  
  /// Allows the user to pick a destination directory
  Future<void> _pickDirectory() async {
    final directory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Destination Folder',
    );
    
    if (directory != null) {
      setState(() {
        _destinationDirectory = directory;
      });
    }
  }
  
  /// Exports all selected diagrams
  Future<void> _exportBatch() async {
    // For PNG and SVG formats with multiple views, require a destination directory
    if ((_selectedFormat == ExportFormat.png || _selectedFormat == ExportFormat.svg) && 
        _getSelectedViewCount() > 1 && 
        _destinationDirectory == null) {
      setState(() {
        _error = 'Please select a destination folder for multiple diagram exports';
      });
      return;
    }
    
    setState(() {
      _exporting = true;
      _progress = 0.0;
      _progressMessage = 'Preparing batch export...';
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
          });
        },
      );
      
      // Prepare list of diagrams to export
      final diagrams = <DiagramReference>[];
      
      // Add selected system context views
      for (final view in widget.workspace.views.systemContextViews) {
        if (_selectedViews[view.key] == true) {
          diagrams.add(DiagramReference(
            workspace: widget.workspace,
            viewKey: view.key,
            title: view.name,
          ));
        }
      }
      
      // Add selected container views
      for (final view in widget.workspace.views.containerViews) {
        if (_selectedViews[view.key] == true) {
          diagrams.add(DiagramReference(
            workspace: widget.workspace,
            viewKey: view.key,
            title: view.name,
          ));
        }
      }
      
      // Add selected component views
      for (final view in widget.workspace.views.componentViews) {
        if (_selectedViews[view.key] == true) {
          diagrams.add(DiagramReference(
            workspace: widget.workspace,
            viewKey: view.key,
            title: view.name,
          ));
        }
      }
      
      // Add selected deployment views
      for (final view in widget.workspace.views.deploymentViews) {
        if (_selectedViews[view.key] == true) {
          diagrams.add(DiagramReference(
            workspace: widget.workspace,
            viewKey: view.key,
            title: view.name,
          ));
        }
      }
      
      // Add selected filtered views
      for (final view in widget.workspace.views.filteredViews) {
        if (_selectedViews[view.key] == true) {
          diagrams.add(DiagramReference(
            workspace: widget.workspace,
            viewKey: view.key,
            title: view.name,
          ));
        }
      }
      
      // Add selected dynamic views
      for (final view in widget.workspace.views.dynamicViews) {
        if (_selectedViews[view.key] == true) {
          diagrams.add(DiagramReference(
            workspace: widget.workspace,
            viewKey: view.key,
            title: view.name,
          ));
        }
      }
      
      // Add selected custom views
      for (final view in widget.workspace.views.customViews) {
        if (_selectedViews[view.key] == true) {
          diagrams.add(DiagramReference(
            workspace: widget.workspace,
            viewKey: view.key,
            title: view.name,
          ));
        }
      }
      
      // Special case for single diagram export
      if (diagrams.length == 1) {
        await _exportSingleDiagram(diagrams.first, options);
      } else {
        // Batch export
        await _exportMultipleDiagrams(diagrams, options);
      }
    } catch (e) {
      setState(() {
        _exporting = false;
        _error = 'Error exporting diagrams: $e';
        _progressMessage = null;
      });
    }
  }
  
  /// Exports a single diagram
  Future<void> _exportSingleDiagram(DiagramReference diagram, ExportOptions options) async {
    setState(() {
      _progressMessage = 'Exporting ${diagram.title ?? diagram.viewKey}...';
    });
    
    // Export the diagram
    final result = await _exportManager.exportDiagram(
      workspace: widget.workspace,
      viewKey: diagram.viewKey,
      options: options,
      title: diagram.title,
    );
    
    // Get save location from user
    final extension = ExportManager.getFileExtension(_selectedFormat);
    final defaultFileName = '${widget.workspace.name}_${diagram.viewKey}.$extension';
    
    setState(() {
      _progressMessage = 'Saving file...';
    });
    
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
  
  /// Exports multiple diagrams in batch
  Future<void> _exportMultipleDiagrams(List<DiagramReference> diagrams, ExportOptions options) async {
    // Ensure destination directory is set
    if (_destinationDirectory == null) {
      // For non-binary formats, ask where to save
      final directory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Destination Folder',
      );
      
      if (directory == null) {
        setState(() {
          _exporting = false;
          _progressMessage = null;
        });
        return;
      }
      
      _destinationDirectory = directory;
    }
    
    setState(() {
      _progressMessage = 'Exporting ${diagrams.length} diagrams...';
    });
    
    // Export the diagrams
    final results = await _exportManager.exportBatch(
      diagrams: diagrams,
      options: options,
    );
    
    setState(() {
      _progressMessage = 'Saving files...';
    });
    
    // Save each result to a file
    final extension = ExportManager.getFileExtension(_selectedFormat);
    
    for (int i = 0; i < diagrams.length; i++) {
      final diagram = diagrams[i];
      final result = results[i];
      
      final fileName = '${widget.workspace.name}_${diagram.viewKey}.$extension';
      final filePath = path.join(_destinationDirectory!, fileName);
      final file = File(filePath);
      
      setState(() {
        _progressMessage = 'Saving ${i+1} of ${diagrams.length}: $fileName';
        _progress = (i + 0.5) / diagrams.length;
      });
      
      if (_selectedFormat == ExportFormat.png) {
        // Binary data
        await file.writeAsBytes(result as List<int>);
      } else {
        // Text data
        await file.writeAsString(result as String);
      }
      
      setState(() {
        _progress = (i + 1.0) / diagrams.length;
      });
    }
    
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }
}