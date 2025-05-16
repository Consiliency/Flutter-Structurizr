import 'package:flutter/material.dart';
import 'package:flutter_structurizr/domain/documentation/documentation.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/decision_graph.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DecisionGraph', () {
    final testDecisions = [
      Decision(
        id: 'ADR-001',
        date: DateTime(2023, 1, 1),
        status: 'Accepted',
        title: 'Use Flutter for UI',
        content: 'Content for ADR-001',
        links: ['ADR-002', 'ADR-003'],
      ),
      Decision(
        id: 'ADR-002',
        date: DateTime(2023, 2, 1),
        status: 'Accepted',
        title: 'Database Selection',
        content: 'Content for ADR-002',
        links: ['ADR-003'],
      ),
      Decision(
        id: 'ADR-003',
        date: DateTime(2023, 3, 1),
        status: 'Proposed',
        title: 'Authentication Strategy',
        content: 'Content for ADR-003',
        links: [],
      ),
    ];

    testWidgets('renders decision nodes and edges', (WidgetTester tester) async {
      // Arrange
      int selectedIndex = -1;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DecisionGraph(
              decisions: testDecisions,
              onDecisionSelected: (index) {
                selectedIndex = index;
              },
            ),
          ),
        ),
      );

      // Let the animation run for a bit
      await tester.pump(const Duration(milliseconds: 500));

      // Assert
      // We can verify the widget structure but not the CustomPaint rendering
      expect(find.byType(DecisionGraph), findsOneWidget);
      // At least one CustomPaint for the edges
      expect(find.byType(CustomPaint), findsWidgets);
      
      // Should find text for all decision IDs and titles
      for (final decision in testDecisions) {
        expect(find.text(decision.id), findsOneWidget);
        expect(find.text(decision.title), findsOneWidget);
      }
    });

    testWidgets('handles node selection', (WidgetTester tester) async {
      // Arrange
      int selectedIndex = -1;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: DecisionGraph(
                decisions: testDecisions,
                onDecisionSelected: (index) {
                  selectedIndex = index;
                },
              ),
            ),
          ),
        ),
      );

      // Let the animation run for a bit
      await tester.pump(const Duration(milliseconds: 500));

      // Find and tap on the first decision node
      final firstDecisionContainer = find.text('ADR-001').first;
      await tester.tap(firstDecisionContainer);
      await tester.pump();

      // Assert
      expect(selectedIndex, 0);
    });

    testWidgets('supports dark mode', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DecisionGraph(
              decisions: testDecisions,
              onDecisionSelected: (index) {},
              isDarkMode: true,
            ),
          ),
        ),
      );

      // Let the animation run for a bit
      await tester.pump(const Duration(milliseconds: 500));

      // Assert
      expect(find.byType(DecisionGraph), findsOneWidget);
      // Specific styling tests would require golden image testing
    });
  });
}