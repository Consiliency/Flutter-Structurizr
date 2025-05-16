import 'package:flutter/material.dart';
import 'package:flutter_structurizr/domain/documentation/documentation.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/decision_list.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DecisionList', () {
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
      Decision(
        id: 'ADR-004',
        date: DateTime(2023, 4, 1),
        status: 'Rejected',
        title: 'Use GraphQL',
        content: 'Content for ADR-004',
        links: ['ADR-001'],
      ),
    ];

    testWidgets('renders decision list with all decisions', (WidgetTester tester) async {
      // Arrange
      int selectedIndex = -1;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DecisionList(
              decisions: testDecisions,
              onDecisionSelected: (index) {
                selectedIndex = index;
              },
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(DecisionList), findsOneWidget);
      
      // Should find text for all decision IDs and titles
      for (final decision in testDecisions) {
        expect(find.text(decision.id), findsWidgets);
        expect(find.text(decision.title), findsWidgets);
      }
      
      // Should find chips for the statuses
      expect(find.text('All'), findsWidgets);
      expect(find.text('Accepted'), findsWidgets);
      expect(find.text('Proposed'), findsWidgets);
      expect(find.text('Rejected'), findsWidgets);
    });

    testWidgets('handles decision selection', (WidgetTester tester) async {
      // Arrange
      int selectedIndex = -1;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DecisionList(
              decisions: testDecisions,
              onDecisionSelected: (index) {
                selectedIndex = index;
              },
            ),
          ),
        ),
      );

      // Find and tap the first decision
      await tester.tap(find.text('Use Flutter for UI'));
      await tester.pump();

      // Assert
      expect(selectedIndex, 0);
    });

    testWidgets('filters by status correctly', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DecisionList(
              decisions: testDecisions,
              onDecisionSelected: (index) {},
            ),
          ),
        ),
      );

      // Initially all decisions are visible
      expect(find.text('Use Flutter for UI'), findsWidgets);
      expect(find.text('Authentication Strategy'), findsWidgets);
      expect(find.text('Use GraphQL'), findsWidgets);

      // Filter by Proposed status
      await tester.tap(find.widgetWithText(FilterChip, 'Proposed'));
      await tester.pump();

      // Only Proposed decision should be visible
      expect(find.text('Use Flutter for UI'), findsNothing);
      expect(find.text('Authentication Strategy'), findsOneWidget);
      expect(find.text('Use GraphQL'), findsNothing);

      // Clear filter by tapping All
      await tester.tap(find.widgetWithText(FilterChip, 'All'));
      await tester.pump();

      // All decisions should be visible again
      expect(find.text('Use Flutter for UI'), findsWidgets);
      expect(find.text('Authentication Strategy'), findsWidgets);
      expect(find.text('Use GraphQL'), findsWidgets);
    });

    testWidgets('supports search functionality', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DecisionList(
              decisions: testDecisions,
              onDecisionSelected: (index) {},
            ),
          ),
        ),
      );

      // Initially all decisions are visible
      expect(find.text('Use Flutter for UI'), findsWidgets);
      expect(find.text('Database Selection'), findsWidgets);
      expect(find.text('Authentication Strategy'), findsWidgets);

      // Search for "Auth"
      await tester.enterText(find.byType(TextField), 'Auth');
      await tester.pump();

      // Only Authentication decision should be visible
      expect(find.text('Use Flutter for UI'), findsNothing);
      expect(find.text('Database Selection'), findsNothing);
      expect(find.text('Authentication Strategy'), findsOneWidget);

      // Clear search
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      // All decisions should be visible again
      expect(find.text('Use Flutter for UI'), findsWidgets);
      expect(find.text('Database Selection'), findsWidgets);
      expect(find.text('Authentication Strategy'), findsWidgets);
    });

    testWidgets('supports date sorting', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DecisionList(
              decisions: testDecisions,
              onDecisionSelected: (index) {},
            ),
          ),
        ),
      );

      // Find the sort button
      final sortButton = find.byTooltip('Sort by date (newest first)');
      expect(sortButton, findsOneWidget);

      // Default is newest first, so the last decision should be first in the list
      expect(tester.getTopLeft(find.text('Use GraphQL')).dy, 
             lessThan(tester.getTopLeft(find.text('Use Flutter for UI')).dy));

      // Tap the sort button to switch to oldest first
      await tester.tap(sortButton);
      await tester.pumpAndSettle();

      // Now the first decision should be first in the list
      expect(tester.getTopLeft(find.text('Use Flutter for UI')).dy, 
             lessThan(tester.getTopLeft(find.text('Use GraphQL')).dy));
    });

    testWidgets('supports dark mode', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DecisionList(
              decisions: testDecisions,
              onDecisionSelected: (index) {},
              isDarkMode: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(DecisionList), findsOneWidget);
      // We would need golden tests to verify the styling, but at least we can
      // verify that the widget builds in dark mode
    });
  });
}