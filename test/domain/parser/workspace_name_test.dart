import 'package:flutter_structurizr/domain/parser/parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Workspace Name Parsing', () {
    test('parses basic workspace name', () {
      // Arrange
      const source = 'workspace "Basic Name" { }';
      final parser = Parser(source);

      // Act
      final ast = parser.parse();

      // Assert
      expect(ast, isNotNull);
      expect(ast.name, equals('Basic Name'));
    });

    test('parses workspace name with description', () {
      // Arrange
      const source = 'workspace "Banking System" "This is a description" { }';
      final parser = Parser(source);

      // Act
      final ast = parser.parse();

      // Assert
      expect(ast, isNotNull);
      expect(ast.name, equals('Banking System'));
      expect(ast.description, equals('This is a description'));
    });
  });
}
