import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/parser/ast/ast.dart';
import 'package:flutter_structurizr/application/dsl/workspace_builder.dart';
import 'package:flutter_structurizr/application/dsl/workspace_builder_impl.dart';

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
      : _builder = WorkspaceBuilderFactoryImpl().createWorkspaceBuilder(errorReporter);
  
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
      configuration: node.configuration,
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
    print('DEBUG: [WorkspaceMapper] visitModelNode: registering model elements');
    // Process people
    for (final personNode in node.people) {
      personNode.accept(this);
    }
    // Process software systems
    for (final systemNode in node.softwareSystems) {
      print('DEBUG: [WorkspaceMapper] Registering software system: \\${systemNode.name}, id: \\${systemNode.id}');
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
    print('DEBUG: [WorkspaceMapper] visitViewsNode: processing views');
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
  void visitIncludeNode(IncludeNode node) {
    // This is handled within the view nodes
  }
  
  @override
  void visitExcludeNode(ExcludeNode node) {
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
  void visitTagsNode(TagsNode node) {
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
  void visitDecisionNode(DecisionNode node) {}
  
  @override
  void visitDiagramReferenceNode(DiagramReferenceNode node) {}
  
  @override
  void visitDocumentationNode(DocumentationNode node) {}
  
  @override
  void visitDocumentationSectionNode(DocumentationSectionNode node) {}
}