import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';
import 'package:flutter_structurizr/domain/view/model_view.dart';
import 'package:flutter_structurizr/domain/view/views.dart';
import 'package:flutter_structurizr/domain/view/view.dart' hide View;
import 'package:flutter_structurizr/infrastructure/serialization/json_serialization.dart';
import 'package:flutter_structurizr/infrastructure/serialization/json_serialization_helper.dart';

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
    
    test('validates workspace JSON with detailed errors', () {
      final model = Model();

      // Create a workspace with a view to pass validation
      final workspace = Workspace(
        id: 1,
        name: 'Test Workspace',
        model: model,
        views: Views(systemContextViews: [SystemContextView(key: 'test', softwareSystemId: 'system1')]),
      );

      final jsonString = JsonSerialization.workspaceToJson(workspace);

      // Valid JSON
      final validErrors = JsonSerialization.validateWorkspaceJson(jsonString);
      expect(validErrors, isEmpty);

      // Invalid JSON: missing required field
      final invalidJson = jsonEncode({
        'id': 1,
        // Missing 'name'
        'model': {},
      });

      final invalidErrors = JsonSerialization.validateWorkspaceJson(invalidJson);
      expect(invalidErrors, isNotEmpty);
      expect(invalidErrors, contains('Missing required field: name'));
    });

    test('pretty print workspace JSON', () {
      final workspace = Workspace(
        id: 1,
        name: 'Test Workspace',
        model: Model(),
      );

      final prettyJson = JsonSerialization.workspaceToPrettyJson(workspace);
      expect(prettyJson, contains('  "id": 1'));
      expect(prettyJson, contains('  "name": "Test Workspace"'));
      expect(prettyJson, contains('  "model": {'));
    });

    test('extract workspace name from JSON', () {
      final json = '''{
        "id": 1,
        "name": "Extracted Name",
        "model": {}
      }''';

      final name = JsonSerialization.extractWorkspaceName(json);
      expect(name, equals('Extracted Name'));
    });

    test('isValidWorkspaceJson convenience method', () {
      // Include systemContextViews to pass validation
      final validJson = '{"id": 1, "name": "Test Workspace", "model": {}, "views": {"systemContextViews": [{"key": "test", "softwareSystemId": "system1"}]}}';
      final invalidJson = '{"id": 1, "model": {}}';

      expect(JsonSerialization.isValidWorkspaceJson(validJson), isTrue);
      expect(JsonSerialization.isValidWorkspaceJson(invalidJson), isFalse);
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

  group('JsonSerializationHelper', () {
    test('workspaceToJson and workspaceFromJson', () {
      final workspace = Workspace(
        id: 1,
        name: 'Test Workspace',
        model: Model(),
      );

      final json = JsonSerializationHelper.workspaceToJson(workspace);
      expect(json, isNotEmpty);

      final deserializedWorkspace = JsonSerializationHelper.workspaceFromJson(json);
      expect(deserializedWorkspace.id, equals(workspace.id));
      expect(deserializedWorkspace.name, equals(workspace.name));
    });

    test('prettyPrintWorkspace formats JSON nicely', () {
      final workspace = Workspace(
        id: 1,
        name: 'Test Workspace',
        model: Model(),
      );

      final prettyJson = JsonSerializationHelper.prettyPrintWorkspace(workspace);
      expect(prettyJson, contains('  "id": 1'));
      expect(prettyJson, contains('  "name": "Test Workspace"'));
      expect(prettyJson.split('\n').length, greaterThan(5)); // Should be multi-line
    });

    test('elementsToJson converts elements to JSON', () {
      final elements = [
        Person(id: 'person1', name: 'User'),
        SoftwareSystem(id: 'system1', name: 'System'),
      ];

      final json = JsonSerializationHelper.elementsToJson(elements);
      expect(json, isNotEmpty);

      final decodedJson = jsonDecode(json) as List;
      expect(decodedJson.length, equals(2));
      expect(decodedJson[0]['id'], equals('person1'));
      expect(decodedJson[1]['id'], equals('system1'));
    });

    // Temporarily commented out due to View type conflicts
    /*test('viewsToJson converts views to JSON', () {
      // This test will be uncommented when View type conflicts are resolved
    });*/

    test('validateJson validates JSON structure', () {
      final validJson = '{"id": 1, "name": "Test", "model": {}}';
      final invalidJson = '{"id": 1}'; // Missing name

      final validErrors = JsonSerializationHelper.validateJson(validJson);
      expect(validErrors, isEmpty);

      final invalidErrors = JsonSerializationHelper.validateJson(invalidJson);
      expect(invalidErrors, isNotEmpty);
      expect(invalidErrors, contains('Missing required field "name"'));
    });

    test('jsonToMap converts JSON to map safely', () {
      final validJson = '{"id": 1, "name": "Test"}';
      final invalidJson = '{not valid json}';

      final validMap = JsonSerializationHelper.jsonToMap(validJson);
      expect(validMap, isNotNull);
      expect(validMap?['id'], equals(1));
      expect(validMap?['name'], equals('Test'));

      final invalidMap = JsonSerializationHelper.jsonToMap(invalidJson);
      expect(invalidMap, isNull);
    });
  });
}