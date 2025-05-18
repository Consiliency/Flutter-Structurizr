import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/view/view.dart';

void main() {
  group('View', () {
    test('creates view with required properties', () {
      const view = BaseView(
        key: 'test-view',
        viewType: 'SystemContext',
      );

      expect(view.key, equals('test-view'));
      expect(view.viewType, equals('SystemContext'));
      expect(view.title, isNull);
      expect(view.description, isNull);
      expect(view.elements, isEmpty);
      expect(view.relationships, isEmpty);
      expect(view.automaticLayout, isNull);
      expect(view.animations, isEmpty);
    });

    test('creates view with all properties', () {
      const element = ElementView(
        id: 'element-id',
        x: 100,
        y: 200,
      );

      const relationship = RelationshipView(
        id: 'relationship-id',
        description: 'Test relationship',
      );

      const automaticLayout = AutomaticLayout(
        implementation: 'ForceDirected',
        rankDirection: 'TopBottom',
      );

      const animationStep = AnimationStep(
        order: 1,
        elements: ['element-id'],
        relationships: ['relationship-id'],
      );

      const view = BaseView(
        key: 'test-view',
        title: 'Test View',
        description: 'A test view',
        elements: [element],
        relationships: [relationship],
        automaticLayout: automaticLayout,
        animations: [animationStep],
        viewType: 'SystemContext',
      );

      expect(view.key, equals('test-view'));
      expect(view.title, equals('Test View'));
      expect(view.description, equals('A test view'));
      expect(view.elements, hasLength(1));
      expect(view.elements[0].id, equals('element-id'));
      expect(view.relationships, hasLength(1));
      expect(view.relationships[0].id, equals('relationship-id'));
      expect(view.automaticLayout, equals(automaticLayout));
      expect(view.animations, hasLength(1));
      expect(view.animations[0].order, equals(1));
      expect(view.viewType, equals('SystemContext'));
    });

    test('adds element', () {
      const view = BaseView(
        key: 'test-view',
        viewType: 'SystemContext',
      );

      const element = ElementView(
        id: 'element-id',
        x: 100,
        y: 200,
      );

      final updatedView = view.addElement(element);

      expect(updatedView.elements, hasLength(1));
      expect(updatedView.elements[0].id, equals('element-id'));
    });

    test('adds relationship', () {
      const view = BaseView(
        key: 'test-view',
        viewType: 'SystemContext',
      );

      const relationship = RelationshipView(
        id: 'relationship-id',
        description: 'Test relationship',
      );

      final updatedView = view.addRelationship(relationship);

      expect(updatedView.relationships, hasLength(1));
      expect(updatedView.relationships[0].id, equals('relationship-id'));
    });

    test('checks if element is contained', () {
      const element = ElementView(
        id: 'element-id',
        x: 100,
        y: 200,
      );

      const view = BaseView(
        key: 'test-view',
        viewType: 'SystemContext',
        elements: [element],
      );

      expect(view.containsElement('element-id'), isTrue);
      expect(view.containsElement('non-existent-id'), isFalse);
    });

    test('checks if relationship is contained', () {
      const relationship = RelationshipView(
        id: 'relationship-id',
        description: 'Test relationship',
      );

      const view = BaseView(
        key: 'test-view',
        viewType: 'SystemContext',
        relationships: [relationship],
      );

      expect(view.containsRelationship('relationship-id'), isTrue);
      expect(view.containsRelationship('non-existent-id'), isFalse);
    });

    test('gets element by id', () {
      const element = ElementView(
        id: 'element-id',
        x: 100,
        y: 200,
      );

      const view = BaseView(
        key: 'test-view',
        viewType: 'SystemContext',
        elements: [element],
      );

      final foundElement = view.getElementById('element-id');

      expect(foundElement, equals(element));
      expect(view.getElementById('non-existent-id'), isNull);
    });

    test('gets relationship by id', () {
      const relationship = RelationshipView(
        id: 'relationship-id',
        description: 'Test relationship',
      );

      const view = BaseView(
        key: 'test-view',
        viewType: 'SystemContext',
        relationships: [relationship],
      );

      final foundRelationship = view.getRelationshipById('relationship-id');

      expect(foundRelationship, equals(relationship));
      expect(view.getRelationshipById('non-existent-id'), isNull);
    });
  });

  group('SystemContextView', () {
    test('creates system context view with required properties', () {
      const view = SystemContextView(
        key: 'test-context',
        softwareSystemId: 'system-id',
      );

      expect(view.key, equals('test-context'));
      expect(view.viewType, equals('SystemContext'));
      expect(view.softwareSystemId, equals('system-id'));
    });
  });

  group('ContainerView', () {
    test('creates container view with required properties', () {
      const view = ContainerView(
        key: 'test-container',
        softwareSystemId: 'system-id',
      );

      expect(view.key, equals('test-container'));
      expect(view.viewType, equals('Container'));
      expect(view.softwareSystemId, equals('system-id'));
      expect(view.externalSoftwareSystemBoundariesVisible, isFalse);
    });
  });

  group('ComponentView', () {
    test('creates component view with required properties', () {
      const view = ComponentView(
        key: 'test-component',
        softwareSystemId: 'system-id',
        containerId: 'container-id',
      );

      expect(view.key, equals('test-component'));
      expect(view.viewType, equals('Component'));
      expect(view.softwareSystemId, equals('system-id'));
      expect(view.containerId, equals('container-id'));
      expect(view.externalContainerBoundariesVisible, isFalse);
    });
  });

  group('DynamicView', () {
    test('creates dynamic view with required properties', () {
      const view = DynamicView(
        key: 'test-dynamic',
      );

      expect(view.key, equals('test-dynamic'));
      expect(view.viewType, equals('Dynamic'));
      expect(view.elementId, isNull);
      expect(view.autoAnimationInterval, isTrue);
    });
  });

  group('DeploymentView', () {
    test('creates deployment view with required properties', () {
      const view = DeploymentView(
        key: 'test-deployment',
        environment: 'Production',
      );

      expect(view.key, equals('test-deployment'));
      expect(view.viewType, equals('Deployment'));
      expect(view.environment, equals('Production'));
      expect(view.softwareSystemId, isNull);
    });
  });

  group('FilteredView', () {
    test('creates filtered view with required properties', () {
      const view = FilteredView(
        key: 'test-filtered',
        baseViewKey: 'base-view',
      );

      expect(view.key, equals('test-filtered'));
      expect(view.viewType, equals('Filtered'));
      expect(view.baseViewKey, equals('base-view'));
      expect(view.filterMode, isNull);
      expect(view.tags, isEmpty);
    });
  });

  group('ElementView', () {
    test('creates element view with required properties', () {
      const element = ElementView(
        id: 'element-id',
      );

      expect(element.id, equals('element-id'));
      expect(element.x, isNull);
      expect(element.y, isNull);
      expect(element.width, isNull);
      expect(element.height, isNull);
    });

    test('creates element view with all properties', () {
      const element = ElementView(
        id: 'element-id',
        x: 100,
        y: 200,
        width: 300,
        height: 150,
      );

      expect(element.id, equals('element-id'));
      expect(element.x, equals(100));
      expect(element.y, equals(200));
      expect(element.width, equals(300));
      expect(element.height, equals(150));
    });
  });

  group('RelationshipView', () {
    test('creates relationship view with required properties', () {
      const relationship = RelationshipView(
        id: 'relationship-id',
      );

      expect(relationship.id, equals('relationship-id'));
      expect(relationship.description, isNull);
      expect(relationship.order, isNull);
      expect(relationship.vertices, isEmpty);
      expect(relationship.position, isNull);
    });

    test('creates relationship view with all properties', () {
      const vertex1 = Vertex(x: 100, y: 100);
      const vertex2 = Vertex(x: 200, y: 200);

      const relationship = RelationshipView(
        id: 'relationship-id',
        description: 'Test relationship',
        order: '1',
        vertices: [vertex1, vertex2],
        position: 50,
      );

      expect(relationship.id, equals('relationship-id'));
      expect(relationship.description, equals('Test relationship'));
      expect(relationship.order, equals('1'));
      expect(relationship.vertices, hasLength(2));
      expect(relationship.vertices[0].x, equals(100));
      expect(relationship.vertices[1].x, equals(200));
      expect(relationship.position, equals(50));
    });
  });

  group('Vertex', () {
    test('creates vertex with required properties', () {
      const vertex = Vertex(x: 100, y: 200);

      expect(vertex.x, equals(100));
      expect(vertex.y, equals(200));
    });
  });

  group('AutomaticLayout', () {
    test('creates automatic layout with default values', () {
      const layout = AutomaticLayout();

      expect(layout.implementation, equals('ForceDirected'));
      expect(layout.rankDirection, isNull);
      expect(layout.rankSeparation, isNull);
      expect(layout.nodeSeparation, isNull);
      expect(layout.edgeSeparation, isNull);
    });

    test('creates automatic layout with all properties', () {
      const layout = AutomaticLayout(
        implementation: 'Graphviz',
        rankDirection: 'TopBottom',
        rankSeparation: 100,
        nodeSeparation: 50,
        edgeSeparation: 25,
      );

      expect(layout.implementation, equals('Graphviz'));
      expect(layout.rankDirection, equals('TopBottom'));
      expect(layout.rankSeparation, equals(100));
      expect(layout.nodeSeparation, equals(50));
      expect(layout.edgeSeparation, equals(25));
    });
  });

  group('AnimationStep', () {
    test('creates animation step with required properties', () {
      const step = AnimationStep(order: 1);

      expect(step.order, equals(1));
      expect(step.elements, isEmpty);
      expect(step.relationships, isEmpty);
    });

    test('creates animation step with all properties', () {
      const step = AnimationStep(
        order: 1,
        elements: ['element-1', 'element-2'],
        relationships: ['relationship-1'],
      );

      expect(step.order, equals(1));
      expect(step.elements, hasLength(2));
      expect(step.elements[0], equals('element-1'));
      expect(step.relationships, hasLength(1));
      expect(step.relationships[0], equals('relationship-1'));
    });
  });
}
