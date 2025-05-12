import 'package:flutter/material.dart' hide Element, Container, View;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/infrastructure/export/diagram_exporter.dart';
import 'package:flutter_structurizr/infrastructure/export/dot_exporter.dart';

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
    
    // Create and return the workspace
    return Workspace(
      id: 1,
      name: 'Test Workspace',
      model: updatedModel,
    );
  }

  group('DotExporter', () {
    test('exports system context diagram to DOT format', () async {
      // Create test workspace and diagram reference
      final workspace = createTestWorkspace();
      final diagram = DiagramReference(
        workspace: workspace,
        viewKey: 'SystemContext',
      );
      
      // Create the exporter
      final exporter = DotExporter();
      
      // Export the diagram
      final dot = await exporter.export(diagram);
      
      // The output should be a string
      expect(dot, isA<String>());
      
      // Check for basic DOT syntax
      expect(dot, contains('digraph "System Context Diagram" {'));
      expect(dot, contains('graph ['));
      expect(dot, contains('node ['));
      expect(dot, contains('edge ['));
      
      // Check for person and system entities
      expect(dot, contains('User'));
      expect(dot, contains('System'));
      
      // Check for relationship
      expect(dot, contains('Uses'));
      expect(dot, contains('-> '));
    });
    
    test('exports container diagram to DOT format', () async {
      // Create test workspace and diagram reference
      final workspace = createTestWorkspace();
      final diagram = DiagramReference(
        workspace: workspace,
        viewKey: 'Containers',
      );
      
      // Create the exporter
      final exporter = DotExporter();
      
      // Export the diagram
      final dot = await exporter.export(diagram);
      
      // The output should be a string
      expect(dot, isA<String>());
      
      // Check for basic DOT syntax
      expect(dot, contains('digraph "Container Diagram" {'));
      
      // Check for elements
      expect(dot, contains('User'));
      expect(dot, contains('System'));
      expect(dot, contains('Web Application'));
      
      // Check for cluster
      expect(dot, contains('subgraph cluster_'));
    });
    
    test('exports component diagram to DOT format', () async {
      // Create test workspace and diagram reference
      final workspace = createTestWorkspace();
      final diagram = DiagramReference(
        workspace: workspace,
        viewKey: 'Components',
      );
      
      // Create the exporter
      final exporter = DotExporter();
      
      // Export the diagram
      final dot = await exporter.export(diagram);
      
      // The output should be a string
      expect(dot, isA<String>());
      
      // Check for basic DOT syntax
      expect(dot, contains('digraph "Component Diagram" {'));
      
      // Check for container and component
      expect(dot, contains('Web Application'));
      expect(dot, contains('Login Controller'));
      
      // Check for technology info
      expect(dot, contains('Flutter'));
      expect(dot, contains('Dart'));
    });
    
    test('exports deployment diagram to DOT format', () async {
      // Create test workspace and diagram reference
      final workspace = createTestWorkspace();
      final diagram = DiagramReference(
        workspace: workspace,
        viewKey: 'Deployment',
      );
      
      // Create the exporter
      final exporter = DotExporter();
      
      // Export the diagram
      final dot = await exporter.export(diagram);
      
      // The output should be a string
      expect(dot, isA<String>());
      
      // Check for basic DOT syntax
      expect(dot, contains('digraph "Deployment Diagram (Production)" {'));
      
      // Check for deployment node
      expect(dot, contains('AWS EC2'));
      expect(dot, contains('Amazon EC2'));
    });
    
    test('respects different layout settings', () async {
      // Create test workspace and diagram reference
      final workspace = createTestWorkspace();
      final diagram = DiagramReference(
        workspace: workspace,
        viewKey: 'SystemContext',
      );
      
      // Create exporters with different layouts
      final dotExporter = DotExporter(
        layout: DotLayout.dot,
      );
      
      final neatoExporter = DotExporter(
        layout: DotLayout.neato,
      );
      
      // Export with different layouts
      final dotDot = await dotExporter.export(diagram);
      final neatoDot = await neatoExporter.export(diagram);
      
      // Check for layout type
      expect(dotDot, contains('digraph'));
      expect(neatoDot, contains('graph'));
    });
    
    test('respects different rank direction settings', () async {
      // Create test workspace and diagram reference
      final workspace = createTestWorkspace();
      final diagram = DiagramReference(
        workspace: workspace,
        viewKey: 'SystemContext',
      );
      
      // Create exporters with different rank directions
      final topBottomExporter = DotExporter(
        rankDirection: DotRankDirection.topToBottom,
      );
      
      final leftRightExporter = DotExporter(
        rankDirection: DotRankDirection.leftToRight,
      );
      
      // Export with different settings
      final tbDot = await topBottomExporter.export(diagram);
      final lrDot = await leftRightExporter.export(diagram);
      
      // Check for rankdir settings
      expect(tbDot, contains('rankdir = TB'));
      expect(lrDot, contains('rankdir = LR'));
    });
    
    test('includes or excludes clusters based on setting', () async {
      // Create test workspace and diagram reference
      final workspace = createTestWorkspace();
      final diagram = DiagramReference(
        workspace: workspace,
        viewKey: 'Containers',
      );
      
      // Create exporters with different cluster settings
      final withClustersExporter = DotExporter(
        includeClusters: true,
      );
      
      final noClustersExporter = DotExporter(
        includeClusters: false,
      );
      
      // Export with different settings
      final withClustersDot = await withClustersExporter.export(diagram);
      final noClustersDot = await noClustersExporter.export(diagram);
      
      // Check for cluster usage
      expect(withClustersDot, contains('subgraph cluster_'));
      
      // This is a bit tricky since the string "cluster_" could appear in the no-cluster version
      // in the legend, so we look for a specific pattern that would only appear in a system cluster
      final regex = RegExp(r'subgraph cluster_.*label = "System"');
      expect(regex.hasMatch(withClustersDot), isTrue);
      expect(regex.hasMatch(noClustersDot), isFalse);
    });
    
    test('includes or excludes detailed labels based on setting', () async {
      // Create test workspace and diagram reference
      final workspace = createTestWorkspace();
      final diagram = DiagramReference(
        workspace: workspace,
        viewKey: 'Components',
      );
      
      // Create exporters with different label settings
      final detailedExporter = DotExporter(
        includeDetailedLabels: true,
      );
      
      final simpleExporter = DotExporter(
        includeDetailedLabels: false,
      );
      
      // Export with different settings
      final detailedDot = await detailedExporter.export(diagram);
      final simpleDot = await simpleExporter.export(diagram);
      
      // Check for detailed labels
      // Detailed labels include descriptions which are longer
      expect(detailedDot.length, greaterThan(simpleDot.length));
      
      // Check for specific patterns
      expect(detailedDot.contains('Handles user authentication'), isTrue);
      expect(simpleDot.contains('Handles user authentication'), isFalse);
    });
    
    test('includes or excludes custom styling based on setting', () async {
      // Create test workspace and diagram reference
      final workspace = createTestWorkspace();
      final diagram = DiagramReference(
        workspace: workspace,
        viewKey: 'SystemContext',
      );
      
      // Create exporters with different styling settings
      final styledExporter = DotExporter(
        includeCustomStyling: true,
      );
      
      final unstyledExporter = DotExporter(
        includeCustomStyling: false,
      );
      
      // Export with different settings
      final styledDot = await styledExporter.export(diagram);
      final unstyledDot = await unstyledExporter.export(diagram);
      
      // Check for styling attributes
      expect(styledDot, contains('fillcolor = "#08427B"'));
      expect(unstyledDot, isNot(contains('fillcolor = "#08427B"')));
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
      final exporter = DotExporter(
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
      final exporter = DotExporter(
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
      for (final dot in results) {
        expect(dot, isA<String>());
        expect(dot, contains('digraph'));
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
      final exporter = DotExporter();
      
      // Exporting should throw an exception
      expect(() => exporter.export(diagram), throwsException);
    });
  });
}