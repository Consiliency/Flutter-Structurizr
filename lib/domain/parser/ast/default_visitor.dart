/// Default AST visitor that provides empty implementations of all visitor methods.
/// 
/// This class implements the visitor pattern for traversing AST nodes.
/// Subclasses can override specific visit methods to handle particular node types.
abstract class DefaultAstVisitor {
  /// Visits a model node containing people, software systems, and deployment environments.
  void visitModelNode(dynamic node) {}

  /// Visits a person node representing an end-user of the system.
  void visitPersonNode(dynamic node) {}

  /// Visits a software system node representing a high-level system.
  void visitSoftwareSystemNode(dynamic node) {}

  /// Visits a container node representing an application or service.
  void visitContainerNode(dynamic node) {}

  /// Visits a component node representing an implementation unit.
  void visitComponentNode(dynamic node) {}

  /// Visits a relationship node representing a connection between elements.
  void visitRelationshipNode(dynamic node) {}

  /// Visits a deployment environment node.
  void visitDeploymentEnvironmentNode(dynamic node) {}

  /// Visits a deployment node representing infrastructure.
  void visitDeploymentNodeNode(dynamic node) {}

  /// Visits an infrastructure node.
  void visitInfrastructureNodeNode(dynamic node) {}

  /// Visits a software system instance node.
  void visitSoftwareSystemInstanceNode(dynamic node) {}

  /// Visits a container instance node.
  void visitContainerInstanceNode(dynamic node) {}

  /// Visits a views node containing diagram definitions.
  void visitViewsNode(dynamic node) {}

  /// Visits a system landscape view node.
  void visitSystemLandscapeViewNode(dynamic node) {}

  /// Visits a system context view node.
  void visitSystemContextViewNode(dynamic node) {}

  /// Visits a container view node.
  void visitContainerViewNode(dynamic node) {}

  /// Visits a component view node.
  void visitComponentViewNode(dynamic node) {}

  /// Visits a dynamic view node.
  void visitDynamicViewNode(dynamic node) {}

  /// Visits a deployment view node.
  void visitDeploymentViewNode(dynamic node) {}

  /// Visits a filtered view node.
  void visitFilteredViewNode(dynamic node) {}

  /// Visits an image view node.
  void visitImageViewNode(dynamic node) {}

  /// Visits a custom view node.
  void visitCustomViewNode(dynamic node) {}

  /// Visits a styles node containing styling information.
  void visitStylesNode(dynamic node) {}

  /// Visits a branding node containing branding configuration.
  void visitBrandingNode(dynamic node) {}

  /// Visits a terminology node containing custom terminology.
  void visitTerminologyNode(dynamic node) {}

  /// Visits a documentation node containing documentation content.
  void visitDocumentationNode(dynamic node) {}

  /// Visits a documentation section node.
  void visitDocumentationSectionNode(dynamic node) {}

  /// Visits a decision node representing an architecture decision record.
  void visitDecisionNode(dynamic node) {}

  /// Visits a properties node containing key-value properties.
  void visitPropertiesNode(dynamic node) {}

  /// Visits a property node representing a single property.
  void visitPropertyNode(dynamic node) {}

  /// Visits a directive node containing parser directives.
  void visitDirectiveNode(dynamic node) {}

  /// Visits a tags node containing element tags.
  void visitTagsNode(dynamic node) {}

  /// Visits an animation node for dynamic views.
  void visitAnimationNode(dynamic node) {}

  /// Visits an animation step node.
  void visitAnimationStepNode(dynamic node) {}

  /// Visits an auto layout node.
  void visitAutoLayoutNode(dynamic node) {}

  /// Visits a theme node containing theme information.
  void visitThemeNode(dynamic node) {}

  /// Visits an exclude node for view filtering.
  void visitExcludeNode(dynamic node) {}

  /// Visits a view property node.
  void visitViewPropertyNode(dynamic node) {}

  /// Visits an include node for file inclusion.
  void visitIncludeNode(dynamic node) {}

  /// Visits a group node for element grouping.
  void visitGroupNode(dynamic node) {}

  /// Visits an enterprise node.
  void visitEnterpriseNode(dynamic node) {}
}