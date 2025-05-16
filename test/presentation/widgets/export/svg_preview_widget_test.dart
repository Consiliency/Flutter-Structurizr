import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/presentation/widgets/export/export_dialog.dart';

void main() {
  const String testSvg = '''
<svg width="800" height="600" xmlns="http://www.w3.org/2000/svg">
  <rect x="50" y="50" width="300" height="200" fill="white" stroke="black" />
  <circle cx="200" cy="150" r="50" fill="blue" />
  <text x="200" y="150" text-anchor="middle" fill="white">System</text>
  <rect x="70" y="70" width="100" height="60" fill="green" />
  <text x="120" y="100" text-anchor="middle" fill="white">Component A</text>
  <rect x="230" y="70" width="100" height="60" fill="red" />
  <text x="280" y="100" text-anchor="middle" fill="white">Component B</text>
  <line x1="120" y1="130" x2="200" y2="150" stroke="black" />
  <line x1="280" y1="130" x2="200" y2="150" stroke="black" />
  <text x="150" y="140" text-anchor="middle" font-size="10">Uses</text>
  <text x="250" y="140" text-anchor="middle" font-size="10">Uses</text>
</svg>
''';

  const String testSvgWithoutWidthHeight = '''
<svg xmlns="http://www.w3.org/2000/svg">
  <rect x="50" y="50" width="300" height="200" fill="white" stroke="black" />
  <circle cx="200" cy="150" r="50" fill="blue" />
  <text x="200" y="150" text-anchor="middle" fill="white">System</text>
</svg>
''';

  testWidgets('SvgPreviewWidget displays SVG metadata correctly', (WidgetTester tester) async {
    // Build the widget
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SvgPreviewWidget(svgData: testSvg),
        ),
      ),
    );
    
    // Verify that the widget renders correctly
    expect(find.text('SVG Preview'), findsOneWidget);
    
    // Check that dimensions are extracted and displayed
    expect(find.text('Size: 800×600'), findsOneWidget);
    
    // Check that element count is calculated and displayed
    expect(find.text('Elements: 11'), findsOneWidget);
    
    // Check that file size is calculated and displayed
    expect(find.textContaining('SVG Size:'), findsOneWidget);
  });
  
  testWidgets('SvgPreviewWidget handles SVG without width/height attributes', (WidgetTester tester) async {
    // Build the widget
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SvgPreviewWidget(svgData: testSvgWithoutWidthHeight),
        ),
      ),
    );
    
    // Verify that the widget renders with default values
    expect(find.text('SVG Preview'), findsOneWidget);
    
    // Should show "Unknown" for dimensions
    expect(find.text('Size: Unknown×Unknown'), findsOneWidget);
    
    // Should still count elements
    expect(find.text('Elements: 3'), findsOneWidget);
    
    // Should still calculate file size
    expect(find.textContaining('SVG Size:'), findsOneWidget);
  });
  
  testWidgets('SvgPreviewWidget displays icon and basic styling', (WidgetTester tester) async {
    // Build the widget
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: const Scaffold(
          body: SvgPreviewWidget(svgData: testSvg),
        ),
      ),
    );
    
    // Verify that the icon is displayed
    expect(find.byIcon(Icons.image), findsOneWidget);
    
    // Icon should have primary color
    final iconWidget = tester.widget<Icon>(find.byIcon(Icons.image));
    expect(iconWidget.color, equals(Theme.of(tester.element(find.byIcon(Icons.image))).primaryColor));
    
    // Should have proper styling with centered content
    expect(find.byType(Center), findsOneWidget);
    expect(find.byType(Column), findsOneWidget);
  });
}