import 'package:flutter/material.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/presentation/widgets/diagram/animation_controls.dart';
import 'package:flutter_structurizr/presentation/widgets/diagram/dynamic_view_diagram.dart';
import 'package:flutter_structurizr/presentation/widgets/diagram/structurizr_diagram.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Structurizr Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TestPage(),
    );
  }
}

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage>
    with SingleTickerProviderStateMixin {
  late Workspace workspace;
  late DynamicView dynamicView;
  late TabController _tabController;

  late DynamicViewDiagramConfig _config;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _config = const DynamicViewDiagramConfig(
      autoPlay: false,
      animationMode: AnimationMode.loop,
      fps: 1.0,
      diagramConfig: StructurizrDiagramConfig(
        showGrid: true,
        fitToScreen: true,
        centerOnStart: true,
        showElementNames: true,
        showRelationshipDescriptions: true,
      ),
    );

    _initializeSampleModel();
  }

  void _initializeSampleModel() {
    workspace = const Workspace(
      name: 'Sample Workspace',
      description: 'Sample workspace for testing',
    );

    // Create a simple model
    final user =
        workspace.model.addPerson('user', 'User', description: 'End User');

    final webApp = workspace.model.addSoftwareSystem(
        'webapp', 'Web Application',
        description: 'Frontend Application');

    final apiSystem = workspace.model
        .addSoftwareSystem('api', 'API Service', description: 'Backend API');

    final database = workspace.model
        .addSoftwareSystem('db', 'Database', description: 'Data Storage');

    // Add relationships
    final userToWebRel = user.uses(webApp, 'Uses');
    final webToApiRel = webApp.uses(apiSystem, 'Calls');
    final apiToDbRel = apiSystem.uses(database, 'Stores data');

    // Create a dynamic view
    dynamicView = const DynamicView(
      key: 'main',
      title: 'Main Flow',
      description: 'Main system flow',
    );

    // Add elements to view
    dynamicView.addElement(ElementView(id: user.id));
    dynamicView.addElement(ElementView(id: webApp.id));
    dynamicView.addElement(ElementView(id: apiSystem.id));
    dynamicView.addElement(ElementView(id: database.id));

    // Add relationships to view
    final rel1 = dynamicView.addRelationship(RelationshipView(
      id: userToWebRel.id,
      order: '1',
    ));

    final rel2 = rel1.addRelationship(RelationshipView(
      id: webToApiRel.id,
      order: '2',
    ));

    final rel3 = rel2.addRelationship(RelationshipView(
      id: apiToDbRel.id,
      order: '3',
    ));

    // Define animation steps
    final animations = [
      // Step 1: Just user and webapp
      AnimationStep(
        order: 1,
        elements: [user.id, webApp.id],
        relationships: [userToWebRel.id],
      ),

      // Step 2: Add API
      AnimationStep(
        order: 2,
        elements: [user.id, webApp.id, apiSystem.id],
        relationships: [userToWebRel.id, webToApiRel.id],
      ),

      // Step 3: Add Database
      AnimationStep(
        order: 3,
        elements: [user.id, webApp.id, apiSystem.id, database.id],
        relationships: [userToWebRel.id, webToApiRel.id, apiToDbRel.id],
      ),
    ];

    // Set animations on the view
    dynamicView = rel3.copyWith(animations: animations);

    // Add view to workspace
    workspace.views.add(dynamicView);
  }

  void _updateConfig(DynamicViewDiagramConfig newConfig) {
    setState(() {
      _config = newConfig;
    });
  }

  void _onElementSelected(String id, Element element) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected: ${element.name}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Structurizr Test'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Dynamic View'),
            Tab(text: 'Settings'),
          ],
        ),
        actions: [
          // Animation mode selection
          PopupMenuButton<AnimationMode>(
            tooltip: 'Animation Mode',
            icon: const Icon(Icons.animation),
            onSelected: (AnimationMode mode) {
              _updateConfig(_config.copyWith(animationMode: mode));
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: AnimationMode.playOnce,
                child: Text('Play Once'),
              ),
              const PopupMenuItem(
                value: AnimationMode.loop,
                child: Text('Loop'),
              ),
              const PopupMenuItem(
                value: AnimationMode.pingPong,
                child: Text('Ping-Pong'),
              ),
            ],
          ),

          // Speed selection
          PopupMenuButton<double>(
            tooltip: 'Animation Speed',
            icon: const Icon(Icons.speed),
            onSelected: (double speed) {
              _updateConfig(_config.copyWith(fps: speed));
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 0.5,
                child: Text('0.5x Speed'),
              ),
              const PopupMenuItem(
                value: 1.0,
                child: Text('1x Speed'),
              ),
              const PopupMenuItem(
                value: 2.0,
                child: Text('2x Speed'),
              ),
              const PopupMenuItem(
                value: 3.0,
                child: Text('3x Speed'),
              ),
            ],
          ),

          // Auto-play toggle
          IconButton(
            icon: Icon(_config.autoPlay
                ? Icons.pause_circle_outline
                : Icons.play_circle_outline),
            tooltip:
                _config.autoPlay ? 'Disable Auto-Play' : 'Enable Auto-Play',
            onPressed: () {
              _updateConfig(_config.copyWith(autoPlay: !_config.autoPlay));
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Dynamic View Tab
          DynamicViewDiagram(
            workspace: workspace,
            view: dynamicView,
            config: _config,
            onElementSelected: _onElementSelected,
          ),

          // Settings Tab
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Diagram Settings',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Element visualization settings
                  SwitchListTile(
                    title: const Text('Show Element Names'),
                    value: _config.diagramConfig.showElementNames,
                    onChanged: (value) {
                      _updateConfig(_config.copyWith(
                        diagramConfig: _config.diagramConfig.copyWith(
                          showElementNames: value,
                        ),
                      ));
                    },
                  ),

                  SwitchListTile(
                    title: const Text('Show Element Descriptions'),
                    value: _config.diagramConfig.showElementDescriptions,
                    onChanged: (value) {
                      _updateConfig(_config.copyWith(
                        diagramConfig: _config.diagramConfig.copyWith(
                          showElementDescriptions: value,
                        ),
                      ));
                    },
                  ),

                  SwitchListTile(
                    title: const Text('Show Relationship Descriptions'),
                    value: _config.diagramConfig.showRelationshipDescriptions,
                    onChanged: (value) {
                      _updateConfig(_config.copyWith(
                        diagramConfig: _config.diagramConfig.copyWith(
                          showRelationshipDescriptions: value,
                        ),
                      ));
                    },
                  ),

                  const Divider(),

                  // Animation settings
                  SwitchListTile(
                    title: const Text('Auto-Play Animation'),
                    value: _config.autoPlay,
                    onChanged: (value) {
                      _updateConfig(_config.copyWith(
                        autoPlay: value,
                      ));
                    },
                  ),

                  // FPS Slider
                  Row(
                    children: [
                      const Text('Animation Speed:'),
                      Expanded(
                        child: Slider(
                          min: 0.5,
                          max: 3.0,
                          divisions: 5,
                          value: _config.fps,
                          label: '${_config.fps}x',
                          onChanged: (value) {
                            _updateConfig(_config.copyWith(
                              fps: value,
                            ));
                          },
                        ),
                      ),
                      Text('${_config.fps}x'),
                    ],
                  ),

                  // Animation mode radio buttons
                  const Text('Animation Mode:'),
                  RadioListTile<AnimationMode>(
                    title: const Text('Play Once'),
                    value: AnimationMode.playOnce,
                    groupValue: _config.animationMode,
                    onChanged: (value) {
                      if (value != null) {
                        _updateConfig(_config.copyWith(
                          animationMode: value,
                        ));
                      }
                    },
                  ),
                  RadioListTile<AnimationMode>(
                    title: const Text('Loop'),
                    value: AnimationMode.loop,
                    groupValue: _config.animationMode,
                    onChanged: (value) {
                      if (value != null) {
                        _updateConfig(_config.copyWith(
                          animationMode: value,
                        ));
                      }
                    },
                  ),
                  RadioListTile<AnimationMode>(
                    title: const Text('Ping-Pong'),
                    value: AnimationMode.pingPong,
                    groupValue: _config.animationMode,
                    onChanged: (value) {
                      if (value != null) {
                        _updateConfig(_config.copyWith(
                          animationMode: value,
                        ));
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
