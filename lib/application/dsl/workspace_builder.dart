import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/relationship.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/parser/reference_resolver.dart';
import 'package:flutter_structurizr/domain/parser/ast/ast.dart';

/// Interface for building a workspace model from AST nodes.
///
/// This separates the concerns of tree traversal (done by the [WorkspaceMapper])
/// from the logic of constructing the domain model (done by this class).
abstract class WorkspaceBuilder {
  /// Gets the current workspace being built.
  Workspace? get workspace;
  
  /// Gets the error reporter for reporting semantic errors.
  ErrorReporter get errorReporter;
  
  /// Gets the reference resolver for handling element references.
  ReferenceResolver get referenceResolver;
  
  /// Creates a new workspace with the given name and description.
  void createWorkspace({
    required String name, 
    String? description,
    Map<String, String>? configuration,
  });
  
  /// Adds a person to the model.
  void addPerson(PersonNode node);
  
  /// Adds a software system to the model.
  void addSoftwareSystem(SoftwareSystemNode node);
  
  /// Adds a container to the model.
  void addContainer(ContainerNode node);
  
  /// Adds a component to the model.
  void addComponent(ComponentNode node);
  
  /// Adds a deployment environment to the model.
  void addDeploymentEnvironment(DeploymentEnvironmentNode node);
  
  /// Adds a deployment node to the model.
  void addDeploymentNode(DeploymentNodeNode node);
  
  /// Adds an infrastructure node to the model.
  void addInfrastructureNode(InfrastructureNodeNode node);
  
  /// Adds a container instance to the model.
  void addContainerInstance(ContainerInstanceNode node);
  
  /// Adds a relationship between elements.
  void addRelationship(RelationshipNode node);
  
  /// Adds a system landscape view to the workspace.
  void addSystemLandscapeView(SystemLandscapeViewNode node);
  
  /// Adds a system context view to the workspace.
  void addSystemContextView(SystemContextViewNode node);
  
  /// Adds default elements to a system context view.
  void addDefaultElements(SystemContextViewNode viewNode);
  
  /// Adds implied relationships between elements in the model.
  void addImpliedRelationships();
  
  /// Populates default values for elements, relationships, and views.
  void populateDefaults();
  
  /// Sets default properties to match the Java implementation.
  void setDefaultsFromJava();
  
  /// Adds a container view to the workspace.
  void addContainerView(ContainerViewNode node);
  
  /// Adds a component view to the workspace.
  void addComponentView(ComponentViewNode node);
  
  /// Adds a dynamic view to the workspace.
  void addDynamicView(DynamicViewNode node);
  
  /// Adds a deployment view to the workspace.
  void addDeploymentView(DeploymentViewNode node);
  
  /// Adds a filtered view to the workspace.
  void addFilteredView(FilteredViewNode node);
  
  /// Adds a custom view to the workspace.
  void addCustomView(CustomViewNode node);
  
  /// Adds an image view to the workspace.
  void addImageView(ImageViewNode node);
  
  /// Applies styles to the workspace.
  void applyStyles(StylesNode node);
  
  /// Applies themes to the workspace.
  void applyTheme(ThemeNode node);
  
  /// Applies branding to the workspace.
  void applyBranding(BrandingNode node);
  
  /// Applies terminology to the workspace.
  void applyTerminology(TerminologyNode node);
  
  /// Validates and finalizes the workspace.
  /// Returns the built workspace or null if validation fails.
  Workspace? build();
  
  /// Gets all pending relationships that need to be resolved.
  List<RelationshipNode> getPendingRelationships();
  
  /// Resolves all pending relationships.
  void resolveRelationships();
  
  /// Sets the current parent element ID for nested elements.
  void setCurrentParent(String? parentId);
  
  /// Gets the current parent element ID for nested elements.
  String? getCurrentParent();
}

/// Factory for creating workspace builders.
abstract class WorkspaceBuilderFactory {
  /// Creates a new workspace builder with the given error reporter.
  WorkspaceBuilder createWorkspaceBuilder(ErrorReporter errorReporter);
}