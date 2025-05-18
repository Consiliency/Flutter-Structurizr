import 'package:flutter_structurizr/application/command/command.dart';
import 'package:flutter_structurizr/domain/documentation/documentation.dart';
import 'package:flutter_structurizr/domain/model/element.dart'
    as structurizr_model;
import 'package:flutter_structurizr/domain/model/deployment_node.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/domain/view/views.dart';
import 'dart:ui' show Offset;

/// A command that modifies a workspace by updating the entire workspace instance.
///
/// This is a generic command that can be used for any workspace operation
/// by providing the appropriate update function.
class WorkspaceUpdateCommand implements Command {
  final Workspace oldWorkspace;
  final Workspace newWorkspace;
  final Function(Workspace) updateWorkspace;
  final String _description;

  WorkspaceUpdateCommand(
    this.oldWorkspace,
    this.newWorkspace,
    this.updateWorkspace,
    this._description,
  );

  @override
  void execute() {
    updateWorkspace(newWorkspace);
  }

  @override
  void undo() {
    updateWorkspace(oldWorkspace);
  }

  @override
  String get description => _description;
}

/// A command that adds a person to a workspace.
class AddPersonCommand implements Command {
  final Workspace workspace;
  final Person person;
  final Function(Workspace) updateWorkspace;

  AddPersonCommand(
    this.workspace,
    this.person,
    this.updateWorkspace,
  );

  @override
  void execute() {
    final newWorkspace = workspace.addPerson(person);
    updateWorkspace(newWorkspace);
  }

  @override
  void undo() {
    final newModel = workspace.model.removePerson(person.id);
    final newWorkspace = workspace.updateModel(newModel);
    updateWorkspace(newWorkspace);
  }

  @override
  String get description => 'Add person: ${person.name}';
}

/// A command that adds a software system to a workspace.
class AddSoftwareSystemCommand implements Command {
  final Workspace workspace;
  final SoftwareSystem system;
  final Function(Workspace) updateWorkspace;

  AddSoftwareSystemCommand(
    this.workspace,
    this.system,
    this.updateWorkspace,
  );

  @override
  void execute() {
    final newWorkspace = workspace.addSoftwareSystem(system);
    updateWorkspace(newWorkspace);
  }

  @override
  void undo() {
    final newModel = workspace.model.removeSoftwareSystem(system.id);
    final newWorkspace = workspace.updateModel(newModel);
    updateWorkspace(newWorkspace);
  }

  @override
  String get description => 'Add software system: ${system.name}';
}

/// A command that adds a container to a workspace.
class AddContainerCommand implements Command {
  final Workspace workspace;
  final structurizr_model.Container container;
  final String parentSystemId;
  final Function(Workspace) updateWorkspace;

  AddContainerCommand(
    this.workspace,
    this.container,
    this.parentSystemId,
    this.updateWorkspace,
  );

  @override
  void execute() {
    final parentSystem = workspace.model.getSoftwareSystemById(parentSystemId);
    if (parentSystem == null) {
      throw CommandException('Parent software system not found');
    }

    final newModel = workspace.model.addContainer(parentSystemId, container);
    final newWorkspace = workspace.updateModel(newModel);
    updateWorkspace(newWorkspace);
  }

  @override
  void undo() {
    final newModel =
        workspace.model.removeContainer(parentSystemId, container.id);
    final newWorkspace = workspace.updateModel(newModel);
    updateWorkspace(newWorkspace);
  }

  @override
  String get description => 'Add container: ${container.name}';
}

/// A command that adds a component to a workspace.
class AddComponentCommand implements Command {
  final Workspace workspace;
  final structurizr_model.Component component;
  final String parentSystemId;
  final String parentContainerId;
  final Function(Workspace) updateWorkspace;

  AddComponentCommand(
    this.workspace,
    this.component,
    this.parentSystemId,
    this.parentContainerId,
    this.updateWorkspace,
  );

  @override
  void execute() {
    final newModel = workspace.model.addComponent(
      parentSystemId,
      parentContainerId,
      component,
    );
    final newWorkspace = workspace.updateModel(newModel);
    updateWorkspace(newWorkspace);
  }

  @override
  void undo() {
    final newModel = workspace.model.removeComponent(
      parentSystemId,
      parentContainerId,
      component.id,
    );
    final newWorkspace = workspace.updateModel(newModel);
    updateWorkspace(newWorkspace);
  }

  @override
  String get description => 'Add component: ${component.name}';
}

/// A command that adds a relationship between elements in a workspace.
class AddRelationshipToWorkspaceCommand implements Command {
  final Workspace workspace;
  final Relationship relationship;
  final Function(Workspace) updateWorkspace;

  AddRelationshipToWorkspaceCommand(
    this.workspace,
    this.relationship,
    this.updateWorkspace,
  );

  @override
  void execute() {
    final newModel = workspace.model.addRelationship(relationship);
    final newWorkspace = workspace.updateModel(newModel);
    updateWorkspace(newWorkspace);
  }

  @override
  void undo() {
    final newModel = workspace.model.removeRelationship(relationship.id);
    final newWorkspace = workspace.updateModel(newModel);
    updateWorkspace(newWorkspace);
  }

  @override
  String get description => 'Add relationship';
}

/// A command that adds a system landscape view to a workspace.
class AddSystemLandscapeViewCommand implements Command {
  final Workspace workspace;
  final SystemLandscapeView view;
  final Function(Workspace) updateWorkspace;

  AddSystemLandscapeViewCommand(
    this.workspace,
    this.view,
    this.updateWorkspace,
  );

  @override
  void execute() {
    final newWorkspace = workspace.addSystemLandscapeView(view);
    updateWorkspace(newWorkspace);
  }

  @override
  void undo() {
    final newViews = workspace.views.removeView(view.key);
    final newWorkspace = workspace.updateViews(newViews);
    updateWorkspace(newWorkspace);
  }

  @override
  String get description => 'Add system landscape view: ${view.name}';
}

/// A command that adds a system context view to a workspace.
class AddSystemContextViewCommand implements Command {
  final Workspace workspace;
  final SystemContextView view;
  final Function(Workspace) updateWorkspace;

  AddSystemContextViewCommand(
    this.workspace,
    this.view,
    this.updateWorkspace,
  );

  @override
  void execute() {
    final newWorkspace = workspace.addSystemContextView(view);
    updateWorkspace(newWorkspace);
  }

  @override
  void undo() {
    final newViews = workspace.views.removeView(view.key);
    final newWorkspace = workspace.updateViews(newViews);
    updateWorkspace(newWorkspace);
  }

  @override
  String get description => 'Add system context view: ${view.name}';
}

/// A command that adds a container view to a workspace.
class AddContainerViewCommand implements Command {
  final Workspace workspace;
  final ContainerView view;
  final Function(Workspace) updateWorkspace;

  AddContainerViewCommand(
    this.workspace,
    this.view,
    this.updateWorkspace,
  );

  @override
  void execute() {
    final newWorkspace = workspace.addContainerView(view);
    updateWorkspace(newWorkspace);
  }

  @override
  void undo() {
    final newViews = workspace.views.removeView(view.key);
    final newWorkspace = workspace.updateViews(newViews);
    updateWorkspace(newWorkspace);
  }

  @override
  String get description => 'Add container view: ${view.name}';
}

/// A command that adds a component view to a workspace.
class AddComponentViewCommand implements Command {
  final Workspace workspace;
  final ComponentView view;
  final Function(Workspace) updateWorkspace;

  AddComponentViewCommand(
    this.workspace,
    this.view,
    this.updateWorkspace,
  );

  @override
  void execute() {
    final newWorkspace = workspace.addComponentView(view);
    updateWorkspace(newWorkspace);
  }

  @override
  void undo() {
    final newViews = workspace.views.removeView(view.key);
    final newWorkspace = workspace.updateViews(newViews);
    updateWorkspace(newWorkspace);
  }

  @override
  String get description => 'Add component view: ${view.name}';
}

/// A command that adds a dynamic view to a workspace.
class AddDynamicViewCommand implements Command {
  final Workspace workspace;
  final DynamicView view;
  final Function(Workspace) updateWorkspace;

  AddDynamicViewCommand(
    this.workspace,
    this.view,
    this.updateWorkspace,
  );

  @override
  void execute() {
    final newWorkspace = workspace.addDynamicView(view);
    updateWorkspace(newWorkspace);
  }

  @override
  void undo() {
    final newViews = workspace.views.removeView(view.key);
    final newWorkspace = workspace.updateViews(newViews);
    updateWorkspace(newWorkspace);
  }

  @override
  String get description => 'Add dynamic view: ${view.name}';
}

/// A command that adds a deployment view to a workspace.
class AddDeploymentViewCommand implements Command {
  final Workspace workspace;
  final DeploymentView view;
  final Function(Workspace) updateWorkspace;

  AddDeploymentViewCommand(
    this.workspace,
    this.view,
    this.updateWorkspace,
  );

  @override
  void execute() {
    final newWorkspace = workspace.addDeploymentView(view);
    updateWorkspace(newWorkspace);
  }

  @override
  void undo() {
    final newViews = workspace.views.removeView(view.key);
    final newWorkspace = workspace.updateViews(newViews);
    updateWorkspace(newWorkspace);
  }

  @override
  String get description => 'Add deployment view: ${view.name}';
}

/// A command that updates a view's position data.
class UpdateViewPositionsCommand implements Command {
  final Workspace workspace;
  final String viewKey;
  final Map<String, Offset> oldPositions;
  final Map<String, Offset> newPositions;
  final Function(Workspace) updateWorkspace;

  UpdateViewPositionsCommand(
    this.workspace,
    this.viewKey,
    this.oldPositions,
    this.newPositions,
    this.updateWorkspace,
  );

  @override
  void execute() {
    final view = workspace.views.getViewByKey(viewKey);
    if (view == null) {
      throw CommandException('View not found: $viewKey');
    }

    View updatedView = view;
    for (final entry in newPositions.entries) {
      final elementId = entry.key;
      final position = entry.value;
      updatedView = updatedView.updateElementPosition(elementId, position);
    }

    final newViews = workspace.views.updateView(updatedView);
    final newWorkspace = workspace.updateViews(newViews);
    updateWorkspace(newWorkspace);
  }

  @override
  void undo() {
    final view = workspace.views.getViewByKey(viewKey);
    if (view == null) {
      throw CommandException('View not found: $viewKey');
    }

    View updatedView = view;
    for (final entry in oldPositions.entries) {
      final elementId = entry.key;
      final position = entry.value;
      updatedView = updatedView.updateElementPosition(elementId, position);
    }

    final newViews = workspace.views.updateView(updatedView);
    final newWorkspace = workspace.updateViews(newViews);
    updateWorkspace(newWorkspace);
  }

  @override
  String get description => 'Update positions in view: $viewKey';

  @override
  bool get canMerge => true;

  @override
  Command? mergeWith(Command other) {
    if (other is UpdateViewPositionsCommand && other.viewKey == viewKey) {
      // Merge position updates
      final mergedPositions = Map<String, Offset>.from(newPositions);
      for (final entry in other.newPositions.entries) {
        mergedPositions[entry.key] = entry.value;
      }

      return UpdateViewPositionsCommand(
        workspace,
        viewKey,
        oldPositions,
        mergedPositions,
        updateWorkspace,
      );
    }
    return null;
  }
}

/// A command that updates element styles in a workspace.
class UpdateStylesCommand implements Command {
  final Workspace workspace;
  final Styles oldStyles;
  final Styles newStyles;
  final Function(Workspace) updateWorkspace;

  UpdateStylesCommand(
    this.workspace,
    this.oldStyles,
    this.newStyles,
    this.updateWorkspace,
  );

  @override
  void execute() {
    final newWorkspace = workspace.updateStyles(newStyles);
    updateWorkspace(newWorkspace);
  }

  @override
  void undo() {
    final newWorkspace = workspace.updateStyles(oldStyles);
    updateWorkspace(newWorkspace);
  }

  @override
  String get description => 'Update styles';
}

/// A command that updates workspace documentation.
class UpdateDocumentationCommand implements Command {
  final Workspace workspace;
  final Documentation? oldDocumentation;
  final Documentation newDocumentation;
  final Function(Workspace) updateWorkspace;

  UpdateDocumentationCommand(
    this.workspace,
    this.oldDocumentation,
    this.newDocumentation,
    this.updateWorkspace,
  );

  @override
  void execute() {
    final newWorkspace = workspace.updateDocumentation(newDocumentation);
    updateWorkspace(newWorkspace);
  }

  @override
  void undo() {
    final newWorkspace = oldDocumentation != null
        ? workspace.updateDocumentation(oldDocumentation!)
        : workspace.copyWith(documentation: null);
    updateWorkspace(newWorkspace);
  }

  @override
  String get description => 'Update documentation';
}

/// A command that removes an element from a workspace.
class RemoveElementCommand implements Command {
  final Workspace workspace;
  final structurizr_model.Element element;
  final Function(Workspace) updateWorkspace;

  // Store additional state for undo
  final SoftwareSystem? parentSystem;
  final structurizr_model.Container? parentContainer;
  final List<Relationship> incomingRelationships;
  final List<Relationship> outgoingRelationships;

  RemoveElementCommand(
    this.workspace,
    this.element,
    this.updateWorkspace, {
    this.parentSystem,
    this.parentContainer,
    this.incomingRelationships = const [],
    this.outgoingRelationships = const [],
  });

  @override
  void execute() {
    Model newModel = workspace.model;

    // Remove the element based on its type
    if (element is Person) {
      newModel = newModel.removePerson(element.id);
    } else if (element is SoftwareSystem) {
      newModel = newModel.removeSoftwareSystem(element.id);
    } else if (element is structurizr_model.Container && parentSystem != null) {
      newModel = newModel.removeContainer(parentSystem!.id, element.id);
    } else if (element is structurizr_model.Component &&
        parentSystem != null &&
        parentContainer != null) {
      newModel = newModel.removeComponent(
        parentSystem!.id,
        parentContainer!.id,
        element.id,
      );
    } else if (element is DeploymentNode) {
      newModel = newModel.removeDeploymentNode(element.id);
    } else if (element is InfrastructureNode) {
      newModel = newModel.removeInfrastructureNode(element.id);
    } else {
      throw CommandException(
          'Unsupported element type: ${element.runtimeType}');
    }

    final newWorkspace = workspace.updateModel(newModel);
    updateWorkspace(newWorkspace);
  }

  @override
  void undo() {
    Model newModel = workspace.model;

    // Add the element back based on its type
    if (element is Person) {
      newModel = newModel.addPerson(element as Person);
    } else if (element is SoftwareSystem) {
      newModel = newModel.addSoftwareSystem(element as SoftwareSystem);
    } else if (element is structurizr_model.Container && parentSystem != null) {
      newModel = newModel.addContainer(
        parentSystem!.id,
        element as structurizr_model.Container,
      );
    } else if (element is structurizr_model.Component &&
        parentSystem != null &&
        parentContainer != null) {
      newModel = newModel.addComponent(
        parentSystem!.id,
        parentContainer!.id,
        element as structurizr_model.Component,
      );
    } else if (element is DeploymentNode) {
      newModel = newModel.addDeploymentNode(element as DeploymentNode);
    } else if (element is InfrastructureNode) {
      newModel = newModel.addInfrastructureNode(element as InfrastructureNode);
    } else {
      throw CommandException(
          'Unsupported element type: ${element.runtimeType}');
    }

    // Add back incoming relationships
    for (final relationship in incomingRelationships) {
      newModel = newModel.addRelationship(relationship);
    }

    // Add back outgoing relationships
    for (final relationship in outgoingRelationships) {
      newModel = newModel.addRelationship(relationship);
    }

    final newWorkspace = workspace.updateModel(newModel);
    updateWorkspace(newWorkspace);
  }

  @override
  String get description =>
      'Remove ${element.type.toLowerCase()}: ${element.name}';
}

/// A command that removes a view from a workspace.
class RemoveViewCommand implements Command {
  final Workspace workspace;
  final View view;
  final Function(Workspace) updateWorkspace;

  RemoveViewCommand(
    this.workspace,
    this.view,
    this.updateWorkspace,
  );

  @override
  void execute() {
    final newViews = workspace.views.removeView(view.key);
    final newWorkspace = workspace.updateViews(newViews);
    updateWorkspace(newWorkspace);
  }

  @override
  void undo() {
    Views newViews = workspace.views;

    // Add the view back based on its type
    if (view is SystemLandscapeView) {
      newViews = newViews.addSystemLandscapeView(view as SystemLandscapeView);
    } else if (view is SystemContextView) {
      newViews = newViews.addSystemContextView(view as SystemContextView);
    } else if (view is ContainerView) {
      newViews = newViews.addContainerView(view as ContainerView);
    } else if (view is ComponentView) {
      newViews = newViews.addComponentView(view as ComponentView);
    } else if (view is DynamicView) {
      newViews = newViews.addDynamicView(view as DynamicView);
    } else if (view is DeploymentView) {
      newViews = newViews.addDeploymentView(view as DeploymentView);
    } else if (view is FilteredView) {
      newViews = newViews.addFilteredView(view as FilteredView);
    } else if (view is ImageView) {
      newViews = newViews.addImageView(view as ImageView);
    } else if (view is CustomView) {
      newViews = newViews.addCustomView(view as CustomView);
    } else {
      throw CommandException('Unsupported view type: ${view.runtimeType}');
    }

    final newWorkspace = workspace.updateViews(newViews);
    updateWorkspace(newWorkspace);
  }

  @override
  String get description => 'Remove view: ${view.name}';
}
