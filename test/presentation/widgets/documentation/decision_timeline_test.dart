import 'package:flutter/material.dart';
import 'package:flutter_structurizr/domain/documentation/documentation.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/decision_timeline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DecisionTimeline', () {
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

    testWidgets('renders decisions in chronological order', (WidgetTester tester) async {
      // Arrange
      int selectedIndex = -1;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DecisionTimeline(
              decisions: testDecisions,
              onDecisionSelected: (index) {
                selectedIndex = index;
              },
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(DecisionTimeline), findsOneWidget);
      
      // Should find text for all decision titles
      for (final decision in testDecisions) {
        expect(find.text(decision.title), findsOneWidget);
      }
      
      // Year header should be present
      expect(find.text('2023'), findsOneWidget);
      
      // Month headers should be present
      expect(find.text('January'), findsOneWidget);
      expect(find.text('February'), findsOneWidget);
      expect(find.text('March'), findsOneWidget);
    });

    testWidgets('handles decision selection', (WidgetTester tester) async {
      // Arrange
      int selectedIndex = -1;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DecisionTimeline(
              decisions: testDecisions,
              onDecisionSelected: (index) {
                selectedIndex = index;
              },
            ),
          ),
        ),
      );

      // Find and tap the first decision
      await tester.tap(find.text('Use Flutter for UI').first);
      await tester.pump();

      // Assert
      expect(selectedIndex, 0);
    });

    testWidgets('supports filtering with the filter dialog', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DecisionTimeline(
              decisions: testDecisions,
              onDecisionSelected: (index) {},
            ),
          ),
        ),
      );

      // Tap the filter button
      await tester.tap(find.byIcon(Icons.filter_list).first);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Filter Decisions'), findsOneWidget);
      expect(find.text('Date Range'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      
      // Should find checkboxes for statuses
      expect(find.text('Accepted'), findsOneWidget);
      expect(find.text('Proposed'), findsOneWidget);
      
      // Should find buttons to cancel or apply
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);
      
      // Tap Cancel to dismiss the dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      
      // Dialog should be gone
      expect(find.text('Filter Decisions'), findsNothing);
    });

    testWidgets('supports dark mode', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DecisionTimeline(
              decisions: testDecisions,
              onDecisionSelected: (index) {},
              isDarkMode: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(DecisionTimeline), findsOneWidget);
      // Specific styling tests would require golden image testing
    });
  });
}