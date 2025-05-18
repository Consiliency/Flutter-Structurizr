import 'package:flutter_structurizr/application/dsl/workspace_mapper.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/parser/parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Minimal Integration Test', () {
    test('parser and mapper complete without errors', () {
      // Arrange
      const source = '''
        workspace "Test" {
          model {
          }
        }
      ''';

      final errorReporter = ErrorReporter(source);
      final parser = Parser(source);
      final mapper = WorkspaceMapper(source, errorReporter);

      // Act
      final ast = parser.parse();
      final workspace = mapper.mapWorkspace(ast);

      // Assert - just check for completion without errors
      expect(errorReporter.hasErrors, isFalse);
      expect(ast, isNotNull);
      expect(workspace, isNotNull);
    });
  });
}
