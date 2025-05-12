import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/infrastructure/export/diagram_exporter.dart';
import 'package:flutter_structurizr/infrastructure/export/png_exporter.dart';

void main() {
  /// Creates a test workspace with sample elements
  Workspace createTestWorkspace() {
    // Create a simple system with a person and a system
    final person = Person.create(
      name: 'User',
      description: 'A user of the system',
    );
    
    final system = SoftwareSystem.create(
      name: 'System',
      description: 'The software system',
    );
    
    final model = Model(
      people: [person],
      softwareSystems: [system],
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
      ],
    );
    
    // Create views collection
    final views = BaseView(
      key: 'views',
      elements: [...systemContextView.elements, ...containerView.elements],
      relationships: [...systemContextView.relationships],
      viewType: 'Views',
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

  group('PngExporter', () {
    testWidgets('exports diagram to PNG format', (WidgetTester tester) async {
      // Create test workspace and diagram reference
      final workspace = createTestWorkspace();
      final diagram = DiagramReference(
        workspace: workspace,
        viewKey: 'SystemContext',
      );
      
      // Create the exporter
      final exporter = PngExporter(
        scaleFactor: 1.0, // Use lower resolution for tests
      );
      
      // Track progress
      double exportProgress = 0.0;
      final progressExporter = PngExporter(
        scaleFactor: 1.0,
        onProgress: (progress) {
          exportProgress = progress;
        },
      );
      
      // Export the diagram
      final bytes = await exporter.export(diagram);
      
      // Basic verification
      expect(bytes, isA<Uint8List>());
      expect(bytes.isNotEmpty, true);
      
      // Verify PNG signature at start of file
      expect(bytes.length, greaterThan(8));
      expect(bytes.sublist(0, 8), equals([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]));
      
      // Test with progress tracking
      await progressExporter.export(diagram);
      expect(exportProgress, equals(1.0)); // Should complete with 100% progress
    });
    
    testWidgets('respects render parameters', (WidgetTester tester) async {
      // Create test workspace and diagram reference
      final workspace = createTestWorkspace();
      final diagram = DiagramReference(
        workspace: workspace,
        viewKey: 'SystemContext',
      );
      
      // Create exporters with different parameters
      final defaultExporter = PngExporter();
      
      final customExporter = PngExporter(
        renderParameters: DiagramRenderParameters(
          width: 800,
          height: 600,
          includeLegend: false,
          includeTitle: false,
        ),
      );
      
      // Export with both exporters
      final defaultBytes = await defaultExporter.export(diagram);
      final customBytes = await customExporter.export(diagram);
      
      // Both should be valid PNGs
      expect(defaultBytes.sublist(0, 8), equals([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]));
      expect(customBytes.sublist(0, 8), equals([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]));
      
      // Custom parameters should produce different output (usually smaller)
      expect(defaultBytes.length, isNot(equals(customBytes.length)));
    });
    
    testWidgets('supports transparent background', (WidgetTester tester) async {
      // Create test workspace and diagram reference
      final workspace = createTestWorkspace();
      final diagram = DiagramReference(
        workspace: workspace,
        viewKey: 'SystemContext',
      );
      
      // Create exporters with different backgrounds
      final opaqueExporter = PngExporter(
        transparentBackground: false,
      );
      
      final transparentExporter = PngExporter(
        transparentBackground: true,
      );
      
      // Export with both exporters
      final opaqueBytes = await opaqueExporter.export(diagram);
      final transparentBytes = await transparentExporter.export(diagram);
      
      // Both should be valid PNGs
      expect(opaqueBytes.sublist(0, 8), equals([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]));
      expect(transparentBytes.sublist(0, 8), equals([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]));
      
      // The files should be different
      expect(opaqueBytes.length, isNot(equals(transparentBytes.length)));
    });
    
    testWidgets('handles error cases gracefully', (WidgetTester tester) async {
      // Create test workspace with an invalid view key
      final workspace = createTestWorkspace();
      final diagram = DiagramReference(
        workspace: workspace,
        viewKey: 'NonExistentView', // This view doesn't exist
      );
      
      // Create the exporter
      final exporter = PngExporter();
      
      // Exporting should throw an exception
      expect(() => exporter.export(diagram), throwsException);
    });
    
    testWidgets('exports batch of diagrams', (WidgetTester tester) async {
      // Create test workspace and multiple diagram references
      final workspace = createTestWorkspace();
      final diagrams = [
        DiagramReference(
          workspace: workspace,
          viewKey: 'SystemContext',
          title: 'System Context Custom Title',
        ),
        DiagramReference(
          workspace: workspace,
          viewKey: 'Containers',
        ),
      ];
      
      // Create the exporter with progress tracking
      double batchProgress = 0.0;
      final exporter = PngExporter(
        scaleFactor: 1.0, // Use lower resolution for tests
      );
      
      // Export the diagrams in batch
      final results = await exporter.exportBatch(
        diagrams,
        onProgress: (progress) {
          batchProgress = progress;
        },
      );
      
      // Verify the results
      expect(results, isA<List<Uint8List>>());
      expect(results.length, equals(2));
      
      // Check each result
      for (final bytes in results) {
        expect(bytes, isA<Uint8List>());
        expect(bytes.isNotEmpty, true);
        expect(bytes.sublist(0, 8), equals([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]));
      }
      
      // Progress should reach 100%
      expect(batchProgress, equals(1.0));
    });
  });
}