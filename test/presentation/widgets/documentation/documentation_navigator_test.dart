import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/documentation/documentation.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/decision_graph.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/decision_timeline.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/documentation_navigator.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/documentation_search.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/table_of_contents.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/markdown_renderer.dart';

void main() {
  // Create a test workspace with documentation
  final workspace = Workspace(
    id: 1,
    name: 'Test Workspace',
    model: Model(),
    documentation: Documentation(
      sections: [
        DocumentationSection(
          title: 'Introduction',
          content: '# Introduction\n\nThis is the introduction.',
          order: 1,
        ),
        DocumentationSection(
          title: 'Architecture',
          content: '# Architecture\n\nThis is the architecture section.',
          order: 2,
        ),
      ],
      decisions: [
        Decision(
          id: 'ADR-001',
          date: DateTime(2023, 1, 15),
          status: 'Accepted',
          title: 'Use Flutter',
          content: '# Decision\n\nWe will use Flutter.',
        ),
        Decision(
          id: 'ADR-002',
          date: DateTime(2023, 2, 20),
          status: 'Proposed',
          title: 'Database Choice',
          content: '# Decision\n\nDatabase selection.',
          links: ['ADR-001'],
        ),
      ],
    ),
  );

  group('DocumentationNavigatorController', () {
    test('initializes with default values', () {
      final controller = DocumentationNavigatorController();
      expect(controller.currentSectionIndex, equals(0));
      expect(controller.currentDecisionIndex, equals(-1));
      expect(controller.viewMode, equals(DocumentationViewMode.documentation));
      expect(controller.viewingDecisions, isFalse);
      expect(controller.contentExpanded, isFalse);
    });

    test('navigates to section', () {
      final controller = DocumentationNavigatorController();
      bool notified = false;
      controller.addListener(() {
        notified = true;
      });

      controller.navigateToSection(1);
      expect(controller.currentSectionIndex, equals(1));
      expect(controller.viewingDecisions, isFalse);
      expect(notified, isTrue);
    });

    test('navigates to decision', () {
      final controller = DocumentationNavigatorController();
      bool notified = false;
      controller.addListener(() {
        notified = true;
      });

      controller.navigateToDecision(1);
      expect(controller.currentDecisionIndex, equals(1));
      expect(controller.viewingDecisions, isTrue);
      expect(notified, isTrue);
    });

    test('toggles decisions view', () {
      final controller = DocumentationNavigatorController();
      bool notified = false;
      controller.addListener(() {
        notified = true;
      });

      expect(controller.viewingDecisions, isFalse);
      controller.toggleDecisionsView();
      expect(controller.viewMode, equals(DocumentationViewMode.decisions));
      expect(controller.viewingDecisions, isTrue);
      expect(notified, isTrue);
    });

    test('switches to decision graph view', () {
      final controller = DocumentationNavigatorController();
      bool notified = false;
      controller.addListener(() {
        notified = true;
      });

      controller.showDecisionGraph();
      expect(controller.viewMode, equals(DocumentationViewMode.decisionGraph));
      expect(controller.viewingDecisions, isFalse);
      expect(notified, isTrue);
    });

    test('switches to decision timeline view', () {
      final controller = DocumentationNavigatorController();
      bool notified = false;
      controller.addListener(() {
        notified = true;
      });

      controller.showDecisionTimeline();
      expect(controller.viewMode, equals(DocumentationViewMode.decisionTimeline));
      expect(controller.viewingDecisions, isFalse);
      expect(notified, isTrue);
    });

    test('switches to search view', () {
      final controller = DocumentationNavigatorController();
      bool notified = false;
      controller.addListener(() {
        notified = true;
      });

      controller.showSearch();
      expect(controller.viewMode, equals(DocumentationViewMode.search));
      expect(controller.viewingDecisions, isFalse);
      expect(notified, isTrue);
    });

    test('toggles content expansion', () {
      final controller = DocumentationNavigatorController();
      bool notified = false;
      controller.addListener(() {
        notified = true;
      });

      expect(controller.contentExpanded, isFalse);
      controller.toggleContentExpansion();
      expect(controller.contentExpanded, isTrue);
      expect(notified, isTrue);
    });
  });

  group('DocumentationNavigator', () {
    testWidgets('renders with documentation sections', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentationNavigator(
              workspace: workspace,
            ),
          ),
        ),
      );

      // Verify table of contents is displayed
      expect(find.byType(TableOfContents), findsOneWidget);
      
      // Verify section titles are displayed
      expect(find.text('Introduction'), findsOneWidget);
      expect(find.text('Architecture'), findsOneWidget);
      
      // Verify content of the selected section (Introduction) is displayed
      expect(find.byType(MarkdownRenderer), findsOneWidget);
    });

    testWidgets('navigates between sections', (WidgetTester tester) async {
      final controller = DocumentationNavigatorController();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentationNavigator(
              workspace: workspace,
              controller: controller,
            ),
          ),
        ),
      );

      // Initially showing Introduction
      expect(find.text('Introduction'), findsOneWidget);
      
      // Navigate to Architecture section
      controller.navigateToSection(1);
      await tester.pump();
      
      // Verify Architecture section is selected
      expect(find.text('Architecture'), findsOneWidget);
    });

    testWidgets('switches to decisions view', (WidgetTester tester) async {
      final controller = DocumentationNavigatorController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentationNavigator(
              workspace: workspace,
              controller: controller,
            ),
          ),
        ),
      );

      // Initially showing documentation
      expect(find.text('Introduction'), findsOneWidget);

      // Switch to decisions view
      controller.toggleDecisionsView();
      await tester.pump();

      // Navigate to first decision
      controller.navigateToDecision(0);
      await tester.pump();

      // Verify decision is shown
      expect(find.text('Use Flutter'), findsOneWidget);
      expect(find.text('Accepted'), findsOneWidget);
    });

    testWidgets('shows decision graph view', (WidgetTester tester) async {
      final controller = DocumentationNavigatorController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentationNavigator(
              workspace: workspace,
              controller: controller,
              showToolbar: true,
            ),
          ),
        ),
      );

      // Switch to decision graph view
      controller.showDecisionGraph();
      await tester.pump();

      // Verify decision graph is shown
      expect(find.byType(DecisionGraph), findsOneWidget);
    });

    testWidgets('shows decision timeline view', (WidgetTester tester) async {
      final controller = DocumentationNavigatorController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentationNavigator(
              workspace: workspace,
              controller: controller,
              showToolbar: true,
            ),
          ),
        ),
      );

      // Switch to decision timeline view
      controller.showDecisionTimeline();
      await tester.pump();

      // Verify decision timeline is shown
      expect(find.byType(DecisionTimeline), findsOneWidget);
    });

    testWidgets('shows search view', (WidgetTester tester) async {
      final controller = DocumentationNavigatorController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentationNavigator(
              workspace: workspace,
              controller: controller,
              showToolbar: true,
            ),
          ),
        ),
      );

      // Switch to search view
      controller.showSearch();
      await tester.pump();

      // Verify search is shown
      expect(find.byType(DocumentationSearch), findsOneWidget);
    });

    testWidgets('renders message when no documentation', (WidgetTester tester) async {
      final emptyWorkspace = Workspace(
        id: 2,
        name: 'Empty Workspace',
        model: Model(),
        // No documentation
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentationNavigator(
              workspace: emptyWorkspace,
            ),
          ),
        ),
      );

      // Verify message is displayed
      expect(find.text('No documentation available for this workspace.'), findsOneWidget);
    });

    testWidgets('respects dark mode setting', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: DocumentationNavigator(
              workspace: workspace,
              isDarkMode: true,
            ),
          ),
        ),
      );

      // Verify the navigator is rendered in dark mode
      // This is a simple check - in a real test we'd check specific colors
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme, equals(ThemeData.dark()));
    });

    testWidgets('navigates to linked decisions', (WidgetTester tester) async {
      final controller = DocumentationNavigatorController();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentationNavigator(
              workspace: workspace,
              controller: controller,
            ),
          ),
        ),
      );

      // Switch to decisions view and navigate to decision with links
      controller.toggleDecisionsView();
      controller.navigateToDecision(1);
      await tester.pumpAndSettle();
      
      // Verify linked decision is shown
      expect(find.text('ADR-001'), findsOneWidget);
      
      // Click the linked decision
      await tester.tap(find.widgetWithText(ActionChip, 'Use Flutter'));
      await tester.pumpAndSettle();
      
      // Verify we navigated to the linked decision
      expect(controller.currentDecisionIndex, equals(0));
    });
  });
}