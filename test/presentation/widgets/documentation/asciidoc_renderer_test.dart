import 'package:flutter/material.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/asciidoc_renderer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Register a mock implementation of WebView
  WebViewPlatform.instance = MockWebViewPlatform();

  group('AsciidocRenderer', () {
    testWidgets('creates a WebView to render AsciiDoc content', (WidgetTester tester) async {
      // Arrange
      const content = '''
= Document Title
:author: Test Author
:email: test@example.com

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
        id: 'test-workspace',
        name: 'Test Workspace',
        description: 'Test workspace for unit tests',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsciidocRenderer(
              content: content,
              workspace: workspace,
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
  });
}

// Mock WebView platform implementation for testing
class MockWebViewPlatform extends WebViewPlatform {
  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    return MockPlatformWebViewController(params);
  }

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) {
    return MockPlatformWebViewWidget(params);
  }
}

class MockPlatformWebViewController extends PlatformWebViewController {
  MockPlatformWebViewController(super.params);

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> setBackgroundColor(Color color) async {}

  @override
  Future<void> setNavigationDelegate(NavigationDelegate delegate) async {}

  @override
  Future<void> addJavaScriptChannel(JavaScriptChannelParams params) async {}

  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) async {}

  @override
  Future<void> runJavaScript(String javaScript) async {}
}

class MockPlatformWebViewWidget extends PlatformWebViewWidget {
  MockPlatformWebViewWidget(super.params);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Text('Mock WebView'),
      ),
    );
  }
}