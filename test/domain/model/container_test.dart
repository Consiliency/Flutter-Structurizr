import 'package:flutter_structurizr/domain/model/container.dart';
import 'package:flutter_structurizr/domain/model/component.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Container tests', () {
    late Container container;
    const containerId = 'container-1';
    const containerName = 'API Application';
    const containerDescription = 'Provides a REST API';
    const containerTechnology = 'Java and Spring Boot';
    const parentId = 'system-1';

    setUp(() {
      container = const Container(
        id: containerId,
        name: containerName,
        description: containerDescription,
        technology: containerTechnology,
        parentId: parentId,
      );
    });

    test('Container creation with ID', () {
      expect(container.id, equals(containerId));
      expect(container.name, equals(containerName));
      expect(container.description, equals(containerDescription));
      expect(container.technology, equals(containerTechnology));
      expect(container.parentId, equals(parentId));
      expect(container.type, equals('Container'));
      expect(container.tags, isEmpty);
      expect(container.properties, isEmpty);
      expect(container.relationships, isEmpty);
      expect(container.components, isEmpty);
    });

    test('Container.create() factory generates UUID', () {
      final createdContainer = Container.create(
        name: containerName,
        parentId: parentId,
        description: containerDescription,
        technology: containerTechnology,
      );

      expect(createdContainer.id, isNotNull);
      expect(createdContainer.id.length, greaterThan(0));
      expect(createdContainer.name, equals(containerName));
      expect(createdContainer.description, equals(containerDescription));
      expect(createdContainer.technology, equals(containerTechnology));
      expect(createdContainer.parentId, equals(parentId));
      expect(
          createdContainer.tags, contains('Container')); // Default tag is added
    });

    test('addComponent() adds a component to the container', () {
      const component = Component(
        id: 'component-1',
        name: 'UserController',
        description: 'REST controller for user endpoints',
        parentId: containerId,
      );

      final updatedContainer = container.addComponent(component);

      expect(updatedContainer.components.length, equals(1));
      expect(updatedContainer.components.first.id, equals(component.id));
      expect(updatedContainer.components.first.name, equals(component.name));

      // Original container should be unchanged (immutability test)
      expect(container.components.length, equals(0));
    });

    test('getComponentById() returns the correct component', () {
      const component1 = Component(
        id: 'component-1',
        name: 'UserController',
        description: 'REST controller for user endpoints',
        parentId: containerId,
      );

      const component2 = Component(
        id: 'component-2',
        name: 'OrderService',
        description: 'Business logic for orders',
        parentId: containerId,
      );

      final containerWithComponents =
          container.addComponent(component1).addComponent(component2);

      final foundComponent =
          containerWithComponents.getComponentById('component-2');

      expect(foundComponent, isNotNull);
      expect(foundComponent?.id, equals('component-2'));
      expect(foundComponent?.name, equals('OrderService'));
    });

    test('getComponentById() returns null for non-existent component', () {
      final containerWithComponent = container.addComponent(const Component(
        id: 'component-1',
        name: 'UserController',
        parentId: containerId,
      ));

      final foundComponent =
          containerWithComponent.getComponentById('non-existent');

      expect(foundComponent, isNull);
    });

    test('addTag() adds a tag to the container', () {
      final updatedContainer = container.addTag('Database');

      expect(updatedContainer.tags, contains('Database'));
      expect(updatedContainer.tags.length, equals(1));

      // Original container should be unchanged (immutability test)
      expect(container.tags.length, equals(0));
    });

    test('addTags() adds multiple tags to the container', () {
      final updatedContainer = container.addTags(['Database', 'Critical']);

      expect(updatedContainer.tags, contains('Database'));
      expect(updatedContainer.tags, contains('Critical'));
      expect(updatedContainer.tags.length, equals(2));
    });

    test('addProperty() adds a property to the container', () {
      final updatedContainer = container.addProperty('version', '1.0.0');

      expect(updatedContainer.properties['version'], equals('1.0.0'));
      expect(updatedContainer.properties.length, equals(1));
    });

    test('addRelationship() adds a relationship from the container', () {
      final updatedContainer = container.addRelationship(
        destinationId: 'database-1',
        description: 'Uses',
        technology: 'JDBC',
      );

      expect(updatedContainer.relationships.length, equals(1));
      expect(
          updatedContainer.relationships.first.sourceId, equals(containerId));
      expect(updatedContainer.relationships.first.destinationId,
          equals('database-1'));
      expect(updatedContainer.relationships.first.description, equals('Uses'));
      expect(updatedContainer.relationships.first.technology, equals('JDBC'));
    });
  });
}
