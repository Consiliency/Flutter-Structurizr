import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/infrastructure/export/export_manager.dart';

void main() {
  runApp(const C4ExportExample());
}

class C4ExportExample extends StatefulWidget {
  const C4ExportExample({Key? key}) : super(key: key);

  @override
  State<C4ExportExample> createState() => _C4ExportExampleState();
}

class _C4ExportExampleState extends State<C4ExportExample> {
  final ScrollController _scrollController = ScrollController();
  String _exportedContent = '';
  double _exportProgress = 0.0;
  bool _isExporting = false;
  ExportFormat _selectedFormat = ExportFormat.c4json;

  // Create workspace with sample data
  late Workspace _workspace;
  late String _systemContextViewKey;
  late String _containerViewKey;

  @override
  void initState() {
    super.initState();
    _setupWorkspace();
  }

  void _setupWorkspace() {
    // Create a model
    const model = Model();

    // Add people
    final user = model.addPerson(
      'user',
      'Bank Customer',
      'A customer of the bank',
    );

    final admin = model.addPerson(
      'admin',
      'Bank Administrator',
      'An administrator of the bank',
    );

    // Add software systems
    final internetBankingSystem = model.addSoftwareSystem(
      'banking_system',
      'Internet Banking System',
      'Allows customers to view account balances and make payments',
    );

    final mainframeBankingSystem = model.addSoftwareSystem(
      'mainframe',
      'Mainframe Banking System',
      'Stores all core banking information',
    );
    mainframeBankingSystem.location = 'External';

    final emailSystem = model.addSoftwareSystem(
      'email',
      'E-mail System',
      'The bank\'s e-mail system',
    );
    emailSystem.location = 'External';

    // Add relationships
    user.uses(internetBankingSystem, 'Uses', 'HTTPS');
    admin.uses(internetBankingSystem, 'Administers', 'HTTPS');
    internetBankingSystem.uses(
        mainframeBankingSystem, 'Gets account information from', 'JDBC');
    internetBankingSystem.uses(emailSystem, 'Sends e-mail using', 'SMTP');

    // Add containers to the banking system
    final webApp = internetBankingSystem.addContainer(
      'web_app',
      'Web Application',
      'Provides all functionality to customers via web interface',
      'JavaScript, Angular',
    );

    final apiApp = internetBankingSystem.addContainer(
      'api_app',
      'API Application',
      'Provides an API for mobile apps to use',
      'Java, Spring Boot',
    );

    final database = internetBankingSystem.addContainer(
      'database',
      'Database',
      'Stores user registration information, audit logs, etc.',
      'Oracle Database',
    );

    // Add container relationships
    webApp.uses(apiApp, 'Uses', 'JSON/HTTPS');
    apiApp.uses(database, 'Reads/writes to', 'JDBC');
    apiApp.uses(mainframeBankingSystem, 'Uses', 'JSON/HTTPS');

    // Create views
    final views = Views();

    // Create system context view
    _systemContextViewKey = 'SystemContext';
    final contextView = views.createSystemContextView(
      internetBankingSystem,
      _systemContextViewKey,
      'System Context diagram for Internet Banking System',
    );
    contextView.addNearestNeighbours(internetBankingSystem);

    // Create container view
    _containerViewKey = 'Containers';
    final containerView = views.createContainerView(
      internetBankingSystem,
      _containerViewKey,
      'Container diagram for Internet Banking System',
    );
    containerView.addAllContainers();
    containerView.addNearestNeighbours(internetBankingSystem);

    // Create workspace
    _workspace = const Workspace(
        'Banking System', 'Example workspace for banking system');
    _workspace.model = model;
    _workspace.views = views;
  }

  Future<void> _exportToC4() async {
    setState(() {
      _isExporting = true;
      _exportProgress = 0.0;
      _exportedContent = 'Exporting...';
    });

    try {
      final manager = ExportManager();

      final result = await manager.exportDiagram(
        workspace: _workspace,
        viewKey: _selectedFormat == ExportFormat.c4json ||
                _selectedFormat == ExportFormat.c4yaml
            ? _systemContextViewKey
            : _containerViewKey,
        options: ExportOptions(
          format: _selectedFormat,
          width: 1200,
          height: 800,
          includeLegend: true,
          includeTitle: true,
          includeMetadata: true,
          onProgress: (progress) {
            setState(() {
              _exportProgress = progress;
            });
          },
        ),
      );

      setState(() {
        _exportedContent = result as String;
      });
    } catch (e) {
      setState(() {
        _exportedContent = 'Export error: $e';
      });
    } finally {
      setState(() {
        _isExporting = false;
        _exportProgress = 1.0;
      });
    }
  }

  Future<void> _saveToFile() async {
    if (_exportedContent.isEmpty || _exportedContent == 'Exporting...') {
      return;
    }

    final directory = Directory.current;
    final extension = ExportManager.getFileExtension(_selectedFormat);
    final file = File('${directory.path}/export.${extension}');

    await file.writeAsString(_exportedContent);

    setState(() {
      _exportedContent = 'File saved to ${file.path}\n\n$_exportedContent';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'C4 Model Export Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('C4 Model Export Example'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Export a C4 Model Diagram',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Format:'),
                  const SizedBox(width: 16),
                  DropdownButton<ExportFormat>(
                    value: _selectedFormat,
                    onChanged: (newFormat) {
                      if (newFormat != null) {
                        setState(() {
                          _selectedFormat = newFormat;
                        });
                      }
                    },
                    items: [
                      const DropdownMenuItem(
                        value: ExportFormat.c4json,
                        child: Text('C4 Model JSON'),
                      ),
                      const DropdownMenuItem(
                        value: ExportFormat.c4yaml,
                        child: Text('C4 Model YAML'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _isExporting ? null : _exportToC4,
                    child: const Text('Export'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _exportedContent.isNotEmpty &&
                            _exportedContent != 'Exporting...'
                        ? _saveToFile
                        : null,
                    child: const Text('Save to File'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _exportProgress,
              ),
              const SizedBox(height: 16),
              const Text(
                'Exported Content:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SelectableText(
                          _exportedContent,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
