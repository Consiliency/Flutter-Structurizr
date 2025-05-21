import 'dart:ui';
import 'package:flutter_structurizr/application/dsl/documentation_mapper.dart';
import 'package:flutter_structurizr/domain/documentation/documentation.dart'
    as domain;
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/modeled_relationship.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/model/deployment_environment.dart';
import 'package:flutter_structurizr/domain/model/group.dart';
import 'package:flutter_structurizr/domain/model/container.dart';
import 'package:flutter_structurizr/domain/model/component.dart';
import 'package:flutter_structurizr/domain/model/deployment_node.dart';
import 'package:flutter_structurizr/domain/model/infrastructure_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/ast.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/documentation/documentation_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/relationship_node.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/parser/reference_resolver.dart';
import 'package:flutter_structurizr/domain/style/branding.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/domain/view/views.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/view_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/views_node.dart';

/// Mapper for converting AST nodes to domain model objects.
///
/// This class implements the visitor pattern to traverse the AST
/// and build the corresponding domain model objects.
class WorkspaceMapper implements AstVisitor {
  /// The error reporter for reporting semantic errors.
  final ErrorReporter errorReporter;

  /// The source code being processed.
  final String _source;

  /// The resulting workspace after mapping.
  Workspace? _workspace;

  /// The current model being built.
  Model _currentModel = const Model();

  /// The current views collection being built.
  Views _currentViews = const Views();

  /// Queue of relationships to be resolved in the second phase
  final List<RelationshipNode> _pendingRelationships = [];

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

  /// Maps element names to their IDs for name-based lookup
  final Map<String, String> _elementNameToId = {};

  /// Maps element IDs to their actual objects
  final Map<String, Element> _elementsById = {};

  /// Current context element ID (for "this" references)
  String? _currentContextId;

  /// Current parent element ID (for nested elements)
  String? _currentParentId;

  /// The reference resolver for handling element references
  final ReferenceResolver _referenceResolver;

  /// The documentation mapper for handling documentation nodes
  final DocumentationMapper _documentationMapper;

  /// Creates a new workspace mapper.
  WorkspaceMapper(this._source, this.errorReporter)
      : _referenceResolver = ReferenceResolver(errorReporter),
        _documentationMapper = DocumentationMapper(errorReporter);

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
      errorReporter.reportStandardError(
        'Error mapping workspace: ${e.toString()}\n$stackTrace',
        workspaceNode.sourcePosition?.offset ?? 0,
      );
      return null;
    }
  }

  /// Resolves relationships between elements.
  void _resolveRelationships() {
    // First process all relationships to create basic relationships
    for (final relationshipNode in _pendingRelationships) {
      _processRelationship(relationshipNode);
    }

    // Now that all relationships are created and added to the model,
    // we can access them via model.findRelationshipBetween which will
    // provide ModeledRelationship objects with proper source/destination access

    // Check for any unresolved or problematic relationships
    _validateRelationships();
  }

  /// Validates all relationships in the model for consistency
  void _validateRelationships() {
    // Get all elements
    final allElements = _referenceResolver.getAllElements();

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

  /// Helper method to resolve an element by name as a specific type.
  /// This is useful for handling references by names in component references.
  T? _resolveElementByName<T extends Element>(String name) {
    // First try direct lookup by name in the element name to ID map
    if (_elementNameToId.containsKey(name)) {
      final id = _elementNameToId[name];
      if (id != null) {
        final element = _elementsById[id];
        if (element is T) {
          return element;
        }
      }
    }

    // Then try finding by name (case sensitive)
    for (final element in _elementsById.values) {
      if (element is T && element.name == name) {
        return element;
      }
    }

    // Finally try case-insensitive match
    final lowerName = name.toLowerCase();
    for (final element in _elementsById.values) {
      if (element is T && element.name.toLowerCase() == lowerName) {
        return element;
      }
    }

    return null;
  }

  /// Resolves a composite reference path like "System.Container.Component".
  /// This allows for qualified path-based references.
  Element? _resolveCompositePath(String path,
      {SourcePosition? sourcePosition}) {
    final parts = path.split('.');
    if (parts.isEmpty) {
      return null;
    }

    if (parts.length == 1) {
      // Single part, just use regular element reference
      return _resolveElementReference(parts[0],
          sourcePosition: sourcePosition, searchByName: true);
    }

    // Multi-part path, start with the first element
    Element? current = _resolveElementReference(parts[0],
        sourcePosition: sourcePosition, searchByName: true);

    // Traverse the path
    for (int i = 1; i < parts.length && current != null; i++) {
      final part = parts[i];
      bool found = false;

      // Find the child element with the matching name
      for (final element in _elementsById.values) {
        if (element.parentId == current!.id &&
            (element.name == part ||
                element.name.toLowerCase() == part.toLowerCase())) {
          current = element;
          found = true;
          break;
        }
      }

      if (!found) {
        if (sourcePosition != null) {
          errorReporter.reportStandardError(
            'Could not resolve path component "$part" in path "$path"',
            sourcePosition.offset,
          );
        }
        return null;
      }
    }

    return current;
  }

  /// Resolves a reference to an element, supporting special keywords like "this" and "parent".
  Element? _resolveElementReference(String reference,
      {SourcePosition? sourcePosition, bool searchByName = false}) {
    // Handle "this" keyword which refers to the current context element
    if (reference == 'this' && _currentContextId != null) {
      return _elementsById[_currentContextId];
    }

    // Handle "parent" keyword which refers to the parent of the current context element
    if (reference == 'parent' && _currentContextId != null) {
      final currentElement = _elementsById[_currentContextId];
      if (currentElement != null && currentElement.parentId != null) {
        return _elementsById[currentElement.parentId!];
      } else {
        if (sourcePosition != null) {
          errorReporter.reportStandardError(
            'Cannot resolve parent reference: current element has no parent',
            sourcePosition.offset,
          );
        }
        return null;
      }
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

    // If the reference contains dots, it might be a path reference (e.g., "System.Container.Component")
    if (reference.contains('.')) {
      final pathResult =
          _resolveCompositePath(reference, sourcePosition: sourcePosition);
      if (pathResult != null) {
        return pathResult;
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
      errorReporter.reportStandardError(
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

    // Resolve source and destination references with improved context handling
    // We'll save the current context to restore it later
    final previousContextId = _referenceResolver.getCurrentContextId();

    // Resolve source element reference
    final sourceElement = _referenceResolver.resolveReference(
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
    _referenceResolver.setCurrentContext(sourceElement.id);

    // Resolve destination element reference with the source as context
    final destinationElement = _referenceResolver.resolveReference(
      destinationId,
      sourcePosition: node.sourcePosition,
      searchByName: true,
    );

    // Restore the previous context
    _referenceResolver.setCurrentContext(previousContextId);

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
      tags: _mapTags(node.tags),
      properties: _mapProperties(node.properties),
    );

    // Update the reference resolver with the updated element
    _referenceResolver.registerElement(newElement);

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
      final parentSystem = _softwareSystemsById[element.parentId];
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
      final parentContainer = _containersById[element.parentId];
      if (parentContainer != null) {
        // Update the component in the parent
        final updatedContainer = parentContainer.copyWith(
          components: parentContainer.components
              .map((c) => c.id == element.id ? element as Component : c)
              .toList(),
        );

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

            // Update cache
            _softwareSystemsById[updatedSystem.id] = updatedSystem;
            _environmentsById[element.id] = element;
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

    // Update the deployment node in the elements map
    _elementsById[node.id] = node;
    _deploymentNodesById[node.id] = node;
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

    // Update the infrastructure node in the elements map
    _elementsById[node.id] = node;
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

    // Update the container instance in the elements map
    _elementsById[node.id] = node;
    _containerInstancesById[node.id] = node;
  }

  /// Adds an element to the current model.
  void _addElementToModel(Element element) {
    // Register the element with the reference resolver
    _referenceResolver.registerElement(element);

    // Register in global element maps for faster lookups
    _elementsById[element.id] = element;
    if (element.name.isNotEmpty) {
      // Some elements like ContainerInstance don't have a name
      _elementNameToId[element.name] = element.id;
    }

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
      } else {
        errorReporter.reportStandardError(
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
      final parentElement = _referenceResolver.resolveReference(parentId);

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
        _referenceResolver.registerElement(updatedEnvironment);
      } else if (parentElement is DeploymentNode) {
        // Add to parent deployment node
        final updatedParentNode = parentElement.copyWith(
          children: [...parentElement.children, element],
        );

        // Update the parent node in the model
        _updateDeploymentNodeInModel(updatedParentNode);

        // Update in reference resolver
        _referenceResolver.registerElement(updatedParentNode);
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
        _referenceResolver.registerElement(updatedParentNode);
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
        _referenceResolver.registerElement(updatedParentNode);
      } else {
        errorReporter.reportStandardError(
          'Parent deployment node not found for container instance: ${element.id}',
          0, // Offset not available here
        );
      }
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

    // Process documentation
    domain.Documentation? documentation;
    if (node.documentation != null) {
      // Map documentation using the documentation mapper
      final mappedDoc =
          _documentationMapper.mapDocumentation(node.documentation!);
      if (mappedDoc != null) {
        documentation = mappedDoc;
      }
    }

    // Process decisions
    if (node.decisions != null && node.decisions!.isNotEmpty) {
      final mappedDecisions =
          _documentationMapper.mapDecisions(node.decisions!);

      // If documentation already exists, add decisions to it
      if (documentation != null) {
        documentation = documentation.copyWith(
          decisions: [...documentation.decisions, ...mappedDecisions],
        );
      } else {
        // Create a new documentation object with just the decisions
        documentation = domain.Documentation(
          decisions: mappedDecisions,
        );
      }
    }

    // Extra logging to debug documentation mapping
    if (node.documentation != null ||
        (node.decisions != null && node.decisions!.isNotEmpty)) {
      if (documentation == null) {
        errorReporter.reportInfo(
          'Documentation mapping failed: documentation is null',
          node.sourcePosition?.offset ?? 0,
        );
      }
    }

    // Create the workspace object
    _workspace = Workspace(
      id: 1, // Default ID for DSL-created workspaces
      name: node.name,
      description: node.description,
      model: _currentModel,
      views: _currentViews,
      configuration: configuration,
      documentation: documentation,
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
    final previousContextId = _referenceResolver.getCurrentContextId();
    _referenceResolver.setCurrentContext(node.id);
    _currentContextId = node.id;

    // Create Person directly with the AST node ID instead of using create()
    final person = Person(
      id: node.id, // Use the ID from the AST
      name: node.name,
      description: node.description,
      tags: node.tags != null ? _mapTags(node.tags) : const ['Person'],
      properties:
          node.properties != null ? _mapProperties(node.properties) : const {},
      location: node.location ?? 'Internal',
    );

    // Register any alias for this person if we have one in the variable
    if (node.variableName != null && node.variableName!.isNotEmpty) {
      _referenceResolver.registerAlias(node.variableName!, node.id);
    }

    _addElementToModel(person);

    // Process relationships defined within this person
    for (final relationship in node.relationships) {
      _pendingRelationships.add(relationship);
    }

    // Restore previous context
    _referenceResolver.setCurrentContext(previousContextId);
    _currentContextId = previousContextId;
  }

  @override
  void visitSoftwareSystemNode(SoftwareSystemNode node) {
    // Save the previous context ID and parent ID to support nesting
    final previousContextId = _referenceResolver.getCurrentContextId();
    final previousParentId = _currentParentId;

    // Set this element as the current context for "this" references
    _referenceResolver.setCurrentContext(node.id);
    _currentContextId = node.id;

    // Create the software system directly with the AST node ID
    final system = SoftwareSystem(
      id: node.id, // Use the ID from the AST
      name: node.name,
      description: node.description,
      tags: node.tags != null ? _mapTags(node.tags) : const ['SoftwareSystem'],
      properties:
          node.properties != null ? _mapProperties(node.properties) : const {},
      location: node.location ?? 'Internal',
    );

    // Register any alias for this system if we have one in the variable
    if (node.variableName != null && node.variableName!.isNotEmpty) {
      _referenceResolver.registerAlias(node.variableName!, node.id);
    }

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
    _referenceResolver.setCurrentContext(previousContextId);
    _currentContextId = previousContextId;
  }

  @override
  void visitContainerNode(ContainerNode node) {
    if (_currentParentId == null) {
      errorReporter.reportStandardError(
        'Container must be defined within a software system: ${node.name}',
        node.sourcePosition?.offset ?? 0,
      );
      return;
    }

    // Save the previous context ID and parent ID to support nesting
    final previousContextId = _referenceResolver.getCurrentContextId();
    final previousParentId = _currentParentId;

    // Set this element as the current context for "this" references
    _referenceResolver.setCurrentContext(node.id);
    _currentContextId = node.id;

    // Create the container
    final container = Container(
      id: node.id, // Use the ID from the AST
      name: node.name,
      description: node.description,
      technology: node.technology,
      parentId: _currentParentId!,
      tags: node.tags != null ? _mapTags(node.tags) : const ['Container'],
      properties:
          node.properties != null ? _mapProperties(node.properties) : const {},
    );

    // Register any alias for this container if we have one in the variable
    if (node.variableName != null && node.variableName!.isNotEmpty) {
      _referenceResolver.registerAlias(node.variableName!, node.id);
    }

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
    _referenceResolver.setCurrentContext(previousContextId);
    _currentContextId = previousContextId;
  }

  @override
  void visitComponentNode(ComponentNode node) {
    if (_currentParentId == null) {
      errorReporter.reportStandardError(
        'Component must be defined within a container: ${node.name}',
        node.sourcePosition?.offset ?? 0,
      );
      return;
    }

    // Save the previous context ID
    final previousContextId = _referenceResolver.getCurrentContextId();

    // Set this element as the current context for "this" references
    _referenceResolver.setCurrentContext(node.id);
    _currentContextId = node.id;

    // Create the component
    final component = Component(
      id: node.id, // Use the ID from the AST
      name: node.name,
      description: node.description,
      technology: node.technology,
      parentId: _currentParentId!,
      tags: node.tags != null ? _mapTags(node.tags) : const ['Component'],
      properties:
          node.properties != null ? _mapProperties(node.properties) : const {},
    );

    // Register any alias for this component if we have one in the variable
    if (node.variableName != null && node.variableName!.isNotEmpty) {
      _referenceResolver.registerAlias(node.variableName!, node.id);
    }

    // Add to model
    _addElementToModel(component);

    // Process relationships defined within this component
    for (final relationship in node.relationships) {
      _pendingRelationships.add(relationship);
    }

    // Restore previous context ID
    _referenceResolver.setCurrentContext(previousContextId);
    _currentContextId = previousContextId;
  }

  @override
  void visitRelationshipNode(RelationshipNode node) {
    // Queue the relationship for processing in the second phase
    // The reference resolution is now handled by our ReferenceResolver
    _pendingRelationships.add(node);
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
      errorReporter.reportStandardError(
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
    final includes =
        node.includes.map((include) => include.expression).toList();
    final excludes =
        node.excludes.map((exclude) => exclude.expression).toList();

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
    String description = 'Dynamic View';

    scopeElement = _resolveElementReference(
      scopeId,
      sourcePosition: node.sourcePosition,
      searchByName: true,
    );

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
    final previousContextId = _referenceResolver.getCurrentContextId();
    final previousParentId = _currentParentId;

    // Set this element as the current context for "this" references
    _referenceResolver.setCurrentContext(node.id);
    _currentContextId = node.id;

    // Create a new deployment environment
    final environment = DeploymentEnvironment(
      id: node.id, // Use the ID from the AST
      name: node.name,
      description: node.description,
      parentId: _currentParentId,
      tags: node.tags != null ? _mapTags(node.tags) : const [],
      properties:
          node.properties != null ? _mapProperties(node.properties) : const {},
    );

    // Register any alias for this environment if we have one in the variable
    if (node.variableName != null && node.variableName!.isNotEmpty) {
      _referenceResolver.registerAlias(node.variableName!, node.id);
    }

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
    _referenceResolver.setCurrentContext(previousContextId);
    _currentContextId = previousContextId;
  }

  @override
  void visitDeploymentNodeNode(DeploymentNodeNode node) {
    if (_currentParentId == null) {
      errorReporter.reportStandardError(
        'Deployment node must be defined within a deployment environment or another deployment node: ${node.name}',
        node.sourcePosition?.offset ?? 0,
      );
      return;
    }

    // Save the previous context ID and parent ID to support nesting
    final previousContextId = _referenceResolver.getCurrentContextId();
    final previousParentId = _currentParentId;

    // Set this element as the current context for "this" references
    _referenceResolver.setCurrentContext(node.id);
    _currentContextId = node.id;

    // Create the deployment node
    final deploymentNode = DeploymentNode(
      id: node.id, // Use the ID from the AST
      name: node.name,
      description: node.description,
      technology: node.technology,
      parentId: _currentParentId!,
      environment: _findEnvironmentForDeploymentNode(_currentParentId!),
      tags: node.tags != null ? _mapTags(node.tags) : const [],
      properties:
          node.properties != null ? _mapProperties(node.properties) : const {},
    );

    // Register any alias for this deployment node if we have one in the variable
    if (node.variableName != null && node.variableName!.isNotEmpty) {
      _referenceResolver.registerAlias(node.variableName!, node.id);
    }

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
    _referenceResolver.setCurrentContext(previousContextId);
    _currentContextId = previousContextId;
  }

  @override
  void visitInfrastructureNodeNode(InfrastructureNodeNode node) {
    if (_currentParentId == null) {
      errorReporter.reportStandardError(
        'Infrastructure node must be defined within a deployment node: ${node.name}',
        node.sourcePosition?.offset ?? 0,
      );
      return;
    }

    // Save the previous context ID
    final previousContextId = _referenceResolver.getCurrentContextId();

    // Set this element as the current context for "this" references
    _referenceResolver.setCurrentContext(node.id);
    _currentContextId = node.id;

    // Create the infrastructure node
    final infraNode = InfrastructureNode(
      id: node.id, // Use the ID from the AST
      name: node.name,
      description: node.description,
      technology: node.technology,
      parentId: _currentParentId!,
      tags: node.tags != null ? _mapTags(node.tags) : const [],
      properties:
          node.properties != null ? _mapProperties(node.properties) : const {},
    );

    // Register any alias for this infrastructure node if we have one in the variable
    if (node.variableName != null && node.variableName!.isNotEmpty) {
      _referenceResolver.registerAlias(node.variableName!, node.id);
    }

    // Add the infrastructure node to our element map
    _addElementToModel(infraNode);

    // Process relationships
    for (final relationship in node.relationships) {
      _pendingRelationships.add(relationship);
    }

    // Restore previous context ID
    _referenceResolver.setCurrentContext(previousContextId);
    _currentContextId = previousContextId;
  }

  @override
  void visitContainerInstanceNode(ContainerInstanceNode node) {
    if (_currentParentId == null) {
      errorReporter.reportStandardError(
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
      errorReporter.reportStandardError(
        'Referenced container not found: ${node.containerId}',
        node.sourcePosition?.offset ?? 0,
      );
      return;
    }

    // Save the previous context ID
    final previousContextId = _referenceResolver.getCurrentContextId();

    // Set this element as the current context for "this" references
    _referenceResolver.setCurrentContext(node.id);
    _currentContextId = node.id;

    // Create the container instance
    final instance = ContainerInstance(
      id: node.id, // Use the ID from the AST
      containerId: container.id, // Use the resolved container ID
      parentId: _currentParentId!,
      instanceId: node.instanceCount,
      tags: node.tags != null ? _mapTags(node.tags) : const [],
      properties:
          node.properties != null ? _mapProperties(node.properties) : const {},
    );

    // Register any alias for this container instance if we have one in the variable
    if (node.variableName != null && node.variableName!.isNotEmpty) {
      _referenceResolver.registerAlias(node.variableName!, node.id);
    }

    // Add the container instance to our element map
    _addElementToModel(instance);

    // Process relationships
    for (final relationship in node.relationships) {
      _pendingRelationships.add(relationship);
    }

    // Restore previous context ID
    _referenceResolver.setCurrentContext(previousContextId);
    _currentContextId = previousContextId;
  }

  /// Finds the environment name for a deployment node by traversing up the hierarchy.
  String _findEnvironmentForDeploymentNode(String nodeId) {
    Element? current = _elementsById[nodeId];

    while (current != null) {
      if (current is DeploymentEnvironment) {
        return current.name;
      }

      current =
          current.parentId != null ? _elementsById[current.parentId!] : null;
    }

    return 'Default'; // Fallback environment name
  }

  @override
  void visitGroupNode(GroupNode node) {
    if (_currentParentId == null) {
      errorReporter.reportStandardError(
        'Group must be defined within a parent context: ${node.name}',
        node.sourcePosition?.offset ?? 0,
      );
      return;
    }

    // Save the previous context ID and parent ID to support nesting
    final previousContextId = _currentContextId;
    final previousParentId = _currentParentId;

    // Generate a unique ID for this group since GroupNode doesn't have an id property
    final groupId = const Uuid().v4();

    // Set this element as the current context for "this" references
    _currentContextId = groupId;

    // Create the group
    final group = Group(
      id: groupId, // Generate a unique ID since GroupNode doesn't have an id property
      name: node.name,
      parentId: _currentParentId!,
      tags: node.tags != null ? _mapTags(node.tags) : const [],
      properties:
          node.properties != null ? _mapProperties(node.properties) : const {},
    );

    // Add group to our element map
    _elementsById[group.id] = group;

    // Also add to name-to-id mapping for lookup by name
    _elementNameToId[group.name] = group.id;

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
  void visitDocumentationNode(DocumentationNode node) {
    // Documentation is handled by the DocumentationMapper
  }

  @override
  void visitDocumentationSectionNode(DocumentationSectionNode node) {
    // Documentation sections are handled by the DocumentationMapper
  }

  @override
  void visitDiagramReferenceNode(DiagramReferenceNode node) {
    // Diagram references are handled by the DocumentationMapper
  }

  @override
  void visitDecisionNode(DecisionNode node) {
    // Decisions are handled by the DocumentationMapper
  }
}
