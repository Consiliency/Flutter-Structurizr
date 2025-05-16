import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/relationship.dart';
import 'package:flutter_structurizr/domain/model/software_system.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/parser/reference_resolver.dart';
import 'package:flutter_structurizr/domain/parser/ast/ast.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/application/dsl/workspace_builder.dart';

/// Parser for system context views in the Structurizr DSL.
///
/// This parser transforms `SystemContextViewNode` AST nodes into
/// `SystemContextView` model objects, handling element inclusion/exclusion,
/// default population, and advanced features.
class SystemContextViewParser {
  /// Error reporter for reporting semantic errors.
  final ErrorReporter errorReporter;
  
  /// Reference resolver for resolving element references.
  final ReferenceResolver referenceResolver;
  
  /// Creates a new system context view parser.
  SystemContextViewParser({
    required this.errorReporter,
    required this.referenceResolver,
  });
  
  /// Parses a system context view node and returns a system context view.
  ///
  /// This method handles the transformation from AST node to model object,
  /// including resolving references, handling inclusion/exclusion rules,
  /// and populating default elements and relationships.
  ///
  /// @param viewNode The AST node to parse.
  /// @param workspaceBuilder The workspace builder to use for resolving references.
  /// @return The parsed system context view.
  SystemContextView? parse(SystemContextViewNode viewNode, WorkspaceBuilder workspaceBuilder) {
    // Resolve the software system reference
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
      return null;
    }
    
    // Initialize element and relationship views
    final elementViews = <ElementView>[];
    final relationshipViews = <RelationshipView>[];
    
    // Convert include/exclude rules to lists of tags
    final includes = viewNode.includes.map((include) => include.expression).toList();
    final excludes = viewNode.excludes.map((exclude) => exclude.expression).toList();
    
    // Process include and exclude rules
    if (includes.contains('*')) {
      // Handle the "include all" case
      handleIncludeAll(viewNode, softwareSystem, elementViews, relationshipViews);
    } else if (includes.isNotEmpty || excludes.isNotEmpty) {
      // Handle specific include/exclude rules
      handleIncludeExclude(viewNode, softwareSystem, elementViews, relationshipViews);
    } else {
      // No explicit include/exclude rules, add default elements and relationships
      populateDefaults(viewNode, softwareSystem, elementViews, relationshipViews);
    }
    
    // Add default elements (like the software system itself)
    workspaceBuilder.addDefaultElements(viewNode);
    
    // Add any implied relationships between elements in the view
    workspaceBuilder.addImpliedRelationships();
    
    // Apply advanced features and options
    setAdvancedFeatures(viewNode, elementViews, relationshipViews);
    
    // Create and return the view
    return SystemContextView(
      key: viewNode.key,
      softwareSystemId: softwareSystem.id,
      title: viewNode.title ?? '${softwareSystem.name} - System Context',
      description: viewNode.description,
      elements: elementViews,
      relationships: relationshipViews,
      automaticLayout: viewNode.autoLayout != null ? AutomaticLayout(
        rankDirection: viewNode.autoLayout!.rankDirection ?? 'TB',
        rankSeparation: viewNode.autoLayout!.rankSeparation ?? 300,
        nodeSeparation: viewNode.autoLayout!.nodeSeparation ?? 300,
      ) : null,
      animations: viewNode.animations.map((animation) => AnimationStep(
        order: animation.order,
        elements: animation.elements,
        relationships: animation.relationships,
      )).toList(),
      includeTags: includes,
      excludeTags: excludes,
    );
  }
  
  /// Handles the case where "*" is used to include all elements.
  ///
  /// This method populates the view with all relevant elements and relationships
  /// when the include "*" rule is used.
  ///
  /// @param viewNode The AST node being parsed.
  /// @param softwareSystem The software system for this view.
  /// @param elementViews The list to populate with element views.
  /// @param relationshipViews The list to populate with relationship views.
  void handleIncludeAll(
    SystemContextViewNode viewNode,
    SoftwareSystem softwareSystem,
    List<ElementView> elementViews,
    List<RelationshipView> relationshipViews
  ) {
    // Add the software system itself
    elementViews.add(ElementView(id: softwareSystem.id));
    viewNode.addElement(ElementNode(id: softwareSystem.id, name: softwareSystem.name));
    
    // Get all elements in the model through reference resolver
    final allElements = referenceResolver.getAllElements();
    
    // Add all people
    for (final element in allElements.values) {
      if (element.runtimeType.toString() == 'Person') {
        elementViews.add(ElementView(id: element.id));
        viewNode.addElement(ElementNode(id: element.id, name: element.name));
        
        // Add relationships to and from this person
        for (final rel in element.relationships) {
          if (rel.destinationId == softwareSystem.id) {
            relationshipViews.add(RelationshipView(id: rel.id));
          }
        }
        
        for (final rel in softwareSystem.relationships) {
          if (rel.destinationId == element.id) {
            relationshipViews.add(RelationshipView(id: rel.id));
          }
        }
      }
    }
    
    // Add all other software systems
    for (final element in allElements.values) {
      if (element.runtimeType.toString() == 'SoftwareSystem' && element.id != softwareSystem.id) {
        elementViews.add(ElementView(id: element.id));
        viewNode.addElement(ElementNode(id: element.id, name: element.name));
        
        // Add relationships to and from this system
        for (final rel in element.relationships) {
          if (rel.destinationId == softwareSystem.id) {
            relationshipViews.add(RelationshipView(id: rel.id));
          }
        }
        
        for (final rel in softwareSystem.relationships) {
          if (rel.destinationId == element.id) {
            relationshipViews.add(RelationshipView(id: rel.id));
          }
        }
      }
    }
  }
  
  /// Handles specific include/exclude rules for the view.
  ///
  /// This method processes include and exclude expressions to filter
  /// which elements and relationships appear in the view.
  ///
  /// @param viewNode The AST node being parsed.
  /// @param softwareSystem The software system for this view.
  /// @param elementViews The list to populate with element views.
  /// @param relationshipViews The list to populate with relationship views.
  void handleIncludeExclude(
    SystemContextViewNode viewNode,
    SoftwareSystem softwareSystem,
    List<ElementView> elementViews,
    List<RelationshipView> relationshipViews
  ) {
    // Always include the software system itself
    elementViews.add(ElementView(id: softwareSystem.id));
    viewNode.addElement(ElementNode(id: softwareSystem.id, name: softwareSystem.name));
    
    // Convert include/exclude rules to lists of tags
    final includes = viewNode.includes.map((include) => include.expression).toList();
    final excludes = viewNode.excludes.map((exclude) => exclude.expression).toList();
    
    // Get all elements in the model through reference resolver
    final allElements = referenceResolver.getAllElements();
    
    // Process people based on include/exclude rules
    for (final element in allElements.values) {
      if (element.runtimeType.toString() == 'Person') {
        bool shouldInclude = false;
        
        // Check if element matches include rules
        if (includes.isNotEmpty) {
          for (final includeTag in includes) {
            if (element.hasTag(includeTag) || element.id == includeTag || element.name == includeTag) {
              shouldInclude = true;
              break;
            }
          }
        }
        
        // Check if element matches exclude rules
        if (excludes.isNotEmpty) {
          for (final excludeTag in excludes) {
            if (element.hasTag(excludeTag) || element.id == excludeTag || element.name == excludeTag) {
              shouldInclude = false;
              break;
            }
          }
        }
        
        if (shouldInclude) {
          elementViews.add(ElementView(id: element.id));
          viewNode.addElement(ElementNode(id: element.id, name: element.name));
          
          // Add relationships between this element and the system
          for (final rel in element.relationships) {
            if (rel.destinationId == softwareSystem.id) {
              relationshipViews.add(RelationshipView(id: rel.id));
            }
          }
          
          for (final rel in softwareSystem.relationships) {
            if (rel.destinationId == element.id) {
              relationshipViews.add(RelationshipView(id: rel.id));
            }
          }
        }
      }
    }
    
    // Process other software systems based on include/exclude rules
    for (final element in allElements.values) {
      if (element.runtimeType.toString() == 'SoftwareSystem' && element.id != softwareSystem.id) {
        bool shouldInclude = false;
        
        // Check if system matches include rules
        if (includes.isNotEmpty) {
          for (final includeTag in includes) {
            if (element.hasTag(includeTag) || element.id == includeTag || element.name == includeTag) {
              shouldInclude = true;
              break;
            }
          }
        }
        
        // Check if system matches exclude rules
        if (excludes.isNotEmpty) {
          for (final excludeTag in excludes) {
            if (element.hasTag(excludeTag) || element.id == excludeTag || element.name == excludeTag) {
              shouldInclude = false;
              break;
            }
          }
        }
        
        if (shouldInclude) {
          elementViews.add(ElementView(id: element.id));
          viewNode.addElement(ElementNode(id: element.id, name: element.name));
          
          // Add relationships between this system and the other system
          for (final rel in element.relationships) {
            if (rel.destinationId == softwareSystem.id) {
              relationshipViews.add(RelationshipView(id: rel.id));
            }
          }
          
          for (final rel in softwareSystem.relationships) {
            if (rel.destinationId == element.id) {
              relationshipViews.add(RelationshipView(id: rel.id));
            }
          }
        }
      }
    }
  }
  
  /// Populates default elements and relationships for the view.
  ///
  /// This method is called when no explicit include/exclude rules are specified,
  /// and adds elements and relationships that make sense by default in a
  /// system context view.
  ///
  /// @param viewNode The AST node being parsed.
  /// @param softwareSystem The software system for this view.
  /// @param elementViews The list to populate with element views.
  /// @param relationshipViews The list to populate with relationship views.
  void populateDefaults(
    SystemContextViewNode viewNode,
    SoftwareSystem softwareSystem,
    List<ElementView> elementViews,
    List<RelationshipView> relationshipViews
  ) {
    // Add the software system itself
    elementViews.add(ElementView(id: softwareSystem.id));
    viewNode.addElement(ElementNode(id: softwareSystem.id, name: softwareSystem.name));
    
    // Get all elements in the model through reference resolver
    final allElements = referenceResolver.getAllElements();
    
    // Add all people who have relationships to/from this system
    for (final element in allElements.values) {
      if (element.runtimeType.toString() == 'Person') {
        bool hasRelationship = false;
        
        // Check for relationships to the software system
        for (final rel in element.relationships) {
          if (rel.destinationId == softwareSystem.id) {
            hasRelationship = true;
            relationshipViews.add(RelationshipView(id: rel.id));
          }
        }
        
        // Check for relationships from the software system
        for (final rel in softwareSystem.relationships) {
          if (rel.destinationId == element.id) {
            hasRelationship = true;
            relationshipViews.add(RelationshipView(id: rel.id));
          }
        }
        
        if (hasRelationship) {
          elementViews.add(ElementView(id: element.id));
          viewNode.addElement(ElementNode(id: element.id, name: element.name));
        }
      }
    }
    
    // Add all other software systems that have relationships to/from this system
    for (final element in allElements.values) {
      if (element.runtimeType.toString() == 'SoftwareSystem' && element.id != softwareSystem.id) {
        bool hasRelationship = false;
        
        // Check for relationships to the software system
        for (final rel in element.relationships) {
          if (rel.destinationId == softwareSystem.id) {
            hasRelationship = true;
            relationshipViews.add(RelationshipView(id: rel.id));
          }
        }
        
        // Check for relationships from the software system
        for (final rel in softwareSystem.relationships) {
          if (rel.destinationId == element.id) {
            hasRelationship = true;
            relationshipViews.add(RelationshipView(id: rel.id));
          }
        }
        
        if (hasRelationship) {
          elementViews.add(ElementView(id: element.id));
          viewNode.addElement(ElementNode(id: element.id, name: element.name));
        }
      }
    }
  }
  
  /// Sets advanced features and options for the view.
  ///
  /// This method applies additional configuration and features to the view,
  /// such as element styles, layout customization, or view-specific properties.
  ///
  /// @param viewNode The AST node being parsed.
  /// @param elementViews The list of element views.
  /// @param relationshipViews The list of relationship views.
  void setAdvancedFeatures(
    SystemContextViewNode viewNode,
    List<ElementView> elementViews,
    List<RelationshipView> relationshipViews
  ) {
    // Apply element properties from the viewNode's properties if they exist
    if (viewNode.properties != null) {
      for (final property in viewNode.properties!.properties) {
        final key = property.key;
        final value = property.value;
        
        if (key == null || value == null) continue;
        
        // Apply property to all elements or specific elements based on the key
        if (key.startsWith('element.')) {
          // Format: element.<id>.<property> = <value>
          final parts = key.split('.');
          if (parts.length >= 3) {
            final elementId = parts[1];
            final propertyName = parts.sublist(2).join('.');
            
            // Find the element view and update properties
            for (var i = 0; i < elementViews.length; i++) {
              if (elementViews[i].id == elementId) {
                // Update element view with the property
                final updatedView = elementViews[i].copyWith(
                  properties: {...elementViews[i].properties, propertyName: value}
                );
                elementViews[i] = updatedView;
                break;
              }
            }
          }
        } else if (key.startsWith('relationship.')) {
          // Format: relationship.<id>.<property> = <value>
          final parts = key.split('.');
          if (parts.length >= 3) {
            final relationshipId = parts[1];
            final propertyName = parts.sublist(2).join('.');
            
            // Find the relationship view and update properties
            for (var i = 0; i < relationshipViews.length; i++) {
              if (relationshipViews[i].id == relationshipId) {
                // Update relationship view with the property
                final updatedView = relationshipViews[i].copyWith(
                  properties: {...relationshipViews[i].properties, propertyName: value}
                );
                relationshipViews[i] = updatedView;
                break;
              }
            }
          }
        }
      }
    }
    
    // Apply animation properties
    for (var i = 0; i < viewNode.animations.length; i++) {
      final animation = viewNode.animations[i];
      
      // Ensure animation steps are sequential
      if (animation.order <= 0) {
        errorReporter.reportWarning(
          'Animation order should be positive: ${animation.order}',
          animation.sourcePosition?.offset ?? 0
        );
      }
    }
  }
}