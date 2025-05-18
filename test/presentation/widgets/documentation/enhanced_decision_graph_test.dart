import 'package:flutter/material.dart';
import 'package:flutter_structurizr/domain/documentation/documentation.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/decision_graph_enhanced.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EnhancedDecisionGraph', () {
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

    final testRelationships = [
      const DecisionRelationship(
        sourceId: 'ADR-001',
        targetId: 'ADR-002',
        type: DecisionRelationshipType.enables,
      ),
      const DecisionRelationship(
        sourceId: 'ADR-002',
        targetId: 'ADR-003',
        type: DecisionRelationshipType.depends,
      ),
    ];

    final testClusters = [
      const DecisionCluster(
        decisionIds: ['ADR-001', 'ADR-002'],
        label: 'Infrastructure',
        color: Colors.blue,
      ),
      const DecisionCluster(
        decisionIds: ['ADR-003'],
        label: 'Security',
        color: Colors.red,
      ),
    ];

    testWidgets('renders decision nodes and edges',
        (WidgetTester tester) async {
      // Arrange
      int selectedIndex = -1;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedDecisionGraph(
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
      expect(find.byType(EnhancedDecisionGraph), findsOneWidget);
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
              child: EnhancedDecisionGraph(
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
            body: EnhancedDecisionGraph(
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
      expect(find.byType(EnhancedDecisionGraph), findsOneWidget);
    });

    testWidgets('renders with explicit relationships',
        (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedDecisionGraph(
              decisions: testDecisions,
              onDecisionSelected: (index) {},
              relationships: testRelationships,
            ),
          ),
        ),
      );

      // Let the animation run for a bit
      await tester.pump(const Duration(milliseconds: 500));

      // Assert
      expect(find.byType(EnhancedDecisionGraph), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);

      // Should find text for all decision IDs and titles
      for (final decision in testDecisions) {
        expect(find.text(decision.id), findsOneWidget);
        expect(find.text(decision.title), findsOneWidget);
      }
    });

    testWidgets('renders clusters correctly', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedDecisionGraph(
              decisions: testDecisions,
              onDecisionSelected: (index) {},
              clusters: testClusters,
            ),
          ),
        ),
      );

      // Let the animation run for a bit
      await tester.pump(const Duration(milliseconds: 500));

      // Assert
      expect(find.byType(EnhancedDecisionGraph), findsOneWidget);

      // Should find cluster labels in the legend
      for (final cluster in testClusters) {
        expect(find.text(cluster.label), findsWidgets);
      }

      // Should find the cluster title in the UI
      expect(find.text('Clusters'), findsOneWidget);
    });

    testWidgets('renders relationship legend', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedDecisionGraph(
              decisions: testDecisions,
              onDecisionSelected: (index) {},
            ),
          ),
        ),
      );

      // Let the animation run for a bit
      await tester.pump(const Duration(milliseconds: 500));

      // Assert
      expect(find.byType(EnhancedDecisionGraph), findsOneWidget);

      // Should find relationship type legend title
      expect(find.text('Relationship Types'), findsOneWidget);

      // Should find at least one relationship type description
      const firstRelationship = DecisionRelationship(
        sourceId: '',
        targetId: '',
        type: DecisionRelationshipType.related,
      );
      expect(find.text(firstRelationship.description), findsWidgets);
    });

    testWidgets('toggling simulation works', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedDecisionGraph(
              decisions: testDecisions,
              onDecisionSelected: (index) {},
            ),
          ),
        ),
      );

      // Let the animation run for a bit
      await tester.pump(const Duration(milliseconds: 500));

      // Find the simulation toggle button (it has a pause icon initially)
      final pauseButton = find.byIcon(Icons.pause);
      expect(pauseButton, findsOneWidget);

      // Tap the button to pause the simulation
      await tester.tap(pauseButton);
      await tester.pump();

      // Now it should show a play icon
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
    });

    testWidgets('zoom controls work', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedDecisionGraph(
              decisions: testDecisions,
              onDecisionSelected: (index) {},
            ),
          ),
        ),
      );

      // Let the animation run for a bit
      await tester.pump(const Duration(milliseconds: 500));

      // Find the zoom buttons
      final zoomInButton = find.byIcon(Icons.add);
      final zoomOutButton = find.byIcon(Icons.remove);
      final resetButton = find.byIcon(Icons.refresh);

      expect(zoomInButton, findsOneWidget);
      expect(zoomOutButton, findsOneWidget);
      expect(resetButton, findsOneWidget);

      // Test tapping the buttons (can't test actual zoom effect in widget test)
      await tester.tap(zoomInButton);
      await tester.pump();

      await tester.tap(zoomOutButton);
      await tester.pump();

      await tester.tap(resetButton);
      await tester.pump();

      // Buttons should still be there
      expect(zoomInButton, findsOneWidget);
      expect(zoomOutButton, findsOneWidget);
      expect(resetButton, findsOneWidget);
    });
  });
}
