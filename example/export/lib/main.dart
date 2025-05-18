import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/infrastructure/export/export_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_structurizr/domain/model/container.dart'
    as model_container;

/// An example application demonstrating the Export capabilities of Flutter Structurizr.
void main() {
  runApp(const ExportExampleApp());
}

class ExportExampleApp extends StatelessWidget {
  const ExportExampleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Structurizr Export Example',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: const ExportExampleScreen(),
    );
  }
}

class ExportExampleScreen extends StatefulWidget {
  const ExportExampleScreen({Key? key}) : super(key: key);

  @override
  State<ExportExampleScreen> createState() => _ExportExampleScreenState();
}

class _ExportExampleScreenState extends State<ExportExampleScreen> {
  final ExportManager _exportManager = ExportManager();
  String _exportStatus = 'Ready to export';
  double _exportProgress = 0.0;
  late Workspace _workspace;
  ExportFormat _selectedFormat = ExportFormat.png;
  bool _includeLegend = true;
  bool _includeTitle = true;
  bool _transparentBackground = false;

  @override
  void initState() {
    super.initState();
    _createSampleWorkspace();
  }

  /// Creates a sample workspace for demonstration
  void _createSampleWorkspace() {
    // Create a simple system with a person and a system
    final person = Person.create(
      name: 'User',
      description: 'A user of the system',
    );

    final system = SoftwareSystem.create(
      name: 'Banking System',
      description: 'Handles all banking operations',
    );

    // Create a container
    final webApp = model_container.Container(
      id: 'webApp',
      name: 'Web Application',
      description: 'Provides banking functionality to customers',
      parentId: system.id,
      technology: 'Flutter',
    );

    final database = model_container.Container(
      id: 'database',
      name: 'Database',
      description: 'Stores user accounts and transaction data',
      parentId: system.id,
      technology: 'PostgreSQL',
    );

    // Add containers to system
    final updatedSystem = system.addContainer(webApp).addContainer(database);

    // Add relationships
    final updatedPerson = person.addRelationship(
      destinationId: system.id,
      description: 'Uses',
      technology: 'HTTPS',
    );

    final updatedWebApp = webApp.addRelationship(
      destinationId: database.id,
      description: 'Reads from and writes to',
      technology: 'SQL',
    );

    // Create model
    final model = Model(
      enterpriseName: 'ACME Bank',
      people: [updatedPerson],
      softwareSystems: [updatedSystem],
    );

    // Create System Context view
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

    // Create Container view
    final containerView = ContainerView(
      key: 'Containers',
      softwareSystemId: system.id,
      title: 'Container Diagram',
      description: 'Shows the containers within the system',
      elements: [
        ElementView(id: person.id),
        ElementView(id: system.id),
        ElementView(id: webApp.id),
        ElementView(id: database.id),
      ],
      relationships: [
        const RelationshipView(id: 'rel1'),
        const RelationshipView(id: 'rel2'),
      ],
    );

    // Create workspace
    _workspace = Workspace(
      id: 1,
      name: 'Banking System',
      description: 'An example banking system',
      model: model,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Structurizr Export Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Export Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Format selection
            Row(
              children: [
                const Text('Export Format:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                DropdownButton<ExportFormat>(
                  value: _selectedFormat,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedFormat = value;
                      });
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: ExportFormat.png,
                      child: Text('PNG Image'),
                    ),
                    DropdownMenuItem(
                      value: ExportFormat.svg,
                      child: Text('SVG Vector Image'),
                    ),
                    DropdownMenuItem(
                      value: ExportFormat.plantuml,
                      child: Text('PlantUML'),
                    ),
                    DropdownMenuItem(
                      value: ExportFormat.c4plantuml,
                      child: Text('C4-PlantUML'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Options
            CheckboxListTile(
              title: const Text('Include Legend'),
              value: _includeLegend,
              onChanged: (value) {
                setState(() {
                  _includeLegend = value ?? true;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            ),

            CheckboxListTile(
              title: const Text('Include Title'),
              value: _includeTitle,
              onChanged: (value) {
                setState(() {
                  _includeTitle = value ?? true;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            ),

            if (_selectedFormat == ExportFormat.png)
              CheckboxListTile(
                title: const Text('Transparent Background'),
                value: _transparentBackground,
                onChanged: (value) {
                  setState(() {
                    _transparentBackground = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),

            const SizedBox(height: 24),

            // Export buttons
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _exportDiagram('SystemContext'),
                  child: const Text('Export System Context'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => _exportDiagram('Containers'),
                  child: const Text('Export Container Diagram'),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Progress and status
            Text('Status: $_exportStatus'),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: _exportProgress),
          ],
        ),
      ),
    );
  }

  /// Exports a diagram with the currently selected settings
  Future<void> _exportDiagram(String viewKey) async {
    setState(() {
      _exportStatus = 'Exporting $viewKey diagram...';
      _exportProgress = 0.0;
    });

    try {
      // Create export options
      final options = ExportOptions(
        format: _selectedFormat,
        width: 1920,
        height: 1080,
        includeLegend: _includeLegend,
        includeTitle: _includeTitle,
        transparentBackground: _transparentBackground,
        onProgress: (progress) {
          setState(() {
            _exportProgress = progress;
          });
        },
      );

      // Export the diagram
      final result = await _exportManager.exportDiagram(
        workspace: _workspace,
        viewKey: viewKey,
        options: options,
      );

      // Save the exported file
      final extension = ExportManager.getFileExtension(_selectedFormat);
      final filename = 'structurizr_${_workspace.name}_${viewKey}.$extension';
      await _saveExportedFile(result, filename);

      setState(() {
        _exportStatus = 'Export complete: $filename';
        _exportProgress = 1.0;
      });
    } catch (e) {
      setState(() {
        _exportStatus = 'Export failed: ${e.toString()}';
        _exportProgress = 0.0;
      });
    }
  }

  /// Saves the exported file to the downloads directory
  Future<void> _saveExportedFile(dynamic content, String filename) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/$filename';

      final file = File(path);

      if (content is Uint8List) {
        // Binary data (PNG)
        await file.writeAsBytes(content);
      } else if (content is String) {
        // Text data (SVG, PlantUML)
        await file.writeAsString(content);
      }

      // TODO('Replace with logging: File saved to: $path');
    } catch (e) {
      // TODO('Replace with logging: Error saving file: $e');
      rethrow;
    }
  }
}
