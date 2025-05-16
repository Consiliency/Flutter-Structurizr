import '../error_reporter.dart';
import '../lexer/token.dart';
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
  
  // Documentation nodes
  void visitDocumentationNode(DocumentationNode node);
  void visitDocumentationSectionNode(DocumentationSectionNode node);
  void visitDiagramReferenceNode(DiagramReferenceNode node);
  void visitDecisionNode(DecisionNode node);
  
  // Miscellaneous nodes
  void visitDirectiveNode(DirectiveNode node);
}

/// A node representing a workspace.
class WorkspaceNode extends AstNode {
  /// The name of the workspace.
  final String name;
  
  /// The description of the workspace.
  final String? description;
  
  /// The model section of the workspace.
  final ModelNode? model;
  
  /// The views section of the workspace.
  final ViewsNode? views;
  
  /// The styles section of the workspace.
  final StylesNode? styles;
  
  /// The themes of the workspace.
  final List<ThemeNode> themes;
  
  /// The branding of the workspace.
  final BrandingNode? branding;
  
  /// The terminology of the workspace.
  final TerminologyNode? terminology;
  
  /// The properties of the workspace.
  final PropertiesNode? properties;
  
  /// The configuration of the workspace.
  final Map<String, String> configuration;
  
  /// The documentation of the workspace.
  final DocumentationNode? documentation;
  
  /// The architecture decision records.
  final List<DecisionNode>? decisions;
  
  /// The directives used in this workspace (e.g., !include).
  final List<DirectiveNode>? directives;
  
  /// Creates a new workspace node.
  WorkspaceNode({
    required this.name,
    this.description,
    this.model,
    this.views,
    this.styles,
    this.themes = const [],
    this.branding,
    this.terminology,
    this.properties,
    this.configuration = const {},
    this.documentation,
    this.decisions,
    this.directives,
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitWorkspaceNode(this);
  }
}

/// Base class for all model element nodes.
abstract class ModelElementNode extends AstNode {
  /// The identifier of this element.
  final String id;
  
  /// The name of this element.
  final String name;
  
  /// The description of this element.
  final String? description;
  
  /// The variable name of this element, if it was assigned to a variable.
  /// This is used for variable aliases in the DSL.
  final String? variableName;
  
  /// The tags associated with this element.
  final TagsNode? tags;
  
  /// The properties associated with this element.
  final PropertiesNode? properties;
  
  /// The relationships originating from this element.
  final List<RelationshipNode> relationships;
  
  /// Creates a new model element node.
  ModelElementNode({
    required this.id,
    required this.name,
    this.description,
    this.variableName,
    this.tags,
    this.properties,
    this.relationships = const [],
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);
  
  /// The fully qualified ID of this element, including any parent IDs.
  String get fullId => id;

  /// Sets the identifier for this element and returns a new instance.
  ModelElementNode setIdentifier(String id) {
    // Not implemented, but could return a copy with new id
    return this;
  }

  /// Sets a property for this element and returns a new instance.
  ModelElementNode setProperty(String key, dynamic value) {
    // Not implemented, but could add to properties
    return this;
  }

  /// Adds a child element and returns a new instance.
  ModelElementNode addChild(ModelElementNode child) {
    // Not implemented, but could add to a children field
    return this;
  }
}

/// Node representing the model section of a workspace.
class ModelNode extends AstNode {
  /// The enterprise name.
  final String? enterpriseName;
  
  /// The people in the model.
  final List<PersonNode> people;
  
  /// The software systems in the model.
  final List<SoftwareSystemNode> softwareSystems;
  
  /// The deployment environments in the model.
  final List<DeploymentEnvironmentNode> deploymentEnvironments;
  
  /// The relationships in the model that aren't owned by a specific element.
  final List<RelationshipNode> relationships;
  
  /// Creates a new model node.
  ModelNode({
    this.enterpriseName,
    this.people = const [],
    this.softwareSystems = const [],
    this.deploymentEnvironments = const [],
    this.relationships = const [],
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitModelNode(this);
  }
  
  /// Returns all elements in this model.
  List<ModelElementNode> get allElements {
    final result = <ModelElementNode>[];
    
    // Add people
    result.addAll(people);
    
    // Add software systems and their containers
    for (final system in softwareSystems) {
      result.add(system);
      
      for (final container in system.containers) {
        result.add(container);
        
        // Add components
        result.addAll(container.components);
      }
    }
    
    // Add deployment environments and their nodes
    for (final env in deploymentEnvironments) {
      result.add(env);
      
      // Add deployment nodes recursively
      result.addAll(_collectDeploymentNodes(env.deploymentNodes));
    }
    
    return result;
  }
  
  /// Recursively collects all deployment nodes.
  List<ModelElementNode> _collectDeploymentNodes(List<DeploymentNodeNode> nodes) {
    final result = <ModelElementNode>[];
    
    for (final node in nodes) {
      result.add(node);
      
      // Add child nodes recursively
      result.addAll(_collectDeploymentNodes(node.children));
      
      // Add infrastructure nodes (they are ModelElementNodes)
      result.addAll(node.infrastructureNodes);
      
      // Add container instances (they are ModelElementNodes)
      result.addAll(node.containerInstances);
    }
    
    return result;
  }

  /// Adds a group to the model and returns a new ModelNode.
  ModelNode addGroup(GroupNode group) {
    // For demonstration, just add to a new field or to people as placeholder
    // In a real implementation, you would have a groups field
    return this;
  }

  /// Adds an enterprise to the model and returns a new ModelNode.
  ModelNode addEnterprise(EnterpriseNode enterprise) {
    // For demonstration, just set enterpriseName
    return ModelNode(
      enterpriseName: enterprise.name,
      people: people,
      softwareSystems: softwareSystems,
      deploymentEnvironments: deploymentEnvironments,
      relationships: relationships,
      sourcePosition: sourcePosition,
    );
  }

  /// Adds an element to the model and returns a new ModelNode.
  ModelNode addElement(ModelElementNode element) {
    // For demonstration, add to people if PersonNode, else to softwareSystems
    if (element is PersonNode) {
      return ModelNode(
        enterpriseName: enterpriseName,
        people: [...people, element],
        softwareSystems: softwareSystems,
        deploymentEnvironments: deploymentEnvironments,
        relationships: relationships,
        sourcePosition: sourcePosition,
      );
    } else if (element is SoftwareSystemNode) {
      return ModelNode(
        enterpriseName: enterpriseName,
        people: people,
        softwareSystems: [...softwareSystems, element],
        deploymentEnvironments: deploymentEnvironments,
        relationships: relationships,
        sourcePosition: sourcePosition,
      );
    }
    // Extend for other element types as needed
    return this;
  }

  /// Adds an implied relationship to the model and returns a new ModelNode.
  ModelNode addImpliedRelationship(RelationshipNode rel) {
    return ModelNode(
      enterpriseName: enterpriseName,
      people: people,
      softwareSystems: softwareSystems,
      deploymentEnvironments: deploymentEnvironments,
      relationships: [...relationships, rel],
      sourcePosition: sourcePosition,
    );
  }

  /// Sets an advanced property (placeholder).
  ModelNode setAdvancedProperty(String key, dynamic value) {
    // Not implemented in AST, but could be added to a properties map
    return this;
  }
}

/// Node representing a person in the model.
class PersonNode extends ModelElementNode {
  /// The location of this person (Internal, External).
  final String? location;
  
  /// Creates a new person node.
  PersonNode({
    required String id,
    required String name,
    String? description,
    String? variableName,
    this.location,
    TagsNode? tags,
    PropertiesNode? properties,
    List<RelationshipNode> relationships = const [],
    SourcePosition? sourcePosition,
  }) : super(
    id: id,
    name: name,
    description: description,
    variableName: variableName,
    tags: tags,
    properties: properties,
    relationships: relationships,
    sourcePosition: sourcePosition,
  );
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitPersonNode(this);
  }
}

/// Node representing a software system in the model.
class SoftwareSystemNode extends ModelElementNode {
  /// The location of this software system (Internal, External).
  final String? location;
  
  /// The containers in this software system.
  final List<ContainerNode> containers;
  
  /// The deployment environments for this software system.
  final List<DeploymentEnvironmentNode> deploymentEnvironments;
  
  /// Creates a new software system node.
  SoftwareSystemNode({
    required String id,
    required String name,
    String? description,
    String? variableName,
    this.location,
    TagsNode? tags,
    PropertiesNode? properties,
    this.containers = const [],
    this.deploymentEnvironments = const [],
    List<RelationshipNode> relationships = const [],
    SourcePosition? sourcePosition,
  }) : super(
    id: id,
    name: name,
    description: description,
    variableName: variableName,
    tags: tags,
    properties: properties,
    relationships: relationships,
    sourcePosition: sourcePosition,
  );
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitSoftwareSystemNode(this);
  }
}

/// Node representing a container in a software system.
class ContainerNode extends ModelElementNode {
  /// The parent software system ID.
  final String parentId;
  
  /// The technology used by this container.
  final String? technology;
  
  /// The components in this container.
  final List<ComponentNode> components;
  
  /// Creates a new container node.
  ContainerNode({
    required String id,
    required this.parentId,
    required String name,
    String? description,
    String? variableName,
    this.technology,
    TagsNode? tags,
    PropertiesNode? properties,
    this.components = const [],
    List<RelationshipNode> relationships = const [],
    SourcePosition? sourcePosition,
  }) : super(
    id: id,
    name: name,
    description: description,
    variableName: variableName,
    tags: tags,
    properties: properties,
    relationships: relationships,
    sourcePosition: sourcePosition,
  );
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitContainerNode(this);
  }
  
  @override
  String get fullId => '$parentId.$id';
}

/// Node representing a component in a container.
class ComponentNode extends ModelElementNode {
  /// The parent container ID.
  final String parentId;
  
  /// The technology used by this component.
  final String? technology;
  
  /// Creates a new component node.
  ComponentNode({
    required String id,
    required this.parentId,
    required String name,
    String? description,
    String? variableName,
    this.technology,
    TagsNode? tags,
    PropertiesNode? properties,
    List<RelationshipNode> relationships = const [],
    SourcePosition? sourcePosition,
  }) : super(
    id: id,
    name: name,
    description: description,
    variableName: variableName,
    tags: tags,
    properties: properties,
    relationships: relationships,
    sourcePosition: sourcePosition,
  );
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitComponentNode(this);
  }
  
  @override
  String get fullId => '$parentId.$id';
}

/// Node representing a deployment environment.
class DeploymentEnvironmentNode extends ModelElementNode {
  /// The parent software system ID.
  final String parentId;
  
  /// The deployment nodes in this environment.
  final List<DeploymentNodeNode> deploymentNodes;
  
  /// Creates a new deployment environment node.
  DeploymentEnvironmentNode({
    required String id,
    required this.parentId,
    required String name,
    String? description,
    String? variableName,
    TagsNode? tags,
    PropertiesNode? properties,
    this.deploymentNodes = const [],
    List<RelationshipNode> relationships = const [],
    SourcePosition? sourcePosition,
  }) : super(
    id: id,
    name: name,
    description: description,
    variableName: variableName,
    tags: tags,
    properties: properties,
    relationships: relationships,
    sourcePosition: sourcePosition,
  );
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitDeploymentEnvironmentNode(this);
  }
  
  @override
  String get fullId => '$parentId.$id';
}

/// Node representing a deployment node.
class DeploymentNodeNode extends ModelElementNode {
  /// The parent node ID.
  final String parentId;
  
  /// The technology of this deployment node.
  final String? technology;
  
  /// The child deployment nodes.
  final List<DeploymentNodeNode> children;
  
  /// The infrastructure nodes in this deployment node.
  final List<InfrastructureNodeNode> infrastructureNodes;
  
  /// The container instances in this deployment node.
  final List<ContainerInstanceNode> containerInstances;
  
  /// Creates a new deployment node node.
  DeploymentNodeNode({
    required String id,
    required this.parentId,
    required String name,
    String? description,
    String? variableName,
    this.technology,
    TagsNode? tags,
    PropertiesNode? properties,
    this.children = const [],
    this.infrastructureNodes = const [],
    this.containerInstances = const [],
    List<RelationshipNode> relationships = const [],
    SourcePosition? sourcePosition,
  }) : super(
    id: id,
    name: name,
    description: description,
    variableName: variableName,
    tags: tags,
    properties: properties,
    relationships: relationships,
    sourcePosition: sourcePosition,
  );
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitDeploymentNodeNode(this);
  }
  
  @override
  String get fullId => '$parentId.$id';
}

/// Node representing an infrastructure node.
class InfrastructureNodeNode extends ModelElementNode {
  /// The parent deployment node ID.
  final String parentId;
  
  /// The technology of this infrastructure node.
  final String? technology;
  
  /// Creates a new infrastructure node node.
  InfrastructureNodeNode({
    required String id,
    required this.parentId,
    required String name,
    String? description,
    String? variableName,
    this.technology,
    TagsNode? tags,
    PropertiesNode? properties,
    List<RelationshipNode> relationships = const [],
    SourcePosition? sourcePosition,
  }) : super(
    id: id,
    name: name,
    description: description,
    variableName: variableName,
    tags: tags,
    properties: properties,
    relationships: relationships,
    sourcePosition: sourcePosition,
  );
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitInfrastructureNodeNode(this);
  }
  
  @override
  String get fullId => '$parentId.$id';
}

/// Node representing a container instance.
class ContainerInstanceNode extends ModelElementNode {
  /// The parent deployment node ID.
  final String parentId;
  
  /// The referenced container ID.
  final String containerId;
  
  /// The number of instances.
  final int instanceCount;
  
  /// Creates a new container instance node.
  ContainerInstanceNode({
    required String id,
    required this.parentId,
    required this.containerId,
    required String name,
    String? description,
    String? variableName,
    this.instanceCount = 1,
    TagsNode? tags,
    PropertiesNode? properties,
    List<RelationshipNode> relationships = const [],
    SourcePosition? sourcePosition,
  }) : super(
    id: id,
    name: name,
    description: description,
    variableName: variableName,
    tags: tags,
    properties: properties,
    relationships: relationships,
    sourcePosition: sourcePosition,
  );
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitContainerInstanceNode(this);
  }
  
  @override
  String get fullId => '$parentId.$id';
}

/// Node representing a group of elements.
class GroupNode extends AstNode {
  /// The name of the group.
  final String name;

  /// The elements in this group.
  final List<ModelElementNode> elements;

  /// The tags associated with this group.
  final TagsNode? tags;

  /// The properties associated with this group.
  final PropertiesNode? properties;

  /// The children of this group.
  final List<ModelElementNode> children;

  /// The relationships in this group.
  final List<RelationshipNode> relationships;

  /// Creates a new group node.
  GroupNode({
    required this.name,
    this.elements = const [],
    this.tags,
    this.properties,
    this.children = const [],
    this.relationships = const [],
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);

  @override
  void accept(AstVisitor visitor) {
    visitor.visitGroupNode(this);
  }

  /// Adds an element to the group and returns a new GroupNode.
  GroupNode addElement(ModelElementNode element) {
    return GroupNode(
      name: name,
      elements: [...elements, element],
      tags: tags,
      properties: properties,
      children: children,
      relationships: relationships,
      sourcePosition: sourcePosition,
    );
  }
}

/// Node representing a relationship between two elements.
class RelationshipNode extends AstNode {
  /// The source element ID.
  final String sourceId;
  
  /// The destination element ID.
  final String destinationId;
  
  /// The description of this relationship.
  final String? description;
  
  /// The technology of this relationship.
  final String? technology;
  
  /// The tags associated with this relationship.
  final TagsNode? tags;
  
  /// The properties associated with this relationship.
  final PropertiesNode? properties;
  
  /// Creates a new relationship node.
  RelationshipNode({
    required this.sourceId,
    required this.destinationId,
    this.description,
    this.technology,
    this.tags,
    this.properties,
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitRelationshipNode(this);
  }
}

/// Node representing tags.
class TagsNode extends AstNode {
  /// The tags as a comma-separated string.
  final String tags;
  
  /// Creates a new tags node.
  TagsNode({
    required this.tags,
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitTagsNode(this);
  }
}

/// Node representing properties.
class PropertiesNode extends AstNode {
  /// The properties.
  final List<PropertyNode> properties;
  
  /// Creates a new properties node.
  PropertiesNode({
    required this.properties,
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitPropertiesNode(this);
  }
}

/// Node representing a property.
class PropertyNode extends AstNode {
  /// The name of the property.
  final String name;
  
  /// The value of the property.
  final String? value;
  
  /// Creates a new property node.
  PropertyNode({
    required this.name,
    this.value,
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);
  
  /// The key representation of this property.
  String get key => name;
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitPropertyNode(this);
  }
}

/// Node representing the views section of a workspace.
class ViewsNode extends AstNode {
  /// The system landscape views.
  final List<SystemLandscapeViewNode> systemLandscapeViews;
  
  /// The system context views.
  final List<SystemContextViewNode> systemContextViews;
  
  /// The container views.
  final List<ContainerViewNode> containerViews;
  
  /// The component views.
  final List<ComponentViewNode> componentViews;
  
  /// The dynamic views.
  final List<DynamicViewNode> dynamicViews;
  
  /// The deployment views.
  final List<DeploymentViewNode> deploymentViews;
  
  /// The filtered views.
  final List<FilteredViewNode> filteredViews;
  
  /// The custom views.
  final List<CustomViewNode> customViews;
  
  /// The image views.
  final List<ImageViewNode> imageViews;
  
  /// The configuration of the views.
  final Map<String, String> configuration;
  
  /// Creates a new views node.
  ViewsNode({
    this.systemLandscapeViews = const [],
    this.systemContextViews = const [],
    this.containerViews = const [],
    this.componentViews = const [],
    this.dynamicViews = const [],
    this.deploymentViews = const [],
    this.filteredViews = const [],
    this.customViews = const [],
    this.imageViews = const [],
    this.configuration = const {},
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitViewsNode(this);
  }
}

/// Base class for all view nodes.
abstract class ViewNode extends AstNode {
  /// The key of this view.
  final String key;
  
  /// The title of this view.
  final String? title;
  
  /// The description of this view.
  final String? description;
  
  /// The includes for this view.
  final List<IncludeNode> includes;
  
  /// The excludes for this view.
  final List<ExcludeNode> excludes;
  
  /// The auto layout settings for this view.
  final AutoLayoutNode? autoLayout;
  
  /// The animation steps for this view.
  final List<AnimationNode> animations;
  
  /// Creates a new view node.
  ViewNode({
    required this.key,
    this.title,
    this.description,
    this.includes = const [],
    this.excludes = const [],
    this.autoLayout,
    this.animations = const [],
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);
}

/// Node representing a system landscape view.
class SystemLandscapeViewNode extends ViewNode {
  /// Creates a new system landscape view node.
  SystemLandscapeViewNode({
    required String key,
    String? title,
    String? description,
    List<IncludeNode> includes = const [],
    List<ExcludeNode> excludes = const [],
    AutoLayoutNode? autoLayout,
    List<AnimationNode> animations = const [],
    SourcePosition? sourcePosition,
  }) : super(
    key: key,
    title: title,
    description: description,
    includes: includes,
    excludes: excludes,
    autoLayout: autoLayout,
    animations: animations,
    sourcePosition: sourcePosition,
  );
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitSystemLandscapeViewNode(this);
  }
}

/// Node representing a system context view.
class SystemContextViewNode extends ViewNode {
  /// The ID of the software system.
  final String systemId;
  
  /// Creates a new system context view node.
  SystemContextViewNode({
    required String key,
    required this.systemId,
    String? title,
    String? description,
    List<IncludeNode> includes = const [],
    List<ExcludeNode> excludes = const [],
    AutoLayoutNode? autoLayout,
    List<AnimationNode> animations = const [],
    SourcePosition? sourcePosition,
  }) : super(
    key: key,
    title: title,
    description: description,
    includes: includes,
    excludes: excludes,
    autoLayout: autoLayout,
    animations: animations,
    sourcePosition: sourcePosition,
  );
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitSystemContextViewNode(this);
  }
}

/// Node representing a container view.
class ContainerViewNode extends ViewNode {
  /// The ID of the software system.
  final String systemId;
  
  /// Creates a new container view node.
  ContainerViewNode({
    required String key,
    required this.systemId,
    String? title,
    String? description,
    List<IncludeNode> includes = const [],
    List<ExcludeNode> excludes = const [],
    AutoLayoutNode? autoLayout,
    List<AnimationNode> animations = const [],
    SourcePosition? sourcePosition,
  }) : super(
    key: key,
    title: title,
    description: description,
    includes: includes,
    excludes: excludes,
    autoLayout: autoLayout,
    animations: animations,
    sourcePosition: sourcePosition,
  );
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitContainerViewNode(this);
  }
}

/// Node representing a component view.
class ComponentViewNode extends ViewNode {
  /// The ID of the container.
  final String containerId;
  
  /// Creates a new component view node.
  ComponentViewNode({
    required String key,
    required this.containerId,
    String? title,
    String? description,
    List<IncludeNode> includes = const [],
    List<ExcludeNode> excludes = const [],
    AutoLayoutNode? autoLayout,
    List<AnimationNode> animations = const [],
    SourcePosition? sourcePosition,
  }) : super(
    key: key,
    title: title,
    description: description,
    includes: includes,
    excludes: excludes,
    autoLayout: autoLayout,
    animations: animations,
    sourcePosition: sourcePosition,
  );
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitComponentViewNode(this);
  }
}

/// Node representing a dynamic view.
class DynamicViewNode extends ViewNode {
  /// The scope of the dynamic view (optional).
  final String? scope;
  
  /// Creates a new dynamic view node.
  DynamicViewNode({
    required String key,
    this.scope,
    String? title,
    String? description,
    List<IncludeNode> includes = const [],
    List<ExcludeNode> excludes = const [],
    AutoLayoutNode? autoLayout,
    List<AnimationNode> animations = const [],
    SourcePosition? sourcePosition,
  }) : super(
    key: key,
    title: title,
    description: description,
    includes: includes,
    excludes: excludes,
    autoLayout: autoLayout,
    animations: animations,
    sourcePosition: sourcePosition,
  );
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitDynamicViewNode(this);
  }
}

/// Node representing a deployment view.
class DeploymentViewNode extends ViewNode {
  /// The ID of the software system.
  final String systemId;
  
  /// The environment (e.g., "Production").
  final String environment;
  
  /// Creates a new deployment view node.
  DeploymentViewNode({
    required String key,
    required this.systemId,
    required this.environment,
    String? title,
    String? description,
    List<IncludeNode> includes = const [],
    List<ExcludeNode> excludes = const [],
    AutoLayoutNode? autoLayout,
    List<AnimationNode> animations = const [],
    SourcePosition? sourcePosition,
  }) : super(
    key: key,
    title: title,
    description: description,
    includes: includes,
    excludes: excludes,
    autoLayout: autoLayout,
    animations: animations,
    sourcePosition: sourcePosition,
  );
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitDeploymentViewNode(this);
  }
}

/// Node representing a filtered view.
class FilteredViewNode extends ViewNode {
  /// The key of the base view.
  final String baseViewKey;
  
  /// Creates a new filtered view node.
  FilteredViewNode({
    required String key,
    required this.baseViewKey,
    String? title,
    String? description,
    List<IncludeNode> includes = const [],
    List<ExcludeNode> excludes = const [],
    SourcePosition? sourcePosition,
  }) : super(
    key: key,
    title: title,
    description: description,
    includes: includes,
    excludes: excludes,
    sourcePosition: sourcePosition,
  );
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitFilteredViewNode(this);
  }
}

/// Node representing a custom view.
class CustomViewNode extends ViewNode {
  /// Creates a new custom view node.
  CustomViewNode({
    required String key,
    String? title,
    String? description,
    List<IncludeNode> includes = const [],
    List<ExcludeNode> excludes = const [],
    AutoLayoutNode? autoLayout,
    List<AnimationNode> animations = const [],
    SourcePosition? sourcePosition,
  }) : super(
    key: key,
    title: title,
    description: description,
    includes: includes,
    excludes: excludes,
    autoLayout: autoLayout,
    animations: animations,
    sourcePosition: sourcePosition,
  );
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitCustomViewNode(this);
  }
}

/// Node representing an image view.
class ImageViewNode extends ViewNode {
  /// The type of the image.
  final String imageType;
  
  /// The content of the image.
  final String content;
  
  /// Creates a new image view node.
  ImageViewNode({
    required String key,
    required this.imageType,
    required this.content,
    String? title,
    String? description,
    SourcePosition? sourcePosition,
  }) : super(
    key: key,
    title: title,
    description: description,
    sourcePosition: sourcePosition,
  );
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitImageViewNode(this);
  }
}

// IncludeNode is now defined in nodes/include_node.dart

/// Node representing an exclude statement.
class ExcludeNode extends AstNode {
  /// The expression to exclude.
  final String expression;
  
  /// Creates a new exclude node.
  ExcludeNode({
    required this.expression,
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitExcludeNode(this);
  }
}

/// Node representing an auto layout.
class AutoLayoutNode extends AstNode {
  /// The rank direction.
  final String? rankDirection;
  
  /// The rank separation.
  final int? rankSeparation;
  
  /// The node separation.
  final int? nodeSeparation;
  
  /// Creates a new auto layout node.
  AutoLayoutNode({
    this.rankDirection,
    this.rankSeparation,
    this.nodeSeparation,
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitAutoLayoutNode(this);
  }
}

/// Node representing an animation step.
class AnimationNode extends AstNode {
  /// The order of this animation step.
  final int order;
  
  /// The elements to show in this animation step.
  final List<String> elements;
  
  /// The relationships to show in this animation step.
  final List<String> relationships;
  
  /// Creates a new animation node.
  AnimationNode({
    required this.order,
    this.elements = const [],
    this.relationships = const [],
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitAnimationNode(this);
  }
}

/// Node representing styles.
class StylesNode extends AstNode {
  /// The element styles.
  final List<ElementStyleNode> elementStyles;
  
  /// The relationship styles.
  final List<RelationshipStyleNode> relationshipStyles;
  
  /// Creates a new styles node.
  StylesNode({
    this.elementStyles = const [],
    this.relationshipStyles = const [],
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitStylesNode(this);
  }
}

/// Node representing an element style.
class ElementStyleNode extends AstNode {
  /// The tag to apply this style to.
  final String tag;
  
  /// The shape.
  final String? shape;
  
  /// The icon URL.
  final String? icon;
  
  /// The width.
  final int? width;
  
  /// The height.
  final int? height;
  
  /// The background color.
  final String? background;
  
  /// The stroke color.
  final String? stroke;
  
  /// The text color.
  final String? color;
  
  /// The font size.
  final int? fontSize;
  
  /// The border style.
  final String? border;
  
  /// The opacity.
  final double? opacity;
  
  /// Additional metadata.
  final Map<String, String> metadata;
  
  /// Creates a new element style node.
  ElementStyleNode({
    required this.tag,
    this.shape,
    this.icon,
    this.width,
    this.height,
    this.background,
    this.stroke,
    this.color,
    this.fontSize,
    this.border,
    this.opacity,
    this.metadata = const {},
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitElementStyleNode(this);
  }
}

/// Node representing a relationship style.
class RelationshipStyleNode extends AstNode {
  /// The tag to apply this style to.
  final String tag;
  
  /// The thickness.
  final int? thickness;
  
  /// The color.
  final String? color;
  
  /// The style.
  final String? style;
  
  /// The routing.
  final String? routing;
  
  /// The font size.
  final int? fontSize;
  
  /// The width.
  final int? width;
  
  /// The position.
  final String? position;
  
  /// The opacity.
  final double? opacity;
  
  /// Additional metadata.
  final Map<String, String> metadata;
  
  /// Creates a new relationship style node.
  RelationshipStyleNode({
    required this.tag,
    this.thickness,
    this.color,
    this.style,
    this.routing,
    this.fontSize,
    this.width,
    this.position,
    this.opacity,
    this.metadata = const {},
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitRelationshipStyleNode(this);
  }
}

/// Node representing a theme.
class ThemeNode extends AstNode {
  /// The URL of the theme.
  final String url;
  
  /// Creates a new theme node.
  ThemeNode({
    required this.url,
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitThemeNode(this);
  }
}

/// Node representing branding.
class BrandingNode extends AstNode {
  /// The logo URL.
  final String? logo;
  
  /// The width of the logo.
  final int? width;
  
  /// The height of the logo.
  final int? height;
  
  /// The font.
  final String? font;
  
  /// Creates a new branding node.
  BrandingNode({
    this.logo,
    this.width,
    this.height,
    this.font,
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitBrandingNode(this);
  }
}

/// Node representing terminology.
class TerminologyNode extends AstNode {
  /// The enterprise term.
  final String? enterprise;
  
  /// The person term.
  final String? person;
  
  /// The software system term.
  final String? softwareSystem;
  
  /// The container term.
  final String? container;
  
  /// The component term.
  final String? component;
  
  /// The code term.
  final String? code;
  
  /// The deployment node term.
  final String? deploymentNode;
  
  /// The relationship term.
  final String? relationship;
  
  /// Creates a new terminology node.
  TerminologyNode({
    this.enterprise,
    this.person,
    this.softwareSystem,
    this.container,
    this.component,
    this.code,
    this.deploymentNode,
    this.relationship,
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitTerminologyNode(this);
  }
}

/// A node representing a DSL directive like !include.
class DirectiveNode extends AstNode {
  /// The type of directive (e.g., "include")
  final String type;
  
  /// The value of the directive
  final String value;
  
  /// Creates a new directive node.
  DirectiveNode({
    required this.type,
    required this.value,
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitDirectiveNode(this);
  }
}

class EnterpriseNode extends AstNode {
  /// The name of the enterprise.
  final String name;

  /// The groups in this enterprise.
  final List<GroupNode> groups;

  /// The tags associated with this enterprise.
  final TagsNode? tags;

  /// The properties associated with this enterprise.
  final PropertiesNode? properties;

  /// Creates a new enterprise node.
  EnterpriseNode({
    required this.name,
    this.groups = const [],
    this.tags,
    this.properties,
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);

  @override
  void accept(AstVisitor visitor) {
    visitor.visitEnterpriseNode(this);
  }

  /// Adds a group to this enterprise.
  void addGroup(GroupNode groupNode) {
    groups.add(groupNode);
  }

  /// Sets a property on this enterprise.
  void setProperty(String key, dynamic value) {
    // Since properties are immutable, this would require creating a new EnterpriseNode
    throw UnimplementedError(
      'EnterpriseNode.setProperty is not supported in the immutable AST. '
      'Create a new EnterpriseNode with the properties set directly.',
    );
  }
}