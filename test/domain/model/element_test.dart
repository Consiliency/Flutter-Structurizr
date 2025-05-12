import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/model/element.dart';

void main() {
  group('Element', () {
    test('creates an element with required properties', () {
      const element = BasicElement(
        id: 'test-id',
        name: 'Test Element',
        type: 'TestType',
      );

      expect(element.id, equals('test-id'));
      expect(element.name, equals('Test Element'));
      expect(element.type, equals('TestType'));
      expect(element.description, isNull);
      expect(element.tags, isEmpty);
      expect(element.properties, isEmpty);
      expect(element.relationships, isEmpty);
      expect(element.parentId, isNull);
    });

    test('creates an element with all properties', () {
      final element = BasicElement(
        id: 'test-id',
        name: 'Test Element',
        description: 'A test element',
        type: 'TestType',
        tags: ['tag1', 'tag2'],
        properties: {'key1': 'value1', 'key2': 'value2'},
        relationships: [
          const Relationship(
            id: 'rel-id',
            sourceId: 'test-id',
            destinationId: 'dest-id',
            description: 'Test relationship',
          ),
        ],
        parentId: 'parent-id',
      );

      expect(element.id, equals('test-id'));
      expect(element.name, equals('Test Element'));
      expect(element.description, equals('A test element'));
      expect(element.type, equals('TestType'));
      expect(element.tags, containsAll(['tag1', 'tag2']));
      expect(element.properties, containsPair('key1', 'value1'));
      expect(element.properties, containsPair('key2', 'value2'));
      expect(element.relationships, hasLength(1));
      expect(element.relationships[0].id, equals('rel-id'));
      expect(element.parentId, equals('parent-id'));
    });

    test('creates an element with generated ID', () {
      final element = BasicElement.create(
        name: 'Test Element',
        type: 'TestType',
      );

      expect(element.id, isNotNull);
      expect(element.id, isNotEmpty);
      expect(element.name, equals('Test Element'));
      expect(element.type, equals('TestType'));
    });

    test('adds a tag', () {
      const element = BasicElement(
        id: 'test-id',
        name: 'Test Element',
        type: 'TestType',
      );

      final updatedElement = element.addTag('new-tag');

      expect(updatedElement.tags, contains('new-tag'));
      expect(updatedElement.tags, hasLength(1));
    });

    test('adds multiple tags', () {
      const element = BasicElement(
        id: 'test-id',
        name: 'Test Element',
        type: 'TestType',
      );

      final updatedElement = element.addTags(['tag1', 'tag2']);

      expect(updatedElement.tags, containsAll(['tag1', 'tag2']));
      expect(updatedElement.tags, hasLength(2));
    });

    test('adds a property', () {
      const element = BasicElement(
        id: 'test-id',
        name: 'Test Element',
        type: 'TestType',
      );

      final updatedElement = element.addProperty('key', 'value');

      expect(updatedElement.properties, containsPair('key', 'value'));
      expect(updatedElement.properties, hasLength(1));
    });

    test('adds a relationship', () {
      const element = BasicElement(
        id: 'source-id',
        name: 'Source Element',
        type: 'TestType',
      );

      final updatedElement = element.addRelationship(
        destinationId: 'dest-id',
        description: 'Test relationship',
      );

      expect(updatedElement.relationships, hasLength(1));
      expect(updatedElement.relationships[0].sourceId, equals('source-id'));
      expect(updatedElement.relationships[0].destinationId, equals('dest-id'));
      expect(updatedElement.relationships[0].description, equals('Test relationship'));
    });

    test('gets relationships to a specific destination', () {
      const relationship1 = Relationship(
        id: 'rel1',
        sourceId: 'source-id',
        destinationId: 'dest1',
        description: 'Relationship 1',
      );

      const relationship2 = Relationship(
        id: 'rel2',
        sourceId: 'source-id',
        destinationId: 'dest2',
        description: 'Relationship 2',
      );

      const relationship3 = Relationship(
        id: 'rel3',
        sourceId: 'source-id',
        destinationId: 'dest1',
        description: 'Relationship 3',
      );

      const element = BasicElement(
        id: 'source-id',
        name: 'Source Element',
        type: 'TestType',
        relationships: [relationship1, relationship2, relationship3],
      );

      final relationships = element.getRelationshipsTo('dest1');

      expect(relationships, hasLength(2));
      expect(relationships[0].id, equals('rel1'));
      expect(relationships[1].id, equals('rel3'));
    });

    test('throws exception when relationship is not found', () {
      const element = BasicElement(
        id: 'source-id',
        name: 'Source Element',
        type: 'TestType',
      );

      expect(
        () => element.getRelationshipById('non-existent'),
        throwsA(isA<RelationshipNotFoundException>()),
      );
    });
  });

  group('Relationship', () {
    test('creates a relationship with required properties', () {
      const relationship = Relationship(
        id: 'rel-id',
        sourceId: 'source-id',
        destinationId: 'dest-id',
        description: 'Test relationship',
      );

      expect(relationship.id, equals('rel-id'));
      expect(relationship.sourceId, equals('source-id'));
      expect(relationship.destinationId, equals('dest-id'));
      expect(relationship.description, equals('Test relationship'));
      expect(relationship.technology, isNull);
      expect(relationship.tags, isEmpty);
      expect(relationship.properties, isEmpty);
      expect(relationship.interactionStyle, equals('Synchronous'));
    });

    test('creates a relationship with all properties', () {
      const relationship = Relationship(
        id: 'rel-id',
        sourceId: 'source-id',
        destinationId: 'dest-id',
        description: 'Test relationship',
        technology: 'HTTPS',
        tags: ['tag1', 'tag2'],
        properties: {'key1': 'value1', 'key2': 'value2'},
        interactionStyle: 'Asynchronous',
      );

      expect(relationship.id, equals('rel-id'));
      expect(relationship.sourceId, equals('source-id'));
      expect(relationship.destinationId, equals('dest-id'));
      expect(relationship.description, equals('Test relationship'));
      expect(relationship.technology, equals('HTTPS'));
      expect(relationship.tags, containsAll(['tag1', 'tag2']));
      expect(relationship.properties, containsPair('key1', 'value1'));
      expect(relationship.properties, containsPair('key2', 'value2'));
      expect(relationship.interactionStyle, equals('Asynchronous'));
    });
  });
}