import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/documentation/documentation.dart';
import 'package:logging/logging.dart';

final logger = Logger('TestLogger');

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    logger.info(
        '[\u001b[32m\u001b[1m\u001b[40m\u001b[0m${record.level.name}] ${record.loggerName}: ${record.message}');
  });

  group('Documentation Model', () {
    test('creates documentation with sections', () {
      const documentation = Documentation(
        sections: [
          DocumentationSection(
            title: 'Overview',
            content: 'This is an overview of the system.',
            format: DocumentationFormat.markdown,
            order: 1,
          ),
          DocumentationSection(
            title: 'Context',
            content:
                '= System Context\n\nThis section describes the system context.',
            format: DocumentationFormat.asciidoc,
            order: 2,
          ),
        ],
      );

      expect(documentation.sections.length, equals(2));
      expect(documentation.sections[0].title, equals('Overview'));
      expect(documentation.sections[0].format,
          equals(DocumentationFormat.markdown));
      expect(documentation.sections[1].title, equals('Context'));
      expect(documentation.sections[1].format,
          equals(DocumentationFormat.asciidoc));
    });

    test('creates documentation with decisions', () {
      final documentation = Documentation(
        decisions: [
          Decision(
            id: 'ADR-001',
            date: DateTime(2023, 5, 15),
            status: 'Accepted',
            title: 'Use Markdown for documentation',
            content:
                '# ADR-001: Use Markdown\n\n## Decision\nWe will use Markdown for documentation...',
            links: ['ADR-002'],
          ),
          Decision(
            id: 'ADR-002',
            date: DateTime(2023, 6, 20),
            status: 'Proposed',
            title: 'API Documentation Format',
            content:
                '# ADR-002: API Documentation Format\n\n## Context\nWe need to document our APIs...',
            format: DocumentationFormat.markdown,
          ),
        ],
      );

      expect(documentation.decisions.length, equals(2));
      expect(documentation.decisions[0].id, equals('ADR-001'));
      expect(documentation.decisions[0].status, equals('Accepted'));
      expect(documentation.decisions[1].id, equals('ADR-002'));
      expect(documentation.decisions[1].status, equals('Proposed'));
    });

    test('creates documentation with sections and decisions', () {
      final documentation = Documentation(
        sections: [
          const DocumentationSection(
            title: 'Overview',
            content: 'This is an overview of the system.',
            format: DocumentationFormat.markdown,
            order: 1,
          ),
        ],
        decisions: [
          Decision(
            id: 'ADR-001',
            date: DateTime(2023, 5, 15),
            status: 'Accepted',
            title: 'Use Markdown for documentation',
            content:
                '# ADR-001: Use Markdown\n\n## Decision\nWe will use Markdown for documentation...',
          ),
        ],
      );

      expect(documentation.sections.length, equals(1));
      expect(documentation.decisions.length, equals(1));
    });

    test('handles special characters in content', () {
      final documentation = Documentation(
        sections: [
          const DocumentationSection(
            title: 'Overview with "quotes"',
            content:
                'Content with "quotes" and \\ backslashes and line\nbreaks',
            format: DocumentationFormat.markdown,
            order: 1,
          ),
        ],
        decisions: [
          Decision(
            id: 'ADR-001',
            date: DateTime(2023, 5, 15),
            status: 'Accepted with "quotes"',
            title: 'Title with "quotes"',
            content:
                'Content with "quotes" and \\ backslashes and line\nbreaks',
          ),
        ],
      );

      expect(documentation.sections[0].title, equals('Overview with "quotes"'));
      expect(documentation.sections[0].content, contains('"quotes"'));
      expect(documentation.sections[0].content, contains('\\'));
      expect(documentation.sections[0].content, contains('line\nbreaks'));

      expect(
          documentation.decisions[0].status, equals('Accepted with "quotes"'));
      expect(documentation.decisions[0].title, equals('Title with "quotes"'));
      expect(documentation.decisions[0].content, contains('"quotes"'));
      expect(documentation.decisions[0].content, contains('\\'));
      expect(documentation.decisions[0].content, contains('line\nbreaks'));
    });
  });
}
