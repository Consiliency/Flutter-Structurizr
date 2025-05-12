import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/documentation/documentation.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/table_of_contents.dart';

void main() {
  group('TableOfContents', () {
    // Test data
    final sections = [
      DocumentationSection(
        title: 'Introduction',
        content: '# Introduction',
        order: 1,
      ),
      DocumentationSection(
        title: 'Architecture',
        content: '# Architecture',
        order: 2,
        elementId: 'system-1',
      ),
    ];
    
    final decisions = [
      Decision(
        id: 'ADR-001',
        date: DateTime(2023, 1, 15),
        status: 'Accepted',
        title: 'Use Flutter',
        content: '# Decision',
      ),
      Decision(
        id: 'ADR-002',
        date: DateTime(2023, 2, 20),
        status: 'Proposed',
        title: 'Database Choice',
        content: '# Decision',
      ),
    ];

    testWidgets('renders with sections', (WidgetTester tester) async {
      int selectedIndex = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TableOfContents(
              sections: sections,
              decisions: [],
              currentSectionIndex: 0,
              currentDecisionIndex: -1,
              viewingDecisions: false,
              onSectionSelected: (index) {
                selectedIndex = index;
              },
              onDecisionSelected: (_) {},
              onToggleView: () {},
            ),
          ),
        ),
      );

      // Verify section titles are displayed
      expect(find.text('Introduction'), findsOneWidget);
      expect(find.text('Architecture'), findsOneWidget);
      
      // Verify element ID is displayed
      expect(find.text('Related to: system-1'), findsOneWidget);
      
      // Tap on the second section
      await tester.tap(find.text('Architecture'));
      
      // Verify selection callback was called with correct index
      expect(selectedIndex, equals(1));
    });

    testWidgets('renders with decisions', (WidgetTester tester) async {
      int selectedIndex = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TableOfContents(
              sections: [],
              decisions: decisions,
              currentSectionIndex: -1,
              currentDecisionIndex: 0,
              viewingDecisions: true,
              onSectionSelected: (_) {},
              onDecisionSelected: (index) {
                selectedIndex = index;
              },
              onToggleView: () {},
            ),
          ),
        ),
      );

      // Verify decision titles are displayed
      expect(find.text('Use Flutter'), findsOneWidget);
      expect(find.text('Database Choice'), findsOneWidget);
      
      // Verify decision IDs and dates are displayed
      expect(find.text('ADR-001 • 2023-01-15'), findsOneWidget);
      expect(find.text('ADR-002 • 2023-02-20'), findsOneWidget);
      
      // Tap on the second decision
      await tester.tap(find.text('Database Choice'));
      
      // Verify selection callback was called with correct index
      expect(selectedIndex, equals(1));
    });

    testWidgets('renders with both sections and decisions', (WidgetTester tester) async {
      bool toggleCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TableOfContents(
              sections: sections,
              decisions: decisions,
              currentSectionIndex: 0,
              currentDecisionIndex: -1,
              viewingDecisions: false,
              onSectionSelected: (_) {},
              onDecisionSelected: (_) {},
              onToggleView: () {
                toggleCalled = true;
              },
            ),
          ),
        ),
      );

      // Verify tab header is shown
      expect(find.text('Documentation'), findsOneWidget);
      expect(find.text('Decisions'), findsOneWidget);
      
      // Tap on the Decisions tab
      await tester.tap(find.text('Decisions'));
      
      // Verify toggle callback was called
      expect(toggleCalled, isTrue);
    });

    testWidgets('handles empty lists', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TableOfContents(
              sections: [],
              decisions: [],
              currentSectionIndex: -1,
              currentDecisionIndex: -1,
              viewingDecisions: false,
              onSectionSelected: (_) {},
              onDecisionSelected: (_) {},
              onToggleView: () {},
            ),
          ),
        ),
      );

      // Verify empty message is displayed
      expect(find.text('No documentation available'), findsOneWidget);
    });

    testWidgets('respects dark mode setting', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: TableOfContents(
              sections: sections,
              decisions: decisions,
              currentSectionIndex: 0,
              currentDecisionIndex: -1,
              viewingDecisions: false,
              onSectionSelected: (_) {},
              onDecisionSelected: (_) {},
              onToggleView: () {},
              isDarkMode: true,
            ),
          ),
        ),
      );

      // Verify the widget is rendered
      expect(find.byType(TableOfContents), findsOneWidget);
      
      // The actual visual check would require golden testing
      // In a real test, we'd verify specific color values
    });
  });
}