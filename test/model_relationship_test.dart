import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print(
        '[\u001b[32m\u001b[1m\u001b[40m\u001b[0m${record.level.name}] ${record.loggerName}: ${record.message}');
  });

  group('Model Relationship Access', () {
    late Model model;

    setUp(() {
      model = const Model();
    });

    test('model provides access to all relationships', () {
      // Create a person
      final person = Person.create(
        name: 'User',
        description: 'A user of the system',
      );

      // Create a software system
      final system = SoftwareSystem.create(
        name: 'Test System',
        description: 'A test system',
      );

      // Add both to the model
      model = model.addPerson(person);
      model = model.addSoftwareSystem(system);

      // Add a relationship
      final personWithRelationship = person.addRelationship(
        destinationId: system.id,
        description: 'Uses',
      );

      // Update the person in the model
      model = model.copyWith(
        people: [personWithRelationship],
      );

      // Test that relationships are accessible through model.relationships
      expect(model.relationships, isNotNull);
      expect(model.relationships.length, equals(1));

      // Test that relationship has sourceId and destinationId
      final relationship = model.relationships.first;
      expect(relationship.sourceId, equals(person.id));
      expect(relationship.destinationId, equals(system.id));
      expect(relationship.description, equals('Uses'));

      // Test that we can find relationship using findRelationshipBetween
      final foundRelationship =
          model.findRelationshipBetween(person.id, system.id);
      expect(foundRelationship, isNotNull);
      expect(foundRelationship!.description, equals('Uses'));
    });

    test('ModeledRelationship provides access to source and destination', () {
      // Create a person
      final person = Person.create(
        name: 'User',
        description: 'A user of the system',
      );

      // Create a software system
      final system = SoftwareSystem.create(
        name: 'Test System',
        description: 'A test system',
      );

      // Add both to the model
      model = model.addPerson(person);
      model = model.addSoftwareSystem(system);

      // Add a relationship
      final personWithRelationship = person.addRelationship(
        destinationId: system.id,
        description: 'Uses',
      );

      // Update the person in the model
      model = model.copyWith(
        people: [personWithRelationship],
      );

      // Test that ModeledRelationship can access source and destination
      final foundRelationship =
          model.findRelationshipBetween(person.id, system.id);
      expect(foundRelationship, isNotNull);

      // Test source and destination access
      expect(foundRelationship?.source, isNotNull);
      expect(foundRelationship?.destination, isNotNull);
      expect(foundRelationship?.source.name, equals('User'));
      expect(foundRelationship?.destination.name, equals('Test System'));
    });
  });
}
