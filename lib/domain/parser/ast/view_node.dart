/// This file is kept for backward compatibility
/// All actual node implementations are now in ast_nodes.dart
/// Import this file to get access to view-related nodes
///
/// @deprecated Use ast_node.dart instead

// Re-export the view-related nodes from ast_node.dart
export 'ast_node.dart'
    show
        ViewNode,
        SystemLandscapeViewNode,
        SystemContextViewNode,
        ContainerViewNode,
        ComponentViewNode,
        DynamicViewNode,
        DeploymentViewNode,
        FilteredViewNode,
        CustomViewNode,
        ImageViewNode,
        IncludeNode,
        ExcludeNode,
        AutoLayoutNode,
        AnimationNode;

export 'nodes/view_node.dart';
export 'nodes/views_node.dart';
