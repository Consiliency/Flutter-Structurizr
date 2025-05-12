import 'package:flutter/material.dart' hide Element, Container, View;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';
import 'package:flutter_structurizr/infrastructure/export/diagram_exporter.dart';
import 'package:flutter_structurizr/infrastructure/export/dsl_exporter.dart';

void main() {
  /// Creates a test workspace with sample elements
  Workspace createTestWorkspace() {
    // Create a simple model with a person and a system
    final person = Person.create(
      name: 'User',
      description: 'A user of the system',
    );
    
    final system = SoftwareSystem.create(
      name: 'System',
      description: 'The software system',
    );
    
    // Add components to the system
    final container = Container.create(
      name: 'Web Application',
      description: 'The web application',
      parentId: system.id,
      technology: 'Flutter',
    );
    
    final component = Component.create(
      name: 'Login Controller',
      description: 'Handles user authentication',
      parentId: container.id,
      technology: 'Dart',
    );
    
    // Add containers to system
    final updatedSystem = system.addContainer(container);
    
    // Create deployment nodes
    final deploymentNode = DeploymentNode.create(
      name: 'AWS EC2',
      environment: 'Production',
      technology: 'Amazon EC2',
    );
    
    // Create a model with all elements
    final model = Model(
      people: [person],
      softwareSystems: [updatedSystem],
      deploymentNodes: [deploymentNode],
    );
    
    // Create a System Context view
    final systemContextView = SystemContextView(
      key: 'SystemContext',
      softwareSystemId: system.id,
      title: 'System Context Diagram',
      description: 'An example system context diagram',
      elements: [
        ElementView(id: person.id),
        ElementView(id: system.id),
      ],
      relationships: [
        RelationshipView(id: 'rel1'),
      ],
    );
    
    // Create container view
    final containerView = ContainerView(
      key: 'Containers',
      softwareSystemId: system.id,
      title: 'Container Diagram',
      description: 'Shows the containers within the system',
      elements: [
        ElementView(id: person.id),
        ElementView(id: system.id),
        ElementView(id: container.id),
      ],
    );
    
    // Create component view
    final componentView = ComponentView(
      key: 'Components',
      softwareSystemId: system.id,
      containerId: container.id,
      title: 'Component Diagram',
      description: 'Shows the components within the container',
      elements: [
        ElementView(id: container.id),
        ElementView(id: component.id),
      ],
    );
    
    // Create deployment view
    final deploymentView = DeploymentView(
      key: 'Deployment',
      environment: 'Production',
      title: 'Deployment Diagram',
      description: 'Shows the deployment of the system',
      elements: [
        ElementView(id: deploymentNode.id),
      ],
    );
    
    // Add a relationship
    final updatedPerson = person.addRelationship(
      destinationId: system.id,
      description: 'Uses',
      technology: 'HTTPS',
    );
    
    final updatedModel = model.copyWith(
      people: [updatedPerson],
    );
    
    // Set up the workspace views
    final views = Views(
      systemContextViews: [systemContextView],
      containerViews: [containerView],
      componentViews: [componentView],
      deploymentViews: [deploymentView],
    );
    
    // Set up workspace configuration with styles
    final elementStyle = ElementStyle(
      tag: 'Person',
      shape: 'Person',
      background: '#08427B',
      color: '#FFFFFF',
    );
    
    final relationshipStyle = RelationshipStyle(
      tag: 'Relationship',
      thickness: 2,
      color: '#707070',
    );
    
    final styles = Styles(
      elements: [elementStyle],
      relationships: [relationshipStyle],
    );
    
    final configuration = WorkspaceConfiguration(
      styles: styles,
    );
    
    // Create and return the workspace
    return Workspace(
      id: 1,
      name: 'Test Workspace',
      description: 'A test workspace for Structurizr DSL export',
      model: updatedModel,
      views: views,
      configuration: configuration,
    );
  }

  group('DslExporter', () {
    test('exports workspace to DSL format', () async {
      // Create test workspace and diagram reference
      final workspace = createTestWorkspace();
      final diagram = DiagramReference(
        workspace: workspace,
        viewKey: 'SystemContext',
      );
      
      // Create the exporter
      final exporter = DslExporter();
      
      // Export the diagram
      final dsl = await exporter.export(diagram);
      
      // The output should be a string
      expect(dsl, isA<String>());
      
      // Check for basic DSL syntax
      expect(dsl, contains('workspace {'));
      expect(dsl, contains('model {'));
      expect(dsl, contains('views {'));
      expect(dsl, contains('styles {'));
      
      // Check for workspace metadata
      expect(dsl, contains('name "Test Workspace"'));
      expect(dsl, contains('description "A test workspace for Structurizr DSL export"'));
      
      // Check for model elements
      expect(dsl, contains('person "User" "A user of the system"'));
      expect(dsl, contains('softwareSystem "System" "The software system"'));
      expect(dsl, contains('container "Web Application" "The web application" "Flutter"'));
      expect(dsl, contains('component "Login Controller" "Handles user authentication" "Dart"'));
      
      // Check for views
      expect(dsl, contains('systemContext'));
      expect(dsl, contains('container'));
      expect(dsl, contains('component'));
      expect(dsl, contains('deployment'));
      
      // Check for styles
      expect(dsl, contains('element "Person"'));
      expect(dsl, contains('relationship "Relationship"'));
    });
    
    test('respects metadata inclusion setting', () async {
      // Create test workspace and diagram reference
      final workspace = createTestWorkspace();
      final diagram = DiagramReference(
        workspace: workspace,
        viewKey: 'SystemContext',
      );
      
      // Create exporters with different metadata settings
      final withMetadataExporter = DslExporter(
        includeMetadata: true,
      );
      
      final noMetadataExporter = DslExporter(
        includeMetadata: false,
      );
      
      // Export with different settings
      final withMetadataDsl = await withMetadataExporter.export(diagram);
      final noMetadataDsl = await noMetadataExporter.export(diagram);
      
      // Check for metadata inclusion
      expect(withMetadataDsl, contains('name "Test Workspace"'));
      expect(withMetadataDsl, contains('description "A test workspace for Structurizr DSL export"'));
      expect(noMetadataDsl, isNot(contains('name "Test Workspace"')));
      expect(noMetadataDsl, isNot(contains('description "A test workspace for Structurizr DSL export"')));
    });
    
    test('respects documentation inclusion setting', () async {
      // Create test workspace and diagram reference
      final workspace = createTestWorkspace();
      final diagram = DiagramReference(
        workspace: workspace,
        viewKey: 'SystemContext',
      );
      
      // Create exporters with different documentation settings
      final withDocsExporter = DslExporter(
        includeDocumentation: true,
      );
      
      final noDocsExporter = DslExporter(
        includeDocumentation: false,
      );
      
      // Export with different settings
      final withDocsDsl = await withDocsExporter.export(diagram);
      final noDocsDsl = await noDocsExporter.export(diagram);
      
      // Since our test workspace doesn't have documentation, we just verify
      // that both exports work and have the same length in this case
      expect(withDocsDsl.length, equals(noDocsDsl.length));
    });
    
    test('respects styles inclusion setting', () async {
      // Create test workspace and diagram reference
      final workspace = createTestWorkspace();
      final diagram = DiagramReference(
        workspace: workspace,
        viewKey: 'SystemContext',
      );
      
      // Create exporters with different styles settings
      final withStylesExporter = DslExporter(
        includeStyles: true,
      );
      
      final noStylesExporter = DslExporter(
        includeStyles: false,
      );
      
      // Export with different settings
      final withStylesDsl = await withStylesExporter.export(diagram);
      final noStylesDsl = await noStylesExporter.export(diagram);
      
      // Check for styles inclusion
      expect(withStylesDsl, contains('styles {'));
      expect(withStylesDsl, contains('element "Person"'));
      expect(noStylesDsl, isNot(contains('styles {')));
      expect(noStylesDsl, isNot(contains('element "Person"')));
    });
    
    test('respects views inclusion setting', () async {
      // Create test workspace and diagram reference
      final workspace = createTestWorkspace();
      final diagram = DiagramReference(
        workspace: workspace,
        viewKey: 'SystemContext',
      );
      
      // Create exporters with different views settings
      final withViewsExporter = DslExporter(
        includeViews: true,
      );
      
      final noViewsExporter = DslExporter(
        includeViews: false,
      );
      
      // Export with different settings
      final withViewsDsl = await withViewsExporter.export(diagram);
      final noViewsDsl = await noViewsExporter.export(diagram);
      
      // Check for views inclusion
      expect(withViewsDsl, contains('views {'));
      expect(withViewsDsl, contains('systemContext'));
      expect(noViewsDsl, isNot(contains('views {')));
      expect(noViewsDsl, isNot(contains('systemContext')));
    });
    
    test('respects indent setting', () async {
      // Create test workspace and diagram reference
      final workspace = createTestWorkspace();
      final diagram = DiagramReference(
        workspace: workspace,
        viewKey: 'SystemContext',
      );
      
      // Create exporters with different indent settings
      final twoSpaceExporter = DslExporter(
        indent: '  ',
      );
      
      final fourSpaceExporter = DslExporter(
        indent: '    ',
      );
      
      final tabExporter = DslExporter(
        indent: '\t',
      );
      
      // Export with different settings
      final twoSpaceDsl = await twoSpaceExporter.export(diagram);
      final fourSpaceDsl = await fourSpaceExporter.export(diagram);
      final tabDsl = await tabExporter.export(diagram);
      
      // Check that the outputs have different lengths due to indentation
      expect(twoSpaceDsl.length, lessThan(fourSpaceDsl.length));
      expect(tabDsl.length, isNot(equals(twoSpaceDsl.length)));
    });
    
    test('reports export progress', () async {
      // Create test workspace and diagram reference
      final workspace = createTestWorkspace();
      final diagram = DiagramReference(
        workspace: workspace,
        viewKey: 'SystemContext',
      );
      
      // Create exporter with progress tracking
      double exportProgress = 0.0;
      final exporter = DslExporter(
        onProgress: (progress) {
          exportProgress = progress;
        },
      );
      
      // Export the diagram
      await exporter.export(diagram);
      
      // Progress should reach 100%
      expect(exportProgress, equals(1.0));
    });
    
    test('exports batch of diagrams', () async {
      // Create test workspace and multiple diagram references
      final workspace = createTestWorkspace();
      final diagrams = [
        DiagramReference(
          workspace: workspace,
          viewKey: 'SystemContext',
        ),
        DiagramReference(
          workspace: workspace,
          viewKey: 'Containers',
        ),
        DiagramReference(
          workspace: workspace,
          viewKey: 'Components',
        ),
      ];
      
      // Create the exporter with progress tracking
      double batchProgress = 0.0;
      final exporter = DslExporter(
        onProgress: (progress) {
          batchProgress = progress;
        },
      );
      
      // Export the diagrams in batch
      final results = await exporter.exportBatch(
        diagrams,
        onProgress: (progress) {
          batchProgress = progress;
        },
      );
      
      // Verify the results
      expect(results, isA<List<String>>());
      expect(results.length, equals(3));
      
      // Check that all results are identical (DSL exporter exports the whole workspace,
      // so the output doesn't depend on which view was referenced)
      expect(results[0], equals(results[1]));
      expect(results[1], equals(results[2]));
      
      // Progress should reach 100%
      expect(batchProgress, equals(1.0));
    });
    
    test('handles empty batch gracefully', () async {
      // Create exporter
      final exporter = DslExporter();
      
      // Export empty batch
      final results = await exporter.exportBatch([]);
      
      // Should return empty list
      expect(results, isEmpty);
    });
    
    test('escapes special characters properly', () async {
      // Create a workspace with special characters
      final person = Person.create(
        name: 'User with "quotes"',
        description: 'A user with \\ backslashes and "quotes"',
      );
      
      final model = Model(
        people: [person],
      );
      
      final workspace = Workspace(
        id: 1,
        name: 'Test "Quotes"',
        description: 'Description with "quotes" and \\ backslashes',
        model: model,
      );
      
      final diagram = DiagramReference(
        workspace: workspace,
        viewKey: 'test',
      );
      
      // Create the exporter
      final exporter = DslExporter();
      
      // Export the diagram
      final dsl = await exporter.export(diagram);
      
      // Check for proper escaping
      expect(dsl, contains('name "Test \\"Quotes\\""'));
      expect(dsl, contains('description "Description with \\"quotes\\" and \\\\ backslashes"'));
      expect(dsl, contains('person "User with \\"quotes\\"" "A user with \\\\ backslashes and \\"quotes\\""'));
    });
  });
}