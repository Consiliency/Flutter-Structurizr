import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/asciidoc_renderer.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'dart:async';

import 'mock_webview.dart';

void main() {
  group('AsciidocRenderer - Improved Tests', () {
    // Setup: register mock implementation of WebView
    late MockWebViewPlatform mockPlatform;
    
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      mockPlatform = MockWebViewPlatform();
      WebViewPlatform.instance = mockPlatform;
    });

    // Helper function to build AsciiDoc renderer with common parameters
    Widget buildRenderer({
      required String content,
      bool isDarkMode = false,
      bool useOfflineMode = false,
      bool enableCaching = true,
      int chunkSize = 50000,
      Workspace? workspace,
      void Function(String)? onDiagramSelected,
    }) {
      return MaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: Scaffold(
          body: AsciidocRenderer(
            content: content,
            isDarkMode: isDarkMode,
            useOfflineMode: useOfflineMode,
            enableCaching: enableCaching,
            chunkSize: chunkSize,
            workspace: workspace,
            onDiagramSelected: onDiagramSelected,
          ),
        ),
      );
    }

    testWidgets('renders asciidoc content with loading indicators', (WidgetTester tester) async {
      const asciidocContent = '''
= Test Document
:author: Test Author

== Introduction

This is a test AsciiDoc document.

[source,dart]
----
void main() {
  print('Hello, AsciiDoc!');
}
----
''';

      // Build renderer
      await tester.pumpWidget(buildRenderer(content: asciidocContent));
      
      // Initial loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(WebViewWidget), findsOneWidget);
      
      // Get mock controller
      final mockController = mockPlatform.lastCreatedController as MockPlatformWebViewController;
      
      // Simulate WebView ready
      mockController.simulateRendererReady();
      await tester.pump();
      
      // Loading indicator should be gone after WebView is ready
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(WebViewWidget), findsOneWidget);
    });

    testWidgets('handles errors with error message and retry button', (WidgetTester tester) async {
      const asciidocContent = '= Error Test Document';
      
      // Build renderer
      await tester.pumpWidget(buildRenderer(content: asciidocContent));
      
      // Get mock controller
      final mockController = mockPlatform.lastCreatedController as MockPlatformWebViewController;
      
      // Simulate error
      mockController.simulateError();
      await tester.pump();
      
      // Should show error message and retry button
      expect(find.text('Error rendering AsciiDoc content'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      
      // Tap retry button
      await tester.tap(find.text('Retry'));
      await tester.pump();
      
      // Should show loading indicator again
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Simulate successful rendering after retry
      mockController.simulateRendererReady();
      await tester.pump();
      
      // Error message should be gone
      expect(find.text('Error rendering AsciiDoc content'), findsNothing);
      expect(find.byType(WebViewWidget), findsOneWidget);
    });

    testWidgets('provides progress indicators for large documents', (WidgetTester tester) async {
      // Create a large document (but not actually too large for test)
      final largeContent = '= Large Document\n\n' + 'Sample content. ' * 100;
      
      // Build renderer with small chunk size to trigger chunking
      await tester.pumpWidget(buildRenderer(
        content: largeContent,
        chunkSize: 100, // Very small chunk size to trigger chunking
      ));
      
      // Initial loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Get mock controller
      final mockController = mockPlatform.lastCreatedController as MockPlatformWebViewController;
      
      // Simulate WebView ready
      mockController.simulateRendererReady();
      await tester.pump();
      
      // After WebView is ready, we'll start rendering chunks - progress indicator should still be visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Trigger chunk processing simulation
      await mockController.runJavaScript('processNextChunk()');
      await tester.pump();
      
      // Simulate progress updates being received
      // Our mock will automatically trigger progress updates
      
      // Complete the rendering
      if (mockController.channels.containsKey('AsciidocRenderer')) {
        final channel = mockController.channels['AsciidocRenderer']!;
        channel.onMessageReceived?.call(
          JavaScriptMessage(message: '{"status": "complete", "renderTime": 150}')
        );
      }
      await tester.pump();
      
      // Progress indicator should be gone after rendering completes
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('supports diagram embedding with callbacks', (WidgetTester tester) async {
      // Content with embedded diagram
      const contentWithDiagram = '''
= System Documentation

== Overview

Here's our system diagram:

embed:SystemContext[width=800,height=600,title=System Context Diagram]
''';

      // Track selected diagram
      String? selectedDiagramKey;
      
      // Create a sample workspace
      final workspace = Workspace(
        id: 1,
        name: 'Test Workspace',
        description: 'Test workspace for diagram embedding',
        model: const Model(),
      );
      
      // Build renderer with diagram callback
      await tester.pumpWidget(buildRenderer(
        content: contentWithDiagram,
        workspace: workspace,
        onDiagramSelected: (key) {
          selectedDiagramKey = key;
        },
      ));
      
      // Get mock controller
      final mockController = mockPlatform.lastCreatedController as MockPlatformWebViewController;
      
      // Simulate WebView ready
      mockController.simulateRendererReady();
      await tester.pump();
      
      // Verify WebView is properly initialized
      expect(find.byType(WebViewWidget), findsOneWidget);
      
      // Simulate diagram click from JavaScript
      if (mockController.channels.containsKey('AsciidocDiagram')) {
        final channel = mockController.channels['AsciidocDiagram']!;
        channel.onMessageReceived?.call(
          JavaScriptMessage(message: '{"diagramKey": "SystemContext"}')
        );
      }
      await tester.pump();
      
      // Verify diagram selection callback worked
      expect(selectedDiagramKey, equals('SystemContext'));
    });

    testWidgets('handles links with callback', (WidgetTester tester) async {
      // Content with links
      const contentWithLinks = '''
= Documentation with Links

== External Links

* [Link to Google](https://www.google.com)
* [Link to another document](doc:OtherDocument)
''';

      // Track clicked link
      String? clickedLink;
      
      // Build renderer with link callback
      await tester.pumpWidget(buildRenderer(
        content: contentWithLinks,
        onDiagramSelected: (key) {
          clickedLink = key;
        },
      ));
      
      // Get mock controller
      final mockController = mockPlatform.lastCreatedController as MockPlatformWebViewController;
      
      // Simulate WebView ready
      mockController.simulateRendererReady();
      await tester.pump();
      
      // Simulate link click from JavaScript
      if (mockController.channels.containsKey('AsciidocLink')) {
        final channel = mockController.channels['AsciidocLink']!;
        channel.onMessageReceived?.call(
          JavaScriptMessage(message: '{"url": "https://www.google.com"}')
        );
      }
      await tester.pump();
      
      // Verify link callback worked
      expect(clickedLink, equals('https://www.google.com'));
      
      // Simulate document link click
      if (mockController.channels.containsKey('AsciidocLink')) {
        final channel = mockController.channels['AsciidocLink']!;
        channel.onMessageReceived?.call(
          JavaScriptMessage(message: '{"url": "doc:OtherDocument"}')
        );
      }
      await tester.pump();
      
      // Verify document link callback worked
      expect(clickedLink, equals('doc:OtherDocument'));
    });

    testWidgets('applies correct theme based on isDarkMode', (WidgetTester tester) async {
      const content = '= Theme Test';
      
      // Build renderer in dark mode
      await tester.pumpWidget(buildRenderer(
        content: content,
        isDarkMode: true,
      ));
      
      // Get mock controller
      final mockController = mockPlatform.lastCreatedController as MockPlatformWebViewController;
      
      // Extract the loaded HTML to verify it contains dark mode styles
      final loadedHtml = mockController.lastLoadedHtml ?? '';
      
      // Verify HTML contains dark mode CSS
      expect(loadedHtml.contains('dark-mode') || loadedHtml.contains('background-color: #1a1a1a'), isTrue);
      
      // Rebuild with light mode
      await tester.pumpWidget(buildRenderer(
        content: content,
        isDarkMode: false,
      ));
      
      // Get new controller (or same one if reused)
      final newController = mockPlatform.lastCreatedController as MockPlatformWebViewController;
      
      // Extract the loaded HTML again
      final newLoadedHtml = newController.lastLoadedHtml ?? '';
      
      // Light mode should have different styles
      // Specific check depends on implementation details, but we can at least verify it's different
      expect(newLoadedHtml != loadedHtml, isTrue);
    });

    testWidgets('supports content caching for performance', (WidgetTester tester) async {
      const content = '= Cached Document';
      const contentHash = 'cached-content-hash';
      
      // Build renderer with caching enabled
      await tester.pumpWidget(buildRenderer(
        content: content,
        enableCaching: true,
      ));
      
      // Get mock controller
      final mockController = mockPlatform.lastCreatedController as MockPlatformWebViewController;
      
      // Simulate WebView ready
      mockController.simulateRendererReady();
      await tester.pump();
      
      // Add content to mock cache
      mockController.addToCache(contentHash, '<div>Rendered HTML for testing</div>');
      
      // Rebuild with same content to test cache hit
      await tester.pumpWidget(buildRenderer(
        content: content,
        enableCaching: true,
      ));
      
      // Simulate WebView ready
      mockController.simulateRendererReady();
      await tester.pump();
      
      // The test is primarily checking that the code path executes without errors
      // since we can't directly verify cache hits in this test environment
      expect(find.byType(WebViewWidget), findsOneWidget);
    });
  });
}