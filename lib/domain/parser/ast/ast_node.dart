import '../error_reporter.dart';
import './ast_nodes.dart';

/// This file serves as a central export point for AST node interfaces
/// It re-exports the core interfaces from ast_nodes.dart
/// This eliminates circular dependencies in the AST node hierarchy

export './ast_nodes.dart' show
    // Core interfaces
    AstNode,
    AstVisitor,
    
    // Nodes
    WorkspaceNode,
    ModelNode,
    ViewsNode,
    
    // Element nodes
    ModelElementNode,
    PersonNode,
    SoftwareSystemNode,
    ContainerNode,
    ComponentNode,
    DeploymentEnvironmentNode,
    DeploymentNodeNode,
    InfrastructureNodeNode,
    ContainerInstanceNode,
    GroupNode,
    
    // Relationship nodes
    RelationshipNode,
    
    // View nodes
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
    
    // View elements
    IncludeNode,
    ExcludeNode,
    AutoLayoutNode,
    AnimationNode,
    
    // Property nodes
    TagsNode,
    PropertiesNode,
    PropertyNode,
    
    // Styling nodes
    StylesNode,
    ElementStyleNode,
    RelationshipStyleNode,
    ThemeNode,
    BrandingNode,
    TerminologyNode,
    
    // Miscellaneous nodes
    DirectiveNode;