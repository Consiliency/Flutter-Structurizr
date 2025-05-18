
/// This file is kept for backward compatibility
/// All actual node implementations are now in ast_nodes.dart
/// Import this file to get access to model-related nodes
/// 
/// @deprecated Use ast_node.dart instead

// Re-export the model-related nodes from ast_node.dart
export 'ast_node.dart' show
    ModelElementNode,
    ModelNode,
    PersonNode,
    SoftwareSystemNode,
    ContainerNode,
    ComponentNode,
    DeploymentEnvironmentNode,
    DeploymentNodeNode,
    InfrastructureNodeNode,
    ContainerInstanceNode,
    GroupNode;