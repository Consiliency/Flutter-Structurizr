import 'package:flutter/material.dart' hide Container, Border, Element, View;
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/view/view.dart' hide View;
import 'package:flutter_structurizr/presentation/widgets/diagram/animation_controls.dart';
import 'package:flutter_structurizr/presentation/widgets/diagram/structurizr_diagram.dart';

/// Configuration options for the DynamicViewDiagram widget
class DynamicViewDiagramConfig {
  /// Whether to show animation controls
  final bool showAnimationControls;
  
  /// Whether to auto-play the animation
  final bool autoPlay;
  
  /// Animation playback mode
  final AnimationMode animationMode;
  
  /// Animation frames per second
  final double fps;
  
  /// Configuration for the diagram
  final StructurizrDiagramConfig diagramConfig;
  
  /// Configuration for animation controls
  final AnimationControlsConfig animationControlsConfig;
  
  /// Creates a new configuration for the dynamic view diagram
  const DynamicViewDiagramConfig({
    this.showAnimationControls = true,
    this.autoPlay = false,
    this.animationMode = AnimationMode.playOnce,
    this.fps = 1.0,
    this.diagramConfig = const StructurizrDiagramConfig(
      fitToScreen: true,
      centerOnStart: true,
    ),
    this.animationControlsConfig = const AnimationControlsConfig(),
  });
  
  /// Creates a copy of this configuration with the given fields replaced with new values
  DynamicViewDiagramConfig copyWith({
    bool? showAnimationControls,
    bool? autoPlay,
    AnimationMode? animationMode,
    double? fps,
    StructurizrDiagramConfig? diagramConfig,
    AnimationControlsConfig? animationControlsConfig,
  }) {
    return DynamicViewDiagramConfig(
      showAnimationControls: showAnimationControls ?? this.showAnimationControls,
      autoPlay: autoPlay ?? this.autoPlay,
      animationMode: animationMode ?? this.animationMode,
      fps: fps ?? this.fps,
      diagramConfig: diagramConfig ?? this.diagramConfig,
      animationControlsConfig: animationControlsConfig ?? this.animationControlsConfig,
    );
  }
}

/// A widget that displays a Structurizr dynamic view with animation controls.
///
/// This widget combines a StructurizrDiagram with AnimationControls to provide
/// a complete solution for animated architecture diagrams. It automatically
/// handles the interaction between the diagram and animation controls.
class DynamicViewDiagram extends StatefulWidget {
  /// The workspace containing the diagram data
  final Workspace workspace;
  
  /// The dynamic view to render
  final DynamicView view;
  
  /// Callback for when an element is selected
  final Function(String id, Element element)? onElementSelected;
  
  /// Callback for when a relationship is selected
  final Function(String id, Relationship relationship)? onRelationshipSelected;
  
  /// Callback for when selection is cleared
  final Function()? onSelectionCleared;
  
  /// Callback for when an element is hovered over
  final Function(String id, Element element)? onElementHovered;
  
  /// Callback for when multiple elements are selected
  final Function(Set<String> elementIds, Set<String> relationshipIds)? onMultipleItemsSelected;
  
  /// Callback for when elements are moved
  final Function(Map<String, Offset> newPositions)? onElementsMoved;
  
  /// Configuration options for the dynamic view diagram
  final DynamicViewDiagramConfig config;
  
  /// Creates a new Structurizr dynamic view diagram
  const DynamicViewDiagram({
    Key? key,
    required this.workspace,
    required this.view,
    this.onElementSelected,
    this.onRelationshipSelected,
    this.onSelectionCleared,
    this.onElementHovered,
    this.onMultipleItemsSelected,
    this.onElementsMoved,
    this.config = const DynamicViewDiagramConfig(),
  }) : super(key: key);
  
  @override
  State<DynamicViewDiagram> createState() => _DynamicViewDiagramState();
}

class _DynamicViewDiagramState extends State<DynamicViewDiagram> {
  /// The current animation step
  int _currentAnimationStep = 0;
  
  /// Key for the diagram to access its state
  final GlobalKey<StructurizrDiagramState> _diagramKey = GlobalKey<StructurizrDiagramState>();
  
  @override
  void initState() {
    super.initState();
  }
  
  @override
  void didUpdateWidget(DynamicViewDiagram oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If the view changed, reset the animation step
    if (widget.view != oldWidget.view) {
      setState(() {
        _currentAnimationStep = 0;
      });
    }
  }
  
  /// Handle animation step changes
  void _onAnimationStepChanged(int step) {
    setState(() {
      _currentAnimationStep = step;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // Check if view is a dynamic view with animation steps
    final hasAnimationSteps = widget.view.animations.isNotEmpty;
    
    return Column(
      children: [
        // Main diagram
        Expanded(
          child: StructurizrDiagram(
            key: _diagramKey,
            workspace: widget.workspace,
            view: widget.view,
            animationStep: _currentAnimationStep,
            config: widget.config.diagramConfig,
            onElementSelected: widget.onElementSelected,
            onRelationshipSelected: widget.onRelationshipSelected,
            onSelectionCleared: widget.onSelectionCleared,
            onElementHovered: widget.onElementHovered,
            onMultipleItemsSelected: widget.onMultipleItemsSelected,
            onElementsMoved: widget.onElementsMoved,
          ),
        ),
        
        // Animation controls (only if there are animation steps and controls are enabled)
        if (hasAnimationSteps && widget.config.showAnimationControls)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AnimationControls(
              animationSteps: widget.view.animations,
              initialStep: _currentAnimationStep,
              onStepChanged: _onAnimationStepChanged,
              config: widget.config.animationControlsConfig.copyWith(
                autoPlay: widget.config.autoPlay,
                defaultMode: widget.config.animationMode,
                fps: widget.config.fps,
              ),
            ),
          ),
      ],
    );
  }
}