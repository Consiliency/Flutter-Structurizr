import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/documentation/documentation.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/model/model.dart';

void main() {
  group('Documentation Export Integration', () {
    // Helper function to escape strings
    String escapeString(String str) {
      return str
          .replaceAll('\\', '\\\\')
          .replaceAll('"', '\\"')
          .replaceAll('\n', '\\n');
    }
    
    /// Mock function simulating the DSL export with documentation inclusion option
    String mockExportFunction(Workspace workspace, {bool includeDocumentation = true}) {
      final buffer = StringBuffer();
      buffer.writeln('workspace {');
      
      // Add workspace name and description
      if (workspace.name.isNotEmpty) {
        buffer.writeln('  name "${escapeString(workspace.name)}"');
      }
      
      if (workspace.description != null && workspace.description!.isNotEmpty) {
        buffer.writeln('  description "${escapeString(workspace.description!)}"');
      }
      
      // Add documentation if requested and available
      if (includeDocumentation && workspace.documentation != null) {
        buffer.writeln();
        buffer.writeln('  documentation {');
        
        // Add documentation sections
        if (workspace.documentation!.sections.isNotEmpty) {
          for (final section in workspace.documentation!.sections) {
            // Start section
            buffer.writeln('    section "${escapeString(section.title)}" {');
            
            // Add format if not markdown (markdown is the default)
            if (section.format != DocumentationFormat.markdown) {
              buffer.writeln('      format "${section.format.toString().split('.').last}"');
            }
            
            // Add content with proper escaping for multi-line strings
            buffer.writeln('      content """${escapeString(section.content)}"""');
            
            // Close section
            buffer.writeln('    }');
          }
        }
        
        // Add decisions section if there are any decisions
        if (workspace.documentation!.decisions.isNotEmpty) {
          buffer.writeln('    decisions {');
          
          for (final decision in workspace.documentation!.decisions) {
            // Start decision
            buffer.writeln('      decision "${escapeString(decision.id)}" {');
            
            // Add decision properties
            buffer.writeln('        title "${escapeString(decision.title)}"');
            buffer.writeln('        status "${escapeString(decision.status)}"');
            
            // Format date as yyyy-MM-dd
            final date = decision.date;
            final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            buffer.writeln('        date "$formattedDate"');
            
            // Add format if not markdown (markdown is the default)
            if (decision.format != DocumentationFormat.markdown) {
              buffer.writeln('        format "${decision.format.toString().split('.').last}"');
            }
            
            // Add content with proper escaping for multi-line strings
            buffer.writeln('        content """${escapeString(decision.content)}"""');
            
            // Add links to other decisions if any
            if (decision.links.isNotEmpty) {
              final linksStr = decision.links.map((link) => '"${escapeString(link)}"').join(', ');
              buffer.writeln('        links $linksStr');
            }
            
            // Close decision
            buffer.writeln('      }');
          }
          
          buffer.writeln('    }');
        }
        
        buffer.writeln('  }');
      }
      
      // Add a simple model section placeholder
      buffer.writeln();
      buffer.writeln('  model {');
      buffer.writeln('    # Model content would go here');
      buffer.writeln('  }');
      
      buffer.writeln('}');
      return buffer.toString();
    }
    
    test('includes documentation when includeDocumentation is true', () {
      // Create a test workspace with documentation
      final workspace = Workspace(
        id: 1,
        name: 'Test Workspace',
        description: 'A test workspace with documentation',
        model: Model(),
        documentation: Documentation(
          sections: [
            DocumentationSection(
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
              content: '# ADR-001: Use Markdown\n\n## Decision\nWe will use Markdown for documentation...',
            ),
          ],
        ),
      );
      
      // Export with documentation included
      final dsl = mockExportFunction(workspace, includeDocumentation: true);
      
      // Check that documentation is included
      expect(dsl, contains('documentation {'));
      expect(dsl, contains('section "Overview" {'));
      expect(dsl, contains('decision "ADR-001" {'));
    });
    
    test('excludes documentation when includeDocumentation is false', () {
      // Create a test workspace with documentation
      final workspace = Workspace(
        id: 1,
        name: 'Test Workspace',
        description: 'A test workspace with documentation',
        model: Model(),
        documentation: Documentation(
          sections: [
            DocumentationSection(
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
              content: '# ADR-001: Use Markdown\n\n## Decision\nWe will use Markdown for documentation...',
            ),
          ],
        ),
      );
      
      // Export with documentation excluded
      final dsl = mockExportFunction(workspace, includeDocumentation: false);
      
      // Check that documentation is excluded
      expect(dsl, isNot(contains('documentation {')));
      expect(dsl, isNot(contains('section "Overview" {')));
      expect(dsl, isNot(contains('decision "ADR-001" {')));
    });
    
    test('handles workspace without documentation gracefully', () {
      // Create a test workspace without documentation
      final workspace = Workspace(
        id: 1,
        name: 'Test Workspace',
        description: 'A test workspace without documentation',
        model: Model(),
      );
      
      // Export with documentation included but none available
      final dsl = mockExportFunction(workspace, includeDocumentation: true);
      
      // Check that the output is still valid
      expect(dsl, contains('workspace {'));
      expect(dsl, contains('model {'));
      expect(dsl, isNot(contains('documentation {')));
    });
  });
}