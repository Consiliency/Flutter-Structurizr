import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/github-dark.dart';

/// A custom syntax extension for embedding diagrams
class DiagramSyntax extends md.InlineSyntax {
  DiagramSyntax() : super(r'!\[(.*?)\]\(embed:(.*?)\)');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final title = match[1]!;
    final viewKey = match[2]!;
    parser.addNode(DiagramElement(title, viewKey));
    return true;
  }
}

/// A custom element for embedded diagrams
class DiagramElement extends md.Element {
  final String title;
  final String viewKey;

  DiagramElement(this.title, this.viewKey) : super('diagram', []);

  @override
  String toString() => 'DiagramElement: $title ($viewKey)';
}

/// A builder for embedded diagrams
class EmbeddedDiagramBuilder extends MarkdownElementBuilder {
  final Workspace? workspace;
  final Function(String)? onDiagramSelected;

  EmbeddedDiagramBuilder({this.workspace, this.onDiagramSelected});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    if (element is DiagramElement) {
      if (workspace == null) {
        return Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Row(
            children: [
              const Icon(Icons.diagram_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Diagram: ${element.title} (Workspace not available)',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        );
      }

      // Create a button that shows the diagram when clicked
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 12.0),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue.shade300),
          borderRadius: BorderRadius.circular(4.0),
          color: Colors.blue.shade50,
        ),
        child: InkWell(
          onTap: () {
            if (onDiagramSelected != null) {
              onDiagramSelected!(element.viewKey);
            }
          },
          child: Row(
            children: [
              const Icon(Icons.account_tree, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      element.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Click to view diagram',
                      style: TextStyle(
                        color: Colors.blue.shade700, 
                        fontSize: 12
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.open_in_new, color: Colors.blue, size: 16),
            ],
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

    return Markdown(
      controller: scrollController,
      data: processedContent,
      selectable: true,
      paddingBuilders: {
        'pre': (element) => const EdgeInsets.all(0),
      },
      builders: {
        'code': SyntaxHighlighterBuilder(isDarkMode: isDarkMode),
        'diagram': EmbeddedDiagramBuilder(
          workspace: workspace,
          onDiagramSelected: onDiagramSelected,
        ),
      },
      extensionSet: md.ExtensionSet(
        [
          if (blockSyntaxes != null) ...blockSyntaxes!,
          md.FencedCodeBlockSyntax(),
        ],
        [
          if (inlineSyntaxes != null) ...inlineSyntaxes!,
          DiagramSyntax(),
          md.InlineHtmlSyntax(),
        ],
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
  String _addSectionNumbering(String content) {
    final lines = content.split('\n');
    final numbers = [0, 0, 0, 0, 0, 0]; // h1, h2, h3, h4, h5, h6
    
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      
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
        lines[i] = '${atxMatch.group(1)!} $sectionNumber $title';
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
          
          // Replace the header
          lines[i] = '${numbers[0]}. ${lines[i]}';
          continue;
        }
        
        if (nextLine.startsWith('-') && nextLine.trim().replaceAll('-', '').isEmpty) {
          // h2
          numbers[1]++;
          
          // Reset lower level counters
          for (var j = 2; j < numbers.length; j++) {
            numbers[j] = 0;
          }
          
          // Replace the header
          lines[i] = '${numbers[0]}.${numbers[1]}. ${lines[i]}';
          continue;
        }
      }
    }
    
    return lines.join('\n');
  }
}