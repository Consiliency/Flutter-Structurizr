# Export Preview Implementation

This document describes the implementation of the export preview functionality in the Flutter Structurizr project.

## Overview

Export preview provides users with a real-time visualization of how their diagram will appear when exported in different formats. The implementation includes:

1. **Debounced Preview Generation**: Throttles preview updates to prevent excessive rendering
2. **Format-specific Preview Widgets**: Specialized renderers for different export formats
3. **Transparent Background Visualization**: Checkerboard pattern for visualizing transparency
4. **Progress Reporting**: Detailed status updates during preview generation
5. **Memory-efficient Rendering**: Optimized preview generation for large diagrams

## Implementation Details

### 1. Debounced Preview Generation

Preview generation is debounced to prevent excessive updates when users change settings rapidly:

```dart
void _generatePreviewDebounced() {
  // Cancel existing timer
  _debounceTimer.cancel();
  
  // Set a new timer to generate preview after delay
  _debounceTimer = Timer(const Duration(milliseconds: 500), () {
    _generatePreview();
  });
}
```

This implementation waits for 500ms after the last change before generating a new preview, significantly reducing the load on the rendering engine.

### 2. Format-specific Preview Widgets

The implementation includes specialized preview widgets for different export formats:

#### SVG Preview Widget

```dart
class SvgPreviewWidget extends StatelessWidget {
  final String svgContent;
  final bool transparentBackground;

  // Extracts and displays SVG metadata
  @override
  Widget build(BuildContext context) {
    // Extract SVG dimensions with regex
    final widthMatch = RegExp(r'width="(\d+)"').firstMatch(svgContent);
    final heightMatch = RegExp(r'height="(\d+)"').firstMatch(svgContent);
    
    // Count elements in SVG
    final elementCount = _countElements(svgContent);
    
    // ... visualization and metadata display logic
  }
}
```

#### PNG Preview Widget

```dart
class PngPreviewWidget extends StatelessWidget {
  final Uint8List? imageData;
  final bool transparentBackground;
  final double width;
  final double height;
  
  // Displays PNG preview with metadata
  @override
  Widget build(BuildContext context) {
    // ... visualization and metadata display logic
  }
}
```

#### Text Preview Widget

```dart
class TextPreviewWidget extends StatelessWidget {
  final String content;
  final String format;
  
  // Displays formatted text content with statistics
  @override
  Widget build(BuildContext context) {
    // ... formatted content display with syntax highlighting
  }
}
```

### 3. Transparent Background Visualization

A checkerboard pattern is implemented to visualize transparency in exported images:

```dart
class CheckerboardBackground extends StatelessWidget {
  final int squareSize;
  
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: CheckerboardPainter(squareSize: squareSize),
    );
  }
}

class CheckerboardPainter extends CustomPainter {
  final int squareSize;
  
  @override
  void paint(Canvas canvas, Size size) {
    // Alternating gray and white squares
    for (int y = 0; y < (size.height / squareSize).ceil(); y++) {
      for (int x = 0; x < (size.width / squareSize).ceil(); x++) {
        final isEven = (x + y) % 2 == 0;
        final rect = Rect.fromLTWH(
          x * squareSize.toDouble(), 
          y * squareSize.toDouble(), 
          squareSize.toDouble(), 
          squareSize.toDouble(),
        );
        
        canvas.drawRect(rect, isEven ? grayPaint : whitePaint);
      }
    }
  }
}
```

This pattern alternates light gray and white squares to make transparent areas of exported images clearly visible to users.

### 4. Progress Reporting

The implementation provides detailed progress reporting with stage-specific messages:

```dart
// Non-linear progress simulation with different stages
if (currentProgress < 0.2) {
  _progressMessage = 'Initializing export renderer...';
} else if (currentProgress < 0.4) {
  _progressMessage = 'Rendering boundaries...';
} else if (currentProgress < 0.6) {
  _progressMessage = 'Rendering relationships...';
} else if (currentProgress < 0.8) {
  _progressMessage = 'Rendering elements...';
} else {
  _progressMessage = 'Generating preview... ${(currentProgress * 100).toInt()}%';
}
```

This approach provides more context to the user about the current operation rather than just showing a percentage.

### 5. Memory-efficient Rendering

For large diagrams, memory-efficient rendering is implemented:

```dart
// Memory-efficient rendering option
CheckboxListTile(
  title: const Text('Memory-Efficient Rendering'),
  subtitle: const Text('For large diagrams'),
  value: _useMemoryEfficientRendering,
  onChanged: (value) {
    setState(() {
      _useMemoryEfficientRendering = value ?? true;
    });
  },
),
```

When enabled, this option instructs the renderer to use a multi-pass approach that conserves memory at the expense of slightly slower rendering.

## Integration with Export Dialog

The preview functionality is integrated into the export dialog, allowing users to see immediate updates as they change export settings:

```dart
class ExportDialog extends StatefulWidget {
  // Dialog implementation with export options and preview pane
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Diagram'),
      content: Row(
        children: [
          // Left panel: Export options
          _buildExportOptions(),
          
          // Right panel: Preview
          _buildPreview(),
        ],
      ),
      // ... dialog actions
    );
  }
}
```

## Usage Example

```dart
// Show export dialog with preview
showDialog(
  context: context,
  builder: (context) => ExportDialog(
    workspace: workspace,
    view: selectedView,
    onExport: (format, options) {
      // Handle export
    },
  ),
);
```

## Testing

Testing the export preview functionality includes:

1. **Widget Tests**: Verify that preview widgets render correctly
2. **Format-specific Tests**: Test specialized preview rendering for each format
3. **Integration Tests**: Test integration with the export dialog
4. **Memory Tests**: Verify memory-efficient rendering for large diagrams

Basic tests are implemented but comprehensive testing is limited by dependency conflicts between Flutter test framework and third-party packages.

## Known Limitations

1. **SVG Rendering**: The current implementation doesn't use a WebView for SVG rendering, limiting the preview accuracy
2. **Preview Size**: The preview is currently a fixed size and doesn't support zooming or panning
3. **Test Environment**: Some tests are affected by dependency conflicts with the `image` package

## Future Enhancements

1. **WebView SVG Rendering**: Implement accurate SVG rendering using a WebView component
2. **Interactive Preview**: Add zoom and pan controls for previews
3. **Side-by-side Comparison**: Allow comparison of different export formats
4. **Preview Caching**: Cache previews to improve performance for repeated exports

## Best Practices

When implementing export preview functionality:

1. **Debounce Updates**: Always debounce preview updates to prevent excessive rendering
2. **Format-specific Widgets**: Create specialized widgets for different export formats
3. **Progress Reporting**: Provide detailed, context-aware progress updates
4. **Memory Efficiency**: Implement memory-efficient rendering for large diagrams
5. **Error Handling**: Provide clear error messages when preview generation fails

## References

1. [Export Dialog Implementation](/home/jenner/Code/dart-structurizr/lib/presentation/widgets/export/export_dialog.dart)
2. [PNG Exporter](/home/jenner/Code/dart-structurizr/lib/infrastructure/export/png_exporter.dart)
3. [SVG Exporter](/home/jenner/Code/dart-structurizr/lib/infrastructure/export/svg_exporter.dart)
4. [Export Preview Example](/home/jenner/Code/dart-structurizr/example/export_preview)
EOF < /dev/null
