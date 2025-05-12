import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/domain/view/views.dart';
import 'package:flutter_structurizr/infrastructure/serialization/json_serialization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';

void main() {
  group('View serialization tests', () {
    late SystemContextView systemContextView;
    late ContainerView containerView;
    late ComponentView componentView;
    late DynamicView dynamicView;
    late DeploymentView deploymentView;
    late Views views;
    
    setUp(() {
      // Create system context view
      systemContextView = SystemContextView(
        key: 'system-context',
        softwareSystemId: 'system-1',
        title: 'System Context Diagram',
        description: 'System context diagram for the banking system',
        elements: [
          ElementView(id: 'system-1', x: 100, y: 100, width: 200, height: 150),
          ElementView(id: 'person-1', x: 400, y: 100, width: 150, height: 100),
        ],
        relationships: [
          RelationshipView(id: 'rel-1', position: 50),
        ],
        automaticLayout: AutomaticLayout(
          implementation: 'ForceDirected',
          rankDirection: 'TopBottom',
        ),
      );
      
      // Create container view
      containerView = ContainerView(
        key: 'container-view',
        softwareSystemId: 'system-1',
        title: 'Container Diagram',
        description: 'Container diagram for the banking system',
        elements: [
          ElementView(id: 'container-1', x: 100, y: 100, width: 200, height: 150),
          ElementView(id: 'container-2', x: 400, y: 100, width: 200, height: 150),
        ],
        relationships: [
          RelationshipView(id: 'rel-2', position: 50),
        ],
        externalSoftwareSystemBoundariesVisible: true,
      );
      
      // Create component view
      componentView = ComponentView(
        key: 'component-view',
        softwareSystemId: 'system-1',
        containerId: 'container-1',
        title: 'Component Diagram',
        description: 'Component diagram for the web application',
        elements: [
          ElementView(id: 'component-1', x: 100, y: 100, width: 150, height: 100),
          ElementView(id: 'component-2', x: 300, y: 100, width: 150, height: 100),
        ],
        relationships: [
          RelationshipView(id: 'rel-3', position: 50),
        ],
        externalContainerBoundariesVisible: true,
      );
      
      // Create dynamic view
      dynamicView = DynamicView(
        key: 'dynamic-view',
        elementId: 'container-1',
        title: 'Dynamic Diagram',
        description: 'Dynamic diagram for the sign-in process',
        elements: [
          ElementView(id: 'component-1'),
          ElementView(id: 'component-2'),
        ],
        relationships: [
          RelationshipView(id: 'rel-3', order: '1'),
          RelationshipView(id: 'rel-4', order: '2'),
        ],
        animations: [
          AnimationStep(order: 1, elements: ['component-1']),
          AnimationStep(
            order: 2, 
            elements: ['component-1', 'component-2'],
            relationships: ['rel-3'],
          ),
          AnimationStep(
            order: 3, 
            elements: ['component-1', 'component-2'],
            relationships: ['rel-3', 'rel-4'],
          ),
        ],
      );
      
      // Create deployment view
      deploymentView = DeploymentView(
        key: 'deployment-view',
        softwareSystemId: 'system-1',
        environment: 'Production',
        title: 'Deployment Diagram',
        description: 'Deployment diagram for the banking system',
        elements: [
          ElementView(id: 'node-1', x: 100, y: 100, width: 300, height: 200),
          ElementView(id: 'container-instance-1', x: 150, y: 150, width: 150, height: 100),
        ],
        relationships: [
          RelationshipView(id: 'rel-5', position: 50),
        ],
      );
      
      // Create views collection
      views = Views(
        systemContextViews: [systemContextView],
        containerViews: [containerView],
        componentViews: [componentView],
        dynamicViews: [dynamicView],
        deploymentViews: [deploymentView],
        configuration: ViewConfiguration(
          defaultView: 'system-context',
          lastModifiedDate: DateTime(2023, 1, 1),
          properties: {'theme': 'default'},
          terminology: Terminology(
            person: 'User',
            softwareSystem: 'System',
          ),
        ),
      );
    });
    
    test('SystemContextView serialization roundtrip', () {
      final json = jsonEncode(systemContextView.toJson());
      final deserialized = SystemContextView.fromJson(jsonDecode(json));
      
      expect(deserialized.key, equals(systemContextView.key));
      expect(deserialized.softwareSystemId, equals(systemContextView.softwareSystemId));
      expect(deserialized.title, equals(systemContextView.title));
      expect(deserialized.description, equals(systemContextView.description));
      expect(deserialized.elements.length, equals(systemContextView.elements.length));
      expect(deserialized.relationships.length, equals(systemContextView.relationships.length));
      expect(deserialized.automaticLayout?.implementation, equals('ForceDirected'));
      expect(deserialized.automaticLayout?.rankDirection, equals('TopBottom'));
    });
    
    test('ContainerView serialization roundtrip', () {
      final json = jsonEncode(containerView.toJson());
      final deserialized = ContainerView.fromJson(jsonDecode(json));
      
      expect(deserialized.key, equals(containerView.key));
      expect(deserialized.softwareSystemId, equals(containerView.softwareSystemId));
      expect(deserialized.title, equals(containerView.title));
      expect(deserialized.description, equals(containerView.description));
      expect(deserialized.elements.length, equals(containerView.elements.length));
      expect(deserialized.relationships.length, equals(containerView.relationships.length));
      expect(deserialized.externalSoftwareSystemBoundariesVisible, isTrue);
    });
    
    test('ComponentView serialization roundtrip', () {
      final json = jsonEncode(componentView.toJson());
      final deserialized = ComponentView.fromJson(jsonDecode(json));
      
      expect(deserialized.key, equals(componentView.key));
      expect(deserialized.softwareSystemId, equals(componentView.softwareSystemId));
      expect(deserialized.containerId, equals(componentView.containerId));
      expect(deserialized.title, equals(componentView.title));
      expect(deserialized.description, equals(componentView.description));
      expect(deserialized.elements.length, equals(componentView.elements.length));
      expect(deserialized.relationships.length, equals(componentView.relationships.length));
      expect(deserialized.externalContainerBoundariesVisible, isTrue);
    });
    
    test('DynamicView serialization roundtrip', () {
      final json = jsonEncode(dynamicView.toJson());
      final deserialized = DynamicView.fromJson(jsonDecode(json));
      
      expect(deserialized.key, equals(dynamicView.key));
      expect(deserialized.elementId, equals(dynamicView.elementId));
      expect(deserialized.title, equals(dynamicView.title));
      expect(deserialized.description, equals(dynamicView.description));
      expect(deserialized.elements.length, equals(dynamicView.elements.length));
      expect(deserialized.relationships.length, equals(dynamicView.relationships.length));
      expect(deserialized.animations.length, equals(dynamicView.animations.length));
      
      // Check animation order
      expect(deserialized.animations[0].order, equals(1));
      expect(deserialized.animations[1].order, equals(2));
      expect(deserialized.animations[2].order, equals(3));
      
      // Check animation content
      expect(deserialized.animations[1].elements, contains('component-1'));
      expect(deserialized.animations[1].elements, contains('component-2'));
      expect(deserialized.animations[1].relationships, contains('rel-3'));
    });
    
    test('DeploymentView serialization roundtrip', () {
      final json = jsonEncode(deploymentView.toJson());
      final deserialized = DeploymentView.fromJson(jsonDecode(json));
      
      expect(deserialized.key, equals(deploymentView.key));
      expect(deserialized.softwareSystemId, equals(deploymentView.softwareSystemId));
      expect(deserialized.environment, equals(deploymentView.environment));
      expect(deserialized.title, equals(deploymentView.title));
      expect(deserialized.description, equals(deploymentView.description));
      expect(deserialized.elements.length, equals(deploymentView.elements.length));
      expect(deserialized.relationships.length, equals(deploymentView.relationships.length));
    });
    
    test('Views collection serialization roundtrip', () {
      final json = jsonEncode(views.toJson());
      final deserialized = Views.fromJson(jsonDecode(json));
      
      expect(deserialized.systemContextViews.length, equals(views.systemContextViews.length));
      expect(deserialized.containerViews.length, equals(views.containerViews.length));
      expect(deserialized.componentViews.length, equals(views.componentViews.length));
      expect(deserialized.dynamicViews.length, equals(views.dynamicViews.length));
      expect(deserialized.deploymentViews.length, equals(views.deploymentViews.length));
      
      // Check configuration
      expect(deserialized.configuration?.defaultView, equals('system-context'));
      expect(deserialized.configuration?.properties['theme'], equals('default'));
      expect(deserialized.configuration?.terminology?.person, equals('User'));
      expect(deserialized.configuration?.terminology?.softwareSystem, equals('System'));
    });
    
    test('Views methods', () {
      // Test getViewByKey method
      final foundView = views.getViewByKey('component-view');
      expect(foundView, isNotNull);
      expect(foundView?.key, equals('component-view'));
      expect(foundView?.viewType, equals('Component'));
      
      // Test non-existent view
      final nonExistentView = views.getViewByKey('non-existent');
      expect(nonExistentView, isNull);
      
      // Test containsViewWithKey method
      expect(views.containsViewWithKey('system-context'), isTrue);
      expect(views.containsViewWithKey('non-existent'), isFalse);
      
      // Test getAllViews method
      final allViews = views.getAllViews();
      expect(allViews.length, equals(5));
      expect(
        allViews.map((v) => v.key),
        containsAll([
          'system-context', 
          'container-view', 
          'component-view', 
          'dynamic-view', 
          'deployment-view'
        ]),
      );
    });
    
    test('Add views', () {
      // Create new filtered view
      final filteredView = FilteredView(
        key: 'filtered-view',
        baseViewKey: 'system-context',
        title: 'Filtered View',
        description: 'Filtered view showing only external dependencies',
        tags: ['External'],
      );
      
      // Add to views collection
      final updatedViews = views.addFilteredView(filteredView);
      
      // Test
      expect(updatedViews.filteredViews.length, equals(1));
      expect(updatedViews.filteredViews.first.key, equals('filtered-view'));
      expect(updatedViews.filteredViews.first.tags, contains('External'));
      
      // Test views count
      expect(updatedViews.getAllViews().length, equals(6));
    });
  });
}