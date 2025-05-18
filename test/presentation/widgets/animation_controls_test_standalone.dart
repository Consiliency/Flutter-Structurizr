import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/presentation/widgets/diagram/animation_controls.dart';
import 'package:logging/logging.dart';

final logger = Logger('TestLogger');

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    logger.info(
        '[\u001b[32m\u001b[1m\u001b[40m\u001b[0m${record.level.name}] ${record.loggerName}: ${record.message}');
  });

  group('AnimationControls', () {
    // Create sample animation steps
    final animations = [
      const AnimationStep(
        order: 1,
        elements: ['system'],
        relationships: [],
      ),
      const AnimationStep(
        order: 2,
        elements: ['system', 'api'],
        relationships: ['rel1'],
      ),
      const AnimationStep(
        order: 3,
        elements: ['system', 'api', 'database'],
        relationships: ['rel1', 'rel2'],
      ),
    ];

    testWidgets('renders without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimationControls(
              animationSteps: animations,
              initialStep: 0,
              onStepChanged: (_) {},
            ),
          ),
        ),
      );

      // Just verify it renders without errors
      expect(find.byType(AnimationControls), findsOneWidget);
    });

    testWidgets('displays correct step indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimationControls(
              animationSteps: animations,
              initialStep: 0,
              onStepChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify initial step indicator
      // We need to look more generally since the exact format may change
      expect(find.textContaining('Step 1'), findsOneWidget);
    });

    testWidgets('navigation buttons work correctly',
        (WidgetTester tester) async {
      int currentStep = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimationControls(
              animationSteps: animations,
              initialStep: currentStep,
              onStepChanged: (step) {
                currentStep = step;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test next button advances steps
      await tester.tap(find.byIcon(Icons.skip_next));
      await tester.pumpAndSettle();
      expect(currentStep, equals(1));
      expect(find.textContaining('Step 2'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.skip_next));
      await tester.pumpAndSettle();
      expect(currentStep, equals(2));
      expect(find.textContaining('Step 3'), findsOneWidget);

      // Test next button stops at last step
      await tester.tap(find.byIcon(Icons.skip_next));
      await tester.pumpAndSettle();
      expect(currentStep, equals(2)); // Still on last step

      // Test previous button goes back
      await tester.tap(find.byIcon(Icons.skip_previous));
      await tester.pumpAndSettle();
      expect(currentStep, equals(1));
      expect(find.textContaining('Step 2'), findsOneWidget);
    });

    testWidgets('play/pause button changes state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimationControls(
              animationSteps: animations,
              initialStep: 0,
              onStepChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify initial play button is shown
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);

      // Tap play button
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      // Verify button changed to pause
      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(find.byIcon(Icons.pause), findsOneWidget);

      // Tap pause button
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pumpAndSettle();

      // Verify button changed back to play
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
    });
  });
}
