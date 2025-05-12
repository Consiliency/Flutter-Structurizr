import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/domain/view/views.dart';

void main() {
  group('Views', () {
    test('creates views with default values', () {
      const views = Views();
      
      expect(views.systemLandscapeViews, isEmpty);
      expect(views.systemContextViews, isEmpty);
      expect(views.containerViews, isEmpty);
      expect(views.componentViews, isEmpty);
      expect(views.dynamicViews, isEmpty);
      expect(views.deploymentViews, isEmpty);
      expect(views.filteredViews, isEmpty);
      expect(views.configuration, isNull);
      expect(views.styles, isNull);
    });
    
    test('creates views with all properties', () {
      final systemLandscapeView = SystemLandscapeView(
        key: 'landscape',
        enterpriseName: 'Test Enterprise',
      );
      
      final systemContextView = SystemContextView(
        key: 'context',
        softwareSystemId: 'system-id',
      );
      
      final containerView = ContainerView(
        key: 'container',
        softwareSystemId: 'system-id',
      );
      
      final componentView = ComponentView(
        key: 'component',
        softwareSystemId: 'system-id',
        containerId: 'container-id',
      );
      
      final dynamicView = DynamicView(
        key: 'dynamic',
        elementId: 'element-id',
      );
      
      final deploymentView = DeploymentView(
        key: 'deployment',
        environment: 'Production',
      );
      
      final filteredView = FilteredView(
        key: 'filtered',
        baseViewKey: 'context',
      );
      
      final configuration = ViewConfiguration(
        defaultView: 'context',
      );
      
      const styles = Styles();
      
      final views = Views(
        systemLandscapeViews: [systemLandscapeView],
        systemContextViews: [systemContextView],
        containerViews: [containerView],
        componentViews: [componentView],
        dynamicViews: [dynamicView],
        deploymentViews: [deploymentView],
        filteredViews: [filteredView],
        configuration: configuration,
        styles: styles,
      );
      
      expect(views.systemLandscapeViews, hasLength(1));
      expect(views.systemContextViews, hasLength(1));
      expect(views.containerViews, hasLength(1));
      expect(views.componentViews, hasLength(1));
      expect(views.dynamicViews, hasLength(1));
      expect(views.deploymentViews, hasLength(1));
      expect(views.filteredViews, hasLength(1));
      expect(views.configuration, equals(configuration));
      expect(views.styles, equals(styles));
    });
    
    test('gets all views flattened', () {
      final systemLandscapeView = SystemLandscapeView(
        key: 'landscape',
        enterpriseName: 'Test Enterprise',
      );
      
      final systemContextView = SystemContextView(
        key: 'context',
        softwareSystemId: 'system-id',
      );
      
      final containerView = ContainerView(
        key: 'container',
        softwareSystemId: 'system-id',
      );
      
      final views = Views(
        systemLandscapeViews: [systemLandscapeView],
        systemContextViews: [systemContextView],
        containerViews: [containerView],
      );
      
      final allViews = views.getAllViews();
      
      expect(allViews, hasLength(3));
      expect(allViews[0], equals(systemLandscapeView));
      expect(allViews[1], equals(systemContextView));
      expect(allViews[2], equals(containerView));
    });
    
    test('gets view by key', () {
      final systemContextView = SystemContextView(
        key: 'context',
        softwareSystemId: 'system-id',
      );
      
      final views = Views(
        systemContextViews: [systemContextView],
      );
      
      final foundView = views.getViewByKey('context');
      
      expect(foundView, equals(systemContextView));
      expect(views.getViewByKey('non-existent'), isNull);
    });
    
    test('checks if view with key exists', () {
      final systemContextView = SystemContextView(
        key: 'context',
        softwareSystemId: 'system-id',
      );
      
      final views = Views(
        systemContextViews: [systemContextView],
      );
      
      expect(views.containsViewWithKey('context'), isTrue);
      expect(views.containsViewWithKey('non-existent'), isFalse);
    });
    
    test('adds system landscape view', () {
      const views = Views();
      
      final systemLandscapeView = SystemLandscapeView(
        key: 'landscape',
        enterpriseName: 'Test Enterprise',
      );
      
      final updatedViews = views.addSystemLandscapeView(systemLandscapeView);
      
      expect(updatedViews.systemLandscapeViews, hasLength(1));
      expect(updatedViews.systemLandscapeViews[0], equals(systemLandscapeView));
    });
    
    test('adds system context view', () {
      const views = Views();
      
      final systemContextView = SystemContextView(
        key: 'context',
        softwareSystemId: 'system-id',
      );
      
      final updatedViews = views.addSystemContextView(systemContextView);
      
      expect(updatedViews.systemContextViews, hasLength(1));
      expect(updatedViews.systemContextViews[0], equals(systemContextView));
    });
    
    test('adds container view', () {
      const views = Views();
      
      final containerView = ContainerView(
        key: 'container',
        softwareSystemId: 'system-id',
      );
      
      final updatedViews = views.addContainerView(containerView);
      
      expect(updatedViews.containerViews, hasLength(1));
      expect(updatedViews.containerViews[0], equals(containerView));
    });
    
    test('adds component view', () {
      const views = Views();
      
      final componentView = ComponentView(
        key: 'component',
        softwareSystemId: 'system-id',
        containerId: 'container-id',
      );
      
      final updatedViews = views.addComponentView(componentView);
      
      expect(updatedViews.componentViews, hasLength(1));
      expect(updatedViews.componentViews[0], equals(componentView));
    });
    
    test('adds dynamic view', () {
      const views = Views();
      
      final dynamicView = DynamicView(
        key: 'dynamic',
        elementId: 'element-id',
      );
      
      final updatedViews = views.addDynamicView(dynamicView);
      
      expect(updatedViews.dynamicViews, hasLength(1));
      expect(updatedViews.dynamicViews[0], equals(dynamicView));
    });
    
    test('adds deployment view', () {
      const views = Views();
      
      final deploymentView = DeploymentView(
        key: 'deployment',
        environment: 'Production',
      );
      
      final updatedViews = views.addDeploymentView(deploymentView);
      
      expect(updatedViews.deploymentViews, hasLength(1));
      expect(updatedViews.deploymentViews[0], equals(deploymentView));
    });
    
    test('adds filtered view', () {
      const views = Views();
      
      final filteredView = FilteredView(
        key: 'filtered',
        baseViewKey: 'context',
      );
      
      final updatedViews = views.addFilteredView(filteredView);
      
      expect(updatedViews.filteredViews, hasLength(1));
      expect(updatedViews.filteredViews[0], equals(filteredView));
    });
    
    test('updates styles', () {
      const views = Views();
      const styles = Styles();
      
      final updatedViews = views.updateStyles(styles);
      
      expect(updatedViews.styles, equals(styles));
    });
  });
  
  group('ViewConfiguration', () {
    test('creates view configuration with default values', () {
      const configuration = ViewConfiguration();
      
      expect(configuration.defaultView, isNull);
      expect(configuration.lastModifiedDate, isNull);
      expect(configuration.properties, isEmpty);
      expect(configuration.terminology, isNull);
    });
    
    test('creates view configuration with all properties', () {
      final lastModifiedDate = DateTime(2023, 1, 1);
      
      final terminology = Terminology(
        person: 'User',
        softwareSystem: 'System',
      );
      
      final configuration = ViewConfiguration(
        defaultView: 'context',
        lastModifiedDate: lastModifiedDate,
        properties: {'key': 'value'},
        terminology: terminology,
      );
      
      expect(configuration.defaultView, equals('context'));
      expect(configuration.lastModifiedDate, equals(lastModifiedDate));
      expect(configuration.properties, containsPair('key', 'value'));
      expect(configuration.terminology, equals(terminology));
    });
  });
  
  group('Terminology', () {
    test('creates terminology with default values (all null)', () {
      const terminology = Terminology();
      
      expect(terminology.person, isNull);
      expect(terminology.softwareSystem, isNull);
      expect(terminology.container, isNull);
      expect(terminology.component, isNull);
      expect(terminology.codeElement, isNull);
      expect(terminology.deploymentNode, isNull);
      expect(terminology.relationship, isNull);
      expect(terminology.enterprise, isNull);
    });
    
    test('creates terminology with all properties', () {
      const terminology = Terminology(
        person: 'User',
        softwareSystem: 'System',
        container: 'Module',
        component: 'Service',
        codeElement: 'Class',
        deploymentNode: 'Node',
        relationship: 'Connection',
        enterprise: 'Organization',
      );
      
      expect(terminology.person, equals('User'));
      expect(terminology.softwareSystem, equals('System'));
      expect(terminology.container, equals('Module'));
      expect(terminology.component, equals('Service'));
      expect(terminology.codeElement, equals('Class'));
      expect(terminology.deploymentNode, equals('Node'));
      expect(terminology.relationship, equals('Connection'));
      expect(terminology.enterprise, equals('Organization'));
    });
  });
}