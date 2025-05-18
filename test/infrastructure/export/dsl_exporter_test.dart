import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/documentation/documentation.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/domain/view/views.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';
import 'package:flutter_structurizr/infrastructure/export/diagram_exporter.dart';
import 'package:flutter_structurizr/infrastructure/export/dsl_exporter.dart';
import 'package:logging/logging.dart';
import 'package:flutter_structurizr/domain/model/container.dart';
import 'package:flutter_structurizr/domain/model/component.dart';
import 'package:flutter_structurizr/domain/model/deployment_node.dart';

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print(
        '[\u001b[32m\u001b[1m\u001b[40m\u001b[0m${record.level.name}] ${record.loggerName}: ${record.message}');
  });

  /// Creates a test workspace with sample elements
  Workspace createTestWorkspace({bool includeDocumentation = false}) {
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
    // final container = Container.create('Container', 'Description');

    // final component = Component.create('Component', 'Description');

    // Add containers to system
    final updatedSystem = system.addContainer(Container(
      id: 'web-app',
      name: 'Web Application',
      description: 'The web application',
      parentId: system.id,
      technology: 'Flutter',
    ));

    // Create deployment nodes
    // final deploymentNode = DeploymentNode.create('Node', 'Description');

    // Create a model with all elements
    final model = Model(
      people: [person],
      softwareSystems: [updatedSystem],
      // deploymentNodes: [deploymentNode],
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
      automaticLayout: const AutomaticLayout(
        rankDirection: 'topBottom',
        rankSeparation: 100,
        nodeSeparation: 100,
        edgeSeparation: 10,
      ),
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
        ElementView(
            id: const Container(
          id: 'web-app',
          name: 'Web Application',
        ).id),
      ],
    );

    // Create component view
    final componentView = ComponentView(
      key: 'Components',
      softwareSystemId: system.id,
      containerId: 'web-app',
      title: 'Component Diagram',
      description: 'Shows the components within the container',
      elements: [
        ElementView(
            id: const Container(
          id: 'web-app',
          name: 'Web Application',
        ).id),
        ElementView(
            id: const Component(
          id: 'login-controller',
          name: 'Login Controller',
          description: 'Handles user authentication',
          parentId: 'web-app',
          technology: 'Dart',
        ).id),
      ],
    );

    // Create deployment view
    final deploymentView = DeploymentView(
      key: 'Deployment',
      environment: 'Production',
      title: 'Deployment Diagram',
      description: 'Shows the deployment of the system',
      elements: [
        ElementView(
            id: const DeploymentNode(
          id: 'aws-ec2',
          name: 'AWS EC2',
        ).id),
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

    // Set up workspace styles
    const elementStyle = ElementStyle(
      tag: 'Person',
      // shape: 'RoundedBox',
      background: '#08427B',
      color: '#FFFFFF',
    );

    const relationshipStyle = RelationshipStyle(
      tag: 'Relationship',
      thickness: 2,
      color: '#707070',
    );

    const styles = Styles(
      elements: [elementStyle],
      relationships: [relationshipStyle],
    );

    // Set up workspace configuration
    const configuration = WorkspaceConfiguration(
      properties: {'terminology': 'standardization'},
    );

    // Add documentation if requested
    Documentation? documentation;
    if (includeDocumentation) {
      documentation = Documentation(
        sections: [
          const DocumentationSection(
            title: 'Overview',
            content:
                'This is an overview of the system.\nIt has multiple lines.',
            format: DocumentationFormat.markdown,
            order: 1,
          ),
          const DocumentationSection(
            title: 'Context',
            content:
                '= System Context\n\nThis section describes the system context.',
            format: DocumentationFormat.asciidoc,
            order: 2,
          ),
        ],
        decisions: [
          Decision(
            id: 'ADR-001',
            date: DateTime(2023, 5, 15),
            status: 'Accepted',
            title: 'Use Markdown for documentation',
            content:
                '# ADR-001: Use Markdown\n\n## Decision\nWe will use Markdown for documentation...',
            links: ['ADR-002'],
          ),
          Decision(
            id: 'ADR-002',
            date: DateTime(2023, 6, 20),
            status: 'Proposed',
            title: 'API Documentation Format',
            content:
                '# ADR-002: API Documentation Format\n\n## Context\nWe need to document our APIs...',
            format: DocumentationFormat.markdown,
          ),
        ],
      );
    }

    // Create and return the workspace
    return Workspace(
      id: 1,
      name: 'Test Workspace',
      description: 'A test workspace for Structurizr DSL export',
      model: updatedModel,
      views: views,
      styles: styles,
      configuration: configuration,
      documentation: documentation,
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
      const exporter = DslExporter();

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
      expect(
          dsl,
          contains(
              'description "A test workspace for Structurizr DSL export"'));

      // Check for model elements
      expect(dsl, contains('person "User" "A user of the system"'));
      expect(dsl, contains('softwareSystem "System" "The software system"'));
      expect(
          dsl,
          contains(
              'container "Web Application" "The web application" "Flutter"'));
      expect(
          dsl,
          contains(
              'component "Login Controller" "Handles user authentication" "Dart"'));

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
      const withMetadataExporter = DslExporter(
        includeMetadata: true,
      );

      const noMetadataExporter = DslExporter(
        includeMetadata: false,
      );

      // Export with different settings
      final withMetadataDsl = await withMetadataExporter.export(diagram);
      final noMetadataDsl = await noMetadataExporter.export(diagram);

      // Check for metadata inclusion
      expect(withMetadataDsl, contains('name "Test Workspace"'));
      expect(
          withMetadataDsl,
          contains(
              'description "A test workspace for Structurizr DSL export"'));
      expect(noMetadataDsl, isNot(contains('name "Test Workspace"')));
      expect(
          noMetadataDsl,
          isNot(contains(
              'description "A test workspace for Structurizr DSL export"')));
    });

    test('respects documentation inclusion setting', () async {
      // Create test workspace with documentation and diagram reference
      final workspace = createTestWorkspace(includeDocumentation: true);
      final diagram = DiagramReference(
        workspace: workspace,
        viewKey: 'SystemContext',
      );

      // Create exporters with different documentation settings
      const withDocsExporter = DslExporter(
        includeDocumentation: true,
      );

      const noDocsExporter = DslExporter(
        includeDocumentation: false,
      );

      // Export with different settings
      final withDocsDsl = await withDocsExporter.export(diagram);
      final noDocsDsl = await noDocsExporter.export(diagram);

      // Check that documentation is included when requested
      expect(withDocsDsl, contains('documentation {'));
      expect(withDocsDsl, contains('section "Overview"'));
      expect(withDocsDsl, contains('section "Context"'));
      expect(withDocsDsl, contains('decisions {'));
      expect(withDocsDsl, contains('decision "ADR-001"'));

      // Check that documentation is excluded when not requested
      expect(noDocsDsl, isNot(contains('documentation {')));
      expect(noDocsDsl, isNot(contains('section "Overview"')));
      expect(noDocsDsl, isNot(contains('decisions {')));
    });

    test('respects styles inclusion setting', () async {
      // Create test workspace and diagram reference
      final workspace = createTestWorkspace();
      final diagram = DiagramReference(
        workspace: workspace,
        viewKey: 'SystemContext',
      );

      // Create exporters with different styles settings
      const withStylesExporter = DslExporter(
        includeStyles: true,
      );

      const noStylesExporter = DslExporter(
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
      const withViewsExporter = DslExporter(
        includeViews: true,
      );

      const noViewsExporter = DslExporter(
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
      const twoSpaceExporter = DslExporter(
        indent: '  ',
      );

      const fourSpaceExporter = DslExporter(
        indent: '    ',
      );

      const tabExporter = DslExporter(
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
      const exporter = DslExporter();

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
        views: const Views(),
        styles: const Styles(),
      );

      final diagram = DiagramReference(
        workspace: workspace,
        viewKey: 'test',
      );

      // Create the exporter
      const exporter = DslExporter();

      // Export the diagram
      final dsl = await exporter.export(diagram);

      // Check for proper escaping
      expect(dsl, contains('name "Test \\"Quotes\\""'));
      expect(
          dsl,
          contains(
              'description "Description with \\"quotes\\" and \\\\ backslashes"'));
      expect(
          dsl,
          contains(
              'person "User with \\"quotes\\"" "A user with \\\\ backslashes and \\"quotes\\""'));
    });

    test('exports documentation section correctly', () async {
      // Create test workspace with documentation and diagram reference
      final workspace = createTestWorkspace(includeDocumentation: true);
      final diagram = DiagramReference(
        workspace: workspace,
        viewKey: 'SystemContext',
      );

      // Create the exporter
      const exporter = DslExporter(
        includeDocumentation: true,
      );

      // Export the diagram
      final dsl = await exporter.export(diagram);

      // Check documentation format
      expect(dsl, contains('documentation {'));

      // Check sections
      expect(dsl, contains('section "Overview" {'));
      expect(
          dsl,
          contains(
              'content """This is an overview of the system.\\nIt has multiple lines."""'));

      // Check explicitly specified format (asciidoc)
      expect(dsl, contains('section "Context" {'));
      expect(dsl, contains('format "asciidoc"'));
      expect(
          dsl,
          contains(
              'content """= System Context\\n\\nThis section describes the system context."""'));
    });

    test('exports decisions correctly', () async {
      // Create test workspace with documentation and diagram reference
      final workspace = createTestWorkspace(includeDocumentation: true);
      final diagram = DiagramReference(
        workspace: workspace,
        viewKey: 'SystemContext',
      );

      // Create the exporter
      const exporter = DslExporter(
        includeDocumentation: true,
      );

      // Export the diagram
      final dsl = await exporter.export(diagram);

      // Check decisions section
      expect(dsl, contains('decisions {'));

      // Check decision 1
      expect(dsl, contains('decision "ADR-001" {'));
      expect(dsl, contains('title "Use Markdown for documentation"'));
      expect(dsl, contains('status "Accepted"'));
      expect(dsl, contains('date "2023-05-15"'));
      expect(dsl, contains('links "ADR-002"'));

      // Check decision 2
      expect(dsl, contains('decision "ADR-002" {'));
      expect(dsl, contains('title "API Documentation Format"'));
      expect(dsl, contains('status "Proposed"'));
      expect(dsl, contains('date "2023-06-20"'));
    });
  });
}
