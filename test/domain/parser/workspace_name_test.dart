import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/parser/parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Workspace Name Parsing', () {
    test('parses basic workspace name', () {
      // Arrange
      final source = 'workspace "Basic Name" { }';
      final errorReporter = ErrorReporter(source);
      final parser = Parser(source);
      
      // Act
      final ast = parser.parse();
      
      // Assert
      expect(errorReporter.hasErrors, isFalse);
      expect(ast, isNotNull);
      expect(ast.name, equals('Basic Name'));
    });
    
    test('parses workspace name with description', () {
      // Arrange
      final source = 'workspace "Banking System" "This is a description" { }';
      final errorReporter = ErrorReporter(source);
      final parser = Parser(source);
      
      // Act
      final ast = parser.parse();
      
      // Assert
      expect(errorReporter.hasErrors, isFalse);
      expect(ast, isNotNull);
      expect(ast.name, equals('Banking System'));
      expect(ast.description, equals('This is a description'));
    });
  });
}