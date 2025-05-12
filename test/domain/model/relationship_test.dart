import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('Relationship tests', () {
    late Relationship relationship;
    final relationshipId = 'rel-1';
    final sourceId = 'source-1';
    final destinationId = 'destination-1';
    final description = 'Uses';
    final technology = 'REST';
    
    setUp(() {
      relationship = Relationship(
        id: relationshipId,
        sourceId: sourceId,
        destinationId: destinationId,
        description: description,
        technology: technology,
      );
    });
    
    test('Relationship creation with ID', () {
      expect(relationship.id, equals(relationshipId));
      expect(relationship.sourceId, equals(sourceId));
      expect(relationship.destinationId, equals(destinationId));
      expect(relationship.description, equals(description));
      expect(relationship.technology, equals(technology));
      expect(relationship.interactionStyle, equals('Synchronous')); // Default
      expect(relationship.tags, isEmpty);
      expect(relationship.properties, isEmpty);
    });
    
    test('Relationship with custom interaction style', () {
      final asyncRelationship = Relationship(
        id: relationshipId,
        sourceId: sourceId,
        destinationId: destinationId,
        description: description,
        interactionStyle: 'Asynchronous',
      );
      
      expect(asyncRelationship.interactionStyle, equals('Asynchronous'));
    });
    
    test('Relationship with tags', () {
      final taggedRelationship = Relationship(
        id: relationshipId,
        sourceId: sourceId,
        destinationId: destinationId,
        description: description,
        tags: ['Important', 'External'],
      );
      
      expect(taggedRelationship.tags, containsAll(['Important', 'External']));
      expect(taggedRelationship.tags.length, equals(2));
    });
    
    test('Relationship with properties', () {
      final relationshipWithProperties = Relationship(
        id: relationshipId,
        sourceId: sourceId,
        destinationId: destinationId,
        description: description,
        properties: {
          'protocol': 'HTTPS',
          'method': 'POST',
        },
      );
      
      expect(relationshipWithProperties.properties['protocol'], equals('HTTPS'));
      expect(relationshipWithProperties.properties['method'], equals('POST'));
      expect(relationshipWithProperties.properties.length, equals(2));
    });
    
    test('Relationship serialization to JSON', () {
      final json = relationship.toJson();
      
      expect(json['id'], equals(relationshipId));
      expect(json['sourceId'], equals(sourceId));
      expect(json['destinationId'], equals(destinationId));
      expect(json['description'], equals(description));
      expect(json['technology'], equals(technology));
      expect(json['interactionStyle'], equals('Synchronous'));
    });
    
    test('Relationship deserialization from JSON', () {
      final json = {
        'id': relationshipId,
        'sourceId': sourceId,
        'destinationId': destinationId,
        'description': description,
        'technology': technology,
        'interactionStyle': 'Asynchronous',
        'tags': ['External', 'Important'],
        'properties': {'protocol': 'HTTPS'},
      };
      
      final deserialized = Relationship.fromJson(json);
      
      expect(deserialized.id, equals(relationshipId));
      expect(deserialized.sourceId, equals(sourceId));
      expect(deserialized.destinationId, equals(destinationId));
      expect(deserialized.description, equals(description));
      expect(deserialized.technology, equals(technology));
      expect(deserialized.interactionStyle, equals('Asynchronous'));
      expect(deserialized.tags, containsAll(['External', 'Important']));
      expect(deserialized.properties['protocol'], equals('HTTPS'));
    });
    
    test('Element.addRelationship() creates valid relationship', () {
      final source = BasicElement(id: sourceId, name: 'Source', type: 'SoftwareSystem');

      final updatedSource = source.addRelationship(
        destinationId: destinationId,
        description: description,
        technology: technology,
        tags: ['Important'],
        properties: {'protocol': 'HTTPS'},
      );
      
      expect(updatedSource.relationships.length, equals(1));
      
      final relationship = updatedSource.relationships.first;
      expect(relationship.sourceId, equals(sourceId));
      expect(relationship.destinationId, equals(destinationId));
      expect(relationship.description, equals(description));
      expect(relationship.technology, equals(technology));
      expect(relationship.tags, contains('Important'));
      expect(relationship.properties['protocol'], equals('HTTPS'));
      
      // Relationship should have auto-generated ID
      expect(relationship.id, isNotNull);
      expect(relationship.id.length, greaterThan(0));
    });
    
    test('Element.getRelationshipById() retrieves the correct relationship', () {
      final source = BasicElement(
        id: sourceId,
        name: 'Source',
        type: 'SoftwareSystem',
        relationships: [relationship],
      );
      
      final retrievedRelationship = source.getRelationshipById(relationshipId);
      
      expect(retrievedRelationship, isNotNull);
      expect(retrievedRelationship?.id, equals(relationshipId));
      expect(retrievedRelationship?.description, equals(description));
    });
    
    test('Element.getRelationshipById() throws when not found', () {
      final source = BasicElement(
        id: sourceId,
        name: 'Source',
        type: 'SoftwareSystem',
        relationships: [relationship],
      );
      
      expect(
        () => source.getRelationshipById('non-existent'),
        throwsA(isA<RelationshipNotFoundException>()),
      );
    });
    
    test('Element.getRelationshipsTo() returns relationships to a destination', () {
      final otherDestinationId = 'destination-2';
      
      final relationship1 = Relationship(
        id: 'rel-1',
        sourceId: sourceId,
        destinationId: destinationId,
        description: 'Uses',
      );
      
      final relationship2 = Relationship(
        id: 'rel-2',
        sourceId: sourceId,
        destinationId: destinationId,
        description: 'Depends on',
      );
      
      final relationship3 = Relationship(
        id: 'rel-3',
        sourceId: sourceId,
        destinationId: otherDestinationId,
        description: 'Sends data to',
      );
      
      final source = BasicElement(
        id: sourceId,
        name: 'Source',
        type: 'SoftwareSystem',
        relationships: [relationship1, relationship2, relationship3],
      );
      
      final relationshipsToDestination = source.getRelationshipsTo(destinationId);
      
      expect(relationshipsToDestination.length, equals(2));
      expect(relationshipsToDestination.map((r) => r.id), containsAll(['rel-1', 'rel-2']));
      
      // Verify other destination has one relationship
      expect(source.getRelationshipsTo(otherDestinationId).length, equals(1));
      expect(source.getRelationshipsTo(otherDestinationId).first.id, equals('rel-3'));
    });
    
    test('Relationship validation in Model', () {
      // Create model with elements and valid relationship
      final sourceElement = Person(id: sourceId, name: 'Person');
      final targetElement = SoftwareSystem(id: destinationId, name: 'System');
      
      final sourceWithRelationship = sourceElement.addRelationship(
        destinationId: destinationId,
        description: 'Uses',
      );
      
      final model = Model(
        people: [sourceWithRelationship],
        softwareSystems: [targetElement],
      );
      
      // Validation should pass
      expect(model.validate(), isEmpty);
      
      // Now create a model with invalid relationship (non-existent target)
      final sourceWithInvalidRelationship = sourceElement.addRelationship(
        destinationId: 'non-existent',
        description: 'Uses',
      );
      
      final invalidModel = Model(
        people: [sourceWithInvalidRelationship],
        softwareSystems: [targetElement],
      );
      
      // Validation should fail with appropriate message
      final validationErrors = invalidModel.validate();
      expect(validationErrors, isNotEmpty);
      expect(
        validationErrors.any((e) => e.contains('non-existent')), 
        isTrue,
        reason: 'Validation should detect missing destination element',
      );
    });
    
    test('Bidirectional relationships', () {
      // Create elements
      final person = Person(id: 'person-1', name: 'User');
      final system = SoftwareSystem(id: 'system-1', name: 'System');
      
      // Add relationships in both directions
      final personWithRelationship = person.addRelationship(
        destinationId: system.id,
        description: 'Uses',
      );
      
      final systemWithRelationship = system.addRelationship(
        destinationId: person.id,
        description: 'Provides data to',
      );
      
      // Create model with both elements
      final model = Model(
        people: [personWithRelationship],
        softwareSystems: [systemWithRelationship],
      );
      
      // Validation should pass
      expect(model.validate(), isEmpty);
      
      // Check relationships are maintained
      final allRelationships = model.getAllRelationships();
      expect(allRelationships.length, equals(2));
      
      // Verify relationships go in both directions
      expect(
        allRelationships.any((r) => 
          r.sourceId == person.id && r.destinationId == system.id
        ),
        isTrue,
      );
      
      expect(
        allRelationships.any((r) => 
          r.sourceId == system.id && r.destinationId == person.id
        ),
        isTrue,
      );
    });
  });
}