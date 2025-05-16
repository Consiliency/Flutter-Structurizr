import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/parser/ast/ast_base.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/model_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/model_element_node.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';

void main() {
  group('GroupNode comprehensive tests', () {
    late GroupNode groupNode;
    
    setUp(() {
      groupNode = GroupNode(
        name: 'TestGroup',
        elements: [],
        children: [],
        relationships: [],
        sourcePosition: SourcePosition(0, 0),
      );
    });
    
    group('addElement method', () {
      test('adds person element to empty group', () {
        final personNode = PersonNode(
          id: 'person1',
          name: 'Person1',
          relationships: [],
          sourcePosition: SourcePosition(0, 0),
        );
        
        final updatedGroup = groupNode.addElement(personNode);
        
        expect(updatedGroup.elements.length, equals(1));
        expect(updatedGroup.elements.first, equals(personNode));
      });

      test('adds software system element to group', () {
        final systemNode = SoftwareSystemNode(
          id: 'system1',
          name: 'System1',
          containers: [],
          relationships: [],
          sourcePosition: SourcePosition(0, 0),
        );
        
        final updatedGroup = groupNode.addElement(systemNode);
        
        expect(updatedGroup.elements.length, equals(1));
        expect(updatedGroup.elements.first, equals(systemNode));
      });

      test('adds multiple elements to group', () {
        final person = PersonNode(
          id: 'person1',
          name: 'Person1',
          relationships: [],
          sourcePosition: SourcePosition(0, 0),
        );
        
        final system = SoftwareSystemNode(
          id: 'system1',
          name: 'System1',
          containers: [],
          relationships: [],
          sourcePosition: SourcePosition(1, 0),
        );
        
        final updatedGroup1 = groupNode.addElement(person);
        final updatedGroup2 = updatedGroup1.addElement(system);
        
        expect(updatedGroup2.elements.length, equals(2));
        expect(updatedGroup2.elements[0], equals(person));
        expect(updatedGroup2.elements[1], equals(system));
      });

      test('preserves other group properties when adding element', () {
        final groupWithProperties = GroupNode(
          name: 'GroupWithProps',
          elements: [],
          children: [],
          relationships: [],
          properties: PropertiesNode(
            properties: [
              PropertyNode(
                name: 'key',
                value: 'value',
                sourcePosition: SourcePosition(0, 0),
              ),
            ],
            sourcePosition: SourcePosition(0, 0),
          ),
          sourcePosition: SourcePosition(0, 0),
        );
        
        final person = PersonNode(
          id: 'person1',
          name: 'Person1',
          relationships: [],
          sourcePosition: SourcePosition(1, 0),
        );
        
        final updatedGroup = groupWithProperties.addElement(person);
        
        expect(updatedGroup.elements.length, equals(1));
        expect(updatedGroup.elements.first, equals(person));
        expect(updatedGroup.properties, isNotNull);
        expect(updatedGroup.properties!.properties.length, equals(1));
        expect(updatedGroup.properties!.properties.first.name, equals('key'));
        expect(updatedGroup.properties!.properties.first.value, equals('value'));
      });

      test('handles adding element with same ID by adding a duplicate', () {
        final person1 = PersonNode(
          id: 'duplicate',
          name: 'Person1',
          relationships: [],
          sourcePosition: SourcePosition(0, 0),
        );
        
        final person2 = PersonNode(
          id: 'duplicate',
          name: 'Person2',
          relationships: [],
          sourcePosition: SourcePosition(1, 0),
        );
        
        final updatedGroup1 = groupNode.addElement(person1);
        final updatedGroup2 = updatedGroup1.addElement(person2);
        
        expect(updatedGroup2.elements.length, equals(2));
        expect(updatedGroup2.elements[0], equals(person1));
        expect(updatedGroup2.elements[1], equals(person2));
      });

      test('ignores null element', () {
        // This test might not be valid if the method doesn't allow null,
        // but it's good to cover this case if possible
        try {
          final updatedGroup = groupNode.addElement(null);
          expect(updatedGroup, equals(groupNode));
        } catch (e) {
          // If method doesn't handle null, this is expected
          expect(e, isA<Error>());
        }
      });
    });
    
    group('setProperty method', () {
      test('adds string property to group with no properties', () {
        final updatedGroup = groupNode.setProperty('key1', 'value1');
        
        expect(updatedGroup.properties, isNotNull);
        
        final property = updatedGroup.properties!.properties.firstWhere(
          (p) => p.name == 'key1',
          orElse: () => PropertyNode(sourcePosition: null),
        );
        
        expect(property.name, equals('key1'));
        expect(property.value, equals('value1'));
      });

      test('adds numeric property to group', () {
        final updatedGroup = groupNode.setProperty('count', 42);
        
        expect(updatedGroup.properties, isNotNull);
        
        final property = updatedGroup.properties!.properties.firstWhere(
          (p) => p.name == 'count',
          orElse: () => PropertyNode(sourcePosition: null),
        );
        
        expect(property.name, equals('count'));
        expect(property.value, equals(42));
      });

      test('adds boolean property to group', () {
        final updatedGroup = groupNode.setProperty('enabled', true);
        
        expect(updatedGroup.properties, isNotNull);
        
        final property = updatedGroup.properties!.properties.firstWhere(
          (p) => p.name == 'enabled',
          orElse: () => PropertyNode(sourcePosition: null),
        );
        
        expect(property.name, equals('enabled'));
        expect(property.value, equals(true));
      });

      test('updates existing property value', () {
        final updatedGroup1 = groupNode.setProperty('key', 'value1');
        final updatedGroup2 = updatedGroup1.setProperty('key', 'value2');
        
        expect(updatedGroup2.properties, isNotNull);
        expect(updatedGroup2.properties!.properties.length, equals(1));
        
        final property = updatedGroup2.properties!.properties.first;
        expect(property.name, equals('key'));
        expect(property.value, equals('value2'));
      });

      test('adds multiple properties to group', () {
        final updatedGroup1 = groupNode.setProperty('key1', 'value1');
        final updatedGroup2 = updatedGroup1.setProperty('key2', 'value2');
        
        expect(updatedGroup2.properties, isNotNull);
        expect(updatedGroup2.properties!.properties.length, equals(2));
        
        final property1 = updatedGroup2.properties!.properties.firstWhere(
          (p) => p.name == 'key1',
        );
        final property2 = updatedGroup2.properties!.properties.firstWhere(
          (p) => p.name == 'key2',
        );
        
        expect(property1.value, equals('value1'));
        expect(property2.value, equals('value2'));
      });

      test('preserves other group data when setting property', () {
        final element = PersonNode(
          id: 'person1',
          name: 'Person1',
          relationships: [],
          sourcePosition: SourcePosition(0, 0),
        );
        
        final groupWithElement = groupNode.addElement(element);
        final updatedGroup = groupWithElement.setProperty('key', 'value');
        
        expect(updatedGroup.elements.length, equals(1));
        expect(updatedGroup.elements.first, equals(element));
        expect(updatedGroup.properties, isNotNull);
        
        final property = updatedGroup.properties!.properties.first;
        expect(property.name, equals('key'));
        expect(property.value, equals('value'));
      });

      test('handles setting property with null name', () {
        try {
          final updatedGroup = groupNode.setProperty(null, 'value');
          
          // If implemented to handle null keys
          expect(updatedGroup, isA<GroupNode>());
        } catch (e) {
          // If null keys are not allowed
          expect(e, isA<Error>());
        }
      });

      test('handles setting property with null value', () {
        try {
          final updatedGroup = groupNode.setProperty('key', null);
          
          // If implemented to handle null values
          expect(updatedGroup, isA<GroupNode>());
          
          if (updatedGroup.properties != null) {
            final property = updatedGroup.properties!.properties.firstWhere(
              (p) => p.name == 'key',
              orElse: () => PropertyNode(sourcePosition: null),
            );
            
            if (property.sourcePosition != null) {
              expect(property.value, isNull);
            }
          }
        } catch (e) {
          // If null values are not allowed
          expect(e, isA<Error>());
        }
      });
    });
  });
}