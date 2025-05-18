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

  group('Documentation DSL Generation', () {
    // Helper function to escape strings
    String escapeString(String str) {
      return str
          .replaceAll('\\', '\\\\')
          .replaceAll('"', '\\"')
          .replaceAll('\n', '\\n');
    }

    // Helper function to generate documentation DSL
    String generateDocumentationDsl(Documentation documentation) {
      final buffer = StringBuffer();
      buffer.writeln('  documentation {');

      // Add documentation sections
      if (documentation.sections.isNotEmpty) {
        for (final section in documentation.sections) {
          // Start section
          buffer.writeln('    section "${escapeString(section.title)}" {');

          // Add format if not markdown (markdown is the default)
          if (section.format != DocumentationFormat.markdown) {
            buffer.writeln(
                '      format "${section.format.toString().split('.').last}"');
          }

          // Add content with proper escaping for multi-line strings
          buffer
              .writeln('      content """${escapeString(section.content)}"""');

          // Close section
          buffer.writeln('    }');
        }
      }

      // Add decisions section if there are any decisions
      if (documentation.decisions.isNotEmpty) {
        buffer.writeln('    decisions {');

        for (final decision in documentation.decisions) {
          // Start decision
          buffer.writeln('      decision "${escapeString(decision.id)}" {');

          // Add decision properties
          buffer.writeln('        title "${escapeString(decision.title)}"');
          buffer.writeln('        status "${escapeString(decision.status)}"');

          // Format date as yyyy-MM-dd
          final date = decision.date;
          final formattedDate =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          buffer.writeln('        date "$formattedDate"');

          // Add format if not markdown (markdown is the default)
          if (decision.format != DocumentationFormat.markdown) {
            buffer.writeln(
                '        format "${decision.format.toString().split('.').last}"');
          }

          // Add content with proper escaping for multi-line strings
          buffer.writeln(
              '        content """${escapeString(decision.content)}"""');

          // Add links to other decisions if any
          if (decision.links.isNotEmpty) {
            final linksStr = decision.links
                .map((link) => '"${escapeString(link)}"')
                .join(', ');
            buffer.writeln('        links $linksStr');
          }

          // Close decision
          buffer.writeln('      }');
        }

        buffer.writeln('    }');
      }

      buffer.writeln('  }');
      return buffer.toString();
    }

    test('generates DSL for documentation with sections', () {
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

      final dsl = generateDocumentationDsl(documentation);

      expect(dsl, contains('documentation {'));
      expect(dsl, contains('section "Overview" {'));
      expect(dsl, contains('content """This is an overview of the system."""'));

      expect(dsl, contains('section "Context" {'));
      expect(dsl, contains('format "asciidoc"'));
      expect(
          dsl,
          contains(
              'content """= System Context\\n\\nThis section describes the system context."""'));
    });

    test('generates DSL for documentation with decisions', () {
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

      final dsl = generateDocumentationDsl(documentation);

      expect(dsl, contains('documentation {'));
      expect(dsl, contains('decisions {'));
      expect(dsl, contains('decision "ADR-001" {'));
      expect(dsl, contains('title "Use Markdown for documentation"'));
      expect(dsl, contains('status "Accepted"'));
      expect(dsl, contains('date "2023-05-15"'));
      expect(
          dsl,
          contains(
              'content """# ADR-001: Use Markdown\\n\\n## Decision\\nWe will use Markdown for documentation..."""'));
      expect(dsl, contains('links "ADR-002"'));

      expect(dsl, contains('decision "ADR-002" {'));
      expect(dsl, contains('title "API Documentation Format"'));
      expect(dsl, contains('status "Proposed"'));
      expect(dsl, contains('date "2023-06-20"'));
    });

    test('generates DSL for documentation with sections and decisions', () {
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

      final dsl = generateDocumentationDsl(documentation);

      expect(dsl, contains('documentation {'));
      expect(dsl, contains('section "Overview" {'));
      expect(dsl, contains('decisions {'));
      expect(dsl, contains('decision "ADR-001" {'));
    });

    test('properly escapes special characters in DSL', () {
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

      final dsl = generateDocumentationDsl(documentation);

      expect(dsl, contains('section "Overview with \\"quotes\\"" {'));
      expect(
          dsl,
          contains(
              'Content with \\"quotes\\" and \\\\ backslashes and line\\nbreaks'));

      expect(dsl, contains('status "Accepted with \\"quotes\\""'));
      expect(dsl, contains('title "Title with \\"quotes\\""'));
      expect(
          dsl,
          contains(
              'Content with \\"quotes\\" and \\\\ backslashes and line\\nbreaks'));
    });

    test('handles empty documentation', () {
      const documentation = Documentation();

      final dsl = generateDocumentationDsl(documentation);

      expect(dsl, contains('documentation {'));
      expect(dsl, isNot(contains('section "')));
      expect(dsl, isNot(contains('decisions {')));
    });
  });
}
