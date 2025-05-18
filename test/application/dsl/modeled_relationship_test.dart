import 'package:flutter_structurizr/application/dsl/workspace_mapper.dart';
import 'package:flutter_structurizr/domain/parser/parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ModeledRelationship with WorkspaceMapper', () {
    test(
        'findRelationshipBetween returns ModeledRelationship with access to source/destination',
        () {
      // Define a simple DSL with a relationship
      const source = '''
        workspace "Test Workspace" {
          model {
            user = person "User" "A user of the system"
            system = softwareSystem "System" "A software system"
            
            user -> system "Uses"
          }
        }
      ''';

      // Parse the DSL
      final parser = Parser(source);
      final ast = parser.parse();

      // Map to a workspace
      final workspace =
          WorkspaceMapper(source, parser.errorReporter).mapWorkspace(ast);

      // Verify the workspace was created
      expect(workspace, isNotNull);
      expect(workspace!.model.relationships.length, equals(1));

      // Get the user and system elements
      final user = workspace.model.people.first;
      final system = workspace.model.softwareSystems.first;

      // Find the relationship between them
      final relationship =
          workspace.model.findRelationshipBetween(user.id, system.id);

      // Verify relationship exists
      expect(relationship, isNotNull);

      // Now test the modeled relationship
      expect(relationship!.source, equals(user));
      expect(relationship.destination, equals(system));
      expect(relationship.source.name, equals('User'));
      expect(relationship.destination.name, equals('System'));
      expect(relationship.description, equals('Uses'));
    });
  });
}
