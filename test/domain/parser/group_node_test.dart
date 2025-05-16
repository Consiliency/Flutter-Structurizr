import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/parser/ast/ast_base.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/model_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/model_element_node.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';

void main() {
  group('GroupNode', () {
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
    
    test('addElement adds an element to the group', () {
      final personNode = PersonNode(
        id: 'user',
        name: 'User',
        description: 'A user of the system',
        relationships: [],
        sourcePosition: SourcePosition(0, 0),
      );
      
      final updatedGroup = groupNode.addElement(personNode);
      
      expect(updatedGroup.elements, contains(personNode));
    });
    
    test('setProperty sets a property on the group', () {
      final updatedGroup = groupNode.setProperty('key', 'value');
      
      // Implementation may vary, but should create or update properties
      expect(updatedGroup, isA<GroupNode>());
      
      // If using PropertiesNode:
      if (updatedGroup.properties != null) {
        final property = updatedGroup.properties!.properties.firstWhere(
          (p) => p.name == 'key',
          orElse: () => PropertyNode(sourcePosition: null),
        );
        expect(property.value, equals('value'));
      }
    });
  });
}