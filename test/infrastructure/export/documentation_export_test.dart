import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/documentation/documentation.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/infrastructure/export/dsl_exporter.dart';

/// A test-specific implementation of DslExporter that exposes protected methods for testing
class TestDslExporter extends DslExporter {
  const TestDslExporter({
    super.includeMetadata = true,
    super.includeDocumentation = true,
    super.includeStyles = true,
    super.includeViews = true,
  });

  /// Expose the _generateDocumentationSection method for testing
  void generateDocumentationSection(StringBuffer buffer, Workspace workspace) {
    _generateDocumentationSection(buffer, workspace);
  }

  /// Expose the _generateDecisionsSection method for testing
  void generateDecisionsSection(StringBuffer buffer, Workspace workspace) {
    _generateDecisionsSection(buffer, workspace);
  }

  /// Expose the _escapeString method for testing
  String escapeString(String str) {
    return _escapeString(str);
  }
}

void main() {
  late TestDslExporter exporter;
  
  setUp(() {
    exporter = const TestDslExporter();
  });

  group('Documentation DSL Export', () {
    test('generates documentation section with markdown content', () {
      // Arrange
      final workspace = _createWorkspaceWithDocumentation(
        sections: [
          const DocumentationSection(
            title: 'Overview',
            content: 'This is an overview of the system.',
            format: DocumentationFormat.markdown,
            order: 1,
          ),
          const DocumentationSection(
            title: 'Getting Started',
            content: '# Getting Started\n\nFollow these steps to get started.',
            format: DocumentationFormat.markdown,
            order: 2,
          ),
        ],
      );
      
      final buffer = StringBuffer();
      
      // Act
      exporter.generateDocumentationSection(buffer, workspace);
      
      // Assert
      final output = buffer.toString();
      expect(output, contains('documentation {'));
      expect(output, contains('section "Overview" {'));
      expect(output, contains('content """This is an overview of the system."""'));
      expect(output, contains('section "Getting Started" {'));
      expect(output, contains('content """# Getting Started\\n\\nFollow these steps to get started."""'));
      
      // Should not contain format specification for markdown (default)
      expect(output.contains('format "markdown"'), isFalse);
    });

    test('generates documentation section with asciidoc content', () {
      // Arrange
      final workspace = _createWorkspaceWithDocumentation(
        sections: [
          const DocumentationSection(
            title: 'AsciiDoc Example',
            content: '= AsciiDoc Title\n\nThis is *bold* content.',
            format: DocumentationFormat.asciidoc,
            order: 1,
          ),
        ],
      );
      
      final buffer = StringBuffer();
      
      // Act
      exporter.generateDocumentationSection(buffer, workspace);
      
      // Assert
      final output = buffer.toString();
      expect(output, contains('documentation {'));
      expect(output, contains('section "AsciiDoc Example" {'));
      expect(output, contains('format "asciidoc"'));
      expect(output, contains('content """= AsciiDoc Title\\n\\nThis is *bold* content."""'));
    });

    test('escapes special characters in documentation content', () {
      // Arrange
      final workspace = _createWorkspaceWithDocumentation(
        sections: [
          const DocumentationSection(
            title: 'Special "Characters"',
            content: 'Content with "quotes" and \\ backslashes and\nnew lines.',
            format: DocumentationFormat.markdown,
            order: 1,
          ),
        ],
      );
      
      final buffer = StringBuffer();
      
      // Act
      exporter.generateDocumentationSection(buffer, workspace);
      
      // Assert
      final output = buffer.toString();
      expect(output, contains('section "Special \\"Characters\\"" {'));
      expect(output, contains('content """Content with \\"quotes\\" and \\\\ backslashes and\\nnew lines."""'));
    });

    test('does not generate documentation section when sections is empty', () {
      // Arrange
      final workspace = _createWorkspaceWithDocumentation(
        sections: [],
      );
      
      final buffer = StringBuffer();
      
      // Act
      exporter.generateDocumentationSection(buffer, workspace);
      
      // Assert
      final output = buffer.toString();
      expect(output, isEmpty);
    });
  });

  group('Decisions DSL Export', () {
    test('generates decisions section with proper formatting', () {
      // Arrange
      final testDate = DateTime(2023, 5, 15);
      final workspace = _createWorkspaceWithDocumentation(
        decisions: [
          Decision(
            id: 'ADR-001',
            date: testDate,
            status: 'Accepted',
            title: 'Use Markdown for documentation',
            content: 'We will use Markdown for documentation because it is widely supported.',
          ),
        ],
      );
      
      final buffer = StringBuffer();
      
      // Act
      exporter.generateDecisionsSection(buffer, workspace);
      
      // Assert
      final output = buffer.toString();
      expect(output, contains('decisions {'));
      expect(output, contains('decision "ADR-001" {'));
      expect(output, contains('title "Use Markdown for documentation"'));
      expect(output, contains('status "Accepted"'));
      expect(output, contains('date "2023-05-15"'));
      expect(output, contains('content """We will use Markdown for documentation because it is widely supported."""'));
    });

    test('generates decisions with links to other decisions', () {
      // Arrange
      final testDate = DateTime(2023, 5, 15);
      final workspace = _createWorkspaceWithDocumentation(
        decisions: [
          Decision(
            id: 'ADR-001',
            date: testDate,
            status: 'Accepted',
            title: 'Use Markdown for documentation',
            content: 'We will use Markdown for documentation because it is widely supported.',
            links: ['ADR-002', 'ADR-003'],
          ),
        ],
      );
      
      final buffer = StringBuffer();
      
      // Act
      exporter.generateDecisionsSection(buffer, workspace);
      
      // Assert
      final output = buffer.toString();
      expect(output, contains('links "ADR-002", "ADR-003"'));
    });

    test('generates decisions with asciidoc format', () {
      // Arrange
      final testDate = DateTime(2023, 5, 15);
      final workspace = _createWorkspaceWithDocumentation(
        decisions: [
          Decision(
            id: 'ADR-001',
            date: testDate,
            status: 'Accepted',
            title: 'Use AsciiDoc for documentation',
            content: '= ADR 001\n\nWe will use *AsciiDoc* for documentation.',
            format: DocumentationFormat.asciidoc,
          ),
        ],
      );
      
      final buffer = StringBuffer();
      
      // Act
      exporter.generateDecisionsSection(buffer, workspace);
      
      // Assert
      final output = buffer.toString();
      expect(output, contains('format "asciidoc"'));
    });
    
    test('handles special characters in decision properties', () {
      // Arrange
      final testDate = DateTime(2023, 5, 15);
      final workspace = _createWorkspaceWithDocumentation(
        decisions: [
          Decision(
            id: 'ADR-001 "Special"',
            date: testDate,
            status: 'Accepted & Implemented',
            title: 'Title with "quotes" and \\ backslashes',
            content: 'Content with "quotes" and \\ backslashes and\nnew lines.',
          ),
        ],
      );
      
      final buffer = StringBuffer();
      
      // Act
      exporter.generateDecisionsSection(buffer, workspace);
      
      // Assert
      final output = buffer.toString();
      expect(output, contains('decision "ADR-001 \\"Special\\"" {'));
      expect(output, contains('status "Accepted & Implemented"'));
      expect(output, contains('title "Title with \\"quotes\\" and \\\\ backslashes"'));
      expect(output, contains('content """Content with \\"quotes\\" and \\\\ backslashes and\\nnew lines."""'));
    });

    test('does not generate decisions section when decisions is empty', () {
      // Arrange
      final workspace = _createWorkspaceWithDocumentation(
        decisions: [],
      );
      
      final buffer = StringBuffer();
      
      // Act
      exporter.generateDecisionsSection(buffer, workspace);
      
      // Assert
      final output = buffer.toString();
      expect(output, isEmpty);
    });
  });

  group('String escaping', () {
    test('escapes quotes, backslashes and newlines correctly', () {
      // Arrange
      const testString = 'This is a "quoted" string with \\ backslashes and\nnew lines.';
      
      // Act
      final escaped = exporter.escapeString(testString);
      
      // Assert
      expect(escaped, 'This is a \\"quoted\\" string with \\\\ backslashes and\\nnew lines.');
    });
    
    test('handles empty strings', () {
      // Arrange
      const testString = '';
      
      // Act
      final escaped = exporter.escapeString(testString);
      
      // Assert
      expect(escaped, '');
    });
    
    test('handles strings with only special characters', () {
      // Arrange
      const testString = '"\\\n';
      
      // Act
      final escaped = exporter.escapeString(testString);
      
      // Assert
      expect(escaped, '\\"\\\\\\n');
    });
  });
}

/// Helper to create workspace with documentation for testing
Workspace _createWorkspaceWithDocumentation({
  List<DocumentationSection> sections = const [],
  List<Decision> decisions = const [],
  List<Image> images = const [],
}) {
  return Workspace(
    id: 1,
    name: 'Test Workspace',
    model: Model(),
    documentation: Documentation(
      sections: sections,
      decisions: decisions,
      images: images,
    ),
  );
}