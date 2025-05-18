import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/parser/parser.dart';
import 'package:flutter_structurizr/application/dsl/workspace_mapper.dart';

void main() {
  group('Problematic Workspace Name Test', () {
    void testWorkspaceName(String source, String expectedName) {
      final errorReporter = ErrorReporter(source);
      final parser = Parser(source);
      final ast = parser.parse();

      expect(ast.name, equals(expectedName));
      expect(errorReporter.hasErrors, isFalse);

      // Also test with the workspace mapper
      final mapper = WorkspaceMapper(source, errorReporter);
      final workspace = mapper.mapWorkspace(ast);

      expect(workspace, isNotNull);
      expect(workspace!.name, equals(expectedName));
    }

    test('handles workspace names with quotes', () {
      testWorkspaceName(
          'workspace "System with \\"quotes\\"" { }', 'System with "quotes"');
    });

    test('handles workspace names with escaped characters', () {
      testWorkspaceName('workspace "System with \\n newlines and \\t tabs" { }',
          'System with \n newlines and \t tabs');
    });

    test('handles workspace names with single quotes', () {
      testWorkspaceName("workspace 'System with single quotes' { }",
          'System with single quotes');
    });

    test('handles workspace names with mixed quotes', () {
      testWorkspaceName("workspace 'System with \"double quotes\" inside' { }",
          'System with "double quotes" inside');
    });

    test('handles workspace names with special characters', () {
      testWorkspaceName('workspace "System with special chars: @#&*()" { }',
          'System with special chars: @#&*()');
    });

    test('handles workspace names with Unicode characters', () {
      testWorkspaceName('workspace "System with Unicode: 你好世界" { }',
          'System with Unicode: 你好世界');
    });

    test('handles workspace names with Unicode escape sequences', () {
      testWorkspaceName(
          'workspace "System with Unicode escapes: \\u0068\\u0069" { }',
          'System with Unicode escapes: hi');
    });

    test('allows using identifiers as workspace names', () {
      const source = 'workspace SystemName { }';
      final parser = Parser(source);
      final ast = parser.parse();

      // The error reporter should have a warning
      expect(parser.errorReporter.hasWarnings, isTrue);
      expect(ast.name, equals('SystemName'));
    });

    test('empty workspace name returns empty string', () {
      testWorkspaceName('workspace "" { }', '');
    });

    test('multi-line workspace name', () {
      testWorkspaceName('workspace "System with\nmultiple\nlines" { }',
          'System with\nmultiple\nlines');
    });

    test('very long workspace name', () {
      final longName = 'A' * 1000;
      testWorkspaceName('workspace "$longName" { }', longName);
    });

    test('workspace name with only spaces', () {
      testWorkspaceName('workspace "   " { }', '   ');
    });
  });
}
