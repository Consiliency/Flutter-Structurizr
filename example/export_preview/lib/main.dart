import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

void main() {
  runApp(const ExportPreviewExampleApp());
}

class ExportPreviewExampleApp extends StatelessWidget {
  const ExportPreviewExampleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Export Preview Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ExportPreviewExamplePage(),
    );
  }
}

class ExportPreviewExamplePage extends StatefulWidget {
  const ExportPreviewExamplePage({Key? key}) : super(key: key);

  @override
  State<ExportPreviewExamplePage> createState() =>
      _ExportPreviewExamplePageState();
}

class _ExportPreviewExamplePageState extends State<ExportPreviewExamplePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Preview Example'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _showExportDialog(),
          child: const Text('Show Export Dialog'),
        ),
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => const SimplifiedExportDialog(),
    );
  }
}

// Simplified version of the export formats
enum ExportFormat {
  png,
  svg,
  plantuml,
  mermaid,
  dot,
  dsl,
}

// SVG Preview Widget for displaying SVG content
class SvgPreviewWidget extends StatelessWidget {
  final String svgContent;
  final bool transparentBackground;

  const SvgPreviewWidget({
    Key? key,
    required this.svgContent,
    this.transparentBackground = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Extract SVG dimensions
    final widthMatch = RegExp(r'width="(\d+)"').firstMatch(svgContent);
    final heightMatch = RegExp(r'height="(\d+)"').firstMatch(svgContent);

    final width = widthMatch != null
        ? int.tryParse(widthMatch.group(1) ?? '400') ?? 400
        : 400;
    final height = heightMatch != null
        ? int.tryParse(heightMatch.group(1) ?? '300') ?? 300
        : 300;

    // Count elements in SVG
    final elementCount = _countElements(svgContent);

    // SVG size in KB
    final svgSize = (svgContent.length / 1024).toStringAsFixed(1);

    // Create a checkerboard pattern for transparent backgrounds
    Widget backgroundWidget = transparentBackground
        ? const CheckerboardBackground()
        : Container(color: Colors.white);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          // Background layer
          Positioned.fill(child: backgroundWidget),

          // SVG content layer (using mock for this example)
          Center(
            child: AspectRatio(
              aspectRatio: width / height,
              child: CustomPaint(
                painter: DiagramPreviewPainter(showGrid: transparentBackground),
              ),
            ),
          ),

          // Information overlay
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Size: $width × $height',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    'Elements: $elementCount',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    'SVG Size: $svgSize KB',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _countElements(String svg) {
    final regex = RegExp('<(?!\\/|\\?|!)[a-zA-Z][^>]*>');
    final matches = regex.allMatches(svg);
    return matches.length;
  }
}

// Checkerboard pattern for transparent backgrounds
class CheckerboardBackground extends StatelessWidget {
  final int squareSize;

  const CheckerboardBackground({
    Key? key,
    this.squareSize = 10,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: CheckerboardPainter(squareSize: squareSize),
    );
  }
}

class CheckerboardPainter extends CustomPainter {
  final int squareSize;

  CheckerboardPainter({required this.squareSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCCCCCC) // Light gray
      ..style = PaintingStyle.fill;

    final darkPaint = Paint()
      ..color = const Color(0xFFFFFFFF) // White
      ..style = PaintingStyle.fill;

    for (int y = 0; y < (size.height / squareSize).ceil(); y++) {
      for (int x = 0; x < (size.width / squareSize).ceil(); x++) {
        final isEven = (x + y) % 2 == 0;
        final rect = Rect.fromLTWH(
          x * squareSize.toDouble(),
          y * squareSize.toDouble(),
          squareSize.toDouble(),
          squareSize.toDouble(),
        );

        canvas.drawRect(rect, isEven ? paint : darkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// PNG Preview Widget for displaying PNG content
class PngPreviewWidget extends StatelessWidget {
  final Uint8List? imageData;
  final bool transparentBackground;
  final double width;
  final double height;

  const PngPreviewWidget({
    Key? key,
    this.imageData,
    this.transparentBackground = false,
    this.width = 1920,
    this.height = 1080,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Create a checkerboard pattern for transparent backgrounds
    Widget backgroundWidget = transparentBackground
        ? const CheckerboardBackground()
        : Container(color: Colors.white);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          // Background layer
          Positioned.fill(child: backgroundWidget),

          // Image content layer (using mock for this example)
          Center(
            child: AspectRatio(
              aspectRatio: width / height,
              child: CustomPaint(
                painter: DiagramPreviewPainter(showGrid: transparentBackground),
              ),
            ),
          ),

          // Information overlay
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Size: ${width.toInt()} × ${height.toInt()}',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (imageData != null)
                    Text(
                      'Image Size: ${(imageData!.length / 1024).toStringAsFixed(1)} KB',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Text-based Preview Widget for formats like PlantUML, Mermaid, etc.
class TextPreviewWidget extends StatelessWidget {
  final String content;
  final String format;

  const TextPreviewWidget({
    Key? key,
    required this.content,
    required this.format,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
        color: theme.colorScheme.surface,
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$format Preview',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.all(12.0),
              child: SingleChildScrollView(
                child: Text(
                  content,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Size: ${content.length} characters',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// Simplified export dialog for demo purposes
class SimplifiedExportDialog extends StatefulWidget {
  const SimplifiedExportDialog({Key? key}) : super(key: key);

  @override
  State<SimplifiedExportDialog> createState() => _SimplifiedExportDialogState();
}

class _SimplifiedExportDialogState extends State<SimplifiedExportDialog> {
  // Selected export format
  ExportFormat _selectedFormat = ExportFormat.png;

  // Export options
  double _width = 1920;
  double _height = 1080;
  double _scale = 1.0;
  bool _includeLegend = true;
  bool _includeTitle = true;
  bool _includeMetadata = true;
  bool _transparentBackground = false;
  bool _useMemoryEfficientRendering = true;

  // Preview options
  bool _showPreview = true;
  Uint8List? _previewData;
  String? _svgPreviewData;
  String? _textPreviewData;
  bool _isGeneratingPreview = false;
  String _previewFormat = 'png';
  late Timer _debounceTimer;

  // Progress
  bool _exporting = false;
  double _progress = 0.0;
  String? _progressMessage;
  String? _error;

  @override
  void initState() {
    super.initState();

    // Generate a preview
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
    if (!_showPreview) return;
    if (_isGeneratingPreview) return; // Prevent concurrent generations

    try {
      setState(() {
        _isGeneratingPreview = true;
        _progress = 0.0;
        _error = null;
      });

      // Determine the format based on selected export format
      _previewFormat = _selectedFormat.toString().split('.').last;

      // Create mock progress updates with more realistic progression
      var currentProgress = 0.0;
      Timer.periodic(const Duration(milliseconds: 50), (timer) {
        if (!mounted || !_isGeneratingPreview) {
          timer.cancel();
          return;
        }

        // Simulate non-linear progress
        double increment;
        if (currentProgress < 0.2) {
          // Start slow (setup)
          increment = 0.005;
        } else if (currentProgress < 0.8) {
          // Middle fast (main processing)
          increment = 0.015;
        } else {
          // End slow (finalization)
          increment = 0.008;
        }

        currentProgress += increment;
        if (currentProgress > 1.0) {
          currentProgress = 1.0;
          timer.cancel();
        }

        setState(() {
          _progress = currentProgress;

          // Different messages based on progress
          if (currentProgress < 0.2) {
            _progressMessage = 'Initializing export renderer...';
          } else if (currentProgress < 0.4) {
            _progressMessage = 'Rendering boundaries...';
          } else if (currentProgress < 0.6) {
            _progressMessage = 'Rendering relationships...';
          } else if (currentProgress < 0.8) {
            _progressMessage = 'Rendering elements...';
          } else {
            _progressMessage =
                'Generating preview... ${(currentProgress * 100).toInt()}%';
          }
        });
      });

      // Simulate network delay with randomness to feel more realistic
      final delay = Duration(milliseconds: 800 + (math.Random().nextInt(400)));
      await Future.delayed(delay);

      // Mock preview generation based on format
      switch (_selectedFormat) {
        case ExportFormat.svg:
          // Generate a mock SVG
          final mockSvg = _generateMockSvg();

          setState(() {
            _svgPreviewData = mockSvg;
            _previewData = Uint8List.fromList(mockSvg.codeUnits);
            _textPreviewData = null;
          });
          break;

        case ExportFormat.png:
          // Generate a mock PNG (actually just a colored rectangle in memory)
          final mockPng = _generateMockPng();

          setState(() {
            _previewData = mockPng;
            _svgPreviewData = null;
            _textPreviewData = null;
          });
          break;

        case ExportFormat.plantuml:
          final mockPlantUml = _generateMockPlantUml();

          setState(() {
            _textPreviewData = mockPlantUml;
            _svgPreviewData = null;
            _previewData = null;
          });
          break;

        case ExportFormat.mermaid:
          final mockMermaid = _generateMockMermaid();

          setState(() {
            _textPreviewData = mockMermaid;
            _svgPreviewData = null;
            _previewData = null;
          });
          break;

        case ExportFormat.dot:
          final mockDot = _generateMockDot();

          setState(() {
            _textPreviewData = mockDot;
            _svgPreviewData = null;
            _previewData = null;
          });
          break;

        case ExportFormat.dsl:
          final mockDsl = _generateMockDsl();

          setState(() {
            _textPreviewData = mockDsl;
            _svgPreviewData = null;
            _previewData = null;
          });
          break;
      }

      setState(() {
        _isGeneratingPreview = false;
        _progressMessage = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to generate preview: $e';
        _isGeneratingPreview = false;
        _progressMessage = null;
      });
    }
  }

  // Generate a mock PNG image as bytes
  Uint8List _generateMockPng() {
    // This would usually be a real PNG image generated from a diagram
    // For this example, we'll just create a list of bytes
    final data = List<int>.filled(100000, 0);

    // Fill with pseudo-random data to simulate a PNG
    for (var i = 0; i < data.length; i++) {
      data[i] = (math.sin(i * 0.01) * 127 + 128).toInt();
    }

    return Uint8List.fromList(data);
  }

  // Generate a mock SVG string
  String _generateMockSvg() {
    return '''
<svg width="400" height="300" xmlns="http://www.w3.org/2000/svg">
  <rect x="50" y="50" width="300" height="200" fill="${_transparentBackground ? 'none' : 'white'}" stroke="black" />
  <circle cx="200" cy="150" r="50" fill="blue" />
  <text x="200" y="150" text-anchor="middle" fill="white">System</text>
  <rect x="70" y="70" width="100" height="60" fill="green" />
  <text x="120" y="100" text-anchor="middle" fill="white">Component A</text>
  <rect x="230" y="70" width="100" height="60" fill="red" />
  <text x="280" y="100" text-anchor="middle" fill="white">Component B</text>
  <line x1="120" y1="130" x2="200" y2="150" stroke="black" />
  <line x1="280" y1="130" x2="200" y2="150" stroke="black" />
  <text x="150" y="140" text-anchor="middle" font-size="10">Uses</text>
  <text x="250" y="140" text-anchor="middle" font-size="10">Uses</text>
  
  ${_includeLegend ? '''
  <rect x="50" y="260" width="300" height="30" fill="lightgrey" />
  <text x="200" y="280" text-anchor="middle" fill="black">Legend</text>
  ''' : ''}
  
  ${_includeTitle ? '''
  <text x="200" y="30" text-anchor="middle" font-size="18" fill="black">System Diagram</text>
  ''' : ''}
  
  ${_includeMetadata ? '''
  <text x="50" y="290" text-anchor="start" font-size="8" fill="grey">Generated by Structurizr</text>
  ''' : ''}
</svg>
''';
  }

  // Generate mock PlantUML
  String _generateMockPlantUml() {
    return '''
@startuml
skinparam backgroundColor ${_transparentBackground ? 'transparent' : 'white'}

${_includeTitle ? 'title System Diagram\n' : ''}

[Component A] as CompA
[Component B] as CompB
database "System" as Sys

CompA --> Sys : Uses
CompB --> Sys : Uses

${_includeLegend ? 'legend right\n  Legend\nendlegend\n' : ''}

${_includeMetadata ? 'footer Generated by Structurizr' : ''}
@enduml
''';
  }

  // Generate mock Mermaid
  String _generateMockMermaid() {
    return '''
graph TD
    ${_includeTitle ? 'subgraph "System Diagram"' : ''}
    A[Component A] --> S((System))
    B[Component B] --> S
    ${_includeTitle ? 'end' : ''}
    
    ${_includeLegend ? 'classDef legend fill:#f9f9f9,stroke:#333,stroke-width:1px;' : ''}
    ${_includeLegend ? 'class A,B,S legend;' : ''}
    
    ${_includeMetadata ? '%% Generated by Structurizr' : ''}
''';
  }

  // Generate mock DOT
  String _generateMockDot() {
    return '''
digraph {
    ${_transparentBackground ? 'bgcolor="transparent"' : 'bgcolor="white"'}
    
    ${_includeTitle ? 'labelloc="t";' : ''}
    ${_includeTitle ? 'label="System Diagram";' : ''}
    
    "Component A" [shape=box, style=filled, fillcolor=green, fontcolor=white];
    "Component B" [shape=box, style=filled, fillcolor=red, fontcolor=white];
    "System" [shape=circle, style=filled, fillcolor=blue, fontcolor=white];
    
    "Component A" -> "System" [label="Uses"];
    "Component B" -> "System" [label="Uses"];
    
    ${_includeLegend ? 'subgraph cluster_legend { label="Legend"; color=gray; }' : ''}
    
    ${_includeMetadata ? '// Generated by Structurizr' : ''}
}
''';
  }

  // Generate mock DSL
  String _generateMockDsl() {
    return '''
workspace {
    model {
        system = softwareSystem "System" {
            compA = component "Component A"
            compB = component "Component B"
        }
        
        compA -> system "Uses"
        compB -> system "Uses"
    }
    
    views {
        systemContext system "${_includeTitle ? 'System Diagram' : ''}" {
            include *
            autoLayout
            ${_includeLegend ? 'legend true' : 'legend false'}
        }
        
        ${_includeMetadata ? 'properties { /* Generated by Structurizr */ }' : ''}
    }
}
''';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return AlertDialog(
      title: const Text('Export Diagram'),
      content: SizedBox(
        width: 800,
        height: 600,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            Expanded(
              child: Row(
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
          onPressed: _exporting
              ? null
              : () {
                  _startExport();
                },
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

  // Start mock export process
  void _startExport() {
    setState(() {
      _exporting = true;
      _progress = 0.0;
      _progressMessage = 'Starting export...';
      _error = null;
    });

    // Create realistic export progress simulation
    var currentProgress = 0.0;
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted || !_exporting) {
        timer.cancel();
        return;
      }

      // Non-linear progress steps
      double increment;
      String message;

      if (currentProgress < 0.1) {
        increment = 0.01;
        message = 'Initializing export...';
      } else if (currentProgress < 0.3) {
        increment = 0.02;
        message = 'Rendering diagram boundaries...';
      } else if (currentProgress < 0.5) {
        increment = 0.03;
        message = 'Rendering relationships...';
      } else if (currentProgress < 0.7) {
        increment = 0.02;
        message = 'Rendering elements...';
      } else if (currentProgress < 0.9) {
        increment = 0.015;
        message =
            'Processing ${_selectedFormat.toString().split('.').last.toUpperCase()} output...';
      } else {
        increment = 0.01;
        message = 'Finishing export...';
      }

      currentProgress += increment;
      if (currentProgress >= 1.0) {
        currentProgress = 1.0;
        message = 'Export complete!';
        timer.cancel();

        // Simulate file save completion
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _exporting = false;
              _progressMessage = null;
            });

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Diagram exported successfully as ${_selectedFormat.toString().split('.').last.toUpperCase()}!'),
                behavior: SnackBarBehavior.floating,
              ),
            );

            // Close dialog after export
            Navigator.of(context).pop();
          }
        });
      }

      setState(() {
        _progress = currentProgress;
        _progressMessage = message;
      });
    });
  }

  /// Builds the export options panel
  Widget _buildExportOptions(bool isDarkMode) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
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
                runSpacing: 8,
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
                // Size controls with adaptive-size card
                Card(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Image Size',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
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

                        // Transparent background option specific to PNG and SVG
                        if (_selectedFormat == ExportFormat.png ||
                            _selectedFormat == ExportFormat.svg)
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Advanced rendering options
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

              // Common options for all formats in a card
              Card(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Content Options',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

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
      ),
    );
  }

  /// Builds the preview panel
  Widget _buildPreview() {
    final showablePreview = _showPreview &&
        (_selectedFormat == ExportFormat.png ||
            _selectedFormat == ExportFormat.svg ||
            _selectedFormat == ExportFormat.plantuml ||
            _selectedFormat == ExportFormat.mermaid ||
            _selectedFormat == ExportFormat.dot ||
            _selectedFormat == ExportFormat.dsl);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Preview',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (showablePreview && !_isGeneratingPreview)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh Preview',
                    onPressed: () => _generatePreview(),
                  ),
              ],
            ),
            const SizedBox(height: 8),
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

                    if (_previewData == null &&
                        _svgPreviewData == null &&
                        _textPreviewData == null) {
                      return Center(
                        child: TextButton.icon(
                          onPressed: () => _generatePreview(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Generate Preview'),
                        ),
                      );
                    }

                    // Display the preview based on format
                    switch (_selectedFormat) {
                      case ExportFormat.svg:
                        if (_svgPreviewData == null) return const SizedBox();
                        return SvgPreviewWidget(
                          svgContent: _svgPreviewData!,
                          transparentBackground: _transparentBackground,
                        );

                      case ExportFormat.png:
                        return PngPreviewWidget(
                          imageData: _previewData,
                          transparentBackground: _transparentBackground,
                          width: _width,
                          height: _height,
                        );

                      case ExportFormat.plantuml:
                      case ExportFormat.mermaid:
                      case ExportFormat.dot:
                      case ExportFormat.dsl:
                        if (_textPreviewData == null) return const SizedBox();
                        return TextPreviewWidget(
                          content: _textPreviewData!,
                          format: _selectedFormat
                              .toString()
                              .split('.')
                              .last
                              .toUpperCase(),
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

// A simple painter to show a mock diagram preview
class DiagramPreviewPainter extends CustomPainter {
  final bool showGrid;

  DiagramPreviewPainter({this.showGrid = false});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw checkerboard grid if requested
    if (showGrid) {
      const gridSize = 10.0;
      final gridPaint1 = Paint()
        ..color = const Color(0xFFCCCCCC)
        ..style = PaintingStyle.fill;

      final gridPaint2 = Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.fill;

      for (int y = 0; y < (size.height / gridSize).ceil(); y++) {
        for (int x = 0; x < (size.width / gridSize).ceil(); x++) {
          final isEven = (x + y) % 2 == 0;
          final rect = Rect.fromLTWH(
            x * gridSize,
            y * gridSize,
            gridSize,
            gridSize,
          );

          canvas.drawRect(rect, isEven ? gridPaint1 : gridPaint2);
        }
      }
    }

    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    // Draw a circle in the center
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      min(size.width, size.height) / 4,
      paint,
    );

    // Draw rectangles around it
    paint.color = Colors.green;
    canvas.drawRect(
      Rect.fromLTWH(
        size.width / 4,
        size.height / 4,
        size.width / 5,
        size.height / 5,
      ),
      paint,
    );

    paint.color = Colors.red;
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 3 / 4 - size.width / 5,
        size.height / 4,
        size.width / 5,
        size.height / 5,
      ),
      paint,
    );

    // Draw lines connecting them
    final linePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(
          size.width / 4 + size.width / 10, size.height / 4 + size.height / 5),
      Offset(size.width / 2, size.height / 2),
      linePaint,
    );

    canvas.drawLine(
      Offset(size.width * 3 / 4 - size.width / 10,
          size.height / 4 + size.height / 5),
      Offset(size.width / 2, size.height / 2),
      linePaint,
    );

    // Draw text labels
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'System',
        style: TextStyle(color: Colors.white, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        size.width / 2 - textPainter.width / 2,
        size.height / 2 - textPainter.height / 2,
      ),
    );

    final textPainter2 = TextPainter(
      text: const TextSpan(
        text: 'Component A',
        style: TextStyle(color: Colors.white, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter2.layout();
    textPainter2.paint(
      canvas,
      Offset(
        size.width / 4 + (size.width / 5) / 2 - textPainter2.width / 2,
        size.height / 4 + (size.height / 5) / 2 - textPainter2.height / 2,
      ),
    );

    final textPainter3 = TextPainter(
      text: const TextSpan(
        text: 'Component B',
        style: TextStyle(color: Colors.white, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter3.layout();
    textPainter3.paint(
      canvas,
      Offset(
        size.width * 3 / 4 - (size.width / 5) / 2 - textPainter3.width / 2,
        size.height / 4 + (size.height / 5) / 2 - textPainter3.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      oldDelegate is DiagramPreviewPainter && oldDelegate.showGrid != showGrid;
}

double min(double a, double b) => a < b ? a : b;
