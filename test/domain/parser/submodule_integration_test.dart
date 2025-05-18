import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/parser/parser.dart';
import 'package:flutter_structurizr/domain/parser/ast/ast.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter_structurizr/domain/parser/ast/nodes/model_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/person_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/software_system_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/relationship_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/include_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/views_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/styles_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/system_context_view_node.dart';

void main() {
  group('Submodule Integration', () {
    late Parser parser;
    late ErrorReporter errorReporter;

    setUp(() {
      errorReporter = ErrorReporter('');
      parser = Parser('');
    });

    test('integrateSubmodules combines modules from includes', () {
      // Set up test workspace with main module
      final mainWorkspace = WorkspaceNode(
        name: 'Main Workspace',
        model: ModelNode(),
      );

      // Set up mock submodules to be integrated
      final submodule1 = WorkspaceNode(
        name: 'Submodule 1',
        model: ModelNode(),
      );

      final submodule2 = WorkspaceNode(
        name: 'Submodule 2',
        model: ModelNode(),
      );

      // Add elements to submodules for testing integration
      submodule1.model!.addPerson(PersonNode(
          id: 'person1', name: 'Person One', description: 'First person'));

      submodule2.model!.addPerson(PersonNode(
          id: 'person2', name: 'Person Two', description: 'Second person'));

      submodule2.model!.addSoftwareSystem(SoftwareSystemNode(
          id: 'system1', name: 'System One', description: 'First system'));

      // Set up includes in the main workspace
      final include1 = IncludeNode(path: 'submodule1.dsl');
      final include2 = IncludeNode(path: 'submodule2.dsl');

      mainWorkspace.addInclude(include1);
      mainWorkspace.addInclude(include2);

      // Run the integration
      parser.integrateSubmodules();

      // Verify that elements from submodules are integrated into main workspace
      expect(mainWorkspace.model!.people.length, equals(2));
      expect(mainWorkspace.model!.softwareSystems.length, equals(1));

      // Verify specific elements were integrated correctly
      final person1 =
          mainWorkspace.model!.people.firstWhere((p) => p.id == 'person1');
      expect(person1.name, equals('Person One'));

      final person2 =
          mainWorkspace.model!.people.firstWhere((p) => p.id == 'person2');
      expect(person2.name, equals('Person Two'));

      final system1 = mainWorkspace.model!.softwareSystems
          .firstWhere((s) => s.id == 'system1');
      expect(system1.name, equals('System One'));
    });

    test('integrateSubmodules handles nested includes', () {
      // Set up test workspaces with nested structure
      final mainWorkspace =
          WorkspaceNode(name: 'Main Workspace', model: ModelNode());
      final submodule1 = WorkspaceNode(name: 'Submodule 1', model: ModelNode());
      final submodule2 = WorkspaceNode(name: 'Submodule 2', model: ModelNode());
      final nestedSubmodule =
          WorkspaceNode(name: 'Nested Submodule', model: ModelNode());

      // Add elements to various modules
      submodule1.model!.addPerson(PersonNode(
          id: 'person1', name: 'Person One', description: 'First person'));

      nestedSubmodule.model!.addPerson(PersonNode(
          id: 'nestedPerson',
          name: 'Nested Person',
          description: 'Nested person'));

      // Set up nested includes
      final nestedInclude = IncludeNode(path: 'nested.dsl');
      submodule2.addInclude(nestedInclude);

      final include1 = IncludeNode(path: 'submodule1.dsl');
      final include2 = IncludeNode(path: 'submodule2.dsl');

      mainWorkspace.addInclude(include1);
      mainWorkspace.addInclude(include2);

      // Run the integration
      parser.integrateSubmodules();

      // Verify all elements are integrated, including from nested modules
      expect(mainWorkspace.model!.people.length, equals(2));

      // Verify nested elements were integrated
      final nestedPerson =
          mainWorkspace.model!.people.firstWhere((p) => p.id == 'nestedPerson');
      expect(nestedPerson.name, equals('Nested Person'));
    });

    test('integrateSubmodules handles circular references', () {
      // Set up test workspaces with circular references
      final workspaceA = WorkspaceNode(name: 'Workspace A', model: ModelNode());
      final workspaceB = WorkspaceNode(name: 'Workspace B', model: ModelNode());

      // Add elements to modules
      workspaceA.model!.addPerson(PersonNode(
          id: 'personA', name: 'Person A', description: 'Person in A'));

      workspaceB.model!.addPerson(PersonNode(
          id: 'personB', name: 'Person B', description: 'Person in B'));

      // Create circular reference: A includes B, B includes A
      final includeB = IncludeNode(path: 'workspaceB.dsl');
      final includeA = IncludeNode(path: 'workspaceA.dsl');

      workspaceA.addInclude(includeB);
      workspaceB.addInclude(includeA);

      // Run the integration - should handle circular references without infinite recursion
      parser.integrateSubmodules();

      // Verify elements were integrated without duplication
      expect(workspaceA.model!.people.length, equals(2));

      final personA =
          workspaceA.model!.people.firstWhere((p) => p.id == 'personA');
      expect(personA.name, equals('Person A'));

      final personB =
          workspaceA.model!.people.firstWhere((p) => p.id == 'personB');
      expect(personB.name, equals('Person B'));
    });

    test('integrateSubmodules merges relationships correctly', () {
      // Set up test workspace with main module
      final mainWorkspace =
          WorkspaceNode(name: 'Main Workspace', model: ModelNode());

      // Set up submodule with relationships
      final submodule = WorkspaceNode(name: 'Submodule', model: ModelNode());

      // Add elements and relationships to submodule
      submodule.model!.addPerson(
          PersonNode(id: 'user', name: 'User', description: 'A user'));

      submodule.model!.addSoftwareSystem(SoftwareSystemNode(
          id: 'system', name: 'System', description: 'A system'));

      // Add relationship between elements
      submodule.model!.addRelationship(RelationshipNode(
          sourceId: 'user',
          destinationId: 'system',
          description: 'Uses',
          technology: 'HTTP'));

      // Set up include in the main workspace
      final include = IncludeNode(path: 'submodule.dsl');
      mainWorkspace.addInclude(include);

      // Run the integration
      parser.integrateSubmodules();

      // Verify relationships are integrated
      expect(mainWorkspace.model!.relationships.length, equals(1));

      final relationship = mainWorkspace.model!.relationships.first;
      expect(relationship.sourceId, equals('user'));
      expect(relationship.destinationId, equals('system'));
      expect(relationship.description, equals('Uses'));
    });

    test('integrateSubmodules handles conflicting element IDs', () {
      // Set up test workspace with main module
      final mainWorkspace = WorkspaceNode(
        name: 'Main Workspace',
        model: ModelNode(),
      );

      // Add element to main workspace
      mainWorkspace.model!.addPerson(PersonNode(
          id: 'person',
          name: 'Main Person',
          description: 'Person in main workspace'));

      // Set up submodule with conflicting element ID
      final submodule = WorkspaceNode(name: 'Submodule', model: ModelNode());

      // Add element with same ID but different properties
      submodule.model!.addPerson(PersonNode(
          id: 'person',
          name: 'Submodule Person',
          description: 'Person in submodule'));

      // Set up include in the main workspace
      final include = IncludeNode(path: 'submodule.dsl');
      mainWorkspace.addInclude(include);

      // Run the integration
      parser.integrateSubmodules();

      // Verify original element was preserved
      expect(mainWorkspace.model!.people.length, equals(1));
      expect(mainWorkspace.model!.people.first.name, equals('Main Person'));
    });

    test('integrateSubmodules merges views correctly', () {
      // Set up test workspace with main module
      final mainWorkspace = WorkspaceNode(
        name: 'Main Workspace',
        model: ModelNode(),
        views: ViewsNode(),
      );

      // Set up submodule with views
      final submodule = WorkspaceNode(
        name: 'Submodule',
        model: ModelNode(),
        views: ViewsNode(systemContextViews: [
          SystemContextViewNode(
            key: 'submodule-context',
            systemId: 'submoduleSystem',
            description: 'Context view from submodule',
          )
        ]),
      );

      // Add elements to main workspace and submodule
      mainWorkspace.model!.addSoftwareSystem(SoftwareSystemNode(
          id: 'mainSystem',
          name: 'Main System',
          description: 'System in main workspace'));

      submodule.model!.addSoftwareSystem(SoftwareSystemNode(
          id: 'submoduleSystem',
          name: 'Submodule System',
          description: 'System in submodule'));

      // Set up include in the main workspace
      final include = IncludeNode(path: 'submodule.dsl');
      mainWorkspace.addInclude(include);

      // Run the integration
      parser.integrateSubmodules();

      // Verify views are integrated
      expect(mainWorkspace.views!.systemContextViews.length, equals(1));

      final view = mainWorkspace.views!.systemContextViews.first;
      expect(view.key, equals('submodule-context'));
      expect(view.systemId, equals('submoduleSystem'));
    });

    test('integrateSubmodules merges styles correctly', () {
      // Set up test workspace with main module
      final mainWorkspace = WorkspaceNode(
        name: 'Main Workspace',
        model: ModelNode(),
        styles: StylesNode(),
      );

      // Set up submodule with styles
      final submodule = WorkspaceNode(
        name: 'Submodule',
        model: ModelNode(),
        styles: StylesNode(),
      );

      // Set up include in the main workspace
      final include = IncludeNode(path: 'submodule.dsl');
      mainWorkspace.addInclude(include);

      // Run the integration
      parser.integrateSubmodules();

      // Verify styles are integrated
      expect(mainWorkspace.styles!.elements.length, equals(0));
      expect(mainWorkspace.styles!.relationships.length, equals(0));
    });

    test('integrateSubmodules merges documentation correctly', () {
      // Set up test workspace with main module
      final mainWorkspace = WorkspaceNode(
        name: 'Main Workspace',
        model: ModelNode(),
      );

      // Set up submodule with documentation
      final submodule = WorkspaceNode(
        name: 'Submodule',
        model: ModelNode(),
        documentation: DocumentationNode(
          content: 'Submodule documentation',
          format: DocumentationFormat.markdown,
          sections: [
            DocumentationSectionNode(
                title: 'Section 1', content: 'Section 1 content'),
            DocumentationSectionNode(
                title: 'Section 2', content: 'Section 2 content'),
          ],
        ),
      );

      // Set up include in the main workspace
      final include = IncludeNode(path: 'submodule.dsl');
      mainWorkspace.addInclude(include);

      // Run the integration
      parser.integrateSubmodules();

      // Verify documentation is integrated
      expect(mainWorkspace.documentation, isNotNull);
      expect(mainWorkspace.documentation!.sections.length, equals(2));

      final section1 = mainWorkspace.documentation!.sections.first;
      expect(section1.title, equals('Section 1'));
      expect(section1.content, equals('Section 1 content'));
    });

    test('integrateSubmodules handles includes with missing files', () {
      // Set up test workspace with main module
      final mainWorkspace = WorkspaceNode(
        name: 'Main Workspace',
        model: ModelNode(),
      );

      // Add a real include node but without a workspace (simulating a file not found)
      final include = IncludeNode(path: 'non_existent.dsl');
      mainWorkspace.addInclude(include);

      // Run the integration
      parser.integrateSubmodules();

      // Verify error was reported
      expect(parser.errors.isNotEmpty, isTrue);
    });

    test('integrateSubmodules with overlapping dependencies', () {
      // Set up a scenario where multiple modules include the same submodule
      final mainWorkspace =
          WorkspaceNode(name: 'Main Workspace', model: ModelNode());
      final module1 = WorkspaceNode(name: 'Module 1', model: ModelNode());
      final module2 = WorkspaceNode(name: 'Module 2', model: ModelNode());
      final sharedModule =
          WorkspaceNode(name: 'Shared Module', model: ModelNode());

      // Add element to shared module
      sharedModule.model!.addPerson(PersonNode(
          id: 'sharedPerson',
          name: 'Shared Person',
          description: 'Person in shared module'));

      // Setup includes: both module1 and module2 include sharedModule
      final sharedInclude1 =
          IncludeNode(path: 'shared.dsl', workspace: sharedModule);
      final sharedInclude2 =
          IncludeNode(path: 'shared.dsl', workspace: sharedModule);

      module1.addInclude(sharedInclude1);
      module2.addInclude(sharedInclude2);

      // Main workspace includes both modules
      final include1 = IncludeNode(path: 'module1.dsl', workspace: module1);
      final include2 = IncludeNode(path: 'module2.dsl', workspace: module2);

      mainWorkspace.addInclude(include1);
      mainWorkspace.addInclude(include2);

      // Run the integration
      parser.integrateSubmodules();

      // Verify shared elements are integrated without duplication
      expect(mainWorkspace.model!.people.length, equals(1));

      final sharedPerson = mainWorkspace.model!.people.first;
      expect(sharedPerson.id, equals('sharedPerson'));
      expect(sharedPerson.name, equals('Shared Person'));
    });

    test('integrateSubmodules with large complex hierarchies', () {
      // Create a large workspace hierarchy to test performance and recursive handling
      final mainWorkspace =
          WorkspaceNode(name: 'Main Workspace', model: ModelNode());

      // Create a chain of submodules 5 levels deep
      WorkspaceNode? currentModule = mainWorkspace;
      final allModules = <WorkspaceNode>[];

      for (var i = 1; i <= 5; i++) {
        final nextModule = WorkspaceNode(
          name: 'Module Level $i',
          model: ModelNode(),
        );

        // Add some unique elements to each module
        nextModule.model!.addPerson(PersonNode(
            id: 'person$i',
            name: 'Person $i',
            description: 'Person at level $i'));

        nextModule.model!.addSoftwareSystem(SoftwareSystemNode(
            id: 'system$i',
            name: 'System $i',
            description: 'System at level $i'));

        // Connect current module to next via include
        final include = IncludeNode(path: 'level$i.dsl', workspace: nextModule);
        currentModule.addInclude(include);

        allModules.add(nextModule);
        currentModule = nextModule;
      }

      // Run the integration
      parser.integrateSubmodules();

      // Verify all elements from all levels are properly integrated
      expect(mainWorkspace.model!.people.length, equals(5));
      expect(mainWorkspace.model!.softwareSystems.length, equals(5));

      // Verify specific elements from different levels
      for (var i = 1; i <= 5; i++) {
        final person =
            mainWorkspace.model!.people.firstWhere((p) => p.id == 'person$i');
        expect(person.name, equals('Person $i'));

        final system = mainWorkspace.model!.softwareSystems
            .firstWhere((s) => s.id == 'system$i');
        expect(system.name, equals('System $i'));
      }
    });

    test('integrateSubmodules properly invokes subparsers', () {
      // This test verifies that integrateSubmodules properly calls the appropriate parser methods

      // Create a workspace with bare includes (no pre-parsed workspaces)
      final mainWorkspace =
          WorkspaceNode(name: 'Main Workspace', model: ModelNode());

      // Add includes that need to be loaded and parsed
      final include1 = IncludeNode(path: 'module1.dsl');
      final include2 = IncludeNode(path: 'module2.dsl');

      mainWorkspace.addInclude(include1);
      mainWorkspace.addInclude(include2);

      // Create a mock FileLoader and mock subparsers
      parser = MockParser('', mainWorkspace);

      // Track which subparsers are invoked
      var modelParserInvoked = false;
      var viewsParserInvoked = false;
      var relationshipParserInvoked = false;
      var includeParserInvoked = false;

      parser.setModelParserHook(() {
        modelParserInvoked = true;
      });

      parser.setViewsParserHook(() {
        viewsParserInvoked = true;
      });

      parser.setRelationshipParserHook(() {
        relationshipParserInvoked = true;
      });

      parser.setIncludeParserHook(() {
        includeParserInvoked = true;
        // Simulate loading included files
        include1.workspace =
            WorkspaceNode(name: 'Module 1', model: ModelNode());
        include2.workspace =
            WorkspaceNode(name: 'Module 2', model: ModelNode());
      });

      // Run the integration
      parser.integrateSubmodules();

      // Verify all appropriate parsers were invoked
      expect(includeParserInvoked, isTrue);
      expect(modelParserInvoked, isTrue);
      expect(viewsParserInvoked, isTrue);
      expect(relationshipParserInvoked, isTrue);
    });

    test('integrateSubmodules with a complete file system test', () async {
      // Create a temporary directory for test files
      final tempDir = Directory.systemTemp.createTempSync('structurizr_test_');
      try {
        // Create a main DSL file
        final mainFile = File(path.join(tempDir.path, 'main.dsl'));
        mainFile.writeAsStringSync('''
          workspace "Main Workspace" {
            model {
              user = person "User" "A user of the system"
              
              !include "module.dsl"
              
              user -> mainSystem "Uses"
            }
          }
        ''');

        // Create a module DSL file
        final moduleFile = File(path.join(tempDir.path, 'module.dsl'));
        moduleFile.writeAsStringSync('''
          mainSystem = softwareSystem "Main System" "The main system"
          
          moduleSystem = softwareSystem "Module System" "A modular system" {
            container1 = container "Container 1" "First container"
            container2 = container "Container 2" "Second container"
          }
          
          mainSystem -> moduleSystem "Integrates with"
        ''');

        // Create a parser for the main file
        final parser = Parser.fromFile(mainFile.path);

        // Parse and load the workspace
        final workspace = parser.parse();

        // Verify the structure was loaded correctly
        expect(workspace.model!.people.length, equals(1));
        expect(workspace.model!.softwareSystems.length, equals(2));
        expect(workspace.model!.relationships.length, equals(2));

        // Verify a specific relationship was correctly loaded
        final userToMainRelationship = workspace.model!.relationships
            .firstWhere(
                (r) => r.sourceId == 'user' && r.destinationId == 'mainSystem');
        expect(userToMainRelationship.description, equals('Uses'));

        // Verify a container inside the module was correctly loaded
        final moduleSystem = workspace.model!.softwareSystems
            .firstWhere((s) => s.id == 'moduleSystem');
        expect(moduleSystem.containers.length, equals(2));
      } finally {
        // Clean up temporary directory
        tempDir.deleteSync(recursive: true);
      }
    });
  });
}

// Mock implementation for testing specific hooks
class MockParser extends Parser {
  final WorkspaceNode mockWorkspace;

  MockParser(String source, this.mockWorkspace) : super(source);

  Function? _modelParserHook;
  Function? _viewsParserHook;
  Function? _relationshipParserHook;
  Function? _includeParserHook;

  @override
  WorkspaceNode parse() {
    return mockWorkspace;
  }

  @override
  WorkspaceNode getWorkspace() {
    return mockWorkspace;
  }

  void setModelParserHook(Function hook) {
    _modelParserHook = hook;
  }

  void setViewsParserHook(Function hook) {
    _viewsParserHook = hook;
  }

  void setRelationshipParserHook(Function hook) {
    _relationshipParserHook = hook;
  }

  void setIncludeParserHook(Function hook) {
    _includeParserHook = hook;
  }

  @override
  void integrateSubmodules() {
    if (_includeParserHook != null) {
      _includeParserHook!();
    }

    if (_modelParserHook != null) {
      _modelParserHook!();
    }

    if (_viewsParserHook != null) {
      _viewsParserHook!();
    }

    if (_relationshipParserHook != null) {
      _relationshipParserHook!();
    }

    super.integrateSubmodules();
  }
}

// Add stubs for addPerson, addSoftwareSystem, addRelationship on ModelNode
extension ModelNodeTestHelpers on ModelNode {
  void addPerson(PersonNode person) {
    // Add to people list if not present
    if (!people.contains(person)) {
      people.add(person);
    }
  }

  void addSoftwareSystem(SoftwareSystemNode system) {
    if (!softwareSystems.contains(system)) {
      softwareSystems.add(system);
    }
  }

  void addRelationship(RelationshipNode rel) {
    if (!relationships.contains(rel)) {
      relationships.add(rel);
    }
  }
}

// Add stubs for addInclude, setWorkspace, setErrorReporter on WorkspaceNode
extension WorkspaceNodeTestHelpers on WorkspaceNode {
  void addInclude(IncludeNode include) {
    // No-op or add to a test-only list
  }
  void setWorkspace(WorkspaceNode ws) {
    // No-op for test
  }
  void setErrorReporter(Function f) {
    // No-op for test
  }
}
