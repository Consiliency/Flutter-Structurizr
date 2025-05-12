import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/documentation/documentation.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/markdown_renderer.dart';

void main() {
  // Create test workspace
  final workspace = Workspace(
    id: 1,
    name: 'Test Workspace',
    model: Model(
      softwareSystems: [
        SoftwareSystem.create(
          name: 'Test System',
          description: 'Test System Description',
        ),
      ],
    ),
    documentation: Documentation(
      sections: [
        DocumentationSection(
          title: 'Introduction',
          content: '# Introduction\n\nThis is the introduction.',
          order: 1,
        ),
      ],
    ),
  );

  group('MarkdownRenderer', () {
    testWidgets('renders basic markdown content', (WidgetTester tester) async {
      const content = '# Heading 1\n\nThis is a paragraph.';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownRenderer(
              content: content,
            ),
          ),
        ),
      );

      // Verify heading and paragraph are rendered
      expect(find.text('Heading 1'), findsOneWidget);
      expect(find.text('This is a paragraph.'), findsOneWidget);
    });

    testWidgets('renders section numbers when enabled', (WidgetTester tester) async {
      const content = '# Heading 1\n\n## Heading 2\n\n### Heading 3';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownRenderer(
              content: content,
              enableSectionNumbering: true,
            ),
          ),
        ),
      );

      // Verify section numbering
      expect(find.textContaining('1 Heading 1'), findsOneWidget);
      expect(find.textContaining('1.1 Heading 2'), findsOneWidget);
      expect(find.textContaining('1.1.1 Heading 3'), findsOneWidget);
    });

    testWidgets('respects dark mode setting', (WidgetTester tester) async {
      const content = '# Heading in Dark Mode';

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: MarkdownRenderer(
              content: content,
              isDarkMode: true,
            ),
          ),
        ),
      );

      // Verify the widget is using dark mode styles
      final headingFinder = find.text('Heading in Dark Mode');
      expect(headingFinder, findsOneWidget);

      // This is a simple check that the text is using light colors for dark mode
      // In a real test, we'd verify the specific color values
      final text = tester.widget<Text>(
        find.descendant(
          of: headingFinder, 
          matching: find.byType(Text),
        ),
      );
      
      expect(text.style?.color, isNot(Colors.black));
    });

    testWidgets('renders code blocks with syntax highlighting', (WidgetTester tester) async {
      const content = '''
# Code Sample

```dart
void main() {
  print('Hello, world!');
}
```
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownRenderer(
              content: content,
            ),
          ),
        ),
      );

      // Verify code block is rendered
      expect(find.text("void main() {"), findsOneWidget);
      expect(find.text("  print('Hello, world!');"), findsOneWidget);
      expect(find.text("}"), findsOneWidget);
    });

    testWidgets('renders embedded diagrams', (WidgetTester tester) async {
      const content = '''
# Diagram Example

![System Context](embed:systemContext)
''';

      String? selectedDiagram;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownRenderer(
              content: content,
              workspace: workspace,
              onDiagramSelected: (viewKey) {
                selectedDiagram = viewKey;
              },
            ),
          ),
        ),
      );

      // Verify diagram placeholder is rendered
      expect(find.text('System Context'), findsOneWidget);
      expect(find.text('Click to view diagram'), findsOneWidget);

      // Tap the diagram and verify callback
      await tester.tap(find.text('System Context'));
      expect(selectedDiagram, equals('systemContext'));
    });

    testWidgets('handles missing workspace for diagrams', (WidgetTester tester) async {
      const content = '''
# Diagram Example

![System Context](embed:systemContext)
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownRenderer(
              content: content,
              // No workspace provided
            ),
          ),
        ),
      );

      // Verify diagram placeholder indicates workspace is not available
      expect(find.text('Diagram: System Context (Workspace not available)'), findsOneWidget);
    });
  });
}