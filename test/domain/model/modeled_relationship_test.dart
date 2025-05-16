import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/modeled_relationship.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ModeledRelationship', () {
    test('provides access to source and destination elements', () {
      // Create a model with sample elements
      final model = Model();
      
      // Add some elements
      final person = Person.create(
        name: 'User',
        description: 'A user of the system',
      );
      
      final system = SoftwareSystem.create(
        name: 'System',
        description: 'A software system',
      );
      
      // Add the elements to the model
      final updatedModel = model
          .addPerson(person)
          .addSoftwareSystem(system);
      
      // Create a relationship
      final personWithRelationship = person.addRelationship(
        destinationId: system.id,
        description: 'Uses',
      );
      
      // Update the model with the updated person
      final modelWithRelationship = updatedModel.copyWith(
        people: [personWithRelationship],
      );
      
      // Find the relationship
      final relationship = modelWithRelationship.findRelationshipBetween(
        person.id, 
        system.id,
      );
      
      // Verify relationship properties
      expect(relationship, isNotNull);
      expect(relationship?.sourceId, equals(person.id));
      expect(relationship?.destinationId, equals(system.id));
      expect(relationship?.description, equals('Uses'));
      
      // Verify source and destination access
      if (relationship != null) {
        expect(relationship.source, isA<Person>());
        expect(relationship.destination, isA<SoftwareSystem>());
        expect(relationship.source.name, equals('User'));
        expect(relationship.destination.name, equals('System'));
      }
    });
    
    test('model provides access to all elements and relationships', () {
      // Create a model with elements
      final model = Model();
      
      // Create elements
      final user = Person.create(
        name: 'User',
        description: 'A user of the system',
      );
      
      final system = SoftwareSystem.create(
        name: 'System',
        description: 'A software system',
      );
      
      // Add elements to model
      final updatedModel = model
          .addPerson(user)
          .addSoftwareSystem(system);
      
      // Create relationship
      final userWithRel = user.addRelationship(
        destinationId: system.id,
        description: 'Uses',
      );
      
      // Update model with relationship
      final modelWithRelationship = updatedModel.copyWith(
        people: [userWithRel],
      );
      
      // Verify elements and relationships access
      expect(modelWithRelationship.elements.length, equals(2));
      expect(modelWithRelationship.relationships.length, equals(1));
      
      // Check relationship details
      final relationship = modelWithRelationship.relationships.first;
      expect(relationship.sourceId, equals(user.id));
      expect(relationship.destinationId, equals(system.id));
      expect(relationship.description, equals('Uses'));
    });
  });
}
