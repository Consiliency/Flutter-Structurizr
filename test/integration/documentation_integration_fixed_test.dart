import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/application/dsl/workspace_mapper.dart';
import 'package:flutter_structurizr/domain/documentation/documentation.dart';
import 'package:flutter_structurizr/domain/parser/parser_fixed.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:logging/logging.dart';

final _logger = Logger('DocumentationIntegrationFixedTest');

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print(
        '[\u001b[32m\u001b[1m\u001b[40m\u001b[0m${record.level.name}] ${record.loggerName}: ${record.message}');
  });

  group('Documentation Integration Tests with Fixed Parser', () {
    test('documentation block is parsed and mapped to domain model', () {
      const source = '''
        workspace "Documentation Test" {
          documentation {
            content = "This is the main documentation content"
            section "Getting Started" {
              content = "This is how to get started with the system"
            }
            section "Architecture" {
              content = "This section describes the architecture"
            }
          }
        }
      ''';

      // Parse the DSL source
      final fixedParser = FixedParser(source);
      final workspaceNode = fixedParser.parse();

      // Print debugging info about workspaceNode
      _logger.info(
          'Documentation test: workspaceNode has documentation: ${workspaceNode.documentation != null}');
      _logger.info(
          'Documentation test: workspaceNode has decisions: ${workspaceNode.decisions != null ? workspaceNode.decisions!.length : 0}');

      if (workspaceNode.documentation != null) {
        _logger.info(
            'Documentation test: content: "${workspaceNode.documentation!.content}"');
        _logger.info(
            'Documentation test: sections count: ${workspaceNode.documentation!.sections.length}');
      }

      // Map the AST to domain model
      final errorReporter = ErrorReporter(source);
      final mapper = WorkspaceMapper(source, errorReporter);
      final workspace = mapper.mapWorkspace(workspaceNode);

      // Print debugging info about parsing
      _logger.info(
          'Documentation test: errorReporter has errors: ${errorReporter.hasErrors}');
      if (errorReporter.hasErrors) {
        for (final error in errorReporter.errors) {
          _logger.severe('Documentation test: ERROR: $error');
        }
      }

      // Verify the documentation was properly mapped
      expect(workspace, isNotNull);
      expect(workspace!.documentation, isNotNull);
      expect(workspace.documentation!.sections,
          hasLength(3)); // main content + 2 sections

      // Check the "Overview" section (created from main content)
      final overview = workspace.documentation!.sections.firstWhere(
        (section) => section.title == 'Overview',
        orElse: () =>
            const DocumentationSection(title: '', content: '', order: 0),
      );
      expect(overview.title, isNotEmpty);
      expect(overview.content, 'This is the main documentation content');
      expect(overview.format, DocumentationFormat.markdown);

      // Check other sections
      final sections = workspace.documentation!.sections
          .where((s) => s.title != 'Overview')
          .toList();
      expect(sections, hasLength(2));
      expect(sections[0].title, 'Getting Started');
      expect(sections[0].content, 'This is how to get started with the system');
      expect(sections[1].title, 'Architecture');
      expect(sections[1].content, 'This section describes the architecture');
    });

    test('decisions are parsed and mapped to domain model', () {
      const source = '''
        workspace "Documentation Test" {
          decisions {
            decision "ADR-001" {
              title = "Use C4 model"
              status = "Accepted"
              date = "2023-05-15"
              content = "We will use the C4 model for our architecture documentation."
            }
            decision "ADR-002" {
              title = "Use Markdown for documentation"
              status = "Accepted"
              date = "2023-06-01"
              content = "We will use Markdown for all documentation."
              link "ADR-001"
            }
          }
        }
      ''';

      // Parse the DSL source
      final fixedParser = FixedParser(source);
      final workspaceNode = fixedParser.parse();

      // Print debugging info about workspaceNode
      _logger.info(
          'Decisions test: workspaceNode has documentation: ${workspaceNode.documentation != null}');
      _logger.info(
          'Decisions test: workspaceNode has decisions: ${workspaceNode.decisions != null ? workspaceNode.decisions!.length : 0}');

      if (workspaceNode.decisions != null &&
          workspaceNode.decisions!.isNotEmpty) {
        _logger.info(
            'Decisions test: first decision ID: "${workspaceNode.decisions![0].decisionId}"');
        _logger.info(
            'Decisions test: first decision title: "${workspaceNode.decisions![0].title}"');
      }

      // Map the AST to domain model
      final errorReporter = ErrorReporter(source);
      final mapper = WorkspaceMapper(source, errorReporter);
      final workspace = mapper.mapWorkspace(workspaceNode);

      // Print debugging info about parsing
      _logger.info(
          'Decisions test: errorReporter has errors: ${errorReporter.hasErrors}');
      if (errorReporter.hasErrors) {
        for (final error in errorReporter.errors) {
          _logger.severe('Decisions test: ERROR: $error');
        }
      }

      // Verify the decisions were properly mapped
      expect(workspace, isNotNull);
      expect(workspace!.documentation, isNotNull);
      expect(workspace.documentation!.decisions, hasLength(2));

      final decisions = workspace.documentation!.decisions;
      expect(decisions[0].id, 'ADR-001');
      expect(decisions[0].title, 'Use C4 model');
      expect(decisions[0].status, 'Accepted');
      // The date should be parsed
      expect(decisions[0].date, DateTime(2023, 5, 15));
      expect(decisions[0].content,
          'We will use the C4 model for our architecture documentation.');
      expect(decisions[0].links, isEmpty);

      expect(decisions[1].id, 'ADR-002');
      expect(decisions[1].title, 'Use Markdown for documentation');
      expect(decisions[1].status, 'Accepted');
      expect(decisions[1].date, DateTime(2023, 6, 1));
      expect(
          decisions[1].content, 'We will use Markdown for all documentation.');
      expect(decisions[1].links, ['ADR-001']);
    });

    test('combined documentation and decisions are mapped correctly', () {
      const source = '''
        workspace "Documentation Test" {
          documentation {
            content = "This is the main documentation content"
            section "Architecture Decisions" {
              content = "This section summarizes the key architecture decisions."
            }
          }
          
          decisions {
            decision "ADR-001" {
              title = "Use C4 model"
              status = "Accepted"
              date = "2023-05-15"
              content = "We will use the C4 model for our architecture documentation."
            }
          }
        }
      ''';

      // Parse the DSL source
      final fixedParser = FixedParser(source);
      final workspaceNode = fixedParser.parse();

      // Print debugging info about workspaceNode
      _logger.info(
          'Combined test: workspaceNode has documentation: ${workspaceNode.documentation != null}');
      _logger.info(
          'Combined test: workspaceNode has decisions: ${workspaceNode.decisions != null ? workspaceNode.decisions!.length : 0}');

      if (workspaceNode.documentation != null) {
        _logger.info(
            'Combined test: content: "${workspaceNode.documentation!.content}"');
        _logger.info(
            'Combined test: sections count: ${workspaceNode.documentation!.sections.length}');
      }

      // Map the AST to domain model
      final errorReporter = ErrorReporter(source);
      final mapper = WorkspaceMapper(source, errorReporter);
      final workspace = mapper.mapWorkspace(workspaceNode);

      // Print debugging info about parsing
      _logger.info(
          'Combined test: errorReporter has errors: ${errorReporter.hasErrors}');
      if (errorReporter.hasErrors) {
        for (final error in errorReporter.errors) {
          _logger.severe('Combined test: ERROR: $error');
        }
      }

      // Verify the documentation and decisions were properly mapped
      expect(workspace, isNotNull);
      expect(workspace!.documentation, isNotNull);
      expect(workspace.documentation!.sections,
          hasLength(2)); // Main content + 1 section
      expect(workspace.documentation!.decisions, hasLength(1));

      // Check section
      expect(
          workspace.documentation!.sections[1].title, 'Architecture Decisions');

      // Check decision
      expect(workspace.documentation!.decisions[0].id, 'ADR-001');
      expect(workspace.documentation!.decisions[0].title, 'Use C4 model');
    });
  });
}
