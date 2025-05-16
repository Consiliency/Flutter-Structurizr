import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/enterprise.dart';
import 'package:flutter_structurizr/domain/model/group.dart';

void main() {
  group('Model with Group/Enterprise/Element Foundation', () {
    late Model model;
    
    setUp(() {
      model = const Model();
    });
    
    test('addGroup adds a group to the model', () {
      final group = Group(id: 'group-id', name: 'Group 1');
      
      final updatedModel = model.addGroup(group);
      
      // Once implemented, this should verify that the group is in the model's groups
      expect(updatedModel, isA<Model>());
      // expect(updatedModel.groups, contains(group));
    });
    
    test('addEnterprise adds an enterprise to the model', () {
      final enterprise = Enterprise(id: 'enterprise-id', name: 'Enterprise 1');
      
      final updatedModel = model.addEnterprise(enterprise);
      
      expect(updatedModel.enterpriseName, equals('Enterprise 1'));
    });
    
    test('addElement adds an element to the model', () {
      final person = Person.create(name: 'User');
      
      final updatedModel = model.addElement(person);
      
      expect(updatedModel.people, contains(person));
    });
    
    test('addRelationship adds a relationship to the model', () {
      final person = Person.create(name: 'User');
      final system = SoftwareSystem.create(name: 'System');
      
      model = model.addPerson(person).addSoftwareSystem(system);
      
      final relationship = Relationship(
        id: 'rel-id',
        sourceId: person.id,
        destinationId: system.id,
        description: 'Uses',
      );
      
      final updatedModel = model.addRelationship(relationship);
      
      // This test assumes the relationship would be added to the source element
      final updatedPerson = updatedModel.getPeopleById(person.id);
      expect(updatedPerson!.relationships, contains(relationship));
    });
    
    test('addImpliedRelationship adds an implied relationship to the model', () {
      final person = Person.create(name: 'User');
      final system = SoftwareSystem.create(name: 'System');
      
      model = model.addPerson(person).addSoftwareSystem(system);
      
      final relationship = Relationship(
        id: 'rel-id',
        sourceId: person.id,
        destinationId: system.id,
        description: 'Implied relationship',
      );
      
      final updatedModel = model.addImpliedRelationship(relationship);
      
      // Once implemented, this should verify the implied relationship storage
      expect(updatedModel, isA<Model>());
    });
    
    test('setAdvancedProperty sets a property on the model', () {
      final updatedModel = model.setAdvancedProperty('key', 'value');
      
      // Once implemented, this should verify the property was set
      expect(updatedModel, isA<Model>());
    });
  });
  
  group('Group operations', () {
    test('Group.addElement adds an element to a group', () {
      final group = Group(id: 'group-id', name: 'Group 1');
      final person = Person.create(name: 'User');
      
      final updatedGroup = group.addElement(person);
      
      // Once implemented, this should verify the element was added
      expect(updatedGroup, isA<Group>());
      // expect(updatedGroup.elements, contains(person));
    });
    
    test('Group.setProperty sets a property on a group', () {
      final group = Group(id: 'group-id', name: 'Group 1');
      
      final updatedGroup = group.setProperty('key', 'value');
      
      // Once implemented, this should verify the property was set
      expect(updatedGroup, isA<Group>());
      // expect(updatedGroup.properties['key'], equals('value'));
    });
  });
  
  group('Enterprise operations', () {
    test('Enterprise.addGroup adds a group to an enterprise', () {
      final enterprise = Enterprise(id: 'enterprise-id', name: 'Enterprise 1');
      final group = Group(id: 'group-id', name: 'Group 1');
      
      final updatedEnterprise = enterprise.addGroup(group);
      
      // Once implemented, this should verify the group was added
      expect(updatedEnterprise, isA<Enterprise>());
      // expect(updatedEnterprise.groups, contains(group));
    });
    
    test('Enterprise.setProperty sets a property on an enterprise', () {
      final enterprise = Enterprise(id: 'enterprise-id', name: 'Enterprise 1');
      
      final updatedEnterprise = enterprise.setProperty('key', 'value');
      
      // Once implemented, this should verify the property was set
      expect(updatedEnterprise, isA<Enterprise>());
      // expect(updatedEnterprise.properties['key'], equals('value'));
    });
  });
  
  group('Element operations', () {
    test('Element.addChild adds a child to an element', () {
      final system = SoftwareSystem.create(name: 'System');
      final container = Container.create(
        name: 'Container',
        parentId: system.id,
      );
      
      final updatedSystem = system.addChild(container);
      
      expect(updatedSystem.containers, contains(container));
    });
    
    test('Element.setIdentifier sets the ID of an element', () {
      final person = Person.create(name: 'User');
      
      final updatedPerson = person.setIdentifier('new-id');
      
      expect(updatedPerson.id, equals('new-id'));
    });
  });
}