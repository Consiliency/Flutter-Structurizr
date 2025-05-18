import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/model/model.dart';

void main() {
  group('Workspace', () {
    test('creates a workspace with required properties', () {
      const model = Model();

      const workspace = Workspace(
        id: 1,
        name: 'Test Workspace',
        model: model,
      );

      expect(workspace.id, equals(1));
      expect(workspace.name, equals('Test Workspace'));
      expect(workspace.description, isNull);
      expect(workspace.version, isNull);
      expect(workspace.model, equals(model));
      expect(workspace.configuration, isNull);
    });

    test('creates a workspace with all properties', () {
      const model = Model(enterpriseName: 'Test Enterprise');

      final configuration = WorkspaceConfiguration(
        properties: {'key': 'value'},
        lastModifiedDate: DateTime(2023, 1, 1),
        lastModifiedUser: 'User',
        lastModifiedAgent: 'Agent',
      );

      final workspace = Workspace(
        id: 1,
        name: 'Test Workspace',
        description: 'A test workspace',
        version: '1.0',
        model: model,
        configuration: configuration,
      );

      expect(workspace.id, equals(1));
      expect(workspace.name, equals('Test Workspace'));
      expect(workspace.description, equals('A test workspace'));
      expect(workspace.version, equals('1.0'));
      expect(workspace.model, equals(model));
      expect(workspace.configuration, equals(configuration));
    });

    test('validates with no errors for valid workspace', () {
      const model = Model();

      const workspace = Workspace(
        id: 1,
        name: 'Test Workspace',
        model: model,
      );

      final errors = workspace.validate();

      expect(errors, isEmpty);
    });

    test('validates with errors for empty name', () {
      const model = Model();

      const workspace = Workspace(
        id: 1,
        name: '',
        model: model,
      );

      final errors = workspace.validate();

      expect(errors, hasLength(1));
      expect(errors[0], contains('name is required'));
    });

    test('validates by including model validation errors', () {
      // Create model with duplicate IDs to force a validation error
      const person1 = Person(
        id: 'duplicate-id',
        name: 'Person 1',
      );

      const person2 = Person(
        id: 'duplicate-id', // Same ID as person1
        name: 'Person 2',
      );

      const model = Model(
        people: [person1, person2],
      );

      const workspace = Workspace(
        id: 1,
        name: 'Test Workspace',
        model: model,
      );

      final errors = workspace.validate();

      expect(errors, hasLength(1));
      expect(errors[0], contains('Duplicate element ID'));
    });

    test('updates model', () {
      const originalModel = Model();
      const updatedModel = Model(enterpriseName: 'Updated Enterprise');

      const workspace = Workspace(
        id: 1,
        name: 'Test Workspace',
        model: originalModel,
      );

      final updatedWorkspace = workspace.updateModel(updatedModel);

      expect(updatedWorkspace.model, equals(updatedModel));
      expect(
          updatedWorkspace.model.enterpriseName, equals('Updated Enterprise'));
    });
  });

  group('WorkspaceConfiguration', () {
    test('creates configuration with default values', () {
      const configuration = WorkspaceConfiguration();

      expect(configuration.users, isNull);
      expect(configuration.properties, isEmpty);
      expect(configuration.lastModifiedDate, isNull);
      expect(configuration.lastModifiedUser, isNull);
      expect(configuration.lastModifiedAgent, isNull);
    });

    test('creates configuration with all properties', () {
      final users = [
        const User(username: 'user1', role: 'admin'),
      ];

      final configuration = WorkspaceConfiguration(
        users: users,
        properties: {'key': 'value'},
        lastModifiedDate: DateTime(2023, 1, 1),
        lastModifiedUser: 'User',
        lastModifiedAgent: 'Agent',
      );

      expect(configuration.users, equals(users));
      expect(configuration.properties, containsPair('key', 'value'));
      expect(configuration.lastModifiedDate, equals(DateTime(2023, 1, 1)));
      expect(configuration.lastModifiedUser, equals('User'));
      expect(configuration.lastModifiedAgent, equals('Agent'));
    });
  });

  group('User', () {
    test('creates a user with required properties', () {
      const user = User(
        username: 'user1',
        role: 'admin',
      );

      expect(user.username, equals('user1'));
      expect(user.role, equals('admin'));
    });
  });
}
