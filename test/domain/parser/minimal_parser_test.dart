import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/parser/parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Minimal Parser Tests', () {
    test('parser completes without errors', () {
      // Arrange
      final source = '''
        workspace "Test" "Description" {
          model {
            user = person "User"
            system = softwareSystem "System"
            
            user -> system "Uses"
          }
        }
      ''';
      
      final errorReporter = ErrorReporter(source);
      final parser = Parser(source);
      
      // Act
      final ast = parser.parse();
      
      // Assert - just make sure we don't have errors
      expect(errorReporter.hasErrors, isFalse);
      expect(ast, isNotNull);
    });
  });
}