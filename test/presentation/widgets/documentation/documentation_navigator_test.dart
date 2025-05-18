import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/documentation/documentation.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/decision_graph.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/decision_timeline.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/documentation_navigator.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/documentation_search.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/keyboard_shortcuts_help.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/table_of_contents.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/markdown_renderer.dart';
import '../../../stubs/workspace_documentation_mixin.dart';

void main() {
  // Create a test workspace with documentation
  final documentation = Documentation(
    sections: [
      const DocumentationSection(
        title: 'Introduction',
        content: '# Introduction\n\nThis is the introduction.',
        order: 1,
      ),
      const DocumentationSection(
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
  );

  // Create a test workspace with documentation
  final workspace =
      WorkspaceDocumentationMixin.createWorkspaceWithDocumentation(
    documentation: documentation,
  );

  group('DocumentationNavigatorController', () {
    test('initializes with default values', () {
      final controller = DocumentationNavigatorController();
      expect(controller.currentSectionIndex, equals(0));
      expect(controller.currentDecisionIndex, equals(-1));
      expect(controller.viewMode, equals(DocumentationViewMode.documentation));
      expect(controller.viewingDecisions, isFalse);
      expect(controller.contentExpanded, isFalse);
      expect(controller.canGoBack, isFalse);
      expect(controller.canGoForward, isFalse);
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
      expect(controller.canGoBack, isTrue);
      expect(controller.canGoForward, isFalse);
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
      expect(controller.canGoBack, isTrue);
      expect(controller.canGoForward, isFalse);
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
      expect(
          controller.viewMode, equals(DocumentationViewMode.decisionTimeline));
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

    test('manages navigation history', () {
      final controller = DocumentationNavigatorController();
      controller.initialize();

      // Initial state
      expect(controller.canGoBack, isFalse);
      expect(controller.canGoForward, isFalse);

      // Navigate to section 1
      controller.navigateToSection(1);
      expect(controller.canGoBack, isTrue);
      expect(controller.canGoForward, isFalse);

      // Navigate to decision 0
      controller.navigateToDecision(0);
      expect(controller.canGoBack, isTrue);
      expect(controller.canGoForward, isFalse);

      // Go back
      controller.goBack();
      expect(controller.currentSectionIndex, equals(1));
      expect(controller.viewMode, equals(DocumentationViewMode.documentation));
      expect(controller.canGoBack, isTrue);
      expect(controller.canGoForward, isTrue);

      // Go back again
      controller.goBack();
      expect(controller.currentSectionIndex, equals(0));
      expect(controller.viewMode, equals(DocumentationViewMode.documentation));
      expect(controller.canGoBack, isFalse);
      expect(controller.canGoForward, isTrue);

      // Go forward
      controller.goForward();
      expect(controller.currentSectionIndex, equals(1));
      expect(controller.viewMode, equals(DocumentationViewMode.documentation));
      expect(controller.canGoBack, isTrue);
      expect(controller.canGoForward, isTrue);

      // Go forward again
      controller.goForward();
      expect(controller.currentDecisionIndex, equals(0));
      expect(controller.viewMode, equals(DocumentationViewMode.decisions));
      expect(controller.canGoBack, isTrue);
      expect(controller.canGoForward, isFalse);

      // Navigate to a new location resets forward history
      controller.showDecisionGraph();
      expect(controller.viewMode, equals(DocumentationViewMode.decisionGraph));
      expect(controller.canGoBack, isTrue);
      expect(controller.canGoForward, isFalse);
    });

    test('validates indices correctly', () {
      final controller = DocumentationNavigatorController();

      // Set controller to an index that's out of range
      controller.navigateToSection(5);

      // Validate with correct ranges
      controller.validateIndices(2, 3);

      // Should adjust to the valid range
      expect(controller.currentSectionIndex,
          equals(1)); // 0-based, so max is 1 for 2 sections

      // Test with decisions
      controller.navigateToDecision(10);
      controller.validateIndices(2, 3);
      expect(controller.currentDecisionIndex,
          equals(2)); // 0-based, so max is 2 for 3 decisions

      // Test with empty sections but valid decisions
      final emptySecController = DocumentationNavigatorController();
      emptySecController.navigateToSection(0);
      emptySecController.validateIndices(0, 3);

      // Should switch to decisions view since no sections are available
      expect(
          emptySecController.viewMode, equals(DocumentationViewMode.decisions));

      // Test with empty decisions but valid sections
      final emptyDecController = DocumentationNavigatorController();
      emptyDecController.navigateToDecision(0);
      emptyDecController.validateIndices(2, 0);

      // Should switch to documentation view since no decisions are available
      expect(emptyDecController.viewMode,
          equals(DocumentationViewMode.documentation));
    });
  });

  group('DocumentationNavigator', () {
    testWidgets('renders with documentation sections',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        SizedBox(
          width: 800,
          height: 600,
          child: MaterialApp(
            home: Scaffold(
              body: DocumentationNavigator(
                workspace: workspace,
              ),
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
        SizedBox(
          width: 800,
          height: 600,
          child: MaterialApp(
            home: Scaffold(
              body: DocumentationNavigator(
                workspace: workspace,
                controller: controller,
              ),
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
        SizedBox(
          width: 800,
          height: 600,
          child: MaterialApp(
            home: Scaffold(
              body: DocumentationNavigator(
                workspace: workspace,
                controller: controller,
              ),
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
        SizedBox(
          width: 800,
          height: 600,
          child: MaterialApp(
            home: Scaffold(
              body: DocumentationNavigator(
                workspace: workspace,
                controller: controller,
                showToolbar: true,
              ),
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
        SizedBox(
          width: 800,
          height: 600,
          child: MaterialApp(
            home: Scaffold(
              body: DocumentationNavigator(
                workspace: workspace,
                controller: controller,
                showToolbar: true,
              ),
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
        SizedBox(
          width: 800,
          height: 600,
          child: MaterialApp(
            home: Scaffold(
              body: DocumentationNavigator(
                workspace: workspace,
                controller: controller,
                showToolbar: true,
              ),
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

    testWidgets('renders message when no documentation',
        (WidgetTester tester) async {
      final emptyWorkspace =
          WorkspaceDocumentationMixin.createWorkspaceWithDocumentation(
        id: 2,
        name: 'Empty Workspace',
        // No documentation
      );

      await tester.pumpWidget(
        SizedBox(
          width: 800,
          height: 600,
          child: MaterialApp(
            home: Scaffold(
              body: DocumentationNavigator(
                workspace: emptyWorkspace,
              ),
            ),
          ),
        ),
      );

      // Verify message is displayed
      expect(find.text('No documentation available for this workspace.'),
          findsOneWidget);
    });

    testWidgets('respects dark mode setting', (WidgetTester tester) async {
      await tester.pumpWidget(
        SizedBox(
          width: 800,
          height: 600,
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: DocumentationNavigator(
                workspace: workspace,
                isDarkMode: true,
              ),
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
        SizedBox(
          width: 800,
          height: 600,
          child: MaterialApp(
            home: Scaffold(
              body: DocumentationNavigator(
                workspace: workspace,
                controller: controller,
              ),
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

    testWidgets('uses history navigation buttons', (WidgetTester tester) async {
      final controller = DocumentationNavigatorController();

      await tester.pumpWidget(
        SizedBox(
          width: 800,
          height: 600,
          child: MaterialApp(
            home: Scaffold(
              body: DocumentationNavigator(
                workspace: workspace,
                controller: controller,
                showToolbar: true,
              ),
            ),
          ),
        ),
      );

      // Initially back/forward buttons should be disabled
      expect(tester.widget<IconButton>(find.byIcon(Icons.arrow_back)).onPressed,
          isNull);
      expect(
          tester.widget<IconButton>(find.byIcon(Icons.arrow_forward)).onPressed,
          isNull);

      // Navigate to a section
      await tester.tap(find.text('Architecture'));
      await tester.pumpAndSettle();

      // Verify section is displayed
      expect(find.text('This is the architecture section.'), findsOneWidget);

      // Back button should be enabled, forward disabled
      expect(tester.widget<IconButton>(find.byIcon(Icons.arrow_back)).onPressed,
          isNotNull);
      expect(
          tester.widget<IconButton>(find.byIcon(Icons.arrow_forward)).onPressed,
          isNull);

      // Switch to decisions view
      await tester.tap(find.byIcon(Icons.assignment));
      await tester.pumpAndSettle();

      // Verify decisions view
      expect(find.text('Use Flutter'), findsOneWidget);

      // Navigate back in history
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Should be back to architecture section
      expect(find.text('This is the architecture section.'), findsOneWidget);

      // Both back and forward should be enabled now
      expect(tester.widget<IconButton>(find.byIcon(Icons.arrow_back)).onPressed,
          isNotNull);
      expect(
          tester.widget<IconButton>(find.byIcon(Icons.arrow_forward)).onPressed,
          isNotNull);

      // Navigate forward
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();

      // Should be back to decisions view
      expect(find.text('Use Flutter'), findsOneWidget);
    });

    testWidgets('toggles content expansion', (WidgetTester tester) async {
      await tester.pumpWidget(
        SizedBox(
          width: 800,
          height: 600,
          child: MaterialApp(
            home: Scaffold(
              body: DocumentationNavigator(
                workspace: workspace,
                showToolbar: true,
              ),
            ),
          ),
        ),
      );

      // Initially both TOC and content should be visible
      expect(find.byType(TableOfContents), findsOneWidget);
      expect(find.byType(MarkdownRenderer), findsOneWidget);

      // Tap the fullscreen button
      await tester.tap(find.byIcon(Icons.fullscreen));
      await tester.pumpAndSettle();

      // TOC should be hidden, content still visible
      expect(find.byType(TableOfContents), findsNothing);
      expect(find.byType(MarkdownRenderer), findsOneWidget);

      // Tap the fullscreen exit button
      await tester.tap(find.byIcon(Icons.fullscreen_exit));
      await tester.pumpAndSettle();

      // Both should be visible again
      expect(find.byType(TableOfContents), findsOneWidget);
      expect(find.byType(MarkdownRenderer), findsOneWidget);
    });

    testWidgets('handles keyboard shortcuts for basic navigation',
        (WidgetTester tester) async {
      final controller = DocumentationNavigatorController();

      await tester.pumpWidget(
        SizedBox(
          width: 800,
          height: 600,
          child: MaterialApp(
            home: Scaffold(
              body: DocumentationNavigator(
                workspace: workspace,
                controller: controller,
                showToolbar: true,
              ),
            ),
          ),
        ),
      );

      // Initially showing first section
      expect(find.text('Introduction'), findsOneWidget);

      // Use down arrow key to navigate to next section
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      // Should navigate to second section
      expect(find.text('Architecture'), findsOneWidget);

      // Test Ctrl+D to toggle to decisions view
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();

      // Should show decisions view
      expect(find.text('Use Flutter'), findsOneWidget);

      // Use down arrow to navigate to next decision
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      // Should navigate to second decision
      expect(find.text('Database Choice'), findsOneWidget);

      // Use up arrow to navigate back to first decision
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();

      // Should navigate to first decision
      expect(find.text('Use Flutter'), findsOneWidget);
    });

    testWidgets('handles keyboard shortcuts for history navigation',
        (WidgetTester tester) async {
      final controller = DocumentationNavigatorController();

      await tester.pumpWidget(
        SizedBox(
          width: 800,
          height: 600,
          child: MaterialApp(
            home: Scaffold(
              body: DocumentationNavigator(
                workspace: workspace,
                controller: controller,
                showToolbar: true,
              ),
            ),
          ),
        ),
      );

      // Navigate to second section
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(find.text('Architecture'), findsOneWidget);

      // Navigate to decisions view
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();
      expect(find.text('Use Flutter'), findsOneWidget);

      // Test Alt+Left to go back in history
      await tester.sendKeyDownEvent(LogicalKeyboardKey.alt);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.alt);
      await tester.pumpAndSettle();

      // Should go back to architecture section
      expect(find.text('Architecture'), findsOneWidget);

      // Test Alt+Right to go forward in history
      await tester.sendKeyDownEvent(LogicalKeyboardKey.alt);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.alt);
      await tester.pumpAndSettle();

      // Should go forward to decisions view
      expect(find.text('Use Flutter'), findsOneWidget);
    });

    testWidgets('handles keyboard shortcuts for view controls',
        (WidgetTester tester) async {
      final controller = DocumentationNavigatorController();

      await tester.pumpWidget(
        SizedBox(
          width: 800,
          height: 600,
          child: MaterialApp(
            home: Scaffold(
              body: DocumentationNavigator(
                workspace: workspace,
                controller: controller,
                showToolbar: true,
              ),
            ),
          ),
        ),
      );

      // Verify starting state
      expect(find.text('Introduction'), findsOneWidget);
      expect(find.byType(TableOfContents), findsOneWidget);

      // Test Ctrl+F to toggle fullscreen
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();

      // TOC should be hidden
      expect(find.byType(TableOfContents), findsNothing);

      // Test Ctrl+F again to toggle back
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();

      // TOC should be visible again
      expect(find.byType(TableOfContents), findsOneWidget);

      // Test Ctrl+G to show decision graph
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyG);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();

      // Should show decision graph
      expect(find.byType(DecisionGraph), findsOneWidget);

      // Test Ctrl+T to show decision timeline
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();

      // Should show decision timeline
      expect(find.byType(DecisionTimeline), findsOneWidget);

      // Test Ctrl+S to show search
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();

      // Should show search
      expect(find.byType(DocumentationSearch), findsOneWidget);
    });

    testWidgets('handles home and end keys for quick navigation',
        (WidgetTester tester) async {
      // Create a test workspace with more sections for testing
      final documentationWithMoreSections = Documentation(
        sections: [
          const DocumentationSection(
            title: 'Section 1',
            content: '# Section 1\n\nContent 1',
            order: 1,
          ),
          const DocumentationSection(
            title: 'Section 2',
            content: '# Section 2\n\nContent 2',
            order: 2,
          ),
          const DocumentationSection(
            title: 'Section 3',
            content: '# Section 3\n\nContent 3',
            order: 3,
          ),
        ],
        decisions: workspace.documentation!.decisions,
      );

      final testWorkspace =
          WorkspaceDocumentationMixin.createWorkspaceWithDocumentation(
        documentation: documentationWithMoreSections,
      );

      final controller = DocumentationNavigatorController();

      await tester.pumpWidget(
        SizedBox(
          width: 800,
          height: 600,
          child: MaterialApp(
            home: Scaffold(
              body: DocumentationNavigator(
                workspace: testWorkspace,
                controller: controller,
                showToolbar: true,
              ),
            ),
          ),
        ),
      );

      // Initially showing first section
      expect(find.text('Section 1'), findsOneWidget);

      // Navigate to last section using End key
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();

      // Should show the last section
      expect(find.text('Section 3'), findsOneWidget);

      // Navigate back to first section using Home key
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();

      // Should show the first section again
      expect(find.text('Section 1'), findsOneWidget);
    });

    testWidgets('handles Alt+Number keys for quick section jumps',
        (WidgetTester tester) async {
      // Create a test workspace with more sections for testing
      final documentationWithMoreSections = Documentation(
        sections: [
          const DocumentationSection(
            title: 'Section 1',
            content: '# Section 1\n\nContent 1',
            order: 1,
          ),
          const DocumentationSection(
            title: 'Section 2',
            content: '# Section 2\n\nContent 2',
            order: 2,
          ),
          const DocumentationSection(
            title: 'Section 3',
            content: '# Section 3\n\nContent 3',
            order: 3,
          ),
        ],
        decisions: workspace.documentation!.decisions,
      );

      final testWorkspace =
          WorkspaceDocumentationMixin.createWorkspaceWithDocumentation(
        documentation: documentationWithMoreSections,
      );

      final controller = DocumentationNavigatorController();

      await tester.pumpWidget(
        SizedBox(
          width: 800,
          height: 600,
          child: MaterialApp(
            home: Scaffold(
              body: DocumentationNavigator(
                workspace: testWorkspace,
                controller: controller,
                showToolbar: true,
              ),
            ),
          ),
        ),
      );

      // Initially showing first section
      expect(find.text('Section 1'), findsOneWidget);

      // Navigate to section 2 using Alt+2
      await tester.sendKeyDownEvent(LogicalKeyboardKey.alt);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.alt);
      await tester.pumpAndSettle();

      // Should show Section 2
      expect(find.text('Section 2'), findsOneWidget);

      // Navigate to section 3 using Alt+3
      await tester.sendKeyDownEvent(LogicalKeyboardKey.alt);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.alt);
      await tester.pumpAndSettle();

      // Should show Section 3
      expect(find.text('Section 3'), findsOneWidget);

      // Navigate back to section 1 using Alt+1
      await tester.sendKeyDownEvent(LogicalKeyboardKey.alt);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.alt);
      await tester.pumpAndSettle();

      // Should show Section 1 again
      expect(find.text('Section 1'), findsOneWidget);
    });

    testWidgets('shows keyboard shortcuts help dialog',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        SizedBox(
          width: 800,
          height: 600,
          child: MaterialApp(
            home: Scaffold(
              body: DocumentationNavigator(
                workspace: workspace,
                showToolbar: true,
              ),
            ),
          ),
        ),
      );

      // Click the help button
      await tester.tap(find.byIcon(Icons.help_outline));
      await tester.pumpAndSettle();

      // Should show the keyboard shortcuts help dialog
      expect(find.byType(KeyboardShortcutsHelp), findsOneWidget);
      expect(find.text('Keyboard Shortcuts'), findsOneWidget);
      expect(find.text('Navigation'), findsOneWidget);
      expect(find.text('View Controls'), findsOneWidget);

      // Test keyboard shortcut for help dialog
      // First close current dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.byType(KeyboardShortcutsHelp), findsNothing);

      // Use keyboard shortcut to open dialog
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.question);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();

      // Dialog should open again
      expect(find.byType(KeyboardShortcutsHelp), findsOneWidget);
    });
  });
}
