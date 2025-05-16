import 'package:flutter/material.dart' hide Container, Border;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_structurizr/application/workspace/workspace_repository.dart';
import 'package:flutter_structurizr/domain/model/model.dart' as model;
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/infrastructure/persistence/file_workspace_repository.dart';
import 'package:flutter_structurizr/presentation/pages/workspace_page.dart';
import 'package:flutter_structurizr/domain/style/styles.dart' as style;
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter_structurizr/domain/parser/parser.dart';
import 'package:flutter_structurizr/application/dsl/workspace_mapper_with_builder.dart';
import 'package:flutter_structurizr/application/dsl/workspace_builder_impl.dart';

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
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['json', 'dsl'],
                );
                if (result != null && result.files.single.path != null) {
                  final filePath = result.files.single.path!;
                  try {
                    if (filePath.endsWith('.json')) {
                      final repository = FileWorkspaceRepository(workspacesDirectory: './.workspaces');
                      final workspace = await repository.loadWorkspace(filePath);
                      if (context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => WorkspacePage(workspace: workspace),
                          ),
                        );
                      }
                    } else if (filePath.endsWith('.dsl')) {
                      final dslText = await File(filePath).readAsString();
                      final parser = Parser(dslText, filePath: filePath);
                      final ast = parser.parse();
                      // Debug output for AST views section
                      if (ast.views != null) {
                        print('DEBUG: AST views node is present');
                        print('  SystemContextViews: \\${ast.views?.systemContextViews.length ?? 0}');
                        for (final v in ast.views?.systemContextViews ?? []) {
                          print('    - key: \\${v.key}, title: \\${v.title}');
                        }
                        print('  ContainerViews: \\${ast.views?.containerViews.length ?? 0}');
                        print('  ComponentViews: \\${ast.views?.componentViews.length ?? 0}');
                        print('  DynamicViews: \\${ast.views?.dynamicViews.length ?? 0}');
                        print('  DeploymentViews: \\${ast.views?.deploymentViews.length ?? 0}');
                        print('  CustomViews: \\${ast.views?.customViews.length ?? 0}');
                        print('  ImageViews: \\${ast.views?.imageViews.length ?? 0}');
                      } else {
                        print('DEBUG: AST views node is NULL');
                      }
                      // Use builder-based mapping
                      final mapper = WorkspaceMapper(dslText, parser.errorReporter);
                      final workspace = mapper.mapWorkspace(ast);
                      if (workspace == null) {
                        throw Exception('Failed to map DSL to workspace.');
                      }
                      // Debug output for workspace contents
                      print('DEBUG: Workspace name: \\${workspace.name}');
                      print('DEBUG: Workspace description: \\${workspace.description}');
                      if (workspace.views.systemContextViews.isNotEmpty) {
                        print('DEBUG: SystemContextViews:');
                        for (final v in workspace.views.systemContextViews) {
                          print('  - key: \\${v.key}, title: \\${v.title}, elements: \\${v.elements.length}');
                        }
                      }
                      if (workspace.views.containerViews.isNotEmpty) {
                        print('DEBUG: ContainerViews:');
                        for (final v in workspace.views.containerViews) {
                          print('  - key: \\${v.key}, title: \\${v.title}, elements: \\${v.elements.length}');
                        }
                      }
                      if (workspace.views.componentViews.isNotEmpty) {
                        print('DEBUG: ComponentViews:');
                        for (final v in workspace.views.componentViews) {
                          print('  - key: \\${v.key}, title: \\${v.title}, elements: \\${v.elements.length}');
                        }
                      }
                      if (workspace.views.deploymentViews.isNotEmpty) {
                        print('DEBUG: DeploymentViews:');
                        for (final v in workspace.views.deploymentViews) {
                          print('  - key: \\${v.key}, title: \\${v.title}, elements: \\${v.elements.length}');
                        }
                      }
                      if (context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => WorkspacePage(workspace: workspace),
                          ),
                        );
                      }
                    } else {
                      throw Exception('Unsupported file type.');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error loading workspace: $e')),
                      );
                    }
                  }
                }
              },
              child: const Text('Import Workspace File (.json, .dsl)'),
            ),
            const SizedBox(height: 20),
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
      // Use FileWorkspaceRepository to load workspace
      final repository = FileWorkspaceRepository(workspacesDirectory: './.workspaces');
      
      // For now, create a simple example workspace since we can't open files directly
      final workspace = Workspace(
        id: 1,
        name: 'Example Workspace',
        description: 'A sample workspace for demonstration',
        model: const model.Model(),
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
          SnackBar(content: Text('Error opening workspace: $e')),
        );
      }
    }
  }

  Future<void> _createWorkspace(BuildContext context) async {
    try {
      // Create a new empty workspace
      final workspace = Workspace(
        id: 2,
        name: 'New Workspace',
        description: 'A new Structurizr workspace',
        model: const model.Model(),
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