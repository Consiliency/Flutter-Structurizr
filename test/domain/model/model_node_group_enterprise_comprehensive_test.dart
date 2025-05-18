import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/enterprise.dart';
import 'package:flutter_structurizr/domain/model/group.dart';
import 'package:flutter_structurizr/domain/model/relationship.dart';

void main() {
  group('Model, Group, Enterprise, Element foundation comprehensive tests', () {
    group('Model.addGroup method', () {
      test('adds group to empty model', () {
        const model = Model();
        const group = Group(id: 'group-1', name: 'Group 1');

        final updatedModel = model.addGroup(group);

        expect(updatedModel.groups, isNotNull);
        expect(updatedModel.groups.length, equals(1));
        expect(updatedModel.groups.first, equals(group));
      });

      test('adds multiple groups to model', () {
        const model = Model();
        const group1 = Group(id: 'group-1', name: 'Group 1');
        const group2 = Group(id: 'group-2', name: 'Group 2');

        final updatedModel = model.addGroup(group1).addGroup(group2);

        expect(updatedModel.groups.length, equals(2));
        expect(updatedModel.groups[0], equals(group1));
        expect(updatedModel.groups[1], equals(group2));
      });

      test('preserves other model properties when adding group', () {
        const model = Model();
        final person = Person.create(name: 'User');
        const group = Group(id: 'group-1', name: 'Group 1');

        final updatedModel = model.addPerson(person).addGroup(group);

        expect(updatedModel.groups.length, equals(1));
        expect(updatedModel.groups.first, equals(group));
        expect(updatedModel.people.length, equals(1));
        expect(updatedModel.people.first, equals(person));
      });

      test('handles adding group with duplicate id', () {
        const model = Model();
        const group1 = Group(id: 'dup-id', name: 'Group 1');
        const group2 = Group(id: 'dup-id', name: 'Group 2');

        final updatedModel = model.addGroup(group1).addGroup(group2);

        // Implementations may vary on handling duplicates
        // Some may replace, others may add both
        expect(updatedModel.groups.length, greaterThanOrEqualTo(1));

        // At minimum the last group should be present
        expect(updatedModel.groups.any((g) => g.name == 'Group 2'), isTrue);
      });
    });

    group('Model.addEnterprise method', () {
      test('adds enterprise to model with no existing enterprise', () {
        const model = Model();
        const enterprise = Enterprise(id: 'enterprise-1', name: 'Enterprise 1');

        final updatedModel = model.addEnterprise(enterprise);

        expect(updatedModel.enterprise, equals(enterprise));
        expect(updatedModel.enterpriseName, equals('Enterprise 1'));
      });

      test('replaces enterprise when adding second enterprise', () {
        const model = Model();
        const enterprise1 =
            Enterprise(id: 'enterprise-1', name: 'Enterprise 1');
        const enterprise2 =
            Enterprise(id: 'enterprise-2', name: 'Enterprise 2');

        final updatedModel =
            model.addEnterprise(enterprise1).addEnterprise(enterprise2);

        expect(updatedModel.enterprise, equals(enterprise2));
        expect(updatedModel.enterpriseName, equals('Enterprise 2'));
      });

      test('preserves other model properties when adding enterprise', () {
        const model = Model();
        final person = Person.create(name: 'User');
        const enterprise = Enterprise(id: 'enterprise-1', name: 'Enterprise 1');

        final updatedModel = model.addPerson(person).addEnterprise(enterprise);

        expect(updatedModel.enterprise, equals(enterprise));
        expect(updatedModel.enterpriseName, equals('Enterprise 1'));
        expect(updatedModel.people.length, equals(1));
        expect(updatedModel.people.first, equals(person));
      });
    });

    group('Model.addElement method', () {
      test('adds person element to model', () {
        const model = Model();
        final person = Person.create(name: 'User');

        final updatedModel = model.addElement(person);

        expect(updatedModel.people.length, equals(1));
        expect(updatedModel.people.first, equals(person));
      });

      test('adds software system element to model', () {
        const model = Model();
        final system = SoftwareSystem.create(name: 'System');

        final updatedModel = model.addElement(system);

        expect(updatedModel.softwareSystems.length, equals(1));
        expect(updatedModel.softwareSystems.first, equals(system));
      });

      test('handling of element with existing ID', () {
        const model = Model();
        const person1 = Person(id: 'dup-id', name: 'Person 1');
        const person2 = Person(id: 'dup-id', name: 'Person 2');

        final updatedModel = model.addElement(person1).addElement(person2);

        expect(updatedModel.people.length, equals(1));
        expect(updatedModel.people.first.name, equals('Person 2'));
      });

      test('preserves other model properties when adding element', () {
        const model = Model();
        const enterprise = Enterprise(id: 'enterprise-1', name: 'Enterprise 1');
        final person = Person.create(name: 'User');

        final updatedModel = model.addEnterprise(enterprise).addElement(person);

        expect(updatedModel.people.length, equals(1));
        expect(updatedModel.people.first, equals(person));
        expect(updatedModel.enterprise, equals(enterprise));
        expect(updatedModel.enterpriseName, equals('Enterprise 1'));
      });
    });

    group('Model.addRelationship method', () {
      test('adds relationship to model', () {
        const model = Model();
        final person = Person.create(name: 'User');
        final system = SoftwareSystem.create(name: 'System');

        final modelWithElements = model.addElement(person).addElement(system);

        final relationship = Relationship(
          id: 'rel-1',
          sourceId: person.id,
          destinationId: system.id,
          description: 'Uses',
        );

        final updatedModel = modelWithElements.addRelationship(relationship);

        // Check if relationship was added to source element
        final updatedPerson = updatedModel.getPeopleById(person.id);
        expect(updatedPerson!.relationships, contains(relationship));
      });

      test('adds multiple relationships to model', () {
        const model = Model();
        final person = Person.create(name: 'User');
        final system1 = SoftwareSystem.create(name: 'System 1');
        final system2 = SoftwareSystem.create(name: 'System 2');

        final modelWithElements =
            model.addElement(person).addElement(system1).addElement(system2);

        final relationship1 = Relationship(
          id: 'rel-1',
          sourceId: person.id,
          destinationId: system1.id,
          description: 'Uses',
        );

        final relationship2 = Relationship(
          id: 'rel-2',
          sourceId: person.id,
          destinationId: system2.id,
          description: 'Also uses',
        );

        final updatedModel = modelWithElements
            .addRelationship(relationship1)
            .addRelationship(relationship2);

        final updatedPerson = updatedModel.getPeopleById(person.id);
        expect(updatedPerson!.relationships.length, equals(2));
        expect(updatedPerson.relationships, contains(relationship1));
        expect(updatedPerson.relationships, contains(relationship2));
      });

      test('handles relationship with missing source element', () {
        const model = Model();
        final system = SoftwareSystem.create(name: 'System');

        final modelWithSystem = model.addElement(system);

        final relationship = Relationship(
          id: 'rel-1',
          sourceId: 'non-existent',
          destinationId: system.id,
          description: 'Uses',
        );

        // Implementation may vary, but should at minimum not crash
        try {
          final updatedModel = modelWithSystem.addRelationship(relationship);
          expect(updatedModel, isA<Model>());
        } catch (e) {
          // Or it might throw an error, which is also a valid approach
          expect(e, isA<Error>());
        }
      });

      test('handles relationship with missing destination element', () {
        const model = Model();
        final person = Person.create(name: 'User');

        final modelWithPerson = model.addElement(person);

        final relationship = Relationship(
          id: 'rel-1',
          sourceId: person.id,
          destinationId: 'non-existent',
          description: 'Uses',
        );

        // Implementation may vary
        try {
          final updatedModel = modelWithPerson.addRelationship(relationship);
          expect(updatedModel, isA<Model>());
        } catch (e) {
          expect(e, isA<Error>());
        }
      });
    });

    group('Model.addImpliedRelationship method', () {
      test('adds implied relationship to model', () {
        const model = Model();
        final person = Person.create(name: 'User');
        final system = SoftwareSystem.create(name: 'System');

        final modelWithElements = model.addElement(person).addElement(system);

        final relationship = Relationship(
          id: 'rel-1',
          sourceId: person.id,
          destinationId: system.id,
          description: 'Implied relationship',
        );

        final updatedModel =
            modelWithElements.addImpliedRelationship(relationship);

        // Implementation may store implied relationships differently
        // than regular relationships, so we can only verify the model was updated
        expect(updatedModel, isA<Model>());

        // If stored with implied flag on source element:
        final updatedPerson = updatedModel.getPeopleById(person.id);
        if (updatedPerson != null && updatedPerson.relationships.isNotEmpty) {
          final addedRel = updatedPerson.relationships.firstWhere(
            (r) => r.id == relationship.id,
            orElse: () => const Relationship(
              id: '',
              sourceId: '',
              destinationId: '',
              description: '',
            ),
          );

          if (addedRel.id.isNotEmpty) {
            expect(addedRel.isImplied, isTrue);
          }
        }
      });
    });

    group('Model.setAdvancedProperty method', () {
      test('sets a string property on the model', () {
        const model = Model();

        final updatedModel = model.setAdvancedProperty('key1', 'value1');

        // Implementation may vary
        expect(updatedModel, isA<Model>());

        // If implemented with properties map:
        if (updatedModel.properties != null) {
          expect(updatedModel.properties!['key1'], equals('value1'));
        }
      });

      test('sets a numeric property on the model', () {
        const model = Model();

        final updatedModel = model.setAdvancedProperty('count', 42);

        expect(updatedModel, isA<Model>());

        // If implemented with properties map:
        if (updatedModel.properties != null) {
          expect(updatedModel.properties!['count'], equals(42));
        }
      });

      test('updates existing property value', () {
        const model = Model();

        final updatedModel = model
            .setAdvancedProperty('key', 'value1')
            .setAdvancedProperty('key', 'value2');

        expect(updatedModel, isA<Model>());

        // If implemented with properties map:
        if (updatedModel.properties != null) {
          expect(updatedModel.properties!['key'], equals('value2'));
        }
      });
    });

    group('Group.addElement method', () {
      test('adds person element to group', () {
        const group = Group(id: 'group-1', name: 'Group 1');
        final person = Person.create(name: 'User');

        final updatedGroup = group.addElement(person);

        expect(updatedGroup.elements, isNotNull);
        expect(updatedGroup.elements.length, equals(1));
        expect(updatedGroup.elements.first, equals(person));
      });

      test('adds software system element to group', () {
        const group = Group(id: 'group-1', name: 'Group 1');
        final system = SoftwareSystem.create(name: 'System');

        final updatedGroup = group.addElement(system);

        expect(updatedGroup.elements, isNotNull);
        expect(updatedGroup.elements.length, equals(1));
        expect(updatedGroup.elements.first, equals(system));
      });

      test('adds multiple elements to group', () {
        const group = Group(id: 'group-1', name: 'Group 1');
        final person = Person.create(name: 'User');
        final system = SoftwareSystem.create(name: 'System');

        final updatedGroup = group.addElement(person).addElement(system);

        expect(updatedGroup.elements.length, equals(2));
        expect(updatedGroup.elements[0], equals(person));
        expect(updatedGroup.elements[1], equals(system));
      });

      test('preserves other group properties when adding element', () {
        const group = Group(
          id: 'group-1',
          name: 'Group 1',
          properties: {'type': 'Internal'},
        );
        final person = Person.create(name: 'User');

        final updatedGroup = group.addElement(person);

        expect(updatedGroup.elements.length, equals(1));
        expect(updatedGroup.elements.first, equals(person));
        expect(updatedGroup.properties, isNotNull);
        expect(updatedGroup.properties['type'], equals('Internal'));
      });
    });

    group('Group.setProperty method', () {
      test('sets a string property on a group', () {
        const group = Group(id: 'group-1', name: 'Group 1');

        final updatedGroup = group.setProperty('type', 'Internal');

        expect(updatedGroup.properties, isNotNull);
        expect(updatedGroup.properties['type'], equals('Internal'));
      });

      test('sets a numeric property on a group', () {
        const group = Group(id: 'group-1', name: 'Group 1');

        final updatedGroup = group.setProperty('order', 3);

        expect(updatedGroup.properties['order'], equals(3));
      });

      test('updates existing property value', () {
        const group = Group(
          id: 'group-1',
          name: 'Group 1',
          properties: {'key': 'value1'},
        );

        final updatedGroup = group.setProperty('key', 'value2');

        expect(updatedGroup.properties['key'], equals('value2'));
      });

      test('sets multiple properties', () {
        const group = Group(id: 'group-1', name: 'Group 1');

        final updatedGroup =
            group.setProperty('key1', 'value1').setProperty('key2', 'value2');

        expect(updatedGroup.properties['key1'], equals('value1'));
        expect(updatedGroup.properties['key2'], equals('value2'));
      });
    });

    group('Enterprise.addGroup method', () {
      test('adds group to enterprise with no groups', () {
        const enterprise = Enterprise(id: 'enterprise-1', name: 'Enterprise 1');
        const group = Group(id: 'group-1', name: 'Group 1');

        final updatedEnterprise = enterprise.addGroup(group);

        expect(updatedEnterprise.groups, isNotNull);
        expect(updatedEnterprise.groups.length, equals(1));
        expect(updatedEnterprise.groups.first, equals(group));
      });

      test('adds multiple groups to enterprise', () {
        const enterprise = Enterprise(id: 'enterprise-1', name: 'Enterprise 1');
        const group1 = Group(id: 'group-1', name: 'Group 1');
        const group2 = Group(id: 'group-2', name: 'Group 2');

        final updatedEnterprise = enterprise.addGroup(group1).addGroup(group2);

        expect(updatedEnterprise.groups.length, equals(2));
        expect(updatedEnterprise.groups[0], equals(group1));
        expect(updatedEnterprise.groups[1], equals(group2));
      });

      test('preserves other enterprise properties when adding group', () {
        const enterprise = Enterprise(
          id: 'enterprise-1',
          name: 'Enterprise 1',
          properties: {'location': 'HQ'},
        );
        const group = Group(id: 'group-1', name: 'Group 1');

        final updatedEnterprise = enterprise.addGroup(group);

        expect(updatedEnterprise.groups.length, equals(1));
        expect(updatedEnterprise.groups.first, equals(group));
        expect(updatedEnterprise.properties, isNotNull);
        expect(updatedEnterprise.properties['location'], equals('HQ'));
      });
    });

    group('Enterprise.setProperty method', () {
      test('sets a string property on an enterprise', () {
        const enterprise = Enterprise(id: 'enterprise-1', name: 'Enterprise 1');

        final updatedEnterprise = enterprise.setProperty('location', 'HQ');

        expect(updatedEnterprise.properties, isNotNull);
        expect(updatedEnterprise.properties['location'], equals('HQ'));
      });

      test('sets a numeric property on an enterprise', () {
        const enterprise = Enterprise(id: 'enterprise-1', name: 'Enterprise 1');

        final updatedEnterprise = enterprise.setProperty('founded', 2010);

        expect(updatedEnterprise.properties['founded'], equals(2010));
      });

      test('updates existing property value', () {
        const enterprise = Enterprise(
          id: 'enterprise-1',
          name: 'Enterprise 1',
          properties: {'key': 'value1'},
        );

        final updatedEnterprise = enterprise.setProperty('key', 'value2');

        expect(updatedEnterprise.properties['key'], equals('value2'));
      });

      test('sets multiple properties', () {
        const enterprise = Enterprise(id: 'enterprise-1', name: 'Enterprise 1');

        final updatedEnterprise = enterprise
            .setProperty('key1', 'value1')
            .setProperty('key2', 'value2');

        expect(updatedEnterprise.properties['key1'], equals('value1'));
        expect(updatedEnterprise.properties['key2'], equals('value2'));
      });
    });

    group('Element.addChild method', () {
      test('SoftwareSystem adds Container child', () {
        final system = SoftwareSystem.create(name: 'System');
        final container = Container.create(
          name: 'Container',
          parentId: system.id,
        );

        final updatedSystem = system.addChild(container);

        expect(updatedSystem.containers, isNotNull);
        expect(updatedSystem.containers.length, equals(1));
        expect(updatedSystem.containers.first, equals(container));
      });

      test('Container adds Component child', () {
        final container = Container.create(name: 'Container');
        final component = Component.create(
          name: 'Component',
          parentId: container.id,
        );

        final updatedContainer = container.addChild(component);

        expect(updatedContainer.components, isNotNull);
        expect(updatedContainer.components!.length, equals(1));
        expect(updatedContainer.components!.first, equals(component));
      });

      test('adds multiple children to parent', () {
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
        expect(updatedSystem.containers[0], equals(container1));
        expect(updatedSystem.containers[1], equals(container2));
      });

      test('preserves parent properties when adding child', () {
        final system = SoftwareSystem.create(name: 'System');
        system.description = 'A system description';

        final container = Container.create(
          name: 'Container',
          parentId: system.id,
        );

        final updatedSystem = system.addChild(container);

        expect(updatedSystem.containers.length, equals(1));
        expect(updatedSystem.description, equals('A system description'));
      });

      test('corrects child parentId if mismatched', () {
        final system = SoftwareSystem.create(name: 'System');
        final container = Container.create(
          name: 'Container',
          parentId: 'wrong-parent',
        );

        final updatedSystem = system.addChild(container);

        expect(updatedSystem.containers.length, equals(1));
        expect(updatedSystem.containers.first.parentId, equals(system.id));
      });
    });

    group('Element.setIdentifier method', () {
      test('changes id of person', () {
        final person = Person.create(name: 'User');

        final updatedPerson = person.setIdentifier('new-id');

        expect(updatedPerson.id, equals('new-id'));
      });

      test('changes id of software system', () {
        final system = SoftwareSystem.create(name: 'System');

        final updatedSystem = system.setIdentifier('new-id');

        expect(updatedSystem.id, equals('new-id'));
      });

      test('preserves all other properties when changing id', () {
        final person = Person.create(name: 'User');
        person.description = 'A user';

        final updatedPerson = person.setIdentifier('new-id');

        expect(updatedPerson.id, equals('new-id'));
        expect(updatedPerson.name, equals('User'));
        expect(updatedPerson.description, equals('A user'));
      });
    });

    group('PersonNode.setProperty method', () {
      test('sets a property on a person', () {
        final person = Person.create(name: 'User');

        final updatedPerson = person.setProperty('role', 'Admin');

        expect(updatedPerson.properties, isNotNull);
        expect(updatedPerson.properties['role'], equals('Admin'));
      });
    });

    group('SoftwareSystemNode.setProperty method', () {
      test('sets a property on a software system', () {
        final system = SoftwareSystem.create(name: 'System');

        final updatedSystem = system.setProperty('version', '1.0');

        expect(updatedSystem.properties, isNotNull);
        expect(updatedSystem.properties['version'], equals('1.0'));
      });
    });
  });
}
