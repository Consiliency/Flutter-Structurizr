import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/modeled_relationship.dart';

void main() {
  group('Model Relationship Handling', () {
    late Model model;
    late Person person1;
    late Person person2;
    late SoftwareSystem system1;
    late SoftwareSystem system2;
    late Container container1;

    setUp(() {
      // Create test elements
      person1 = Person.create(name: 'User');
      person2 = Person.create(name: 'Admin');
      system1 = SoftwareSystem.create(name: 'System 1');
      system2 = SoftwareSystem.create(name: 'System 2');
      container1 = Container.create(
        name: 'Container 1',
        parentId: system1.id,
      );

      // Add relationships between elements
      final person1WithRel = person1.addRelationship(
        destinationId: system1.id,
        description: 'Uses',
        technology: 'HTTPS',
      );

      final system1WithContainer = system1.copyWith(containers: [container1]);

      final system1WithRel = system1WithContainer.addRelationship(
        destinationId: system2.id,
        description: 'Sends data to',
        technology: 'REST API',
      );

      final system2WithRel = system2.addRelationship(
        destinationId: person2.id,
        description: 'Notifies',
        technology: 'Email',
      );

      // Create the model with these elements
      model = Model(
        people: [person1WithRel, person2],
        softwareSystems: [system1WithRel, system2WithRel],
      );
    });

    test('model.relationships returns all relationships from elements', () {
      // Get all relationships from the model
      final relationships = model.relationships;

      // We should have 3 relationships in total
      expect(relationships.length, equals(3));

      // Check if each relationship has the expected properties
      expect(
        relationships.any((r) =>
            r.sourceId == person1.id &&
            r.destinationId == system1.id &&
            r.description == 'Uses' &&
            r.technology == 'HTTPS'),
        isTrue,
      );

      expect(
        relationships.any((r) =>
            r.sourceId == system1.id &&
            r.destinationId == system2.id &&
            r.description == 'Sends data to' &&
            r.technology == 'REST API'),
        isTrue,
      );

      expect(
        relationships.any((r) =>
            r.sourceId == system2.id &&
            r.destinationId == person2.id &&
            r.description == 'Notifies' &&
            r.technology == 'Email'),
        isTrue,
      );
    });

    test('can access sourceId and destinationId from relationships', () {
      final relationships = model.relationships;

      for (final relationship in relationships) {
        // Verify that sourceId and destinationId are accessible
        expect(relationship.sourceId, isNotEmpty);
        expect(relationship.destinationId, isNotEmpty);

        // Verify that the source and destination elements exist in the model
        final sourceElement = model.getElementById(relationship.sourceId);
        final destinationElement =
            model.getElementById(relationship.destinationId);

        expect(sourceElement, isNotNull);
        expect(destinationElement, isNotNull);
      }
    });

    test(
        'ModeledRelationship provides direct access to source and destination elements',
        () {
      final relationships = model.relationships;

      for (final relationship in relationships) {
        // Convert to ModeledRelationship
        final modeledRelationship =
            ModeledRelationship.fromRelationship(relationship, model);

        // Verify that source and destination can be accessed directly
        expect(modeledRelationship.source, isNotNull);
        expect(modeledRelationship.destination, isNotNull);
        expect(modeledRelationship.source.id, equals(relationship.sourceId));
        expect(modeledRelationship.destination.id,
            equals(relationship.destinationId));
      }
    });

    test('adds new relationships to the model correctly', () {
      // Original relationship count
      final originalCount = model.relationships.length;

      // Add a new relationship from container to person2
      final updatedContainer = container1.addRelationship(
        destinationId: person2.id,
        description: 'Authenticates',
        technology: 'OAuth',
      );

      // Update the container in the model
      // First get the existing system
      final existingSystem =
          model.softwareSystems.firstWhere((s) => s.id == system1.id);

      // Update the container within the system
      final updatedContainers = [updatedContainer];
      final updatedSystem =
          existingSystem.copyWith(containers: updatedContainers);

      // Update the system in the model
      final updatedSystems = model.softwareSystems
          .map((s) => s.id == system1.id ? updatedSystem : s)
          .toList();

      final updatedModel = model.copyWith(softwareSystems: updatedSystems);

      // Verify the new relationship exists
      final newRelationships = updatedModel.relationships;
      expect(newRelationships.length, equals(originalCount + 1));

      // Verify the new relationship has the expected properties
      expect(
        newRelationships.any((r) =>
            r.sourceId == container1.id &&
            r.destinationId == person2.id &&
            r.description == 'Authenticates' &&
            r.technology == 'OAuth'),
        isTrue,
      );
    });

    test('model.validate() verifies relationships reference valid elements',
        () {
      // Create an invalid relationship to a non-existent element
      final personWithInvalidRel = person1.addRelationship(
        destinationId: 'non-existent-id',
        description: 'Invalid relationship',
      );

      // Update the model with the invalid relationship
      final invalidModel = model.copyWith(
        people: [personWithInvalidRel, person2],
      );

      // Validate the model
      final validationErrors = invalidModel.validate();

      // There should be validation errors
      expect(validationErrors, isNotEmpty);
      expect(
        validationErrors.any((e) =>
            e.contains('non-existent destination') &&
            e.contains('non-existent-id')),
        isTrue,
      );

      // Original model should still be valid
      expect(model.validate(), isEmpty);
    });

    test('can find relationships between elements', () {
      // Find relationship between person1 and system1
      final relationship =
          model.findRelationshipBetween(person1.id, system1.id);

      expect(relationship, isNotNull);
      expect(relationship!.sourceId, equals(person1.id));
      expect(relationship.destinationId, equals(system1.id));
      expect(relationship.description, equals('Uses'));

      // Find relationship with specific description
      final specificRel = model.findRelationshipBetween(
          system1.id, system2.id, 'Sends data to');

      expect(specificRel, isNotNull);
      expect(specificRel!.technology, equals('REST API'));

      // Non-existent relationship
      final nonExistentRel =
          model.findRelationshipBetween(person1.id, person2.id);
      expect(nonExistentRel, isNull);
    });
  });
}
