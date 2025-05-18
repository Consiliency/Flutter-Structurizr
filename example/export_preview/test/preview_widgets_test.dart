import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:export_preview_example/main.dart';

void main() {
  testWidgets('Preview widget rendering tests', (WidgetTester tester) async {
    // For basic widget testing, we're just going to verify that 
    // the main components can render without errors
    
    // Build the SvgPreviewWidget
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SvgPreviewWidget(
              svgContent: '<svg width="100" height="100"></svg>',
              transparentBackground: false,
            ),
          ),
        ),
      ),
    );
    
    await tester.pumpAndSettle();
    
    // Verify the widget exists
    expect(find.byType(SvgPreviewWidget), findsOneWidget);
    
    // Build the TextPreviewWidget
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: TextPreviewWidget(
              content: 'Test content',
              format: 'DSL',
            ),
          ),
        ),
      ),
    );
    
    await tester.pumpAndSettle();
    
    // Verify the widget exists and format is displayed
    expect(find.byType(TextPreviewWidget), findsOneWidget);
    expect(find.text('DSL Preview'), findsOneWidget);
    
    // Build the CheckerboardBackground
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 100,
              height: 100,
              child: CheckerboardBackground(squareSize: 10),
            ),
          ),
        ),
      ),
    );
    
    await tester.pumpAndSettle();
    
    // Verify the widget exists
    expect(find.byType(CheckerboardBackground), findsOneWidget);
  });
}