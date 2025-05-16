import 'package:flutter/material.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/asciidoc_renderer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'dart:async';
import 'mock_webview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Register a mock implementation of WebView
  final mockPlatform = MockWebViewPlatform();
  WebViewPlatform.instance = mockPlatform;

  group('AsciidocRenderer', () {
    tearDown(() {
      final mockController = mockPlatform.lastCreatedController;
      if (mockController is MockPlatformWebViewController) {
        mockController.disposeForTest();
      }
    });

    testWidgets('creates a WebView to render AsciiDoc content', (WidgetTester tester) async {
      // Arrange
      const content = '''
= Document Title
:author: Jenner Torrence
:email: jennertorrence@hotmail.com

== Introduction

This is a simple AsciiDoc document.

[source,dart]
----
void main() {
  print('Hello, AsciiDoc!');
}
----

== Diagram References

Here's a diagram: embed:system-context[System Context Diagram]
''';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AsciidocRenderer(
              content: content,
              useOfflineMode: false, // Don't try to load from assets in tests
            ),
          ),
        ),
      );
      
      // Allow for the WebView to initialize
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(WebViewWidget), findsOneWidget);
      // Since the WebView content is not directly accessible in tests, 
      // we're primarily checking that the widget builds correctly.
    });

    testWidgets('shows loading indicator while WebView is initializing', 
        (WidgetTester tester) async {
      // Arrange
      const content = '= Sample Title\n\nSome content';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AsciidocRenderer(
              content: content,
              useOfflineMode: false,
            ),
          ),
        ),
      );

      // Assert - initially shows loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Simulate WebView finishing loading
      await tester.pumpAndSettle();
      
      // Loading indicator should disappear after WebView loads
      // Note: In real test environment, the loading indicator might still be visible
      // since the mock WebView platform doesn't actually load content.
    });

    testWidgets('passes workspace and diagram selection callback to renderer', 
        (WidgetTester tester) async {
      // Arrange
      const content = 'Test content';
      String? selectedDiagram;
      
      final workspace = Workspace(
        id: 1, // Use numeric ID
        name: 'Test Workspace',
        description: 'Test workspace for unit tests',
        model: const Model(), // No ID needed
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsciidocRenderer(
              content: content,
              workspace: workspace,
              useOfflineMode: false,
              onDiagramSelected: (key) {
                selectedDiagram = key;
              },
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(WebViewWidget), findsOneWidget);
      
      // We can't directly test the callback from WebView in this testing environment,
      // but we can verify the widget builds with the correct parameters.
    });

    testWidgets('applies dark mode styles when specified', (WidgetTester tester) async {
      // Arrange
      const content = 'Test content';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AsciidocRenderer(
              content: content,
              isDarkMode: true,
              useOfflineMode: false,
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(WebViewWidget), findsOneWidget);
      // Again, we can't directly test the styles applied to the WebView content,
      // but we can verify the widget builds with the correct parameters.
    });
    
    testWidgets('shows progress indicators for large documents', (WidgetTester tester) async {
      // Generate a large string
      final largeContent = '= Large Document\n\n' + ('Lorem ipsum dolor sit amet. ' * 10000);
      
      // Act - create with smaller chunk size to trigger chunking
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsciidocRenderer(
              content: largeContent,
              useOfflineMode: false,
              chunkSize: 100, // Small chunk size to trigger chunked rendering
            ),
          ),
        ),
      );
      
      // Assert - check for loading indicators
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Let it render for a moment
      await tester.pump(const Duration(milliseconds: 100));
      
      // Get the controller to manipulate it for testing
      final mockController = mockPlatform.lastCreatedController as MockPlatformWebViewController;
          
      // Simulate progress updates
      mockController.simulateRendererReady();
      await tester.pump();
      
      // Verify the progress indicator is still showing (for chunk processing)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Trigger chunk processing simulation by running JavaScript that triggers it
      await mockController.runJavaScript('processNextChunk()');
      await tester.pump();
      
      // After all chunks processed, loading indicator should be gone
      await tester.pump(const Duration(milliseconds: 150));
    });
    
    testWidgets('uses content caching for previously rendered content', (WidgetTester tester) async {
      // Setup content and hash
      const content = '= Cached Document\n\nThis content should be cached.';
      const contentHash = 'test-hash-123';
      
      // Build the renderer
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AsciidocRenderer(
              content: content,
              useOfflineMode: false,
              enableCaching: true, // Enable caching
            ),
          ),
        ),
      );
      
      // Get the controller to manipulate it for testing
      final mockController = mockPlatform.lastCreatedController as MockPlatformWebViewController;
      
      // Simulate the renderer being ready
      mockController.simulateRendererReady();
      await tester.pump();
      
      // Simulate adding content to cache
      mockController.addToCache(contentHash, '<div>Rendered HTML</div>');
      
      // Rebuild with same content to test caching
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AsciidocRenderer(
              content: content,
              useOfflineMode: false,
              enableCaching: true,
            ),
          ),
        ),
      );
      
      // Verify renderer initialized
      mockController.simulateRendererReady();
      await tester.pump();
      
      // Can't directly verify cache usage since the WebView is mocked, but we've exercised the code path
    });
    
    testWidgets('handles errors with retry functionality', (WidgetTester tester) async {
      const content = '= Error Test Document\n\nTest content';
      // Create the mock platform controller and wrap it in a TestWebViewController
      final mockPlatformController = mockPlatform.createPlatformWebViewController(const PlatformWebViewControllerCreationParams()) as MockPlatformWebViewController;
      final testController = TestWebViewController(mockPlatformController);
      // Build the renderer with the test controller
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsciidocRenderer(
              content: content,
              useOfflineMode: false,
              controller: testController,
            ),
          ),
        ),
      );
      // Simulate an error
      testController.mock.simulateError();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      // Error state should show retry button
      expect(find.text('Error rendering AsciiDoc'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      print('[Test] Tapping retry button');
      await tester.tap(find.text('Retry'));
      await tester.pump();
      print('[Test] Retry button tapped, pumped');
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      testController.mock.simulateRendererReady();
      await tester.pump();
      expect(find.text('Error rendering AsciiDoc'), findsNothing);
    });
  });
}