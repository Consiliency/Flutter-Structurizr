import 'package:flutter/material.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/presentation/widgets/diagram/animation_controls.dart';
import 'package:flutter_structurizr/presentation/widgets/diagram/dynamic_view_diagram.dart';
import 'package:flutter_structurizr/presentation/widgets/diagram/structurizr_diagram.dart';

/// Example showing how to use the DynamicViewDiagram widget.
///
/// This example demonstrates:
/// 1. Creating a workspace with a dynamic view
/// 2. Using the DynamicViewDiagram widget with configuration options
/// 3. Different animation playback modes
class DynamicViewExample extends StatefulWidget {
  const DynamicViewExample({Key? key}) : super(key: key);

  @override
  State<DynamicViewExample> createState() => _DynamicViewExampleState();
}

class _DynamicViewExampleState extends State<DynamicViewExample> {
  /// An example workspace with a dynamic view for demonstration
  late final Workspace _workspace;
  
  /// The dynamic view for demonstration
  late final DynamicView _dynamicView;
  
  /// Current configuration for the dynamic view diagram
  late DynamicViewDiagramConfig _config;

  @override
  void initState() {
    super.initState();
    
    // Initialize configuration
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
    
    // Load the workspace and dynamic view
    _initWorkspaceAndView();
  }
  
  /// Initialize an example workspace with a dynamic view
  void _initWorkspaceAndView() {
    // Create a simple example workspace for demonstration
    final workspace = Workspace(name: "Workspace", model: Model(), views: Views(),); Workspace(
      name: 'Dynamic View Example',
      description: 'Example workspace showing animation of dynamic views',
    );
    
    // Add some example elements to the model
    final user = workspace.model.addPerson(
      id: 'user',
      name: 'User',
      description: 'A user of the system',
    );
    
    final webApp = workspace.model.addSoftwareSystem(
      id: 'webApp',
      name: 'Web Application',
      description: 'The web application',
    );
    
    final apiGateway = workspace.model.addSoftwareSystem(
      id: 'apiGateway',
      name: 'API Gateway',
      description: 'API Gateway',
    );
    
    final database = workspace.model.addSoftwareSystem(
      id: 'database',
      name: 'Database',
      description: 'The database',
    );
    
    final cache = workspace.model.addSoftwareSystem(
      id: 'cache',
      name: 'Cache Service',
      description: 'Distributed caching service',
    );
    
    // Add relationships between elements
    user.uses(
      destination: webApp,
      description: 'Uses',
      technology: 'HTTPS',
    );
    
    webApp.uses(
      destination: apiGateway,
      description: 'Calls API',
      technology: 'HTTPS',
    );
    
    apiGateway.uses(
      destination: cache,
      description: 'Checks cache',
      technology: 'Redis',
    );
    
    apiGateway.uses(
      destination: database,
      description: 'Reads/writes data',
      technology: 'SQL/TCP',
    );
    
    cache.uses(
      destination: database, 
      description: 'Populates on miss',
      technology: 'SQL/TCP',
    );
    
    // Create a dynamic view
    final dynamicView = DynamicView(
      key: 'dynamic',
      title: 'User Request Flow',
      description: 'Shows the flow of a user request through the system',
      autoAnimationInterval: true,
    );
    
    // Add elements to the view (without relationships yet)
    dynamicView.addElement(ElementView(id: user.id));
    dynamicView.addElement(ElementView(id: webApp.id));
    dynamicView.addElement(ElementView(id: apiGateway.id));
    dynamicView.addElement(ElementView(id: cache.id));
    dynamicView.addElement(ElementView(id: database.id));
    
    // Add the relationship views (these will be shown in order in the animation)
    final rel1 = dynamicView.addRelationship(RelationshipView(
      id: user.getRelationships()[0].id,
      order: '1',
    ));
    
    final rel2 = rel1.addRelationship(RelationshipView(
      id: webApp.getRelationships()[0].id,
      order: '2',
    ));
    
    final rel3 = rel2.addRelationship(RelationshipView(
      id: apiGateway.getRelationships()[0].id,
      order: '3',
    ));
    
    final rel4 = rel3.addRelationship(RelationshipView(
      id: cache.getRelationships()[0].id,
      order: '4',
    ));
    
    final rel5 = rel4.addRelationship(RelationshipView(
      id: apiGateway.getRelationships()[1].id,
      order: '5',
    ));
    
    // Define animation steps
    final animations = [
      // Step 1: Show user and web app, with the first relationship
      AnimationStep(
        order: 1,
        elements: [user.id, webApp.id],
        relationships: [user.getRelationships()[0].id],
      ),
      
      // Step 2: Add API gateway and the next relationship
      AnimationStep(
        order: 2,
        elements: [user.id, webApp.id, apiGateway.id],
        relationships: [
          user.getRelationships()[0].id,
          webApp.getRelationships()[0].id,
        ],
      ),
      
      // Step 3: Add cache and check cache relationship
      AnimationStep(
        order: 3,
        elements: [user.id, webApp.id, apiGateway.id, cache.id],
        relationships: [
          user.getRelationships()[0].id,
          webApp.getRelationships()[0].id,
          apiGateway.getRelationships()[0].id,
        ],
      ),
      
      // Step 4: Add database and relationship from cache to database
      AnimationStep(
        order: 4,
        elements: [user.id, webApp.id, apiGateway.id, cache.id, database.id],
        relationships: [
          user.getRelationships()[0].id,
          webApp.getRelationships()[0].id,
          apiGateway.getRelationships()[0].id,
          cache.getRelationships()[0].id,
        ],
      ),
      
      // Step 5: Add the final relationship from API gateway to database
      AnimationStep(
        order: 5,
        elements: [user.id, webApp.id, apiGateway.id, cache.id, database.id],
        relationships: [
          user.getRelationships()[0].id,
          webApp.getRelationships()[0].id,
          apiGateway.getRelationships()[0].id,
          cache.getRelationships()[0].id,
          apiGateway.getRelationships()[1].id,
        ],
      ),
    ];
    
    // Set the animation steps on the view
    final finalView = rel5.copyWith(animations: animations);
    
    // Add the view to the workspace
    workspace.views.add(finalView);
    
    // Set the workspace and view for the example
    _workspace = workspace;
    _dynamicView = finalView;
  }
  
  /// Handle element selection
  void _onElementSelected(String id, Element element) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected element: ${element.name}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
  
  /// Update the animation config
  void _updateConfig(DynamicViewDiagramConfig newConfig) {
    setState(() {
      _config = newConfig;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dynamic View Example'),
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
            icon: Icon(_config.autoPlay ? Icons.pause_circle_outline : Icons.play_circle_outline),
            tooltip: _config.autoPlay ? 'Disable Auto-Play' : 'Enable Auto-Play',
            onPressed: () {
              _updateConfig(_config.copyWith(autoPlay: !_config.autoPlay));
            },
          ),
        ],
      ),
      body: DynamicViewDiagram(
        workspace: _workspace,
        view: _dynamicView,
        config: _config,
        onElementSelected: _onElementSelected,
      ),
    );
  }
}