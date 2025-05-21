import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/application/dsl/workspace_builder.dart';
import 'package:flutter_structurizr/application/dsl/workspace_builder_impl.dart';
import 'package:flutter_structurizr/domain/parser/ast/ast_node.dart'
    show AstVisitor, WorkspaceNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/model_node.dart'
    show ModelNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/person_node.dart'
    show PersonNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/software_system_node.dart'
    show SoftwareSystemNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/container_node.dart'
    show ContainerNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/component_node.dart'
    show ComponentNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/relationship_node.dart'
    show RelationshipNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/views_node.dart'
    show ViewsNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/group_node.dart'
    show GroupNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/deployment_environment_node.dart'
    show DeploymentEnvironmentNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/deployment_node_node.dart'
    show DeploymentNodeNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/infrastructure_node_node.dart'
    show InfrastructureNodeNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/container_instance_node.dart'
    show ContainerInstanceNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/auto_layout_node.dart'
    show AutoLayoutNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/animation_node.dart'
    show AnimationNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/properties_node.dart'
    show PropertiesNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/property_node.dart'
    show PropertyNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/styles_node.dart'
    show StylesNode, ElementStyleNode, RelationshipStyleNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/theme_node.dart'
    show ThemeNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/branding_node.dart'
    show BrandingNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/terminology_node.dart'
    show TerminologyNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/directive_node.dart'
    show DirectiveNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/decision_node.dart'
    show DecisionNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/documentation_node.dart'
    show DocumentationNode, DocumentationSectionNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/system_landscape_view_node.dart'
    show SystemLandscapeViewNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/system_context_view_node.dart'
    show SystemContextViewNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/container_view_node.dart'
    show ContainerViewNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/component_view_node.dart'
    show ComponentViewNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/dynamic_view_node.dart'
    show DynamicViewNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/deployment_view_node.dart'
    show DeploymentViewNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/filtered_view_node.dart'
    show FilteredViewNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/custom_view_node.dart'
    show CustomViewNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/image_view_node.dart'
    show ImageViewNode;

/// Mapper for converting AST nodes to domain model objects.
///
/// This class implements the visitor pattern to traverse the AST
/// and build the corresponding domain model objects using a WorkspaceBuilder.
class WorkspaceMapper implements AstVisitor {
  /// The error reporter for reporting semantic errors.
  final ErrorReporter errorReporter;

  /// The source code being processed.
  final String _source;

  /// The workspace builder used for constructing the model.
  final WorkspaceBuilder _builder;

  /// Creates a new workspace mapper.
  WorkspaceMapper(this._source, this.errorReporter)
      : _builder = WorkspaceBuilderImpl(errorReporter);

  /// Maps an AST to a domain model workspace.
  ///
  /// This is the main entry point for the mapping process.
  Workspace? mapWorkspace(WorkspaceNode workspaceNode) {
    try {
      // First phase: process the AST and build model elements
      workspaceNode.accept(this);

      // Second phase: resolve relationships
      _builder.resolveRelationships();

      // Build and validate the final workspace
      return _builder.build();
    } catch (e, stackTrace) {
      // Log any errors during mapping
      errorReporter.reportStandardError(
        'Error mapping workspace: ${e.toString()}\n$stackTrace',
        workspaceNode.sourcePosition?.offset ?? 0,
      );
      return null;
    }
  }

  // Implementation of the AstVisitor interface

  @override
  void visitWorkspaceNode(WorkspaceNode node) {
    // Create workspace configuration
    _builder.createWorkspace(
      name: node.name,
      description: node.description,
      configuration: _convertMapToStringMap(node.configuration),
    );

    // Process the model section
    if (node.model != null) {
      node.model!.accept(this);
    }

    // Process the views section
    if (node.views != null) {
      node.views!.accept(this);
    }

    // Process styles
    if (node.styles != null) {
      node.styles!.accept(this);
    }

    // Process themes
    for (final theme in node.themes) {
      theme.accept(this);
    }

    // Process branding
    if (node.branding != null) {
      node.branding!.accept(this);
    }

    // Process terminology
    if (node.terminology != null) {
      node.terminology!.accept(this);
    }
  }

  @override
  void visitModelNode(ModelNode node) {
    // print('DEBUG: [WorkspaceMapper] visitModelNode: registering model elements');
    // Process people
    for (final personNode in node.people) {
      personNode.accept(this);
    }
    // Process software systems
    for (final systemNode in node.softwareSystems) {
      // print('DEBUG: [WorkspaceMapper] Registering software system: \\${systemNode.name}, id: \\${systemNode.id}');
      systemNode.accept(this);
    }
    // Process deployment environments
    for (final envNode in node.deploymentEnvironments) {
      envNode.accept(this);
    }
    // Process relationships at the model level
    for (final relationship in node.relationships) {
      relationship.accept(this);
    }
  }

  @override
  void visitPersonNode(PersonNode node) {
    _builder.addPerson(node);
  }

  @override
  void visitSoftwareSystemNode(SoftwareSystemNode node) {
    _builder.addSoftwareSystem(node);
  }

  @override
  void visitContainerNode(ContainerNode node) {
    _builder.addContainer(node);
  }

  @override
  void visitComponentNode(ComponentNode node) {
    _builder.addComponent(node);
  }

  @override
  void visitRelationshipNode(RelationshipNode node) {
    _builder.addRelationship(node);
  }

  @override
  void visitViewsNode(ViewsNode node) {
    // print('DEBUG: [WorkspaceMapper] visitViewsNode: processing views');
    // Process different types of views
    for (final view in node.systemLandscapeViews) {
      view.accept(this);
    }

    for (final view in node.systemContextViews) {
      view.accept(this);
    }

    for (final view in node.containerViews) {
      view.accept(this);
    }

    for (final view in node.componentViews) {
      view.accept(this);
    }

    for (final view in node.dynamicViews) {
      view.accept(this);
    }

    for (final view in node.deploymentViews) {
      view.accept(this);
    }

    for (final view in node.filteredViews) {
      view.accept(this);
    }

    for (final view in node.customViews) {
      view.accept(this);
    }

    for (final view in node.imageViews) {
      view.accept(this);
    }
  }

  @override
  void visitSystemLandscapeViewNode(SystemLandscapeViewNode node) {
    _builder.addSystemLandscapeView(node);
  }

  @override
  void visitSystemContextViewNode(SystemContextViewNode node) {
    _builder.addSystemContextView(node);
  }

  @override
  void visitContainerViewNode(ContainerViewNode node) {
    _builder.addContainerView(node);
  }

  @override
  void visitComponentViewNode(ComponentViewNode node) {
    _builder.addComponentView(node);
  }

  @override
  void visitDynamicViewNode(DynamicViewNode node) {
    _builder.addDynamicView(node);
  }

  @override
  void visitDeploymentViewNode(DeploymentViewNode node) {
    _builder.addDeploymentView(node);
  }

  @override
  void visitFilteredViewNode(FilteredViewNode node) {
    _builder.addFilteredView(node);
  }

  @override
  void visitCustomViewNode(CustomViewNode node) {
    _builder.addCustomView(node);
  }

  @override
  void visitImageViewNode(ImageViewNode node) {
    _builder.addImageView(node);
  }

  @override
  void visitDeploymentEnvironmentNode(DeploymentEnvironmentNode node) {
    _builder.addDeploymentEnvironment(node);
  }

  @override
  void visitDeploymentNodeNode(DeploymentNodeNode node) {
    _builder.addDeploymentNode(node);
  }

  @override
  void visitInfrastructureNodeNode(InfrastructureNodeNode node) {
    _builder.addInfrastructureNode(node);
  }

  @override
  void visitContainerInstanceNode(ContainerInstanceNode node) {
    _builder.addContainerInstance(node);
  }

  @override
  void visitGroupNode(GroupNode node) {
    // Save the previous parent ID to support nesting
    final previousParentId = _builder.getCurrentParent();

    // Process the group's children
    for (final child in node.children) {
      child.accept(this);
    }

    // Process relationships
    for (final relationship in node.relationships) {
      relationship.accept(this);
    }

    // Restore previous parent ID
    _builder.setCurrentParent(previousParentId);
  }

  @override
  void visitIncludeNode(dynamic node) {
    // This is handled within the view nodes
  }

  @override
  void visitExcludeNode(dynamic node) {
    // This is handled within the view nodes
  }

  @override
  void visitAutoLayoutNode(AutoLayoutNode node) {
    // This is handled within the view nodes
  }

  @override
  void visitAnimationNode(AnimationNode node) {
    // This is handled within the view nodes
  }

  @override
  void visitTagsNode(dynamic node) {
    // This is handled within the element and relationship nodes
  }

  @override
  void visitPropertiesNode(PropertiesNode node) {
    // This is handled within the element and relationship nodes
  }

  @override
  void visitPropertyNode(PropertyNode node) {
    // This is handled within the properties node
  }

  @override
  void visitStylesNode(StylesNode node) {
    _builder.applyStyles(node);
  }

  @override
  void visitElementStyleNode(ElementStyleNode node) {
    // This is handled within the styles node
  }

  @override
  void visitRelationshipStyleNode(RelationshipStyleNode node) {
    // This is handled within the styles node
  }

  @override
  void visitThemeNode(ThemeNode node) {
    _builder.applyTheme(node);
  }

  @override
  void visitBrandingNode(BrandingNode node) {
    _builder.applyBranding(node);
  }

  @override
  void visitTerminologyNode(TerminologyNode node) {
    _builder.applyTerminology(node);
  }

  @override
  void visitDirectiveNode(DirectiveNode node) {
    // Handle !include directive
    if (node.type.toLowerCase() == 'include') {
      // In a production implementation, this would include content from other files
      // For this implementation, we'll log a message but not actually include the file
      errorReporter.reportInfo(
        'Include directive found: ${node.value}. File inclusion is not implemented in this version.',
        node.sourcePosition?.offset ?? 0,
      );
    } else {
      // Log unknown directive
      errorReporter.reportInfo(
        'Unknown directive: ${node.type}',
        node.sourcePosition?.offset ?? 0,
      );
    }
  }

  @override
  void visitDecisionNode(dynamic node) {}

  @override
  void visitDocumentationNode(DocumentationNode node) {}

  @override
  void visitDocumentationSectionNode(DocumentationSectionNode node) {}

  @override
  void visitDiagramReferenceNode(dynamic node) {}

  @override
  void visitSoftwareSystemInstanceNode(dynamic node) {}

  @override
  void visitViewNode(dynamic node) {}

  @override
  void visitViewPropertyNode(dynamic node) {}

  /// Helper method to convert Map<String, dynamic> to Map<String, String>
  Map<String, String>? _convertMapToStringMap(Map<String, dynamic>? input) {
    if (input == null) return null;
    return input.map((k, v) => MapEntry(k, v.toString()));
  }
}
