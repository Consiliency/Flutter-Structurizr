import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/application/dsl/documentation_mapper.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/documentation/documentation_node.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';

void main() {
  group('DocumentationMapper', () {
    late DocumentationMapper mapper;
    late ErrorReporter errorReporter;

    setUp(() {
      errorReporter = ErrorReporter('');
      mapper = DocumentationMapper(errorReporter);
    });

    test('mapDocumentation converts DocumentationNode to Documentation', () {
      // Create a DocumentationNode AST node
      final docNode = DocumentationNode(
        content: 'This is documentation content',
        format: DocumentationFormat.markdown,
        sections: [
          DocumentationSectionNode(
            title: 'Section 1',
            content: 'Section 1 content',
            sourcePosition: null,
          ),
          DocumentationSectionNode(
            title: 'Section 2',
            content: 'Section 2 content',
            sourcePosition: null,
          ),
        ],
        sourcePosition: null,
      );

      // Map it to a domain Documentation object
      final result = mapper.mapDocumentation(docNode);

      // Verify the result
      expect(result, isNotNull);
      expect(result!.sections.length, 3); // Overview + 2 sections

      // Check the Overview section
      final sections = result.sections;
      final overview = sections.firstWhere((s) => s.title == 'Overview');
      expect(overview, isNotNull);
      expect(overview.content, 'This is documentation content');

      // Check the other sections
      final section1 = sections.firstWhere((s) => s.title == 'Section 1');
      expect(section1, isNotNull);
      expect(section1.content, 'Section 1 content');

      final section2 = sections.firstWhere((s) => s.title == 'Section 2');
      expect(section2, isNotNull);
      expect(section2.content, 'Section 2 content');
    });

    test('mapDecisions converts DecisionNode list to Decision list', () {
      // Create a list of DecisionNode AST nodes
      final decisionNodes = [
        DecisionNode(
          decisionId: 'ADR-001',
          title: 'Use Markdown',
          status: 'Accepted',
          date: '2023-05-15',
          content: 'We will use Markdown for documentation',
          sourcePosition: null,
        ),
        DecisionNode(
          decisionId: 'ADR-002',
          title: 'Use C4 Model',
          status: 'Proposed',
          date: '2023-06-01',
          content: 'We will use C4 Model for architecture documentation',
          links: ['ADR-001'],
          sourcePosition: null,
        ),
      ];

      // Map them to domain Decision objects
      final results = mapper.mapDecisions(decisionNodes);

      // Verify the results
      expect(results.length, 2);
      expect(results[0].id, 'ADR-001');
      expect(results[0].title, 'Use Markdown');
      expect(results[0].status, 'Accepted');
      expect(results[0].date, DateTime(2023, 5, 15));
      expect(results[0].content, 'We will use Markdown for documentation');
      expect(results[0].links, isEmpty);

      expect(results[1].id, 'ADR-002');
      expect(results[1].title, 'Use C4 Model');
      expect(results[1].status, 'Proposed');
      expect(results[1].date, DateTime(2023, 6, 1));
      expect(results[1].content,
          'We will use C4 Model for architecture documentation');
      expect(results[1].links, ['ADR-001']);
    });
  });
}
