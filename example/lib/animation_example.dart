import 'package:flutter/material.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/presentation/widgets/diagram/animation_controls.dart';
import 'package:flutter_structurizr/presentation/widgets/diagram/structurizr_diagram.dart';

/// Example showing how to use the animation controls with a Structurizr diagram.
///
/// This example demonstrates:
/// 1. Loading a workspace with a dynamic view
/// 2. Setting up a StructurizrDiagram widget with animation step support
/// 3. Connecting AnimationControls to control the current animation step
class AnimationExample extends StatefulWidget {
  const AnimationExample({Key? key}) : super(key: key);

  @override
  State<AnimationExample> createState() => _AnimationExampleState();
}

class _AnimationExampleState extends State<AnimationExample> {
  /// The current animation step
  int _currentAnimationStep = 0;
  
  /// An example workspace with a dynamic view for demonstration
  late final Workspace _workspace;
  
  /// The dynamic view for demonstration
  late final DynamicView _dynamicView;

  @override
  void initState() {
    super.initState();
    
    // Load the workspace and dynamic view
    _initWorkspaceAndView();
  }
  
  /// Initialize an example workspace with a dynamic view
  void _initWorkspaceAndView() {
    // Create a simple example workspace for demonstration
    final workspace = Workspace(
      name: 'Animation Example',
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
      destination: database,
      description: 'Reads/writes data',
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
      
      // Step 3: Add database and the final relationship
      AnimationStep(
        order: 3,
        elements: [user.id, webApp.id, apiGateway.id, database.id],
        relationships: [
          user.getRelationships()[0].id,
          webApp.getRelationships()[0].id,
          apiGateway.getRelationships()[0].id,
        ],
      ),
    ];
    
    // Set the animation steps on the view
    final finalView = rel3.copyWith(animations: animations);
    
    // Add the view to the workspace
    workspace.views.add(finalView);
    
    // Set the workspace and view for the example
    _workspace = workspace;
    _dynamicView = finalView;
  }
  
  /// Handle animation step changes
  void _onAnimationStepChanged(int step) {
    setState(() {
      _currentAnimationStep = step;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animation Example'),
      ),
      body: Column(
        children: [
          Expanded(
            // The main diagram
            child: StructurizrDiagram(
              workspace: _workspace,
              view: _dynamicView,
              animationStep: _currentAnimationStep,
              config: const StructurizrDiagramConfig(
                showGrid: true,
                fitToScreen: true,
                centerOnStart: true,
              ),
            ),
          ),
          
          // Animation controls at the bottom
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AnimationControls(
              animationSteps: _dynamicView.animations,
              initialStep: _currentAnimationStep,
              onStepChanged: _onAnimationStepChanged,
              config: const AnimationControlsConfig(
                autoPlay: false,
                defaultMode: AnimationMode.loop,
                fps: 1.0,
                showStepLabels: true,
                showTimingControls: true,
                showModeControls: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}