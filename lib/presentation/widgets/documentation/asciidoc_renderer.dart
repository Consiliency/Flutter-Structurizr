import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// A widget for rendering AsciiDoc content.
class AsciidocRenderer extends StatefulWidget {
  /// The AsciiDoc content to render.
  final String content;
  
  /// Optional workspace for resolving diagram references.
  final Workspace? workspace;
  
  /// Called when a diagram is selected.
  final Function(String)? onDiagramSelected;
  
  /// Optional initial scroll position.
  final double initialScrollOffset;
  
  /// Whether to use dark mode.
  final bool isDarkMode;

  /// Creates a new AsciiDoc renderer widget.
  const AsciidocRenderer({
    Key? key,
    required this.content,
    this.workspace,
    this.onDiagramSelected,
    this.initialScrollOffset = 0.0,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  State<AsciidocRenderer> createState() => _AsciidocRendererState();
}

class _AsciidocRendererState extends State<AsciidocRenderer> {
  late WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(widget.isDarkMode ? Colors.grey.shade900 : Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            setState(() {
              _isLoading = false;
            });
            
            // Set initial scroll position if specified
            if (widget.initialScrollOffset > 0) {
              _controller.runJavaScript(
                'window.scrollTo(0, ${widget.initialScrollOffset});'
              );
            }
          },
          onNavigationRequest: (request) {
            // Check if the URL is a diagram link
            if (request.url.startsWith('diagram:')) {
              final diagramKey = request.url.substring(8); // Remove 'diagram:' prefix
              if (widget.onDiagramSelected != null) {
                widget.onDiagramSelected!(diagramKey);
              }
              return NavigationDecision.prevent;
            }
            
            // Allow normal navigation
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'DiagramLink',
        onMessageReceived: (JavaScriptMessage message) {
          if (widget.onDiagramSelected != null) {
            widget.onDiagramSelected!(message.message);
          }
        },
      )
      ..loadHtmlString(_buildHtmlPage());
  }

  String _buildHtmlPage() {
    // Process the AsciiDoc content to replace custom diagram syntax
    final String processedContent = _processContent(widget.content);
    
    // Theme styles
    final String themeStyles = widget.isDarkMode
        ? '''
          body {
            background-color: #212121;
            color: #f5f5f5;
          }
          a { color: #64B5F6; }
          pre { background-color: #424242; border-color: #616161; }
          code { background-color: #424242; color: #64B5F6; }
          .admonitionblock { background-color: #424242; border-color: #616161; }
          table { border-color: #616161; }
          table th { background-color: #424242; }
          hr { border-color: #616161; }
          blockquote { border-left-color: #616161; color: #bdbdbd; }
          .diagram-link { background-color: #1565C0; color: white; }
          .diagram-link:hover { background-color: #1976D2; }
        '''
        : '''
          body {
            background-color: #ffffff;
            color: #212121;
          }
          a { color: #2196F3; }
          pre { background-color: #f5f5f5; border-color: #e0e0e0; }
          code { background-color: #f5f5f5; color: #0D47A1; }
          .admonitionblock { background-color: #f5f5f5; border-color: #e0e0e0; }
          table { border-color: #e0e0e0; }
          table th { background-color: #f5f5f5; }
          hr { border-color: #e0e0e0; }
          blockquote { border-left-color: #e0e0e0; color: #757575; }
          .diagram-link { background-color: #E3F2FD; color: #0D47A1; }
          .diagram-link:hover { background-color: #BBDEFB; }
        ''';

    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>AsciiDoc Content</title>
        
        <!-- Include Asciidoctor.js from CDN -->
        <script src="https://cdn.jsdelivr.net/npm/asciidoctor@2.2.6/dist/browser/asciidoctor.min.js"></script>
        
        <style>
          body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            line-height: 1.6;
            padding: 16px;
            margin: 0;
          }
          
          h1, h2, h3, h4, h5, h6 {
            margin-top: 1.5em;
            margin-bottom: 0.5em;
            font-weight: 600;
          }
          
          h1 { font-size: 2em; }
          h2 { font-size: 1.75em; }
          h3 { font-size: 1.5em; }
          h4 { font-size: 1.25em; }
          h5 { font-size: 1em; }
          h6 { font-size: 0.85em; }
          
          p, ul, ol {
            margin-top: 0;
            margin-bottom: 1em;
          }
          
          a {
            text-decoration: none;
          }
          
          a:hover {
            text-decoration: underline;
          }
          
          code {
            font-family: SFMono-Regular, Consolas, "Liberation Mono", Menlo, monospace;
            padding: 0.2em 0.4em;
            border-radius: 3px;
          }
          
          pre {
            padding: 16px;
            overflow: auto;
            border-radius: 3px;
            border: 1px solid;
          }
          
          pre code {
            background-color: transparent;
            padding: 0;
          }
          
          blockquote {
            margin-left: 0;
            padding-left: 1em;
            border-left: 3px solid;
          }
          
          table {
            border-collapse: collapse;
            width: 100%;
            margin-bottom: 1em;
          }
          
          table, th, td {
            border: 1px solid;
          }
          
          th, td {
            padding: 8px;
            text-align: left;
          }
          
          hr {
            border: 0;
            border-top: 1px solid;
            margin: 1.5em 0;
          }
          
          .admonitionblock {
            margin: 1em 0;
            padding: 1em;
            border: 1px solid;
            border-radius: 3px;
          }
          
          .admonitionblock .icon {
            display: inline-block;
            margin-right: 0.5em;
            font-weight: bold;
          }
          
          .admonitionblock.note .icon:before { content: "Note: "; color: #03A9F4; }
          .admonitionblock.tip .icon:before { content: "Tip: "; color: #4CAF50; }
          .admonitionblock.important .icon:before { content: "Important: "; color: #FF9800; }
          .admonitionblock.warning .icon:before { content: "Warning: "; color: #F44336; }
          .admonitionblock.caution .icon:before { content: "Caution: "; color: #F44336; }
          
          .diagram-link {
            display: inline-flex;
            align-items: center;
            padding: 8px 12px;
            margin: 16px 0;
            border-radius: 4px;
            cursor: pointer;
            transition: background-color 0.2s;
          }
          
          .diagram-link:before {
            content: "↔";
            margin-right: 8px;
            font-weight: bold;
          }
          
          ${themeStyles}
        </style>
      </head>
      <body>
        <script>
          // Initialize Asciidoctor.js
          var asciidoctor = Asciidoctor();
          
          // Convert the AsciiDoc content to HTML
          var content = `${_escapeJs(processedContent)}`;
          var html = asciidoctor.convert(content, { safe: 'safe', attributes: { 'showtitle': true, 'icons': 'font' } });
          
          // Insert the converted content
          document.body.innerHTML = html;
          
          // Process diagram links
          document.querySelectorAll('.diagram-link').forEach(function(link) {
            link.addEventListener('click', function(e) {
              e.preventDefault();
              var key = link.getAttribute('data-diagram-key');
              DiagramLink.postMessage(key);
            });
          });
        </script>
      </body>
      </html>
    ''';
  }

  /// Process the AsciiDoc content to handle diagram references.
  String _processContent(String content) {
    // Find and replace diagram references using the custom syntax: embed:diagram-key[Title]
    // This is similar to the syntax used in the MarkdownRenderer but adapted for AsciiDoc
    final diagramPattern = RegExp(r'embed:([^\[\]]+)\[(.*?)\]');
    
    return content.replaceAllMapped(diagramPattern, (match) {
      final diagramKey = match.group(1)!;
      final title = match.group(2)!;
      
      // Create a diagram link that will be processed by JavaScript
      return '++++\n<div class="diagram-link" data-diagram-key="$diagramKey">$title</div>\n++++';
    });
  }

  /// Escape JavaScript special characters in a string.
  String _escapeJs(String content) {
    return content
        .replaceAll('\\', '\\\\')
        .replaceAll('`', '\\`')
        .replaceAll('\$', '\\\$')
        .replaceAll('\r\n', '\n')
        .replaceAll('\n', '\\n');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}