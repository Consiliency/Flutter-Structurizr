import 'package:flutter_structurizr/application/dsl/workspace_mapper.dart';
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/parser/ast/ast.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkspaceMapper', () {
    late WorkspaceMapper mapper;

    setUp(() {
      const source = '';
      mapper = WorkspaceMapper(source);
    });

    test('maps an empty workspace', () {
      // Arrange
      final workspaceNode = WorkspaceNode(
        name: 'Test Workspace',
        description: 'A test workspace',
        sourcePosition: SourcePosition(line: 1, column: 1, offset: 0),
      );

      // Act
      final workspace = mapper.mapWorkspace(workspaceNode);

      // Assert
      expect(workspace, isNotNull);
      expect(workspace.name, equals('Test Workspace'));
      expect(workspace.description, equals('A test workspace'));
      expect(workspace.model.elements, isEmpty);
    });

    test('maps a workspace with a person', () {
      // Arrange
      final personNode = PersonNode(
        id: 'user',
        name: 'User',
        description: 'A user of the system',
        sourcePosition: SourcePosition(line: 2, column: 1, offset: 0),
      );

      final modelNode = ModelNode(
        people: [personNode],
        sourcePosition: SourcePosition(line: 1, column: 5, offset: 0),
      );

      final workspaceNode = WorkspaceNode(
        name: 'Test Workspace',
        description: 'A test workspace',
        model: modelNode,
        sourcePosition: SourcePosition(line: 1, column: 1, offset: 0),
      );

      // Act
      final workspace = mapper.mapWorkspace(workspaceNode);

      // Assert
      expect(workspace, isNotNull);
      expect(workspace.model.elements, hasLength(1));

      final person = workspace.model.elements.first as Person;
      expect(person.name, equals('User'));
      expect(person.description, equals('A user of the system'));
      expect(person.identifier, equals('user'));
    });

    test('maps a workspace with a software system', () {
      // Arrange
      final systemNode = SoftwareSystemNode(
        id: 'system',
        name: 'System',
        description: 'A software system',
        sourcePosition: SourcePosition(line: 2, column: 1, offset: 0),
        properties: null,
        relationships: [],
        containers: [],
      );

      final workspaceNode = WorkspaceNode(
        name: 'Test Workspace',
        description: 'A test workspace',
        sourcePosition: SourcePosition(0, 1, 1),
        children: [systemNode],
      );

      // Act
      final workspace = mapper.mapWorkspace(workspaceNode);

      // Assert
      expect(workspace, isNotNull);
      expect(workspace.model.elements, hasLength(1));

      final system = workspace.model.elements.first as SoftwareSystem;
      expect(system.name, equals('System'));
      expect(system.description, equals('A software system'));
      expect(system.identifier, equals('system'));
    });

    test('maps a workspace with a container inside a software system', () {
      // Arrange
      final containerNode = ContainerNode(
        name: 'Container',
        description: 'A container',
        sourcePosition: SourcePosition(0, 3, 1),
        identifier: 'container',
        properties: [],
        relationships: [],
        children: [],
      );

      final systemNode = SoftwareSystemNode(
        name: 'System',
        description: 'A software system',
        sourcePosition: SourcePosition(0, 2, 1),
        identifier: 'system',
        properties: [],
        relationships: [],
        children: [containerNode],
      );

      final workspaceNode = WorkspaceNode(
        name: 'Test Workspace',
        description: 'A test workspace',
        sourcePosition: SourcePosition(0, 1, 1),
        children: [systemNode],
      );

      // Act
      final workspace = mapper.mapWorkspace(workspaceNode);

      // Assert
      expect(workspace, isNotNull);
      expect(workspace.model.elements, hasLength(2)); // System + Container

      final system = workspace.model.elements.first as SoftwareSystem;
      expect(system.name, equals('System'));

      final container = workspace.model.elements
          .whereType<Container>()
          .firstWhere((e) => e.identifier == 'container');
      expect(container.name, equals('Container'));
      expect(container.parent, equals(system));
    });

    test('maps a workspace with a component inside a container', () {
      // Arrange
      final componentNode = ComponentNode(
        name: 'Component',
        description: 'A component',
        sourcePosition: SourcePosition(0, 4, 1),
        identifier: 'component',
        properties: [],
        relationships: [],
        children: [],
      );

      final containerNode = ContainerNode(
        name: 'Container',
        description: 'A container',
        sourcePosition: SourcePosition(0, 3, 1),
        identifier: 'container',
        properties: [],
        relationships: [],
        children: [componentNode],
      );

      final systemNode = SoftwareSystemNode(
        name: 'System',
        description: 'A software system',
        sourcePosition: SourcePosition(0, 2, 1),
        identifier: 'system',
        properties: [],
        relationships: [],
        children: [containerNode],
      );

      final workspaceNode = WorkspaceNode(
        name: 'Test Workspace',
        description: 'A test workspace',
        sourcePosition: SourcePosition(0, 1, 1),
        children: [systemNode],
      );

      // Act
      final workspace = mapper.mapWorkspace(workspaceNode);

      // Assert
      expect(workspace, isNotNull);
      expect(workspace.model.elements,
          hasLength(3)); // System + Container + Component

      final component = workspace.model.elements
          .whereType<Component>()
          .firstWhere((e) => e.identifier == 'component');
      expect(component.name, equals('Component'));

      final container = workspace.model.elements
          .whereType<Container>()
          .firstWhere((e) => e.identifier == 'container');
      expect(component.parent, equals(container));
    });

    test('maps relationships between elements', () {
      // Arrange
      final relationshipNode = RelationshipNode(
        sourceIdentifier: 'user',
        destinationIdentifier: 'system',
        description: 'Uses',
        technology: null,
        sourcePosition: SourcePosition(0, 5, 1),
        properties: [],
      );

      final personNode = PersonNode(
        name: 'User',
        description: 'A user of the system',
        sourcePosition: SourcePosition(0, 2, 1),
        identifier: 'user',
        properties: [],
        relationships: [relationshipNode],
      );

      final systemNode = SoftwareSystemNode(
        name: 'System',
        description: 'A software system',
        sourcePosition: SourcePosition(0, 3, 1),
        identifier: 'system',
        properties: [],
        relationships: [],
        children: [],
      );

      final workspaceNode = WorkspaceNode(
        name: 'Test Workspace',
        description: 'A test workspace',
        sourcePosition: SourcePosition(0, 1, 1),
        children: [personNode, systemNode],
      );

      // Act
      final workspace = mapper.mapWorkspace(workspaceNode);

      // Assert
      expect(workspace, isNotNull);
      expect(workspace.model.relationships, hasLength(1));

      final relationship = workspace.model.relationships.first;
      expect(relationship.source.identifier, equals('user'));
      expect(relationship.destination.identifier, equals('system'));
      expect(relationship.description, equals('Uses'));
    });

    test('reports error for relationship with undefined source', () {
      // Arrange
      final relationshipNode = RelationshipNode(
        sourceIdentifier: 'undefined',
        destinationIdentifier: 'system',
        description: 'Uses',
        technology: null,
        sourcePosition: SourcePosition(0, 5, 1),
        properties: [],
      );

      final systemNode = SoftwareSystemNode(
        name: 'System',
        description: 'A software system',
        sourcePosition: SourcePosition(0, 3, 1),
        identifier: 'system',
        properties: [],
        relationships: [relationshipNode],
        children: [],
      );

      final workspaceNode = WorkspaceNode(
        name: 'Test Workspace',
        description: 'A test workspace',
        sourcePosition: SourcePosition(0, 1, 1),
        children: [systemNode],
      );

      // Act
      expect(
          () => mapper.mapWorkspace(workspaceNode), throwsA(isA<ParseError>()));
    });

    test('reports error for relationship with undefined destination', () {
      // Arrange
      final relationshipNode = RelationshipNode(
        sourceIdentifier: 'system',
        destinationIdentifier: 'undefined',
        description: 'Uses',
        technology: null,
        sourcePosition: SourcePosition(0, 5, 1),
        properties: [],
      );

      final systemNode = SoftwareSystemNode(
        name: 'System',
        description: 'A software system',
        sourcePosition: SourcePosition(0, 3, 1),
        identifier: 'system',
        properties: [],
        relationships: [relationshipNode],
        children: [],
      );

      final workspaceNode = WorkspaceNode(
        name: 'Test Workspace',
        description: 'A test workspace',
        sourcePosition: SourcePosition(0, 1, 1),
        children: [systemNode],
      );

      // Act
      expect(
          () => mapper.mapWorkspace(workspaceNode), throwsA(isA<ParseError>()));
    });

    test('maps properties on elements', () {
      // Arrange
      final tagPropertyNode = PropertyNode(
        name: 'tags',
        value: 'web,external',
        sourcePosition: SourcePosition(0, 3, 1),
      );

      final personNode = PersonNode(
        name: 'User',
        description: 'A user of the system',
        sourcePosition: SourcePosition(0, 2, 1),
        identifier: 'user',
        properties: [tagPropertyNode],
        relationships: [],
      );

      final workspaceNode = WorkspaceNode(
        name: 'Test Workspace',
        description: 'A test workspace',
        sourcePosition: SourcePosition(0, 1, 1),
        children: [personNode],
      );

      // Act
      final workspace = mapper.mapWorkspace(workspaceNode);

      // Assert
      expect(workspace, isNotNull);

      final person = workspace.model.elements.first as Person;
      expect(person.tags, contains('web'));
      expect(person.tags, contains('external'));
    });

    test('complex model with multiple element types and relationships', () {
      // Arrange
      // Person -> System -> Container -> Component relationships
      final userToSystemRelationshipNode = RelationshipNode(
        sourceIdentifier: 'user',
        destinationIdentifier: 'system',
        description: 'Uses',
        technology: null,
        sourcePosition: SourcePosition(0, 10, 1),
        properties: [],
      );

      final systemToContainerRelationshipNode = RelationshipNode(
        sourceIdentifier: 'system',
        destinationIdentifier: 'container',
        description: 'Contains',
        technology: null,
        sourcePosition: SourcePosition(0, 11, 1),
        properties: [],
      );

      final containerToComponentRelationshipNode = RelationshipNode(
        sourceIdentifier: 'container',
        destinationIdentifier: 'component',
        description: 'Contains',
        technology: null,
        sourcePosition: SourcePosition(0, 12, 1),
        properties: [],
      );

      final componentNode = ComponentNode(
        name: 'Component',
        description: 'A component',
        sourcePosition: SourcePosition(0, 7, 1),
        identifier: 'component',
        properties: [],
        relationships: [],
        children: [],
      );

      final containerNode = ContainerNode(
        name: 'Container',
        description: 'A container',
        sourcePosition: SourcePosition(0, 6, 1),
        identifier: 'container',
        properties: [],
        relationships: [containerToComponentRelationshipNode],
        children: [componentNode],
      );

      final systemNode = SoftwareSystemNode(
        name: 'System',
        description: 'A software system',
        sourcePosition: SourcePosition(0, 5, 1),
        identifier: 'system',
        properties: [],
        relationships: [systemToContainerRelationshipNode],
        children: [containerNode],
      );

      final personNode = PersonNode(
        name: 'User',
        description: 'A user of the system',
        sourcePosition: SourcePosition(0, 4, 1),
        identifier: 'user',
        properties: [],
        relationships: [userToSystemRelationshipNode],
      );

      final workspaceNode = WorkspaceNode(
        name: 'Complex Workspace',
        description: 'A complex workspace with multiple elements',
        sourcePosition: SourcePosition(0, 1, 1),
        children: [personNode, systemNode],
      );

      // Act
      final workspace = mapper.mapWorkspace(workspaceNode);

      // Assert
      expect(workspace, isNotNull);
      expect(workspace.name, equals('Complex Workspace'));

      // Check elements
      expect(workspace.model.elements.whereType<Person>().length, equals(1));
      expect(workspace.model.elements.whereType<SoftwareSystem>().length,
          equals(1));
      expect(workspace.model.elements.whereType<Container>().length, equals(1));
      expect(workspace.model.elements.whereType<Component>().length, equals(1));

      // Check relationships
      expect(workspace.model.relationships.length, equals(3));

      // Check parent-child relationships
      final component = workspace.model.elements
          .whereType<Component>()
          .firstWhere((e) => e.identifier == 'component');
      final container = workspace.model.elements
          .whereType<Container>()
          .firstWhere((e) => e.identifier == 'container');
      final system = workspace.model.elements
          .whereType<SoftwareSystem>()
          .firstWhere((e) => e.identifier == 'system');

      expect(component.parent, equals(container));
      expect(container.parent, equals(system));
    });

    test('maps styles for elements and relationships', () {
      // Arrange
      final elementStyleNode = ElementStyleNode(
        tag: 'Element',
        shape: 'Box',
        background: '#FF0000',
        color: '#FFFFFF',
        sourcePosition: SourcePosition(0, 5, 1),
      );

      final relationshipStyleNode = RelationshipStyleNode(
        tag: 'Relationship',
        thickness: 2,
        color: '#0000FF',
        style: 'Dashed',
        sourcePosition: SourcePosition(0, 6, 1),
      );

      final stylesNode = StylesNode(
        elementStyles: [elementStyleNode],
        relationshipStyles: [relationshipStyleNode],
        sourcePosition: SourcePosition(0, 4, 1),
      );

      final workspaceNode = WorkspaceNode(
        name: 'Test Workspace',
        description: 'A test workspace',
        sourcePosition: SourcePosition(0, 1, 1),
        children: [],
        styles: stylesNode,
      );

      // Act
      final workspace = mapper.mapWorkspace(workspaceNode);

      // Assert
      expect(workspace, isNotNull);
      expect(workspace.styles, isNotNull);
      expect(workspace.styles.elements.length, equals(1));
      expect(workspace.styles.relationships.length, equals(1));

      final elementStyle = workspace.styles.elements.first;
      expect(elementStyle.tag, equals('Element'));
      expect(elementStyle.shape, equals(Shape.box));

      final relationshipStyle = workspace.styles.relationships.first;
      expect(relationshipStyle.tag, equals('Relationship'));
      expect(relationshipStyle.thickness, equals(2));
      expect(relationshipStyle.style, equals(LineStyle.dashed));
    });

    test('maps branding information', () {
      // Arrange
      final brandingNode = BrandingNode(
        logo: 'https://example.com/logo.png',
        font: 'Open Sans',
        sourcePosition: SourcePosition(0, 4, 1),
      );

      final workspaceNode = WorkspaceNode(
        name: 'Test Workspace',
        description: 'A test workspace',
        sourcePosition: SourcePosition(0, 1, 1),
        children: [],
        branding: brandingNode,
      );

      // Act
      final workspace = mapper.mapWorkspace(workspaceNode);

      // Assert
      expect(workspace, isNotNull);
      expect(workspace.branding, isNotNull);
      expect(workspace.branding.logo, equals('https://example.com/logo.png'));
      expect(workspace.branding.fonts.length, equals(1));
      expect(workspace.branding.fonts.first.name, equals('Open Sans'));
    });

    test('maps terminology customization', () {
      // Arrange
      final terminologyNode = TerminologyNode(
        person: 'Actor',
        softwareSystem: 'Application',
        container: 'Service',
        component: 'Module',
        sourcePosition: SourcePosition(0, 4, 1),
      );

      final workspaceNode = WorkspaceNode(
        name: 'Test Workspace',
        description: 'A test workspace',
        sourcePosition: SourcePosition(0, 1, 1),
        children: [],
        terminology: terminologyNode,
      );

      // Act
      final workspace = mapper.mapWorkspace(workspaceNode);

      // Assert
      expect(workspace, isNotNull);
      expect(workspace.views, isNotNull);
      expect(workspace.views.configuration, isNotNull);
      expect(workspace.views.configuration?.terminology, isNotNull);

      final terminology = workspace.views.configuration!.terminology!;
      expect(terminology.person, equals('Actor'));
      expect(terminology.softwareSystem, equals('Application'));
      expect(terminology.container, equals('Service'));
      expect(terminology.component, equals('Module'));
    });
  });
}
