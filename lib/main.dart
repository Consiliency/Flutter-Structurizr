import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_structurizr/application/workspace/workspace_repository.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/presentation/pages/workspace_page.dart';

void main() {
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
            const Text('A cross-platform implementation of the Structurizr architecture visualization tool.'),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                _openWorkspace(context);
              },
              child: const Text('Open Workspace'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _createWorkspace(context);
              },
              child: const Text('Create New Workspace'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openWorkspace(BuildContext context) async {
    try {
      // Use WorkspaceRepository to open file picker and load workspace
      final repository = WorkspaceRepository();
      final workspace = await repository.openWorkspace();

      if (workspace != null && context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => WorkspacePage(workspace: workspace),
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
      final workspace = Workspace(
        name: 'New Workspace',
        description: 'A new Structurizr workspace',
      );

      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => WorkspacePage(workspace: workspace),
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