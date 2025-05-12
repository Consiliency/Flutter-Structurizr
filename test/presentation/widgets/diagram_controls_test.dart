import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/presentation/widgets/diagram_controls.dart';

void main() {
  group('DiagramControls', () {
    testWidgets('renders all controls when all flags are true', (WidgetTester tester) async {
      bool zoomInPressed = false;
      bool zoomOutPressed = false;
      bool resetViewPressed = false;
      bool fitToScreenPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagramControls(
              onZoomIn: () => zoomInPressed = true,
              onZoomOut: () => zoomOutPressed = true,
              onResetView: () => resetViewPressed = true,
              onFitToScreen: () => fitToScreenPressed = true,
              config: const DiagramControlsConfig(
                showZoomIn: true,
                showZoomOut: true,
                showResetView: true,
                showFitToScreen: true,
              ),
            ),
          ),
        ),
      );
      
      // Verify all buttons are rendered
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(find.byIcon(Icons.center_focus_strong), findsOneWidget);
      expect(find.byIcon(Icons.fit_screen), findsOneWidget);
      
      // Test interactions
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(zoomInPressed, true);
      
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();
      expect(zoomOutPressed, true);
      
      await tester.tap(find.byIcon(Icons.center_focus_strong));
      await tester.pump();
      expect(resetViewPressed, true);
      
      await tester.tap(find.byIcon(Icons.fit_screen));
      await tester.pump();
      expect(fitToScreenPressed, true);
    });
    
    testWidgets('shows only specified controls', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagramControls(
              onZoomIn: () {},
              onZoomOut: () {},
              onResetView: () {},
              onFitToScreen: () {},
              config: const DiagramControlsConfig(
                showZoomIn: true,
                showZoomOut: true,
                showResetView: false,
                showFitToScreen: false,
              ),
            ),
          ),
        ),
      );
      
      // Verify only specified buttons are rendered
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(find.byIcon(Icons.center_focus_strong), findsNothing);
      expect(find.byIcon(Icons.fit_screen), findsNothing);
    });
    
    testWidgets('can be arranged horizontally', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagramControls(
              onZoomIn: () {},
              onZoomOut: () {},
              onResetView: () {},
              onFitToScreen: () {},
              config: const DiagramControlsConfig(
                isVertical: false,
              ),
            ),
          ),
        ),
      );
      
      // Find the Row widget (horizontal layout)
      expect(find.byType(Row), findsOneWidget);
      expect(find.byType(Column), findsNWidgets(0)); // No Column for the main layout
    });
    
    testWidgets('can be arranged vertically', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagramControls(
              onZoomIn: () {},
              onZoomOut: () {},
              onResetView: () {},
              onFitToScreen: () {},
              config: const DiagramControlsConfig(
                isVertical: true,
              ),
            ),
          ),
        ),
      );
      
      // Find the Column widget (vertical layout)
      expect(find.byType(Column), findsOneWidget);
      expect(find.byType(Row), findsNWidgets(0)); // No Row for the main layout
    });
    
    testWidgets('shows labels when configured', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagramControls(
              onZoomIn: () {},
              onZoomOut: () {},
              onResetView: () {},
              onFitToScreen: () {},
              config: const DiagramControlsConfig(
                showLabels: true,
              ),
            ),
          ),
        ),
      );
      
      // Verify labels are rendered
      expect(find.text('Zoom In'), findsOneWidget);
      expect(find.text('Zoom Out'), findsOneWidget);
      expect(find.text('Reset View'), findsOneWidget);
      expect(find.text('Fit to Screen'), findsOneWidget);
    });
    
    testWidgets('hides labels when configured', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagramControls(
              onZoomIn: () {},
              onZoomOut: () {},
              onResetView: () {},
              onFitToScreen: () {},
              config: const DiagramControlsConfig(
                showLabels: false,
              ),
            ),
          ),
        ),
      );
      
      // Verify labels are not rendered
      expect(find.text('Zoom In'), findsNothing);
      expect(find.text('Zoom Out'), findsNothing);
      expect(find.text('Reset View'), findsNothing);
      expect(find.text('Fit to Screen'), findsNothing);
    });
    
    testWidgets('applies custom colors', (WidgetTester tester) async {
      const customButtonColor = Colors.red;
      const customIconColor = Colors.blue;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagramControls(
              onZoomIn: () {},
              onZoomOut: () {},
              onResetView: () {},
              onFitToScreen: () {},
              config: const DiagramControlsConfig(
                buttonColor: customButtonColor,
                iconColor: customIconColor,
              ),
            ),
          ),
        ),
      );
      
      // Find the container with the button color
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      
      // Check if the color is applied (with opacity)
      expect(
        (decoration.color as Color).value,
        equals(customButtonColor.withOpacity(0.8).value),
      );
      
      // Find the IconButton to check the icon color
      final iconButtons = tester.widgetList<IconButton>(find.byType(IconButton));
      for (final iconButton in iconButtons) {
        final icon = iconButton.icon as Icon;
        expect(icon.color, equals(customIconColor));
      }
    });
  });
}