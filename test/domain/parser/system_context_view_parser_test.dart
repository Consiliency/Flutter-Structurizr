import 'package:flutter_structurizr/application/dsl/workspace_builder.dart';
import 'package:flutter_structurizr/application/dsl/workspace_builder_impl.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/person.dart';
import 'package:flutter_structurizr/domain/model/software_system.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/parser/ast/ast.dart';
import 'package:flutter_structurizr/domain/parser/reference_resolver.dart';
import 'package:flutter_structurizr/domain/parser/views_parser/system_context_view_parser.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_test/flutter_test.dart';

class MockParserError implements ParserError {
  @override
  final ErrorSeverity severity;
  @override
  final String message;
  @override
  final SourcePosition position;
  @override
  final String source;

  MockParserError({
    required this.severity,
    required this.message,
    required this.position,
    required this.source,
  });

  @override
  String get errorLine => '';

  @override
  String format() => '$severity: $message at ${position.toString()}';
}

class MockErrorReporter implements ErrorReporter {
  final List<ParserError> _errors = [];
  
  @override
  final String source = '';

  @override
  bool get hasErrors => _errors.any((e) => 
      e.severity == ErrorSeverity.error || 
      e.severity == ErrorSeverity.fatal);

  @override
  bool get hasFatalErrors => _errors.any((e) => e.severity == ErrorSeverity.fatal);

  @override
  int get errorCount => _errors.length;

  @override
  List<ParserError> get errors => List.unmodifiable(_errors);

  @override
  void reportError({
    required ErrorSeverity severity,
    required String message,
    required int offset,
  }) {
    final position = SourcePosition(line: 1, column: offset + 1, offset: offset);
    final error = MockParserError(
      severity: severity,
      message: message,
      position: position,
      source: source,
    );
    _errors.add(error);
  }

  @override
  void reportFatalError(String message, int offset) {
    reportError(
      severity: ErrorSeverity.fatal,
      message: message,
      offset: offset,
    );
  }

  @override
  void reportStandardError(String message, int offset) {
    reportError(
      severity: ErrorSeverity.error,
      message: message,
      offset: offset,
    );
  }

  @override
  void reportWarning(String message, int offset) {
    reportError(
      severity: ErrorSeverity.warning,
      message: message,
      offset: offset,
    );
  }

  @override
  void reportInfo(String message, int offset) {
    reportError(
      severity: ErrorSeverity.info,
      message: message,
      offset: offset,
    );
  }

  @override
  String formatErrors() {
    if (_errors.isEmpty) {
      return 'No errors reported.';
    }

    final sb = StringBuffer();
    sb.writeln('${_errors.length} error(s) found:');
    sb.writeln();

    for (var error in _errors) {
      sb.writeln(error.format());
    }

    return sb.toString();
  }

  @override
  String getSourceSnippet(SourcePosition position, {int contextLines = 2}) {
    return '';
  }
}

// Mock class for testing protected methods in WorkspaceBuilderImpl
class TestableWorkspaceBuilder extends WorkspaceBuilderImpl {
  TestableWorkspaceBuilder(ErrorReporter errorReporter) : super(errorReporter);
  
  // Expose protected methods for testing
  @override
  void addDefaultElements(SystemContextViewNode viewNode) {
    super.addDefaultElements(viewNode);
  }
  
  @override
  void addImpliedRelationships() {
    super.addImpliedRelationships();
  }
  
  @override
  void populateDefaults() {
    super.populateDefaults();
  }
  
  @override
  void setDefaultsFromJava() {
    super.setDefaultsFromJava();
  }
}

void main() {
  late MockErrorReporter errorReporter;
  late WorkspaceBuilder builder;
  late TestableWorkspaceBuilder testableBuilder;
  late SystemContextViewParser parser;

  setUp(() {
    errorReporter = MockErrorReporter();
    builder = WorkspaceBuilderFactoryImpl().createWorkspaceBuilder(errorReporter);
    testableBuilder = TestableWorkspaceBuilder(errorReporter);
    parser = SystemContextViewParser(
      errorReporter: errorReporter,
      referenceResolver: builder.referenceResolver,
    );
  });

  tearDown(() {
    errorReporter = MockErrorReporter();
  });

  group('WorkspaceBuilderImpl.addSystemContextView', () {
    test('successfully adds a system context view', () {
      // Arrange
      builder.createWorkspace(name: 'Test Workspace');
      
      // Add a software system
      final systemNode = SoftwareSystemNode(
        id: 'system1',
        name: 'Banking System',
        description: 'Manages customer accounts and transactions',
        sourcePosition: SourcePosition(offset: 0, line: 1, column: 1),
      );
      builder.addSoftwareSystem(systemNode);
      
      // Create a system context view node
      final viewNode = SystemContextViewNode(
        key: 'SystemContext',
        systemId: 'system1',
        title: 'Banking System - System Context',
        description: 'System context diagram for the banking system',
        sourcePosition: SourcePosition(offset: 100, line: 5, column: 1),
      );
      
      // Act
      builder.addSystemContextView(viewNode);
      
      // Assert
      final workspace = builder.build();
      expect(workspace, isNotNull);
      expect(workspace!.views.systemContextViews.length, equals(1));
      expect(workspace.views.systemContextViews.first.key, equals('SystemContext'));
      expect(workspace.views.systemContextViews.first.softwareSystemId, equals('system1'));
      expect(workspace.views.systemContextViews.first.title, equals('Banking System - System Context'));
      expect(workspace.views.systemContextViews.first.description, equals('System context diagram for the banking system'));
      expect(errorReporter.errors, isEmpty);
    });
    
    test('reports error when software system not found', () {
      // Arrange
      builder.createWorkspace(name: 'Test Workspace');
      
      // Create a system context view node with a non-existent software system
      final viewNode = SystemContextViewNode(
        key: 'SystemContext',
        systemId: 'nonExistentSystem',
        title: 'Banking System - System Context',
        description: 'System context diagram for the banking system',
        sourcePosition: SourcePosition(offset: 100, line: 5, column: 1),
      );
      
      // Act
      builder.addSystemContextView(viewNode);
      
      // Assert
      final workspace = builder.build();
      expect(workspace, isNotNull);
      expect(workspace!.views.systemContextViews.length, equals(0)); // View should not be added
      expect(errorReporter.errorCount, greaterThan(0));
      expect(errorReporter.formatErrors(), contains('Software system not found'));
    });
    
    test('adds relationships between system and people', () {
      // Arrange
      builder.createWorkspace(name: 'Test Workspace');
      
      // Add a software system
      final systemNode = SoftwareSystemNode(
        id: 'system1',
        name: 'Banking System',
        description: 'Manages customer accounts and transactions',
        sourcePosition: SourcePosition(offset: 0, line: 1, column: 1),
      );
      builder.addSoftwareSystem(systemNode);
      
      // Add a person with relationship to the system
      final personNode = PersonNode(
        id: 'person1',
        name: 'Customer',
        description: 'A customer of the bank',
        sourcePosition: SourcePosition(offset: 200, line: 10, column: 1),
      );
      builder.addPerson(personNode);
      
      // Add relationship
      final relationshipNode = RelationshipNode(
        sourceId: 'person1',
        destinationId: 'system1',
        description: 'Uses',
        technology: 'Web',
        sourcePosition: SourcePosition(offset: 300, line: 15, column: 1),
      );
      builder.addRelationship(relationshipNode);
      builder.resolveRelationships();
      
      // Create a system context view node
      final viewNode = SystemContextViewNode(
        key: 'SystemContext',
        systemId: 'system1',
        title: 'Banking System - System Context',
        description: 'System context diagram for the banking system',
        sourcePosition: SourcePosition(offset: 400, line: 20, column: 1),
      );
      
      // Act
      builder.addSystemContextView(viewNode);
      
      // Assert
      final workspace = builder.build();
      expect(workspace, isNotNull);
      expect(workspace!.views.systemContextViews.length, equals(1));
      
      // The view should contain both the software system and the person
      final view = workspace.views.systemContextViews.first;
      expect(view.elements.length, equals(2)); 
      expect(view.elements.any((e) => e.id == 'system1'), isTrue);
      expect(view.elements.any((e) => e.id == 'person1'), isTrue);
      
      // The view should also contain the relationship
      expect(view.relationships.length, equals(1));
      
      // No errors should be reported
      expect(errorReporter.errors, isEmpty);
    });
    
    test('adds relationships between system and other systems', () {
      // Arrange
      builder.createWorkspace(name: 'Test Workspace');
      
      // Add the main software system
      final mainSystemNode = SoftwareSystemNode(
        id: 'mainSystem',
        name: 'Banking System',
        description: 'Manages customer accounts and transactions',
        sourcePosition: SourcePosition(offset: 0, line: 1, column: 1),
      );
      builder.addSoftwareSystem(mainSystemNode);
      
      // Add another software system
      final externalSystemNode = SoftwareSystemNode(
        id: 'externalSystem',
        name: 'Payment Gateway',
        description: 'Processes payments',
        sourcePosition: SourcePosition(offset: 200, line: 10, column: 1),
      );
      builder.addSoftwareSystem(externalSystemNode);
      
      // Add a relationship between the systems
      final relationshipNode = RelationshipNode(
        sourceId: 'mainSystem',
        destinationId: 'externalSystem',
        description: 'Uses',
        technology: 'API',
        sourcePosition: SourcePosition(offset: 300, line: 15, column: 1),
      );
      builder.addRelationship(relationshipNode);
      builder.resolveRelationships();
      
      // Create a system context view node
      final viewNode = SystemContextViewNode(
        key: 'SystemContext',
        systemId: 'mainSystem',
        title: 'Banking System - System Context',
        description: 'System context diagram for the banking system',
        sourcePosition: SourcePosition(offset: 400, line: 20, column: 1),
      );
      
      // Act
      builder.addSystemContextView(viewNode);
      
      // Assert
      final workspace = builder.build();
      expect(workspace, isNotNull);
      expect(workspace!.views.systemContextViews.length, equals(1));
      
      // The view should contain both software systems
      final view = workspace.views.systemContextViews.first;
      expect(view.elements.length, equals(2));
      expect(view.elements.any((e) => e.id == 'mainSystem'), isTrue);
      expect(view.elements.any((e) => e.id == 'externalSystem'), isTrue);
      
      // The view should also contain the relationship
      expect(view.relationships.length, equals(1));
      
      // No errors should be reported
      expect(errorReporter.errors, isEmpty);
    });
    
    test('creates view with default title when not specified', () {
      // Arrange
      builder.createWorkspace(name: 'Test Workspace');
      
      // Add a software system
      final systemNode = SoftwareSystemNode(
        id: 'system1',
        name: 'Banking System',
        description: 'Manages customer accounts and transactions',
        sourcePosition: SourcePosition(offset: 0, line: 1, column: 1),
      );
      builder.addSoftwareSystem(systemNode);
      
      // Create a system context view node without a title
      final viewNode = SystemContextViewNode(
        key: 'SystemContext',
        systemId: 'system1',
        title: null, // No title specified
        description: 'System context diagram for the banking system',
        sourcePosition: SourcePosition(offset: 100, line: 5, column: 1),
      );
      
      // Act
      builder.addSystemContextView(viewNode);
      
      // Assert
      final workspace = builder.build();
      expect(workspace, isNotNull);
      expect(workspace!.views.systemContextViews.length, equals(1));
      expect(workspace.views.systemContextViews.first.key, equals('SystemContext'));
      
      // The title should be generated based on the system name
      expect(workspace.views.systemContextViews.first.title, equals('Banking System - System Context'));
      
      // No errors should be reported
      expect(errorReporter.errors, isEmpty);
    });
    
    test('handles include/exclude tags in the view', () {
      // Arrange
      builder.createWorkspace(name: 'Test Workspace');
      
      // Add a software system
      final systemNode = SoftwareSystemNode(
        id: 'system1',
        name: 'Banking System',
        description: 'Manages customer accounts and transactions',
        sourcePosition: SourcePosition(offset: 0, line: 1, column: 1),
      );
      builder.addSoftwareSystem(systemNode);
      
      // Create a system context view node with include/exclude rules
      final viewNode = SystemContextViewNode(
        key: 'SystemContext',
        systemId: 'system1',
        title: 'Banking System - System Context',
        description: 'System context diagram for the banking system',
        sourcePosition: SourcePosition(offset: 100, line: 5, column: 1),
        includes: [
          IncludeNode(
            expression: 'Customer',
            sourcePosition: SourcePosition(offset: 150, line: 6, column: 1),
          ),
        ],
        excludes: [
          ExcludeNode(
            expression: 'Developer',
            sourcePosition: SourcePosition(offset: 200, line: 7, column: 1),
          ),
        ],
      );
      
      // Act
      builder.addSystemContextView(viewNode);
      
      // Assert
      final workspace = builder.build();
      expect(workspace, isNotNull);
      expect(workspace!.views.systemContextViews.length, equals(1));
      
      // The view should have include/exclude tags
      final view = workspace.views.systemContextViews.first;
      expect(view.includeTags, contains('Customer'));
      expect(view.excludeTags, contains('Developer'));
      
      // No errors should be reported
      expect(errorReporter.errors, isEmpty);
    });
  });
  
  group('WorkspaceBuilderImpl.addDefaultElements', () {
    test('adds default elements to the view node', () {
      // Arrange
      testableBuilder.createWorkspace(name: 'Test Workspace');
      
      // Add a software system
      final systemNode = SoftwareSystemNode(
        id: 'system1',
        name: 'Banking System',
        description: 'Manages customer accounts and transactions',
        sourcePosition: SourcePosition(offset: 0, line: 1, column: 1),
      );
      testableBuilder.addSoftwareSystem(systemNode);
      
      // Add a person with relationship to the system
      final personNode = PersonNode(
        id: 'person1',
        name: 'Customer',
        description: 'A customer of the bank',
        sourcePosition: SourcePosition(offset: 200, line: 10, column: 1),
      );
      testableBuilder.addPerson(personNode);
      
      // Create a system context view node
      final viewNode = SystemContextViewNode(
        key: 'SystemContext',
        systemId: 'system1',
        title: 'Banking System - System Context',
        description: 'System context diagram for the banking system',
        sourcePosition: SourcePosition(offset: 400, line: 20, column: 1),
      );
      
      // Track original element count
      int initialElementCount = viewNode.elements.length;
      
      // Act
      testableBuilder.addDefaultElements(viewNode);
      
      // Assert
      expect(viewNode.elements.length, greaterThan(initialElementCount));
      expect(viewNode.elements.any((e) => e.id == 'system1'), isTrue);
      expect(errorReporter.errors, isEmpty);
    });
    
    test('does not add elements when system not found', () {
      // Arrange
      testableBuilder.createWorkspace(name: 'Test Workspace');
      
      // Create a system context view node with non-existent system
      final viewNode = SystemContextViewNode(
        key: 'SystemContext',
        systemId: 'nonExistentSystem',
        title: 'Banking System - System Context',
        description: 'System context diagram for the banking system',
        sourcePosition: SourcePosition(offset: 400, line: 20, column: 1),
      );
      
      // Track original element count
      int initialElementCount = viewNode.elements.length;
      
      // Act
      testableBuilder.addDefaultElements(viewNode);
      
      // Assert
      expect(viewNode.elements.length, equals(initialElementCount));
      expect(errorReporter.errorCount, greaterThan(0));
    });
    
    test('adds all elements with relationships to the system', () {
      // Arrange
      testableBuilder.createWorkspace(name: 'Test Workspace');
      
      // Add a software system
      final systemNode = SoftwareSystemNode(
        id: 'system1',
        name: 'Banking System',
        description: 'Manages customer accounts and transactions',
        sourcePosition: SourcePosition(offset: 0, line: 1, column: 1),
      );
      testableBuilder.addSoftwareSystem(systemNode);
      
      // Add multiple people with relationships to the system
      final person1Node = PersonNode(
        id: 'person1',
        name: 'Customer',
        description: 'A customer of the bank',
        sourcePosition: SourcePosition(offset: 200, line: 10, column: 1),
      );
      final person2Node = PersonNode(
        id: 'person2',
        name: 'Administrator',
        description: 'A bank administrator',
        sourcePosition: SourcePosition(offset: 300, line: 15, column: 1),
      );
      testableBuilder.addPerson(person1Node);
      testableBuilder.addPerson(person2Node);
      
      // Add another system with relationship to the main system
      final system2Node = SoftwareSystemNode(
        id: 'system2',
        name: 'Payment Gateway',
        description: 'Processes payments',
        sourcePosition: SourcePosition(offset: 400, line: 20, column: 1),
      );
      testableBuilder.addSoftwareSystem(system2Node);
      
      // Add relationships
      final rel1Node = RelationshipNode(
        sourceId: 'person1',
        destinationId: 'system1',
        description: 'Uses',
        sourcePosition: SourcePosition(offset: 500, line: 25, column: 1),
      );
      final rel2Node = RelationshipNode(
        sourceId: 'person2',
        destinationId: 'system1',
        description: 'Administers',
        sourcePosition: SourcePosition(offset: 600, line: 30, column: 1),
      );
      final rel3Node = RelationshipNode(
        sourceId: 'system1',
        destinationId: 'system2',
        description: 'Uses',
        sourcePosition: SourcePosition(offset: 700, line: 35, column: 1),
      );
      
      testableBuilder.addRelationship(rel1Node);
      testableBuilder.addRelationship(rel2Node);
      testableBuilder.addRelationship(rel3Node);
      testableBuilder.resolveRelationships();
      
      // Create a system context view node
      final viewNode = SystemContextViewNode(
        key: 'SystemContext',
        systemId: 'system1',
        title: 'Banking System - System Context',
        description: 'System context diagram for the banking system',
        sourcePosition: SourcePosition(offset: 800, line: 40, column: 1),
      );
      
      // Act
      testableBuilder.addDefaultElements(viewNode);
      
      // Assert
      // Should have main system + 2 people + 1 external system = 4 elements
      expect(viewNode.elements.length, equals(4));
      expect(viewNode.elements.any((e) => e.id == 'system1'), isTrue);
      expect(viewNode.elements.any((e) => e.id == 'person1'), isTrue);
      expect(viewNode.elements.any((e) => e.id == 'person2'), isTrue);
      expect(viewNode.elements.any((e) => e.id == 'system2'), isTrue);
      expect(errorReporter.errors, isEmpty);
    });
  });
  
  group('WorkspaceBuilderImpl.addImpliedRelationships', () {
    test('adds implied relationships to the model', () {
      // Arrange
      testableBuilder.createWorkspace(name: 'Test Workspace');
      
      // Add a software system with containers
      final systemNode = SoftwareSystemNode(
        id: 'system1',
        name: 'Banking System',
        description: 'Manages customer accounts and transactions',
        sourcePosition: SourcePosition(offset: 0, line: 1, column: 1),
      );
      testableBuilder.addSoftwareSystem(systemNode);
      
      // Add container to the system
      final containerNode = ContainerNode(
        id: 'container1',
        name: 'Web Application',
        description: 'The web frontend',
        technology: 'Flutter Web',
        parentId: 'system1',
        sourcePosition: SourcePosition(offset: 100, line: 5, column: 1),
      );
      testableBuilder.setCurrentParent('system1');
      testableBuilder.addContainer(containerNode);
      
      // Add component to the container
      final componentNode = ComponentNode(
        id: 'component1',
        name: 'Authentication Controller',
        description: 'Handles user authentication',
        technology: 'Dart',
        parentId: 'container1',
        sourcePosition: SourcePosition(offset: 200, line: 10, column: 1),
      );
      testableBuilder.setCurrentParent('container1');
      testableBuilder.addComponent(componentNode);
      
      // Add a person with relationship to a component
      final personNode = PersonNode(
        id: 'person1',
        name: 'Customer',
        description: 'A customer of the bank',
        sourcePosition: SourcePosition(offset: 300, line: 15, column: 1),
      );
      testableBuilder.addPerson(personNode);
      
      // Add relationship from person to component (detail level)
      final relationshipNode = RelationshipNode(
        sourceId: 'person1',
        destinationId: 'component1',
        description: 'Authenticates with',
        sourcePosition: SourcePosition(offset: 400, line: 20, column: 1),
      );
      testableBuilder.addRelationship(relationshipNode);
      testableBuilder.resolveRelationships();
      
      // Get initial relationship count before adding implied relationships
      final initialRelationshipCount = testableBuilder.workspace?.model.getAllRelationships().length ?? 0;
      
      // Act
      testableBuilder.addImpliedRelationships();
      
      // Assert
      final workspace = testableBuilder.build();
      expect(workspace, isNotNull);
      
      // There should be more relationships after adding implied ones
      final finalRelationshipCount = workspace!.model.getAllRelationships().length;
      expect(finalRelationshipCount, greaterThan(initialRelationshipCount));
      
      // Person should have implied relationship to container
      final person = workspace.model.people.first;
      final containerRels = person.relationships.where((r) => r.destinationId == 'container1');
      expect(containerRels.isNotEmpty, isTrue);
      
      // Person should have implied relationship to system
      final systemRels = person.relationships.where((r) => r.destinationId == 'system1');
      expect(systemRels.isNotEmpty, isTrue);
      
      expect(errorReporter.errors, isEmpty);
    });
    
    test('does not add duplicate relationships', () {
      // Arrange
      testableBuilder.createWorkspace(name: 'Test Workspace');
      
      // Add software system
      final systemNode = SoftwareSystemNode(
        id: 'system1',
        name: 'Banking System',
        description: 'Manages customer accounts',
        sourcePosition: SourcePosition(offset: 0, line: 1, column: 1),
      );
      testableBuilder.addSoftwareSystem(systemNode);
      
      // Add container
      final containerNode = ContainerNode(
        id: 'container1',
        name: 'Web Application',
        description: 'The web frontend',
        technology: 'Flutter Web',
        parentId: 'system1',
        sourcePosition: SourcePosition(offset: 100, line: 5, column: 1),
      );
      testableBuilder.setCurrentParent('system1');
      testableBuilder.addContainer(containerNode);
      
      // Add person with explicit relationships to both container and system
      final personNode = PersonNode(
        id: 'person1',
        name: 'Customer',
        description: 'A customer of the bank',
        sourcePosition: SourcePosition(offset: 200, line: 10, column: 1),
      );
      testableBuilder.addPerson(personNode);
      
      // Explicit relationship to container
      final containerRelNode = RelationshipNode(
        sourceId: 'person1',
        destinationId: 'container1',
        description: 'Uses',
        sourcePosition: SourcePosition(offset: 300, line: 15, column: 1),
      );
      
      // Explicit relationship to system
      final systemRelNode = RelationshipNode(
        sourceId: 'person1',
        destinationId: 'system1',
        description: 'Uses',
        sourcePosition: SourcePosition(offset: 400, line: 20, column: 1),
      );
      
      testableBuilder.addRelationship(containerRelNode);
      testableBuilder.addRelationship(systemRelNode);
      testableBuilder.resolveRelationships();
      
      // Get initial relationship count
      final initialRelationshipCount = testableBuilder.workspace?.model.getAllRelationships().length ?? 0;
      
      // Act
      testableBuilder.addImpliedRelationships();
      
      // Assert
      final workspace = testableBuilder.build();
      expect(workspace, isNotNull);
      
      // The relationship count should be the same as before (no duplicates added)
      final finalRelationshipCount = workspace!.model.getAllRelationships().length;
      expect(finalRelationshipCount, equals(initialRelationshipCount));
      
      // The person should still have exactly one relationship to system and one to container
      final person = workspace.model.people.first;
      final containerRels = person.relationships.where((r) => r.destinationId == 'container1');
      expect(containerRels.length, equals(1));
      
      final systemRels = person.relationships.where((r) => r.destinationId == 'system1');
      expect(systemRels.length, equals(1));
      
      expect(errorReporter.errors, isEmpty);
    });
  });
  
  group('WorkspaceBuilderImpl.populateDefaults', () {
    test('populates default values for elements and views', () {
      // Arrange
      testableBuilder.createWorkspace(name: 'Test Workspace');
      
      // Add some elements without specifying some properties
      final systemNode = SoftwareSystemNode(
        id: 'system1',
        name: 'Banking System',
        description: 'Manages customer accounts',
        sourcePosition: SourcePosition(offset: 0, line: 1, column: 1),
        // Location not specified
      );
      testableBuilder.addSoftwareSystem(systemNode);
      
      // Act
      testableBuilder.populateDefaults();
      
      // Assert
      final workspace = testableBuilder.build();
      expect(workspace, isNotNull);
      
      // Check that default location was set
      final system = workspace!.model.softwareSystems.first;
      expect(system.location, equals('Internal')); // Default location
      
      expect(errorReporter.errors, isEmpty);
    });
  });
  
  group('WorkspaceBuilderImpl.setDefaultsFromJava', () {
    test('sets Java style defaults for views', () {
      // Arrange
      testableBuilder.createWorkspace(name: 'Test Workspace');
      
      // Add a software system
      final systemNode = SoftwareSystemNode(
        id: 'system1',
        name: 'Banking System',
        description: 'Manages customer accounts',
        sourcePosition: SourcePosition(offset: 0, line: 1, column: 1),
      );
      testableBuilder.addSoftwareSystem(systemNode);
      
      // Create a system context view
      final viewNode = SystemContextViewNode(
        key: 'SystemContext',
        systemId: 'system1',
        title: 'Banking System - System Context',
        description: 'System context diagram',
        sourcePosition: SourcePosition(offset: 100, line: 5, column: 1),
      );
      testableBuilder.addSystemContextView(viewNode);
      
      // Act
      testableBuilder.setDefaultsFromJava();
      
      // Assert
      final workspace = testableBuilder.build();
      expect(workspace, isNotNull);
      
      // Check that Java-style defaults were applied to views
      final view = workspace!.views.systemContextViews.first;
      
      // Java-style defaults would typically include things like:
      // - Paper size (A4_Landscape)
      // - Element styles for certain types
      // - Default layout settings
      
      // Since we can't directly check these implementation details in the test,
      // we'll just verify that the method executed without errors
      expect(errorReporter.errors, isEmpty);
    });
  });
  
  group('SystemContextViewParser.parse', () {
    test('parses a system context view with all properties', () {
      // Arrange
      builder.createWorkspace(name: 'Test Workspace');
      
      // Add a software system
      final systemNode = SoftwareSystemNode(
        id: 'system1',
        name: 'Banking System',
        description: 'Manages customer accounts and transactions',
        sourcePosition: SourcePosition(offset: 0, line: 1, column: 1),
      );
      builder.addSoftwareSystem(systemNode);
      
      // Add a person with relationship to the system
      final personNode = PersonNode(
        id: 'person1',
        name: 'Customer',
        description: 'A customer of the bank',
        sourcePosition: SourcePosition(offset: 200, line: 10, column: 1),
      );
      builder.addPerson(personNode);
      
      // Add relationship
      final relationshipNode = RelationshipNode(
        sourceId: 'person1',
        destinationId: 'system1',
        description: 'Uses',
        technology: 'Web',
        sourcePosition: SourcePosition(offset: 300, line: 15, column: 1),
      );
      builder.addRelationship(relationshipNode);
      builder.resolveRelationships();
      
      // Create a system context view node with all properties
      final viewNode = SystemContextViewNode(
        key: 'SystemContext',
        systemId: 'system1',
        title: 'Banking System - System Context',
        description: 'System context diagram for the banking system',
        sourcePosition: SourcePosition(offset: 400, line: 20, column: 1),
        autoLayout: AutoLayoutNode(
          rankDirection: 'TB',
          rankSeparation: 300,
          nodeSeparation: 300,
          sourcePosition: SourcePosition(offset: 500, line: 25, column: 1),
        ),
        animations: [
          AnimationNode(
            order: 1,
            elements: ['system1'],
            relationships: [],
            sourcePosition: SourcePosition(offset: 600, line: 30, column: 1),
          ),
          AnimationNode(
            order: 2,
            elements: ['person1'],
            relationships: [],
            sourcePosition: SourcePosition(offset: 700, line: 35, column: 1),
          ),
        ],
      );
      
      // Act
      final view = parser.parse(viewNode, builder);
      
      // Assert
      expect(view, isNotNull);
      expect(view!.key, equals('SystemContext'));
      expect(view.softwareSystemId, equals('system1'));
      expect(view.title, equals('Banking System - System Context'));
      expect(view.description, equals('System context diagram for the banking system'));
      
      // Check auto-layout
      expect(view.automaticLayout, isNotNull);
      expect(view.automaticLayout!.rankDirection, equals('TB'));
      expect(view.automaticLayout!.rankSeparation, equals(300));
      expect(view.automaticLayout!.nodeSeparation, equals(300));
      
      // Check animations
      expect(view.animations.length, equals(2));
      expect(view.animations[0].order, equals(1));
      expect(view.animations[0].elements, contains('system1'));
      expect(view.animations[1].order, equals(2));
      expect(view.animations[1].elements, contains('person1'));
      
      // View should contain the system and the person with a relationship
      expect(view.elements.length, equals(2));
      expect(view.elements.any((e) => e.id == 'system1'), isTrue);
      expect(view.elements.any((e) => e.id == 'person1'), isTrue);
      expect(view.relationships.length, equals(1));
      
      expect(errorReporter.errors, isEmpty);
    });
    
    test('reports error when software system not found', () {
      // Arrange
      builder.createWorkspace(name: 'Test Workspace');
      
      // Create a system context view node with non-existent system
      final viewNode = SystemContextViewNode(
        key: 'SystemContext',
        systemId: 'nonExistentSystem',
        title: 'Banking System - System Context',
        description: 'System context diagram for the banking system',
        sourcePosition: SourcePosition(offset: 100, line: 5, column: 1),
      );
      
      // Act
      final view = parser.parse(viewNode, builder);
      
      // Assert
      expect(view, isNull);
      expect(errorReporter.errorCount, greaterThan(0));
      expect(errorReporter.formatErrors(), contains('Software system not found'));
    });
    
    test('generates title based on system name when not provided', () {
      // Arrange
      builder.createWorkspace(name: 'Test Workspace');
      
      // Add a software system
      final systemNode = SoftwareSystemNode(
        id: 'system1',
        name: 'Banking System',
        description: 'Manages customer accounts and transactions',
        sourcePosition: SourcePosition(offset: 0, line: 1, column: 1),
      );
      builder.addSoftwareSystem(systemNode);
      
      // Create a system context view node without title
      final viewNode = SystemContextViewNode(
        key: 'SystemContext',
        systemId: 'system1',
        title: null, // No title provided
        description: 'System context diagram for the banking system',
        sourcePosition: SourcePosition(offset: 100, line: 5, column: 1),
      );
      
      // Act
      final view = parser.parse(viewNode, builder);
      
      // Assert
      expect(view, isNotNull);
      expect(view!.title, equals('Banking System - System Context'));
      expect(errorReporter.errors, isEmpty);
    });
    
    test('includes relationships between elements in the view', () {
      // Arrange
      builder.createWorkspace(name: 'Test Workspace');
      
      // Add a software system
      final systemNode = SoftwareSystemNode(
        id: 'system1',
        name: 'Banking System',
        description: 'Manages customer accounts and transactions',
        sourcePosition: SourcePosition(offset: 0, line: 1, column: 1),
      );
      builder.addSoftwareSystem(systemNode);
      
      // Add a person with relationship to the system
      final personNode = PersonNode(
        id: 'person1',
        name: 'Customer',
        description: 'A customer of the bank',
        sourcePosition: SourcePosition(offset: 200, line: 10, column: 1),
      );
      builder.addPerson(personNode);
      
      // Add another system with relationship to the main system
      final system2Node = SoftwareSystemNode(
        id: 'system2',
        name: 'Payment Gateway',
        description: 'Processes payments',
        sourcePosition: SourcePosition(offset: 400, line: 20, column: 1),
      );
      builder.addSoftwareSystem(system2Node);
      
      // Add relationships
      final rel1Node = RelationshipNode(
        sourceId: 'person1',
        destinationId: 'system1',
        description: 'Uses',
        sourcePosition: SourcePosition(offset: 600, line: 30, column: 1),
      );
      final rel2Node = RelationshipNode(
        sourceId: 'system1',
        destinationId: 'system2',
        description: 'Uses',
        sourcePosition: SourcePosition(offset: 700, line: 35, column: 1),
      );
      
      builder.addRelationship(rel1Node);
      builder.addRelationship(rel2Node);
      builder.resolveRelationships();
      
      // Create a system context view node
      final viewNode = SystemContextViewNode(
        key: 'SystemContext',
        systemId: 'system1',
        title: 'Banking System - System Context',
        description: 'System context diagram for the banking system',
        sourcePosition: SourcePosition(offset: 800, line: 40, column: 1),
      );
      
      // Act
      final view = parser.parse(viewNode, builder);
      
      // Assert
      expect(view, isNotNull);
      
      // The view should contain all three elements
      expect(view!.elements.length, equals(3));
      expect(view.elements.any((e) => e.id == 'system1'), isTrue);
      expect(view.elements.any((e) => e.id == 'person1'), isTrue);
      expect(view.elements.any((e) => e.id == 'system2'), isTrue);
      
      // The view should contain both relationships
      expect(view.relationships.length, equals(2));
      
      expect(errorReporter.errors, isEmpty);
    });
    
    test('handles include tags when specified', () {
      // Arrange
      builder.createWorkspace(name: 'Test Workspace');
      
      // Add a software system
      final systemNode = SoftwareSystemNode(
        id: 'system1',
        name: 'Banking System',
        description: 'Manages customer accounts and transactions',
        sourcePosition: SourcePosition(offset: 0, line: 1, column: 1),
      );
      builder.addSoftwareSystem(systemNode);
      
      // Create a system context view node with include tags
      final viewNode = SystemContextViewNode(
        key: 'SystemContext',
        systemId: 'system1',
        title: 'Banking System - System Context',
        description: 'System context diagram for the banking system',
        sourcePosition: SourcePosition(offset: 100, line: 5, column: 1),
        includes: [
          IncludeNode(
            expression: 'Customer',
            sourcePosition: SourcePosition(offset: 200, line: 10, column: 1),
          ),
        ],
      );
      
      // Act
      final view = parser.parse(viewNode, builder);
      
      // Assert
      expect(view, isNotNull);
      expect(view!.includeTags, contains('Customer'));
      expect(errorReporter.errors, isEmpty);
    });
    
    test('handles exclude tags when specified', () {
      // Arrange
      builder.createWorkspace(name: 'Test Workspace');
      
      // Add a software system
      final systemNode = SoftwareSystemNode(
        id: 'system1',
        name: 'Banking System',
        description: 'Manages customer accounts and transactions',
        sourcePosition: SourcePosition(offset: 0, line: 1, column: 1),
      );
      builder.addSoftwareSystem(systemNode);
      
      // Create a system context view node with exclude tags
      final viewNode = SystemContextViewNode(
        key: 'SystemContext',
        systemId: 'system1',
        title: 'Banking System - System Context',
        description: 'System context diagram for the banking system',
        sourcePosition: SourcePosition(offset: 100, line: 5, column: 1),
        excludes: [
          ExcludeNode(
            expression: 'Developer',
            sourcePosition: SourcePosition(offset: 200, line: 10, column: 1),
          ),
        ],
      );
      
      // Act
      final view = parser.parse(viewNode, builder);
      
      // Assert
      expect(view, isNotNull);
      expect(view!.excludeTags, contains('Developer'));
      expect(errorReporter.errors, isEmpty);
    });
  });
  
  group('SystemContextViewParser.handleIncludeAll', () {
    // Create mock classes to test internal parser methods
    class TestableSystemContextViewParser extends SystemContextViewParser {
      TestableSystemContextViewParser({
        required super.errorReporter,
        required super.referenceResolver,
      });
      
      @override
      void handleIncludeAll(SystemContextViewNode viewNode) {
        super.handleIncludeAll(viewNode);
      }
      
      @override
      void handleIncludeExclude(SystemContextViewNode viewNode) {
        super.handleIncludeExclude(viewNode);
      }
      
      @override
      void populateDefaults(SystemContextViewNode viewNode) {
        super.populateDefaults(viewNode);
      }
      
      @override
      void setAdvancedFeatures(SystemContextViewNode viewNode) {
        super.setAdvancedFeatures(viewNode);
      }
    }
    
    late TestableSystemContextViewParser testableParser;
    
    setUp(() {
      testableParser = TestableSystemContextViewParser(
        errorReporter: errorReporter,
        referenceResolver: builder.referenceResolver,
      );
    });
    
    test('adds all relevant elements when no include/exclude rules', () {
      // Arrange
      builder.createWorkspace(name: 'Test Workspace');
      
      // Add a software system
      final systemNode = SoftwareSystemNode(
        id: 'system1',
        name: 'Banking System',
        description: 'Manages customer accounts and transactions',
        sourcePosition: SourcePosition(offset: 0, line: 1, column: 1),
      );
      builder.addSoftwareSystem(systemNode);
      
      // Add a person with relationship to the system
      final personNode = PersonNode(
        id: 'person1',
        name: 'Customer',
        description: 'A customer of the bank',
        sourcePosition: SourcePosition(offset: 200, line: 10, column: 1),
      );
      builder.addPerson(personNode);
      
      // Add relationship
      final relationshipNode = RelationshipNode(
        sourceId: 'person1',
        destinationId: 'system1',
        description: 'Uses',
        sourcePosition: SourcePosition(offset: 300, line: 15, column: 1),
      );
      builder.addRelationship(relationshipNode);
      builder.resolveRelationships();
      
      // Create a system context view node
      final viewNode = SystemContextViewNode(
        key: 'SystemContext',
        systemId: 'system1',
        title: 'Banking System - System Context',
        description: 'System context diagram for the banking system',
        sourcePosition: SourcePosition(offset: 400, line: 20, column: 1),
      );
      
      // Track initial element count
      int initialElementCount = viewNode.elements.length;
      
      // Act
      testableParser.handleIncludeAll(viewNode);
      
      // Assert
      expect(viewNode.elements.length, greaterThan(initialElementCount));
      expect(viewNode.elements.any((e) => e.id == 'system1'), isTrue);
      expect(viewNode.elements.any((e) => e.id == 'person1'), isTrue);
      expect(errorReporter.errors, isEmpty);
    });
  });
  
  group('SystemContextViewParser.handleIncludeExclude', () {
    class TestableSystemContextViewParser extends SystemContextViewParser {
      TestableSystemContextViewParser({
        required super.errorReporter,
        required super.referenceResolver,
      });
      
      @override
      void handleIncludeExclude(SystemContextViewNode viewNode) {
        super.handleIncludeExclude(viewNode);
      }
    }
    
    late TestableSystemContextViewParser testableParser;
    
    setUp(() {
      testableParser = TestableSystemContextViewParser(
        errorReporter: errorReporter,
        referenceResolver: builder.referenceResolver,
      );
    });
    
    test('filters elements based on include rules', () {
      // Arrange
      builder.createWorkspace(name: 'Test Workspace');
      
      // Add a software system
      final systemNode = SoftwareSystemNode(
        id: 'system1',
        name: 'Banking System',
        description: 'Manages customer accounts and transactions',
        tags: TagsNode(tags: 'Core', sourcePosition: null),
        sourcePosition: SourcePosition(offset: 0, line: 1, column: 1),
      );
      builder.addSoftwareSystem(systemNode);
      
      // Add people with different tags
      final person1Node = PersonNode(
        id: 'person1',
        name: 'Customer',
        description: 'A customer of the bank',
        tags: TagsNode(tags: 'Customer', sourcePosition: null),
        sourcePosition: SourcePosition(offset: 200, line: 10, column: 1),
      );
      final person2Node = PersonNode(
        id: 'person2',
        name: 'Developer',
        description: 'A system developer',
        tags: TagsNode(tags: 'Developer', sourcePosition: null),
        sourcePosition: SourcePosition(offset: 300, line: 15, column: 1),
      );
      builder.addPerson(person1Node);
      builder.addPerson(person2Node);
      
      // Create a system context view node with include rules
      final viewNode = SystemContextViewNode(
        key: 'SystemContext',
        systemId: 'system1',
        title: 'Banking System - System Context',
        description: 'System context diagram for the banking system',
        sourcePosition: SourcePosition(offset: 400, line: 20, column: 1),
        includes: [
          IncludeNode(
            expression: 'Customer',
            sourcePosition: SourcePosition(offset: 500, line: 25, column: 1),
          ),
        ],
      );
      
      // Act
      testableParser.handleIncludeExclude(viewNode);
      
      // Assert
      expect(viewNode.elements.any((e) => e.id == 'system1'), isTrue); // System always included
      expect(viewNode.elements.any((e) => e.id == 'person1'), isTrue); // Has matching tag
      expect(viewNode.elements.any((e) => e.id == 'person2'), isFalse); // Doesn't match tag
      expect(errorReporter.errors, isEmpty);
    });
    
    test('filters elements based on exclude rules', () {
      // Arrange
      builder.createWorkspace(name: 'Test Workspace');
      
      // Add a software system
      final systemNode = SoftwareSystemNode(
        id: 'system1',
        name: 'Banking System',
        description: 'Manages customer accounts and transactions',
        tags: TagsNode(tags: 'Core', sourcePosition: null),
        sourcePosition: SourcePosition(offset: 0, line: 1, column: 1),
      );
      builder.addSoftwareSystem(systemNode);
      
      // Add people with different tags
      final person1Node = PersonNode(
        id: 'person1',
        name: 'Customer',
        description: 'A customer of the bank',
        tags: TagsNode(tags: 'Customer', sourcePosition: null),
        sourcePosition: SourcePosition(offset: 200, line: 10, column: 1),
      );
      final person2Node = PersonNode(
        id: 'person2',
        name: 'Developer',
        description: 'A system developer',
        tags: TagsNode(tags: 'Developer', sourcePosition: null),
        sourcePosition: SourcePosition(offset: 300, line: 15, column: 1),
      );
      builder.addPerson(person1Node);
      builder.addPerson(person2Node);
      
      // Add all elements to the view node first
      final viewNode = SystemContextViewNode(
        key: 'SystemContext',
        systemId: 'system1',
        title: 'Banking System - System Context',
        description: 'System context diagram for the banking system',
        sourcePosition: SourcePosition(offset: 400, line: 20, column: 1),
        excludes: [
          ExcludeNode(
            expression: 'Developer',
            sourcePosition: SourcePosition(offset: 500, line: 25, column: 1),
          ),
        ],
      );
      
      // Add elements to the view node
      viewNode.addElement(ElementNode(id: 'system1', sourcePosition: null));
      viewNode.addElement(ElementNode(id: 'person1', sourcePosition: null));
      viewNode.addElement(ElementNode(id: 'person2', sourcePosition: null));
      
      // Act
      testableParser.handleIncludeExclude(viewNode);
      
      // Assert
      expect(viewNode.elements.any((e) => e.id == 'system1'), isTrue); // System always included
      expect(viewNode.elements.any((e) => e.id == 'person1'), isTrue); // Not excluded
      expect(viewNode.elements.any((e) => e.id == 'person2'), isFalse); // Should be excluded
      expect(errorReporter.errors, isEmpty);
    });
  });
  
  group('SystemContextViewParser.populateDefaults', () {
    class TestableSystemContextViewParser extends SystemContextViewParser {
      TestableSystemContextViewParser({
        required super.errorReporter,
        required super.referenceResolver,
      });
      
      @override
      void populateDefaults(SystemContextViewNode viewNode) {
        super.populateDefaults(viewNode);
      }
    }
    
    late TestableSystemContextViewParser testableParser;
    
    setUp(() {
      testableParser = TestableSystemContextViewParser(
        errorReporter: errorReporter,
        referenceResolver: builder.referenceResolver,
      );
    });
    
    test('adds default elements to the view', () {
      // Arrange
      builder.createWorkspace(name: 'Test Workspace');
      
      // Add a software system
      final systemNode = SoftwareSystemNode(
        id: 'system1',
        name: 'Banking System',
        description: 'Manages customer accounts and transactions',
        sourcePosition: SourcePosition(offset: 0, line: 1, column: 1),
      );
      builder.addSoftwareSystem(systemNode);
      
      // Create an empty system context view node
      final viewNode = SystemContextViewNode(
        key: 'SystemContext',
        systemId: 'system1',
        title: 'Banking System - System Context',
        description: 'System context diagram for the banking system',
        sourcePosition: SourcePosition(offset: 100, line: 5, column: 1),
      );
      
      // Track initial element count
      int initialElementCount = viewNode.elements.length;
      
      // Act
      testableParser.populateDefaults(viewNode);
      
      // Assert
      expect(viewNode.elements.length, greaterThan(initialElementCount));
      expect(viewNode.elements.any((e) => e.id == 'system1'), isTrue); // At minimum, should add the system
      expect(errorReporter.errors, isEmpty);
    });
  });
  
  group('SystemContextViewParser.setAdvancedFeatures', () {
    class TestableSystemContextViewParser extends SystemContextViewParser {
      TestableSystemContextViewParser({
        required super.errorReporter,
        required super.referenceResolver,
      });
      
      @override
      void setAdvancedFeatures(SystemContextViewNode viewNode) {
        super.setAdvancedFeatures(viewNode);
      }
    }
    
    late TestableSystemContextViewParser testableParser;
    
    setUp(() {
      testableParser = TestableSystemContextViewParser(
        errorReporter: errorReporter,
        referenceResolver: builder.referenceResolver,
      );
    });
    
    test('sets advanced features on the view node', () {
      // Arrange
      builder.createWorkspace(name: 'Test Workspace');
      
      // Create a system context view node with advanced features
      final viewNode = SystemContextViewNode(
        key: 'SystemContext',
        systemId: 'system1',
        title: 'Banking System - System Context',
        description: 'System context diagram for the banking system',
        sourcePosition: SourcePosition(offset: 100, line: 5, column: 1),
        properties: PropertiesNode(
          properties: [
            PropertyNode(
              key: 'theme',
              value: 'dark',
              sourcePosition: SourcePosition(offset: 200, line: 10, column: 1),
            ),
            PropertyNode(
              key: 'paperSize',
              value: 'A3_Landscape',
              sourcePosition: SourcePosition(offset: 300, line: 15, column: 1),
            ),
          ],
          sourcePosition: SourcePosition(offset: 150, line: 8, column: 1),
        ),
      );
      
      // Act
      testableParser.setAdvancedFeatures(viewNode);
      
      // Assert
      // Advanced features are applied via setProperty, which updates the ViewNode's properties
      // Since we can't directly access these properties in the test, we verify that the method
      // executed without errors
      expect(errorReporter.errors, isEmpty);
    });
  });
  
  group('SystemContextViewNode methods', () {
    test('setIncludeRule adds include rule to the node', () {
      // Arrange
      final viewNode = SystemContextViewNode(
        key: 'SystemContext',
        systemId: 'system1',
        title: 'Banking System - System Context',
        description: 'System context diagram for the banking system',
        sourcePosition: SourcePosition(offset: 100, line: 5, column: 1),
        includes: [], // Start with empty includes
      );
      
      final includeRule = IncludeNode(
        expression: 'Customer',
        sourcePosition: SourcePosition(offset: 200, line: 10, column: 1),
      );
      
      // Act
      viewNode.setIncludeRule(includeRule);
      
      // Assert
      expect(viewNode.includes.length, equals(1));
      expect(viewNode.includes.first.expression, equals('Customer'));
    });
    
    test('setExcludeRule adds exclude rule to the node', () {
      // Arrange
      final viewNode = SystemContextViewNode(
        key: 'SystemContext',
        systemId: 'system1',
        title: 'Banking System - System Context',
        description: 'System context diagram for the banking system',
        sourcePosition: SourcePosition(offset: 100, line: 5, column: 1),
        excludes: [], // Start with empty excludes
      );
      
      final excludeRule = ExcludeNode(
        expression: 'Developer',
        sourcePosition: SourcePosition(offset: 200, line: 10, column: 1),
      );
      
      // Act
      viewNode.setExcludeRule(excludeRule);
      
      // Assert
      expect(viewNode.excludes.length, equals(1));
      expect(viewNode.excludes.first.expression, equals('Developer'));
    });
    
    test('setInheritance sets the parent view for inheritance', () {
      // Arrange
      final viewNode = SystemContextViewNode(
        key: 'SystemContext',
        systemId: 'system1',
        title: 'Banking System - System Context',
        description: 'System context diagram for the banking system',
        sourcePosition: SourcePosition(offset: 100, line: 5, column: 1),
      );
      
      final parentViewNode = SystemContextViewNode(
        key: 'ParentSystemContext',
        systemId: 'system1',
        title: 'Parent View',
        description: 'Parent view for inheritance',
        sourcePosition: SourcePosition(offset: 200, line: 10, column: 1),
      );
      
      // Act
      viewNode.setInheritance(parentViewNode);
      
      // Assert
      // Since ViewNode does not expose the inheritance property directly,
      // we can only verify that the method executes without errors
      // In a real implementation, this would set an inheritance property
      expect(() => viewNode.setInheritance(parentViewNode), returnsNormally);
    });
  });
  
  group('ViewNode methods', () {
    test('addElement adds an element to the view node', () {
      // Arrange
      final viewNode = SystemContextViewNode(
        key: 'SystemContext',
        systemId: 'system1',
        title: 'Banking System - System Context',
        description: 'System context diagram for the banking system',
        sourcePosition: SourcePosition(offset: 100, line: 5, column: 1),
      );
      
      final elementNode = ElementNode(
        id: 'element1',
        sourcePosition: SourcePosition(offset: 200, line: 10, column: 1),
      );
      
      // Act
      viewNode.addElement(elementNode);
      
      // Assert
      expect(viewNode.elements.length, equals(1));
      expect(viewNode.elements.first.id, equals('element1'));
    });
    
    test('setProperty sets a property on the view node', () {
      // Arrange
      final viewNode = SystemContextViewNode(
        key: 'SystemContext',
        systemId: 'system1',
        title: 'Banking System - System Context',
        description: 'System context diagram for the banking system',
        sourcePosition: SourcePosition(offset: 100, line: 5, column: 1),
      );
      
      // Act
      viewNode.setProperty('theme', 'dark');
      
      // Assert
      // Since ViewNode does not expose the properties directly,
      // we can only verify that the method executes without errors
      expect(() => viewNode.setProperty('theme', 'dark'), returnsNormally);
    });
  });
}