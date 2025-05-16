import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/relationship_finder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RelationshipFinder', () {
    test('should find all relationships in a model', () {
      // Setup elements with relationships
      final person = Person.create(name: 'User');
      final system1 = SoftwareSystem.create(name: 'System 1');
      final system2 = SoftwareSystem.create(name: 'System 2');
      
      // Add relationships
      final personWithRelationship = person.addRelationship(
        destinationId: system1.id,
        description: 'Uses',
        tags: ['tag1'],
      );
      
      final system1WithRelationship = system1.addRelationship(
        destinationId: system2.id,
        description: 'Sends data to',
        tags: ['tag2'],
      );
      
      // Create a model with these elements
      final model = Model(
        people: [personWithRelationship],
        softwareSystems: [system1WithRelationship, system2],
      );
      
      // Create a relationship finder
      final finder = RelationshipFinder(model);
      
      // Find all relationships
      final relationships = finder.findAllRelationships();
      
      // Verify all relationships are found
      expect(relationships.length, equals(2));
      expect(
        relationships.any((r) => 
          r.sourceId == personWithRelationship.id && 
          r.destinationId == system1.id
        ), 
        isTrue
      );
      expect(
        relationships.any((r) => 
          r.sourceId == system1.id && 
          r.destinationId == system2.id
        ), 
        isTrue
      );
    });
    
    test('should find relationships involving an element', () {
      // Setup elements with relationships
      final person = Person.create(name: 'User');
      final system1 = SoftwareSystem.create(name: 'System 1');
      final system2 = SoftwareSystem.create(name: 'System 2');
      
      // Add relationships
      final personWithRelationship = person.addRelationship(
        destinationId: system1.id,
        description: 'Uses',
      );
      
      final system1WithRelationship = system1.addRelationship(
        destinationId: system2.id,
        description: 'Sends data to',
      );
      
      // Create a model with these elements
      final model = Model(
        people: [personWithRelationship],
        softwareSystems: [system1WithRelationship, system2],
      );
      
      // Create a relationship finder
      final finder = RelationshipFinder(model);
      
      // Find relationships involving system1
      final system1Element = model.getSoftwareSystemById(system1WithRelationship.id)!;
      final relationships = finder.findRelationshipsInvolving(system1Element);
      
      // Verify all relationships are found (both incoming and outgoing)
      expect(relationships.length, equals(2));
      expect(
        relationships.any((r) => 
          r.sourceId == personWithRelationship.id && 
          r.destinationId == system1.id
        ), 
        isTrue
      );
      expect(
        relationships.any((r) => 
          r.sourceId == system1.id && 
          r.destinationId == system2.id
        ), 
        isTrue
      );
    });
    
    test('should find relationships with a specific tag', () {
      // Setup elements with relationships
      final person = Person.create(name: 'User');
      final system1 = SoftwareSystem.create(name: 'System 1');
      final system2 = SoftwareSystem.create(name: 'System 2');
      
      // Add relationships
      final personWithRelationship = person.addRelationship(
        destinationId: system1.id,
        description: 'Uses',
        tags: ['important'],
      );
      
      final system1WithRelationship = system1.addRelationship(
        destinationId: system2.id,
        description: 'Sends data to',
        tags: ['async', 'important'],
      );
      
      // Create a model with these elements
      final model = Model(
        people: [personWithRelationship],
        softwareSystems: [system1WithRelationship, system2],
      );
      
      // Create a relationship finder
      final finder = RelationshipFinder(model);
      
      // Find relationships with the 'important' tag
      final importantRelationships = finder.findRelationshipsByTag('important');
      
      // Verify all 'important' relationships are found
      expect(importantRelationships.length, equals(2));
      
      // Find relationships with the 'async' tag
      final asyncRelationships = finder.findRelationshipsByTag('async');
      
      // Verify only the 'async' relationship is found
      expect(asyncRelationships.length, equals(1));
      expect(asyncRelationships.first.sourceId, equals(system1.id));
      expect(asyncRelationships.first.destinationId, equals(system2.id));
    });
  });
}