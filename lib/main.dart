import 'package:flutter/material.dart' hide Container, Border;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/infrastructure/persistence/file_workspace_repository.dart';
import 'package:flutter_structurizr/presentation/pages/workspace_page.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter_structurizr/domain/parser/parser.dart';
import 'package:flutter_structurizr/application/dsl/workspace_mapper_with_builder.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:logging/logging.dart';

void main() {
  // Disable logging to prevent infinite recursion
  Logger.root.level = Level.OFF;
  
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
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Workspace? _workspace;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    
    // Automatically load test workspace on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTestWorkspace();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Structurizr DSL Viewer'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error: $_errorMessage',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              )
            else if (_workspace != null)
              Expanded(
                child: WorkspacePage(workspace: _workspace!),
              )
            else
              const Text(
                'No workspace loaded',
                style: TextStyle(fontSize: 18),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _loadWorkspace,
              child: const Text('Load Workspace'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadWorkspace() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'dsl'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.single.path!);
        final fileExtension = file.path.split('.').last.toLowerCase();

        Workspace? workspace;

        if (fileExtension == 'json') {
          // Load JSON workspace
          final repository = FileWorkspaceRepository(
            workspacesDirectory: './.workspaces',
          );
          workspace = await repository.loadWorkspace(file.path);
        } else if (fileExtension == 'dsl') {
          // Parse DSL file
          print('DEBUG: Starting DSL parsing for file: ${file.path}');
          final content = await file.readAsString();
          final parser = Parser(content);
          final ast = parser.parse();
          print('DEBUG: AST parsing complete');
          print('DEBUG: AST views node is present: ${ast.views != null}');

          // Map AST to Workspace using WorkspaceMapper
          print('DEBUG: Starting workspace mapping');
          final mapper = WorkspaceMapper('<dsl>', ErrorReporter('<dsl>'));
          workspace = mapper.mapWorkspace(ast);
          print('DEBUG: Workspace mapping complete');
          print('DEBUG: Workspace name: ${workspace?.name}');
          print('DEBUG: Workspace description: ${workspace?.description}');
          print('DEBUG: Final workspace views:');
          print('  SystemContextViews: ${workspace?.views.systemContextViews.length ?? 0}');
          print('  ContainerViews: ${workspace?.views.containerViews.length ?? 0}');
          print('  ComponentViews: ${workspace?.views.componentViews.length ?? 0}');
          print('  DeploymentViews: ${workspace?.views.deploymentViews.length ?? 0}');
        }

        if (workspace != null) {
          setState(() {
            _workspace = workspace;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Failed to load workspace';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTestWorkspace() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final file = File('/home/jenner/Code/dart-structurizr/test_simple.dsl');
      
      if (await file.exists()) {
        print('DEBUG: Auto-loading test workspace from: ${file.path}');
        final content = await file.readAsString();
        final parser = Parser(content);
        final ast = parser.parse();
        print('DEBUG: AST parsing complete - auto load');
        print('DEBUG: AST views node is present: ${ast.views != null}');

        final mapper = WorkspaceMapper('<dsl>', ErrorReporter('<dsl>'));
        final workspace = mapper.mapWorkspace(ast);
        print('DEBUG: Workspace mapping complete - auto load');
        print('DEBUG: Workspace name: ${workspace?.name}');
        print('DEBUG: Final workspace views:');
        print('  SystemContextViews: ${workspace?.views.systemContextViews.length ?? 0}');
        print('  ContainerViews: ${workspace?.views.containerViews.length ?? 0}');

        if (workspace != null) {
          setState(() {
            _workspace = workspace;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Failed to load test workspace';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      print('ERROR loading test workspace: $e');
    }
  }
}