import '../error_reporter.dart';
import 'nodes/documentation/documentation_node.dart';
import 'nodes/include_node.dart';

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
  void visitModelElementNode(ModelElementNode node);
  void visitPersonNode(PersonNode node);
  void visitSoftwareSystemNode(SoftwareSystemNode node);
  void visitContainerNode(ContainerNode node);
  void visitComponentNode(ComponentNode node);
  void visitDeploymentEnvironmentNode(DeploymentEnvironmentNode node);
  void visitDeploymentNodeNode(DeploymentNodeNode node);
  void visitInfrastructureNodeNode(InfrastructureNodeNode node);
  void visitContainerInstanceNode(ContainerInstanceNode node);
  void visitGroupNode(GroupNode node);
  void visitEnterpriseNode(EnterpriseNode node);
  
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
  
  // Documentation nodes
  void visitDocumentationNode(DocumentationNode node);
  void visitDocumentationSectionNode(DocumentationSectionNode node);
  void visitDiagramReferenceNode(DiagramReferenceNode node);
  void visitDecisionNode(DecisionNode node);
}

// Forward declarations for all node types
class WorkspaceNode extends AstNode { 
  WorkspaceNode(SourcePosition? sourcePosition) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) => visitor.visitWorkspaceNode(this);
}

class ModelNode extends AstNode { 
  ModelNode(SourcePosition? sourcePosition) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) => visitor.visitModelNode(this);
}

class ViewsNode extends AstNode { 
  ViewsNode(SourcePosition? sourcePosition) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) => visitor.visitViewsNode(this);
}

abstract class ModelElementNode extends AstNode { 
  ModelElementNode(SourcePosition? sourcePosition) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) => visitor.visitModelElementNode(this);
}

class PersonNode extends ModelElementNode { 
  PersonNode(SourcePosition? sourcePosition) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) => visitor.visitPersonNode(this);
}

class SoftwareSystemNode extends ModelElementNode { 
  SoftwareSystemNode(SourcePosition? sourcePosition) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) => visitor.visitSoftwareSystemNode(this);
}

class ContainerNode extends ModelElementNode { 
  ContainerNode(SourcePosition? sourcePosition) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) => visitor.visitContainerNode(this);
}

class ComponentNode extends ModelElementNode { 
  ComponentNode(SourcePosition? sourcePosition) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) => visitor.visitComponentNode(this);
}

class DeploymentEnvironmentNode extends ModelElementNode { 
  DeploymentEnvironmentNode(SourcePosition? sourcePosition) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) => visitor.visitDeploymentEnvironmentNode(this);
}

class DeploymentNodeNode extends ModelElementNode { 
  DeploymentNodeNode(SourcePosition? sourcePosition) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) => visitor.visitDeploymentNodeNode(this);
}

class InfrastructureNodeNode extends ModelElementNode { 
  InfrastructureNodeNode(SourcePosition? sourcePosition) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) => visitor.visitInfrastructureNodeNode(this);
}

class ContainerInstanceNode extends ModelElementNode { 
  ContainerInstanceNode(SourcePosition? sourcePosition) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) => visitor.visitContainerInstanceNode(this);
}

class GroupNode extends AstNode { 
  GroupNode(SourcePosition? sourcePosition) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) => visitor.visitGroupNode(this);
}

class EnterpriseNode extends AstNode {
  EnterpriseNode(SourcePosition? sourcePosition) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) => visitor.visitEnterpriseNode(this);
}

class RelationshipNode extends AstNode { 
  RelationshipNode(SourcePosition? sourcePosition) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) => visitor.visitRelationshipNode(this);
}

abstract class ViewNode extends AstNode { 
  ViewNode(SourcePosition? sourcePosition) : super(sourcePosition);
}

class SystemLandscapeViewNode extends ViewNode { 
  SystemLandscapeViewNode(SourcePosition? sourcePosition) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) => visitor.visitSystemLandscapeViewNode(this);
}

class SystemContextViewNode extends ViewNode { 
  SystemContextViewNode(SourcePosition? sourcePosition) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) => visitor.visitSystemContextViewNode(this);
}

class ContainerViewNode extends ViewNode { 
  ContainerViewNode(SourcePosition? sourcePosition) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) => visitor.visitContainerViewNode(this);
}

class ComponentViewNode extends ViewNode { 
  ComponentViewNode(SourcePosition? sourcePosition) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) => visitor.visitComponentViewNode(this);
}

class DynamicViewNode extends ViewNode { 
  DynamicViewNode(SourcePosition? sourcePosition) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) => visitor.visitDynamicViewNode(this);
}

class DeploymentViewNode extends ViewNode { 
  DeploymentViewNode(SourcePosition? sourcePosition) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) => visitor.visitDeploymentViewNode(this);
}

class FilteredViewNode extends ViewNode { 
  FilteredViewNode(SourcePosition? sourcePosition) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) => visitor.visitFilteredViewNode(this);
}

class CustomViewNode extends ViewNode { 
  CustomViewNode(SourcePosition? sourcePosition) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) => visitor.visitCustomViewNode(this);
}

class ImageViewNode extends ViewNode { 
  ImageViewNode(SourcePosition? sourcePosition) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) => visitor.visitImageViewNode(this);
}

// IncludeNode is now defined in nodes/include_node.dart

class ExcludeNode extends AstNode { 
  ExcludeNode(SourcePosition? sourcePosition) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) => visitor.visitExcludeNode(this);
}

class AutoLayoutNode extends AstNode { 
  AutoLayoutNode(SourcePosition? sourcePosition) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) => visitor.visitAutoLayoutNode(this);
}

class AnimationNode extends AstNode { 
  AnimationNode(SourcePosition? sourcePosition) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) => visitor.visitAnimationNode(this);
}

class TagsNode extends AstNode { 
  TagsNode(SourcePosition? sourcePosition) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) => visitor.visitTagsNode(this);
}

class PropertiesNode extends AstNode { 
  PropertiesNode(SourcePosition? sourcePosition) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) => visitor.visitPropertiesNode(this);
}

class PropertyNode extends AstNode { 
  PropertyNode(SourcePosition? sourcePosition) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) => visitor.visitPropertyNode(this);
}

class StylesNode extends AstNode { 
  StylesNode(SourcePosition? sourcePosition) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) => visitor.visitStylesNode(this);
}

class ElementStyleNode extends AstNode { 
  ElementStyleNode(SourcePosition? sourcePosition) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) => visitor.visitElementStyleNode(this);
}

class RelationshipStyleNode extends AstNode { 
  RelationshipStyleNode(SourcePosition? sourcePosition) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) => visitor.visitRelationshipStyleNode(this);
}

class ThemeNode extends AstNode { 
  ThemeNode(SourcePosition? sourcePosition) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) => visitor.visitThemeNode(this);
}

class BrandingNode extends AstNode { 
  BrandingNode(SourcePosition? sourcePosition) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) => visitor.visitBrandingNode(this);
}

class TerminologyNode extends AstNode { 
  TerminologyNode(SourcePosition? sourcePosition) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) => visitor.visitTerminologyNode(this);
}

class DirectiveNode extends AstNode { 
  DirectiveNode(SourcePosition? sourcePosition) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) => visitor.visitDirectiveNode(this);
}

// Documentation nodes are implemented in nodes/documentation/documentation_node.dart