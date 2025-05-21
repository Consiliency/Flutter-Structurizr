import 'package:flutter_structurizr/domain/model/software_system.dart';
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/parser/ast/ast.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/parser/reference_resolver.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/application/dsl/workspace_builder.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/system_context_view_node.dart'
    show SystemContextViewNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/model_element_node.dart'
    show ElementNode;

/// Parser for system context views in the DSL.
class SystemContextViewParser {
  /// The error reporter for semantic errors
  final ErrorReporter errorReporter;

  /// The reference resolver for handling element references
  final ReferenceResolver referenceResolver;

  /// Creates a new system context view parser
  SystemContextViewParser({
    required this.errorReporter,
    required this.referenceResolver,
  });

  /// Parses and builds a system context view from an AST node
  SystemContextView? parse(
      SystemContextViewNode node, WorkspaceBuilder builder) {
    // Resolve the system reference
    final softwareSystem = referenceResolver.resolveReference(
      node.systemId,
      sourcePosition: node.sourcePosition,
      searchByName: true,
      expectedType: SoftwareSystem,
    ) as SoftwareSystem?;

    if (softwareSystem == null) {
      // List all available software system IDs and names
      final allSystems = referenceResolver
          .getAllElements()
          .values
          .where((e) => e.runtimeType.toString() == 'SoftwareSystem');
      final availableIds = allSystems
          .map((sys) => 'id: ${sys.id}, name: ${sys.name}')
          .join('; ');

      errorReporter.reportStandardError(
        'Software system not found for system context view: ${node.key}, systemId: ${node.systemId}\n'
        'Available software system IDs: $availableIds',
        node.sourcePosition?.offset ?? 0,
      );
      return null;
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

    // Calculate element views and relationship views based on include/exclude criteria
    final model = builder.workspace?.model;
    if (model == null) {
      errorReporter.reportStandardError(
        'Model not found for system context view: ${node.key}',
        node.sourcePosition?.offset ?? 0,
      );
      return null;
    }

    // Populate elements and relationships based on include/exclude rules
    final elementViews = <ElementView>[];
    final relationshipViews = <RelationshipView>[];

    if (includes.contains('*')) {
      // Include all elements in scope
      handleIncludeAll(node);
    } else if (!includes.isEmpty || !excludes.isEmpty) {
      // Handle specific include/exclude expressions
      handleIncludeExclude(node);
    } else {
      // Default population behavior - add the system itself
      elementViews.add(ElementView(id: softwareSystem.id));

      // Add all people who have relationships to/from this system
      for (final person in model.people) {
        final relsTo = person.getRelationshipsTo(softwareSystem.id);
        final relsFrom = softwareSystem.getRelationshipsTo(person.id);
        if (relsTo.isNotEmpty || relsFrom.isNotEmpty) {
          elementViews.add(ElementView(id: person.id));
          for (final rel in relsTo) {
            relationshipViews.add(RelationshipView(id: rel.id));
          }
          for (final rel in relsFrom) {
            relationshipViews.add(RelationshipView(id: rel.id));
          }
        }
      }

      // Add all other software systems that have relationships to/from this system
      for (final otherSystem in model.softwareSystems) {
        if (otherSystem.id == softwareSystem.id) continue;
        final relsTo = otherSystem.getRelationshipsTo(softwareSystem.id);
        final relsFrom = softwareSystem.getRelationshipsTo(otherSystem.id);
        if (relsTo.isNotEmpty || relsFrom.isNotEmpty) {
          elementViews.add(ElementView(id: otherSystem.id));
          for (final rel in relsTo) {
            relationshipViews.add(RelationshipView(id: rel.id));
          }
          for (final rel in relsFrom) {
            relationshipViews.add(RelationshipView(id: rel.id));
          }
        }
      }
    }

    // Populate default values
    populateDefaults(node);

    // Set advanced features
    setAdvancedFeatures(node);

    // Determine the view title
    final resolvedTitle = (node.title?.isNotEmpty == true)
        ? node.title
        : ((softwareSystem.name.isNotEmpty)
            ? '${softwareSystem.name} - System Context'
            : 'System Context');

    // Create and return the view
    return SystemContextView(
      key: node.key,
      softwareSystemId: softwareSystem.id,
      title: resolvedTitle,
      description: node.description,
      elements: elementViews,
      relationships: relationshipViews,
      automaticLayout: automaticLayout,
      animations: animationSteps,
      includeTags: includes?.cast<String>() ?? [],
      excludeTags: excludes?.cast<String>() ?? [],
    );
  }

  /// Handles the "include *" rule by adding all relevant elements
  void handleIncludeAll(SystemContextViewNode viewNode) {
    // Get the software system
    final softwareSystem = referenceResolver.resolveReference(
      viewNode.systemId,
      sourcePosition: viewNode.sourcePosition,
      searchByName: true,
      expectedType: SoftwareSystem,
    ) as SoftwareSystem?;

    if (softwareSystem == null) return;

    // Add the software system itself
    viewNode.addElement(
        ElementNode(id: softwareSystem.id, name: softwareSystem.name));

    // Get the model
    final model = referenceResolver.getModel();
    if (model == null) return;

    // Add all people in the model
    for (final person in model.people) {
      viewNode.addElement(ElementNode(id: person.id, name: person.name));
    }

    // Add all other software systems
    for (final otherSystem in model.softwareSystems) {
      if (otherSystem.id != softwareSystem.id) {
        viewNode.addElement(
            ElementNode(id: otherSystem.id, name: otherSystem.name));
      }
    }
  }

  /// Handles specific include/exclude tag expressions
  void handleIncludeExclude(SystemContextViewNode viewNode) {
    // Get the software system
    final softwareSystem = referenceResolver.resolveReference(
      viewNode.systemId,
      sourcePosition: viewNode.sourcePosition,
      searchByName: true,
      expectedType: SoftwareSystem,
    ) as SoftwareSystem?;

    if (softwareSystem == null) return;

    // Add the software system itself
    viewNode.addElement(
        ElementNode(id: softwareSystem.id, name: softwareSystem.name));

    // Get the model
    final model = referenceResolver.getModel();
    if (model == null) return;

    // Get include and exclude expressions
    final includes =
        viewNode.includes.map((include) => include.expression).toList();
    final excludes =
        viewNode.excludes.map((exclude) => exclude.expression).toList();

    // Filter people based on tags
    for (final person in model.people) {
      bool shouldInclude = false;

      // Check includes
      if (includes.isEmpty) {
        shouldInclude = true; // No includes means include everything
      } else {
        for (final tag in person.tags) {
          if (includes.contains(tag)) {
            shouldInclude = true;
            break;
          }
        }
      }

      // Check excludes
      for (final tag in person.tags) {
        if (excludes.contains(tag)) {
          shouldInclude = false;
          break;
        }
      }

      if (shouldInclude) {
        viewNode.addElement(ElementNode(id: person.id, name: person.name));
      }
    }

    // Filter software systems based on tags
    for (final otherSystem in model.softwareSystems) {
      if (otherSystem.id == softwareSystem.id) continue;

      bool shouldInclude = false;

      // Check includes
      if (includes.isEmpty) {
        shouldInclude = true; // No includes means include everything
      } else {
        for (final tag in otherSystem.tags) {
          if (includes.contains(tag)) {
            shouldInclude = true;
            break;
          }
        }
      }

      // Check excludes
      for (final tag in otherSystem.tags) {
        if (excludes.contains(tag)) {
          shouldInclude = false;
          break;
        }
      }

      if (shouldInclude) {
        viewNode.addElement(
            ElementNode(id: otherSystem.id, name: otherSystem.name));
      }
    }
  }

  /// Populates default values for the view
  void populateDefaults(SystemContextViewNode viewNode) {
    // Get the software system
    final softwareSystem = referenceResolver.resolveReference(
      viewNode.systemId,
      sourcePosition: viewNode.sourcePosition,
      searchByName: true,
      expectedType: SoftwareSystem,
    ) as SoftwareSystem?;

    if (softwareSystem == null) return;

    // Always ensure the central software system is included
    if (!viewNode.hasElement(softwareSystem.id)) {
      viewNode.addElement(
          ElementNode(id: softwareSystem.id, name: softwareSystem.name));
    }

    // Set default paper size if not specified
    if (!viewNode.hasProperty('paperSize')) {
      viewNode.setProperty('paperSize', 'A4_Landscape');
    }

    // Set default auto-layout if not specified
    if (viewNode.autoLayout == null) {
      // This would be done at the model level rather than node level
      // since the AST node doesn't support adding this after creation
    }
  }

  /// Sets advanced features for the view
  void setAdvancedFeatures(SystemContextViewNode viewNode) {
    // Set enterprise boundary by default if enterprise name is defined
    final model = referenceResolver.getModel();
    if (model?.enterprise != null && model!.enterprise!.name.isNotEmpty) {
      viewNode.setProperty('showEnterpriseBoundary', 'true');
    }

    // Set other advanced properties if needed
    viewNode.setProperty('lastLayoutDate', DateTime.now().toIso8601String());
  }
}
