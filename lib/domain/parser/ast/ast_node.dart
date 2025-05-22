// AST node base class and visitor interface imports (assume these exist or are stubbed)
import 'nodes/model_node.dart' show ModelNode;
import 'nodes/views_node.dart' show ViewsNode;
import 'nodes/styles_node.dart';
import 'nodes/branding_node.dart';
import 'nodes/terminology_node.dart';
import 'nodes/documentation/documentation_node.dart' as doc_nodes;
import 'nodes/person_node.dart' show PersonNode;
import 'nodes/software_system_node.dart' show SoftwareSystemNode;
import 'nodes/container_node.dart' show ContainerNode;
import 'nodes/component_node.dart' show ComponentNode;
import 'nodes/deployment_environment_node.dart' show DeploymentEnvironmentNode;
import 'nodes/deployment_node_node.dart' show DeploymentNodeNode;
import 'nodes/infrastructure_node_node.dart' show InfrastructureNodeNode;
import 'nodes/software_system_instance_node.dart'
    show SoftwareSystemInstanceNode;
import 'nodes/container_instance_node.dart' show ContainerInstanceNode;
import 'nodes/properties_node.dart' show PropertiesNode;
import 'nodes/property_node.dart' show PropertyNode;
import 'nodes/directive_node.dart' show DirectiveNode;
import 'nodes/documentation/documentation_node.dart' show DiagramReferenceNode;
import 'nodes/documentation_node.dart'
    show DocumentationNode, DocumentationSectionNode;
import 'nodes/system_landscape_view_node.dart' show SystemLandscapeViewNode;
import 'nodes/system_context_view_node.dart' show SystemContextViewNode;
import 'nodes/container_view_node.dart' show ContainerViewNode;
import 'nodes/component_view_node.dart' show ComponentViewNode;
import 'nodes/dynamic_view_node.dart' show DynamicViewNode;
import 'nodes/deployment_view_node.dart' show DeploymentViewNode;
import 'nodes/filtered_view_node.dart' show FilteredViewNode;
import 'nodes/custom_view_node.dart' show CustomViewNode;
import 'nodes/image_view_node.dart' show ImageViewNode;
import 'nodes/theme_node.dart' show ThemeNode;
import 'nodes/source_position.dart';
// AstVisitor does not exist, so define a minimal stub below

// Minimal stub for AstVisitor
abstract class AstVisitor {
  void visitWorkspaceNode(WorkspaceNode node);
  void visitModelNode(ModelNode node);
  void visitViewsNode(ViewsNode node);
  void visitViewNode(
      dynamic node); // Use dynamic for now, or import ViewNode if possible
  void visitViewPropertyNode(dynamic node);
  void visitIncludeNode(dynamic node);
  void visitExcludeNode(dynamic node);
  void visitTagsNode(dynamic node);

  // Add missing visit methods for AST node types
  void visitPersonNode(PersonNode node);
  void visitSoftwareSystemNode(SoftwareSystemNode node);
  void visitContainerNode(ContainerNode node);
  void visitComponentNode(ComponentNode node);
  void visitDeploymentEnvironmentNode(DeploymentEnvironmentNode node);
  void visitDeploymentNodeNode(DeploymentNodeNode node);
  void visitInfrastructureNodeNode(InfrastructureNodeNode node);
  void visitSoftwareSystemInstanceNode(SoftwareSystemInstanceNode node);
  void visitContainerInstanceNode(ContainerInstanceNode node);
  void visitRelationshipNode(dynamic node); // Use dynamic for RelationshipNode
  void visitPropertiesNode(PropertiesNode node);
  void visitPropertyNode(PropertyNode node);
  void visitDirectiveNode(DirectiveNode node);
  void visitDecisionNode(doc_nodes.DecisionNode node);
  void visitDiagramReferenceNode(DiagramReferenceNode node);
  void visitDocumentationNode(DocumentationNode node);
  void visitDocumentationSectionNode(DocumentationSectionNode node);
  void visitSystemLandscapeViewNode(SystemLandscapeViewNode node);
  void visitSystemContextViewNode(SystemContextViewNode node);
  void visitContainerViewNode(ContainerViewNode node);
  void visitComponentViewNode(ComponentViewNode node);
  void visitDynamicViewNode(DynamicViewNode node);
  void visitDeploymentViewNode(DeploymentViewNode node);
  void visitFilteredViewNode(FilteredViewNode node);
  void visitCustomViewNode(CustomViewNode node);
  void visitImageViewNode(ImageViewNode node);
}

// The WorkspaceNode AST node, root of the parsed DSL tree
class WorkspaceNode {
  final String name;
  final String? description;
  final ModelNode? model;
  final ViewsNode? views;
  final StylesNode? styles;
  final List<ThemeNode> themes;
  final BrandingNode? branding;
  final TerminologyNode? terminology;
  final doc_nodes.DocumentationNode? documentation;
  final List<doc_nodes.DecisionNode>? decisions;
  final Map<String, String>? properties;
  final Map<String, dynamic>? configuration;
  final List<String>? directives; // e.g., include directives
  final SourcePosition? sourcePosition;

  WorkspaceNode({
    required this.name,
    this.description,
    this.model,
    this.views,
    this.styles,
    this.themes = const [],
    this.branding,
    this.terminology,
    this.documentation,
    this.decisions,
    this.properties,
    this.configuration,
    this.directives,
    this.sourcePosition,
  });

  // Accept a visitor (visitor pattern)
  void accept(AstVisitor visitor) {
    visitor.visitWorkspaceNode(this);
  }

  // Helper: get all children nodes for traversal
  List<Object?> get children => [
        model,
        views,
        styles,
        branding,
        terminology,
        documentation,
        if (decisions != null) ...decisions!,
      ];

  void addInclude(dynamic include) {
    // No-op or add to a test-only list if needed
  }

  void setWorkspace(WorkspaceNode ws) {
    // No-op for test/integration
  }

  void setErrorReporter(Function f) {
    // No-op for test/integration
  }
}

abstract class AstNode {
  final SourcePosition? sourcePosition;
  AstNode([this.sourcePosition]);
  void accept(AstVisitor visitor);
}
