import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  
  /// Whether to use offline mode (bundled asciidoctor.js).
  final bool useOfflineMode;
  
  /// Chunk size for progressive rendering (in characters)
  /// Defaults to 100,000 characters. Set to 0 to disable chunking.
  final int chunkSize;
  
  /// Whether to enable content caching
  final bool enableCaching;
  
  /// Maximum memory allocated for caching (in KB)
  final int maxCacheSize;

  /// Optionally provide a WebViewController (for testing/mocking)
  final WebViewController? controller;

  /// Creates a new AsciiDoc renderer widget.
  const AsciidocRenderer({
    Key? key,
    required this.content,
    this.workspace,
    this.onDiagramSelected,
    this.initialScrollOffset = 0.0,
    this.isDarkMode = false,
    this.useOfflineMode = true,
    this.chunkSize = 100000,
    this.enableCaching = true,
    this.maxCacheSize = 10240, // 10MB default cache limit
    this.controller,
  }) : super(key: key);

  @override
  State<AsciidocRenderer> createState() => _AsciidocRendererState();
}

class _AsciidocRendererState extends State<AsciidocRenderer> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String? _asciidoctorJs;
  String? _highlightJs;
  
  // Content rendering state
  bool _isProcessingChunks = false;
  int _totalChunks = 1;
  int _processedChunks = 0;
  
  // Performance tracking
  Stopwatch? _renderStopwatch;
  
  // Caching
  static final Map<String, String> _contentCache = {};
  static int _currentCacheSize = 0;

  @override
  void initState() {
    super.initState();
    _renderStopwatch = Stopwatch()..start();
    _loadResources();
  }

  /// Loads JavaScript resources needed for rendering.
  Future<void> _loadResources() async {
    print('[AsciidocRenderer] _loadResources called, _isLoading=$_isLoading, _hasError=$_hasError');
    if (!widget.useOfflineMode) {
      _initController();
      return;
    }
    
    try {
      // Check if content is already in cache
      if (widget.enableCaching) {
        final contentHash = _computeHash(widget.content);
        if (_contentCache.containsKey(contentHash)) {
          debugPrint('AsciidocRenderer: Content found in cache');
          _initController(cachedContentHash: contentHash);
          return;
        }
      }
      
      // Load JavaScript resources in parallel
      final futures = [
        rootBundle.loadString('assets/js/asciidoctor.min.js'),
        rootBundle.loadString('assets/js/highlight.min.js'),
      ];
      
      final results = await Future.wait(futures);
      _asciidoctorJs = results[0];
      _highlightJs = results[1];
      
      _initController();
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
        _errorMessage = 'Failed to load resources: $e';
      });
    }
  }
  
  /// Computes a simple hash of the content for caching.
  String _computeHash(String content) {
    int hash = 0;
    for (int i = 0; i < content.length; i++) {
      hash = (hash * 31 + content.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    return hash.toString();
  }
  
  /// Manages the content cache, removing old entries if needed.
  void _manageCache(String contentHash, String renderedHTML) {
    if (!widget.enableCaching) return;
    
    // Calculate size of rendered HTML in KB
    final sizeInKB = renderedHTML.length ~/ 1024;
    
    // If adding this would exceed cache size, remove oldest entries
    if (_currentCacheSize + sizeInKB > widget.maxCacheSize) {
      // Simple LRU-like eviction: remove first entries until we have enough space
      while (_contentCache.isNotEmpty && 
             _currentCacheSize + sizeInKB > widget.maxCacheSize) {
        final firstKey = _contentCache.keys.first;
        final removedSize = _contentCache[firstKey]!.length ~/ 1024;
        _contentCache.remove(firstKey);
        _currentCacheSize -= removedSize;
      }
    }
    
    // Add to cache
    _contentCache[contentHash] = renderedHTML;
    _currentCacheSize += sizeInKB;
    
    debugPrint('AsciidocRenderer: Cache size: $_currentCacheSize KB / ${widget.maxCacheSize} KB');
  }

  void _initController({String? cachedContentHash}) {
    _controller = widget.controller ?? WebViewController();
    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(widget.isDarkMode ? Colors.grey.shade900 : Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            print('[AsciidocRenderer] onPageFinished called');
            if (cachedContentHash != null) {
              _renderStopwatch?.stop();
              debugPrint('AsciidocRenderer: Rendered from cache in ${_renderStopwatch?.elapsedMilliseconds}ms');
              setState(() {
                _isLoading = false;
              });
              return;
            }
            if (_isProcessingChunks) return;
            _renderStopwatch?.stop();
            debugPrint('AsciidocRenderer: Initial render complete in ${_renderStopwatch?.elapsedMilliseconds}ms');
            setState(() {
              _isLoading = false;
            });
            if (widget.initialScrollOffset > 0) {
              _controller.runJavaScript(
                'window.scrollTo(0, ${widget.initialScrollOffset});'
              );
            }
          },
          onNavigationRequest: (request) {
            if (request.url.startsWith('diagram:')) {
              final diagramKey = request.url.substring(8);
              if (widget.onDiagramSelected != null) {
                widget.onDiagramSelected!(diagramKey);
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            print('[AsciidocRenderer] onWebResourceError called: errorCode=${error.errorCode}, description=${error.description}');
            setState(() {
              _hasError = true;
              _isLoading = false;
              _errorMessage = 'Error ${error.errorCode}: ${error.description}';
            });
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
      ..addJavaScriptChannel(
        'Console',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint('AsciidocRenderer: ${message.message}');
        },
      )
      ..addJavaScriptChannel(
        'RenderProgress',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            final Map<String, dynamic> progress = jsonDecode(message.message);
            final currentChunk = progress['currentChunk'] as int;
            final totalChunks = progress['totalChunks'] as int;
            setState(() {
              _processedChunks = currentChunk;
              _totalChunks = totalChunks;
            });
            if (currentChunk == totalChunks) {
              _isProcessingChunks = false;
              _finalizeRendering();
            }
          } catch (e) {
            debugPrint('AsciidocRenderer: Error parsing progress data: $e');
          }
        },
      )
      ..addJavaScriptChannel(
        'RenderedContent',
        onMessageReceived: (JavaScriptMessage message) {
          if (widget.enableCaching) {
            final contentHash = _computeHash(widget.content);
            _manageCache(contentHash, message.message);
          }
        },
      );
      
    // If we have cached content, use it
    if (cachedContentHash != null) {
      _controller.loadHtmlString(_buildHtmlPageWithCache(cachedContentHash));
    } else {
      // Otherwise build the page from scratch
      final htmlPage = _buildHtmlPage();
      _controller.loadHtmlString(htmlPage);
      
      // If using chunking for large content, set up processing state
      if (widget.chunkSize > 0 && widget.content.length > widget.chunkSize) {
        _isProcessingChunks = true;
        _totalChunks = (widget.content.length / widget.chunkSize).ceil();
      }
    }
    print('[AsciidocRenderer] _initController using controller hashCode=${_controller.hashCode}');
  }
  
  /// Finalizes rendering after all chunks are processed
  void _finalizeRendering() {
    _renderStopwatch?.stop();
    debugPrint('AsciidocRenderer: Complete render finished in ${_renderStopwatch?.elapsedMilliseconds}ms');
    setState(() {
      _isLoading = false;
    });
    
    // Set initial scroll position if specified
    if (widget.initialScrollOffset > 0) {
      _controller.runJavaScript(
        'window.scrollTo(0, ${widget.initialScrollOffset});'
      );
    }
    
    // Save rendered content for caching
    if (widget.enableCaching) {
      _controller.runJavaScript('RenderedContent.postMessage(document.documentElement.outerHTML);');
    }
  }

  /// Builds HTML page with cached content
  String _buildHtmlPageWithCache(String contentHash) {
    final String cachedHTML = _contentCache[contentHash] ?? '';
    
    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>AsciiDoc Content (Cached)</title>
      </head>
      <body>
        $cachedHTML
        <script>
          // Signal that the page is loaded from cache
          setTimeout(function() {
            Console.postMessage('AsciiDoc loaded from cache');
          }, 100);
        </script>
      </body>
      </html>
    ''';
  }
  
  /// Builds complete HTML page for rendering AsciiDoc content
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
          
          // Toc styles
          #toc { background-color: #333333; border-color: #424242; }
          #toc ul li a { color: #e0e0e0; }
          #toc ul li a:hover { color: #90CAF9; }
          .sectlevel1 > li > a { color: #BBDEFB !important; }
          #toc.toc2 #toctitle { color: #E3F2FD; border-bottom-color: #616161; }
          
          // Syntax highlighting
          .hljs-keyword { color: #ff79c6; }
          .hljs-built_in { color: #8be9fd; }
          .hljs-string { color: #f1fa8c; }
          .hljs-comment { color: #6272a4; }
          .hljs-function { color: #50fa7b; }
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
          
          // Toc styles
          #toc { background-color: #f5f5f5; border-color: #e0e0e0; }
          #toc ul li a { color: #757575; }
          #toc ul li a:hover { color: #2196F3; }
          .sectlevel1 > li > a { color: #1565C0 !important; }
          #toc.toc2 #toctitle { color: #0D47A1; border-bottom-color: #e0e0e0; }
          
          // Syntax highlighting
          .hljs-keyword { color: #d73a49; }
          .hljs-built_in { color: #0086b3; }
          .hljs-string { color: #032f62; }
          .hljs-comment { color: #6a737d; }
          .hljs-function { color: #6f42c1; }
        ''';

    // JavaScript resources
    final String asciidoctorScript = widget.useOfflineMode
        ? '<script>${_asciidoctorJs ?? ''}</script>'
        : '<script src="https://cdn.jsdelivr.net/npm/asciidoctor@2.2.6/dist/browser/asciidoctor.min.js"></script>';
        
    final String highlightScript = widget.useOfflineMode && _highlightJs != null
        ? '<script>${_highlightJs}</script>'
        : '<script src="https://cdn.jsdelivr.net/npm/highlight.js@11.7.0/lib/highlight.min.js"></script>';

    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>AsciiDoc Content</title>
        
        <!-- Include Asciidoctor.js -->
        ${asciidoctorScript}
        
        <!-- Include Highlight.js for syntax highlighting -->
        ${highlightScript}
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/highlight.js@11.7.0/styles/${widget.isDarkMode ? 'atom-one-dark' : 'github'}.min.css">
        
        <!-- Add progress indicator styles -->
        <style id="progress-styles">
          #rendering-progress {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            height: 4px;
            background-color: #e0e0e0;
            z-index: 9999;
          }
          #progress-bar {
            height: 100%;
            background-color: ${widget.isDarkMode ? '#64B5F6' : '#2196F3'};
            width: 0%;
            transition: width 0.3s ease;
          }
          .progress-overlay {
            position: fixed;
            right: 16px;
            bottom: 16px;
            background-color: ${widget.isDarkMode ? 'rgba(33, 33, 33, 0.8)' : 'rgba(255, 255, 255, 0.8)'};
            color: ${widget.isDarkMode ? '#fff' : '#333'};
            padding: 8px 16px;
            border-radius: 4px;
            font-size: 12px;
            z-index: 9999;
            box-shadow: 0 2px 4px rgba(0,0,0,0.2);
          }
        </style>
        
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
          
          /* Table of Contents styling */
          #toc {
            border: 1px solid;
            border-radius: 4px;
            padding: 1em;
            margin-bottom: 1.5em;
          }
          
          #toc ul {
            list-style-type: none;
            padding-left: 1.5em;
          }
          
          #toc ul li {
            margin: 0.5em 0;
          }
          
          #toc ul li a {
            text-decoration: none;
          }
          
          #toc.toc2 {
            position: fixed;
            left: 0;
            top: 0;
            bottom: 0;
            width: 15em;
            overflow-y: auto;
            padding: 1em;
            border-right: 1px solid;
            z-index: 1000;
          }
          
          #toc.toc2 #toctitle {
            margin-top: 0;
            margin-bottom: 0.8em;
            font-size: 1.2em;
            font-weight: bold;
            padding-bottom: 0.5em;
            border-bottom: 1px solid;
          }
          
          body.toc2 {
            padding-left: 15em;
          }
          
          /* Apply theme styles */
          ${themeStyles}
        </style>
      </head>
      <body>
        <!-- Add progress indicators to DOM -->
        <div id="rendering-progress"><div id="progress-bar"></div></div>
        <div id="progress-stats" class="progress-overlay" style="display: none;"></div>
        
        <script>
          // Create helper for progressive rendering
          var progressiveRenderer = {
            totalChunks: 1,
            currentChunk: 0,
            chunkSize: ${widget.chunkSize},
            content: "",
            html: "",
            asciidoctor: null,
            renderingTime: 0,
            startTime: performance.now(),
            
            // Initialize with content
            init: function(content) {
              this.content = content;
              if (this.chunkSize > 0 && content.length > this.chunkSize) {
                this.totalChunks = Math.ceil(content.length / this.chunkSize);
              }
              this.updateProgress();
            },
            
            // Process all content (for small documents) or first chunk (for large ones)
            processInitialContent: function() {
              try {
                this.asciidoctor = Asciidoctor();
                var processingStartTime = performance.now();
                
                // For small documents or if chunking is disabled, process everything at once
                if (this.totalChunks === 1 || this.chunkSize <= 0) {
                  this.html = this.asciidoctor.convert(this.content, { 
                    safe: 'safe', 
                    attributes: { 
                      'showtitle': true, 
                      'icons': 'font',
                      'source-highlighter': 'highlightjs',
                      'toc': 'auto',
                      'toc-placement': 'auto'
                    } 
                  });
                  document.body.innerHTML = this.html;
                  this.currentChunk = 1;
                } else {
                  // For large documents, process the first chunk
                  var firstChunk = this.content.substring(0, this.chunkSize);
                  this.html = this.asciidoctor.convert(firstChunk, { 
                    safe: 'safe', 
                    attributes: { 
                      'showtitle': true, 
                      'icons': 'font',
                      'source-highlighter': 'highlightjs',
                      'toc': 'auto',
                      'toc-placement': 'auto'
                    } 
                  });
                  document.body.innerHTML = this.html;
                  this.currentChunk = 1;
                  
                  // Schedule the processing of the remaining chunks
                  this.scheduleNextChunk();
                }
                
                this.renderingTime += performance.now() - processingStartTime;
                this.updateProgress();
                this.setupEventHandlers();
                
                if (this.totalChunks === 1) {
                  this.finalizeRendering();
                }
              } catch (error) {
                Console.postMessage('Error rendering AsciiDoc: ' + error.message);
                document.body.innerHTML = '<div style="color: red; padding: 20px;"><h3>Error rendering AsciiDoc</h3><p>' + error.message + '</p><pre>' + error.stack + '</pre></div>';
              }
            },
            
            // Process the next chunk of content
            processNextChunk: function() {
              if (this.currentChunk >= this.totalChunks) return;
              
              var processingStartTime = performance.now();
              try {
                var startIndex = this.currentChunk * this.chunkSize;
                var endIndex = Math.min(startIndex + this.chunkSize, this.content.length);
                var chunk = this.content.substring(startIndex, endIndex);
                
                // Convert this chunk
                var chunkHtml = this.asciidoctor.convert(chunk, {
                  safe: 'safe',
                  attributes: {
                    'showtitle': false, // No title in subsequent chunks
                    'icons': 'font',
                    'source-highlighter': 'highlightjs'
                  }
                });
                
                // Extract just the content (not the full document)
                var tempDiv = document.createElement('div');
                tempDiv.innerHTML = chunkHtml;
                var contentElements = tempDiv.querySelectorAll('body > *');
                
                // Append to the existing content
                var container = document.querySelector('.content') || document.body;
                for (var i = 0; i < contentElements.length; i++) {
                  container.appendChild(contentElements[i]);
                }
                
                this.currentChunk++;
                this.renderingTime += performance.now() - processingStartTime;
                this.updateProgress();
                
                // Process highlights for the new content
                var newCodeBlocks = container.querySelectorAll('pre code:not(.hljs)');
                newCodeBlocks.forEach(function(block) {
                  hljs.highlightElement(block);
                });
                
                // Setup event handlers for the new content
                this.setupEventHandlers();
                
                // Schedule the next chunk or finalize
                if (this.currentChunk < this.totalChunks) {
                  this.scheduleNextChunk();
                } else {
                  this.finalizeRendering();
                }
              } catch (error) {
                Console.postMessage('Error processing chunk ' + this.currentChunk + ': ' + error.message);
                this.currentChunk++; // Skip this chunk and continue
                if (this.currentChunk < this.totalChunks) {
                  this.scheduleNextChunk();
                } else {
                  this.finalizeRendering();
                }
              }
            },
            
            // Schedule the next chunk with a small delay to allow UI updates
            scheduleNextChunk: function() {
              var self = this;
              setTimeout(function() {
                self.processNextChunk();
              }, 10); // Small delay to allow UI to update
            },
            
            // Set up event handlers for diagram links
            setupEventHandlers: function() {
              document.querySelectorAll('.diagram-link:not([data-event-bound])').forEach(function(link) {
                link.setAttribute('data-event-bound', 'true');
                link.addEventListener('click', function(e) {
                  e.preventDefault();
                  var key = link.getAttribute('data-diagram-key');
                  DiagramLink.postMessage(key);
                });
              });
            },
            
            // Update progress indicators
            updateProgress: function() {
              var progressBar = document.getElementById('progress-bar');
              var progressStats = document.getElementById('progress-stats');
              var progressPercent = (this.currentChunk / this.totalChunks) * 100;
              
              progressBar.style.width = progressPercent + '%';
              
              if (this.totalChunks > 1) {
                progressStats.style.display = 'block';
                progressStats.textContent = 'Rendering: ' + 
                  this.currentChunk + '/' + this.totalChunks + ' chunks ' +
                  '(' + Math.round(progressPercent) + '%) - ' +
                  Math.round(this.renderingTime) + 'ms';
              }
              
              // Report progress to Flutter
              RenderProgress.postMessage(JSON.stringify({
                currentChunk: this.currentChunk,
                totalChunks: this.totalChunks,
                renderingTimeMs: Math.round(this.renderingTime)
              }));
            },
            
            // Finalize the rendering process
            finalizeRendering: function() {
              var totalTime = performance.now() - this.startTime;
              Console.postMessage('AsciiDoc rendered successfully in ' + Math.round(totalTime) + 'ms ' +
                                '(processing: ' + Math.round(this.renderingTime) + 'ms)');
              
              // Hide progress indicators after a delay
              setTimeout(function() {
                var progressBar = document.getElementById('rendering-progress');
                var progressStats = document.getElementById('progress-stats');
                progressBar.style.display = 'none';
                progressStats.style.display = 'none';
              }, 2000);
            }
          };
          
          // Start the rendering process
          try {
            // Initialize with content
            var content = \`${_escapeJs(processedContent)}\`;
            progressiveRenderer.init(content);
            
            // Begin processing
            progressiveRenderer.processInitialContent();
          } catch (error) {
            // Handle errors
            Console.postMessage('Error initializing renderer: ' + error.message);
            document.body.innerHTML = '<div style="color: red; padding: 20px;"><h3>Error rendering AsciiDoc</h3><p>' + error.message + '</p><pre>' + error.stack + '</pre></div>';
          }
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
    print('[AsciidocRenderer] build: _isLoading=$_isLoading, _hasError=$_hasError');
    if (_hasError) {
      print('[AsciidocRenderer] Building error widget: \x1B[31m$_errorMessage\x1B[0m');
      debugPrint('[AsciidocRenderer] Building error widget: $_errorMessage');
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Error rendering AsciiDoc',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: () {
                print('[AsciidocRenderer] Retry button pressed');
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                  _errorMessage = '';
                  _processedChunks = 0;
                  _totalChunks = 1;
                  _isProcessingChunks = false;
                  _renderStopwatch = Stopwatch()..start();
                });
                _loadResources();
              },
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          Container(
            color: widget.isDarkMode ? Colors.grey.shade900 : Colors.white,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  if (_isProcessingChunks && _totalChunks > 1) ...[  
                    const SizedBox(height: 16),
                    Text(
                      'Rendering large document...',
                      style: TextStyle(
                        color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 200,
                      child: LinearProgressIndicator(
                        value: _processedChunks / _totalChunks,
                        backgroundColor: widget.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.isDarkMode ? Colors.blue.shade300 : Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Processing chunk $_processedChunks of $_totalChunks',
                      style: TextStyle(
                        color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
  
  @override
  void dispose() {
    _renderStopwatch?.stop();
    super.dispose();
  }
}