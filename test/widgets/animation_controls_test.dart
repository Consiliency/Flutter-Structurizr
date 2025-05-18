import 'package:flutter/material.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/presentation/widgets/diagram/animation_controls.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print(
        '[\u001b[32m\u001b[1m\u001b[40m\u001b[0m${record.level.name}] ${record.loggerName}: ${record.message}');
  });

  group('AnimationControls Widget', () {
    // Test data - animation steps
    final animationSteps = [
      const AnimationStep(
        order: 1,
        elements: ['el1', 'el2'],
        relationships: ['rel1'],
      ),
      const AnimationStep(
        order: 2,
        elements: ['el1', 'el2', 'el3'],
        relationships: ['rel1', 'rel2'],
      ),
      const AnimationStep(
        order: 3,
        elements: ['el1', 'el2', 'el3', 'el4'],
        relationships: ['rel1', 'rel2', 'rel3'],
      ),
    ];

    testWidgets('renders correctly with animation steps',
        (WidgetTester tester) async {
      int callbackStep = 0;

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimationControls(
              animationSteps: animationSteps,
              initialStep: 0,
              onStepChanged: (step) {
                callbackStep = step;
              },
            ),
          ),
        ),
      );

      // Verify initial state
      expect(find.text('Step 1/3'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
      expect(find.byIcon(Icons.skip_previous), findsOneWidget);
      expect(find.byIcon(Icons.skip_next), findsOneWidget);
    });

    testWidgets('changes step when next button is tapped',
        (WidgetTester tester) async {
      int callbackStep = 0;

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimationControls(
              animationSteps: animationSteps,
              initialStep: 0,
              onStepChanged: (step) {
                callbackStep = step;
              },
            ),
          ),
        ),
      );

      // Initial state verification
      expect(find.text('Step 1/3'), findsOneWidget);

      // Tap next button
      await tester.tap(find.byIcon(Icons.skip_next));
      await tester.pumpAndSettle();

      // Verify state after next button tap
      expect(find.text('Step 2/3'), findsOneWidget);
      expect(callbackStep, 1); // Callback should receive index 1 (step 2)
    });

    testWidgets('changes step when previous button is tapped',
        (WidgetTester tester) async {
      int callbackStep = 0;

      // Build the widget with initial step 1 (second step)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimationControls(
              animationSteps: animationSteps,
              initialStep: 1, // Start at second step
              onStepChanged: (step) {
                callbackStep = step;
              },
            ),
          ),
        ),
      );

      // Initial state verification
      expect(find.text('Step 2/3'), findsOneWidget);

      // Tap previous button
      await tester.tap(find.byIcon(Icons.skip_previous));
      await tester.pumpAndSettle();

      // Verify state after previous button tap
      expect(find.text('Step 1/3'), findsOneWidget);
      expect(callbackStep, 0); // Callback should receive index 0 (step 1)
    });

    testWidgets('changes play/pause state when play button is tapped',
        (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimationControls(
              animationSteps: animationSteps,
              initialStep: 0,
              onStepChanged: (step) {},
            ),
          ),
        ),
      );

      // Initial state verification - play icon visible
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);

      // Tap play button
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      // After tapping play, pause icon should be visible
      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(find.byIcon(Icons.pause), findsOneWidget);

      // Tap pause button
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump();

      // After tapping pause, play icon should be visible again
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
    });

    testWidgets('shows "No steps" when animation steps are empty',
        (WidgetTester tester) async {
      // Build the widget with no animation steps
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimationControls(
              animationSteps: const [],
              initialStep: 0,
              onStepChanged: (step) {},
            ),
          ),
        ),
      );

      // Verify state with no steps
      expect(find.text('No steps'), findsOneWidget);
      expect(find.byType(Slider), findsNothing); // Slider should not be shown
    });

    testWidgets('timeline slider changes step when moved',
        (WidgetTester tester) async {
      int callbackStep = 0;

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimationControls(
              animationSteps: animationSteps,
              initialStep: 0,
              onStepChanged: (step) {
                callbackStep = step;
              },
            ),
          ),
        ),
      );

      // Find and interact with the slider
      final Slider slider = tester.widget(find.byType(Slider));

      // Get the slider's value and bounds
      expect(slider.value, 0.0);
      expect(slider.min, 0.0);
      expect(slider.max, 2.0); // 3 steps (0-indexed)

      // Simulate changing the slider value
      // This is a bit tricky in tests, so we'll use the state directly

      // Find the slider's gesture detector and simulate a drag
      final sliderCenter = tester.getCenter(find.byType(Slider));
      final sliderRight = Offset(sliderCenter.dx + 100, sliderCenter.dy);

      // Drag to approximately step 2
      await tester.drag(find.byType(Slider), sliderRight - sliderCenter);
      await tester.pumpAndSettle();

      // Verify the step changed
      expect(callbackStep, isNot(0)); // Step should have changed
    });

    testWidgets('plays animation automatically when autoPlay is true',
        (WidgetTester tester) async {
      int callbackStep = 0;

      // Build the widget with autoPlay set to true
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimationControls(
              animationSteps: animationSteps,
              initialStep: 0,
              onStepChanged: (step) {
                callbackStep = step;
              },
              config: const AnimationControlsConfig(
                autoPlay: true,
                fps: 10.0, // Use high FPS for testing purposes
              ),
            ),
          ),
        ),
      );

      // Verify the play button state - should show pause icon
      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(find.byIcon(Icons.pause), findsOneWidget);

      // Wait for animation to advance
      await tester.pump(const Duration(milliseconds: 200)); // Wait for advance

      // Verify the step advanced automatically
      expect(callbackStep, 1); // Should advance to step 1
    });
  });
}
