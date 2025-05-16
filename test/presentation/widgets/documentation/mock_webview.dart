import 'package:flutter/material.dart' hide Container;
import 'package:flutter/widgets.dart' as widgets show Container;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'dart:async';

/// A mock implementation of WebViewPlatform for testing
class MockWebViewPlatform extends WebViewPlatform {
  // Track the last created controller for testing
  PlatformWebViewController? lastCreatedController;
  final List<NavigationDelegate> delegates = [];
  
  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    final controller = MockPlatformWebViewController(params);
    lastCreatedController = controller;
    return controller;
  }

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) {
    return MockPlatformWebViewWidget(params: params);
  }
  
  @override
  PlatformWebViewCookieManager createPlatformCookieManager(
    PlatformWebViewCookieManagerCreationParams params,
  ) {
    throw UnimplementedError();
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) {
    return MockPlatformNavigationDelegate(params);
  }
}

/// A mock implementation of PlatformWebViewController for testing
class MockPlatformWebViewController extends PlatformWebViewController {
  MockPlatformWebViewController(PlatformWebViewControllerCreationParams params)
      : super.implementation(params);
  
  NavigationDelegate? _pendingDelegate;
  
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == Symbol('runJavaScript') ||
        invocation.memberName == Symbol('runJavaScriptReturningResult') ||
        invocation.memberName == Symbol('setNavigationDelegate') ||
        invocation.memberName == Symbol('addJavaScriptChannel') ||
        invocation.memberName == Symbol('loadHtmlString')) {
      // Methods we've implemented
      return null;
    }
    
    if (invocation.isGetter) {
      return null;
    } else if (invocation.isSetter) {
      return null;
    } else {
      return Future<dynamic>.value();
    }
  }
  // Keep track of JavaScript channels for testing
  final Map<String, JavaScriptChannelParams> _channels = {};
  NavigationDelegate? _navigationDelegate;
  String? _lastLoadedHtml;
  String _cachedContent = '';
  bool _isLoading = true;
  bool _hasError = false;
  bool _isDarkMode = false;
  // Simulate caching behavior
  final Map<String, String> _contentCache = {};
  final List<Timer> _timers = [];
  bool _disposed = false;

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> setBackgroundColor(Color color) async {}

  @override
  Future<void> setNavigationDelegate(NavigationDelegate delegate) async {
    print('[MockPlatformWebViewController] setNavigationDelegate called on controller hashCode=\x1B[36m${hashCode}\x1B[0m with delegate=$delegate');
    _navigationDelegate = delegate;
    _pendingDelegate = delegate;
  }

  @override
  Future<void> addJavaScriptChannel(JavaScriptChannelParams params) async {
    print('[MockPlatformWebViewController] addJavaScriptChannel: ${params.name}');
    _channels[params.name] = params;
  }

  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) async {
    ensureDelegateWired();
    print('[MockPlatformWebViewController] loadHtmlString called on controller hashCode=\x1B[36m${hashCode}\x1B[0m: _hasError=$_hasError, _isLoading=$_isLoading');
    // Cancel any existing timers before starting a new load
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
    print('[MockPlatformWebViewController] loadHtmlString: $html');
    _lastLoadedHtml = html;
    _isLoading = true;
    _hasError = false;
    // Detect dark mode for test verification
    _isDarkMode = html.contains('dark-mode') || html.contains('background-color: #1a1a1a');
    // Simulate page loading
    _navigationDelegate?.onPageStarted?.call('about:blank');
    final timer = Timer(const Duration(milliseconds: 50), () {
      print('[MockPlatformWebViewController] Timer fired (disposed=$_disposed, hasError=$_hasError)');
      if (_disposed || _hasError) {
        for (final t in _timers) {
          t.cancel();
        }
        _timers.clear();
        print('[MockPlatformWebViewController] Timer cancelled due to disposed or error');
        return;
      }
      print('[MockPlatformWebViewController] Timer firing onPageFinished');
      _navigationDelegate?.onPageFinished?.call('about:blank');
      _isLoading = false;
    });
    print('[MockPlatformWebViewController] Timer created in loadHtmlString');
    _timers.add(timer);
  }

  @override
  Future<void> loadRequest(LoadRequestParams params) async {}
  
  @override
  Future<void> loadFile(String absoluteFilePath) async {}

  @override
  Future<void> runJavaScript(String javaScript) async {
    print('[MockPlatformWebViewController] runJavaScript: $javaScript');
    // Simulate processing javascript
    if (javaScript.contains('processNextChunk')) {
      _simulateChunkProcessing();
    } else if (javaScript.contains('initializeRenderer')) {
      _simulateRendererInitialization();
    } else if (javaScript.contains('simulateDiagramClick')) {
      // Simulate diagram click from JS
      if (_channels.containsKey('AsciidocDiagram')) {
        final channel = _channels['AsciidocDiagram']!;
        channel.onMessageReceived?.call(JavaScriptMessage(message: '{"diagramKey": "SystemContext"}'));
      }
    } else if (javaScript.contains('simulateLinkClick')) {
      // Simulate link click from JS
      if (_channels.containsKey('AsciidocLink')) {
        final channel = _channels['AsciidocLink']!;
        channel.onMessageReceived?.call(JavaScriptMessage(message: 'https://www.google.com'));
      }
    }
  }
  
  Future<void> _simulateChunkProcessing() async {
    // Simulate chunk processing and progress updates
    for (int i = 0; i < 3; i++) {
      await Future.delayed(const Duration(milliseconds: 10));
      if (_channels.containsKey('AsciidocProgress')) {
        final progressChannel = _channels['AsciidocProgress']!;
        // Simulate progress message from JavaScript
        progressChannel.onMessageReceived?.call(
          JavaScriptMessage(message: '{"progress": ${(i + 1) * 33}, "currentChunk": $i, "totalChunks": 3}')
        );
      }
    }
    
    // Simulate completion
    if (_channels.containsKey('AsciidocRenderer')) {
      final rendererChannel = _channels['AsciidocRenderer']!;
      rendererChannel.onMessageReceived?.call(
        JavaScriptMessage(message: '{"status": "complete", "renderTime": 120}')
      );
    }
  }
  
  Future<void> _simulateRendererInitialization() async {
    await Future.delayed(const Duration(milliseconds: 20));
    if (_channels.containsKey('AsciidocRenderer')) {
      final rendererChannel = _channels['AsciidocRenderer']!;
      rendererChannel.onMessageReceived?.call(
        JavaScriptMessage(message: '{"status": "initialized"}')
      );
    }
  }
  
  @override
  Future<String> runJavaScriptReturningResult(String javaScript) async {
    // Simulate caching behavior
    if (javaScript.contains('getCachedContent')) {
      final contentHash = javaScript.split('"')[1]; // Extract hash from JS string
      if (_contentCache.containsKey(contentHash)) {
        return _contentCache[contentHash]!;
      }
      return 'null'; // Cache miss
    }
    
    // Check if renderer is ready
    if (javaScript.contains('isRendererReady')) {
      return !_isLoading ? 'true' : 'false';
    }
    
    return '';
  }
  
  @override
  Future<void> setUserAgent(String? userAgent) async {}
  
  @override
  Future<String?> getUserAgent() async {
    return null;
  }
  
  @override
  Future<void> enableZoom(bool enabled) async {}
  
  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {}
  
  @override
  Future<void> reload() async {
    _isLoading = true;
    _navigationDelegate?.onPageStarted?.call('about:blank');
    
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!_hasError) {
        _navigationDelegate?.onPageFinished?.call('about:blank');
        _isLoading = false;
      }
    });
  }
  
  @override
  Future<void> clearCache() async {
    _contentCache.clear();
  }
  
  @override
  Future<void> clearLocalStorage() async {}
  
  @override
  Future<void> setOnPlatformPermissionRequest(
    void Function(PlatformWebViewPermissionRequest request)? onPermissionRequest,
  ) async {}
  
  // Test helper methods
  void simulateError() {
    ensureDelegateWired();
    print('[MockPlatformWebViewController] simulateError called on controller hashCode=\x1B[36m${hashCode}\x1B[0m');
    _hasError = true;
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
    _navigationDelegate?.onWebResourceError?.call(
      WebResourceError(
        errorCode: -1,
        description: 'Simulated error',
        errorType: WebResourceErrorType.connect,
        isForMainFrame: true,
      ),
    );
    // Also fire onPageFinished to simulate error completion
    _navigationDelegate?.onPageFinished?.call('about:blank');
    _isLoading = false;
  }
  
  void simulateRendererReady() {
    ensureDelegateWired();
    print('[MockPlatformWebViewController] simulateRendererReady called on controller hashCode=\x1B[36m${hashCode}\x1B[0m');
    _navigationDelegate?.onPageFinished?.call('about:blank');
    _isLoading = false;
  }
  
  // Simulate caching a document
  void addToCache(String hash, String html) {
    _contentCache[hash] = html;
    // Cancel and clear all timers after caching
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
  }

  // Public getters for test access
  Map<String, JavaScriptChannelParams> get channels => _channels;
  String? get lastLoadedHtml => _lastLoadedHtml;

  /// Simulate a diagram click from JavaScript for test purposes
  void triggerDiagramClick(String key) {
    if (_channels.containsKey('AsciidocDiagram')) {
      final channel = _channels['AsciidocDiagram']!;
      channel.onMessageReceived?.call(JavaScriptMessage(message: '{"diagramKey": "$key"}'));
    }
  }

  /// Simulate a link click from JavaScript for test purposes
  void triggerLinkClick(String url) {
    if (_channels.containsKey('AsciidocLink')) {
      final channel = _channels['AsciidocLink']!;
      channel.onMessageReceived?.call(JavaScriptMessage(message: '{"url": "$url"}'));
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
  }

  /// Dispose all timers and mark as disposed (for use in tests)
  void disposeForTest() {
    dispose();
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
  }

  void ensureDelegateWired() {
    if (_pendingDelegate != null) {
      print('[MockPlatformWebViewController] ensureDelegateWired: wiring pending delegate on controller hashCode=\x1B[36m${hashCode}\x1B[0m');
      _navigationDelegate = _pendingDelegate;
      _pendingDelegate = null;
    }
  }
}

/// A mock implementation of PlatformWebViewWidget for testing
class MockPlatformWebViewWidget extends PlatformWebViewWidget {
  MockPlatformWebViewWidget({PlatformWebViewWidgetCreationParams? params})
      : super.implementation(params ?? PlatformWebViewWidgetCreationParams(controller: MockPlatformWebViewController(const PlatformWebViewControllerCreationParams())));

  @override
  Widget build(BuildContext context) {
    return widgets.Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Text('Mock WebView'),
      ),
    );
  }
}

/// A mock implementation of PlatformNavigationDelegate for testing
class MockPlatformNavigationDelegate extends PlatformNavigationDelegate {
  MockPlatformNavigationDelegate(PlatformNavigationDelegateCreationParams params)
      : super.implementation(params);

  @override
  Future<void> setOnNavigationRequest(FutureOr<NavigationDecision> Function(NavigationRequest) onNavigationRequest) async {
    // No-op for testing
  }

  @override
  Future<void> setOnPageFinished(void Function(String url)? onPageFinished) async {
    // No-op for testing
  }

  @override
  Future<void> setOnPageStarted(void Function(String url)? onPageStarted) async {
    // No-op for testing
  }

  @override
  Future<void> setOnWebResourceError(void Function(WebResourceError error)? onWebResourceError) async {
    // No-op for testing
  }
}

/// A test WebViewController that wraps a MockPlatformWebViewController for injection
class TestWebViewController extends WebViewController {
  TestWebViewController(MockPlatformWebViewController mockController)
      : super.fromPlatform(mockController);

  MockPlatformWebViewController get mock => platform as MockPlatformWebViewController;
}