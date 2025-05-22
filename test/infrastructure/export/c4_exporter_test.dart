import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/view/views.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/infrastructure/export/c4_exporter.dart';
import 'package:flutter_structurizr/infrastructure/export/diagram_exporter.dart';

void main() {
  group('C4Exporter', () {
    late Workspace testWorkspace;
    late String systemContextViewKey;

    setUp(() {
      // Create a test workspace with a basic system context view
      // Using the actual API structure

      // Create a Person using the factory method
      final user = Person.create(
        name: 'User',
        description: 'A user of the system',
      );

      // Create a SoftwareSystem
      final softwareSystem = SoftwareSystem.create(
        name: 'Software System',
        description: 'Description of the system',
      );

      // Create another SoftwareSystem for external system
      final database = SoftwareSystem.create(
        name: 'Database System',
        description: 'Stores data',
        location: 'External',
      );

      // Add relationships between elements
      final userWithRelationship = user.addRelationship(
        destinationId: softwareSystem.id,
        description: 'Uses',
        technology: 'HTTPS',
      );

      final systemWithRelationship = softwareSystem.addRelationship(
        destinationId: database.id,
        description: 'Reads/writes to',
        technology: 'JDBC',
      );

      // Create model
      final model = Model(
        people: [userWithRelationship],
        softwareSystems: [systemWithRelationship, database],
      );

      // Create views
      const views = Views();

      // Create a SystemContextView
      systemContextViewKey = 'context';
      final contextView = SystemContextView(
        key: systemContextViewKey,
        softwareSystemId: softwareSystem.id,
        title: 'System Context Diagram',
        elements: [
          ElementView(id: userWithRelationship.id),
          ElementView(id: systemWithRelationship.id),
          ElementView(id: database.id),
        ],
        relationships: [
          RelationshipView(id: userWithRelationship.relationships[0].id),
          RelationshipView(id: systemWithRelationship.relationships[0].id),
        ],
      );

      // Add the view to views
      final updatedViews = views.addSystemContextView(contextView);

      // Create the workspace
      testWorkspace = Workspace(
        id: 1,
        name: 'Test Workspace',
        description: 'Test workspace for C4 export',
        model: model,
        views: updatedViews,
      );
    });

    test('Exports to JSON format', () async {
      // Arrange
      const exporter = C4Exporter(
        style: C4DiagramStyle.standard,
        format: C4OutputFormat.json,
        includeMetadata: true,
        includeRelationships: true,
        includeStyles: true,
      );

      final diagram = DiagramReference(
        workspace: testWorkspace,
        viewKey: systemContextViewKey,
      );

      // Act
      final result = await exporter.export(diagram);

      // Assert
      expect(result, isA<String>());
      expect(result, contains('"type": "SystemContext"'));
      expect(result, contains('"scope": "Software System"'));
      expect(result, contains('"elements": ['));
      expect(result, contains('"relationships": ['));
      expect(result, contains('"styles": {'));
      expect(result, contains('"type": "person"'));
      expect(result, contains('"type": "softwareSystem"'));
    });

    test('Exports to YAML format', () async {
      // Arrange
      const exporter = C4Exporter(
        style: C4DiagramStyle.standard,
        format: C4OutputFormat.yaml,
        includeMetadata: true,
        includeRelationships: true,
        includeStyles: true,
      );

      final diagram = DiagramReference(
        workspace: testWorkspace,
        viewKey: systemContextViewKey,
      );

      // Act
      final result = await exporter.export(diagram);

      // Assert
      expect(result, isA<String>());
      expect(result, contains('type: SystemContext'));
      expect(result, contains('scope: Software System'));
      expect(result, contains('elements:'));
      expect(result, contains('relationships:'));
      expect(result, contains('styles:'));
      expect(result, contains('type: person'));
      expect(result, contains('type: softwareSystem'));
    });

    test('Exports with enhanced styling', () async {
      // Arrange
      const exporter = C4Exporter(
        style: C4DiagramStyle.enhanced,
        format: C4OutputFormat.json,
        includeMetadata: true,
        includeRelationships: true,
        includeStyles: true,
      );

      final diagram = DiagramReference(
        workspace: testWorkspace,
        viewKey: systemContextViewKey,
      );

      // Act
      final result = await exporter.export(diagram);

      // Assert
      expect(result, isA<String>());
      expect(result, contains('"customStyles"'));
    });

    test('Respects metadata inclusion flag', () async {
      // Arrange
      const exporter = C4Exporter(
        style: C4DiagramStyle.standard,
        format: C4OutputFormat.json,
        includeMetadata: false,
        includeRelationships: true,
        includeStyles: true,
      );

      final diagram = DiagramReference(
        workspace: testWorkspace,
        viewKey: systemContextViewKey,
      );

      // Act
      final result = await exporter.export(diagram);

      // Assert
      expect(result, isA<String>());
      expect(result, isNot(contains('"type": "SystemContext"')));
      expect(result, isNot(contains('"scope": "Software System"')));
      expect(result, contains('"elements": ['));
    });

    test('Respects relationships inclusion flag', () async {
      // Arrange
      const exporter = C4Exporter(
        style: C4DiagramStyle.standard,
        format: C4OutputFormat.json,
        includeMetadata: true,
        includeRelationships: false,
        includeStyles: true,
      );

      final diagram = DiagramReference(
        workspace: testWorkspace,
        viewKey: systemContextViewKey,
      );

      // Act
      final result = await exporter.export(diagram);

      // Assert
      expect(result, isA<String>());
      expect(result, contains('"elements": ['));
      expect(result, isNot(contains('"relationships": [')));
    });

    test('Respects styles inclusion flag', () async {
      // Arrange
      const exporter = C4Exporter(
        style: C4DiagramStyle.standard,
        format: C4OutputFormat.json,
        includeMetadata: true,
        includeRelationships: true,
        includeStyles: false,
      );

      final diagram = DiagramReference(
        workspace: testWorkspace,
        viewKey: systemContextViewKey,
      );

      // Act
      final result = await exporter.export(diagram);

      // Assert
      expect(result, isA<String>());
      expect(result, contains('"elements": ['));
      expect(result, isNot(contains('"styles": {')));
    });
  });
}
