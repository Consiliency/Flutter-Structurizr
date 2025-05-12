import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';
import 'package:flutter_structurizr/infrastructure/serialization/json_serialization.dart';

void main() {
  group('JsonSerialization', () {
    test('converts workspace to and from JSON', () {
      final model = Model(
        people: [
          Person.create(
            name: 'User',
            description: 'A user of the system',
          ),
        ],
        softwareSystems: [
          SoftwareSystem.create(
            name: 'System',
            description: 'A software system',
          ),
        ],
      );
      
      final workspace = Workspace(
        id: 1,
        name: 'Test Workspace',
        description: 'A test workspace',
        model: model,
      );
      
      // Convert to JSON string
      final jsonString = JsonSerialization.workspaceToJson(workspace);
      
      // Verify it's valid JSON
      expect(() => jsonDecode(jsonString), returnsNormally);
      
      // Convert back to workspace
      final parsedWorkspace = JsonSerialization.workspaceFromJson(jsonString);
      
      // Verify properties
      expect(parsedWorkspace.id, equals(workspace.id));
      expect(parsedWorkspace.name, equals(workspace.name));
      expect(parsedWorkspace.description, equals(workspace.description));
      expect(parsedWorkspace.model.people.length, equals(workspace.model.people.length));
      expect(parsedWorkspace.model.softwareSystems.length, equals(workspace.model.softwareSystems.length));
    });
    
    test('converts model to and from JSON', () {
      final model = Model(
        enterpriseName: 'Test Enterprise',
        people: [
          Person.create(name: 'User'),
        ],
        softwareSystems: [
          SoftwareSystem.create(name: 'System'),
        ],
      );
      
      // Convert to JSON string
      final jsonString = JsonSerialization.modelToJson(model);
      
      // Verify it's valid JSON
      expect(() => jsonDecode(jsonString), returnsNormally);
      
      // Convert back to model
      final parsedModel = JsonSerialization.modelFromJson(jsonString);
      
      // Verify properties
      expect(parsedModel.enterpriseName, equals(model.enterpriseName));
      expect(parsedModel.people.length, equals(model.people.length));
      expect(parsedModel.softwareSystems.length, equals(model.softwareSystems.length));
    });
    
    test('converts person element to and from JSON', () {
      final person = Person.create(
        name: 'User',
        description: 'A user of the system',
        location: 'External',
      );
      
      // Convert to JSON string
      final jsonString = JsonSerialization.elementToJson(person);
      
      // Verify it's valid JSON
      expect(() => jsonDecode(jsonString), returnsNormally);
      
      // Convert back to element
      final parsedElement = JsonSerialization.elementFromJson(jsonString) as Person;
      
      // Verify properties
      expect(parsedElement.name, equals(person.name));
      expect(parsedElement.description, equals(person.description));
      expect(parsedElement.location, equals(person.location));
    });
    
    test('converts software system element to and from JSON', () {
      final container = Container.create(
        name: 'Container',
        parentId: 'system-id',
        technology: 'Java',
      );
      
      final system = SoftwareSystem.create(
        name: 'System',
        description: 'A software system',
        containers: [container],
      );
      
      // Convert to JSON string
      final jsonString = JsonSerialization.elementToJson(system);
      
      // Verify it's valid JSON
      expect(() => jsonDecode(jsonString), returnsNormally);
      
      // Convert back to element
      final parsedElement = JsonSerialization.elementFromJson(jsonString) as SoftwareSystem;
      
      // Verify properties
      expect(parsedElement.name, equals(system.name));
      expect(parsedElement.description, equals(system.description));
      expect(parsedElement.containers.length, equals(system.containers.length));
      expect(parsedElement.containers[0].name, equals(container.name));
      expect(parsedElement.containers[0].technology, equals(container.technology));
    });
    
    test('converts styles to and from JSON', () {
      final styles = Styles(
        elements: [
          ElementStyle(
            tag: 'Person',
            shape: Shape.person,
          ),
        ],
        relationships: [
          const RelationshipStyle(
            tag: 'Relationship',
            thickness: 2,
          ),
        ],
        themes: ['default'],
      );
      
      // Convert to JSON string
      final jsonString = JsonSerialization.stylesToJson(styles);
      
      // Verify it's valid JSON
      expect(() => jsonDecode(jsonString), returnsNormally);
      
      // Convert back to styles
      final parsedStyles = JsonSerialization.stylesFromJson(jsonString);
      
      // Verify properties
      expect(parsedStyles.elements.length, equals(styles.elements.length));
      expect(parsedStyles.elements[0].tag, equals(styles.elements[0].tag));
      expect(parsedStyles.elements[0].shape, equals(styles.elements[0].shape));
      expect(parsedStyles.relationships.length, equals(styles.relationships.length));
      expect(parsedStyles.relationships[0].tag, equals(styles.relationships[0].tag));
      expect(parsedStyles.relationships[0].thickness, equals(styles.relationships[0].thickness));
      expect(parsedStyles.themes.length, equals(styles.themes.length));
      expect(parsedStyles.themes[0], equals(styles.themes[0]));
    });
    
    test('validates workspace JSON', () {
      final model = Model();
      
      final workspace = Workspace(
        id: 1,
        name: 'Test Workspace',
        model: model,
      );
      
      final jsonString = JsonSerialization.workspaceToJson(workspace);
      
      // Valid JSON
      expect(JsonSerialization.validateWorkspaceJson(jsonString), isTrue);
      
      // Invalid JSON: missing required field
      final invalidJson = jsonEncode({
        'id': 1,
        // Missing 'name'
        'model': {},
      });
      
      expect(JsonSerialization.validateWorkspaceJson(invalidJson), isFalse);
    });
    
    test('throws JsonParsingException on invalid JSON', () {
      const invalidJson = '{not valid json}';
      
      expect(
        () => JsonSerialization.workspaceFromJson(invalidJson),
        throwsA(isA<JsonParsingException>()),
      );
    });
    
    test('parses list of elements correctly', () {
      final json = {
        'people': [
          {
            'id': '1',
            'name': 'User 1',
            'type': 'Person',
          },
          {
            'id': '2',
            'name': 'User 2',
            'type': 'Person',
          },
        ],
      };
      
      final people = JsonSerialization.parseList<Person>(
        json,
        'people',
        Person.fromJson,
      );
      
      expect(people.length, equals(2));
      expect(people[0].id, equals('1'));
      expect(people[0].name, equals('User 1'));
      expect(people[1].id, equals('2'));
      expect(people[1].name, equals('User 2'));
    });
    
    test('returns empty list when key is not found', () {
      final json = {'otherKey': []};
      
      final people = JsonSerialization.parseList<Person>(
        json,
        'people',
        Person.fromJson,
      );
      
      expect(people, isEmpty);
    });
  });
}