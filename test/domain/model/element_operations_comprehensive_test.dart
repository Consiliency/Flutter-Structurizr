import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/relationship.dart';
import 'package:flutter_structurizr/domain/model/container.dart';
import 'package:flutter_structurizr/domain/model/component.dart';

void main() {
  group('Element operations comprehensive tests', () {
    group('Element.addChild method', () {
      test('SoftwareSystem adds Container child', () {
        final system = SoftwareSystem.create(name: 'System');
        final container = Container.create(
          name: 'Container',
          parentId: system.id,
        );

        final updatedSystem = system.addChild(container);

        expect(updatedSystem.containers, contains(container));
      });

      test('Container adds Component child', () {
        final container = Container.create(name: 'Container');
        final component = Component.create(
          name: 'Component',
          parentId: container.id,
        );

        final updatedContainer = container.addChild(component);

        expect(updatedContainer.components, contains(component));
      });

      test('adding multiple children to parent', () {
        final system = SoftwareSystem.create(name: 'System');
        final container1 = Container.create(
          name: 'Container 1',
          parentId: system.id,
        );
        final container2 = Container.create(
          name: 'Container 2',
          parentId: system.id,
        );

        final updatedSystem = system.addChild(container1).addChild(container2);

        expect(updatedSystem.containers.length, equals(2));
        expect(updatedSystem.containers, contains(container1));
        expect(updatedSystem.containers, contains(container2));
      });

      test('child with different type is ignored', () {
        final system = SoftwareSystem.create(name: 'System');
        // Component is not a valid direct child of SoftwareSystem
        final component = Component.create(name: 'Component');

        try {
          final updatedSystem = system.addChild(component);

          // If implemented to silently ignore invalid children:
          expect(updatedSystem.containers, isEmpty);
        } catch (e) {
          // If implemented to throw on invalid children:
          expect(e, isA<Error>());
        }
      });

      test('adds child with corrected parentId', () {
        final system = SoftwareSystem.create(name: 'System');
        final container = Container.create(
          name: 'Container',
          parentId: 'wrong-parent',
        );

        final updatedSystem = system.addChild(container);

        expect(updatedSystem.containers.first.parentId, equals(system.id));
      });

      test('preserves parent properties when adding child', () {
        final system = SoftwareSystem.create(name: 'System');
        system.description = 'System description';
        system.url = 'https://example.com';

        final container = Container.create(
          name: 'Container',
          parentId: system.id,
        );

        final updatedSystem = system.addChild(container);

        expect(updatedSystem.containers, contains(container));
        expect(updatedSystem.description, equals('System description'));
        expect(updatedSystem.url, equals('https://example.com'));
      });

      test('handles duplicate IDs by replacing', () {
        final system = SoftwareSystem.create(name: 'System');
        final container1 = Container(
          id: 'same-id',
          name: 'Container 1',
          parentId: system.id,
        );
        final container2 = Container(
          id: 'same-id',
          name: 'Container 2',
          parentId: system.id,
        );

        final updatedSystem = system.addChild(container1).addChild(container2);

        expect(updatedSystem.containers.length, equals(1));
        expect(updatedSystem.containers.first.name, equals('Container 2'));
      });
    });

    group('Element.setIdentifier method', () {
      test('changes id of a person', () {
        final person = Person.create(name: 'User');
        final oldId = person.id;

        final updatedPerson = person.setIdentifier('new-id');

        expect(updatedPerson.id, equals('new-id'));
        expect(updatedPerson.id, isNot(equals(oldId)));
      });

      test('changes id of a software system', () {
        final system = SoftwareSystem.create(name: 'System');
        final oldId = system.id;

        final updatedSystem = system.setIdentifier('new-id');

        expect(updatedSystem.id, equals('new-id'));
        expect(updatedSystem.id, isNot(equals(oldId)));
      });

      test('changes id of a container', () {
        final container = Container.create(name: 'Container');
        final oldId = container.id;

        final updatedContainer = container.setIdentifier('new-id');

        expect(updatedContainer.id, equals('new-id'));
        expect(updatedContainer.id, isNot(equals(oldId)));
      });

      test('preserves all other properties when changing id', () {
        final person = Person.create(name: 'User');
        person.description = 'A user description';
        person.url = 'https://example.com/user';
        person.location = Location.internal;

        final updatedPerson = person.setIdentifier('new-id');

        expect(updatedPerson.id, equals('new-id'));
        expect(updatedPerson.name, equals('User'));
        expect(updatedPerson.description, equals('A user description'));
        expect(updatedPerson.url, equals('https://example.com/user'));
        expect(updatedPerson.location, equals(Location.internal));
      });

      test('preserves relationships when changing id', () {
        final person = Person.create(name: 'User');
        final system = SoftwareSystem.create(name: 'System');

        final relationship = Relationship(
          id: 'rel-1',
          sourceId: person.id,
          destinationId: system.id,
          description: 'Uses',
        );

        final personWithRel = person.addRelationship(relationship);
        final updatedPerson = personWithRel.setIdentifier('new-id');

        expect(updatedPerson.relationships.length, equals(1));
        expect(updatedPerson.relationships.first.sourceId, equals('new-id'));
      });

      test('change id updates relationships sourceId', () {
        final person = Person.create(name: 'User');
        final system = SoftwareSystem.create(name: 'System');

        final relationship = Relationship(
          id: 'rel-1',
          sourceId: person.id,
          destinationId: system.id,
          description: 'Uses',
        );

        final personWithRel = person.addRelationship(relationship);
        final updatedPerson = personWithRel.setIdentifier('new-id');

        // Source ID in relationships should be updated to match the new element ID
        expect(updatedPerson.relationships.first.sourceId, equals('new-id'));
      });

      test('handles empty identifier', () {
        final person = Person.create(name: 'User');

        try {
          final updatedPerson = person.setIdentifier('');

          // If implementation allows empty IDs:
          expect(updatedPerson.id, isEmpty);
        } catch (e) {
          // If implementation disallows empty IDs:
          expect(e, isA<Error>());
        }
      });
    });

    group('PersonNode.setProperty method', () {
      test('adds string property to person', () {
        final person = Person.create(name: 'User');

        final updatedPerson = person.setProperty('name', 'User');

        expect(updatedPerson.properties, isNotNull);
        expect(updatedPerson.properties['name'], equals('User'));
      });

      test('adds numeric property to person', () {
        final person = Person.create(name: 'User');

        final updatedPerson = person.setProperty('age', 30);

        expect(updatedPerson.properties['age'], equals(30));
      });

      test('adds boolean property to person', () {
        final person = Person.create(name: 'User');

        final updatedPerson = person.setProperty('active', true);

        expect(updatedPerson.properties['active'], equals(true));
      });

      test('updates existing property value', () {
        final person = Person.create(name: 'User');
        final personWithProp = person.setProperty('role', 'User');

        final updatedPerson = personWithProp.setProperty('role', 'Admin');

        expect(updatedPerson.properties['role'], equals('Admin'));
      });

      test('adds multiple properties', () {
        final person = Person.create(name: 'User');

        final updatedPerson =
            person.setProperty('role', 'Admin').setProperty('department', 'IT');

        expect(updatedPerson.properties['role'], equals('Admin'));
        expect(updatedPerson.properties['department'], equals('IT'));
      });

      test('preserves other person data when setting property', () {
        final person = Person.create(name: 'User');
        person.description = 'A user';

        final updatedPerson = person.setProperty('role', 'Admin');

        expect(updatedPerson.properties['role'], equals('Admin'));
        expect(updatedPerson.name, equals('User'));
        expect(updatedPerson.description, equals('A user'));
      });
    });

    group('SoftwareSystemNode.setProperty method', () {
      test('adds string property to software system', () {
        final system = SoftwareSystem.create(name: 'System');

        final updatedSystem = system.setProperty('description', 'A system');

        expect(updatedSystem.properties, isNotNull);
        expect(updatedSystem.properties['description'], equals('A system'));
      });

      test('adds numeric property to software system', () {
        final system = SoftwareSystem.create(name: 'System');

        final updatedSystem = system.setProperty('version', 1);

        expect(updatedSystem.properties['version'], equals(1));
      });

      test('adds complex property to software system', () {
        final system = SoftwareSystem.create(name: 'System');

        final updatedSystem = system
            .setProperty('metadata', {'deployed': true, 'region': 'us-west'});

        expect(updatedSystem.properties['metadata'], isA<Map>());
        expect(
            (updatedSystem.properties['metadata'] as Map)['deployed'], isTrue);
        expect((updatedSystem.properties['metadata'] as Map)['region'],
            equals('us-west'));
      });

      test('updates existing property value', () {
        final system = SoftwareSystem.create(name: 'System');
        final systemWithProp = system.setProperty('status', 'Development');

        final updatedSystem =
            systemWithProp.setProperty('status', 'Production');

        expect(updatedSystem.properties['status'], equals('Production'));
      });

      test('adds multiple properties', () {
        final system = SoftwareSystem.create(name: 'System');

        final updatedSystem = system
            .setProperty('version', '1.0')
            .setProperty('status', 'Active');

        expect(updatedSystem.properties['version'], equals('1.0'));
        expect(updatedSystem.properties['status'], equals('Active'));
      });

      test('preserves children when setting property', () {
        final system = SoftwareSystem.create(name: 'System');
        final container = Container.create(
          name: 'Container',
          parentId: system.id,
        );

        final systemWithContainer = system.addChild(container);
        final updatedSystem = systemWithContainer.setProperty('version', '1.0');

        expect(updatedSystem.properties['version'], equals('1.0'));
        expect(updatedSystem.containers, contains(container));
      });
    });
  });
}
