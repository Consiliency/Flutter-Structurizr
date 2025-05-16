import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/parser/ast/ast_base.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/model_element_node.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';

void main() {
  group('ElementNode comprehensive tests', () {
    group('addChild method', () {
      test('SoftwareSystem adds Container child', () {
        final system = SoftwareSystemNode(
          id: 'system',
          name: 'Test System',
          containers: [],
          relationships: [],
          sourcePosition: SourcePosition(0, 0),
        );
        
        final container = ContainerNode(
          id: 'container',
          parentId: 'system',
          name: 'Test Container',
          description: 'A test container',
          components: [],
          relationships: [],
          sourcePosition: SourcePosition(1, 0),
        );
        
        final updatedSystem = system.addChild(container);
        
        expect(updatedSystem.containers.length, equals(1));
        expect(updatedSystem.containers.first, equals(container));
      });
      
      test('Container adds Component child', () {
        final container = ContainerNode(
          id: 'container',
          name: 'Test Container',
          description: 'A test container',
          components: [],
          relationships: [],
          sourcePosition: SourcePosition(0, 0),
        );
        
        final component = ComponentNode(
          id: 'component',
          parentId: 'container',
          name: 'Test Component',
          description: 'A test component',
          relationships: [],
          sourcePosition: SourcePosition(1, 0),
        );
        
        final updatedContainer = container.addChild(component);
        
        expect(updatedContainer.components.length, equals(1));
        expect(updatedContainer.components.first, equals(component));
      });
      
      test('adding multiple children to parent', () {
        final system = SoftwareSystemNode(
          id: 'system',
          name: 'Test System',
          containers: [],
          relationships: [],
          sourcePosition: SourcePosition(0, 0),
        );
        
        final container1 = ContainerNode(
          id: 'container1',
          parentId: 'system',
          name: 'Container 1',
          description: 'First container',
          components: [],
          relationships: [],
          sourcePosition: SourcePosition(1, 0),
        );
        
        final container2 = ContainerNode(
          id: 'container2',
          parentId: 'system',
          name: 'Container 2',
          description: 'Second container',
          components: [],
          relationships: [],
          sourcePosition: SourcePosition(2, 0),
        );
        
        final updatedSystem1 = system.addChild(container1);
        final updatedSystem2 = updatedSystem1.addChild(container2);
        
        expect(updatedSystem2.containers.length, equals(2));
        expect(updatedSystem2.containers[0], equals(container1));
        expect(updatedSystem2.containers[1], equals(container2));
      });
      
      test('preserves parent properties when adding child', () {
        final system = SoftwareSystemNode(
          id: 'system',
          name: 'Test System',
          containers: [],
          relationships: [],
          properties: PropertiesNode(
            properties: [
              PropertyNode(
                name: 'description',
                value: 'A system',
                sourcePosition: SourcePosition(0, 0),
              ),
            ],
            sourcePosition: SourcePosition(0, 0),
          ),
          sourcePosition: SourcePosition(0, 0),
        );
        
        final container = ContainerNode(
          id: 'container',
          parentId: 'system',
          name: 'Test Container',
          description: 'A test container',
          components: [],
          relationships: [],
          sourcePosition: SourcePosition(1, 0),
        );
        
        final updatedSystem = system.addChild(container);
        
        expect(updatedSystem.containers.length, equals(1));
        expect(updatedSystem.containers.first, equals(container));
        expect(updatedSystem.properties, isNotNull);
        expect(updatedSystem.properties!.properties.length, equals(1));
        expect(updatedSystem.properties!.properties.first.name, equals('description'));
        expect(updatedSystem.properties!.properties.first.value, equals('A system'));
      });
      
      test('handles unsupported child type', () {
        final person = PersonNode(
          id: 'person',
          name: 'Test Person',
          relationships: [],
          sourcePosition: SourcePosition(0, 0),
        );
        
        final container = ContainerNode(
          id: 'container',
          name: 'Test Container',
          description: 'A test container',
          components: [],
          relationships: [],
          sourcePosition: SourcePosition(1, 0),
        );
        
        try {
          // Person shouldn't accept Container as child
          final updatedPerson = person.addChild(container);
          
          // If implemented to handle invalid children types:
          expect(updatedPerson, equals(person));
        } catch (e) {
          // If invalid children throw errors:
          expect(e, isA<Error>());
        }
      });
      
      test('handles child with mismatched parentId', () {
        final system = SoftwareSystemNode(
          id: 'system',
          name: 'Test System',
          containers: [],
          relationships: [],
          sourcePosition: SourcePosition(0, 0),
        );
        
        final container = ContainerNode(
          id: 'container',
          parentId: 'wrong-parent', // Mismatched parent ID
          name: 'Test Container',
          description: 'A test container',
          components: [],
          relationships: [],
          sourcePosition: SourcePosition(1, 0),
        );
        
        try {
          final updatedSystem = system.addChild(container);
          
          // If implemented to handle mismatched parentId:
          expect(updatedSystem, isA<SoftwareSystemNode>());
          
          // Check if parentId was corrected
          if (updatedSystem.containers.isNotEmpty) {
            expect(updatedSystem.containers.first.parentId, equals('system'));
          }
        } catch (e) {
          // If mismatched parentId throws errors:
          expect(e, isA<Error>());
        }
      });
      
      test('handles null child parameter', () {
        final system = SoftwareSystemNode(
          id: 'system',
          name: 'Test System',
          containers: [],
          relationships: [],
          sourcePosition: SourcePosition(0, 0),
        );
        
        try {
          final updatedSystem = system.addChild(null);
          
          // If implemented to handle null children:
          expect(updatedSystem, equals(system));
        } catch (e) {
          // If null children throw errors:
          expect(e, isA<Error>());
        }
      });
    });
    
    group('setIdentifier method', () {
      test('changes id of person node', () {
        final person = PersonNode(
          id: 'old-id',
          name: 'Test Person',
          relationships: [],
          sourcePosition: SourcePosition(0, 0),
        );
        
        final updatedPerson = person.setIdentifier('new-id');
        
        expect(updatedPerson.id, equals('new-id'));
      });
      
      test('changes id of software system node', () {
        final system = SoftwareSystemNode(
          id: 'old-id',
          name: 'Test System',
          containers: [],
          relationships: [],
          sourcePosition: SourcePosition(0, 0),
        );
        
        final updatedSystem = system.setIdentifier('new-id');
        
        expect(updatedSystem.id, equals('new-id'));
      });
      
      test('preserves all other properties when changing id', () {
        final system = SoftwareSystemNode(
          id: 'old-id',
          name: 'Test System',
          containers: [],
          relationships: [],
          properties: PropertiesNode(
            properties: [
              PropertyNode(
                name: 'description',
                value: 'A system',
                sourcePosition: SourcePosition(0, 0),
              ),
            ],
            sourcePosition: SourcePosition(0, 0),
          ),
          sourcePosition: SourcePosition(0, 0),
        );
        
        final updatedSystem = system.setIdentifier('new-id');
        
        expect(updatedSystem.id, equals('new-id'));
        expect(updatedSystem.name, equals('Test System'));
        expect(updatedSystem.properties, isNotNull);
        expect(updatedSystem.properties!.properties.length, equals(1));
        expect(updatedSystem.properties!.properties.first.name, equals('description'));
        expect(updatedSystem.properties!.properties.first.value, equals('A system'));
      });
      
      test('changing id does not affect children', () {
        final system = SoftwareSystemNode(
          id: 'old-system-id',
          name: 'Test System',
          containers: [
            ContainerNode(
              id: 'container',
              parentId: 'old-system-id',
              name: 'Test Container',
              description: 'A test container',
              components: [],
              relationships: [],
              sourcePosition: SourcePosition(1, 0),
            ),
          ],
          relationships: [],
          sourcePosition: SourcePosition(0, 0),
        );
        
        final updatedSystem = system.setIdentifier('new-system-id');
        
        expect(updatedSystem.id, equals('new-system-id'));
        expect(updatedSystem.containers.length, equals(1));
        expect(updatedSystem.containers.first.id, equals('container'));
        
        // Note: real implementation might update child.parentId as well
        // but this depends on how IDs are managed in the model
      });
      
      test('handles empty id string', () {
        final person = PersonNode(
          id: 'old-id',
          name: 'Test Person',
          relationships: [],
          sourcePosition: SourcePosition(0, 0),
        );
        
        try {
          final updatedPerson = person.setIdentifier('');
          
          // If empty ids are allowed:
          expect(updatedPerson.id, equals(''));
        } catch (e) {
          // If empty ids throw errors:
          expect(e, isA<Error>());
        }
      });
      
      test('handles null id parameter', () {
        final person = PersonNode(
          id: 'old-id',
          name: 'Test Person',
          relationships: [],
          sourcePosition: SourcePosition(0, 0),
        );
        
        try {
          final updatedPerson = person.setIdentifier(null);
          
          // If null ids are allowed (unlikely):
          expect(updatedPerson.id, isNull);
        } catch (e) {
          // If null ids throw errors (most likely):
          expect(e, isA<Error>());
        }
      });
    });
    
    group('PersonNode.setProperty method', () {
      test('adds string property to person node', () {
        final person = PersonNode(
          id: 'person',
          name: 'Test Person',
          relationships: [],
          sourcePosition: SourcePosition(0, 0),
        );
        
        final updatedPerson = person.setProperty('name', 'User');
        
        expect(updatedPerson.properties, isNotNull);
        
        final property = updatedPerson.properties!.properties.firstWhere(
          (p) => p.name == 'name',
          orElse: () => PropertyNode(sourcePosition: null),
        );
        
        expect(property.name, equals('name'));
        expect(property.value, equals('User'));
      });
      
      test('updates existing property on person node', () {
        final person = PersonNode(
          id: 'person',
          name: 'Test Person',
          relationships: [],
          properties: PropertiesNode(
            properties: [
              PropertyNode(
                name: 'name',
                value: 'Old Name',
                sourcePosition: SourcePosition(0, 0),
              ),
            ],
            sourcePosition: SourcePosition(0, 0),
          ),
          sourcePosition: SourcePosition(0, 0),
        );
        
        final updatedPerson = person.setProperty('name', 'New Name');
        
        expect(updatedPerson.properties!.properties.length, equals(1));
        expect(updatedPerson.properties!.properties.first.name, equals('name'));
        expect(updatedPerson.properties!.properties.first.value, equals('New Name'));
      });
    });
    
    group('SoftwareSystemNode.setProperty method', () {
      test('adds string property to software system node', () {
        final system = SoftwareSystemNode(
          id: 'system',
          name: 'Test System',
          containers: [],
          relationships: [],
          sourcePosition: SourcePosition(0, 0),
        );
        
        final updatedSystem = system.setProperty('description', 'A system');
        
        expect(updatedSystem.properties, isNotNull);
        
        final property = updatedSystem.properties!.properties.firstWhere(
          (p) => p.name == 'description',
          orElse: () => PropertyNode(sourcePosition: null),
        );
        
        expect(property.name, equals('description'));
        expect(property.value, equals('A system'));
      });
      
      test('updates existing property on software system node', () {
        final system = SoftwareSystemNode(
          id: 'system',
          name: 'Test System',
          containers: [],
          relationships: [],
          properties: PropertiesNode(
            properties: [
              PropertyNode(
                name: 'description',
                value: 'Old description',
                sourcePosition: SourcePosition(0, 0),
              ),
            ],
            sourcePosition: SourcePosition(0, 0),
          ),
          sourcePosition: SourcePosition(0, 0),
        );
        
        final updatedSystem = system.setProperty('description', 'New description');
        
        expect(updatedSystem.properties!.properties.length, equals(1));
        expect(updatedSystem.properties!.properties.first.name, equals('description'));
        expect(updatedSystem.properties!.properties.first.value, equals('New description'));
      });
    });
  });
}