import 'package:flutter_structurizr/domain/parser/parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Minimal Parser Tests', () {
    test('parser completes without errors', () {
      // Arrange
      const source = '''
        workspace "Test" "Description" {
          model {
            user = person "User"
            system = softwareSystem "System"
            
            user -> system "Uses"
          }
        }
      ''';

      final parser = Parser(source);

      // Act
      final ast = parser.parse();

      // Assert - just make sure we don't have errors
      expect(ast, isNotNull);
    });
  });
}
