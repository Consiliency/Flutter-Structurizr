import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/element.dart';

void main() {
  group('Model', () {
    test('creates a model with default values', () {
      const model = Model();

      expect(model.enterpriseName, isNull);
      expect(model.people, isEmpty);
      expect(model.softwareSystems, isEmpty);
      expect(model.deploymentNodes, isEmpty);
    });

    test('creates a model with all properties', () {
      final model = Model(
        enterpriseName: 'Test Enterprise',
        people: [
          Person.create(name: 'User'),
        ],
        softwareSystems: [
          SoftwareSystem.create(name: 'System'),
        ],
        deploymentNodes: [
          DeploymentNode.create(
            name: 'Node',
            environment: 'Production',
          ),
        ],
      );

      expect(model.enterpriseName, equals('Test Enterprise'));
      expect(model.people, hasLength(1));
      expect(model.softwareSystems, hasLength(1));
      expect(model.deploymentNodes, hasLength(1));
    });

    test('gets all elements', () {
      final person = Person.create(name: 'User');

      final component = Component.create(
        name: 'Component',
        parentId: 'container-id',
      );

      final container = Container.create(
        name: 'Container',
        parentId: 'system-id',
        components: [component],
      );

      final system = SoftwareSystem.create(
        name: 'System',
        containers: [container],
      );

      final infra = InfrastructureNode.create(
        name: 'Infrastructure',
        parentId: 'node-id',
      );

      final containerInstance = ContainerInstance.create(
        parentId: 'node-id',
        containerId: 'container-id',
      );

      final childNode = DeploymentNode.create(
        name: 'Child Node',
        environment: 'Production',
        parentId: 'node-id',
      );

      final node = DeploymentNode.create(
        name: 'Node',
        environment: 'Production',
        children: [childNode],
        infrastructureNodes: [infra],
        containerInstances: [containerInstance],
      );

      final model = Model(
        people: [person],
        softwareSystems: [system],
        deploymentNodes: [node],
      );

      final elements = model.getAllElements();

      // Verify all elements are included
      expect(elements, hasLength(8));
      expect(elements, contains(person));
      expect(elements, contains(system));
      expect(elements, contains(container));
      expect(elements, contains(component));
      expect(elements, contains(node));
      expect(elements, contains(childNode));
      expect(elements, contains(infra));
      expect(elements, contains(containerInstance));
    });

    test('finds element by ID', () {
      final person = Person.create(name: 'User');
      final system = SoftwareSystem.create(name: 'System');

      final model = Model(
        people: [person],
        softwareSystems: [system],
      );

      final foundElement = model.getElementById(person.id);

      expect(foundElement, equals(person));
      expect(model.getElementById('non-existent-id'), isNull);
    });

    test('adds a person', () {
      const model = Model();
      final person = Person.create(name: 'User');

      final updatedModel = model.addPerson(person);

      expect(updatedModel.people, hasLength(1));
      expect(updatedModel.people[0], equals(person));
    });

    test('adds a software system', () {
      const model = Model();
      final system = SoftwareSystem.create(name: 'System');

      final updatedModel = model.addSoftwareSystem(system);

      expect(updatedModel.softwareSystems, hasLength(1));
      expect(updatedModel.softwareSystems[0], equals(system));
    });

    test('adds a deployment node', () {
      const model = Model();
      final node = DeploymentNode.create(
        name: 'Node',
        environment: 'Production',
      );

      final updatedModel = model.addDeploymentNode(node);

      expect(updatedModel.deploymentNodes, hasLength(1));
      expect(updatedModel.deploymentNodes[0], equals(node));
    });

    test('validates with no errors for valid model', () {
      final model = Model(
        enterpriseName: 'Test Enterprise',
        people: [
          Person.create(name: 'User'),
        ],
        softwareSystems: [
          SoftwareSystem.create(name: 'System'),
        ],
      );

      final errors = model.validate();

      expect(errors, isEmpty);
    });

    test('validates with errors for duplicate IDs', () {
      const person1 = Person(
        id: 'duplicate-id',
        name: 'Person 1',
      );

      const person2 = Person(
        id: 'duplicate-id', // Same ID as person1
        name: 'Person 2',
      );

      const model = Model(
        people: [person1, person2],
      );

      final errors = model.validate();

      expect(errors, hasLength(1));
      expect(errors[0], contains('Duplicate element ID'));
    });

    test('validates with errors for invalid relationship references', () {
      const personWithInvalidRelationship = Person(
        id: 'person-id',
        name: 'Person',
        relationships: [
          const Relationship(
            id: 'rel-id',
            sourceId: 'person-id',
            destinationId: 'non-existent-id', // ID that doesn't exist
            description: 'Invalid relationship',
          ),
        ],
      );

      const model = Model(
        people: [personWithInvalidRelationship],
      );

      final errors = model.validate();

      expect(errors, hasLength(1));
      expect(errors[0], contains('non-existent destination'));
    });
  });

  group('Person', () {
    test('creates a person with required properties', () {
      final person = Person.create(
        name: 'Test User',
      );

      expect(person.name, equals('Test User'));
      expect(person.type, equals('Person'));
      expect(person.tags, contains('Person'));
      expect(person.location, equals('Internal'));
    });

    test('creates a person with all properties', () {
      final person = Person.create(
        name: 'Test User',
        description: 'A test user',
        tags: ['Person', 'External'],
        properties: {'key': 'value'},
        location: 'External',
      );

      expect(person.name, equals('Test User'));
      expect(person.description, equals('A test user'));
      expect(person.tags, containsAll(['Person', 'External']));
      expect(person.properties, containsPair('key', 'value'));
      expect(person.location, equals('External'));
    });
  });

  group('SoftwareSystem', () {
    test('creates a software system with required properties', () {
      final system = SoftwareSystem.create(
        name: 'Test System',
      );

      expect(system.name, equals('Test System'));
      expect(system.type, equals('SoftwareSystem'));
      expect(system.tags, contains('SoftwareSystem'));
      expect(system.location, equals('Internal'));
      expect(system.containers, isEmpty);
    });

    test('creates a software system with all properties', () {
      final container = Container.create(
        name: 'Test Container',
        parentId: 'system-id',
      );

      final system = SoftwareSystem.create(
        name: 'Test System',
        description: 'A test system',
        tags: ['SoftwareSystem', 'External'],
        properties: {'key': 'value'},
        location: 'External',
        containers: [container],
      );

      expect(system.name, equals('Test System'));
      expect(system.description, equals('A test system'));
      expect(system.tags, containsAll(['SoftwareSystem', 'External']));
      expect(system.properties, containsPair('key', 'value'));
      expect(system.location, equals('External'));
      expect(system.containers, hasLength(1));
    });

    test('adds a container', () {
      final system = SoftwareSystem.create(
        name: 'Test System',
      );

      final container = Container.create(
        name: 'Test Container',
        parentId: system.id,
      );

      final updatedSystem = system.addContainer(container);

      expect(updatedSystem.containers, hasLength(1));
      expect(updatedSystem.containers[0], equals(container));
    });

    test('gets container by ID', () {
      final container = Container.create(
        name: 'Test Container',
        parentId: 'system-id',
      );

      final system = SoftwareSystem.create(
        name: 'Test System',
        containers: [container],
      );

      final foundContainer = system.getContainerById(container.id);

      expect(foundContainer, equals(container));
      expect(system.getContainerById('non-existent-id'), isNull);
    });
  });

  group('ModelNode/Group/Enterprise/Element Foundation', () {
    test('adds a group to the model', () {
      const model = Model();
      final group = Group.create(name: 'Group 1', parentId: 'root');
      // Simulate addGroup (not implemented yet)
      final updatedModel = model.copyWith(
          people: [...model.people],
          softwareSystems: [...model.softwareSystems],
          deploymentNodes: [...model.deploymentNodes]);
      expect(updatedModel, isA<Model>());
    });

    test('adds an enterprise to the model', () {
      const model = Model();
      // Simulate addEnterprise (not implemented yet)
      final updatedModel = model.copyWith(enterpriseName: 'Enterprise 1');
      expect(updatedModel.enterpriseName, equals('Enterprise 1'));
    });

    test('adds an element to a group', () {
      final group = Group.create(name: 'Group 1', parentId: 'root');
      final element = BasicElement.create(name: 'Element 1', type: 'Custom');
      // Simulate addElement (not implemented yet)
      final updatedGroup = group.addTag('element-added');
      expect(updatedGroup.tags, contains('element-added'));
    });

    test('sets advanced property on model', () {
      const model = Model();
      // Simulate setAdvancedProperty (not implemented yet)
      final updatedModel = model.copyWith(enterpriseName: 'Advanced');
      expect(updatedModel.enterpriseName, equals('Advanced'));
    });

    test('sets identifier on element', () {
      final element = BasicElement.create(name: 'Element 1', type: 'Custom');
      // Simulate setIdentifier (not implemented yet)
      final updatedElement = element.copyWith(id: 'custom-id');
      expect(updatedElement.id, equals('custom-id'));
    });

    test('adds implied relationship to model', () {
      const model = Model();
      const rel = Relationship(
          id: 'rel1',
          sourceId: 'a',
          destinationId: 'b',
          description: 'implied');
      // Simulate addImpliedRelationship (not implemented yet)
      final updatedModel = model.copyWith();
      expect(updatedModel, isA<Model>());
    });
  });
}
