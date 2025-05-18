import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/presentation/widgets/diagram_controls.dart';
import 'package:logging/logging.dart';

final logger = Logger('TestLogger');

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    logger.info(
        '[\u001b[32m\u001b[1m\u001b[40m\u001b[0m${record.level.name}] ${record.loggerName}: ${record.message}');
  });

  group('DiagramControls', () {
    testWidgets('renders without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagramControls(
              onZoomIn: () {},
              onZoomOut: () {},
              onResetView: () {},
              onFitToScreen: () {},
            ),
          ),
        ),
      );

      // Just verify it renders without errors
      expect(find.byType(DiagramControls), findsOneWidget);
    });

    testWidgets('buttons call callback functions', (WidgetTester tester) async {
      bool zoomInCalled = false;
      bool zoomOutCalled = false;
      bool resetViewCalled = false;
      bool fitToScreenCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagramControls(
              onZoomIn: () {
                zoomInCalled = true;
              },
              onZoomOut: () {
                zoomOutCalled = true;
              },
              onResetView: () {
                resetViewCalled = true;
              },
              onFitToScreen: () {
                fitToScreenCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap zoom in button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(zoomInCalled, true);

      // Tap zoom out button
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();
      expect(zoomOutCalled, true);

      // Tap reset view button
      await tester.tap(find.byIcon(Icons.center_focus_strong));
      await tester.pumpAndSettle();
      expect(resetViewCalled, true);

      // Tap fit to screen button
      await tester.tap(find.byIcon(Icons.fit_screen));
      await tester.pumpAndSettle();
      expect(fitToScreenCalled, true);
    });

    testWidgets('renders with horizontal layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagramControls(
              onZoomIn: () {},
              onZoomOut: () {},
              onResetView: () {},
              onFitToScreen: () {},
              config: const DiagramControlsConfig(isVertical: false),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify it renders in horizontal orientation
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('renders with vertical layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagramControls(
              onZoomIn: () {},
              onZoomOut: () {},
              onResetView: () {},
              onFitToScreen: () {},
              config: const DiagramControlsConfig(isVertical: true),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify it renders in vertical orientation
      expect(find.byType(Column), findsWidgets);
    });
  });
}
