import 'package:flutter/material.dart' hide Container, Border;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_structurizr/domain/model/model.dart' as model;
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/presentation/pages/workspace_page.dart';
import 'package:logging/logging.dart';

final logger = Logger('Main');

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    logger.info(
        '[[32m[1m[40m[0m${record.level.name}] ${record.loggerName}: ${record.message}');
  });
  runApp(
    const ProviderScope(
      child: StructurizrApp(),
    ),
  );
}

class StructurizrApp extends StatelessWidget {
  const StructurizrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Structurizr',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1168BD)),
        useMaterial3: true,
        fontFamily: 'OpenSans',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1168BD),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'OpenSans',
      ),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Structurizr'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Flutter Structurizr',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
                'A cross-platform implementation of the Structurizr architecture visualization tool.'),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                _openSampleWorkspace(context);
              },
              child: const Text('Open Sample Workspace'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _createWorkspace(context);
              },
              child: const Text('Create New Workspace'),
            ),
            const SizedBox(height: 20),
            Text(
              'File import coming soon...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSampleWorkspace(BuildContext context) async {
    try {
      // Create a sample workspace with some basic elements
      const workspace = Workspace(
        id: 1,
        name: 'Sample E-Commerce System',
        description: 'A sample e-commerce system demonstrating C4 model concepts',
        model: model.Model(
          people: [
            model.Person(
              id: 'customer',
              name: 'Customer',
              description: 'A customer of the e-commerce system',
              type: 'Person',
              tags: ['Person', 'External'],
            ),
            model.Person(
              id: 'admin',
              name: 'Administrator',
              description: 'An administrator of the e-commerce system',
              type: 'Person',
              tags: ['Person', 'Internal'],
            ),
          ],
          softwareSystems: [
            model.SoftwareSystem(
              id: 'ecommerce',
              name: 'E-Commerce System',
              description: 'Main e-commerce application',
              type: 'SoftwareSystem',
              tags: ['SoftwareSystem'],
            ),
            model.SoftwareSystem(
              id: 'payment',
              name: 'Payment Gateway',
              description: 'External payment processing system',
              type: 'SoftwareSystem',
              tags: ['SoftwareSystem', 'External'],
            ),
          ],
        ),
      );

      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const WorkspacePage(workspace: workspace),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening workspace: $e')),
        );
      }
    }
  }

  Future<void> _createWorkspace(BuildContext context) async {
    try {
      // Create a new empty workspace
      const workspace = Workspace(
        id: 2,
        name: 'New Workspace',
        description: 'A new Structurizr workspace',
        model: model.Model(),
      );

      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const WorkspacePage(workspace: workspace),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating workspace: $e')),
        );
      }
    }
  }
}