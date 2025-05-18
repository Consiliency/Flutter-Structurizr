import 'package:flutter/material.dart';
import 'package:flutter_structurizr/domain/documentation/documentation.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/documentation_search.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/documentation_search_controller.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/documentation_search_index.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Legacy DocumentationSearchController', () {
    late DocumentationSearchController controller;
    late Documentation documentation;

    setUp(() {
      // Set up test documentation
      documentation = Documentation(
        sections: [
          const DocumentationSection(
            title: 'Getting Started',
            content: 'This is a guide to getting started with the application.',
            order: 1,
          ),
          const DocumentationSection(
            title: 'Advanced Features',
            content: 'These are the advanced features of the application. '
                'Some features require configuration.',
            order: 2,
          ),
        ],
        decisions: [
          Decision(
            id: 'ADR-001',
            date: DateTime(2023, 1, 1),
            status: 'Accepted',
            title: 'Use Flutter for UI',
            content: 'We decided to use Flutter for the UI implementation '
                'because it provides a fast development experience and '
                'cross-platform support.',
          ),
          Decision(
            id: 'ADR-002',
            date: DateTime(2023, 2, 1),
            status: 'Proposed',
            title: 'Database Selection',
            content: 'We are considering using a local database for storage.',
          ),
        ],
      );

      controller = DocumentationSearchController();
      controller.setDocumentation(documentation);
    });

    tearDown(() {
      controller.dispose();
    });

    test('search finds matches in sections and decisions', () {
      // Act
      controller.search('guide');

      // Assert
      expect(controller.results.length, 1);
      expect(controller.results[0].section, documentation.sections[0]);
      expect(controller.results[0].matchedText, 'guide');

      // Act - search with multiple matches
      controller.search('application');

      // Assert
      expect(controller.results.length, 2);
      expect(controller.results[0].section, documentation.sections[0]);
      expect(controller.results[1].section, documentation.sections[1]);

      // Act - search in decision content
      controller.search('flutter');

      // Assert
      expect(controller.results.length, 1);
      expect(controller.results[0].decision, documentation.decisions[0]);
      expect(controller.results[0].matchedText.toLowerCase(), 'flutter');
    });

    test('search is case insensitive', () {
      // Act
      controller.search('GUIDE');

      // Assert
      expect(controller.results.length, 1);
      expect(controller.results[0].matchedText.toLowerCase(), 'guide');

      // Act
      controller.search('Flutter');

      // Assert
      expect(controller.results.length, 1);
      expect(controller.results[0].matchedText.toLowerCase(), 'flutter');
    });

    test('clear resets search state', () {
      // Arrange
      controller.search('guide');
      expect(controller.results.length, 1);

      // Act
      controller.clear();

      // Assert
      expect(controller.query, '');
      expect(controller.results, isEmpty);
      expect(controller.isSearching, false);
    });

    test('handles empty search query', () {
      // Act
      controller.search('');

      // Assert
      expect(controller.results, isEmpty);
      expect(controller.isSearching, false);
    });

    test('handles null documentation', () {
      // Arrange
      controller = DocumentationSearchController();

      // Act
      controller.search('test');

      // Assert
      expect(controller.results, isEmpty);
      expect(controller.isSearching, false);
    });
  });

  group('Enhanced Documentation Search', () {
    late DocumentationSearchIndex searchIndex;
    late Workspace workspace;

    setUp(() {
      // Create a test workspace with documentation
      final documentation = Documentation(
        sections: [
          const DocumentationSection(
            title: 'Introduction',
            content:
                'This is the introduction to the project. It provides an overview of the system architecture.',
            metadata: {
              'author': 'John Doe',
              'date': '2023-05-20',
            },
          ),
          const DocumentationSection(
            title: 'Architecture',
            content:
                'The architecture follows a clean architecture approach with domain-driven design.',
            metadata: {
              'author': 'Jane Smith',
              'date': '2023-05-21',
            },
          ),
          const DocumentationSection(
            title: 'Components',
            content:
                'The system consists of multiple components including the backend API and frontend UI.',
            metadata: {
              'author': 'John Doe',
              'date': '2023-05-22',
            },
          ),
        ],
        decisions: [
          Decision(
            id: 'ADR-001',
            title: 'Use Markdown for Documentation',
            status: 'Accepted',
            date: DateTime(2023, 5, 15),
            content:
                'We will use Markdown for documentation because it is simple and widely supported.',
          ),
          Decision(
            id: 'ADR-002',
            title: 'Database Technology Selection',
            status: 'Proposed',
            date: DateTime(2023, 5, 16),
            content:
                'We are considering PostgreSQL for the database due to its robust features and reliability.',
          ),
          Decision(
            id: 'ADR-003',
            title: 'Frontend Framework',
            status: 'Rejected',
            date: DateTime(2023, 5, 17),
            content:
                'We considered using React but decided against it in favor of Flutter for cross-platform support.',
          ),
        ],
      );

      workspace = Workspace(
        name: 'Test Workspace',
        documentation: documentation,
      );

      searchIndex = DocumentationSearchIndex.fromWorkspace(workspace);
    });

    test('indexWorkspace builds the search index correctly', () {
      expect(searchIndex.isBuilt, isTrue);
      expect(searchIndex.documentCount, equals(6)); // 3 sections + 3 decisions
    });

    test('search returns results for basic query', () {
      final results = searchIndex.search('architecture');

      expect(results, isNotEmpty);
      expect(results.any((result) => result.title == 'Architecture'), isTrue);
      expect(results.any((result) => result.content.contains('architecture')),
          isTrue);
    });

    test('search returns empty list for empty query', () {
      final results = searchIndex.search('');
      expect(results, isEmpty);
    });

    test('search prioritizes title matches over content matches', () {
      final results = searchIndex.search('architecture');

      // The Architecture section should be ranked higher than sections that only
      // mention architecture in their content
      final titleMatch =
          results.firstWhere((result) => result.title == 'Architecture');
      final contentMatch = results.firstWhere((result) =>
          result.title != 'Architecture' &&
          result.content.contains('architecture'));

      expect(titleMatch.relevance, greaterThan(contentMatch.relevance));
    });

    test('search includes matched terms in results', () {
      final results = searchIndex.search('architecture');

      expect(results, isNotEmpty);
      for (final result in results) {
        expect(result.matchedTerms, contains('architecture'));
      }
    });

    test('search supports filtering by type', () {
      final results = searchIndex.search('type:decision');

      expect(results, isNotEmpty);
      for (final result in results) {
        expect(result.type, equals('decision'));
      }
    });

    test('search supports filtering by status', () {
      final results = searchIndex.search('status:accepted');

      expect(results, isNotEmpty);
      for (final result in results) {
        expect(result.metadata['status']?.toLowerCase(), equals('accepted'));
      }
    });

    test('search supports combined filtering and terms', () {
      final results = searchIndex.search('documentation type:decision');

      expect(results, isNotEmpty);
      for (final result in results) {
        expect(result.type, equals('decision'));
        expect(result.content.toLowerCase().contains('documentation'), isTrue);
      }
    });
  });

  group('DocumentationSearch Widget', () {
    late Documentation documentation;

    setUp(() {
      // Set up test documentation
      documentation = Documentation(
        sections: [
          const DocumentationSection(
            title: 'Getting Started',
            content: 'This is a guide to getting started with the application.',
            order: 1,
          ),
          const DocumentationSection(
            title: 'Advanced Features',
            content: 'These are the advanced features of the application.',
            order: 2,
          ),
        ],
        decisions: [
          Decision(
            id: 'ADR-001',
            date: DateTime(2023, 1, 1),
            status: 'Accepted',
            title: 'Use Flutter for UI',
            content: 'We decided to use Flutter for the UI implementation.',
          ),
        ],
      );
    });

    testWidgets('renders search field and initial state',
        (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentationSearch(
              documentation: documentation,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Enter a search query to find content'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('displays search results', (WidgetTester tester) async {
      // Arrange
      final controller = DocumentationSearchController();
      controller.setDocumentation(documentation);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentationSearch(
              documentation: documentation,
              controller: controller,
            ),
          ),
        ),
      );

      // Enter search query
      await tester.enterText(find.byType(TextField), 'guide');
      await tester.pump();
      await tester
          .pump(const Duration(milliseconds: 300)); // Allow for async search

      // Assert
      expect(find.text('Getting Started'), findsOneWidget);
      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('displays no results message', (WidgetTester tester) async {
      // Arrange
      final controller = DocumentationSearchController();
      controller.setDocumentation(documentation);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentationSearch(
              documentation: documentation,
              controller: controller,
            ),
          ),
        ),
      );

      // Enter search query that won't match anything
      await tester.enterText(find.byType(TextField), 'nonexistent');
      await tester.pump();
      await tester
          .pump(const Duration(milliseconds: 300)); // Allow for async search

      // Assert
      expect(find.text('No results found for "nonexistent"'), findsOneWidget);
    });

    testWidgets('clears search when clear button is tapped',
        (WidgetTester tester) async {
      // Arrange
      final controller = DocumentationSearchController();
      controller.setDocumentation(documentation);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentationSearch(
              documentation: documentation,
              controller: controller,
            ),
          ),
        ),
      );

      // Enter search query
      await tester.enterText(find.byType(TextField), 'guide');
      await tester.pump();

      // Clear button should be visible
      expect(find.byIcon(Icons.clear), findsOneWidget);

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      // Assert
      expect(find.text('Enter a search query to find content'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('calls onSectionSelected when a section result is tapped',
        (WidgetTester tester) async {
      // Arrange
      int? selectedSectionIndex;
      final controller = DocumentationSearchController();
      controller.setDocumentation(documentation);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentationSearch(
              documentation: documentation,
              controller: controller,
              onSectionSelected: (index) {
                selectedSectionIndex = index;
              },
            ),
          ),
        ),
      );

      // Enter search query
      await tester.enterText(find.byType(TextField), 'guide');
      await tester.pump();
      await tester
          .pump(const Duration(milliseconds: 300)); // Allow for async search

      // Tap on the result
      await tester.tap(find.text('Getting Started'));
      await tester.pump();

      // Assert
      expect(selectedSectionIndex, 0);
    });
  });
}
