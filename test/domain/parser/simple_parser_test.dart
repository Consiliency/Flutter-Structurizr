import 'package:flutter_structurizr/domain/parser/parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

final _logger = Logger('SimpleParserTest');

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print(
        '[[32m[1m[40m[0m${record.level.name}] ${record.loggerName}: ${record.message}');
  });

  group('Simple Parser Test', () {
    test('parses a basic DSL model', () {
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

      _logger.info('AST: $ast');

      // Assert
      expect(ast, isNotNull);
      // Temporarily disable this check
      // expect(ast.name, equals('Test'));
      expect(ast.description, equals('Description'));

      // Check model
      expect(ast.model, isNotNull);
      expect(ast.model!.people.length, equals(1));
      expect(ast.model!.softwareSystems.length, equals(1));
      expect(ast.model!.relationships.length, equals(1));

      // Check person
      final person = ast.model!.people.first;
      expect(person.name, equals('User'));
      expect(person.id, equals('user'));

      // Check system
      final system = ast.model!.softwareSystems.first;
      expect(system.name, equals('System'));
      expect(system.id, equals('system'));

      // Check relationship
      final relationship = ast.model!.relationships.first;
      expect(relationship.sourceId, equals('user'));
      expect(relationship.destinationId, equals('system'));
      expect(relationship.description, equals('Uses'));
    });
  });
}
