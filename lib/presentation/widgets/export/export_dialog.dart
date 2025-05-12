import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' hide Element, Container, View;
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/infrastructure/export/export_manager.dart';

/// A dialog for exporting a diagram to various formats
class ExportDialog extends StatefulWidget {
  /// The workspace containing the diagram
  final Workspace workspace;
  
  /// The key of the view to export
  final String viewKey;
  
  /// Title for the exported diagram (optional)
  final String? title;
  
  /// Creates a new export dialog
  const ExportDialog({
    Key? key,
    required this.workspace,
    required this.viewKey,
    this.title,
  }) : super(key: key);

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
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

  // Export progress
  bool _exporting = false;
  double _progress = 0.0;
  String? _progressMessage;
  String? _error;

  // Export manager
  final _exportManager = ExportManager();
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return AlertDialog(
      title: const Text('Export Diagram'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            
            // Image size options (for raster/vector formats)
            if (_selectedFormat == ExportFormat.png || _selectedFormat == ExportFormat.svg) ...[
              Row(
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
              const SizedBox(height: 16),
            ],
            
            // Background options (for PNG)
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
              ),
              if (!_transparentBackground) ...[
                const SizedBox(height: 8),
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
              const SizedBox(height: 16),
            ],
            
            // Include options
            CheckboxListTile(
              title: const Text('Include Legend'),
              value: _includeLegend,
              onChanged: (value) {
                setState(() {
                  _includeLegend = value ?? true;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text('Include Title'),
              value: _includeTitle,
              onChanged: (value) {
                setState(() {
                  _includeTitle = value ?? true;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text('Include Metadata'),
              value: _includeMetadata,
              onChanged: (value) {
                setState(() {
                  _includeMetadata = value ?? true;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),

            // Memory optimization option
            if (_selectedFormat == ExportFormat.png || _selectedFormat == ExportFormat.svg)
              CheckboxListTile(
                title: const Text('Use Memory-Efficient Rendering'),
                subtitle: const Text('Recommended for large diagrams'),
                value: _useMemoryEfficientRendering,
                onChanged: (value) {
                  setState(() {
                    _useMemoryEfficientRendering = value ?? true;
                  });
                },
                contentPadding: EdgeInsets.zero,
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
          onPressed: _exporting 
              ? null 
              : _export,
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
            _progressMessage = 'Exporting diagram... ${(progress * 100).toStringAsFixed(0)}%';
          });
        },
      );

      // Add memory optimization option if PNG or SVG format
      if (_selectedFormat == ExportFormat.png || _selectedFormat == ExportFormat.svg) {
        if (_exportManager is PngExporter || _exportManager is SvgExporter) {
          // Apply memory optimization setting to exporter
          // Note: This requires modifying the export_manager.dart to support this option
          // For now, we'll note that this would be implemented here
        }
      }
      
      // Export the diagram
      final result = await _exportManager.exportDiagram(
        workspace: widget.workspace,
        viewKey: widget.viewKey,
        options: options,
        title: widget.title,
      );
      
      // Get save location from user
      final extension = ExportManager.getFileExtension(_selectedFormat);
      final mimeType = ExportManager.getMimeType(_selectedFormat);
      final defaultFileName = '${widget.workspace.name}_${widget.viewKey}.$extension';
      
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
    } catch (e) {
      setState(() {
        _exporting = false;
        _error = 'Error exporting diagram: $e';
        _progressMessage = null;
      });
    }
  }
}