# Getting Started with Dart Structurizr

This guide will help you get started with using the Dart Structurizr library.

## Installation

Add the dependency to your `pubspec.yaml` file:

```yaml
dependencies:
  dart_structurizr: ^0.1.0
```

Then run:

```
flutter pub get
```

## Basic Usage

### Loading a Workspace

```dart
import 'package:dart_structurizr/structurizr.dart';
import 'dart:convert';

// Load workspace from JSON
final json = jsonDecode(jsonString);
final workspace = Workspace.fromJson(json);
```

### Rendering a Diagram

```dart
import 'package:flutter/material.dart';
import 'package:dart_structurizr/structurizr.dart';

class DiagramPage extends StatelessWidget {
  final Workspace workspace;
  
  const DiagramPage({Key? key, required this.workspace}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(workspace.name)),
      body: StructurizrDiagram(
        workspace: workspace,
        viewKey: 'SystemContext',
      ),
    );
  }
}
```

### Exporting Diagrams

```dart
import 'package:dart_structurizr/structurizr.dart';

// Export to Mermaid
final exporter = MermaidExporter();
final mermaidDiagram = exporter.exportView(workspace, 'SystemContext');

// Export to PlantUML
final plantUmlExporter = PlantUMLExporter();
final plantUmlDiagram = plantUmlExporter.exportView(workspace, 'SystemContext');
```

## Advanced Topics

For more advanced usage, see the following guides:

- [Creating Models Programmatically](examples/creating_models.md)
- [Custom Styling](examples/custom_styling.md)
- [Exporting to Different Formats](exporters/overview.md)
- [Interactive Diagrams](examples/interactive_diagrams.md)