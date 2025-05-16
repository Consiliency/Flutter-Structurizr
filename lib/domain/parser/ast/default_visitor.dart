import 'ast_base.dart';
import 'nodes/documentation/documentation_node.dart';

/// A default implementation of AstVisitor that does nothing for each node.
/// Extend this class to only override the visitor methods you need.
class DefaultAstVisitor implements AstVisitor {
  @override
  void visitWorkspaceNode(WorkspaceNode node) {}
  
  @override
  void visitModelNode(ModelNode node) {}
  
  @override
  void visitViewsNode(ViewsNode node) {}
  
  @override
  void visitModelElementNode(ModelElementNode node) {}
  
  @override
  void visitPersonNode(PersonNode node) {}
  
  @override
  void visitSoftwareSystemNode(SoftwareSystemNode node) {}
  
  @override
  void visitContainerNode(ContainerNode node) {}
  
  @override
  void visitComponentNode(ComponentNode node) {}
  
  @override
  void visitDeploymentEnvironmentNode(DeploymentEnvironmentNode node) {}
  
  @override
  void visitDeploymentNodeNode(DeploymentNodeNode node) {}
  
  @override
  void visitInfrastructureNodeNode(InfrastructureNodeNode node) {}
  
  @override
  void visitContainerInstanceNode(ContainerInstanceNode node) {}
  
  @override
  void visitGroupNode(GroupNode node) {}
  
  @override
  void visitEnterpriseNode(EnterpriseNode node) {}
  
  @override
  void visitRelationshipNode(RelationshipNode node) {}
  
  @override
  void visitSystemLandscapeViewNode(SystemLandscapeViewNode node) {}
  
  @override
  void visitSystemContextViewNode(SystemContextViewNode node) {}
  
  @override
  void visitContainerViewNode(ContainerViewNode node) {}
  
  @override
  void visitComponentViewNode(ComponentViewNode node) {}
  
  @override
  void visitDynamicViewNode(DynamicViewNode node) {}
  
  @override
  void visitDeploymentViewNode(DeploymentViewNode node) {}
  
  @override
  void visitFilteredViewNode(FilteredViewNode node) {}
  
  @override
  void visitCustomViewNode(CustomViewNode node) {}
  
  @override
  void visitImageViewNode(ImageViewNode node) {}
  
  @override
  void visitIncludeNode(IncludeNode node) {}
  
  @override
  void visitExcludeNode(ExcludeNode node) {}
  
  @override
  void visitAutoLayoutNode(AutoLayoutNode node) {}
  
  @override
  void visitAnimationNode(AnimationNode node) {}
  
  @override
  void visitTagsNode(TagsNode node) {}
  
  @override
  void visitPropertiesNode(PropertiesNode node) {}
  
  @override
  void visitPropertyNode(PropertyNode node) {}
  
  @override
  void visitStylesNode(StylesNode node) {}
  
  @override
  void visitElementStyleNode(ElementStyleNode node) {}
  
  @override
  void visitRelationshipStyleNode(RelationshipStyleNode node) {}
  
  @override
  void visitThemeNode(ThemeNode node) {}
  
  @override
  void visitBrandingNode(BrandingNode node) {}
  
  @override
  void visitTerminologyNode(TerminologyNode node) {}
  
  @override
  void visitDirectiveNode(DirectiveNode node) {}
  
  @override
  void visitDocumentationNode(DocumentationNode node) {}
  
  @override
  void visitDocumentationSectionNode(DocumentationSectionNode node) {}
  
  @override
  void visitDiagramReferenceNode(DiagramReferenceNode node) {}
  
  @override
  void visitDecisionNode(DecisionNode node) {}
}