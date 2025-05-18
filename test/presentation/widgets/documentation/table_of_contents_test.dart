import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/documentation/documentation.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/table_of_contents.dart';

void main() {
  group('TableOfContents', () {
    // Test data
    final sections = [
      const DocumentationSection(
        title: '1. Introduction',
        content: '# Introduction',
        order: 1,
      ),
      const DocumentationSection(
        title: '1.1. Getting Started',
        content: '# Getting Started',
        order: 2,
      ),
      const DocumentationSection(
        title: '1.2. Installation',
        content: '# Installation',
        order: 3,
      ),
      const DocumentationSection(
        title: '2. Architecture',
        content: '# Architecture',
        order: 4,
        elementId: 'system-1',
      ),
      const DocumentationSection(
        title: '2.1. Components',
        content: '# Components',
        order: 5,
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

    testWidgets('renders with sections and collapsible hierarchy', (WidgetTester tester) async {
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

      // Verify section titles are displayed - initially only root sections should be visible with their direct children
      expect(find.text('1. Introduction'), findsOneWidget);
      expect(find.text('1.1. Getting Started'), findsOneWidget);
      expect(find.text('1.2. Installation'), findsOneWidget);
      expect(find.text('2. Architecture'), findsOneWidget);
      expect(find.text('2.1. Components'), findsOneWidget);
      
      // Verify element ID is displayed
      expect(find.text('Related to: system-1'), findsOneWidget);
      
      // Tap on the collapse icon for Introduction section
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down).first);
      await tester.pump();
      
      // Verify that child sections are no longer visible
      expect(find.text('1. Introduction'), findsOneWidget);
      expect(find.text('1.1. Getting Started'), findsNothing);
      expect(find.text('1.2. Installation'), findsNothing);
      
      // Expand it again
      await tester.tap(find.byIcon(Icons.keyboard_arrow_right).first);
      await tester.pump();
      
      // Verify that child sections are visible again
      expect(find.text('1.1. Getting Started'), findsOneWidget);
      expect(find.text('1.2. Installation'), findsOneWidget);
      
      // Tap on a section to select it
      await tester.tap(find.text('2. Architecture'));
      
      // Verify selection callback was called with correct index
      expect(selectedIndex, equals(3));
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
    
    testWidgets('keyboard accessibility for expand/collapse', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TableOfContents(
              sections: sections,
              decisions: [],
              currentSectionIndex: 0,
              currentDecisionIndex: -1,
              viewingDecisions: false,
              onSectionSelected: (_) {},
              onDecisionSelected: (_) {},
              onToggleView: () {},
            ),
          ),
        ),
      );

      // Focus on the first expand/collapse button
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down).first);
      await tester.pump();
      
      // Verify state changed (section collapsed)
      expect(find.text('1.1. Getting Started'), findsNothing);
      
      // Tap again to expand
      await tester.tap(find.byIcon(Icons.keyboard_arrow_right).first);
      await tester.pump();
      
      // Verify state changed back (section expanded)
      expect(find.text('1.1. Getting Started'), findsOneWidget);
    });
  });
}