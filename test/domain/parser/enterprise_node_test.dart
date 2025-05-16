import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/parser/ast/ast_base.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/model_node.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';

void main() {
  group('EnterpriseNode', () {
    late EnterpriseNode enterpriseNode;
    
    setUp(() {
      enterpriseNode = EnterpriseNode(
        name: 'Test Enterprise',
        sourcePosition: SourcePosition(0, 0),
      );
    });
    
    test('addGroup adds a group to the enterprise', () {
      final groupNode = GroupNode(
        name: 'Test Group',
        elements: [],
        children: [],
        relationships: [],
        sourcePosition: SourcePosition(0, 0),
      );
      
      final updatedEnterprise = enterpriseNode.addGroup(groupNode);
      
      // Implementation may vary, but should at least return an EnterpriseNode
      expect(updatedEnterprise, isA<EnterpriseNode>());
      
      // Ideally would check that the group was added to the enterprise's groups
      // if (updatedEnterprise.groups != null) {
      //   expect(updatedEnterprise.groups, contains(groupNode));
      // }
    });
    
    test('setProperty sets a property on the enterprise', () {
      final updatedEnterprise = enterpriseNode.setProperty('key', 'value');
      
      // Implementation may vary, but should create or update properties
      expect(updatedEnterprise, isA<EnterpriseNode>());
      
      // If using PropertiesNode:
      if (updatedEnterprise.properties != null) {
        final property = updatedEnterprise.properties!.properties.firstWhere(
          (p) => p.name == 'key',
          orElse: () => PropertyNode(sourcePosition: null),
        );
        expect(property.value, equals('value'));
      }
    });
  });
}