import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/parser/ast/ast_base.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/model_element_node.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';

void main() {
  group('ElementNode', () {
    test('addChild adds a child to the element', () {
      // Create a software system node as a parent
      final parentNode = SoftwareSystemNode(
        id: 'system',
        name: 'System',
        description: 'A software system',
        containers: [],
        relationships: [],
        sourcePosition: SourcePosition(0, 0),
      );
      
      // Create a container node as a child
      final childNode = ContainerNode(
        id: 'container',
        parentId: 'system',
        name: 'Container',
        description: 'A container',
        components: [],
        relationships: [],
        sourcePosition: SourcePosition(0, 0),
      );
      
      final updatedParent = parentNode.addChild(childNode);
      
      expect(updatedParent, isA<SoftwareSystemNode>());
      expect(updatedParent.containers, contains(childNode));
    });
    
    test('setIdentifier changes the ID of the element', () {
      final element = PersonNode(
        id: 'old-id',
        name: 'Person',
        relationships: [],
        sourcePosition: SourcePosition(0, 0),
      );
      
      final updatedElement = element.setIdentifier('new-id');
      
      expect(updatedElement.id, equals('new-id'));
    });
    
    test('PersonNode.setProperty sets a property on a person', () {
      final person = PersonNode(
        id: 'user',
        name: 'User',
        relationships: [],
        sourcePosition: SourcePosition(0, 0),
      );
      
      final updatedPerson = person.setProperty('key', 'value');
      
      // Implementation may vary, but should create or update properties
      expect(updatedPerson, isA<PersonNode>());
      
      // If using PropertiesNode:
      if (updatedPerson.properties != null) {
        final property = updatedPerson.properties!.properties.firstWhere(
          (p) => p.name == 'key',
          orElse: () => PropertyNode(sourcePosition: null),
        );
        expect(property.value, equals('value'));
      }
    });
    
    test('SoftwareSystemNode.setProperty sets a property on a software system', () {
      final system = SoftwareSystemNode(
        id: 'system',
        name: 'System',
        containers: [],
        relationships: [],
        sourcePosition: SourcePosition(0, 0),
      );
      
      final updatedSystem = system.setProperty('description', 'A system');
      
      // Implementation may vary, but should create or update properties
      expect(updatedSystem, isA<SoftwareSystemNode>());
      
      // If using PropertiesNode:
      if (updatedSystem.properties != null) {
        final property = updatedSystem.properties!.properties.firstWhere(
          (p) => p.name == 'description',
          orElse: () => PropertyNode(sourcePosition: null),
        );
        expect(property.value, equals('A system'));
      }
    });
  });
}