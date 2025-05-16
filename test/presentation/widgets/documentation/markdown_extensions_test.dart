import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/markdown_extensions.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/markdown_renderer.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:typed_data';

void main() {
  group('TaskListSyntax', () {
    late TaskListSyntax syntax;
    
    setUp(() {
      syntax = TaskListSyntax();
    });
    
    test('pattern matches task list items', () {
      expect(syntax.pattern.hasMatch('- [ ] Incomplete task'), isTrue);
      expect(syntax.pattern.hasMatch('- [x] Complete task'), isTrue);
      expect(syntax.pattern.hasMatch('- [X] Complete task with uppercase X'), isTrue);
      expect(syntax.pattern.hasMatch('* [ ] Task with asterisk'), isTrue);
      expect(syntax.pattern.hasMatch('+ [ ] Task with plus'), isTrue);
      
      // Should match with up to 3 spaces of indentation
      expect(syntax.pattern.hasMatch(' - [ ] Task with 1 space'), isTrue);
      expect(syntax.pattern.hasMatch('  - [ ] Task with 2 spaces'), isTrue);
      expect(syntax.pattern.hasMatch('   - [ ] Task with 3 spaces'), isTrue);
      
      // Should not match with 4 or more spaces of indentation
      expect(syntax.pattern.hasMatch('    - [ ] Task with 4 spaces'), isFalse);
      
      // Should not match non-task list items
      expect(syntax.pattern.hasMatch('- Regular list item'), isFalse);
      expect(syntax.pattern.hasMatch('Text with [x] in it'), isFalse);
    });
  });
  
  group('EnhancedImageSyntax', () {
    late EnhancedImageSyntax syntax;
    
    setUp(() {
      syntax = EnhancedImageSyntax();
    });
    
    test('pattern matches enhanced image syntax', () {
      expect(syntax.pattern.hasMatch('![Alt text](path/to/image)'), isTrue);
      expect(syntax.pattern.hasMatch('![Alt text](path/to/image?width=300)'), isTrue);
      expect(syntax.pattern.hasMatch('![Alt text](path/to/image?width=300&height=200)'), isTrue);
      expect(syntax.pattern.hasMatch('![Alt text](path/to/image?caption=Image%20caption)'), isTrue);
      
      // Should match complex URLs
      expect(syntax.pattern.hasMatch('![Alt text](https://example.com/image.png?width=300)'), isTrue);
      
      // Should not match non-image syntax
      expect(syntax.pattern.hasMatch('[Link text](path/to/page)'), isFalse);
      expect(syntax.pattern.hasMatch('Text with ![Alt text] but no URL'), isFalse);
    });
    
    test('parses parameters correctly', () {
      final parser = md.InlineParser('![Alt text](image.png?width=300&height=200&caption=Hello%20World)', md.Document());
      syntax.onMatch(parser, RegExp(r'!\[(.*?)\]\((.*?)(?:\?(.+))?\)').firstMatch(
        '![Alt text](image.png?width=300&height=200&caption=Hello%20World)')!
      );
      
      final element = parser.result.first as EnhancedImageElement;
      expect(element.alt, equals('Alt text'));
      expect(element.url, equals('image.png'));
      expect(element.width, equals(300));
      expect(element.height, equals(200));
      expect(element.caption, equals('Hello%20World'));
    });
  });
  
  group('MetadataBlockSyntax', () {
    late MetadataBlockSyntax syntax;
    
    setUp(() {
      syntax = MetadataBlockSyntax();
    });
    
    test('pattern matches metadata blocks', () {
      expect(syntax.pattern.hasMatch('---'), isTrue);
      
      // Should not match text that isn't exactly three dashes
      expect(syntax.pattern.hasMatch('--'), isFalse);
      expect(syntax.pattern.hasMatch('----'), isFalse);
      expect(syntax.pattern.hasMatch('--- Title'), isFalse);
    });
  });
  
  group('KeyboardShortcutSyntax', () {
    late KeyboardShortcutSyntax syntax;
    
    setUp(() {
      syntax = KeyboardShortcutSyntax();
    });
    
    test('pattern matches keyboard shortcuts', () {
      expect(syntax.pattern.hasMatch('<kbd>Ctrl</kbd>'), isTrue);
      expect(syntax.pattern.hasMatch('<kbd>Ctrl+S</kbd>'), isTrue);
      expect(syntax.pattern.hasMatch('<kbd>⌘+C</kbd>'), isTrue);
      
      // Should not match invalid syntax
      expect(syntax.pattern.hasMatch('kbd>Ctrl</kbd>'), isFalse);
      expect(syntax.pattern.hasMatch('<kbd>Ctrl<kbd>'), isFalse);
      expect(syntax.pattern.hasMatch('Text with <kbd> but no closing tag'), isFalse);
    });
  });
  
  testWidgets('TaskListBuilder renders correctly', (WidgetTester tester) async {
    final builder = TaskListBuilder(isDarkMode: false);
    
    // Create a task list item
    final element = TaskListItem('-', true, 'Completed task');
    
    // Build the widget
    final widget = builder.visitElementAfter(element, const TextStyle()) as Widget;
    
    // Render the widget
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: widget,
      ),
    ));
    
    // Verify the widget structure
    expect(find.text('Completed task'), findsOneWidget);
    expect(find.byType(Checkbox), findsOneWidget);
    
    // Check that the checkbox is checked
    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, isTrue);
  });
  
  testWidgets('EnhancedImageBuilder renders correctly', (WidgetTester tester) async {
    final builder = EnhancedImageBuilder(isDarkMode: false);
    
    // Create an enhanced image element
    final element = EnhancedImageElement('Alt text', 'asset:assets/images/test.png', {
      'width': '200',
      'height': '150',
      'caption': 'Test Caption',
    });
    
    // Mock asset image provider
    final TestAssetBundle assetBundle = TestAssetBundle();
    
    // Build the widget
    final widget = builder.visitElementAfter(element, const TextStyle()) as Widget;
    
    // Render the widget
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Material(child: widget),
      ),
    ));
    
    // Verify the widget structure contains a caption
    expect(find.text('Test Caption'), findsOneWidget);
    
    // Expect an image widget
    expect(find.byType(Image), findsOneWidget);
  });
  
  testWidgets('KeyboardShortcutBuilder renders correctly', (WidgetTester tester) async {
    final builder = KeyboardShortcutBuilder(isDarkMode: false);
    
    // Create a keyboard shortcut element
    final element = KeyboardShortcutElement('Ctrl+S');
    
    // Build the widget
    final widget = builder.visitElementAfter(element, const TextStyle()) as Widget;
    
    // Render the widget
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Material(child: widget),
      ),
    ));
    
    // Verify the widget structure
    expect(find.text('Ctrl+S'), findsOneWidget);
    
    // Expect a Container with decoration
    final container = tester.widget<Container>(find.byType(Container));
    expect(container.decoration, isA<BoxDecoration>());
  });
  
  testWidgets('EnhancedTableBuilder renders correctly', (WidgetTester tester) async {
    final builder = EnhancedTableBuilder(isDarkMode: false);
    
    // Create a simple table element
    final tableElement = md.Element('table', []);
    
    // Add header and rows
    final thead = md.Element('thead', []);
    final tr1 = md.Element('tr', []);
    
    final th1 = md.Element('th', [md.Text('Header 1')]);
    final th2 = md.Element('th', [md.Text('Header 2')]);
    (tr1.children ??= []).addAll([th1, th2]);
    (thead.children ??= []).add(tr1);
    
    final tbody = md.Element('tbody', []);
    final tr2 = md.Element('tr', []);
    
    final td1 = md.Element('td', [md.Text('Cell 1')]);
    final td2 = md.Element('td', [md.Text('Cell 2')]);
    (tr2.children ??= []).addAll([td1, td2]);
    (tbody.children ??= []).add(tr2);
    
    (tableElement.children ??= []).addAll([thead, tbody]);
    
    // Create mock stylesheet
    final styleSheet = MarkdownStyleSheet(
      tableColumnWidth: const FlexColumnWidth(),
      tableCellsPadding: const EdgeInsets.all(8.0),
      tableBorder: TableBorder.all(),
      tableCellsDecoration: const BoxDecoration(color: Colors.white),
    );
    
    // Build the widget
    final widget = builder.visitElementAfter(tableElement, const TextStyle()) as Widget;
    
    // Render the widget
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Material(child: widget),
      ),
    ));
    
    // Verify there is a Table widget
    expect(find.byType(Table), findsOneWidget);
  });
}

class TestAssetBundle extends Fake implements AssetBundle {
  @override
  Future<ByteData> load(String key) async {
    // Return a dummy 1x1 transparent PNG
    return ByteData.sublistView(Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
      0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
      0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
      0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
    ]));
  }
}