import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/container.dart';
import 'package:flutter_structurizr/domain/model/component.dart';
import 'package:flutter_structurizr/domain/model/deployment_environment.dart';
import 'package:flutter_structurizr/domain/model/deployment_node.dart';
import 'package:flutter_structurizr/domain/model/infrastructure_node.dart';
import 'package:flutter_structurizr/domain/model/relationship.dart';
import 'package:flutter_structurizr/domain/model/modeled_relationship.dart';
import 'package:flutter_structurizr/domain/model/group.dart';
import 'package:flutter_structurizr/domain/style/branding.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/domain/view/views.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/parser/reference_resolver.dart';
import 'package:flutter_structurizr/domain/parser/views_parser/system_context_view_parser.dart';
import 'package:flutter_structurizr/application/dsl/workspace_builder.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/view_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/views_node.dart';
import 'package:flutter_structurizr/util/color.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/relationship_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/person_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/software_system_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/container_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/component_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/deployment_environment_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/deployment_node_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/infrastructure_node_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/container_instance_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/system_landscape_view_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/system_context_view_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/container_view_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/component_view_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/dynamic_view_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/deployment_view_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/filtered_view_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/custom_view_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/image_view_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/styles_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/tags_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/properties_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/theme_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/branding_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/terminology_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/tags_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/properties_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/model_element_node.dart'
    show ElementNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/styles_node.dart'
    show ElementStyleNode, RelationshipStyleNode;
import 'package:logging/logging.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/model_element_node.dart'
    show ElementNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/styles_node.dart'
    show ElementStyleNode, RelationshipStyleNode;
import 'package:flutter_structurizr/domain/model/container_instance.dart';
import 'package:flutter/material.dart' show Color;

final logger = Logger('WorkspaceBuilderImpl');

/// Default implementation of the [WorkspaceBuilder] interface.
class WorkspaceBuilderImpl implements WorkspaceBuilder {
  /// The error reporter for reporting semantic errors.
  @override
  final ErrorReporter errorReporter;

  /// The reference resolver for handling element references.
  @override
  final ReferenceResolver referenceResolver;

  /// The workspace being built.
  @override
  Workspace? workspace;

  /// The current model being built.
  Model _currentModel = const Model();

  /// The current views collection being built.
  Views _currentViews = const Views();

  /// Queue of relationships to be resolved
  final List<RelationshipNode> _pendingRelationships = [];

  /// Current parent element ID (for nested elements)
  String? _currentParentId;

  /// Maps software system identifiers to their actual objects
  final Map<String, SoftwareSystem> _softwareSystemsById = {};

  /// Maps container identifiers to their actual objects
  final Map<String, Container> _containersById = {};

  /// Maps component identifiers to their actual objects
  final Map<String, Component> _componentsById = {};

  /// Maps deployment environment identifiers to their actual objects
  final Map<String, DeploymentEnvironment> _environmentsById = {};

  /// Maps deployment node identifiers to their actual objects
  final Map<String, DeploymentNode> _deploymentNodesById = {};

  /// Maps infrastructure node identifiers to their actual objects
  final Map<String, InfrastructureNode> _infrastructureNodesById = {};

  /// Maps container instance identifiers to their actual objects
  final Map<String, ContainerInstance> _containerInstancesById = {};

  /// Creates a new workspace builder with the given error reporter.
  WorkspaceBuilderImpl(this.errorReporter)
      : referenceResolver = ReferenceResolver(errorReporter);

  @override
  void createWorkspace({
    required String name,
    String? description,
    Map<String, String>? configuration,
  }) {
    // Create workspace configuration
    final workspaceConfiguration = WorkspaceConfiguration(
      properties: configuration ?? const {},
    );

    // Create the workspace object
    workspace = Workspace(
      id: 1, // Default ID for DSL-created workspaces
      name: name,
      description: description,
      model: _currentModel,
      views: _currentViews,
      configuration: workspaceConfiguration,
    );
  }

  @override
  void addPerson(PersonNode node) {
    // Save current context for "this" references
    final previousContextId = referenceResolver.getCurrentContextId();
    referenceResolver.setCurrentContext(node.id);

    // Create Person directly with the AST node ID
    final person = Person(
      id: node.id,
      name: node.name,
      description: node.description,
      tags: node.tags,
      properties: node.properties ?? {},
      location: node.location ?? 'Internal',
    );

    _addElementToModel(person);

    // Queue relationships for later processing
    for (final relationship in node.relationships) {
      if (relationship is RelationshipNode) {
        _pendingRelationships.add(relationship);
      }
    }

    // Restore previous context
    referenceResolver.setCurrentContext(previousContextId);
  }

  @override
  void addSoftwareSystem(SoftwareSystemNode node) {
    // TODO: Replace with proper logging or remove for production
    // print(
    //     'DEBUG: [WorkspaceBuilderImpl] Registering software system: id={node.id}, name={node.name}');
    // Save the previous context ID and parent ID to support nesting
    final previousContextId = referenceResolver.getCurrentContextId();
    final previousParentId = _currentParentId;

    // Set this element as the current context for "this" references
    referenceResolver.setCurrentContext(node.id);

    // Create the software system directly with the AST node ID
    final system = SoftwareSystem(
      id: node.id,
      name: node.name,
      description: node.description,
      tags: node.tags,
      properties: node.properties ?? {},
      location: node.location ?? 'Internal',
    );

    // Add to model
    _addElementToModel(system);

    // Set as current parent for nested elements
    _currentParentId = system.id;

    // Process containers
    for (final containerNode in node.containers) {
      addContainer(containerNode);
    }

    // Process deployment environments
    for (final envNode in node.deploymentEnvironments) {
      addDeploymentEnvironment(envNode);
    }

    // Queue relationships for later processing
    for (final relationship in node.relationships) {
      if (relationship is RelationshipNode) {
        _pendingRelationships.add(relationship);
      }
    }

    // Restore previous parent ID and context ID
    _currentParentId = previousParentId;
    referenceResolver.setCurrentContext(previousContextId);
  }

  @override
  void addContainer(ContainerNode node) {
    if (_currentParentId == null) {
      errorReporter.reportStandardError(
        'Container must be defined within a software system: ${node.name}',
        node.sourcePosition?.offset ?? 0,
      );
      return;
    }

    // Save the previous context ID and parent ID to support nesting
    final previousContextId = referenceResolver.getCurrentContextId();
    final previousParentId = _currentParentId;

    // Set this element as the current context for "this" references
    referenceResolver.setCurrentContext(node.id);

    // Create the container
    final container = Container(
      id: node.id,
      name: node.name,
      description: node.description,
      technology: node.technology,
      parentId: _currentParentId!,
      tags: node.tags,
      properties: node.properties ?? {},
    );

    // Add to model
    _addElementToModel(container);

    // Set as current parent for nested elements
    _currentParentId = container.id;

    // Process components
    for (final componentNode in node.components) {
      addComponent(componentNode);
    }

    // Queue relationships for later processing
    for (final relationship in node.relationships) {
      if (relationship is RelationshipNode) {
        _pendingRelationships.add(relationship);
      }
    }

    // Restore previous parent ID and context ID
    _currentParentId = previousParentId;
    referenceResolver.setCurrentContext(previousContextId);
  }

  @override
  void addComponent(ComponentNode node) {
    if (_currentParentId == null) {
      errorReporter.reportStandardError(
        'Component must be defined within a container: ${node.name}',
        node.sourcePosition?.offset ?? 0,
      );
      return;
    }

    // Save the previous context ID
    final previousContextId = referenceResolver.getCurrentContextId();

    // Set this element as the current context for "this" references
    referenceResolver.setCurrentContext(node.id);

    // Create the component
    final component = Component(
      id: node.id,
      name: node.name,
      description: node.description,
      technology: node.technology,
      parentId: _currentParentId!,
      tags: node.tags,
      properties: node.properties ?? {},
    );

    // Add to model
    _addElementToModel(component);

    // Queue relationships for later processing
    for (final relationship in node.relationships) {
      if (relationship is RelationshipNode) {
        _pendingRelationships.add(relationship);
      }
    }

    // Restore previous context ID
    referenceResolver.setCurrentContext(previousContextId);
  }

  @override
  void addDeploymentEnvironment(DeploymentEnvironmentNode node) {
    // Save the previous context ID and parent ID to support nesting
    final previousContextId = referenceResolver.getCurrentContextId();
    final previousParentId = _currentParentId;

    // Set this element as the current context for "this" references
    referenceResolver.setCurrentContext(node.id);

    // Create a new deployment environment
    final environment = DeploymentEnvironment(
      id: node.id,
      name: node.name,
      description: node.description,
      parentId: _currentParentId,
      tags: node.tags,
      properties: node.properties ?? {},
    );

    // Add to our element map for reference resolution
    _addElementToModel(environment);

    // Set this environment as the current parent for nested elements
    _currentParentId = environment.id;

    // Process child deployment nodes
    for (final deploymentNode in node.deploymentNodes) {
      addDeploymentNode(deploymentNode);
    }

    // Queue relationships for later processing
    for (final relationship in node.relationships) {
      if (relationship is RelationshipNode) {
        _pendingRelationships.add(relationship);
      }
    }

    // Restore previous parent ID and context ID
    _currentParentId = previousParentId;
    referenceResolver.setCurrentContext(previousContextId);
  }

  @override
  void addDeploymentNode(DeploymentNodeNode node) {
    if (_currentParentId == null) {
      errorReporter.reportStandardError(
        'Deployment node must be defined within a deployment environment or another deployment node: ${node.name}',
        node.sourcePosition?.offset ?? 0,
      );
      return;
    }

    // Save the previous context ID and parent ID to support nesting
    final previousContextId = referenceResolver.getCurrentContextId();
    final previousParentId = _currentParentId;

    // Set this element as the current context for "this" references
    referenceResolver.setCurrentContext(node.id);

    // Create the deployment node
    final deploymentNode = DeploymentNode(
      id: node.id,
      name: node.name,
      description: node.description,
      technology: node.technology,
      parentId: _currentParentId!,
      environment: _findEnvironmentForDeploymentNode(_currentParentId!),
      tags: node.tags,
      properties: node.properties ?? {},
    );

    // Add the new node to our element map
    _addElementToModel(deploymentNode);

    // Set this node as the current parent for nested elements
    _currentParentId = deploymentNode.id;

    // Process child deployment nodes
    for (final childNode in node.children) {
      if (childNode is DeploymentNodeNode) {
        addDeploymentNode(childNode);
      }
    }

    // Process infrastructure nodes
    for (final infraNode in node.infrastructureNodes) {
      addInfrastructureNode(infraNode);
    }

    // Process container instances
    for (final instance in node.containerInstances) {
      addContainerInstance(instance);
    }

    // Queue relationships for later processing
    for (final relationship in node.relationships) {
      if (relationship is RelationshipNode) {
        _pendingRelationships.add(relationship);
      }
    }

    // Restore previous parent ID and context ID
    _currentParentId = previousParentId;
    referenceResolver.setCurrentContext(previousContextId);
  }

  @override
  void addInfrastructureNode(InfrastructureNodeNode node) {
    if (_currentParentId == null) {
      errorReporter.reportStandardError(
        'Infrastructure node must be defined within a deployment node: ${node.name}',
        node.sourcePosition?.offset ?? 0,
      );
      return;
    }

    // Save the previous context ID
    final previousContextId = referenceResolver.getCurrentContextId();

    // Set this element as the current context for "this" references
    referenceResolver.setCurrentContext(node.id);

    // Create the infrastructure node
    final infraNode = InfrastructureNode(
      id: node.id,
      name: node.name,
      description: node.description,
      technology: node.technology,
      parentId: _currentParentId!,
      tags: node.tags,
      properties: node.properties ?? {},
    );

    // Add the infrastructure node to our element map
    _addElementToModel(infraNode);

    // Queue relationships for later processing
    for (final relationship in node.relationships) {
      if (relationship is RelationshipNode) {
        _pendingRelationships.add(relationship);
      }
    }

    // Restore previous context ID
    referenceResolver.setCurrentContext(previousContextId);
  }

  @override
  void addContainerInstance(ContainerInstanceNode node) {
    if (_currentParentId == null) {
      errorReporter.reportStandardError(
        'Container instance must be defined within a deployment node: ${node.containerId}',
        node.sourcePosition?.offset ?? 0,
      );
      return;
    }

    // Resolve the referenced container
    final container = referenceResolver.resolveReference(
      node.containerId,
      sourcePosition: node.sourcePosition,
      searchByName: true,
      expectedType: Container,
    ) as Container?;

    if (container == null) {
      errorReporter.reportStandardError(
        'Referenced container not found: ${node.containerId}',
        node.sourcePosition?.offset ?? 0,
      );
      return;
    }

    // Save the previous context ID
    final previousContextId = referenceResolver.getCurrentContextId();

    // Set this element as the current context for "this" references
    referenceResolver.setCurrentContext(node.id);

    // Create the container instance
    final instance = ContainerInstance(
      id: node.id,
      containerId: container.id, // Use the resolved container ID
      name: node.identifier, // Use identifier as name
      parentId: _currentParentId!,
      tags: node.tags,
      properties: node.properties ?? {},
    );

    // Add the container instance to our element map
    _addElementToModel(instance);

    // Queue relationships for later processing
    for (final relationship in node.relationships) {
      if (relationship is RelationshipNode) {
        _pendingRelationships.add(relationship);
      }
    }

    // Restore previous context ID
    referenceResolver.setCurrentContext(previousContextId);
  }

  @override
  void addRelationship(RelationshipNode node) {
    // Queue the relationship for processing later
    _pendingRelationships.add(node);
  }

  @override
  void addSystemLandscapeView(SystemLandscapeViewNode node) {
    // Create auto-layout if specified
    AutomaticLayout? automaticLayout;
    if (node.autoLayout != null) {
      automaticLayout = AutomaticLayout(
        rankDirection: node.autoLayout!.rankDirection ?? 'TB',
        rankSeparation: node.autoLayout!.rankSeparation ?? 300,
        nodeSeparation: node.autoLayout!.nodeSeparation ?? 300,
      );
    }

    // Create animation steps if specified
    final animationSteps = <AnimationStep>[];
    for (final animation in node.animations) {
      animationSteps.add(AnimationStep(
        order: animation.order,
        elements: animation.elements,
        relationships: animation.relationships,
      ));
    }

    // Process include/exclude rules for the view
    final includes =
        node.includes.map((include) => include.expression).toList();
    final excludes =
        node.excludes.map((exclude) => exclude.expression).toList();

    // Create a system landscape view
    final view = SystemLandscapeView(
      key: node.key,
      title: node.title ?? 'System Landscape',
      description: node.description,
      elements: [], // Elements will be populated based on include/exclude rules
      relationships: [], // Relationships will be computed
      automaticLayout: automaticLayout,
      animations: animationSteps,
      includeTags: includes?.cast<String>() ?? [],
      excludeTags: excludes?.cast<String>() ?? [],
    );

    // Add to views collection
    _currentViews = _currentViews.addSystemLandscapeView(view);

    if (workspace != null) {
      workspace = workspace!.updateViews(_currentViews);
    }
  }

  @override
  void addSystemContextView(SystemContextViewNode node) {
    // TODO: Replace with proper logging or remove for production
    // print(
    //     'DEBUG: [WorkspaceBuilderImpl] Delegating to SystemContextViewParser');
    // Print all registered software system IDs and names
    final allSystems = referenceResolver
        .getAllElements()
        .values
        .where((e) => e.runtimeType.toString() == 'SoftwareSystem');
    logger.info('DEBUG: [WorkspaceBuilderImpl] Registered software systems:');
    for (final sys in allSystems) {
      logger.info('  - id: ${sys.id}, name: ${sys.name}');
    }

    // Create a parser for system context views
    final parser = SystemContextViewParser(
      errorReporter: errorReporter,
      referenceResolver: referenceResolver,
    );

    // Parse the view using the dedicated parser
    final view = parser.parse(node, this);

    if (view != null) {
      // Add default elements (like the software system itself)
      addDefaultElements(node);

      // Add any implied relationships between elements in the view
      addImpliedRelationships();

      // Populate any defaults that aren't explicitly specified
      populateDefaults();

      // Set default properties from Java implementation
      setDefaultsFromJava();

      // Add to views collection
      _currentViews = _currentViews.addSystemContextView(view);

      if (workspace != null) {
        workspace = workspace!.updateViews(_currentViews);
      }
    }
  }

  @override
  void addDefaultElements(SystemContextViewNode viewNode) {
    final softwareSystem = referenceResolver.resolveReference(
      viewNode.softwareSystemId,
      sourcePosition: viewNode.sourcePosition,
      searchByName: true,
      expectedType: SoftwareSystem,
    ) as SoftwareSystem?;

    if (softwareSystem == null) {
      errorReporter.reportStandardError(
        'Software system not found for system context view: ${viewNode.key}, system ID: ${viewNode.softwareSystemId}',
        viewNode.sourcePosition?.offset ?? 0,
      );
      return;
    }

    // Add the software system itself if not already added
    if (!viewNode.hasElement(softwareSystem.id)) {
      viewNode.addElement(
          ElementNode(id: softwareSystem.id, name: softwareSystem.name));
    }
  }

  @override
  void addImpliedRelationships() {
    // Get all elements in the model
    final allElements = referenceResolver.getAllElements();

    // For each element in the model, check if it has relationships
    // to or from other elements that aren't explicitly declared
    for (final element in allElements.values) {
      // Skip if not a container or component (these are the ones that might have implied relationships)
      if (element.runtimeType.toString() != 'Container' &&
          element.runtimeType.toString() != 'Component') {
        continue;
      }

      // Find the parent element (software system for container, container for component)
      final parent = element.parentId != null
          ? referenceResolver.resolveReference(element.parentId!)
          : null;

      if (parent == null) continue;

      // For each relationship from this element
      for (final relationship in element.relationships) {
        final destinationElement =
            referenceResolver.resolveReference(relationship.destinationId);
        if (destinationElement == null) continue;

        // If the destination element is outside the parent's scope,
        // create an implied relationship from the parent to the destination
        if (destinationElement.parentId != parent.id) {
          // First check if a similar relationship already exists
          bool relationshipExists = false;
          for (final parentRel in parent.relationships) {
            if (parentRel.destinationId == destinationElement.id) {
              relationshipExists = true;
              break;
            }
          }

          // If no relationship exists, create an implied one
          if (!relationshipExists) {
            // We don't directly create the relationship here, as it would
            // modify the model state that's being iterated. Instead, we
            // queue it for processing after the loop.
            // For now, we just log the potential implied relationship
            logger.info(
                'DEBUG: [addImpliedRelationships] Found implied relationship: ${parent.name} -> ${destinationElement.name}');
          }
        }
      }
    }
  }

  @override
  void populateDefaults() {
    // This method populates any default values that aren't explicitly
    // specified in the DSL. This includes:
    // - Default element styles (shapes, colors, etc.)
    // - Default relationship styles (line types, arrows, etc.)
    // - Default view settings (paper size, orientation, etc.)

    // Get existing styles collection or create new
    Styles styles = workspace?.styles ?? const Styles();

    // Check if we already have default element styles
    if (!styles.hasElementStyle('Element')) {
      // Add default element style
      const defaultElementStyle = ElementStyle(
        tag: 'Element',
        shape: Shape.box,
        color: '#333333', // Dark grey text
        background: '#FAFAFA', // Light background
        fontSize: 24,
        border: Border.solid,
      );

      styles = styles.addElementStyle(defaultElementStyle);
    }

    // Check if we already have default relationship styles
    if (!styles.hasRelationshipStyle('Relationship')) {
      // Add default relationship style
      const defaultRelationshipStyle = RelationshipStyle(
        tag: 'Relationship',
        thickness: 2,
        color: '#555555', // Dark grey line
        style: LineStyle.solid,
        routing: StyleRouting.direct,
        fontSize: 22,
      );

      styles = styles.addRelationshipStyle(defaultRelationshipStyle);
    }

    // Update workspace with the styles
    if (workspace != null) {
      workspace = workspace!.copyWith(styles: styles);
    }
  }

  @override
  void setDefaultsFromJava() {
    // This method sets defaults to match the Java implementation
    // of Structurizr. This includes specific styles, layout,
    // and behavior that maintains compatibility with existing diagrams.

    // Get existing styles collection or create new
    Styles styles = workspace?.styles ?? const Styles();

    // Add Java-compatible styles for specific elements
    if (!styles.hasElementStyle('Person')) {
      // Add person style (uses a person shape)
      const personStyle = ElementStyle(
        tag: 'Person',
        shape: Shape.person,
        background: '#B3E5FC', // Light blue
        color: '#333333', // Dark grey text
        fontSize: 22,
        border: Border.solid,
      );

      styles = styles.addElementStyle(personStyle);
    }

    if (!styles.hasElementStyle('SoftwareSystem')) {
      // Add software system style
      const softwareSystemStyle = ElementStyle(
        tag: 'SoftwareSystem',
        shape: Shape.box,
        background: '#FDE293', // Light yellow
        color: '#333333', // Dark grey text
        fontSize: 22,
        border: Border.solid,
      );

      styles = styles.addElementStyle(softwareSystemStyle);
    }

    // Update workspace with the styles
    if (workspace != null) {
      workspace = workspace!.copyWith(styles: styles);
    }
  }

  @override
  void addContainerView(ContainerViewNode node) {
    // TODO: Replace with proper logging or remove for production
    logger.info(
        'DEBUG: addContainerView called with key: \\${node.key}, title: \\${node.title}');
    // Resolve the system reference
    final softwareSystem = referenceResolver.resolveReference(
      node.systemId,
      sourcePosition: node.sourcePosition,
      searchByName: true,
      expectedType: SoftwareSystem,
    ) as SoftwareSystem?;

    if (softwareSystem == null) {
      errorReporter.reportStandardError(
        'Software system not found for container view: ${node.key}, systemId: ${node.systemId}',
        node.sourcePosition?.offset ?? 0,
      );
      return;
    }

    // Create auto-layout if specified
    AutomaticLayout? automaticLayout;
    if (node.autoLayout != null) {
      automaticLayout = AutomaticLayout(
        rankDirection: node.autoLayout!.rankDirection ?? 'TB',
        rankSeparation: node.autoLayout!.rankSeparation ?? 300,
        nodeSeparation: node.autoLayout!.nodeSeparation ?? 300,
      );
    }

    // Process animations if specified
    final animationSteps = <AnimationStep>[];
    for (final animation in node.animations) {
      animationSteps.add(AnimationStep(
        order: animation.order,
        elements: animation.elements,
        relationships: animation.relationships,
      ));
    }

    // Process include/exclude rules for the view
    final includes =
        node.includes.map((include) => include.expression).toList();
    final excludes =
        node.excludes.map((exclude) => exclude.expression).toList();

    // Create a container view
    final view = ContainerView(
      key: node.key,
      softwareSystemId: softwareSystem.id,
      title: node.title ?? '${softwareSystem.name} - Containers',
      description: node.description,
      elements: [], // Elements will be populated based on include/exclude rules
      relationships: [], // Relationships will be computed
      automaticLayout: automaticLayout,
      animations: animationSteps,
      includeTags: includes?.cast<String>() ?? [],
      excludeTags: excludes?.cast<String>() ?? [],
    );

    // Add to views collection
    _currentViews = _currentViews.addContainerView(view);

    if (workspace != null) {
      workspace = workspace!.updateViews(_currentViews);
    }
  }

  @override
  void addComponentView(ComponentViewNode node) {
    // TODO: Replace with proper logging or remove for production
    logger.info(
        'DEBUG: addComponentView called with key: \\${node.key}, title: \\${node.title}');
    // Resolve the container reference
    final container = referenceResolver.resolveReference(
      node.containerId,
      sourcePosition: node.sourcePosition,
      searchByName: true,
      expectedType: Container,
    ) as Container?;

    if (container == null) {
      errorReporter.reportStandardError(
        'Container not found for component view: ${node.key}, containerId: ${node.containerId}',
        node.sourcePosition?.offset ?? 0,
      );
      return;
    }

    // Create auto-layout if specified
    AutomaticLayout? automaticLayout;
    if (node.autoLayout != null) {
      automaticLayout = AutomaticLayout(
        rankDirection: node.autoLayout!.rankDirection ?? 'TB',
        rankSeparation: node.autoLayout!.rankSeparation ?? 300,
        nodeSeparation: node.autoLayout!.nodeSeparation ?? 300,
      );
    }

    // Process animations if specified
    final animationSteps = <AnimationStep>[];
    for (final animation in node.animations) {
      animationSteps.add(AnimationStep(
        order: animation.order,
        elements: animation.elements,
        relationships: animation.relationships,
      ));
    }

    // Process include/exclude rules for the view
    final includes =
        node.includes.map((include) => include.expression).toList();
    final excludes =
        node.excludes.map((exclude) => exclude.expression).toList();

    // Get the software system for this container
    SoftwareSystem? softwareSystem = null;
    if (container.parentId != null) {
      softwareSystem = _softwareSystemsById[container.parentId];
    }

    if (softwareSystem == null) {
      errorReporter.reportStandardError(
        'Could not find parent software system for container: ${container.name}',
        node.sourcePosition?.offset ?? 0,
      );
      return;
    }

    // Create a component view
    final view = ComponentView(
      key: node.key,
      softwareSystemId: softwareSystem.id,
      containerId: container.id,
      title: node.title ?? '${container.name} - Components',
      description: node.description,
      elements: [], // Elements will be populated based on include/exclude rules
      relationships: [], // Relationships will be computed
      automaticLayout: automaticLayout,
      animations: animationSteps,
      includeTags: includes?.cast<String>() ?? [],
      excludeTags: excludes?.cast<String>() ?? [],
    );

    // Add to views collection
    _currentViews = _currentViews.addComponentView(view);

    if (workspace != null) {
      workspace = workspace!.updateViews(_currentViews);
    }
  }

  @override
  void addDynamicView(DynamicViewNode node) {
    // TODO: Replace with proper logging or remove for production
    logger.info(
        'DEBUG: addDynamicView called with key: \\${node.key}, title: \\${node.title}');
    // Find the scope element if specified
    String? scopeId = node.scope;
    Element? scopeElement;
    String description = 'Dynamic View';

    if (scopeId != null) {
      scopeElement = referenceResolver.resolveReference(
        scopeId,
        sourcePosition: node.sourcePosition,
        searchByName: true,
      );
    }

    if (scopeElement == null) {
      errorReporter.reportStandardError(
        'Scope element not found for dynamic view: ${node.key}, scope: $scopeId',
        node.sourcePosition?.offset ?? 0,
      );
      return;
    }

    // Update scopeId with the resolved element ID
    scopeId = scopeElement.id;
    description = 'Dynamic view of ${scopeElement.name}';

    // Create auto-layout if specified
    AutomaticLayout? automaticLayout;
    if (node.autoLayout != null) {
      automaticLayout = AutomaticLayout(
        rankDirection: node.autoLayout!.rankDirection ?? 'TB',
        rankSeparation: node.autoLayout!.rankSeparation ?? 300,
        nodeSeparation: node.autoLayout!.nodeSeparation ?? 300,
      );
    }

    // Process animations if specified
    // For dynamic views, animations define the sequence of interactions
    final animationSteps = <AnimationStep>[];

    for (int i = 0; i < node.animations.length; i++) {
      final animation = node.animations[i];

      // Create animation step with the specified order
      animationSteps.add(AnimationStep(
        order: animation.order,
        elements: animation.elements,
        relationships: animation.relationships,
      ));
    }

    // Process include/exclude rules for the view
    final includes =
        node.includes.map((include) => include.expression).toList();
    final excludes =
        node.excludes.map((exclude) => exclude.expression).toList();

    // Create a dynamic view
    final view = DynamicView(
      key: node.key,
      elementId: scopeId, // Use elementId instead of scope
      title: node.title ?? description,
      description: node.description,
      elements: [], // Elements will be populated based on include/exclude rules and animation steps
      relationships: [], // Relationships will be computed from animation steps
      automaticLayout: automaticLayout,
      animations: animationSteps,
      includeTags: includes?.cast<String>() ?? [],
      excludeTags: excludes?.cast<String>() ?? [],
    );

    // Add to views collection
    _currentViews = _currentViews.addDynamicView(view);

    if (workspace != null) {
      workspace = workspace!.updateViews(_currentViews);
    }
  }

  @override
  void addDeploymentView(DeploymentViewNode node) {
    // TODO: Replace with proper logging or remove for production
    logger.info(
        'DEBUG: addDeploymentView called with key: \\${node.key}, title: \\${node.title}');
    // Resolve the system reference
    final softwareSystem = node.systemId != null ? referenceResolver.resolveReference(
      node.systemId!,
      sourcePosition: node.sourcePosition,
      searchByName: true,
      expectedType: SoftwareSystem,
    ) as SoftwareSystem? : null;

    if (softwareSystem == null) {
      errorReporter.reportStandardError(
        'Software system not found for deployment view: ${node.key}, systemId: ${node.systemId}',
        node.sourcePosition?.offset ?? 0,
      );
      return;
    }

    // Create auto-layout if specified
    AutomaticLayout? automaticLayout;
    if (node.autoLayout != null) {
      automaticLayout = AutomaticLayout(
        rankDirection: node.autoLayout!.rankDirection ?? 'TB',
        rankSeparation: node.autoLayout!.rankSeparation ?? 300,
        nodeSeparation: node.autoLayout!.nodeSeparation ?? 300,
      );
    }

    // Process animations if specified
    final animationSteps = <AnimationStep>[];
    for (final animation in node.animations) {
      animationSteps.add(AnimationStep(
        order: animation.order,
        elements: animation.elements,
        relationships: animation.relationships,
      ));
    }

    // Process include/exclude rules for the view
    final includes =
        node.includes.map((include) => include.expression).toList();
    final excludes =
        node.excludes.map((exclude) => exclude.expression).toList();

    // Create a deployment view
    final view = DeploymentView(
      key: node.key,
      softwareSystemId: softwareSystem.id,
      environment: node.environment,
      title: node.title ??
          '${softwareSystem.name} - ${node.environment} Deployment',
      description: node.description,
      elements: [], // Elements will be populated based on include/exclude rules
      relationships: [], // Relationships will be computed
      automaticLayout: automaticLayout,
      animations: animationSteps,
      includeTags: includes?.cast<String>() ?? [],
      excludeTags: excludes?.cast<String>() ?? [],
    );

    // Add to views collection
    _currentViews = _currentViews.addDeploymentView(view);

    if (workspace != null) {
      workspace = workspace!.updateViews(_currentViews);
    }
  }

  @override
  void addFilteredView(FilteredViewNode node) {
    // TODO: Replace with proper logging or remove for production
    logger.info(
        'DEBUG: addFilteredView called with key: \\${node.key}, title: \\${node.title}');
    // Find the base view by key
    View? baseView;

    // Check in all view collections
    if (_currentViews.systemLandscapeViews
        .any((v) => v.key == node.baseViewKey)) {
      baseView = _currentViews.systemLandscapeViews
          .firstWhere((v) => v.key == node.baseViewKey);
    } else if (_currentViews.systemContextViews
        .any((v) => v.key == node.baseViewKey)) {
      baseView = _currentViews.systemContextViews
          .firstWhere((v) => v.key == node.baseViewKey);
    } else if (_currentViews.containerViews
        .any((v) => v.key == node.baseViewKey)) {
      baseView = _currentViews.containerViews
          .firstWhere((v) => v.key == node.baseViewKey);
    } else if (_currentViews.componentViews
        .any((v) => v.key == node.baseViewKey)) {
      baseView = _currentViews.componentViews
          .firstWhere((v) => v.key == node.baseViewKey);
    } else if (_currentViews.dynamicViews
        .any((v) => v.key == node.baseViewKey)) {
      baseView = _currentViews.dynamicViews
          .firstWhere((v) => v.key == node.baseViewKey);
    } else if (_currentViews.deploymentViews
        .any((v) => v.key == node.baseViewKey)) {
      baseView = _currentViews.deploymentViews
          .firstWhere((v) => v.key == node.baseViewKey);
    }

    if (baseView == null) {
      errorReporter.reportStandardError(
        'Base view not found for filtered view: ${node.key}, baseViewKey: ${node.baseViewKey}',
        node.sourcePosition?.offset ?? 0,
      );
      return;
    }

    // Process include/exclude rules for the view
    final includes =
        node.includes.map((include) => include.expression).toList();
    final excludes =
        node.excludes.map((exclude) => exclude.expression).toList();

    // Create a filtered view
    final view = FilteredView(
      key: node.key,
      baseViewKey: node.baseViewKey,
      title: node.title ?? 'Filtered: ${baseView.title}',
      description: node.description,
      includeTags: includes?.cast<String>() ?? [],
      excludeTags: excludes?.cast<String>() ?? [],
    );

    // Add to views collection
    _currentViews = _currentViews.addFilteredView(view);

    if (workspace != null) {
      workspace = workspace!.updateViews(_currentViews);
    }
  }

  @override
  void addCustomView(CustomViewNode node) {
    // TODO: Replace with proper logging or remove for production
    logger.info(
        'DEBUG: addCustomView called with key: \\${node.key}, title: \\${node.title}');
    // Create auto-layout if specified
    AutomaticLayout? automaticLayout;
    if (node.autoLayout != null) {
      automaticLayout = AutomaticLayout(
        rankDirection: node.autoLayout!.rankDirection ?? 'TB',
        rankSeparation: node.autoLayout!.rankSeparation ?? 300,
        nodeSeparation: node.autoLayout!.nodeSeparation ?? 300,
      );
    }

    // Process animations if specified
    final animationSteps = <AnimationStep>[];
    for (final animation in node.animations) {
      animationSteps.add(AnimationStep(
        order: animation.order,
        elements: animation.elements,
        relationships: animation.relationships,
      ));
    }

    // Process include/exclude rules for the view
    final includes =
        node.includes.map((include) => include.expression).toList();
    final excludes =
        node.excludes.map((exclude) => exclude.expression).toList();

    // Create a custom view
    final view = CustomView(
      key: node.key,
      title: node.title ?? 'Custom View',
      description: node.description,
      elements: [], // Elements will be populated based on include/exclude rules
      relationships: [], // Relationships will be computed
      paperSize: 'A4_Landscape', // Default
      automaticLayout: automaticLayout,
      animations: animationSteps,
      includeTags: includes?.cast<String>() ?? [],
      excludeTags: excludes?.cast<String>() ?? [],
    );

    // Add to views collection
    _currentViews = _currentViews.addCustomView(view);

    if (workspace != null) {
      workspace = workspace!.updateViews(_currentViews);
    }
  }

  @override
  void addImageView(ImageViewNode node) {
    // TODO: Replace with proper logging or remove for production
    logger.info(
        'DEBUG: addImageView called with key: \\${node.key}, title: \\${node.title}');
    // Create an image view
    final view = ImageView(
      key: node.key,
      title: node.title ?? 'Image View',
      description: node.description,
      imageType: node.imageType,
      content: node.content,
      paperSize: 'A4_Landscape', // Default
    );

    // Add to views collection
    _currentViews = _currentViews.addImageView(view);

    if (workspace != null) {
      workspace = workspace!.updateViews(_currentViews);
    }
  }

  @override
  void applyStyles(StylesNode node) {
    // Get existing styles collection or create new
    Styles styles = workspace?.styles ?? const Styles();

    // Process element styles
    for (final elementStyle in node.elementStyles) {
      // Convert the style node to a style object
      final style = _elementStyleFromNode(elementStyle);
      if (style != null) {
        styles = styles.addElementStyle(style);
      }
    }

    // Process relationship styles
    for (final relationshipStyle in node.relationshipStyles) {
      // Convert the style node to a style object
      final style = _relationshipStyleFromNode(relationshipStyle);
      if (style != null) {
        styles = styles.addRelationshipStyle(style);
      }
    }

    // Update workspace with the styles
    if (workspace != null) {
      workspace = workspace!.copyWith(styles: styles);
    }
  }

  @override
  void applyTheme(ThemeNode node) {
    // Get existing styles collection or create new
    Styles styles = workspace?.styles ?? const Styles();

    // Add the theme URL to the styles
    if (node.url != null) {
      styles = styles.addTheme(node.url!);
    }

    // Update workspace with the styles
    if (workspace != null) {
      workspace = workspace!.copyWith(styles: styles);
    }
  }

  @override
  void applyBranding(BrandingNode node) {
    // Create branding configuration
    Branding branding = Branding(
      logo: node.logo,
    );

    // Add font if specified
    if (node.font != null) {
      branding = branding.addFont(Font(
        name: node.font!,
        url: '', // URL is not specified in the DSL, so we use an empty string
      ));
    }

    // Update workspace with the branding
    if (workspace != null) {
      workspace = workspace!.copyWith(branding: branding);
    }
  }

  @override
  void applyTerminology(TerminologyNode node) {
    // Create terminology configuration
    final terminology = Terminology(
      enterprise: node.enterprise,
      person: node.person,
      softwareSystem: node.softwareSystem,
      container: node.container,
      component: node.component,
      codeElement: node.code,
      deploymentNode: node.deploymentNode,
      relationship: node.relationship,
    );

    // Create view configuration with the terminology
    final viewConfiguration = ViewConfiguration(
      terminology: terminology,
    );

    // Update workspace views configuration
    _currentViews = _currentViews.copyWith(
      configuration: viewConfiguration,
    );

    // Update workspace with the views
    if (workspace != null) {
      workspace = workspace!.copyWith(views: _currentViews);
    }
  }

  @override
  List<RelationshipNode> getPendingRelationships() {
    return List.unmodifiable(_pendingRelationships);
  }

  @override
  void resolveRelationships() {
    // TODO: Replace with proper logging or remove for production
    logger.info(
        'DEBUG: [resolveRelationships] Pending relationships: \\${_pendingRelationships.length}');
    for (final rel in _pendingRelationships) {
      logger.info(
          'DEBUG: [resolveRelationships] Pending: source=\\${rel.sourceId}, dest=\\${rel.destinationId}, desc=\\${rel.description}');
    }
    // First process all relationships to create basic relationships
    for (final relationshipNode in _pendingRelationships) {
      _processRelationship(relationshipNode);
    }
    // Now that all relationships are created and added to the model,
    // we can validate them
    _validateRelationships();
    // Print all relationships in the model after processing
    logger.info(
        'DEBUG: [resolveRelationships] Model relationships after processing:');
    for (final rel in _currentModel.getAllRelationships()) {
      logger.info(
          '  - id: \\${rel.id}, source: \\${rel.sourceId}, dest: \\${rel.destinationId}, desc: \\${rel.description}');
    }
  }

  @override
  void setCurrentParent(String? parentId) {
    _currentParentId = parentId;
  }

  @override
  String? getCurrentParent() {
    return _currentParentId;
  }

  @override
  Workspace? build() {
    if (workspace == null) {
      errorReporter.reportStandardError(
        'Cannot build workspace: workspace has not been created',
        0,
      );
      return null;
    }

    // Validate the workspace
    final errors = workspace!.validate();
    if (errors.isNotEmpty) {
      for (final error in errors) {
        errorReporter.reportStandardError(error, 0);
      }
      return null;
    }

    return workspace;
  }

  /// Helper method to convert tags to a List of tag strings.
  List<String> _mapTags(dynamic tags) {
    if (tags is List<String>) return tags;
    if (tags is TagsNode) return tags.tags;
    return [];
  }

  /// Helper method to convert properties to a Map<String, String>.
  Map<String, String> _mapProperties(dynamic properties) {
    if (properties is Map<String, String>) return properties;
    if (properties is PropertiesNode) return properties.properties;
    return {};
  }

  /// Finds the environment name for a deployment node by traversing up the hierarchy.
  String _findEnvironmentForDeploymentNode(String nodeId) {
    Element? current = referenceResolver.resolveReference(nodeId);

    while (current != null) {
      if (current is DeploymentEnvironment) {
        return current.name;
      }

      current = current.parentId != null
          ? referenceResolver.resolveReference(current.parentId!)
          : null;
    }

    return 'Default'; // Fallback environment name
  }

  /// Processes a relationship and adds it to the source element.
  void _processRelationship(RelationshipNode node) {
    String sourceId = node.sourceId;
    String destinationId = node.destinationId;

    // Resolve source and destination references with improved context handling
    // We'll save the current context to restore it later
    final previousContextId = referenceResolver.getCurrentContextId();

    // Resolve source element reference
    final sourceElement = referenceResolver.resolveReference(
      sourceId,
      sourcePosition: node.sourcePosition,
      searchByName: true,
    );

    if (sourceElement == null) {
      errorReporter.reportStandardError(
        'Relationship source element not found: $sourceId',
        node.sourcePosition?.offset ?? 0,
      );
      return;
    }

    // Set the source element as the context for resolving the destination
    // This enables proper resolution of references like "parent" from the source's context
    referenceResolver.setCurrentContext(sourceElement.id);

    // Resolve destination element reference with the source as context
    final destinationElement = referenceResolver.resolveReference(
      destinationId,
      sourcePosition: node.sourcePosition,
      searchByName: true,
    );

    // Restore the previous context
    referenceResolver.setCurrentContext(previousContextId);

    if (destinationElement == null) {
      errorReporter.reportStandardError(
        'Relationship destination element not found: $destinationId',
        node.sourcePosition?.offset ?? 0,
      );
      return;
    }

    // Update sourceId and destinationId with resolved IDs
    sourceId = sourceElement.id;
    destinationId = destinationElement.id;

    // Add the relationship to the source element
    final newElement = sourceElement.addRelationship(
      destinationId: destinationId,
      description: node.description ?? '',
      technology: node.technology,
      tags: node.tags != null ? _mapTags(node.tags) : const [],
      properties:
          node.properties != null ? _mapProperties(node.properties) : const {},
    );

    // Update the reference resolver with the updated element
    referenceResolver.registerElement(newElement);

    // Update the model with the new element
    _updateModelWithElement(newElement);

    // Get the relationship that was just added
    final addedRelationship = newElement.relationships.firstWhere(
      (rel) =>
          rel.destinationId == destinationId &&
          rel.description == (node.description ?? ''),
      orElse: () => throw Exception('Failed to find added relationship'),
    );

    // Create a modeled relationship for better source/destination access
    if (addedRelationship is! ModeledRelationship) {
      // This allows us to access the source and destination elements directly
      final modeledRelationship = ModeledRelationship.fromRelationship(
        addedRelationship,
        _currentModel,
      );

      // The model will handle the modeled relationships via the findRelationshipBetween method
    }
  }

  /// Validates all relationships in the model for consistency.
  void _validateRelationships() {
    // Get all elements
    final allElements = referenceResolver.getAllElements();

    // Check for relationships to non-existent elements
    for (final element in allElements.values) {
      for (final relationship in element.relationships) {
        if (!allElements.containsKey(relationship.destinationId)) {
          errorReporter.reportStandardError(
            'Relationship from ${element.name} references non-existent destination: ${relationship.destinationId}',
            0, // Offset not available here
          );
        }
      }
    }
  }

  /// Updates the model with a modified element.
  void _updateModelWithElement(Element element) {
    if (element is Person) {
      _currentModel = _currentModel.copyWith(
        people: _currentModel.people
            .map((p) => p.id == element.id ? element : p)
            .toList(),
      );
    } else if (element is SoftwareSystem) {
      _currentModel = _currentModel.copyWith(
        softwareSystems: _currentModel.softwareSystems
            .map((s) => s.id == element.id ? element : s)
            .toList(),
      );

      // Update the cache
      _softwareSystemsById[element.id] = element;
    } else if (element is Container) {
      // Find the parent software system
      final parentSystem = _softwareSystemsById[element.parentId!];
      if (parentSystem != null) {
        // Update the container in the parent
        final updatedSystem = parentSystem.copyWith(
          containers: parentSystem.containers
              .map((c) => c.id == element.id ? element : c)
              .toList(),
        );

        // Update the software system in the model
        _currentModel = _currentModel.copyWith(
          softwareSystems: _currentModel.softwareSystems
              .map((s) => s.id == updatedSystem.id ? updatedSystem : s)
              .toList(),
        );

        // Update caches
        _softwareSystemsById[updatedSystem.id] = updatedSystem;
        _containersById[element.id] = element;
      }
    } else if (element is Component) {
      // Find the parent container
      final parentContainer = _containersById[element.parentId!];
      if (parentContainer != null) {
        // Update the component in the parent
        final updatedContainer = parentContainer.addComponent(element);

        // Update the container in the model by updating its parent system
        final parentSystem = _softwareSystemsById[updatedContainer.parentId];
        if (parentSystem != null) {
          final updatedSystem = parentSystem.copyWith(
            containers: parentSystem.containers
                .map((c) => c.id == updatedContainer.id ? updatedContainer : c)
                .toList(),
          );

          // Update the software system in the model
          _currentModel = _currentModel.copyWith(
            softwareSystems: _currentModel.softwareSystems
                .map((s) => s.id == updatedSystem.id ? updatedSystem : s)
                .toList(),
          );

          // Update caches
          _softwareSystemsById[updatedSystem.id] = updatedSystem;
          _containersById[updatedContainer.id] = updatedContainer;
          _componentsById[element.id] = element;
        }
      }
    } else if (element is DeploymentNode) {
      // This is a complex update as we need to find the node in its hierarchy
      _updateDeploymentNodeInModel(element);
    } else if (element is InfrastructureNode) {
      // This is a complex update that requires finding the parent deployment node
      _updateInfrastructureNodeInModel(element);
    } else if (element is ContainerInstance) {
      // This is a complex update that requires finding the parent deployment node
      _updateContainerInstanceInModel(element);
    } else if (element is DeploymentEnvironment) {
      // Find if the environment is in the main model or in a software system
      final envIndex = _currentModel.deploymentEnvironments
          .indexWhere((e) => e.id == element.id);
      if (envIndex >= 0) {
        // In the main model
        _currentModel = _currentModel.copyWith(
          deploymentEnvironments: _currentModel.deploymentEnvironments
              .map((e) => e.id == element.id ? element : e)
              .toList(),
        );
      } else {
        // Check in software systems
        for (final system in _currentModel.softwareSystems) {
          final systemEnvIndex = system.deploymentEnvironments
              .indexWhere((e) => e.id == element.id);
          if (systemEnvIndex >= 0) {
            final updatedSystem = system.copyWith(
              deploymentEnvironments: system.deploymentEnvironments
                  .map((e) => e.id == element.id ? element : e)
                  .toList(),
            );

            // Update the system in the model
            _currentModel = _currentModel.copyWith(
              softwareSystems: _currentModel.softwareSystems
                  .map((s) => s.id == updatedSystem.id ? updatedSystem : s)
                  .toList(),
            );

            // Update caches
            _softwareSystemsById[updatedSystem.id] = updatedSystem;
            _environmentsById[element.id] = element;
            break;
          }
        }
      }
    }

    // Update the workspace with the new model
    if (workspace != null) {
      workspace = workspace!.updateModel(_currentModel);
    }
  }

  /// Updates a deployment node in the model, traversing the hierarchy as needed.
  void _updateDeploymentNodeInModel(DeploymentNode node) {
    // We need to find the root environment that contains this node
    DeploymentEnvironment? rootEnvironment;
    String? rootEnvId;

    // Traverse up the parent chain to find the root environment
    Element? current = node;
    while (current != null && current is! DeploymentEnvironment) {
      if (current.parentId == null) break;
      current = referenceResolver.resolveReference(current.parentId!);
    }

    if (current is DeploymentEnvironment) {
      rootEnvironment = current;
      rootEnvId = rootEnvironment.id;
    } else {
      // Could not find the root environment
      errorReporter.reportStandardError(
        'Could not find root environment for deployment node: ${node.name}',
        0,
      );
      return;
    }

    // Now we have the root environment, update the node

    // This recursive function updates a node in the deployment node tree
    DeploymentNode updateNodeInTree(DeploymentNode currentNode, String targetId,
        DeploymentNode updatedNode) {
      if (currentNode.id == targetId) {
        // This is the node we want to update
        return updatedNode;
      } else {
        // Check children recursively
        final updatedChildren = currentNode.children
            .map((child) => updateNodeInTree(child, targetId, updatedNode))
            .toList();

        return currentNode.copyWith(children: updatedChildren);
      }
    }

    // Update all deployment nodes in the environment
    final updatedNodes = rootEnvironment.deploymentNodes.map((deploymentNode) {
      // Check if this node or any of its children need updating
      if (deploymentNode.id == node.id) {
        return node;
      } else {
        // Check in the children
        return updateNodeInTree(deploymentNode, node.id, node);
      }
    }).toList();

    // Update the environment with the updated deployment nodes
    final updatedEnvironment =
        rootEnvironment.copyWith(deploymentNodes: updatedNodes);

    // Update the environment in the model
    // Check if it's in the main model or in a software system
    final envIndex = _currentModel.deploymentEnvironments
        .indexWhere((e) => e.id == rootEnvId);
    if (envIndex >= 0) {
      // In the main model
      _currentModel = _currentModel.copyWith(
        deploymentEnvironments: _currentModel.deploymentEnvironments
            .map((e) => e.id == rootEnvId ? updatedEnvironment : e)
            .toList(),
      );

      // Update the cache
      _environmentsById[rootEnvId] = updatedEnvironment;
    } else {
      // Check in software systems
      for (final system in _currentModel.softwareSystems) {
        final systemEnvIndex =
            system.deploymentEnvironments.indexWhere((e) => e.id == rootEnvId);
        if (systemEnvIndex >= 0) {
          final updatedSystem = system.copyWith(
            deploymentEnvironments: system.deploymentEnvironments
                .map((e) => e.id == rootEnvId ? updatedEnvironment : e)
                .toList(),
          );

          // Update the system in the model
          _currentModel = _currentModel.copyWith(
            softwareSystems: _currentModel.softwareSystems
                .map((s) => s.id == updatedSystem.id ? updatedSystem : s)
                .toList(),
          );

          // Update caches
          _softwareSystemsById[updatedSystem.id] = updatedSystem;
          _environmentsById[rootEnvId] = updatedEnvironment;
          break;
        }
      }
    }

    // Update the deployment node in the caches
    _deploymentNodesById[node.id] = node;

    // Update the workspace with the new model
    if (workspace != null) {
      workspace = workspace!.updateModel(_currentModel);
    }
  }

  /// Updates an infrastructure node in the model, traversing the hierarchy as needed.
  void _updateInfrastructureNodeInModel(InfrastructureNode node) {
    // Find the parent deployment node
    final parentNode = _deploymentNodesById[node.parentId];
    if (parentNode == null) {
      errorReporter.reportStandardError(
        'Parent deployment node not found for infrastructure node: ${node.name}',
        0,
      );
      return;
    }

    // Update the parent node with the new infrastructure node
    final updatedParentNode = parentNode.copyWith(
      infrastructureNodes: parentNode.infrastructureNodes
          .map((n) => n.id == node.id ? node : n)
          .toList(),
    );

    // Update the parent node in the model
    _updateDeploymentNodeInModel(updatedParentNode);

    // Update the infrastructure node in the caches
    _infrastructureNodesById[node.id] = node;
  }

  /// Updates a container instance in the model, traversing the hierarchy as needed.
  void _updateContainerInstanceInModel(ContainerInstance node) {
    // Find the parent deployment node
    final parentNode = _deploymentNodesById[node.parentId];
    if (parentNode == null) {
      errorReporter.reportStandardError(
        'Parent deployment node not found for container instance: ${node.id}',
        0,
      );
      return;
    }

    // Update the parent node with the new container instance
    final updatedParentNode = parentNode.copyWith(
      containerInstances: parentNode.containerInstances
          .map((n) => n.id == node.id ? node : n)
          .toList(),
    );

    // Update the parent node in the model
    _updateDeploymentNodeInModel(updatedParentNode);

    // Update the container instance in the caches
    _containerInstancesById[node.id] = node;
  }

  /// Adds an element to the current model.
  void _addElementToModel(Element element) {
    // Register the element with the reference resolver
    referenceResolver.registerElement(element);

    // Store in type-specific maps for faster lookups
    if (element is Person) {
      _currentModel = _currentModel.addPerson(element);
    } else if (element is SoftwareSystem) {
      _currentModel = _currentModel.addSoftwareSystem(element);
      _softwareSystemsById[element.id] = element;
    } else if (element is Container) {
      // Find the parent software system
      final parentSystem = _softwareSystemsById[element.parentId!];
      if (parentSystem != null) {
        // Add the container to the parent
        final updatedSystem = parentSystem.addContainer(element);

        // Update the software system in the model
        _currentModel = _currentModel.copyWith(
          softwareSystems: _currentModel.softwareSystems
              .map((s) => s.id == updatedSystem.id ? updatedSystem : s)
              .toList(),
        );

        // Update caches
        _softwareSystemsById[updatedSystem.id] = updatedSystem;
        _containersById[element.id] = element;
      } else {
        errorReporter.reportStandardError(
          'Parent software system not found for container: ${element.name}',
          0, // Offset not available here
        );
      }
    } else if (element is Component) {
      // Find the parent container
      final parentContainer = _containersById[element.parentId!];
      if (parentContainer != null) {
        // Add the component to the parent
        final updatedContainer = parentContainer.addComponent(element);

        // Update the container in the model by updating its parent system
        final parentSystem = _softwareSystemsById[updatedContainer.parentId];
        if (parentSystem != null) {
          final updatedSystem = parentSystem.copyWith(
            containers: parentSystem.containers
                .map((c) => c.id == updatedContainer.id ? updatedContainer : c)
                .toList(),
          );

          // Update the software system in the model
          _currentModel = _currentModel.copyWith(
            softwareSystems: _currentModel.softwareSystems
                .map((s) => s.id == updatedSystem.id ? updatedSystem : s)
                .toList(),
          );

          // Update caches
          _softwareSystemsById[updatedSystem.id] = updatedSystem;
          _containersById[updatedContainer.id] = updatedContainer;
          _componentsById[element.id] = element;
        }
      }
    } else if (element is DeploymentEnvironment) {
      // Add the environment to the model
      if (element.parentId != null) {
        // Add to parent software system
        final parentSystem = _softwareSystemsById[element.parentId!];
        if (parentSystem != null) {
          final updatedSystem = parentSystem.copyWith(
            deploymentEnvironments: [
              ...parentSystem.deploymentEnvironments,
              element
            ],
          );

          // Update the model with the modified system
          _currentModel = _currentModel.copyWith(
            softwareSystems: _currentModel.softwareSystems
                .map((s) => s.id == updatedSystem.id ? updatedSystem : s)
                .toList(),
          );

          // Update caches
          _softwareSystemsById[updatedSystem.id] = updatedSystem;
        } else {
          errorReporter.reportStandardError(
            'Parent software system not found for deployment environment: ${element.name}',
            0, // Offset not available here
          );
        }
      } else {
        // Add directly to the model
        _currentModel = _currentModel.copyWith(
          deploymentEnvironments: [
            ..._currentModel.deploymentEnvironments,
            element
          ],
        );
      }

      // Update environment cache
      _environmentsById[element.id] = element;
    } else if (element is DeploymentNode) {
      // Add the node to the parent
      final parentId = element.parentId!;
      final parentElement = referenceResolver.resolveReference(parentId);

      if (parentElement is DeploymentEnvironment) {
        // Add to environment
        final updatedEnvironment = parentElement.copyWith(
          deploymentNodes: [...parentElement.deploymentNodes, element],
        );

        // Update the environment in the model
        if (updatedEnvironment.parentId != null) {
          // In a software system
          final parentSystem =
              _softwareSystemsById[updatedEnvironment.parentId!];
          if (parentSystem != null) {
            final updatedSystem = parentSystem.copyWith(
              deploymentEnvironments: parentSystem.deploymentEnvironments
                  .map((e) =>
                      e.id == updatedEnvironment.id ? updatedEnvironment : e)
                  .toList(),
            );

            // Update the model
            _currentModel = _currentModel.copyWith(
              softwareSystems: _currentModel.softwareSystems
                  .map((s) => s.id == updatedSystem.id ? updatedSystem : s)
                  .toList(),
            );

            // Update caches
            _softwareSystemsById[updatedSystem.id] = updatedSystem;
          }
        } else {
          // In the main model
          _currentModel = _currentModel.copyWith(
            deploymentEnvironments: _currentModel.deploymentEnvironments
                .map((e) =>
                    e.id == updatedEnvironment.id ? updatedEnvironment : e)
                .toList(),
          );
        }

        // Update environment cache
        _environmentsById[updatedEnvironment.id] = updatedEnvironment;

        // Update in reference resolver
        referenceResolver.registerElement(updatedEnvironment);
      } else if (parentElement is DeploymentNode) {
        // Add to parent deployment node
        final updatedParentNode = parentElement.copyWith(
          children: [...parentElement.children, element],
        );

        // Update the parent node in the model
        _updateDeploymentNodeInModel(updatedParentNode);

        // Update in reference resolver
        referenceResolver.registerElement(updatedParentNode);
      } else {
        errorReporter.reportStandardError(
          'Invalid parent type for deployment node: ${element.name}',
          0, // Offset not available here
        );
      }

      // Update deployment node cache
      _deploymentNodesById[element.id] = element;
    } else if (element is InfrastructureNode) {
      // Add the node to the parent deployment node
      final parentNode = _deploymentNodesById[element.parentId!];
      if (parentNode != null) {
        final updatedParentNode = parentNode.copyWith(
          infrastructureNodes: [...parentNode.infrastructureNodes, element],
        );

        // Update the parent node in the model
        _updateDeploymentNodeInModel(updatedParentNode);

        // Update infrastructure node cache
        _infrastructureNodesById[element.id] = element;

        // Update in reference resolver
        referenceResolver.registerElement(updatedParentNode);
      } else {
        errorReporter.reportStandardError(
          'Parent deployment node not found for infrastructure node: ${element.name}',
          0, // Offset not available here
        );
      }
    } else if (element is ContainerInstance) {
      // Add the instance to the parent deployment node
      final parentNode = _deploymentNodesById[element.parentId!];
      if (parentNode != null) {
        final updatedParentNode = parentNode.copyWith(
          containerInstances: [...parentNode.containerInstances, element],
        );

        // Update the parent node in the model
        _updateDeploymentNodeInModel(updatedParentNode);

        // Update container instance cache
        _containerInstancesById[element.id] = element;

        // Update in reference resolver
        referenceResolver.registerElement(updatedParentNode);
      } else {
        errorReporter.reportStandardError(
          'Parent deployment node not found for container instance: ${element.id}',
          0, // Offset not available here
        );
      }
    }

    // Update the workspace with the new model
    if (workspace != null) {
      workspace = workspace!.updateModel(_currentModel);
    }
  }

  /// Helper method to convert an element style node to an ElementStyle.
  ElementStyle? _elementStyleFromNode(ElementStyleNode node) {
    // Create shape from string
    Shape shape = Shape.box;
    if (node.shape != null) {
      try {
        shape = Shape.values.firstWhere(
          (s) =>
              s.toString().split('.').last.toLowerCase() ==
              node.shape!.toLowerCase(),
          orElse: () => Shape.box,
        );
      } catch (e) {
        errorReporter.reportStandardError(
          'Unknown shape: ${node.shape}',
          node.sourcePosition?.offset ?? 0,
        );
      }
    }

    // Create border from string
    Border border = Border.solid;
    if (node.border != null) {
      try {
        border = Border.values.firstWhere(
          (b) =>
              b.toString().split('.').last.toLowerCase() ==
              node.border!.toLowerCase(),
          orElse: () => Border.solid,
        );
      } catch (e) {
        errorReporter.reportStandardError(
          'Unknown border style: ${node.border}',
          node.sourcePosition?.offset ?? 0,
        );
      }
    }

    // Convert string colors to Color objects
    Color? backgroundColor;
    Color? strokeColor;
    Color? textColor;

    if (node.background != null) {
      backgroundColor = _colorFromHex(node.background!);
    }

    if (node.stroke != null) {
      strokeColor = _colorFromHex(node.stroke!);
    }

    if (node.color != null) {
      textColor = _colorFromHex(node.color!);
    }

    // Create the element style
    final elementStyle = ElementStyle(
      tag: node.tag,
      shape: shape,
      icon: node.icon,
      width: _parseStringToInt(node.width),
      height: _parseStringToInt(node.height),
      background: _colorToHex(backgroundColor),
      stroke: _colorToHex(strokeColor),
      color: _colorToHex(textColor),
      fontSize: node.fontSize,
      border: border,
      opacity: node.opacity != null ? (node.opacity! * 100).toInt() : 100,
    );

    return elementStyle;
  }

  /// Helper method to convert a relationship style node to a RelationshipStyle.
  RelationshipStyle? _relationshipStyleFromNode(RelationshipStyleNode node) {
    // Create line style from string
    LineStyle lineStyle = LineStyle.solid;
    if (node.style != null) {
      try {
        lineStyle = LineStyle.values.firstWhere(
          (s) =>
              s.toString().split('.').last.toLowerCase() ==
              node.style!.toLowerCase(),
          orElse: () => LineStyle.solid,
        );
      } catch (e) {
        errorReporter.reportStandardError(
          'Unknown line style: ${node.style}',
          node.sourcePosition?.offset ?? 0,
        );
      }
    }

    // Create routing from string
    StyleRouting routing = StyleRouting.direct;
    if (node.routing != null) {
      try {
        routing = StyleRouting.values.firstWhere(
          (r) =>
              r.toString().split('.').last.toLowerCase() ==
              node.routing!.toLowerCase(),
          orElse: () => StyleRouting.direct,
        );
      } catch (e) {
        errorReporter.reportStandardError(
          'Unknown routing: ${node.routing}',
          node.sourcePosition?.offset ?? 0,
        );
      }
    }

    // Convert string color to Color object
    Color? lineColor;
    if (node.color != null) {
      lineColor = _colorFromHex(node.color!);
    }

    // Create the relationship style
    final relationshipStyle = RelationshipStyle(
      tag: node.tag,
      thickness: node.thickness ?? 2,
      color: _colorToHex(lineColor),
      style: lineStyle,
      routing: routing,
      fontSize: node.fontSize,
      opacity: node.opacity != null ? (node.opacity! * 100).toInt() : 100,
    );

    return relationshipStyle;
  }

  // Utility method stub for _colorFromHex
  Color _colorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  // Utility method for Color to hex conversion
  String? _colorToHex(Color? color) {
    if (color == null) return null;
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  // Utility method for String to int conversion
  int? _parseStringToInt(String? value) {
    if (value == null) return null;
    return int.tryParse(value);
  }
}
