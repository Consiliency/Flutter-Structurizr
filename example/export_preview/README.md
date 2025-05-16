# Export Preview Example

A Flutter example application demonstrating the export preview functionality for Structurizr diagrams. This example shows how to implement a real-time preview system for diagram exports in various formats.

## Features

- **Multiple Export Formats**: Support for PNG, SVG, PlantUML, Mermaid, DOT/Graphviz, and DSL formats
- **Real-time Preview Updates**: Debounced preview generation that updates as export options change
- **Format-specific Options**: Different options for each export format
- **Transparent Background Support**: Visual preview of transparency using a checkerboard pattern
- **Export Progress Simulation**: Realistic progress reporting during export
- **Memory-efficient Rendering**: Options for handling large diagrams
- **Format-specific Preview Widgets**: Specialized preview widgets for different export formats

## Implementation Details

The example demonstrates several key concepts:

1. **Debounced Updates**: Using `Timer` to throttle preview generation and prevent excessive updates
2. **Progress Reporting**: Realistic progress indicators with stage-specific messages
3. **Transparent Background Handling**: Checkerboard pattern for visualizing transparency
4. **SVG Metadata Extraction**: Regex-based extraction of SVG dimensions and element count
5. **Custom Painting**: Using `CustomPainter` to render diagram previews
6. **Format-specific Preview Widgets**: Specialized widgets for SVG, PNG, and text-based formats

## Usage

Run the example with:

```bash
flutter run -d chrome  # For web
flutter run            # For desktop/mobile
```

Or use the convenience script:

```bash
./run_example.sh
```

## Key Components

- **SvgPreviewWidget**: Specialized widget for SVG preview with metadata extraction
- **PngPreviewWidget**: PNG preview widget with transparent background support
- **TextPreviewWidget**: Code preview for text-based formats (PlantUML, Mermaid, etc.)
- **CheckerboardBackground**: Custom painter for visualizing transparent backgrounds
- **DiagramPreviewPainter**: Custom painter for rendering mock diagram previews

## Integration

This example can be integrated into the main Structurizr application by:

1. Adding the preview widgets to the export dialog
2. Connecting real exporters instead of the mock implementations
3. Implementing proper file saving functionality
4. Adding support for additional export options as needed

## Troubleshooting

- If previews are generating too frequently, increase the debounce timeout
- For memory issues with large diagrams, enable the "Memory-efficient Rendering" option
- If SVG preview metadata is incorrect, check the RegExp patterns used for extraction
