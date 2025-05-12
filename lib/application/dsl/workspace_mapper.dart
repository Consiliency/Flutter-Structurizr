import 'dart:ui';
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/model/deployment_environment.dart';
import 'package:flutter_structurizr/domain/model/group.dart';
import 'package:flutter_structurizr/domain/parser/ast/ast_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/model_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/property_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/relationship_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/view_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/workspace_node.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/style/branding.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/domain/view/views.dart';
import 'package:uuid/uuid.dart';

/// Mapper for converting AST nodes to domain model objects.
/// 
/// This class implements the visitor pattern to traverse the AST
/// and build the corresponding domain model objects.
class WorkspaceMapper implements AstVisitor {
  /// The error reporter for reporting semantic errors.
  final ErrorReporter _errorReporter;
  
  /// The source code being processed.
  final String _source;
  
  /// The resulting workspace after mapping.
  Workspace? _workspace;
  
  /// The current model being built.
  Model _currentModel = const Model();
  
  /// The current views collection being built.
  Views _currentViews = const Views();
  
  /// Maps element identifiers to their actual model objects
  final Map<String, Element> _elementsById = {};
  
  /// Queue of relationships to be resolved in the second phase
  final List<RelationshipNode> _pendingRelationships = [];
  
  /// Maps parent identifier references to their child elements for hierarchy building
  final Map<String, List<Element>> _elementsByParent = {};
  
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

  /// Maps element name to element ID for lookups when relationships use names
  final Map<String, String> _elementNameToId = {};
  
  /// Current parent element ID (for nested elements)
  String? _currentParentId;

  /// The current context element ID (for "this" references)
  String? _currentContextId;
  
  /// Creates a new workspace mapper.
  WorkspaceMapper(this._source, this._errorReporter);
  
  /// Maps an AST to a domain model workspace.
  /// 
  /// This is the main entry point for the mapping process.
  Workspace? mapWorkspace(WorkspaceNode workspaceNode) {
    try {
      // First phase: process the AST and build model elements
      workspaceNode.accept(this);
      
      // Second phase: resolve relationships
      _resolveRelationships();
      
      // Build the final workspace
      return _workspace;
    } catch (e, stackTrace) {
      // Log any errors during mapping
      _errorReporter.reportStandardError(
        'Error mapping workspace: ${e.toString()}\n$stackTrace',
        workspaceNode.sourcePosition?.offset ?? 0,
      );
      return null;
    }
  }
  
  /// Resolves relationships between elements.
  void _resolveRelationships() {
    for (final relationshipNode in _pendingRelationships) {
      _processRelationship(relationshipNode);
    }
  }
  
  /// Maps a string of tags from a TagsNode to a list of strings.
  List<String> _mapTags(TagsNode? tagsNode) {
    if (tagsNode == null) {
      return [];
    }
    
    final result = tagsNode.tags.split(',').map((tag) => tag.trim()).toList();
    return result;
  }
  
  /// Maps properties from a PropertiesNode to a map.
  Map<String, String> _mapProperties(PropertiesNode? propertiesNode) {
    if (propertiesNode == null) {
      return {};
    }

    final result = <String, String>{};
    for (final property in propertiesNode.properties) {
      if (property.key != null && property.value != null) {
        result[property.key!] = property.value!;
      }
    }
    return result;
  }
  
  /// Resolves a reference to an element, supporting special keywords like "this".
  Element? _resolveElementReference(String reference, {SourcePosition? sourcePosition, bool searchByName = false}) {
    // Handle "this" keyword which refers to the current context element
    if (reference == 'this' && _currentContextId != null) {
      return _elementsById[_currentContextId];
    }

    // Try direct lookup by ID
    if (_elementsById.containsKey(reference)) {
      return _elementsById[reference];
    }

    // Try lookup by name if searchByName is enabled
    if (searchByName && _elementNameToId.containsKey(reference)) {
      final id = _elementNameToId[reference];
      if (id != null && _elementsById.containsKey(id)) {
        return _elementsById[id];
      }
    }

    // Try finding element by simple name match (case sensitive)
    for (final element in _elementsById.values) {
      if (element.name == reference) {
        return element;
      }
    }

    // Try finding element by simple name match (case insensitive)
    final lowercaseReference = reference.toLowerCase();
    for (final element in _elementsById.values) {
      if (element.name.toLowerCase() == lowercaseReference) {
        return element;
      }
    }

    // Element not found
    if (sourcePosition != null) {
      _errorReporter.reportStandardError(
        'Element reference not found: $reference',
        sourcePosition.offset,
      );
    }
    
    return null;
  }
  
  /// Processes a relationship and adds it to the source element.
  void _processRelationship(RelationshipNode node) {
    String sourceId = node.sourceId;
    String destinationId = node.destinationId;
    
    // Resolve source and destination references
    final sourceElement = _resolveElementReference(
      sourceId, 
      sourcePosition: node.sourcePosition,
      searchByName: true,
    );
    
    final destinationElement = _resolveElementReference(
      destinationId, 
      sourcePosition: node.sourcePosition,
      searchByName: true,
    );
    
    if (sourceElement == null) {
      _errorReporter.reportStandardError(
        'Relationship source element not found: $sourceId',
        node.sourcePosition?.offset ?? 0,
      );
      return;
    }
    
    if (destinationElement == null) {
      _errorReporter.reportStandardError(
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
      tags: _mapTags(node.tags),
      properties: _mapProperties(node.properties),
    );
    
    // Update the element in our elements map
    _elementsById[sourceId] = newElement;
    
    // Update the model with the new element
    _updateModelWithElement(newElement);
  }
  
  /// Updates the model with a modified element.
  void _updateModelWithElement(Element element) {
    if (element is Person) {
      _currentModel = _currentModel.copyWith(
        people: _currentModel.people.map((p) => 
          p.id == element.id ? element as Person : p
        ).toList(),
      );
    } else if (element is SoftwareSystem) {
      _currentModel = _currentModel.copyWith(
        softwareSystems: _currentModel.softwareSystems.map((s) => 
          s.id == element.id ? element as SoftwareSystem : s
        ).toList(),
      );
      
      // Update the cache
      _softwareSystemsById[element.id] = element;
    } else if (element is Container) {
      // Find the parent software system
      final parentSystem = _softwareSystemsById[element.parentId];
      if (parentSystem != null) {
        // Update the container in the parent
        final updatedSystem = parentSystem.copyWith(
          containers: parentSystem.containers.map((c) => 
            c.id == element.id ? element as Container : c
          ).toList(),
        );
        
        // Update the software system in the model
        _currentModel = _currentModel.copyWith(
          softwareSystems: _currentModel.softwareSystems.map((s) => 
            s.id == updatedSystem.id ? updatedSystem : s
          ).toList(),
        );
        
        // Update caches
        _softwareSystemsById[updatedSystem.id] = updatedSystem;
        _containersById[element.id] = element;
      }
    } else if (element is Component) {
      // Find the parent container
      final parentContainer = _containersById[element.parentId];
      if (parentContainer != null) {
        // Update the component in the parent
        final updatedContainer = parentContainer.copyWith(
          components: parentContainer.components.map((c) => 
            c.id == element.id ? element as Component : c
          ).toList(),
        );
        
        // Update the container in the model by updating its parent system
        final parentSystem = _softwareSystemsById[updatedContainer.parentId];
        if (parentSystem != null) {
          final updatedSystem = parentSystem.copyWith(
            containers: parentSystem.containers.map((c) => 
              c.id == updatedContainer.id ? updatedContainer : c
            ).toList(),
          );
          
          // Update the software system in the model
          _currentModel = _currentModel.copyWith(
            softwareSystems: _currentModel.softwareSystems.map((s) => 
              s.id == updatedSystem.id ? updatedSystem : s
            ).toList(),
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
      final envIndex = _currentModel.deploymentEnvironments.indexWhere((e) => e.id == element.id);
      if (envIndex >= 0) {
        // In the main model
        _currentModel = _currentModel.copyWith(
          deploymentEnvironments: _currentModel.deploymentEnvironments
              .map((e) => e.id == element.id ? element as DeploymentEnvironment : e)
              .toList(),
        );
      } else {
        // Check in software systems
        for (final system in _currentModel.softwareSystems) {
          final systemEnvIndex = system.deploymentEnvironments.indexWhere((e) => e.id == element.id);
          if (systemEnvIndex >= 0) {
            final updatedSystem = system.copyWith(
              deploymentEnvironments: system.deploymentEnvironments
                  .map((e) => e.id == element.id ? element as DeploymentEnvironment : e)
                  .toList(),
            );
            
            // Update the system in the model
            _currentModel = _currentModel.copyWith(
              softwareSystems: _currentModel.softwareSystems
                  .map((s) => s.id == updatedSystem.id ? updatedSystem : s)
                  .toList(),
            );
            
            // Update cache
            _softwareSystemsById[updatedSystem.id] = updatedSystem;
            _environmentsById[element.id] = element as DeploymentEnvironment;
            break;
          }
        }
      }
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
      current = _elementsById[current.parentId!];
    }
    
    if (current is DeploymentEnvironment) {
      rootEnvironment = current;
      rootEnvId = rootEnvironment.id;
    } else {
      // Could not find the root environment
      _errorReporter.reportStandardError(
        'Could not find root environment for deployment node: ${node.name}',
        0,
      );
      return;
    }
    
    // Now we have the root environment, update the node
    
    // This recursive function updates a node in the deployment node tree
    DeploymentNode updateNodeInTree(DeploymentNode currentNode, String targetId, DeploymentNode updatedNode) {
      if (currentNode.id == targetId) {
        // This is the node we want to update
        return updatedNode;
      } else {
        // Check children recursively
        final updatedChildren = currentNode.children.map((child) =>
          updateNodeInTree(child, targetId, updatedNode)
        ).toList();
        
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
    final updatedEnvironment = rootEnvironment.copyWith(
      deploymentNodes: updatedNodes
    );
    
    // Update the environment in the model
    if (rootEnvId != null) {
      // Check if it's in the main model or in a software system
      final envIndex = _currentModel.deploymentEnvironments.indexWhere((e) => e.id == rootEnvId);
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
          final systemEnvIndex = system.deploymentEnvironments.indexWhere((e) => e.id == rootEnvId);
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
    }
    
    // Update the deployment node in the elements map
    _elementsById[node.id] = node;
    _deploymentNodesById[node.id] = node;
  }
  
  /// Updates an infrastructure node in the model, traversing the hierarchy as needed.
  void _updateInfrastructureNodeInModel(InfrastructureNode node) {
    // Find the parent deployment node
    final parentNode = _deploymentNodesById[node.parentId];
    if (parentNode == null) {
      _errorReporter.reportStandardError(
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
    
    // Update the infrastructure node in the elements map
    _elementsById[node.id] = node;
    _infrastructureNodesById[node.id] = node;
  }
  
  /// Updates a container instance in the model, traversing the hierarchy as needed.
  void _updateContainerInstanceInModel(ContainerInstance node) {
    // Find the parent deployment node
    final parentNode = _deploymentNodesById[node.parentId];
    if (parentNode == null) {
      _errorReporter.reportStandardError(
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
    
    // Update the container instance in the elements map
    _elementsById[node.id] = node;
    _containerInstancesById[node.id] = node;
  }
  
  /// Adds an element to the current model.
  void _addElementToModel(Element element) {
    // Store the element by ID for easy lookup later
    _elementsById[element.id] = element;
    
    // Store element name to ID mapping for lookup by name
    _elementNameToId[element.name] = element.id;
    
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
          softwareSystems: _currentModel.softwareSystems.map((s) => 
            s.id == updatedSystem.id ? updatedSystem : s
          ).toList(),
        );
        
        // Update caches
        _softwareSystemsById[updatedSystem.id] = updatedSystem;
        _containersById[element.id] = element;
      } else {
        _errorReporter.reportStandardError(
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
            containers: parentSystem.containers.map((c) => 
              c.id == updatedContainer.id ? updatedContainer : c
            ).toList(),
          );
          
          // Update the software system in the model
          _currentModel = _currentModel.copyWith(
            softwareSystems: _currentModel.softwareSystems.map((s) => 
              s.id == updatedSystem.id ? updatedSystem : s
            ).toList(),
          );
          
          // Update caches
          _softwareSystemsById[updatedSystem.id] = updatedSystem;
          _containersById[updatedContainer.id] = updatedContainer;
          _componentsById[element.id] = element;
        }
      } else {
        _errorReporter.reportStandardError(
          'Parent container not found for component: ${element.name}',
          0, // Offset not available here
        );
      }
    } else if (element is DeploymentEnvironment) {
      // Add the environment to the model
      if (element.parentId != null) {
        // Add to parent software system
        final parentSystem = _softwareSystemsById[element.parentId!];
        if (parentSystem != null) {
          final updatedSystem = parentSystem.copyWith(
            deploymentEnvironments: [...parentSystem.deploymentEnvironments, element],
          );
          
          // Update the model with the modified system
          _currentModel = _currentModel.copyWith(
            softwareSystems: _currentModel.softwareSystems.map((s) =>
              s.id == updatedSystem.id ? updatedSystem : s
            ).toList(),
          );
          
          // Update caches
          _softwareSystemsById[updatedSystem.id] = updatedSystem;
        } else {
          _errorReporter.reportStandardError(
            'Parent software system not found for deployment environment: ${element.name}',
            0, // Offset not available here
          );
        }
      } else {
        // Add directly to the model
        _currentModel = _currentModel.copyWith(
          deploymentEnvironments: [..._currentModel.deploymentEnvironments, element],
        );
      }
      
      // Update environment cache
      _environmentsById[element.id] = element as DeploymentEnvironment;
    } else if (element is DeploymentNode) {
      // Add the node to the parent
      final parentId = element.parentId!;
      final parentElement = _elementsById[parentId];
      
      if (parentElement is DeploymentEnvironment) {
        // Add to environment
        final updatedEnvironment = parentElement.copyWith(
          deploymentNodes: [...parentElement.deploymentNodes, element],
        );
        
        // Update the environment in the model
        if (updatedEnvironment.parentId != null) {
          // In a software system
          final parentSystem = _softwareSystemsById[updatedEnvironment.parentId!];
          if (parentSystem != null) {
            final updatedSystem = parentSystem.copyWith(
              deploymentEnvironments: parentSystem.deploymentEnvironments.map((e) =>
                e.id == updatedEnvironment.id ? updatedEnvironment : e
              ).toList(),
            );
            
            // Update the model
            _currentModel = _currentModel.copyWith(
              softwareSystems: _currentModel.softwareSystems.map((s) =>
                s.id == updatedSystem.id ? updatedSystem : s
              ).toList(),
            );
            
            // Update caches
            _softwareSystemsById[updatedSystem.id] = updatedSystem;
          }
        } else {
          // In the main model
          _currentModel = _currentModel.copyWith(
            deploymentEnvironments: _currentModel.deploymentEnvironments.map((e) =>
              e.id == updatedEnvironment.id ? updatedEnvironment : e
            ).toList(),
          );
        }
        
        // Update environment cache
        _environmentsById[updatedEnvironment.id] = updatedEnvironment;
      } else if (parentElement is DeploymentNode) {
        // Add to parent deployment node
        final updatedParentNode = parentElement.copyWith(
          children: [...parentElement.children, element],
        );
        
        // Update the parent node in the model
        _updateDeploymentNodeInModel(updatedParentNode);
      } else {
        _errorReporter.reportStandardError(
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
      } else {
        _errorReporter.reportStandardError(
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
      } else {
        _errorReporter.reportStandardError(
          'Parent deployment node not found for container instance: ${element.id}',
          0, // Offset not available here
        );
      }
    }
    
    // If this element has a parent, store it for hierarchy building
    if (element.parentId != null) {
      final parentId = element.parentId!;
      _elementsByParent.putIfAbsent(parentId, () => []).add(element);
    }
  }
  
  // Implementation of the AstVisitor interface
  
  @override
  void visitWorkspaceNode(WorkspaceNode node) {
    // Create workspace configuration
    final configuration = WorkspaceConfiguration(
      properties: node.configuration,
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

    // Create the workspace object
    _workspace = Workspace(
      id: 1, // Default ID for DSL-created workspaces
      name: node.name,
      description: node.description,
      model: _currentModel,
      views: _currentViews,
      configuration: configuration,
    );
  }
  
  @override
  void visitModelNode(ModelNode node) {
    // Set enterprise name if available
    _currentModel = _currentModel.copyWith(
      enterpriseName: node.enterpriseName,
    );
    
    // Process people
    for (final personNode in node.people) {
      personNode.accept(this);
    }
    
    // Process software systems
    for (final systemNode in node.softwareSystems) {
      systemNode.accept(this);
    }
    
    // Process deployment environments
    for (final envNode in node.deploymentEnvironments) {
      envNode.accept(this);
    }

    // Process relationships at the model level
    for (final relationship in node.relationships) {
      _pendingRelationships.add(relationship);
    }
  }
  
  @override
  void visitPersonNode(PersonNode node) {
    // Save current context for "this" references
    final previousContextId = _currentContextId;
    _currentContextId = node.id;
    
    final person = Person.create(
      id: node.id, // Use the ID from the AST
      name: node.name,
      description: node.description,
      tags: node.tags != null ? _mapTags(node.tags) : const ['Person'],
      properties: node.properties != null ? _mapProperties(node.properties) : const {},
      location: node.location ?? 'Internal',
    );
    
    _addElementToModel(person);

    // Process relationships defined within this person
    for (final relationship in node.relationships) {
      _pendingRelationships.add(relationship);
    }
    
    // Restore previous context
    _currentContextId = previousContextId;
  }
  
  @override
  void visitSoftwareSystemNode(SoftwareSystemNode node) {
    // Save the previous context ID and parent ID to support nesting
    final previousContextId = _currentContextId;
    final previousParentId = _currentParentId;
    
    // Set this element as the current context for "this" references
    _currentContextId = node.id;
    
    // Create the software system
    final system = SoftwareSystem.create(
      id: node.id, // Use the ID from the AST
      name: node.name,
      description: node.description,
      tags: node.tags != null ? _mapTags(node.tags) : const ['SoftwareSystem'],
      properties: node.properties != null ? _mapProperties(node.properties) : const {},
      location: node.location ?? 'Internal',
    );
    
    // Add to model
    _addElementToModel(system);
    
    // Set as current parent for nested elements
    _currentParentId = system.id;
    
    // Process containers
    for (final containerNode in node.containers) {
      containerNode.accept(this);
    }

    // Process deployment environments
    for (final envNode in node.deploymentEnvironments) {
      envNode.accept(this);
    }

    // Process relationships defined within this system
    for (final relationship in node.relationships) {
      _pendingRelationships.add(relationship);
    }
    
    // Restore previous parent ID and context ID
    _currentParentId = previousParentId;
    _currentContextId = previousContextId;
  }
  
  @override
  void visitContainerNode(ContainerNode node) {
    if (_currentParentId == null) {
      _errorReporter.reportStandardError(
        'Container must be defined within a software system: ${node.name}',
        node.sourcePosition?.offset ?? 0,
      );
      return;
    }
    
    // Save the previous context ID and parent ID to support nesting
    final previousContextId = _currentContextId;
    final previousParentId = _currentParentId;
    
    // Set this element as the current context for "this" references
    _currentContextId = node.id;
    
    // Create the container
    final container = Container.create(
      id: node.id, // Use the ID from the AST
      name: node.name,
      description: node.description,
      technology: node.technology,
      parentId: _currentParentId!,
      tags: node.tags != null ? _mapTags(node.tags) : const ['Container'],
      properties: node.properties != null ? _mapProperties(node.properties) : const {},
    );
    
    // Add to model
    _addElementToModel(container);
    
    // Set as current parent for nested elements
    _currentParentId = container.id;
    
    // Process components
    for (final componentNode in node.components) {
      componentNode.accept(this);
    }

    // Process relationships defined within this container
    for (final relationship in node.relationships) {
      _pendingRelationships.add(relationship);
    }
    
    // Restore previous parent ID and context ID
    _currentParentId = previousParentId;
    _currentContextId = previousContextId;
  }
  
  @override
  void visitComponentNode(ComponentNode node) {
    if (_currentParentId == null) {
      _errorReporter.reportStandardError(
        'Component must be defined within a container: ${node.name}',
        node.sourcePosition?.offset ?? 0,
      );
      return;
    }
    
    // Save the previous context ID
    final previousContextId = _currentContextId;
    
    // Set this element as the current context for "this" references
    _currentContextId = node.id;
    
    // Create the component
    final component = Component.create(
      id: node.id, // Use the ID from the AST
      name: node.name,
      description: node.description,
      technology: node.technology,
      parentId: _currentParentId!,
      tags: node.tags != null ? _mapTags(node.tags) : const ['Component'],
      properties: node.properties != null ? _mapProperties(node.properties) : const {},
    );
    
    // Add to model
    _addElementToModel(component);

    // Process relationships defined within this component
    for (final relationship in node.relationships) {
      _pendingRelationships.add(relationship);
    }
    
    // Restore previous context ID
    _currentContextId = previousContextId;
  }
  
  @override
  void visitRelationshipNode(RelationshipNode node) {
    // Transform "this" references based on current context
    String sourceId = node.sourceId;
    String destinationId = node.destinationId;
    
    // If using "this" keyword and we have a current context, replace with the actual ID
    if (sourceId == 'this' && _currentContextId != null) {
      sourceId = _currentContextId!;
    }
    
    if (destinationId == 'this' && _currentContextId != null) {
      destinationId = _currentContextId!;
    }
    
    // Queue relationship for processing in the second phase
    // with the transformed IDs
    _pendingRelationships.add(RelationshipNode(
      sourceId: sourceId,
      destinationId: destinationId,
      description: node.description,
      technology: node.technology,
      tags: node.tags,
      properties: node.properties,
      sourcePosition: node.sourcePosition,
    ));
  }
  
  @override
  void visitViewsNode(ViewsNode node) {
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
    
    // Process configuration if present
    if (node.configuration.isNotEmpty) {
      // Apply configuration to views
      _currentViews = _currentViews.copyWith(
        configuration: ViewConfiguration(
          properties: node.configuration,
        ),
      );
    }
  }
  
  @override
  void visitSystemLandscapeViewNode(SystemLandscapeViewNode node) {
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
    final includes = node.includes.map((include) => include.expression).toList();
    final excludes = node.excludes.map((exclude) => exclude.expression).toList();

    // Create a system landscape view
    final view = SystemLandscapeView(
      key: node.key,
      title: node.title ?? 'System Landscape',
      description: node.description,
      elements: [], // Elements will be populated based on include/exclude rules
      relationships: [], // Relationships will be computed
      automaticLayout: automaticLayout,
      animations: animationSteps,
      includeTags: includes,
      excludeTags: excludes,
    );

    // Add to views collection
    _currentViews = _currentViews.addSystemLandscapeView(view);
  }
  
  @override
  void visitSystemContextViewNode(SystemContextViewNode node) {
    // Resolve the system reference
    final softwareSystem = _resolveElementReference(
      node.systemId, 
      sourcePosition: node.sourcePosition,
      searchByName: true,
    ) as SoftwareSystem?;

    if (softwareSystem == null) {
      _errorReporter.reportStandardError(
        'Software system not found for system context view: ${node.key}, systemId: ${node.systemId}',
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
    final includes = node.includes.map((include) => include.expression).toList();
    final excludes = node.excludes.map((exclude) => exclude.expression).toList();

    // Create a system context view
    final view = SystemContextView(
      key: node.key,
      softwareSystemId: softwareSystem.id,
      title: node.title ?? '${softwareSystem.name} - System Context',
      description: node.description,
      elements: [], // Elements will be populated based on include/exclude rules
      relationships: [], // Relationships will be computed
      automaticLayout: automaticLayout,
      animations: animationSteps,
      includeTags: includes,
      excludeTags: excludes,
    );

    // Add to views collection
    _currentViews = _currentViews.addSystemContextView(view);
  }

  @override
  void visitContainerViewNode(ContainerViewNode node) {
    // Resolve the system reference
    final softwareSystem = _resolveElementReference(
      node.systemId, 
      sourcePosition: node.sourcePosition,
      searchByName: true,
    ) as SoftwareSystem?;

    if (softwareSystem == null) {
      _errorReporter.reportStandardError(
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
    final includes = node.includes.map((include) => include.expression).toList();
    final excludes = node.excludes.map((exclude) => exclude.expression).toList();

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
      includeTags: includes,
      excludeTags: excludes,
    );

    // Add to views collection
    _currentViews = _currentViews.addContainerView(view);
  }

  @override
  void visitComponentViewNode(ComponentViewNode node) {
    // Resolve the container reference
    final container = _resolveElementReference(
      node.containerId, 
      sourcePosition: node.sourcePosition,
      searchByName: true,
    ) as Container?;

    if (container == null) {
      _errorReporter.reportStandardError(
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
    final includes = node.includes.map((include) => include.expression).toList();
    final excludes = node.excludes.map((exclude) => exclude.expression).toList();

    // Get the software system for this container
    SoftwareSystem? softwareSystem = null;
    if (container.parentId != null) {
      softwareSystem = _softwareSystemsById[container.parentId];
    }

    if (softwareSystem == null) {
      _errorReporter.reportStandardError(
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
      includeTags: includes,
      excludeTags: excludes,
    );

    // Add to views collection
    _currentViews = _currentViews.addComponentView(view);
  }
  
  @override
  void visitDynamicViewNode(DynamicViewNode node) {
    // Find the scope element if specified
    String? scopeId = node.scope;
    Element? scopeElement;
    String description = "Dynamic View";

    if (scopeId != null) {
      scopeElement = _resolveElementReference(
        scopeId, 
        sourcePosition: node.sourcePosition,
        searchByName: true,
      );

      if (scopeElement == null) {
        _errorReporter.reportStandardError(
          'Scope element not found for dynamic view: ${node.key}, scope: $scopeId',
          node.sourcePosition?.offset ?? 0,
        );
        return;
      }

      // Update scopeId with the resolved element ID
      scopeId = scopeElement.id;
      description = 'Dynamic view of ${scopeElement.name}';
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
    final includes = node.includes.map((include) => include.expression).toList();
    final excludes = node.excludes.map((exclude) => exclude.expression).toList();

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
      includeTags: includes,
      excludeTags: excludes,
    );

    // Add to views collection
    _currentViews = _currentViews.addDynamicView(view);
  }

  @override
  void visitDeploymentViewNode(DeploymentViewNode node) {
    // Resolve the system reference
    final softwareSystem = _resolveElementReference(
      node.systemId, 
      sourcePosition: node.sourcePosition,
      searchByName: true,
    ) as SoftwareSystem?;

    if (softwareSystem == null) {
      _errorReporter.reportStandardError(
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
    final includes = node.includes.map((include) => include.expression).toList();
    final excludes = node.excludes.map((exclude) => exclude.expression).toList();

    // Create a deployment view
    final view = DeploymentView(
      key: node.key,
      softwareSystemId: softwareSystem.id,
      environment: node.environment,
      title: node.title ?? '${softwareSystem.name} - ${node.environment} Deployment',
      description: node.description,
      elements: [], // Elements will be populated based on include/exclude rules
      relationships: [], // Relationships will be computed
      automaticLayout: automaticLayout,
      animations: animationSteps,
      includeTags: includes,
      excludeTags: excludes,
    );

    // Add to views collection
    _currentViews = _currentViews.addDeploymentView(view);
  }

  @override
  void visitFilteredViewNode(FilteredViewNode node) {
    // Find the base view by key
    View? baseView;

    // Check in all view collections
    if (_currentViews.systemLandscapeViews.any((v) => v.key == node.baseViewKey)) {
      baseView = _currentViews.systemLandscapeViews.firstWhere((v) => v.key == node.baseViewKey);
    } else if (_currentViews.systemContextViews.any((v) => v.key == node.baseViewKey)) {
      baseView = _currentViews.systemContextViews.firstWhere((v) => v.key == node.baseViewKey);
    } else if (_currentViews.containerViews.any((v) => v.key == node.baseViewKey)) {
      baseView = _currentViews.containerViews.firstWhere((v) => v.key == node.baseViewKey);
    } else if (_currentViews.componentViews.any((v) => v.key == node.baseViewKey)) {
      baseView = _currentViews.componentViews.firstWhere((v) => v.key == node.baseViewKey);
    } else if (_currentViews.dynamicViews.any((v) => v.key == node.baseViewKey)) {
      baseView = _currentViews.dynamicViews.firstWhere((v) => v.key == node.baseViewKey);
    } else if (_currentViews.deploymentViews.any((v) => v.key == node.baseViewKey)) {
      baseView = _currentViews.deploymentViews.firstWhere((v) => v.key == node.baseViewKey);
    }

    if (baseView == null) {
      _errorReporter.reportStandardError(
        'Base view not found for filtered view: ${node.key}, baseViewKey: ${node.baseViewKey}',
        node.sourcePosition?.offset ?? 0,
      );
      return;
    }

    // Process include/exclude rules for the view
    final includes = node.includes.map((include) => include.expression).toList();
    final excludes = node.excludes.map((exclude) => exclude.expression).toList();

    // Create a filtered view
    final view = FilteredView(
      key: node.key,
      baseViewKey: node.baseViewKey,
      title: node.title ?? 'Filtered: ${baseView.title}',
      description: node.description,
      includeTags: includes,
      excludeTags: excludes,
    );

    // Add to views collection
    _currentViews = _currentViews.addFilteredView(view);
  }
  
  @override
  void visitCustomViewNode(CustomViewNode node) {
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
    final includes = node.includes.map((include) => include.expression).toList();
    final excludes = node.excludes.map((exclude) => exclude.expression).toList();

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
      includeTags: includes,
      excludeTags: excludes,
    );

    // Add to views collection
    _currentViews = _currentViews.addCustomView(view);
  }
  
  @override
  void visitImageViewNode(ImageViewNode node) {
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
  }
  
  @override
  void visitDeploymentEnvironmentNode(DeploymentEnvironmentNode node) {
    // Save the previous context ID and parent ID to support nesting
    final previousContextId = _currentContextId;
    final previousParentId = _currentParentId;
    
    // Set this element as the current context for "this" references
    _currentContextId = node.id;

    // Create a new deployment environment
    final environment = DeploymentEnvironment.create(
      id: node.id, // Use the ID from the AST
      name: node.name,
      description: node.description,
      parentId: _currentParentId,
      tags: node.tags != null ? _mapTags(node.tags) : const [],
      properties: node.properties != null ? _mapProperties(node.properties) : const {},
    );

    // Add to our element map for reference resolution
    _addElementToModel(environment);

    // Set this environment as the current parent for nested elements
    _currentParentId = environment.id;

    // Process child deployment nodes
    for (final deploymentNode in node.deploymentNodes) {
      deploymentNode.accept(this);
    }

    // Process relationships defined in this environment
    for (final relationship in node.relationships) {
      _pendingRelationships.add(relationship);
    }

    // Restore previous parent ID and context ID
    _currentParentId = previousParentId;
    _currentContextId = previousContextId;
  }
  
  @override
  void visitDeploymentNodeNode(DeploymentNodeNode node) {
    if (_currentParentId == null) {
      _errorReporter.reportStandardError(
        'Deployment node must be defined within a deployment environment or another deployment node: ${node.name}',
        node.sourcePosition?.offset ?? 0,
      );
      return;
    }

    // Save the previous context ID and parent ID to support nesting
    final previousContextId = _currentContextId;
    final previousParentId = _currentParentId;
    
    // Set this element as the current context for "this" references
    _currentContextId = node.id;

    // Create the deployment node
    final deploymentNode = DeploymentNode.create(
      id: node.id, // Use the ID from the AST
      name: node.name,
      description: node.description,
      technology: node.technology,
      parentId: _currentParentId!,
      environment: _findEnvironmentForDeploymentNode(_currentParentId!),
      tags: node.tags != null ? _mapTags(node.tags) : const [],
      properties: node.properties != null ? _mapProperties(node.properties) : const {},
    );

    // Add the new node to our element map
    _addElementToModel(deploymentNode);

    // Set this node as the current parent for nested elements
    _currentParentId = deploymentNode.id;

    // Process child deployment nodes
    for (final childNode in node.children) {
      childNode.accept(this);
    }

    // Process infrastructure nodes
    for (final infraNode in node.infrastructureNodes) {
      infraNode.accept(this);
    }

    // Process container instances
    for (final instance in node.containerInstances) {
      instance.accept(this);
    }

    // Process relationships
    for (final relationship in node.relationships) {
      _pendingRelationships.add(relationship);
    }

    // Restore previous parent ID and context ID
    _currentParentId = previousParentId;
    _currentContextId = previousContextId;
  }
  
  @override
  void visitInfrastructureNodeNode(InfrastructureNodeNode node) {
    if (_currentParentId == null) {
      _errorReporter.reportStandardError(
        'Infrastructure node must be defined within a deployment node: ${node.name}',
        node.sourcePosition?.offset ?? 0,
      );
      return;
    }

    // Save the previous context ID
    final previousContextId = _currentContextId;
    
    // Set this element as the current context for "this" references
    _currentContextId = node.id;

    // Create the infrastructure node
    final infraNode = InfrastructureNode.create(
      id: node.id, // Use the ID from the AST
      name: node.name,
      description: node.description,
      technology: node.technology,
      parentId: _currentParentId!,
      tags: node.tags != null ? _mapTags(node.tags) : const [],
      properties: node.properties != null ? _mapProperties(node.properties) : const {},
    );

    // Add the infrastructure node to our element map
    _addElementToModel(infraNode);

    // Process relationships
    for (final relationship in node.relationships) {
      _pendingRelationships.add(relationship);
    }

    // Restore previous context ID
    _currentContextId = previousContextId;
  }
  
  @override
  void visitContainerInstanceNode(ContainerInstanceNode node) {
    if (_currentParentId == null) {
      _errorReporter.reportStandardError(
        'Container instance must be defined within a deployment node: ${node.containerId}',
        node.sourcePosition?.offset ?? 0,
      );
      return;
    }

    // Resolve the referenced container
    final container = _resolveElementReference(
      node.containerId, 
      sourcePosition: node.sourcePosition,
      searchByName: true,
    ) as Container?;

    if (container == null) {
      _errorReporter.reportStandardError(
        'Referenced container not found: ${node.containerId}',
        node.sourcePosition?.offset ?? 0,
      );
      return;
    }

    // Save the previous context ID
    final previousContextId = _currentContextId;
    
    // Set this element as the current context for "this" references
    _currentContextId = node.id;

    // Create the container instance
    final instance = ContainerInstance.create(
      id: node.id, // Use the ID from the AST
      containerId: container.id, // Use the resolved container ID
      parentId: _currentParentId!,
      instanceId: node.instanceCount,
      tags: node.tags != null ? _mapTags(node.tags) : const [],
      properties: node.properties != null ? _mapProperties(node.properties) : const {},
    );

    // Add the container instance to our element map
    _addElementToModel(instance);

    // Process relationships
    for (final relationship in node.relationships) {
      _pendingRelationships.add(relationship);
    }

    // Restore previous context ID
    _currentContextId = previousContextId;
  }

  /// Finds the environment name for a deployment node by traversing up the hierarchy.
  String _findEnvironmentForDeploymentNode(String nodeId) {
    Element? current = _elementsById[nodeId];

    while (current != null) {
      if (current is DeploymentEnvironment) {
        return current.name;
      }

      current = current.parentId != null ? _elementsById[current.parentId!] : null;
    }

    return 'Default'; // Fallback environment name
  }
  
  @override
  void visitGroupNode(GroupNode node) {
    if (_currentParentId == null) {
      _errorReporter.reportStandardError(
        'Group must be defined within a parent context: ${node.name}',
        node.sourcePosition?.offset ?? 0,
      );
      return;
    }

    // Save the previous context ID and parent ID to support nesting
    final previousContextId = _currentContextId;
    final previousParentId = _currentParentId;
    
    // Set this element as the current context for "this" references
    _currentContextId = node.id;

    // Create the group
    final group = Group.create(
      id: node.id, // Use the ID from the AST
      name: node.name,
      parentId: _currentParentId!,
      tags: node.tags != null ? _mapTags(node.tags) : const [],
      properties: node.properties != null ? _mapProperties(node.properties) : const {},
    );

    // Add group to our element map
    _elementsById[group.id] = group;

    // Set this group as the current parent for nested elements
    _currentParentId = group.id;

    // Process children
    for (final child in node.children) {
      child.accept(this);
    }

    // Process relationships
    for (final relationship in node.relationships) {
      _pendingRelationships.add(relationship);
    }

    // Restore previous parent ID and context ID
    _currentParentId = previousParentId;
    _currentContextId = previousContextId;
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
    // Create styles collection or start with existing one
    Styles styles = _workspace?.styles ?? const Styles();

    // Process element styles
    for (final elementStyle in node.elementStyles) {
      elementStyle.accept(this);
      // Styles will be updated by the element style visitor
    }

    // Process relationship styles
    for (final relationshipStyle in node.relationshipStyles) {
      relationshipStyle.accept(this);
      // Styles will be updated by the relationship style visitor
    }

    // Update workspace with the styles
    if (_workspace != null) {
      _workspace = _workspace!.copyWith(styles: styles);
    }
  }

  @override
  void visitElementStyleNode(ElementStyleNode node) {
    // Get existing styles collection or create new
    Styles styles = _workspace?.styles ?? const Styles();

    // Create shape from string
    Shape shape = Shape.box;
    if (node.shape != null) {
      try {
        shape = Shape.values.firstWhere(
          (s) => s.toString().split('.').last.toLowerCase() == node.shape!.toLowerCase(),
          orElse: () => Shape.box,
        );
      } catch (e) {
        _errorReporter.reportStandardError(
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
          (b) => b.toString().split('.').last.toLowerCase() == node.border!.toLowerCase(),
          orElse: () => Border.solid,
        );
      } catch (e) {
        _errorReporter.reportStandardError(
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
      width: node.width,
      height: node.height,
      background: backgroundColor,
      stroke: strokeColor,
      color: textColor,
      fontSize: node.fontSize,
      border: border,
      opacity: node.opacity != null ? (node.opacity! * 100).toInt() : 100,
    );

    // Add the style to the styles collection
    styles = styles.addElementStyle(elementStyle);

    // Update workspace with the styles
    if (_workspace != null) {
      _workspace = _workspace!.copyWith(styles: styles);
    }
  }

  @override
  void visitRelationshipStyleNode(RelationshipStyleNode node) {
    // Get existing styles collection or create new
    Styles styles = _workspace?.styles ?? const Styles();

    // Create line style from string
    LineStyle lineStyle = LineStyle.solid;
    if (node.style != null) {
      try {
        lineStyle = LineStyle.values.firstWhere(
          (s) => s.toString().split('.').last.toLowerCase() == node.style!.toLowerCase(),
          orElse: () => LineStyle.solid,
        );
      } catch (e) {
        _errorReporter.reportStandardError(
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
          (r) => r.toString().split('.').last.toLowerCase() == node.routing!.toLowerCase(),
          orElse: () => StyleRouting.direct,
        );
      } catch (e) {
        _errorReporter.reportStandardError(
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
      thickness: node.thickness ?? 1,
      color: lineColor,
      style: lineStyle,
      routing: routing,
      fontSize: node.fontSize,
      width: node.width,
      position: node.position != null ? int.tryParse(node.position!) ?? 50 : 50,
      opacity: node.opacity != null ? (node.opacity! * 100).toInt() : 100,
    );

    // Add the style to the styles collection
    styles = styles.addRelationshipStyle(relationshipStyle);

    // Update workspace with the styles
    if (_workspace != null) {
      _workspace = _workspace!.copyWith(styles: styles);
    }
  }

  @override
  void visitThemeNode(ThemeNode node) {
    // Get existing styles collection or create new
    Styles styles = _workspace?.styles ?? const Styles();

    // Add the theme URL to the styles
    styles = styles.addTheme(node.url);

    // Update workspace with the styles
    if (_workspace != null) {
      _workspace = _workspace!.copyWith(styles: styles);
    }
  }

  @override
  void visitBrandingNode(BrandingNode node) {
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
    if (_workspace != null) {
      _workspace = _workspace!.copyWith(branding: branding);
    }
  }
  
  @override
  void visitTerminologyNode(TerminologyNode node) {
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
    if (_workspace != null) {
      _workspace = _workspace!.copyWith(views: _currentViews);
    }
  }

  /// Helper method to convert a hex color string to a Color object
  Color? _colorFromHex(String hexString) {
    // Remove any leading # character
    final hex = hexString.startsWith('#') ? hexString.substring(1) : hexString;

    try {
      // Parse the hex color
      if (hex.length == 6) {
        final r = int.parse(hex.substring(0, 2), radix: 16);
        final g = int.parse(hex.substring(2, 4), radix: 16);
        final b = int.parse(hex.substring(4, 6), radix: 16);
        return Color.fromARGB(255, r, g, b);
      } else if (hex.length == 8) {
        final a = int.parse(hex.substring(0, 2), radix: 16);
        final r = int.parse(hex.substring(2, 4), radix: 16);
        final g = int.parse(hex.substring(4, 6), radix: 16);
        final b = int.parse(hex.substring(6, 8), radix: 16);
        return Color.fromARGB(a, r, g, b);
      }
    } catch (e) {
      // Invalid hex string
      return null;
    }

    return null;
  }

  @override
  void visitDirectiveNode(DirectiveNode node) {
    // Handle !include directive
    if (node.type.toLowerCase() == 'include') {
      // In a production implementation, this would include content from other files
      // For this implementation, we'll log a message but not actually include the file
      _errorReporter.reportInfo(
        'Include directive found: ${node.value}. File inclusion is not implemented in this version.',
        node.sourcePosition?.offset ?? 0,
      );
    } else {
      // Log unknown directive
      _errorReporter.reportInfo(
        'Unknown directive: ${node.type}',
        node.sourcePosition?.offset ?? 0,
      );
    }
  }
}