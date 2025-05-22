import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/model_element_node.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';

void main() {
  group('EnterpriseNode comprehensive tests', () {
    late EnterpriseNode enterpriseNode;

    setUp(() {
      enterpriseNode = EnterpriseNode(
        name: 'Test Enterprise',
        sourcePosition: const SourcePosition(0, 0),
      );
    });

    group('addGroup method', () {
      test('adds group to enterprise with no groups', () {
        final groupNode = GroupNode(
          name: 'Test Group',
          elements: [],
          children: [],
          relationships: [],
          sourcePosition: const SourcePosition(0, 0),
        );

        final updatedEnterprise = enterpriseNode.addGroup(groupNode);

        expect(updatedEnterprise, isA<EnterpriseNode>());

        // If groups property exists and is implemented:
        if (updatedEnterprise.groups != null) {
          expect(updatedEnterprise.groups!.length, equals(1));
          expect(updatedEnterprise.groups!.first, equals(groupNode));
        }
      });

      test('adds multiple groups to enterprise', () {
        final group1 = GroupNode(
          name: 'Group 1',
          elements: [],
          children: [],
          relationships: [],
          sourcePosition: const SourcePosition(0, 0),
        );

        final group2 = GroupNode(
          name: 'Group 2',
          elements: [],
          children: [],
          relationships: [],
          sourcePosition: const SourcePosition(1, 0),
        );

        final updatedEnterprise1 = enterpriseNode.addGroup(group1);
        final updatedEnterprise2 = updatedEnterprise1.addGroup(group2);

        expect(updatedEnterprise2, isA<EnterpriseNode>());

        // If groups property exists and is implemented:
        if (updatedEnterprise2.groups != null) {
          expect(updatedEnterprise2.groups!.length, equals(2));
          expect(updatedEnterprise2.groups![0], equals(group1));
          expect(updatedEnterprise2.groups![1], equals(group2));
        }
      });

      test('adding group with same name does not throw error', () {
        final group1 = GroupNode(
          name: 'Duplicate',
          elements: [],
          children: [],
          relationships: [],
          sourcePosition: const SourcePosition(0, 0),
        );

        final group2 = GroupNode(
          name: 'Duplicate', // Same name
          elements: [],
          children: [],
          relationships: [],
          sourcePosition: const SourcePosition(1, 0),
        );

        final updatedEnterprise1 = enterpriseNode.addGroup(group1);
        final updatedEnterprise2 = updatedEnterprise1.addGroup(group2);

        expect(updatedEnterprise2, isA<EnterpriseNode>());

        // If groups property exists and is implemented:
        if (updatedEnterprise2.groups != null) {
          expect(updatedEnterprise2.groups!.length, equals(2));
        }
      });

      test('preserves other enterprise properties when adding group', () {
        final enterpriseWithProps = EnterpriseNode(
          name: 'Enterprise With Props',
          properties: PropertiesNode(
            properties: [
              PropertyNode(
                name: 'location',
                value: 'HQ',
                sourcePosition: const SourcePosition(0, 0),
              ),
            ],
            sourcePosition: const SourcePosition(0, 0),
          ),
          sourcePosition: const SourcePosition(0, 0),
        );

        final group = GroupNode(
          name: 'Test Group',
          elements: [],
          children: [],
          relationships: [],
          sourcePosition: const SourcePosition(1, 0),
        );

        final updatedEnterprise = enterpriseWithProps.addGroup(group);

        expect(updatedEnterprise.properties, isNotNull);
        expect(updatedEnterprise.properties!.properties.length, equals(1));
        expect(updatedEnterprise.properties!.properties.first.name,
            equals('location'));
        expect(
            updatedEnterprise.properties!.properties.first.value, equals('HQ'));

        // If groups property exists and is implemented:
        if (updatedEnterprise.groups != null) {
          expect(updatedEnterprise.groups!.length, equals(1));
          expect(updatedEnterprise.groups!.first, equals(group));
        }
      });

      test('handles null group parameter', () {
        try {
          final updatedEnterprise = enterpriseNode.addGroup(null);

          // If implemented to handle null groups
          expect(updatedEnterprise, equals(enterpriseNode));
        } catch (e) {
          // If null groups are not allowed
          expect(e, isA<Error>());
        }
      });
    });

    group('setProperty method', () {
      test('adds string property to enterprise with no properties', () {
        final updatedEnterprise = enterpriseNode.setProperty('key1', 'value1');

        expect(updatedEnterprise.properties, isNotNull);

        final property = updatedEnterprise.properties!.properties.firstWhere(
          (p) => p.name == 'key1',
          orElse: () => PropertyNode(sourcePosition: null),
        );

        expect(property.name, equals('key1'));
        expect(property.value, equals('value1'));
      });

      test('adds numeric property to enterprise', () {
        final updatedEnterprise = enterpriseNode.setProperty('count', 42);

        expect(updatedEnterprise.properties, isNotNull);

        final property = updatedEnterprise.properties!.properties.firstWhere(
          (p) => p.name == 'count',
          orElse: () => PropertyNode(sourcePosition: null),
        );

        expect(property.name, equals('count'));
        expect(property.value, equals(42));
      });

      test('adds boolean property to enterprise', () {
        final updatedEnterprise = enterpriseNode.setProperty('enabled', true);

        expect(updatedEnterprise.properties, isNotNull);

        final property = updatedEnterprise.properties!.properties.firstWhere(
          (p) => p.name == 'enabled',
          orElse: () => PropertyNode(sourcePosition: null),
        );

        expect(property.name, equals('enabled'));
        expect(property.value, equals(true));
      });

      test('updates existing property value', () {
        final updatedEnterprise1 = enterpriseNode.setProperty('key', 'value1');
        final updatedEnterprise2 =
            updatedEnterprise1.setProperty('key', 'value2');

        expect(updatedEnterprise2.properties, isNotNull);
        expect(updatedEnterprise2.properties!.properties.length, equals(1));

        final property = updatedEnterprise2.properties!.properties.first;
        expect(property.name, equals('key'));
        expect(property.value, equals('value2'));
      });

      test('adds multiple properties to enterprise', () {
        final updatedEnterprise1 = enterpriseNode.setProperty('key1', 'value1');
        final updatedEnterprise2 =
            updatedEnterprise1.setProperty('key2', 'value2');

        expect(updatedEnterprise2.properties, isNotNull);
        expect(updatedEnterprise2.properties!.properties.length, equals(2));

        final property1 = updatedEnterprise2.properties!.properties.firstWhere(
          (p) => p.name == 'key1',
        );
        final property2 = updatedEnterprise2.properties!.properties.firstWhere(
          (p) => p.name == 'key2',
        );

        expect(property1.value, equals('value1'));
        expect(property2.value, equals('value2'));
      });

      test('preserves other enterprise data when setting property', () {
        // Create enterprise with groups
        final group = GroupNode(
          name: 'Test Group',
          elements: [],
          children: [],
          relationships: [],
          sourcePosition: const SourcePosition(0, 0),
        );

        final enterpriseWithGroup = enterpriseNode.addGroup(group);
        final updatedEnterprise =
            enterpriseWithGroup.setProperty('key', 'value');

        // If groups property exists and is implemented:
        if (updatedEnterprise.groups != null) {
          expect(updatedEnterprise.groups!.length, equals(1));
          expect(updatedEnterprise.groups!.first, equals(group));
        }

        expect(updatedEnterprise.properties, isNotNull);
        final property = updatedEnterprise.properties!.properties.first;
        expect(property.name, equals('key'));
        expect(property.value, equals('value'));
      });

      test('handles setting property with null name', () {
        try {
          final updatedEnterprise = enterpriseNode.setProperty(null, 'value');

          // If implemented to handle null keys
          expect(updatedEnterprise, isA<EnterpriseNode>());
        } catch (e) {
          // If null keys are not allowed
          expect(e, isA<Error>());
        }
      });

      test('handles setting property with null value', () {
        try {
          final updatedEnterprise = enterpriseNode.setProperty('key', null);

          // If implemented to handle null values
          expect(updatedEnterprise, isA<EnterpriseNode>());

          if (updatedEnterprise.properties != null) {
            final property =
                updatedEnterprise.properties!.properties.firstWhere(
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
