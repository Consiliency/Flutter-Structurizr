import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart' as flutter_md;
import 'package:flutter_markdown/flutter_markdown.dart' show MarkdownElementBuilder, MarkdownStyleSheet;
import 'package:markdown/markdown.dart' as md;

/// Extension for task lists in Markdown
/// ```
/// - [ ] Incomplete task
/// - [x] Complete task
/// ```
class TaskListSyntax extends md.BlockSyntax {
  static final _pattern = RegExp(r'^[ ]{0,3}([-*+])\s+\[([ xX])\]\s+(.*)$');

  @override
  RegExp get pattern => _pattern;

  @override
  bool canParse(md.BlockParser parser) {
    final match = pattern.firstMatch(parser.current.content);
    return match != null;
  }

  @override
  md.Node parse(md.BlockParser parser) {
    final match = pattern.firstMatch(parser.current.content)!;
    final bullet = match.group(1)!;
    final checked = match.group(2)!.toLowerCase() == 'x';
    final text = match.group(3)!;

    final itemLines = <String>[text];
    parser.advance();

    // Handle any potential indented continuation lines
    while (!parser.isDone) {
      final nextLine = parser.current.content;
      final continueMatch = RegExp(r'^[ ]{2,}(.*)$').firstMatch(nextLine);
      if (continueMatch != null) {
        itemLines.add(continueMatch.group(1)!);
        parser.advance();
      } else {
        break;
      }
    }

    final content = itemLines.join('\n');
    final taskItem = TaskListItem(bullet, checked, content);
    
    return md.Element('task-list', [taskItem]);
  }
}

/// Represents a task list item in Markdown
class TaskListItem extends md.Element {
  final String bullet;
  final bool checked;
  final String content;

  TaskListItem(this.bullet, this.checked, this.content)
      : super('task-list-item', [md.Text(content)]) {
    attributes['bullet'] = bullet;
    attributes['checked'] = checked.toString();
  }
}

/// Builder for rendering task list items
class TaskListBuilder extends flutter_md.MarkdownElementBuilder {
  final bool isDarkMode;

  TaskListBuilder({this.isDarkMode = false});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    if (element is TaskListItem) {
      return _buildTaskItem(element, preferredStyle);
    } else if (element.tag == 'task-list') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: (element.children ?? [])
            .map((child) => child is TaskListItem 
                ? _buildTaskItem(child, preferredStyle)
                : const SizedBox.shrink())
            .toList(),
      );
    }
    return null;
  }

  Widget _buildTaskItem(TaskListItem item, TextStyle? style) {
    final checked = item.checked;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: checked,
              onChanged: null, // Read-only checkbox
              fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                if (checked) {
                  return isDarkMode ? Colors.blue.shade700 : Colors.blue.shade600;
                }
                return isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200;
              }),
              checkColor: isDarkMode ? Colors.white : Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DefaultTextStyle(
              style: (style ?? const TextStyle()).copyWith(
                decoration: checked ? TextDecoration.lineThrough : null,
                color: checked 
                    ? (isDarkMode ? Colors.white54 : Colors.black54)
                    : (isDarkMode ? Colors.white : Colors.black87),
              ),
              child: Text(item.content),
            ),
          ),
        ],
      ),
    );
  }
}

/// Extension for image handling in Markdown with additional options
/// ```
/// ![Alt text](path/to/image?width=300&height=200&caption=Image caption)
/// ```
class EnhancedImageSyntax extends md.InlineSyntax {
  EnhancedImageSyntax() : super(r'!\[(.*?)\]\((.*?)(?:\?(.+))?\)');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final alt = match[1] ?? '';
    final url = match[2] ?? '';
    
    // Parse optional parameters if present
    final params = <String, String>{};
    if (match.groupCount >= 3 && match[3] != null) {
      final paramString = match[3]!;
      final paramPairs = paramString.split('&');
      
      for (final pair in paramPairs) {
        final parts = pair.split('=');
        if (parts.length == 2) {
          params[parts[0]] = parts[1];
        }
      }
    }
    
    parser.addNode(EnhancedImageElement(alt, url, params));
    return true;
  }
}

/// A custom element for enhanced images
class EnhancedImageElement extends md.Element {
  final String alt;
  final String url;
  final Map<String, String> params;

  EnhancedImageElement(this.alt, this.url, this.params) : super('enhanced-image', []) {
    attributes['alt'] = alt;
    attributes['src'] = url;
    
    // Store parameters as attributes
    params.forEach((key, value) {
      attributes[key] = value;
    });
  }

  /// Gets the width of the image, defaults to null (auto)
  double? get width => params.containsKey('width') ? double.tryParse(params['width']!) : null;
  
  /// Gets the height of the image, defaults to null (auto)
  double? get height => params.containsKey('height') ? double.tryParse(params['height']!) : null;
  
  /// Gets the caption for the image, if any
  String? get caption => params['caption'];
  
  /// Gets the alignment for the image, defaults to center
  String get alignment => params['align'] ?? 'center';
  
  /// Gets the border radius for the image, defaults to 0
  double get borderRadius => params.containsKey('radius') ? double.tryParse(params['radius']!) ?? 0 : 0;
}

/// Builder for rendering enhanced images
class EnhancedImageBuilder extends flutter_md.MarkdownElementBuilder {
  final bool isDarkMode;
  final bool enableCaching;
  final Map<String, ImageProvider> _imageCache = {};

  EnhancedImageBuilder({this.isDarkMode = false, this.enableCaching = true});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    if (element is EnhancedImageElement) {
      return _buildEnhancedImage(element);
    }
    return null;
  }

  Widget _buildEnhancedImage(EnhancedImageElement element) {
    // Get properties from element
    final src = element.url;
    final alt = element.alt;
    final width = element.width;
    final height = element.height;
    final caption = element.caption;
    final alignment = _parseAlignment(element.alignment);
    final borderRadius = element.borderRadius;
    
    // Get or create image provider
    final imageProvider = _getImageProvider(src);
    
    // Create the image widget
    final imageWidget = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image(
        image: imageProvider,
        width: width,
        height: height,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width ?? 300,
            height: height ?? 200,
            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.broken_image,
                    size: 48,
                    color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load image',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                    ),
                  ),
                  if (alt.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      alt,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return Container(
            width: width ?? 300,
            height: height ?? 200,
            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / 
                      loadingProgress.expectedTotalBytes!
                    : null,
                color: isDarkMode ? Colors.blue.shade300 : Colors.blue,
              ),
            ),
          );
        },
      ),
    );
    
    // Wrap with caption if provided
    if (caption != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Align(
            alignment: alignment,
            child: imageWidget,
          ),
          const SizedBox(height: 8),
          Text(
            Uri.decodeComponent(caption),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
            ),
          ),
        ],
      );
    }
    
    return Align(
      alignment: alignment,
      child: imageWidget,
    );
  }

  ImageProvider _getImageProvider(String src) {
    if (enableCaching && _imageCache.containsKey(src)) {
      return _imageCache[src]!;
    }
    
    ImageProvider provider;
    if (src.startsWith('http://') || src.startsWith('https://')) {
      provider = NetworkImage(src);
    } else if (src.startsWith('asset:')) {
      final assetPath = src.substring(6); // Remove 'asset:' prefix
      provider = AssetImage(assetPath);
    } else {
      // Assume it's a file path
      provider = AssetImage(src);
    }
    
    if (enableCaching) {
      _imageCache[src] = provider;
    }
    
    return provider;
  }

  Alignment _parseAlignment(String align) {
    switch (align.toLowerCase()) {
      case 'left':
        return Alignment.centerLeft;
      case 'right':
        return Alignment.centerRight;
      case 'center':
      default:
        return Alignment.center;
    }
  }
}

/// Extension for advanced table rendering in Markdown using only public APIs
class EnhancedTableBuilder extends MarkdownElementBuilder {
  final bool isDarkMode;

  EnhancedTableBuilder({this.isDarkMode = false});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    if (element.tag != 'table') return null;

    // Parse table header and rows from the element tree
    final rows = <List<Widget>>[];
    List<Widget>? headerCells;

    for (final row in element.children ?? []) {
      if (row is md.Element && row.tag == 'tr') {
        final cells = <Widget>[];
        for (final cell in row.children ?? []) {
          if (cell is md.Element && (cell.tag == 'th' || cell.tag == 'td')) {
            cells.add(Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                cell.textContent,
                style: cell.tag == 'th'
                    ? const TextStyle(fontWeight: FontWeight.bold)
                    : const TextStyle(),
              ),
            ));
          }
        }
        if (row.children!.isNotEmpty && row.children!.first is md.Element && (row.children!.first as md.Element).tag == 'th') {
          headerCells = cells;
        } else {
          rows.add(cells);
        }
      }
    }

    // Build the table
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Table(
          children: [
            if (headerCells != null)
              TableRow(
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                ),
                children: headerCells!,
              ),
            ...rows.asMap().entries.map((entry) {
              final index = entry.key;
              final rowCells = entry.value;
              return TableRow(
                decoration: BoxDecoration(
                  color: index % 2 == 0
                      ? (isDarkMode ? Colors.grey.shade900 : Colors.white)
                      : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50),
                ),
                children: rowCells,
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Extension for metadata block in Markdown
/// ```
/// ---
/// title: Document Title
/// author: Author Name
/// date: 2023-05-20
/// tags: tag1, tag2, tag3
/// ---
/// ```
class MetadataBlockSyntax extends md.BlockSyntax {
  static final _pattern = RegExp(r'^---$');
  static final _endPattern = RegExp(r'^---$');

  @override
  RegExp get pattern => _pattern;

  @override
  bool canParse(md.BlockParser parser) {
    if (!parser.matches(pattern)) return false;
    // Allow parsing at any position (no public API for start-of-doc)
    return true;
  }

  @override
  md.Node parse(md.BlockParser parser) {
    // Skip the opening '---'
    parser.advance();
    
    final metadata = <String, String>{};
    final lines = <String>[];
    
    // Parse metadata lines until we hit the closing '---'
    while (!parser.isDone) {
      final line = parser.current.content;
      
      if (_endPattern.hasMatch(line)) {
        parser.advance();
        break;
      }
      
      lines.add(line);
      
      // Parse key: value
      final match = RegExp(r'^([^:]+):\s*(.*)$').firstMatch(line);
      if (match != null) {
        final key = match.group(1)!.trim();
        final value = match.group(2)!.trim();
        metadata[key] = value;
      }
      
      parser.advance();
    }
    
    return MetadataElement(metadata, lines.join('\n'));
  }
}

/// A custom element for metadata blocks
class MetadataElement extends md.Element {
  final Map<String, String> metadata;
  final String rawContent;

  MetadataElement(this.metadata, this.rawContent) : super('metadata', []) {
    // Store metadata as attributes
    metadata.forEach((key, value) {
      attributes[key] = value;
    });
  }

  String? operator [](String key) => metadata[key];
}

/// Builder for rendering metadata blocks
class MetadataBuilder extends flutter_md.MarkdownElementBuilder {
  final bool isDarkMode;
  final bool visible;

  MetadataBuilder({this.isDarkMode = false, this.visible = false});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    if (element is MetadataElement) {
      if (!visible) return const SizedBox.shrink();
      
      return Container(
        margin: const EdgeInsets.only(bottom: 24.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Document Metadata',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            ...element.metadata.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
    }
    return null;
  }
}

/// Extension for keyboard shortcuts with the <kbd>Key</kbd> tag
class KeyboardShortcutSyntax extends md.InlineSyntax {
  KeyboardShortcutSyntax() : super(r'<kbd>(.*?)</kbd>');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final key = match[1] ?? '';
    parser.addNode(KeyboardShortcutElement(key));
    return true;
  }
}

/// A custom element for keyboard shortcuts
class KeyboardShortcutElement extends md.Element {
  final String key;

  KeyboardShortcutElement(this.key) : super('kbd', []) {
    attributes['key'] = key;
  }
}

/// Builder for rendering keyboard shortcuts
class KeyboardShortcutBuilder extends flutter_md.MarkdownElementBuilder {
  final bool isDarkMode;

  KeyboardShortcutBuilder({this.isDarkMode = false});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    if (element.tag == 'kbd') {
      final key = element.attributes['key'] ?? '';
      
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
        margin: const EdgeInsets.symmetric(horizontal: 2.0),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
          ),
          boxShadow: [
            BoxShadow(
              color: isDarkMode 
                  ? Colors.black.withOpacity(0.3) 
                  : Colors.black.withOpacity(0.1),
              offset: const Offset(0, 1),
              blurRadius: 1.0,
            ),
          ],
        ),
        child: Text(
          key,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      );
    }
    return null;
  }
}