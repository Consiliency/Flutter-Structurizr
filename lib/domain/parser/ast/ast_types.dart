import 'package:flutter_structurizr/domain/parser/lexer/token.dart';

import 'nodes/workspace_node.dart';
import 'nodes/model_node.dart';
import 'nodes/model_element_node.dart';
import 'nodes/relationship_node.dart';
import 'nodes/deployment_node.dart';
import 'nodes/property_node.dart';
import 'nodes/view_node.dart';

/// Base class for all AST nodes in the Structurizr DSL parser.
abstract class AstNode {
  /// The source position where this node starts.
  final SourcePosition? sourcePosition;
  
  /// Creates a new AST node with an optional source position.
  AstNode(this.sourcePosition);
  
  /// Accept a visitor for processing this node.
  void accept(AstVisitor visitor);
}

/// Visitor interface for processing AST nodes.
abstract class AstVisitor {
  // Top-level nodes
  void visitWorkspaceNode(WorkspaceNode node);
  void visitModelNode(ModelNode node);
  void visitViewsNode(ViewsNode node);
  
  // Model element nodes
  void visitPersonNode(PersonNode node);
  void visitSoftwareSystemNode(SoftwareSystemNode node);
  void visitContainerNode(ContainerNode node);
  void visitComponentNode(ComponentNode node);
  void visitDeploymentEnvironmentNode(DeploymentEnvironmentNode node);
  void visitDeploymentNodeNode(DeploymentNodeNode node);
  void visitInfrastructureNodeNode(InfrastructureNodeNode node);
  void visitContainerInstanceNode(ContainerInstanceNode node);
  void visitGroupNode(GroupNode node);
  
  // Relationship node
  void visitRelationshipNode(RelationshipNode node);
  
  // View nodes
  void visitSystemLandscapeViewNode(SystemLandscapeViewNode node);
  void visitSystemContextViewNode(SystemContextViewNode node);
  void visitContainerViewNode(ContainerViewNode node);
  void visitComponentViewNode(ComponentViewNode node);
  void visitDynamicViewNode(DynamicViewNode node);
  void visitDeploymentViewNode(DeploymentViewNode node);
  void visitFilteredViewNode(FilteredViewNode node);
  void visitCustomViewNode(CustomViewNode node);
  void visitImageViewNode(ImageViewNode node);
  
  // View elements
  void visitIncludeNode(IncludeNode node);
  void visitExcludeNode(ExcludeNode node);
  void visitAutoLayoutNode(AutoLayoutNode node);
  void visitAnimationNode(AnimationNode node);
  
  // Property nodes
  void visitTagsNode(TagsNode node);
  void visitPropertiesNode(PropertiesNode node);
  void visitPropertyNode(PropertyNode node);
  
  // Styling nodes
  void visitStylesNode(StylesNode node);
  void visitElementStyleNode(ElementStyleNode node);
  void visitRelationshipStyleNode(RelationshipStyleNode node);
  void visitThemeNode(ThemeNode node);
  void visitBrandingNode(BrandingNode node);
  void visitTerminologyNode(TerminologyNode node);
  
  // Miscellaneous nodes
  void visitDirectiveNode(DirectiveNode node);
}

// Abstract base classes
abstract class ModelElementNode extends AstNode {
  ModelElementNode(SourcePosition? sourcePosition) : super(sourcePosition);
}

abstract class ViewNode extends AstNode {
  ViewNode(SourcePosition? sourcePosition) : super(sourcePosition);
}