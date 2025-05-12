import 'package:flutter/material.dart' hide Container, Element;
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/style/branding.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/domain/view/views.dart';
import 'package:flutter_structurizr/infrastructure/serialization/json_serialization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';

void main() {
  group('Complex model integration tests', () {
    late Workspace workspace;
    
    setUp(() {
      // Create a workspace with a complete model
      // 1. Create people
      final customer = Person.create(
        name: 'Customer',
        description: 'A customer of the bank',
        tags: ['Person', 'Customer', 'External'],
      );
      
      final backOfficeStaff = Person.create(
        name: 'Back Office Staff',
        description: 'Administration and support staff',
        tags: ['Person', 'Internal'],
      );
      
      // 2. Create software systems
      final internetBankingSystem = SoftwareSystem.create(
        name: 'Internet Banking System',
        description: 'Allows customers to view account balances and make payments',
        tags: ['SoftwareSystem', 'Internal'],
      );
      
      final mainframeBankingSystem = SoftwareSystem.create(
        name: 'Mainframe Banking System',
        description: 'Stores all core banking information',
        tags: ['SoftwareSystem', 'Internal', 'Legacy'],
      );
      
      final emailSystem = SoftwareSystem.create(
        name: 'E-mail System',
        description: 'Sends e-mails to customers',
        tags: ['SoftwareSystem', 'External'],
      );
      
      // 3. Create relationships between people and systems
      final customerWithRelationships = customer
          .addRelationship(
            destinationId: internetBankingSystem.id,
            description: 'Uses',
            technology: 'Web Browser',
            tags: ['Customer-System'],
          );
      
      final backOfficeStaffWithRelationships = backOfficeStaff
          .addRelationship(
            destinationId: mainframeBankingSystem.id,
            description: 'Uses',
            technology: 'Terminal',
            tags: ['Staff-System'],
          );
      
      // Add relationships between systems
      final internetBankingSystemWithRelationships = internetBankingSystem
          .addRelationship(
            destinationId: mainframeBankingSystem.id,
            description: 'Gets account information from',
            technology: 'JSON/HTTPS',
            tags: ['System-System'],
          )
          .addRelationship(
            destinationId: emailSystem.id,
            description: 'Sends e-mail using',
            technology: 'SMTP',
            tags: ['System-System'],
          );
      
      // 4. Create containers for the Internet Banking System
      final webApplication = Container.create(
        name: 'Web Application',
        description: 'Provides Internet Banking functionality via the web',
        parentId: internetBankingSystem.id,
        technology: 'Java and Spring MVC',
        tags: ['Container', 'WebApp'],
      );
      
      final apiApplication = Container.create(
        name: 'API Application',
        description: 'Provides Internet Banking functionality via API',
        parentId: internetBankingSystem.id,
        technology: 'Java and Spring Boot',
        tags: ['Container', 'API'],
      );
      
      final database = Container.create(
        name: 'Database',
        description: 'Stores user data, accounts, etc.',
        parentId: internetBankingSystem.id,
        technology: 'Oracle Database',
        tags: ['Container', 'Database'],
      );
      
      // 5. Create relationships between containers
      final webApplicationWithRelationships = webApplication
          .addRelationship(
            destinationId: apiApplication.id,
            description: 'Makes API calls to',
            technology: 'JSON/HTTPS',
          )
          .addRelationship(
            destinationId: database.id,
            description: 'Reads from and writes to',
            technology: 'JDBC',
          );
      
      final apiApplicationWithRelationships = apiApplication
          .addRelationship(
            destinationId: database.id,
            description: 'Reads from and writes to',
            technology: 'JDBC',
          )
          .addRelationship(
            destinationId: mainframeBankingSystem.id,
            description: 'Makes API calls to',
            technology: 'JSON/HTTPS',
          );
      
      // 6. Create components for the API Application
      final signinController = Component.create(
        name: 'Sign In Controller',
        description: 'Handles sign in requests',
        parentId: apiApplication.id,
        technology: 'Spring MVC Controller',
        tags: ['Component', 'Controller'],
      );
      
      final accountsController = Component.create(
        name: 'Accounts Controller',
        description: 'Provides accounts information',
        parentId: apiApplication.id,
        technology: 'Spring MVC Controller',
        tags: ['Component', 'Controller'],
      );
      
      final securityComponent = Component.create(
        name: 'Security Component',
        description: 'Provides authentication and authorization',
        parentId: apiApplication.id,
        technology: 'Spring Security',
        tags: ['Component', 'Security'],
      );
      
      // 7. Create relationships between components
      final signinControllerWithRelationships = signinController
          .addRelationship(
            destinationId: securityComponent.id,
            description: 'Uses',
            technology: 'Java Method Call',
          );
      
      final accountsControllerWithRelationships = accountsController
          .addRelationship(
            destinationId: securityComponent.id,
            description: 'Uses',
            technology: 'Java Method Call',
          )
          .addRelationship(
            destinationId: mainframeBankingSystem.id,
            description: 'Makes API calls to',
            technology: 'JSON/HTTPS',
          )
          .addRelationship(
            destinationId: database.id,
            description: 'Reads from and writes to',
            technology: 'JDBC',
          );
      
      // 8. Create deployment nodes
      final liveEnv = DeploymentNode.create(
        name: 'Live',
        environment: 'Live',
        description: 'Production environment',
        tags: ['DeploymentNode', 'Live'],
      );
      
      final awsNode = DeploymentNode.create(
        name: 'Amazon Web Services',
        environment: 'Live',
        description: 'AWS us-east-1',
        technology: 'Amazon Web Services',
        parentId: liveEnv.id,
        tags: ['DeploymentNode', 'AWS'],
      );
      
      final ec2Node = DeploymentNode.create(
        name: 'EC2',
        environment: 'Live',
        description: 'EC2 instances',
        technology: 'Amazon EC2',
        parentId: awsNode.id,
        tags: ['DeploymentNode', 'EC2'],
      );
      
      final rdsNode = DeploymentNode.create(
        name: 'RDS',
        environment: 'Live',
        description: 'RDS database instances',
        technology: 'Amazon RDS',
        parentId: awsNode.id,
        tags: ['DeploymentNode', 'RDS'],
      );
      
      // 9. Create container instances
      final webAppInstance = ContainerInstance.create(
        containerId: webApplication.id,
        parentId: ec2Node.id,
        instanceId: 1,
        tags: ['ContainerInstance', 'WebApp'],
      );
      
      final apiAppInstance = ContainerInstance.create(
        containerId: apiApplication.id,
        parentId: ec2Node.id,
        instanceId: 1,
        tags: ['ContainerInstance', 'API'],
      );
      
      final dbInstance = ContainerInstance.create(
        containerId: database.id,
        parentId: rdsNode.id,
        instanceId: 1,
        tags: ['ContainerInstance', 'Database'],
      );
      
      // 10. Add infrastructure nodes
      final loadBalancer = InfrastructureNode.create(
        name: 'Load Balancer',
        description: 'Routes traffic to web and API applications',
        technology: 'Elastic Load Balancer',
        parentId: awsNode.id,
        tags: ['InfrastructureNode', 'LoadBalancer'],
      );
      
      // 11. Create relationships in deployment view
      final loadBalancerWithRelationships = loadBalancer
          .addRelationship(
            destinationId: webAppInstance.id,
            description: 'Forwards web requests to',
            technology: 'HTTPS',
          )
          .addRelationship(
            destinationId: apiAppInstance.id,
            description: 'Forwards API requests to',
            technology: 'HTTPS',
          );
      
      final webAppInstanceWithRelationships = webAppInstance
          .addRelationship(
            destinationId: apiAppInstance.id,
            description: 'Makes API calls to',
            technology: 'JSON/HTTPS',
          );
      
      final apiAppInstanceWithRelationships = apiAppInstance
          .addRelationship(
            destinationId: dbInstance.id,
            description: 'Reads from and writes to',
            technology: 'JDBC',
          );
      
      // 12. Build the complete model
      // Add containers to system
      final internetBankingSystemWithContainers = internetBankingSystemWithRelationships
          .addContainer(webApplicationWithRelationships)
          .addContainer(apiApplicationWithRelationships.addComponent(signinControllerWithRelationships)
              .addComponent(accountsControllerWithRelationships)
              .addComponent(securityComponent))
          .addContainer(database);
      
      // Add infrastructure nodes and instances to deployment nodes
      final liveEnvWithNodes = liveEnv
          .addChildNode(awsNode
              .addChildNode(ec2Node
                  .addContainerInstance(webAppInstanceWithRelationships)
                  .addContainerInstance(apiAppInstanceWithRelationships))
              .addChildNode(rdsNode
                  .addContainerInstance(dbInstance))
              .addInfrastructureNode(loadBalancerWithRelationships));
      
      // Create the model
      final model = Model(
        enterpriseName: 'Big Bank plc',
        people: [customerWithRelationships, backOfficeStaffWithRelationships],
        softwareSystems: [internetBankingSystemWithContainers, mainframeBankingSystem, emailSystem],
        deploymentNodes: [liveEnvWithNodes],
      );
      
      // 13. Create views
      // System Landscape view
      final systemLandscapeView = SystemLandscapeView(
        key: 'SystemLandscape',
        description: 'System Landscape for Big Bank plc',
        title: 'System Landscape',
        elements: [
          ElementView(id: customer.id, x: 100, y: 100),
          ElementView(id: backOfficeStaff.id, x: 300, y: 100),
          ElementView(id: internetBankingSystem.id, x: 500, y: 200),
          ElementView(id: mainframeBankingSystem.id, x: 800, y: 200),
          ElementView(id: emailSystem.id, x: 500, y: 400),
        ],
        relationships: [
          RelationshipView(id: customerWithRelationships.relationships[0].id),
          RelationshipView(id: backOfficeStaffWithRelationships.relationships[0].id),
          RelationshipView(id: internetBankingSystemWithRelationships.relationships[0].id),
          RelationshipView(id: internetBankingSystemWithRelationships.relationships[1].id),
        ],
        automaticLayout: AutomaticLayout(
          implementation: 'ForceDirected',
          rankDirection: 'TopBottom',
        ),
      );
      
      // System Context view
      final systemContextView = SystemContextView(
        key: 'SystemContext',
        softwareSystemId: internetBankingSystem.id,
        description: 'System Context diagram for the Internet Banking System',
        title: 'Internet Banking System - System Context',
        elements: [
          ElementView(id: customer.id, x: 100, y: 200),
          ElementView(id: internetBankingSystem.id, x: 500, y: 200),
          ElementView(id: mainframeBankingSystem.id, x: 900, y: 200),
          ElementView(id: emailSystem.id, x: 500, y: 400),
        ],
        relationships: [
          RelationshipView(id: customerWithRelationships.relationships[0].id),
          RelationshipView(id: internetBankingSystemWithRelationships.relationships[0].id),
          RelationshipView(id: internetBankingSystemWithRelationships.relationships[1].id),
        ],
      );
      
      // Container view
      final containerView = ContainerView(
        key: 'Containers',
        softwareSystemId: internetBankingSystem.id,
        description: 'Container diagram for the Internet Banking System',
        title: 'Internet Banking System - Containers',
        elements: [
          ElementView(id: customer.id, x: 100, y: 200),
          ElementView(id: webApplication.id, x: 500, y: 100),
          ElementView(id: apiApplication.id, x: 500, y: 300),
          ElementView(id: database.id, x: 800, y: 200),
          ElementView(id: mainframeBankingSystem.id, x: 900, y: 400),
          ElementView(id: emailSystem.id, x: 900, y: 100),
        ],
        relationships: [
          RelationshipView(id: customerWithRelationships.relationships[0].id),
          RelationshipView(id: webApplicationWithRelationships.relationships[0].id),
          RelationshipView(id: webApplicationWithRelationships.relationships[1].id),
          RelationshipView(id: apiApplicationWithRelationships.relationships[0].id),
          RelationshipView(id: apiApplicationWithRelationships.relationships[1].id),
        ],
      );
      
      // Component view
      final componentView = ComponentView(
        key: 'Components',
        softwareSystemId: internetBankingSystem.id,
        containerId: apiApplication.id,
        description: 'Component diagram for the API Application',
        title: 'Internet Banking System - API Application Components',
        elements: [
          ElementView(id: signinController.id, x: 300, y: 100),
          ElementView(id: accountsController.id, x: 300, y: 300),
          ElementView(id: securityComponent.id, x: 600, y: 200),
          ElementView(id: database.id, x: 900, y: 200),
          ElementView(id: mainframeBankingSystem.id, x: 900, y: 400),
        ],
        relationships: [
          RelationshipView(id: signinControllerWithRelationships.relationships[0].id),
          RelationshipView(id: accountsControllerWithRelationships.relationships[0].id),
          RelationshipView(id: accountsControllerWithRelationships.relationships[1].id),
          RelationshipView(id: accountsControllerWithRelationships.relationships[2].id),
        ],
      );
      
      // Dynamic view
      final dynamicView = DynamicView(
        key: 'SignIn',
        elementId: apiApplication.id,
        description: 'Sign in process for the Internet Banking System',
        title: 'Internet Banking System - Dynamic',
        elements: [
          ElementView(id: customer.id),
          ElementView(id: webApplication.id),
          ElementView(id: signinController.id),
          ElementView(id: securityComponent.id),
          ElementView(id: database.id),
        ],
        relationships: [
          RelationshipView(id: customerWithRelationships.relationships[0].id, order: '1'),
          RelationshipView(id: webApplicationWithRelationships.relationships[0].id, order: '2'),
          RelationshipView(id: signinControllerWithRelationships.relationships[0].id, order: '3'),
          RelationshipView(id: accountsControllerWithRelationships.relationships[2].id, order: '4'),
        ],
        animations: [
          AnimationStep(
            order: 1, 
            elements: [customer.id],
          ),
          AnimationStep(
            order: 2, 
            elements: [customer.id, webApplication.id],
            relationships: [customerWithRelationships.relationships[0].id],
          ),
          AnimationStep(
            order: 3, 
            elements: [customer.id, webApplication.id, signinController.id],
            relationships: [
              customerWithRelationships.relationships[0].id,
              webApplicationWithRelationships.relationships[0].id,
            ],
          ),
          AnimationStep(
            order: 4, 
            elements: [customer.id, webApplication.id, signinController.id, securityComponent.id],
            relationships: [
              customerWithRelationships.relationships[0].id,
              webApplicationWithRelationships.relationships[0].id,
              signinControllerWithRelationships.relationships[0].id,
            ],
          ),
          AnimationStep(
            order: 5, 
            elements: [
              customer.id, 
              webApplication.id, 
              signinController.id, 
              securityComponent.id,
              database.id,
            ],
            relationships: [
              customerWithRelationships.relationships[0].id,
              webApplicationWithRelationships.relationships[0].id,
              signinControllerWithRelationships.relationships[0].id,
              accountsControllerWithRelationships.relationships[2].id,
            ],
          ),
        ],
      );
      
      // Deployment view
      final deploymentView = DeploymentView(
        key: 'Deployment',
        softwareSystemId: internetBankingSystem.id,
        environment: 'Live',
        description: 'Deployment diagram for the Internet Banking System',
        title: 'Internet Banking System - Deployment',
        elements: [
          ElementView(id: liveEnv.id, x: 50, y: 50),
          ElementView(id: awsNode.id, x: 100, y: 100),
          ElementView(id: ec2Node.id, x: 150, y: 150),
          ElementView(id: rdsNode.id, x: 150, y: 300),
          ElementView(id: loadBalancer.id, x: 150, y: 50),
          ElementView(id: webAppInstance.id, x: 250, y: 100),
          ElementView(id: apiAppInstance.id, x: 250, y: 200),
          ElementView(id: dbInstance.id, x: 250, y: 300),
        ],
        relationships: [
          RelationshipView(id: loadBalancerWithRelationships.relationships[0].id),
          RelationshipView(id: loadBalancerWithRelationships.relationships[1].id),
          RelationshipView(id: webAppInstanceWithRelationships.relationships[0].id),
          RelationshipView(id: apiAppInstanceWithRelationships.relationships[0].id),
        ],
      );
      
      // Create filtered view based on system context
      final filteredView = FilteredView(
        key: 'ExternalSystemsOnly',
        baseViewKey: 'SystemContext',
        description: 'Only showing external systems',
        title: 'Internet Banking System - External Systems',
        tags: ['External'],
        filterMode: 'Include',
      );
      
      // Add views
      final views = Views(
        systemLandscapeViews: [systemLandscapeView],
        systemContextViews: [systemContextView],
        containerViews: [containerView],
        componentViews: [componentView],
        dynamicViews: [dynamicView],
        deploymentViews: [deploymentView],
        filteredViews: [filteredView],
        configuration: ViewConfiguration(
          defaultView: 'SystemContext',
          lastModifiedDate: DateTime(2023, 1, 1),
        ),
      );
      
      // Add styles
      final styles = Styles(
        elements: [
          ElementStyle(
            tag: 'Person',
            shape: Shape.person,
            background: const Color(0xFF1168BD),
            color: const Color(0xFFFFFFFF),
          ),
          ElementStyle(
            tag: 'External',
            background: const Color(0xFF999999),
          ),
          ElementStyle(
            tag: 'SoftwareSystem',
            background: const Color(0xFF1168BD),
            color: const Color(0xFFFFFFFF),
          ),
          ElementStyle(
            tag: 'Container',
            background: const Color(0xFF438DD5),
            color: const Color(0xFFFFFFFF),
          ),
          ElementStyle(
            tag: 'Component',
            background: const Color(0xFF85BBF0),
            color: const Color(0xFF000000),
          ),
          ElementStyle(
            tag: 'Database',
            shape: Shape.cylinder,
          ),
        ],
        relationships: [
          RelationshipStyle(
            tag: 'Synchronous',
            thickness: 2,
            color: const Color(0xFF707070),
            style: LineStyle.solid,
          ),
          RelationshipStyle(
            tag: 'Asynchronous',
            thickness: 2,
            color: const Color(0xFF707070),
            style: LineStyle.dashed,
          ),
        ],
        themes: ['https://static.structurizr.com/themes/default/theme.json'],
      );
      
      // Create branding
      final branding = Branding(
        logo: 'https://example.com/logo.png',
      );
      
      // Add styles and branding to views
      final viewsWithStyles = views.copyWith(
        styles: styles,
      );
      
      // Create workspace
      workspace = Workspace(
        id: 1,
        name: 'Big Bank plc',
        description: 'Architecture model for Big Bank plc',
        model: model,
        configuration: WorkspaceConfiguration(
          lastModifiedDate: DateTime(2023, 1, 1),
          lastModifiedUser: 'User',
          properties: {
            'structurizr.branding': jsonEncode(branding.toJson()),
          },
        ),
      );
    });
    
    test('Complex model validates successfully', () {
      final validationErrors = workspace.validate();
      expect(validationErrors, isEmpty, reason: 'Complex model should validate successfully');
    });
    
    test('Complex model can be serialized to JSON', () {
      final jsonString = JsonSerialization.workspaceToJson(workspace);
      expect(jsonString, isNotNull);
      expect(jsonString.length, greaterThan(0));
      
      // Verify JSON can be parsed
      final jsonMap = jsonDecode(jsonString);
      expect(jsonMap['id'], equals(1));
      expect(jsonMap['name'], equals('Big Bank plc'));
      expect(jsonMap['model'], isNotNull);
      expect(jsonMap['model']['softwareSystems'], isNotNull);
      
      // Verify model contents are preserved
      expect(jsonMap['model']['softwareSystems'].length, equals(3));
      expect(jsonMap['model']['people'].length, equals(2));
    });
    
    test('Complex model can be deserialized from JSON', () {
      final jsonString = JsonSerialization.workspaceToJson(workspace);
      final deserializedWorkspace = JsonSerialization.workspaceFromJson(jsonString);
      
      expect(deserializedWorkspace.id, equals(workspace.id));
      expect(deserializedWorkspace.name, equals(workspace.name));
      
      // Verify model
      expect(deserializedWorkspace.model.enterpriseName, equals('Big Bank plc'));
      expect(deserializedWorkspace.model.people.length, equals(2));
      expect(deserializedWorkspace.model.softwareSystems.length, equals(3));
      
      // Find a specific system
      final internetBankingSystem = deserializedWorkspace.model.softwareSystems
          .firstWhere((s) => s.name == 'Internet Banking System');
      
      expect(internetBankingSystem.containers.length, equals(3));
      
      // Find a specific container
      final apiApplication = internetBankingSystem.containers
          .firstWhere((c) => c.name == 'API Application');
      
      expect(apiApplication.components.length, equals(3));
      
      // Find a specific component
      final signinController = apiApplication.components
          .firstWhere((c) => c.name == 'Sign In Controller');
      
      expect(signinController.technology, equals('Spring MVC Controller'));
      
      // Check all relationships are present
      final allRelationships = deserializedWorkspace.model.getAllRelationships();
      expect(allRelationships.length, greaterThan(10));
    });
    
    test('Element and relationship lookups work correctly', () {
      // Get all elements
      final allElements = workspace.model.getAllElements();
      expect(allElements.length, greaterThan(15));
      
      // Find a specific element by ID
      final person = allElements.firstWhere((e) => e.type == 'Person' && e.name == 'Customer');
      final element = workspace.model.getElementById(person.id);
      expect(element, isNotNull);
      expect(element?.name, equals('Customer'));
      
      // Find elements with specific tags
      final externalElements = allElements.where((e) => e.tags.contains('External')).toList();
      expect(externalElements.length, greaterThan(0));
      
      // Find relationships with specific properties
      final jdbcRelationships = workspace.model.getAllRelationships()
          .where((r) => r.technology == 'JDBC')
          .toList();
      expect(jdbcRelationships.length, greaterThan(0));
    });
    
    test('Views correctly include elements and relationships', () {
      // Find a system by name
      final internetBankingSystem = workspace.model.softwareSystems
          .firstWhere((s) => s.name == 'Internet Banking System');
      
      // Find container view
      final views = Views(
        systemLandscapeViews: [
          SystemLandscapeView(
            key: 'SystemLandscape',
            description: 'Test',
          ),
        ],
        containerViews: [
          ContainerView(
            key: 'Containers',
            softwareSystemId: internetBankingSystem.id,
            description: 'Test',
          ),
        ],
      );
      
      // Check view retrieval
      final containerView = views.getViewByKey('Containers');
      expect(containerView, isNotNull);
      expect(containerView?.viewType, equals('Container'));
      
      // Check views count
      expect(views.getAllViews().length, equals(2));
      
      // Check view contains/has methods
      expect(views.containsViewWithKey('Containers'), isTrue);
      expect(views.containsViewWithKey('NonExistent'), isFalse);
    });
  });
}