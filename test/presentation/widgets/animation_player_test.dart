import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/presentation/widgets/diagram/animation_controls.dart';

void main() {
  group('AnimationControls', () {
    // Create sample animation steps
    final animationSteps = [
      const AnimationStep(order: 1, elements: ['element1'], relationships: []),
      const AnimationStep(order: 2, elements: ['element1', 'element2'], relationships: ['relationship1']),
      const AnimationStep(order: 3, elements: ['element1', 'element2', 'element3'], relationships: ['relationship1', 'relationship2']),
    ];
    
    testWidgets('renders all controls correctly', (WidgetTester tester) async {
      int currentStep = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimationControls(
              animationSteps: animationSteps,
              initialStep: currentStep,
              onStepChanged: (step) {
                currentStep = step;
              },
            ),
          ),
        ),
      );
      
      // Verify navigation buttons are rendered
      expect(find.byIcon(Icons.skip_previous), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.skip_next), findsOneWidget);
      
      // Verify step indicator is shown
      expect(find.text('Step 1/3'), findsOneWidget);
      
      // Verify slider is present
      expect(find.byType(Slider), findsOneWidget);
    });
    
    testWidgets('handles step navigation correctly', (WidgetTester tester) async {
      int currentStep = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimationControls(
              animationSteps: animationSteps,
              initialStep: currentStep,
              onStepChanged: (step) {
                currentStep = step;
              },
            ),
          ),
        ),
      );
      
      // Tap next button to advance to step 2
      await tester.tap(find.byIcon(Icons.skip_next));
      await tester.pump();
      expect(currentStep, equals(1));
      
      // Tap next button again to advance to step 3
      await tester.tap(find.byIcon(Icons.skip_next));
      await tester.pump();
      expect(currentStep, equals(2));
      
      // Tap next button again, should stay at step 3 (last step)
      await tester.tap(find.byIcon(Icons.skip_next));
      await tester.pump();
      expect(currentStep, equals(2));
      
      // Tap previous button to go back to step 2
      await tester.tap(find.byIcon(Icons.skip_previous));
      await tester.pump();
      expect(currentStep, equals(1));
      
      // Tap previous button again to go back to step 1
      await tester.tap(find.byIcon(Icons.skip_previous));
      await tester.pump();
      expect(currentStep, equals(0));
      
      // Tap previous button again, should stay at step 1 (first step)
      await tester.tap(find.byIcon(Icons.skip_previous));
      await tester.pump();
      expect(currentStep, equals(0));
    });
    
    testWidgets('handles play button correctly', (WidgetTester tester) async {
      int currentStep = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimationControls(
              animationSteps: animationSteps,
              initialStep: currentStep,
              onStepChanged: (step) {
                currentStep = step;
              },
            ),
          ),
        ),
      );
      
      // Initially, play button should be shown
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
      
      // Tap play button
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      
      // Now, pause button should be shown
      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(find.byIcon(Icons.pause), findsOneWidget);
      
      // Tap pause button
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump();
      
      // Now, play button should be shown again
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
    });
    
    testWidgets('updates step indicator when step changes', (WidgetTester tester) async {
      int currentStep = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimationControls(
              animationSteps: animationSteps,
              initialStep: currentStep,
              onStepChanged: (step) {
                currentStep = step;
              },
            ),
          ),
        ),
      );
      
      // Initially, step indicator should show "Step 1/3"
      expect(find.text('Step 1/3'), findsOneWidget);
      
      // Tap next button to advance to step 2
      await tester.tap(find.byIcon(Icons.skip_next));
      await tester.pump();
      
      // Now, step indicator should show "Step 2/3"
      expect(find.text('Step 1/3'), findsNothing);
      expect(find.text('Step 2/3'), findsOneWidget);
      
      // Tap next button again to advance to step 3
      await tester.tap(find.byIcon(Icons.skip_next));
      await tester.pump();
      
      // Now, step indicator should show "Step 3/3"
      expect(find.text('Step 2/3'), findsNothing);
      expect(find.text('Step 3/3'), findsOneWidget);
    });
    
    testWidgets('handles empty animation steps', (WidgetTester tester) async {
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
      
      // Verify "No steps" message is shown
      expect(find.text('No steps'), findsOneWidget);
      
      // Verify slider is not shown
      expect(find.byType(Slider), findsNothing);
    });
    
    testWidgets('shows speed and mode controls when configured', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimationControls(
              animationSteps: animationSteps,
              initialStep: 0,
              onStepChanged: (step) {},
              config: const AnimationControlsConfig(
                showTimingControls: true,
                showModeControls: true,
              ),
            ),
          ),
        ),
      );
      
      // Verify speed control is shown
      expect(find.text('Speed:'), findsOneWidget);
      
      // Verify mode control is shown
      expect(find.text('Mode:'), findsOneWidget);
    });
    
    testWidgets('hides speed and mode controls when configured', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimationControls(
              animationSteps: animationSteps,
              initialStep: 0,
              onStepChanged: (step) {},
              config: const AnimationControlsConfig(
                showTimingControls: false,
                showModeControls: false,
              ),
            ),
          ),
        ),
      );
      
      // Verify speed control is not shown
      expect(find.text('Speed:'), findsNothing);
      
      // Verify mode control is not shown
      expect(find.text('Mode:'), findsNothing);
    });
  });
}