import 'package:flutter/widgets.dart';
import 'package:flutter_structurizr/application/command/workspace_commands.dart';
import 'package:flutter_structurizr/domain/documentation/documentation.dart';
import 'package:flutter_structurizr/domain/model/person.dart';
import 'package:flutter_structurizr/domain/model/software_system.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkspaceUpdateCommand', () {
    test('executes by updating the workspace', () {
      // Arrange
      Workspace? currentWorkspace = Workspace(
        id: 1,
        name: 'Test Workspace',
        model: makeModel(),
      );

      final newWorkspace = Workspace(
        id: 1,
        name: 'Updated Workspace',
        model: makeModel(),
      );

      void updateWorkspace(Workspace workspace) {
        currentWorkspace = workspace;
      }

      final command = WorkspaceUpdateCommand(
        currentWorkspace!,
        newWorkspace,
        updateWorkspace,
        'Update workspace name',
      );

      // Act
      command.execute();

      // Assert
      expect(currentWorkspace, equals(newWorkspace));
      expect(currentWorkspace?.name, equals('Updated Workspace'));
    });

    test('undoes by restoring the original workspace', () {
      // Arrange
      Workspace? currentWorkspace = Workspace(
        id: 1,
        name: 'Test Workspace',
        model: makeModel(),
      );

      final originalWorkspace = currentWorkspace;

      final newWorkspace = Workspace(
        id: 1,
        name: 'Updated Workspace',
        model: makeModel(),
      );

      void updateWorkspace(Workspace workspace) {
        currentWorkspace = workspace;
      }

      final command = WorkspaceUpdateCommand(
        originalWorkspace,
        newWorkspace,
        updateWorkspace,
        'Update workspace name',
      );

      // Act
      command.execute();
      command.undo();

      // Assert
      expect(currentWorkspace, equals(originalWorkspace));
      expect(currentWorkspace?.name, equals('Test Workspace'));
    });
  });

  group('AddPersonCommand', () {
    test('executes by adding a person to the workspace', () {
      // Arrange
      Workspace? currentWorkspace = Workspace(
        id: 1,
        name: 'Test Workspace',
        model: makeModel(),
      );

      const person = Person(
        id: 'person1',
        name: 'Test Person',
      );

      void updateWorkspace(Workspace workspace) {
        currentWorkspace = workspace;
      }

      final command = AddPersonCommand(
        currentWorkspace!,
        person,
        updateWorkspace,
      );

      // Act
      command.execute();

      // Assert
      expect(currentWorkspace?.model.people.length, equals(1));
      expect(currentWorkspace?.model.people.first.name, equals('Test Person'));
    });

    test('undoes by removing the person from the workspace', () {
      // Arrange
      Workspace? currentWorkspace = Workspace(
        id: 1,
        name: 'Test Workspace',
        model: makeModel(),
      );

      const person = Person(
        id: 'person1',
        name: 'Test Person',
      );

      void updateWorkspace(Workspace workspace) {
        currentWorkspace = workspace;
      }

      final command = AddPersonCommand(
        currentWorkspace!,
        person,
        updateWorkspace,
      );

      // Act
      command.execute();
      command.undo();

      // Assert
      expect(currentWorkspace?.model.people.length, equals(0));
    });
  });

  group('AddSoftwareSystemCommand', () {
    test('executes by adding a software system to the workspace', () {
      // Arrange
      Workspace? currentWorkspace = Workspace(
        id: 1,
        name: 'Test Workspace',
        model: makeModel(),
      );

      const system = SoftwareSystem(
        id: 'system1',
        name: 'Test System',
      );

      void updateWorkspace(Workspace workspace) {
        currentWorkspace = workspace;
      }

      final command = AddSoftwareSystemCommand(
        currentWorkspace!,
        system,
        updateWorkspace,
      );

      // Act
      command.execute();

      // Assert
      expect(currentWorkspace?.model.softwareSystems.length, equals(1));
      expect(currentWorkspace?.model.softwareSystems.first.name,
          equals('Test System'));
    });

    test('undoes by removing the software system from the workspace', () {
      // Arrange
      Workspace? currentWorkspace = Workspace(
        id: 1,
        name: 'Test Workspace',
        model: makeModel(),
      );

      const system = SoftwareSystem(
        id: 'system1',
        name: 'Test System',
      );

      void updateWorkspace(Workspace workspace) {
        currentWorkspace = workspace;
      }

      final command = AddSoftwareSystemCommand(
        currentWorkspace!,
        system,
        updateWorkspace,
      );

      // Act
      command.execute();
      command.undo();

      // Assert
      expect(currentWorkspace?.model.softwareSystems.length, equals(0));
    });
  });

  group('UpdateStylesCommand', () {
    test('executes by updating the styles in the workspace', () {
      // Arrange
      Workspace? currentWorkspace = Workspace(
        id: 1,
        name: 'Test Workspace',
        model: makeModel(),
      );

      final originalStyles = currentWorkspace.styles;

      const newStyles = Styles(
        elements: [
          ElementStyle(
            tag: 'Person',
            shape: Shape.person,
            color: '#FF0000',
          ),
        ],
      );

      void updateWorkspace(Workspace workspace) {
        currentWorkspace = workspace;
      }

      final command = UpdateStylesCommand(
        currentWorkspace,
        originalStyles,
        newStyles,
        updateWorkspace,
      );

      // Act
      command.execute();

      // Assert
      expect(currentWorkspace?.styles, equals(newStyles));
      expect(currentWorkspace?.styles.elements.length, equals(1));
      expect(currentWorkspace?.styles.elements.first.tag, equals('Person'));
    });

    test('undoes by restoring the original styles', () {
      // Arrange
      Workspace? currentWorkspace = Workspace(
        id: 1,
        name: 'Test Workspace',
        model: makeModel(),
      );

      final originalStyles = currentWorkspace.styles;

      const newStyles = Styles(
        elements: [
          ElementStyle(
            tag: 'Person',
            shape: Shape.person,
            color: '#FF0000',
          ),
        ],
      );

      void updateWorkspace(Workspace workspace) {
        currentWorkspace = workspace;
      }

      final command = UpdateStylesCommand(
        currentWorkspace,
        originalStyles,
        newStyles,
        updateWorkspace,
      );

      // Act
      command.execute();
      command.undo();

      // Assert
      expect(currentWorkspace?.styles, equals(originalStyles));
      expect(currentWorkspace?.styles.elements.length, equals(0));
    });
  });

  group('UpdateDocumentationCommand', () {
    test('executes by updating the documentation in the workspace', () {
      // Arrange
      Workspace? currentWorkspace = Workspace(
        id: 1,
        name: 'Test Workspace',
        model: makeModel(),
      );

      final originalDoc = currentWorkspace.documentation;

      const newDoc = Documentation(
        content: 'Test documentation',
      );

      void updateWorkspace(Workspace workspace) {
        currentWorkspace = workspace;
      }

      final command = UpdateDocumentationCommand(
        currentWorkspace,
        originalDoc,
        newDoc,
        updateWorkspace,
      );

      // Act
      command.execute();

      // Assert
      expect(currentWorkspace?.documentation, equals(newDoc));
      expect(currentWorkspace?.documentation?.content,
          equals('Test documentation'));
    });

    test('undoes by restoring the original documentation', () {
      // Arrange
      Workspace? currentWorkspace = Workspace(
        id: 1,
        name: 'Test Workspace',
        model: makeModel(),
        documentation: const Documentation(content: 'Original documentation'),
      );

      final originalDoc = currentWorkspace.documentation;

      const newDoc = Documentation(
        content: 'Test documentation',
      );

      void updateWorkspace(Workspace workspace) {
        currentWorkspace = workspace;
      }

      final command = UpdateDocumentationCommand(
        currentWorkspace,
        originalDoc,
        newDoc,
        updateWorkspace,
      );

      // Act
      command.execute();
      command.undo();

      // Assert
      expect(currentWorkspace?.documentation, equals(originalDoc));
      expect(currentWorkspace?.documentation?.content,
          equals('Original documentation'));
    });
  });

  group('UpdateViewPositionsCommand', () {
    test('executes by updating element positions in a view', () {
      // Arrange
      const systemContextView = SystemContextView(
        softwareSystemId: 'system1',
        key: 'systemContext',
        description: 'Test View',
        elements: {
          'person1': const ElementView(id: 'person1', x: 0, y: 0),
          'system1': const ElementView(id: 'system1', x: 0, y: 0),
        },
      );

      Workspace? currentWorkspace = Workspace(
        id: 1,
        name: 'Test Workspace',
        model: makeModel(),
        views: Views(
          systemContextViews: [systemContextView],
        ),
      );

      final oldPositions = {
        'person1': const Offset(0, 0),
        'system1': const Offset(0, 0),
      };

      final newPositions = {
        'person1': const Offset(100, 100),
        'system1': const Offset(200, 200),
      };

      void updateWorkspace(Workspace workspace) {
        currentWorkspace = workspace;
      }

      final command = UpdateViewPositionsCommand(
        currentWorkspace,
        'systemContext',
        oldPositions,
        newPositions,
        updateWorkspace,
      );

      // Act
      command.execute();

      // Assert
      final updatedView = currentWorkspace?.views.getViewByKey('systemContext')
          as SystemContextView?;
      expect(updatedView?.elements['person1'].x, equals(100));
      expect(updatedView?.elements['person1'].y, equals(100));
      expect(updatedView?.elements['system1'].x, equals(200));
      expect(updatedView?.elements['system1'].y, equals(200));
    });

    test('undoes by restoring the original positions', () {
      // Arrange
      const systemContextView = SystemContextView(
        softwareSystemId: 'system1',
        key: 'systemContext',
        description: 'Test View',
        elements: {
          'person1': const ElementView(id: 'person1', x: 0, y: 0),
          'system1': const ElementView(id: 'system1', x: 0, y: 0),
        },
      );

      Workspace? currentWorkspace = Workspace(
        id: 1,
        name: 'Test Workspace',
        model: makeModel(),
        views: Views(
          systemContextViews: [systemContextView],
        ),
      );

      final oldPositions = {
        'person1': const Offset(0, 0),
        'system1': const Offset(0, 0),
      };

      final newPositions = {
        'person1': const Offset(100, 100),
        'system1': const Offset(200, 200),
      };

      void updateWorkspace(Workspace workspace) {
        currentWorkspace = workspace;
      }

      final command = UpdateViewPositionsCommand(
        currentWorkspace,
        'systemContext',
        oldPositions,
        newPositions,
        updateWorkspace,
      );

      // Act
      command.execute();
      command.undo();

      // Assert
      final updatedView = currentWorkspace?.views.getViewByKey('systemContext')
          as SystemContextView?;
      expect(updatedView?.elements['person1'].x, equals(0));
      expect(updatedView?.elements['person1'].y, equals(0));
      expect(updatedView?.elements['system1'].x, equals(0));
      expect(updatedView?.elements['system1'].y, equals(0));
    });

    test('merges with another UpdateViewPositionsCommand', () {
      // Arrange
      const systemContextView = SystemContextView(
        softwareSystemId: 'system1',
        key: 'systemContext',
        description: 'Test View',
        elements: {
          'person1': const ElementView(id: 'person1', x: 0, y: 0),
          'system1': const ElementView(id: 'system1', x: 0, y: 0),
        },
      );

      Workspace? currentWorkspace = Workspace(
        id: 1,
        name: 'Test Workspace',
        model: makeModel(),
        views: Views(
          systemContextViews: [systemContextView],
        ),
      );

      void updateWorkspace(Workspace workspace) {
        currentWorkspace = workspace;
      }

      final command1 = UpdateViewPositionsCommand(
        currentWorkspace,
        'systemContext',
        {
          'person1': const Offset(0, 0),
        },
        {
          'person1': const Offset(100, 100),
        },
        updateWorkspace,
      );

      final command2 = UpdateViewPositionsCommand(
        currentWorkspace,
        'systemContext',
        {
          'system1': const Offset(0, 0),
        },
        {
          'system1': const Offset(200, 200),
        },
        updateWorkspace,
      );

      // Act
      final mergedCommand =
          command1.mergeWith(command2) as UpdateViewPositionsCommand?;

      // Assert
      expect(mergedCommand, isNotNull);
      expect(mergedCommand?.newPositions.length, equals(2));
      expect(mergedCommand?.newPositions['person1'],
          equals(const Offset(100, 100)));
      expect(mergedCommand?.newPositions['system1'],
          equals(const Offset(200, 200)));
    });
  });
}

/// Creates a basic model for testing.
Model makeModel() {
  return const Model(
    people: [],
    softwareSystems: [],
    deploymentEnvironments: [],
  );
}
