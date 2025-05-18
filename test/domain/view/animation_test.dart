import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:logging/logging.dart';

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print(
        '[\u001b[32m\u001b[1m\u001b[40m\u001b[0m${record.level.name}] ${record.loggerName}: ${record.message}');
  });

  group('Animation tests', () {
    test('AnimationStep creation', () {
      const step = AnimationStep(
        order: 1,
        elements: ['element-1', 'element-2'],
        relationships: ['rel-1'],
      );

      expect(step.order, equals(1));
      expect(step.elements, contains('element-1'));
      expect(step.elements, contains('element-2'));
      expect(step.relationships, contains('rel-1'));
    });

    test('AnimationStep serialization roundtrip', () {
      const step = AnimationStep(
        order: 1,
        elements: ['element-1', 'element-2'],
        relationships: ['rel-1'],
      );

      final json = jsonEncode(step.toJson());
      final deserialized =
          AnimationStep.fromJson(jsonDecode(json) as Map<String, dynamic>);

      expect(deserialized.order, equals(step.order));
      expect(deserialized.elements, equals(step.elements));
      expect(deserialized.relationships, equals(step.relationships));
    });

    test('DynamicView with animation steps', () {
      const dynamicView = DynamicView(
        key: 'dynamic-view',
        elementId: 'container-1',
        title: 'Dynamic Diagram',
        description: 'Dynamic diagram showing sign-in process',
        animations: [
          AnimationStep(
            order: 1,
            elements: ['component-1'],
          ),
          AnimationStep(
            order: 2,
            elements: ['component-1', 'component-2'],
            relationships: ['rel-1'],
          ),
          AnimationStep(
            order: 3,
            elements: ['component-1', 'component-2', 'component-3'],
            relationships: ['rel-1', 'rel-2'],
          ),
        ],
      );

      expect(dynamicView.animations.length, equals(3));

      // Step order should be sequential
      expect(dynamicView.animations[0].order, equals(1));
      expect(dynamicView.animations[1].order, equals(2));
      expect(dynamicView.animations[2].order, equals(3));

      // Each step should include more elements/relationships
      expect(dynamicView.animations[0].elements.length, equals(1));
      expect(dynamicView.animations[1].elements.length, equals(2));
      expect(dynamicView.animations[2].elements.length, equals(3));

      expect(dynamicView.animations[0].relationships.length, equals(0));
      expect(dynamicView.animations[1].relationships.length, equals(1));
      expect(dynamicView.animations[2].relationships.length, equals(2));
    });

    test('DynamicView serialization with animations', () {
      const dynamicView = DynamicView(
        key: 'dynamic-view',
        elementId: 'container-1',
        title: 'Dynamic Diagram',
        description: 'Dynamic diagram showing sign-in process',
        autoAnimationInterval: true,
        animations: [
          AnimationStep(
            order: 1,
            elements: ['component-1'],
          ),
          AnimationStep(
            order: 2,
            elements: ['component-1', 'component-2'],
            relationships: ['rel-1'],
          ),
        ],
      );

      final json = jsonEncode(dynamicView.toJson());
      final deserialized =
          DynamicView.fromJson(jsonDecode(json) as Map<String, dynamic>);

      expect(deserialized.key, equals(dynamicView.key));
      expect(deserialized.elementId, equals(dynamicView.elementId));
      expect(deserialized.autoAnimationInterval, isTrue);
      expect(deserialized.animations.length, equals(2));

      // Check animations were properly serialized
      expect(deserialized.animations[0].order, equals(1));
      expect(deserialized.animations[0].elements, equals(['component-1']));
      expect(deserialized.animations[0].relationships, isEmpty);

      expect(deserialized.animations[1].order, equals(2));
      expect(deserialized.animations[1].elements,
          equals(['component-1', 'component-2']));
      expect(deserialized.animations[1].relationships, equals(['rel-1']));
    });

    test('DynamicView progressive relationship addition', () {
      // Create elements and relationships for the view
      final elements = [
        const ElementView(id: 'component-1', x: 100, y: 100),
        const ElementView(id: 'component-2', x: 300, y: 100),
        const ElementView(id: 'component-3', x: 500, y: 100),
      ];

      final relationships = [
        const RelationshipView(id: 'rel-1', order: '1'),
        const RelationshipView(id: 'rel-2', order: '2'),
        const RelationshipView(id: 'rel-3', order: '3'),
      ];

      // Create dynamic view
      final dynamicView = DynamicView(
        key: 'dynamic-view',
        elementId: 'container-1',
        title: 'Dynamic Diagram',
        description: 'Dynamic diagram showing sign-in process',
        elements: elements,
        relationships: relationships,
        animations: [
          const AnimationStep(
            order: 1,
            elements: ['component-1'],
            relationships: [],
          ),
          const AnimationStep(
            order: 2,
            elements: ['component-1', 'component-2'],
            relationships: ['rel-1'],
          ),
          const AnimationStep(
            order: 3,
            elements: ['component-1', 'component-2', 'component-3'],
            relationships: ['rel-1', 'rel-2'],
          ),
          const AnimationStep(
            order: 4,
            elements: ['component-1', 'component-2', 'component-3'],
            relationships: ['rel-1', 'rel-2', 'rel-3'],
          ),
        ],
      );

      // Serialize and deserialize to verify animation steps are preserved
      final json = jsonEncode(dynamicView.toJson());
      final deserialized =
          DynamicView.fromJson(jsonDecode(json) as Map<String, dynamic>);

      // Verify animations
      expect(deserialized.animations.length, equals(4));

      // First step: Only component-1, no relationships
      expect(deserialized.animations[0].elements, equals(['component-1']));
      expect(deserialized.animations[0].relationships, isEmpty);

      // Second step: component-1 and component-2, rel-1
      expect(deserialized.animations[1].elements,
          containsAll(['component-1', 'component-2']));
      expect(deserialized.animations[1].relationships, equals(['rel-1']));

      // Third step: All components, rel-1 and rel-2
      expect(deserialized.animations[2].elements,
          containsAll(['component-1', 'component-2', 'component-3']));
      expect(
          deserialized.animations[2].relationships, equals(['rel-1', 'rel-2']));

      // Fourth step: All components, all relationships
      expect(deserialized.animations[3].elements,
          containsAll(['component-1', 'component-2', 'component-3']));
      expect(deserialized.animations[3].relationships,
          containsAll(['rel-1', 'rel-2', 'rel-3']));
    });

    test('Relationship order in dynamic views', () {
      // Create relationships with explicit order
      final relationships = [
        const RelationshipView(id: 'rel-1', order: '1'),
        const RelationshipView(id: 'rel-2', order: '2'),
        const RelationshipView(id: 'rel-3', order: '3'),
        const RelationshipView(id: 'rel-4', order: '1.1'), // Between 1 and 2
      ];

      // Create dynamic view
      final dynamicView = DynamicView(
        key: 'dynamic-view',
        elementId: 'container-1',
        relationships: relationships,
      );

      final json = jsonEncode(dynamicView.toJson());
      final deserialized =
          DynamicView.fromJson(jsonDecode(json) as Map<String, dynamic>);

      // Verify relationship orders are preserved
      expect(deserialized.relationships[0].order, equals('1'));
      expect(deserialized.relationships[1].order, equals('2'));
      expect(deserialized.relationships[2].order, equals('3'));
      expect(deserialized.relationships[3].order, equals('1.1'));
    });
  });
}
