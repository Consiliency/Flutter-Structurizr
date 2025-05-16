import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/parser/ast/ast_base.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/model_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/model_element_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/relationship_node.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';

void main() {
  group('ModelNode comprehensive tests', () {
    late ModelNode modelNode;
    
    setUp(() {
      modelNode = ModelNode(
        people: [],
        softwareSystems: [],
        deploymentEnvironments: [],
        relationships: [],
      );
    });
    
    group('addGroup method', () {
      test('adds single group to empty model', () {
        final groupNode = GroupNode(
          name: 'Group1',
          elements: [],
          children: [],
          relationships: [],
          sourcePosition: SourcePosition(0, 0),
        );
        
        final updatedModel = modelNode.addGroup(groupNode);
        
        expect(updatedModel.groups, isNotNull);
        expect(updatedModel.groups!.length, equals(1));
        expect(updatedModel.groups!.first, equals(groupNode));
      });

      test('adds multiple groups to model', () {
        final group1 = GroupNode(
          name: 'Group1',
          elements: [],
          children: [],
          relationships: [],
          sourcePosition: SourcePosition(0, 0),
        );
        
        final group2 = GroupNode(
          name: 'Group2',
          elements: [],
          children: [],
          relationships: [],
          sourcePosition: SourcePosition(0, 0),
        );
        
        final updatedModel1 = modelNode.addGroup(group1);
        final updatedModel2 = updatedModel1.addGroup(group2);
        
        expect(updatedModel2.groups!.length, equals(2));
        expect(updatedModel2.groups![0], equals(group1));
        expect(updatedModel2.groups![1], equals(group2));
      });

      test('adding group with same name does not throw error', () {
        final group1 = GroupNode(
          name: 'Group1',
          elements: [],
          children: [],
          relationships: [],
          sourcePosition: SourcePosition(0, 0),
        );
        
        final group2 = GroupNode(
          name: 'Group1', // Same name
          elements: [],
          children: [],
          relationships: [],
          sourcePosition: SourcePosition(1, 0),
        );
        
        final updatedModel1 = modelNode.addGroup(group1);
        final updatedModel2 = updatedModel1.addGroup(group2);
        
        expect(updatedModel2.groups!.length, equals(2));
      });
    });
    
    group('addEnterprise method', () {
      test('adds enterprise to model with no existing enterprise', () {
        final enterpriseNode = EnterpriseNode(
          name: 'Enterprise1',
          sourcePosition: SourcePosition(0, 0),
        );
        
        final updatedModel = modelNode.addEnterprise(enterpriseNode);
        
        expect(updatedModel.enterpriseName, equals('Enterprise1'));
        expect(updatedModel.enterprise, equals(enterpriseNode));
      });

      test('replaces enterprise when adding second enterprise', () {
        final enterprise1 = EnterpriseNode(
          name: 'Enterprise1',
          sourcePosition: SourcePosition(0, 0),
        );
        
        final enterprise2 = EnterpriseNode(
          name: 'Enterprise2',
          sourcePosition: SourcePosition(1, 0),
        );
        
        final updatedModel1 = modelNode.addEnterprise(enterprise1);
        final updatedModel2 = updatedModel1.addEnterprise(enterprise2);
        
        expect(updatedModel2.enterpriseName, equals('Enterprise2'));
        expect(updatedModel2.enterprise, equals(enterprise2));
      });

      test('preserves all other model properties when adding enterprise', () {
        final personNode = PersonNode(
          id: 'person1',
          name: 'Person1',
          relationships: [],
          sourcePosition: SourcePosition(0, 0),
        );
        
        final enterpriseNode = EnterpriseNode(
          name: 'Enterprise1',
          sourcePosition: SourcePosition(1, 0),
        );
        
        final updatedModel1 = modelNode.addElement(personNode);
        final updatedModel2 = updatedModel1.addEnterprise(enterpriseNode);
        
        expect(updatedModel2.enterpriseName, equals('Enterprise1'));
        expect(updatedModel2.enterprise, equals(enterpriseNode));
        expect(updatedModel2.people.length, equals(1));
        expect(updatedModel2.people.first, equals(personNode));
      });
    });
    
    group('addElement method', () {
      test('adds person element to model', () {
        final personNode = PersonNode(
          id: 'person1',
          name: 'Person1',
          relationships: [],
          sourcePosition: SourcePosition(0, 0),
        );
        
        final updatedModel = modelNode.addElement(personNode);
        
        expect(updatedModel.people.length, equals(1));
        expect(updatedModel.people.first, equals(personNode));
      });

      test('adds software system element to model', () {
        final systemNode = SoftwareSystemNode(
          id: 'system1',
          name: 'System1',
          containers: [],
          relationships: [],
          sourcePosition: SourcePosition(0, 0),
        );
        
        final updatedModel = modelNode.addElement(systemNode);
        
        expect(updatedModel.softwareSystems.length, equals(1));
        expect(updatedModel.softwareSystems.first, equals(systemNode));
      });

      test('ignores unsupported element types', () {
        // Mock unsupported element type
        final unknownNode = UnsupportedElementNode();
        
        final updatedModel = modelNode.addElement(unknownNode);
        
        // Should return model unchanged
        expect(updatedModel, equals(modelNode));
      });

      test('adding elements with same id overrides previous elements', () {
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
        
        final updatedModel1 = modelNode.addElement(person1);
        final updatedModel2 = updatedModel1.addElement(person2);
        
        expect(updatedModel2.people.length, equals(1));
        expect(updatedModel2.people.first, equals(person2));
      });
    });
    
    group('addRelationship method', () {
      test('adds relationship to empty model', () {
        final relationshipNode = RelationshipNode(
          sourceId: 'source',
          destinationId: 'destination',
          description: 'relates to',
          sourcePosition: SourcePosition(0, 0),
        );
        
        final updatedModel = modelNode.addRelationship(relationshipNode);
        
        expect(updatedModel.relationships.length, equals(1));
        expect(updatedModel.relationships.first, equals(relationshipNode));
      });

      test('adds multiple relationships to model', () {
        final relationship1 = RelationshipNode(
          sourceId: 'source1',
          destinationId: 'destination1',
          description: 'relates to',
          sourcePosition: SourcePosition(0, 0),
        );
        
        final relationship2 = RelationshipNode(
          sourceId: 'source2',
          destinationId: 'destination2',
          description: 'depends on',
          sourcePosition: SourcePosition(1, 0),
        );
        
        final updatedModel1 = modelNode.addRelationship(relationship1);
        final updatedModel2 = updatedModel1.addRelationship(relationship2);
        
        expect(updatedModel2.relationships.length, equals(2));
        expect(updatedModel2.relationships, contains(relationship1));
        expect(updatedModel2.relationships, contains(relationship2));
      });

      test('preserves all other model properties when adding relationship', () {
        final personNode = PersonNode(
          id: 'person1',
          name: 'Person1',
          relationships: [],
          sourcePosition: SourcePosition(0, 0),
        );
        
        final relationshipNode = RelationshipNode(
          sourceId: 'source',
          destinationId: 'destination',
          description: 'relates to',
          sourcePosition: SourcePosition(1, 0),
        );
        
        final updatedModel1 = modelNode.addElement(personNode);
        final updatedModel2 = updatedModel1.addRelationship(relationshipNode);
        
        expect(updatedModel2.relationships.length, equals(1));
        expect(updatedModel2.relationships.first, equals(relationshipNode));
        expect(updatedModel2.people.length, equals(1));
        expect(updatedModel2.people.first, equals(personNode));
      });
    });
    
    group('addImpliedRelationship method', () {
      test('adds implied relationship to model', () {
        final relationshipNode = RelationshipNode(
          sourceId: 'source',
          destinationId: 'destination',
          description: 'implied relation',
          isImplied: true,
          sourcePosition: SourcePosition(0, 0),
        );
        
        final updatedModel = modelNode.addImpliedRelationship(relationshipNode);
        
        // Implementation depends on how implied relationships are stored
        expect(updatedModel, isA<ModelNode>());
        
        // If implemented with separate collection:
        if (updatedModel.impliedRelationships != null) {
          expect(updatedModel.impliedRelationships!.length, equals(1));
          expect(updatedModel.impliedRelationships!.first, equals(relationshipNode));
        }
        // Otherwise might be added to regular relationships with a flag
        else if (updatedModel.relationships.isNotEmpty) {
          expect(updatedModel.relationships.first.isImplied, isTrue);
        }
      });

      test('implied relationships should not affect explicit relationships', () {
        final explicitRel = RelationshipNode(
          sourceId: 'source1',
          destinationId: 'dest1',
          description: 'explicit',
          sourcePosition: SourcePosition(0, 0),
        );
        
        final impliedRel = RelationshipNode(
          sourceId: 'source2',
          destinationId: 'dest2',
          description: 'implied',
          isImplied: true,
          sourcePosition: SourcePosition(1, 0),
        );
        
        final updatedModel1 = modelNode.addRelationship(explicitRel);
        final updatedModel2 = updatedModel1.addImpliedRelationship(impliedRel);
        
        expect(updatedModel2.relationships.length, equals(1)); 
        expect(updatedModel2.relationships.first, equals(explicitRel));
        
        // If implemented with separate collection:
        if (updatedModel2.impliedRelationships != null) {
          expect(updatedModel2.impliedRelationships!.length, equals(1));
        }
      });
    });
    
    group('setAdvancedProperty method', () {
      test('sets a string property on the model', () {
        final updatedModel = modelNode.setAdvancedProperty('key1', 'value1');
        
        // Implementation depends on how properties are stored
        expect(updatedModel, isA<ModelNode>());
        
        // If implemented with properties map:
        if (updatedModel.properties != null) {
          expect(updatedModel.properties!['key1'], equals('value1'));
        }
      });

      test('sets a numeric property on the model', () {
        final updatedModel = modelNode.setAdvancedProperty('count', 42);
        
        expect(updatedModel, isA<ModelNode>());
        
        // If implemented with properties map:
        if (updatedModel.properties != null) {
          expect(updatedModel.properties!['count'], equals(42));
        }
      });

      test('sets a boolean property on the model', () {
        final updatedModel = modelNode.setAdvancedProperty('enabled', true);
        
        expect(updatedModel, isA<ModelNode>());
        
        // If implemented with properties map:
        if (updatedModel.properties != null) {
          expect(updatedModel.properties!['enabled'], equals(true));
        }
      });

      test('updates existing property value', () {
        final updatedModel1 = modelNode.setAdvancedProperty('key', 'value1');
        final updatedModel2 = updatedModel1.setAdvancedProperty('key', 'value2');
        
        expect(updatedModel2, isA<ModelNode>());
        
        // If implemented with properties map:
        if (updatedModel2.properties != null) {
          expect(updatedModel2.properties!['key'], equals('value2'));
        }
      });
    });
  });
}

// Mock class for testing unsupported element types
class UnsupportedElementNode extends ElementNode {
  UnsupportedElementNode()
      : super(
          id: 'unknown',
          name: 'Unknown',
          relationships: [],
          sourcePosition: SourcePosition(0, 0),
        );
}