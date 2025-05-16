import 'package:flutter/material.dart' hide Container, Element, View;
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/presentation/widgets/diagram/animation_controls.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnimationControls Widget - Improved Tests', () {
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

    // Helper to build the widget in a proper MaterialApp wrapper
    Widget buildTestWidget({
      List<AnimationStep>? steps,
      int initialStep = 0,
      void Function(int)? onStepChanged,
      AnimationControlsConfig? config,
    }) {
      return MaterialApp(
        theme: ThemeData.light(), // Use a specific theme for consistency
        home: Scaffold(
          body: Center(
            child: AnimationControls(
              animationSteps: steps ?? animationSteps,
              initialStep: initialStep,
              onStepChanged: onStepChanged ?? ((step) {}),
              config: config ?? const AnimationControlsConfig(),
            ),
          ),
        ),
      );
    }

    testWidgets('timeline slider changes step when dragged', (WidgetTester tester) async {
      int callbackStep = -1;

      // Build the widget with a wider slider for easier testing
      await tester.pumpWidget(
        buildTestWidget(
          config: const AnimationControlsConfig(
            timelineWidth: 400.0, // Use a wider slider
            height: 120.0, // More height for better touch targets
          ),
          onStepChanged: (step) {
            callbackStep = step;
          },
        ),
      );

      // Verify slider is present and initial step is correct
      expect(find.byType(Slider), findsOneWidget);
      
      // Find the slider's center
      final Finder sliderFinder = find.byType(Slider);
      final Slider slider = tester.widget<Slider>(sliderFinder);
      expect(slider.value, 0.0); // Initial step is 0
      
      // Tap at the end of the slider to go to the last step
      // This is more reliable than drag operations in tests
      final Offset sliderStart = tester.getTopLeft(sliderFinder);
      final Offset sliderEnd = tester.getTopRight(sliderFinder);
      
      // Tap near the end to go to step 2
      await tester.tapAt(Offset(sliderEnd.dx - 10, sliderStart.dy + 10));
      await tester.pumpAndSettle();
      
      // Verify the callback was called with the last step (2)
      expect(callbackStep, 2);
    });

    testWidgets('respects config options for visibility of controls', (WidgetTester tester) async {
      // Build the widget with controls options disabled
      await tester.pumpWidget(
        buildTestWidget(
          config: const AnimationControlsConfig(
            showTimingControls: false,
            showModeControls: false,
            showStepLabels: false,
            height: 120.0, // More height for reliable testing
          ),
        ),
      );

      // Verify speed controls are not shown
      expect(find.text('Speed:'), findsNothing);
      
      // Verify mode controls are not shown
      expect(find.text('Mode:'), findsNothing);
    });

    testWidgets('handles custom styling through config', (WidgetTester tester) async {
      // Custom colors for testing
      const customBgColor = Color(0xFF333333);
      const customTextColor = Color(0xFFFFFFFF);
      const customIconColor = Color(0xFF00FF00);

      // Build the widget with custom colors
      await tester.pumpWidget(
        buildTestWidget(
          config: const AnimationControlsConfig(
            backgroundColor: customBgColor,
            textColor: customTextColor,
            iconColor: customIconColor,
            height: 120.0, // More height for reliable testing
          ),
        ),
      );

      // Get the Material widget that contains our controls
      final material = tester.widget<Material>(find.byType(Material).first);
      expect(material.color, equals(customBgColor));
      
      // Find the SizedBox/Container that wraps our controls
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.height, equals(120.0));
      
      // Find some text and verify its color
      final stepText = tester.widget<Text>(find.text('Step 1/3'));
      expect(stepText.style?.color, equals(customTextColor));
    });

    testWidgets('changes animation mode correctly', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(buildTestWidget());

      // Find dropdown for mode
      final modeFinder = find.text('Mode:');
      expect(modeFinder, findsOneWidget);
      
      // DropdownButton may have multiple instances of the dropdown value text,
      // so we need to find the button first, then check its child
      final dropdownFinder = find.ancestor(
        of: find.text('Once'),
        matching: find.byType(DropdownButton<AnimationMode>),
      );
      expect(dropdownFinder, findsOneWidget);
      
      // Tap to open dropdown
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();
      
      // Now modal dialog is shown with dropdown items, find and tap Loop
      await tester.tap(find.text('Loop').last);
      await tester.pumpAndSettle();
      
      // Verify dropdown now shows Loop
      final dropdownAfter = find.ancestor(
        of: find.text('Loop'),
        matching: find.byType(DropdownButton<AnimationMode>),
      );
      expect(dropdownAfter, findsOneWidget);
    });

    testWidgets('changes animation speed correctly', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(buildTestWidget());

      // Find dropdown for speed
      final speedFinder = find.text('Speed:');
      expect(speedFinder, findsOneWidget);
      
      // Find the dropdown
      final dropdownFinder = find.ancestor(
        of: find.text('1x'),
        matching: find.byType(DropdownButton<double>),
      );
      expect(dropdownFinder, findsOneWidget);
      
      // Tap to open dropdown
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();
      
      // Now modal dialog is shown with dropdown items, find and tap 2x
      await tester.tap(find.text('2x').last);
      await tester.pumpAndSettle();
      
      // Verify dropdown now shows 2x
      final dropdownAfter = find.ancestor(
        of: find.text('2x'),
        matching: find.byType(DropdownButton<double>),
      );
      expect(dropdownAfter, findsOneWidget);
    });

    testWidgets('handles animation step updates correctly', (WidgetTester tester) async {
      // Create a StatefulBuilder test widget to control state from outside
      int initialStep = 0;
      int currentStep = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Scaffold(
                body: Column(
                  children: [
                    AnimationControls(
                      animationSteps: animationSteps,
                      initialStep: initialStep,
                      onStepChanged: (step) {
                        setState(() {
                          currentStep = step;
                        });
                      },
                    ),
                    // Add a button to change the initialStep
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          initialStep = 1;
                        });
                      },
                      child: const Text('Change Step'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      
      // Verify initial state
      expect(find.text('Step 1/3'), findsOneWidget);
      
      // Tap the button to change initialStep
      await tester.tap(find.text('Change Step'));
      await tester.pump();
      
      // Rebuild with the updated initialStep
      await tester.pumpAndSettle();
      
      // Verify the display updated to step 2
      expect(find.text('Step 2/3'), findsOneWidget);
    });

    testWidgets('plays animation automatically when autoPlay is true', (WidgetTester tester) async {
      int callbackStep = 0;
      
      // Slow down animation for test
      await tester.pumpWidget(
        buildTestWidget(
          config: const AnimationControlsConfig(
            autoPlay: true,
            fps: 5.0, // 5 FPS for faster testing
          ),
          onStepChanged: (step) {
            callbackStep = step;
          },
        ),
      );
      
      // Verify that pause button is showing (indicating playback is active)
      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(find.byIcon(Icons.pause), findsOneWidget);
      
      // Wait for animation to advance to the next step
      // Need to wait at least 200ms for 5 FPS (1000ms / 5 = 200ms per step)
      await tester.pump(const Duration(milliseconds: 300));
      
      // The callback should have been called to advance to step 1
      expect(callbackStep, 1);
    });
  });
}