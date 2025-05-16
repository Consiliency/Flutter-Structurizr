import 'package:flutter/material.dart';

import 'animation_example.dart';
import 'c4_export_example.dart';
import 'documentation_example.dart';
import 'element_explorer_example.dart';
import 'dynamic_view_example.dart';
import 'export_example.dart';
import 'theme_example.dart';

/// Example application showcasing various features of the Dart Structurizr library
void main() {
  runApp(const DartStructurizrExampleApp());
}

/// Main example application
class DartStructurizrExampleApp extends StatelessWidget {
  /// Create a new example app
  const DartStructurizrExampleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dart Structurizr Examples',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const ExampleListPage(),
    );
  }
}

/// Example list page
class ExampleListPage extends StatelessWidget {
  /// Create a new example list page
  const ExampleListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dart Structurizr Examples'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.explore),
              title: const Text('Element Explorer'),
              subtitle: const Text('Tree view with context menu and drag support'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ElementExplorerExampleApp(),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.animation),
              title: const Text('Animation'),
              subtitle: const Text('Dynamic view animations'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AnimationExampleApp(),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.doc_chart),
              title: const Text('Dynamic View'),
              subtitle: const Text('Interactive sequence diagrams'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DynamicViewExampleApp(),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Documentation'),
              subtitle: const Text('Rich documentation and decision tracking'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DocumentationExampleApp(),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Export'),
              subtitle: const Text('Export to various formats'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExportExampleApp(),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.schema),
              title: const Text('C4 Model Export'),
              subtitle: const Text('Export to C4 model formats (JSON/YAML)'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const C4ExportExample(),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.color_lens),
              title: const Text('Theme'),
              subtitle: const Text('Custom theming and styles'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ThemeExampleApp(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}