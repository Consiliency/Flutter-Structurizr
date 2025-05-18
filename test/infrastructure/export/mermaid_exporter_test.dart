import 'package:flutter/material.dart' hide Element, Container, View;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/infrastructure/export/diagram_exporter.dart';
import 'package:flutter_structurizr/infrastructure/export/mermaid_exporter.dart';

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
        const RelationshipView(id: 'rel1'),
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

    // Create and return the workspace
    return Workspace(
      id: 1,
      name: 'Test Workspace',
      model: updatedModel,
    );
  }

  group('MermaidExporter', () {
    test('exports system context diagram to Mermaid format', () async {
      // Create test workspace and diagram reference
      final workspace = createTestWorkspace();
      final diagram = DiagramReference(
        workspace: workspace,
        viewKey: 'SystemContext',
      );

      // Create the exporter
      const exporter = MermaidExporter();

      // Export the diagram
      final mermaid = await exporter.export(diagram);

      // The output should be a string
      expect(mermaid, isA<String>());

      // Check for basic Mermaid syntax
      expect(mermaid, contains('graph TD'));
      expect(mermaid, contains('%% System Context Diagram'));

      // Check for person and system entities
      expect(mermaid, contains('User'));
      expect(mermaid, contains('System'));

      // Check for relationship
      expect(mermaid, contains('Uses'));
    });

    test('exports container diagram to Mermaid format', () async {
      // Create test workspace and diagram reference
      final workspace = createTestWorkspace();
      final diagram = DiagramReference(
        workspace: workspace,
        viewKey: 'Containers',
      );

      // Create the exporter
      const exporter = MermaidExporter();

      // Export the diagram
      final mermaid = await exporter.export(diagram);

      // The output should be a string
      expect(mermaid, isA<String>());

      // Check for basic Mermaid syntax
      expect(mermaid, contains('graph TD'));
      expect(mermaid, contains('%% Container Diagram'));

      // Check for elements
      expect(mermaid, contains('User'));
      expect(mermaid, contains('System'));
      expect(mermaid, contains('Web Application'));

      // Check for subgraph for system
      expect(mermaid, contains('subgraph'));
    });

    test('exports component diagram to Mermaid format', () async {
      // Create test workspace and diagram reference
      final workspace = createTestWorkspace();
      final diagram = DiagramReference(
        workspace: workspace,
        viewKey: 'Components',
      );

      // Create the exporter
      const exporter = MermaidExporter();

      // Export the diagram
      final mermaid = await exporter.export(diagram);

      // The output should be a string
      expect(mermaid, isA<String>());

      // Check for basic Mermaid syntax
      expect(mermaid, contains('graph TD'));
      expect(mermaid, contains('%% Component Diagram'));

      // Check for container and component
      expect(mermaid, contains('Web Application'));
      expect(mermaid, contains('Login Controller'));

      // Check for technology info
      expect(mermaid, contains('Flutter'));
      expect(mermaid, contains('Dart'));
    });

    test('exports deployment diagram to Mermaid format', () async {
      // Create test workspace and diagram reference
      final workspace = createTestWorkspace();
      final diagram = DiagramReference(
        workspace: workspace,
        viewKey: 'Deployment',
      );

      // Create the exporter
      const exporter = MermaidExporter();

      // Export the diagram
      final mermaid = await exporter.export(diagram);

      // The output should be a string
      expect(mermaid, isA<String>());

      // Check for basic Mermaid syntax
      expect(mermaid, contains('graph TD'));

      // Check for deployment node
      expect(mermaid, contains('AWS EC2'));
      expect(mermaid, contains('Amazon EC2'));
    });

    test('respects different direction settings', () async {
      // Create test workspace and diagram reference
      final workspace = createTestWorkspace();
      final diagram = DiagramReference(
        workspace: workspace,
        viewKey: 'SystemContext',
      );

      // Create exporters with different directions
      const topDownExporter = MermaidExporter(
        direction: MermaidDirection.topToBottom,
      );

      const leftRightExporter = MermaidExporter(
        direction: MermaidDirection.leftToRight,
      );

      // Export with different directions
      final topDownMermaid = await topDownExporter.export(diagram);
      final leftRightMermaid = await leftRightExporter.export(diagram);

      // Check for direction settings
      expect(topDownMermaid, contains('graph TD'));
      expect(leftRightMermaid, contains('graph LR'));
    });

    test('includes or excludes theming based on setting', () async {
      // Create test workspace and diagram reference
      final workspace = createTestWorkspace();
      final diagram = DiagramReference(
        workspace: workspace,
        viewKey: 'SystemContext',
      );

      // Create exporters with different theme settings
      const withThemeExporter = MermaidExporter(
        includeTheme: true,
      );

      const noThemeExporter = MermaidExporter(
        includeTheme: false,
      );

      // Export with different settings
      final withThemeMermaid = await withThemeExporter.export(diagram);
      final noThemeMermaid = await noThemeExporter.export(diagram);

      // Check for styling
      expect(withThemeMermaid, contains('classDef'));
      expect(noThemeMermaid, isNot(contains('classDef')));
    });

    test('includes or excludes notes based on setting', () async {
      // Create test workspace and diagram reference
      final workspace = createTestWorkspace();
      final diagram = DiagramReference(
        workspace: workspace,
        viewKey: 'SystemContext',
      );

      // Create exporters with different notes settings
      const withNotesExporter = MermaidExporter(
        includeNotes: true,
      );

      const noNotesExporter = MermaidExporter(
        includeNotes: false,
      );

      // Export with different settings
      final withNotesMermaid = await withNotesExporter.export(diagram);
      final noNotesMermaid = await noNotesExporter.export(diagram);

      // Check for notes
      expect(withNotesMermaid, contains('_note'));
      expect(noNotesMermaid, isNot(contains('_note')));
    });

    test('uses C4 styling when specified', () async {
      // Create test workspace and diagram reference
      final workspace = createTestWorkspace();
      final diagram = DiagramReference(
        workspace: workspace,
        viewKey: 'SystemContext',
      );

      // Create exporters with different style settings
      const standardExporter = MermaidExporter(
        style: MermaidStyle.standard,
      );

      const c4Exporter = MermaidExporter(
        style: MermaidStyle.c4,
      );

      // Export with different settings
      final standardMermaid = await standardExporter.export(diagram);
      final c4Mermaid = await c4Exporter.export(diagram);

      // Check for C4 specific elements
      expect(c4Mermaid, contains('Legend'));
      expect(standardMermaid, isNot(contains('Legend')));
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
      final exporter = MermaidExporter(
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
      final exporter = MermaidExporter(
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

      // Check each result
      for (final mermaid in results) {
        expect(mermaid, isA<String>());
        expect(mermaid, contains('graph TD'));
      }

      // Progress should reach 100%
      expect(batchProgress, equals(1.0));
    });

    test('handles error cases gracefully', () async {
      // Create test workspace with an invalid view key
      final workspace = createTestWorkspace();
      final diagram = DiagramReference(
        workspace: workspace,
        viewKey: 'NonExistentView', // This view doesn't exist
      );

      // Create the exporter
      const exporter = MermaidExporter();

      // Exporting should throw an exception
      expect(() => exporter.export(diagram), throwsException);
    });
  });
}
