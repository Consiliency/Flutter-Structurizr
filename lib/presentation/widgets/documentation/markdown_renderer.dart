import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_structurizr/util/themes/github_dark.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/markdown_extensions.dart' as md_ext;

/// A custom syntax extension for embedding diagrams
class DiagramSyntax extends md.InlineSyntax {
  DiagramSyntax() : super(r'!\[(.*?)\]\(embed:(.*?)(?:\?(.+))?\)');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final title = match[1]!;
    final viewKey = match[2]!;
    
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
    
    parser.addNode(DiagramElement(title, viewKey, params));
    return true;
  }
}

/// A custom element for embedded diagrams
class DiagramElement extends md.Element {
  final String title;
  final String viewKey;
  final Map<String, String> params;

  DiagramElement(this.title, this.viewKey, [this.params = const {}]) : super('diagram', []);

  /// Gets the width of the diagram, defaults to 'auto'
  String get width => params['width'] ?? 'auto';
  
  /// Gets the height of the diagram, defaults to 'auto'
  String get height => params['height'] ?? 'auto';
  
  /// Whether to show title for the diagram, defaults to true
  bool get showTitle => params['showTitle']?.toLowerCase() != 'false';

  @override
  String toString() => 'DiagramElement: $title ($viewKey) $params';
}

/// A builder for embedded diagrams
class EmbeddedDiagramBuilder extends MarkdownElementBuilder {
  final Workspace? workspace;
  final Function(String)? onDiagramSelected;
  final bool isDarkMode;

  EmbeddedDiagramBuilder({
    this.workspace, 
    this.onDiagramSelected,
    this.isDarkMode = false,
  });

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    if (element is DiagramElement) {
      if (workspace == null) {
        return Container(
          padding: const EdgeInsets.all(8.0),
          margin: const EdgeInsets.symmetric(vertical: 16.0),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(4.0),
            color: isDarkMode ? Colors.grey.shade800.withOpacity(0.3) : Colors.grey.shade50,
          ),
          child: Row(
            children: [
              Icon(
                Icons.insert_chart_outlined, 
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Diagram: ${element.title} (Workspace not available)',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      // Apply width and height constraints if specified
      final double? width = element.width == 'auto' ? null : double.tryParse(element.width);
      final double? height = element.height == 'auto' ? null : double.tryParse(element.height);
      
      // Create a button that shows the diagram when clicked
      return Container(
        width: width,
        height: height,
        constraints: BoxConstraints(
          maxWidth: width ?? double.infinity,
          maxHeight: height ?? double.infinity,
        ),
        margin: const EdgeInsets.symmetric(vertical: 16.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDarkMode 
                ? Colors.blue.shade800
                : Colors.blue.shade300,
          ),
          borderRadius: BorderRadius.circular(4.0),
          color: isDarkMode 
              ? Color(0xFF0D2C54).withOpacity(0.5)
              : Colors.blue.shade50,
        ),
        child: InkWell(
          onTap: () {
            if (onDiagramSelected != null) {
              onDiagramSelected!(element.viewKey);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (element.showTitle) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.account_tree, 
                        color: isDarkMode ? Colors.blue.shade300 : Colors.blue,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          element.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                ],
                
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.preview,
                          size: 48,
                          color: isDarkMode ? Colors.blue.shade200 : Colors.blue.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Click to view diagram',
                          style: TextStyle(
                            color: isDarkMode ? Colors.blue.shade200 : Colors.blue.shade700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '(${element.viewKey})',
                          style: TextStyle(
                            color: isDarkMode 
                                ? Colors.grey.shade400 
                                : Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return null;
  }
}

/// A syntax highlighter for code blocks
class SyntaxHighlighterBuilder extends MarkdownElementBuilder {
  final bool isDarkMode;

  SyntaxHighlighterBuilder({this.isDarkMode = false});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    String? language = element.attributes['class'];
    
    if (language != null && language.startsWith('language-')) {
      language = language.substring(9); // Remove 'language-' prefix
    } else {
      language = 'dart'; // Default to Dart if no language is specified
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4.0),
        child: HighlightView(
          element.textContent,
          language: language,
          theme: isDarkMode ? githubDarkTheme : githubTheme,
          padding: const EdgeInsets.all(12.0),
          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
        ),
      ),
    );
  }
}

/// A widget for rendering Markdown content with Structurizr-specific extensions.
class MarkdownRenderer extends StatelessWidget {
  /// The Markdown content to render.
  final String content;
  
  /// Optional workspace for resolving diagram references.
  final Workspace? workspace;
  
  /// Called when a diagram is selected.
  final Function(String)? onDiagramSelected;
  
  /// Optional initial scroll position.
  final double initialScrollOffset;
  
  /// Whether to apply section numbering to headers.
  final bool enableSectionNumbering;
  
  /// Whether to use dark mode.
  final bool isDarkMode;
  
  /// Additional extensions for markdown processing.
  final List<md.BlockSyntax>? blockSyntaxes;
  
  /// Additional extensions for markdown processing.
  final List<md.InlineSyntax>? inlineSyntaxes;
  
  /// Whether to enable task list support.
  final bool enableTaskLists;
  
  /// Whether to enable enhanced image handling.
  final bool enableEnhancedImages;
  
  /// Whether to show metadata blocks.
  final bool showMetadata;
  
  /// Whether to cache images.
  final bool enableImageCaching;

  /// Creates a new markdown renderer widget.
  const MarkdownRenderer({
    Key? key,
    required this.content,
    this.workspace,
    this.onDiagramSelected,
    this.initialScrollOffset = 0.0,
    this.enableSectionNumbering = true,
    this.isDarkMode = false,
    this.blockSyntaxes,
    this.inlineSyntaxes,
    this.enableTaskLists = true,
    this.enableEnhancedImages = true,
    this.showMetadata = false,
    this.enableImageCaching = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scrollController = ScrollController(
      initialScrollOffset: initialScrollOffset,
    );

    String processedContent = content;
    
    // Add section numbering if enabled
    if (enableSectionNumbering) {
      processedContent = _addSectionNumbering(processedContent);
    }

    // Build the custom extension set
    final blockExtensions = <md.BlockSyntax>[
      if (blockSyntaxes != null) ...blockSyntaxes!,
      md.FencedCodeBlockSyntax(),
      if (enableTaskLists) md_ext.TaskListSyntax(),
      if (showMetadata) md_ext.MetadataBlockSyntax(),
    ];
    
    final inlineExtensions = <md.InlineSyntax>[
      if (inlineSyntaxes != null) ...inlineSyntaxes!,
      DiagramSyntax(),
      if (enableEnhancedImages) md_ext.EnhancedImageSyntax(),
      md_ext.KeyboardShortcutSyntax(),
      md.InlineHtmlSyntax(),
    ];
    
    // Build the element builders map
    final builders = <String, MarkdownElementBuilder>{
      'code': SyntaxHighlighterBuilder(isDarkMode: isDarkMode),
      'diagram': EmbeddedDiagramBuilder(
        workspace: workspace,
        onDiagramSelected: onDiagramSelected,
        isDarkMode: isDarkMode,
      ),
      'table': md_ext.EnhancedTableBuilder(isDarkMode: isDarkMode),
      'taREDACTEDlist': md_ext.TaskListBuilder(isDarkMode: isDarkMode),
      'taREDACTEDlist-item': md_ext.TaskListBuilder(isDarkMode: isDarkMode),
      if (enableEnhancedImages) 'enhanced-image': md_ext.EnhancedImageBuilder(
        isDarkMode: isDarkMode,
        enableCaching: enableImageCaching,
      ),
      if (showMetadata) 'metadata': md_ext.MetadataBuilder(
        isDarkMode: isDarkMode,
        visible: showMetadata,
      ),
      'kbd': md_ext.KeyboardShortcutBuilder(isDarkMode: isDarkMode),
    };
    
    return Markdown(
      controller: scrollController,
      data: processedContent,
      selectable: true,
      builders: builders,
      extensionSet: md.ExtensionSet(
        blockExtensions,
        inlineExtensions,
      ),
      styleSheet: MarkdownStyleSheet(
        h1: theme.textTheme.headlineMedium!.copyWith(
          color: isDarkMode ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
        h2: theme.textTheme.titleLarge!.copyWith(
          color: isDarkMode ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
        ),
        h3: theme.textTheme.titleMedium!.copyWith(
          color: isDarkMode ? Colors.white70 : Colors.black87,
          fontWeight: FontWeight.bold,
        ),
        h4: theme.textTheme.titleSmall!.copyWith(
          color: isDarkMode ? Colors.white70 : Colors.black87,
          fontWeight: FontWeight.bold,
        ),
        h5: theme.textTheme.bodyLarge!.copyWith(
          color: isDarkMode ? Colors.white70 : Colors.black87,
          fontWeight: FontWeight.bold,
        ),
        h6: theme.textTheme.bodyLarge!.copyWith(
          color: isDarkMode ? Colors.white70 : Colors.black54,
          fontWeight: FontWeight.bold,
        ),
        p: theme.textTheme.bodyMedium!.copyWith(
          color: isDarkMode ? Colors.white70 : Colors.black87,
        ),
        code: theme.textTheme.bodySmall!.copyWith(
          color: isDarkMode ? Colors.lightBlue.shade300 : Colors.blue.shade700,
          fontFamily: 'monospace',
          backgroundColor: isDarkMode 
              ? Colors.grey.shade800 
              : Colors.grey.shade200,
        ),
        blockquote: theme.textTheme.bodyMedium!.copyWith(
          color: isDarkMode ? Colors.white54 : Colors.grey.shade700,
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: isDarkMode ? Colors.white30 : Colors.grey.shade300,
              width: 4.0,
            ),
          ),
        ),
        blockquotePadding: const EdgeInsets.only(left: 16.0),
        tableHead: const TextStyle(fontWeight: FontWeight.bold),
        tableBody: theme.textTheme.bodyMedium,
        tableBorder: TableBorder.all(
          color: isDarkMode ? Colors.white30 : Colors.grey.shade300,
          width: 1.0,
        ),
        tableColumnWidth: const FlexColumnWidth(),
        tableCellsPadding: const EdgeInsets.all(8.0),
        tableCellsDecoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade900 : Colors.white,
        ),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDarkMode ? Colors.white30 : Colors.grey.shade300,
              width: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  /// Adds section numbering to the markdown headers.
  /// 
  /// This function adds hierarchical section numbers to markdown headers.
  /// For example:
  /// # Header -> # 1 Header
  /// ## Subheader -> ## 1.1 Subheader
  /// # Another Header -> # 2 Another Header
  String _addSectionNumbering(String content) {
    final lines = content.split('\n');
    final numbers = [0, 0, 0, 0, 0, 0]; // h1, h2, h3, h4, h5, h6
    final processedLines = <String>[];
    
    bool isCodeBlock = false;
    String? codeBlockMarker;
    
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      // Skip numbering within code blocks
      if (line.trim().startsWith('```')) {
        if (!isCodeBlock) {
          isCodeBlock = true;
          codeBlockMarker = line.trim();
        } else if (line.trim() == codeBlockMarker) {
          isCodeBlock = false;
          codeBlockMarker = null;
        }
        processedLines.add(line);
        continue;
      }
      
      if (isCodeBlock) {
        processedLines.add(line);
        continue;
      }
      
      // Check for ATX-style headers (# Header)
      final atxMatch = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(line);
      if (atxMatch != null) {
        final level = atxMatch.group(1)!.length - 1; // 0-based index
        
        // Reset lower level counters
        for (var j = level + 1; j < numbers.length; j++) {
          numbers[j] = 0;
        }
        
        // Increment the current level
        numbers[level]++;
        
        // Build section number
        final sectionNumber = numbers
            .sublist(0, level + 1)
            .where((num) => num > 0)
            .join('.');
        
        // Replace the header
        final title = atxMatch.group(2)!;
        processedLines.add('${atxMatch.group(1)!} $sectionNumber $title');
        continue;
      }
      
      // Check for Setext-style headers (Header\n===== or Header\n-----)
      if (i < lines.length - 1) {
        final nextLine = lines[i + 1];
        
        if (nextLine.startsWith('=') && nextLine.trim().replaceAll('=', '').isEmpty) {
          // h1
          numbers[0]++;
          
          // Reset all other counters
          for (var j = 1; j < numbers.length; j++) {
            numbers[j] = 0;
          }
          
          // Replace the header and add both lines
          processedLines.add('# ${numbers[0]} ${lines[i]}');
          processedLines.add(nextLine);
          i++; // Skip the next line (underline)
          continue;
        }
        
        if (nextLine.startsWith('-') && nextLine.trim().replaceAll('-', '').isEmpty) {
          // h2
          numbers[1]++;
          
          // Reset lower level counters
          for (var j = 2; j < numbers.length; j++) {
            numbers[j] = 0;
          }
          
          // Replace the header and add both lines
          processedLines.add('## ${numbers[0]}.${numbers[1]} ${lines[i]}');
          processedLines.add(nextLine);
          i++; // Skip the next line (underline)
          continue;
        }
      }
      
      // Not a header, add the line as is
      processedLines.add(line);
    }
    
    return processedLines.join('\n');
  }
}