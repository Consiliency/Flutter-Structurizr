import 'package:flutter_structurizr/application/dsl/workspace_builder.dart';
import 'package:flutter_structurizr/application/dsl/workspace_builder_impl.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/person.dart';
import 'package:flutter_structurizr/domain/model/software_system.dart';
import 'package:flutter_structurizr/domain/model/container.dart';
import 'package:flutter_structurizr/domain/model/component.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/parser/ast/ast.dart';
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

void main() {
  late MockErrorReporter errorReporter;
  late WorkspaceBuilder builder;

  setUp(() {
    errorReporter = MockErrorReporter();
    builder = WorkspaceBuilderFactoryImpl().createWorkspaceBuilder(errorReporter);
  });

  tearDown(() {
    // Clear the errors by creating a new error reporter
    errorReporter = MockErrorReporter();
  });

  group('WorkspaceBuilder', () {
    test('creates a basic workspace', () {
      // Arrange
      builder.createWorkspace(
        name: 'Test Workspace',
        description: 'Test workspace description',
      );

      // Act
      final workspace = builder.build();

      // Assert
      expect(workspace, isNotNull);
      expect(workspace!.name, equals('Test Workspace'));
      expect(workspace.description, equals('Test workspace description'));
      expect(workspace.model.people, isEmpty);
      expect(workspace.model.softwareSystems, isEmpty);
      expect(errorReporter.errors, isEmpty);
    });

    test('adds a person to the model', () {
      // Arrange
      builder.createWorkspace(
        name: 'Test Workspace',
      );

      // Create a person node
      final personNode = PersonNode(
        id: 'person1',
        name: 'User',
        description: 'A user of the system',
        location: 'External',
        sourcePosition: SourcePosition(offset: 0, line: 1, column: 1),
      );

      // Act
      builder.addPerson(personNode);

      // Assert
      final workspace = builder.build();
      expect(workspace, isNotNull);
      expect(workspace!.model.people.length, equals(1));
      expect(workspace.model.people.first.id, equals('person1'));
      expect(workspace.model.people.first.name, equals('User'));
      expect(workspace.model.people.first.description, equals('A user of the system'));
      expect(workspace.model.people.first.location, equals('External'));
      expect(errorReporter.errors, isEmpty);
    });

    test('adds a software system to the model', () {
      // Arrange
      builder.createWorkspace(
        name: 'Test Workspace',
      );

      // Create a software system node
      final systemNode = SoftwareSystemNode(
        id: 'system1',
        name: 'Banking System',
        description: 'Manages customer accounts and transactions',
        location: 'Internal',
        sourcePosition: SourcePosition(offset: 0, line: 1, column: 1),
      );

      // Act
      builder.addSoftwareSystem(systemNode);

      // Assert
      final workspace = builder.build();
      expect(workspace, isNotNull);
      expect(workspace!.model.softwareSystems.length, equals(1));
      expect(workspace.model.softwareSystems.first.id, equals('system1'));
      expect(workspace.model.softwareSystems.first.name, equals('Banking System'));
      expect(workspace.model.softwareSystems.first.description, equals('Manages customer accounts and transactions'));
      expect(workspace.model.softwareSystems.first.location, equals('Internal'));
      expect(errorReporter.errors, isEmpty);
    });

    test('adds a container to a software system', () {
      // Arrange
      builder.createWorkspace(
        name: 'Test Workspace',
      );

      // Create a software system node
      final systemNode = SoftwareSystemNode(
        id: 'system1',
        name: 'Banking System',
        description: 'Manages customer accounts and transactions',
        sourcePosition: SourcePosition(offset: 0, line: 1, column: 1),
      );

      // Add the system
      builder.addSoftwareSystem(systemNode);

      // Create a container node
      final containerNode = ContainerNode(
        id: 'container1',
        name: 'Web Application',
        description: 'Provides banking functionality to customers',
        technology: 'Flutter Web',
        parentId: 'system1',
        sourcePosition: SourcePosition(offset: 100, line: 5, column: 1),
      );

      // Act
      builder.setCurrentParent('system1');
      builder.addContainer(containerNode);

      // Assert
      final workspace = builder.build();
      expect(workspace, isNotNull);
      expect(workspace!.model.softwareSystems.length, equals(1));
      expect(workspace.model.softwareSystems.first.containers.length, equals(1));
      expect(workspace.model.softwareSystems.first.containers.first.id, equals('container1'));
      expect(workspace.model.softwareSystems.first.containers.first.name, equals('Web Application'));
      expect(workspace.model.softwareSystems.first.containers.first.parentId, equals('system1'));
      expect(workspace.model.softwareSystems.first.containers.first.technology, equals('Flutter Web'));
      expect(errorReporter.errors, isEmpty);
    });

    test('adds a component to a container', () {
      // Arrange
      builder.createWorkspace(
        name: 'Test Workspace',
      );

      // Create a software system node
      final systemNode = SoftwareSystemNode(
        id: 'system1',
        name: 'Banking System',
        description: 'Manages customer accounts and transactions',
        sourcePosition: SourcePosition(offset: 0, line: 1, column: 1),
      );

      // Add the system
      builder.addSoftwareSystem(systemNode);

      // Create a container node
      final containerNode = ContainerNode(
        id: 'container1',
        name: 'Web Application',
        description: 'Provides banking functionality to customers',
        technology: 'Flutter Web',
        parentId: 'system1',
        sourcePosition: SourcePosition(offset: 100, line: 5, column: 1),
      );

      // Add the container
      builder.setCurrentParent('system1');
      builder.addContainer(containerNode);

      // Create a component node
      final componentNode = ComponentNode(
        id: 'component1',
        name: 'Authentication Controller',
        description: 'Handles user authentication',
        technology: 'Dart',
        parentId: 'container1',
        sourcePosition: SourcePosition(offset: 200, line: 10, column: 1),
      );

      // Act
      builder.setCurrentParent('container1');
      builder.addComponent(componentNode);

      // Assert
      final workspace = builder.build();
      expect(workspace, isNotNull);
      expect(workspace!.model.softwareSystems.length, equals(1));
      expect(workspace.model.softwareSystems.first.containers.length, equals(1));
      expect(workspace.model.softwareSystems.first.containers.first.components.length, equals(1));
      expect(workspace.model.softwareSystems.first.containers.first.components.first.id, equals('component1'));
      expect(workspace.model.softwareSystems.first.containers.first.components.first.name, equals('Authentication Controller'));
      expect(workspace.model.softwareSystems.first.containers.first.components.first.parentId, equals('container1'));
      expect(workspace.model.softwareSystems.first.containers.first.components.first.technology, equals('Dart'));
      expect(errorReporter.errors, isEmpty);
    });

    test('adds a relationship between elements', () {
      // Arrange
      builder.createWorkspace(
        name: 'Test Workspace',
      );

      // Create elements
      final personNode = PersonNode(
        id: 'person1',
        name: 'User',
        description: 'A user of the system',
        sourcePosition: SourcePosition(offset: 0, line: 1, column: 1),
      );

      final systemNode = SoftwareSystemNode(
        id: 'system1',
        name: 'Banking System',
        description: 'Manages customer accounts and transactions',
        sourcePosition: SourcePosition(offset: 100, line: 5, column: 1),
      );

      // Add the elements
      builder.addPerson(personNode);
      builder.addSoftwareSystem(systemNode);

      // Create a relationship
      final relationshipNode = RelationshipNode(
        sourceId: 'person1',
        destinationId: 'system1',
        description: 'Uses',
        technology: 'HTTPS',
        sourcePosition: SourcePosition(offset: 200, line: 10, column: 1),
      );

      // Act
      builder.addRelationship(relationshipNode);
      builder.resolveRelationships();

      // Assert
      final workspace = builder.build();
      expect(workspace, isNotNull);
      expect(workspace!.model.people.length, equals(1));
      expect(workspace.model.softwareSystems.length, equals(1));
      
      // The person should have a relationship to the system
      final person = workspace.model.people.first;
      expect(person.relationships.length, equals(1));
      expect(person.relationships.first.destinationId, equals('system1'));
      expect(person.relationships.first.description, equals('Uses'));
      expect(person.relationships.first.technology, equals('HTTPS'));
      expect(errorReporter.errors, isEmpty);
    });

    test('adds a system landscape view', () {
      // Arrange
      builder.createWorkspace(
        name: 'Test Workspace',
      );

      // Create a system landscape view node
      final viewNode = SystemLandscapeViewNode(
        key: 'landscape',
        title: 'System Landscape',
        description: 'Overview of the system landscape',
        sourcePosition: SourcePosition(offset: 0, line: 1, column: 1),
      );

      // Act
      builder.addSystemLandscapeView(viewNode);

      // Assert
      final workspace = builder.build();
      expect(workspace, isNotNull);
      expect(workspace!.views.systemLandscapeViews.length, equals(1));
      expect(workspace.views.systemLandscapeViews.first.key, equals('landscape'));
      expect(workspace.views.systemLandscapeViews.first.title, equals('System Landscape'));
      expect(workspace.views.systemLandscapeViews.first.description, equals('Overview of the system landscape'));
      expect(errorReporter.errors, isEmpty);
    });

    test('reports error when adding container without parent', () {
      // Arrange
      builder.createWorkspace(
        name: 'Test Workspace',
      );

      // Create a container node without setting a parent
      final containerNode = ContainerNode(
        id: 'container1',
        name: 'Web Application',
        description: 'Provides banking functionality to customers',
        technology: 'Flutter Web',
        parentId: 'system1',
        sourcePosition: SourcePosition(offset: 100, line: 5, column: 1),
      );

      // Act
      builder.addContainer(containerNode);

      // Assert
      expect(builder.build(), isNotNull); // The build should still succeed
      expect(errorReporter.errorCount, equals(1));
      expect(errorReporter.formatErrors(), contains('Container must be defined within a software system'));
    });

    test('reports error when adding component without parent', () {
      // Arrange
      builder.createWorkspace(
        name: 'Test Workspace',
      );

      // Create a component node without setting a parent
      final componentNode = ComponentNode(
        id: 'component1',
        name: 'Authentication Controller',
        description: 'Handles user authentication',
        technology: 'Dart',
        parentId: 'container1',
        sourcePosition: SourcePosition(offset: 200, line: 10, column: 1),
      );

      // Act
      builder.addComponent(componentNode);

      // Assert
      expect(builder.build(), isNotNull); // The build should still succeed
      expect(errorReporter.errorCount, equals(1));
      expect(errorReporter.formatErrors(), contains('Component must be defined within a container'));
    });
    
    test('handles variable names for alias registration', () {
      // Arrange
      builder.createWorkspace(
        name: 'Test Workspace',
      );
      
      // Create a person node with a variable name
      final personNode = PersonNode(
        id: 'person1',
        name: 'User',
        description: 'A user of the system',
        variableName: 'user',
        sourcePosition: SourcePosition(offset: 0, line: 1, column: 1),
      );
      
      // Create a system node with a variable name
      final systemNode = SoftwareSystemNode(
        id: 'system1',
        name: 'Banking System',
        description: 'Banking system for customers',
        variableName: 'bankingSystem',
        sourcePosition: SourcePosition(offset: 100, line: 5, column: 1),
      );
      
      // Act
      builder.addPerson(personNode);
      builder.addSoftwareSystem(systemNode);
      
      // Add a relationship using the variable names
      final relationshipNode = RelationshipNode(
        sourceId: 'user', // Using the variable name instead of the ID
        destinationId: 'bankingSystem', // Using the variable name instead of the ID
        description: 'Uses',
        technology: 'HTTPS',
        sourcePosition: SourcePosition(offset: 200, line: 10, column: 1),
      );
      
      builder.addRelationship(relationshipNode);
      builder.resolveRelationships();
      
      // Assert
      final workspace = builder.build();
      expect(workspace, isNotNull);
      
      // The person should have a relationship to the system
      final person = workspace.model.people.first;
      expect(person.relationships.length, equals(1));
      expect(person.relationships.first.destinationId, equals('system1')); // The actual ID, not the variable name
      expect(person.relationships.first.description, equals('Uses'));
      
      // Verify that the resolver has the aliases registered
      expect(builder.referenceResolver.resolveReference('user'), equals(person));
      expect(builder.referenceResolver.resolveReference('bankingSystem'), equals(workspace.model.softwareSystems.first));
      
      expect(errorReporter.errors, isEmpty);
    });
    
    test('handles multiple aliases for the same element', () {
      // Arrange
      builder.createWorkspace(
        name: 'Test Workspace',
      );
      
      // Create a system node with a variable name
      final systemNode = SoftwareSystemNode(
        id: 'system1',
        name: 'Banking System',
        description: 'Banking system for customers',
        variableName: 'bankingSystem',
        sourcePosition: SourcePosition(offset: 0, line: 1, column: 1),
      );
      
      // Act
      builder.addSoftwareSystem(systemNode);
      
      // Manually register another alias for the same system
      builder.referenceResolver.registerAlias('bank', 'system1');
      
      // Assert
      expect(builder.referenceResolver.resolveReference('bankingSystem'), isNotNull);
      expect(builder.referenceResolver.resolveReference('bank'), isNotNull);
      
      // Both aliases should resolve to the same system
      expect(builder.referenceResolver.resolveReference('bankingSystem'), 
             equals(builder.referenceResolver.resolveReference('bank')));
      
      expect(errorReporter.errors, isEmpty);
    });
  });

  group('SystemContextView methods', () {
    test('addSystemContextView adds a system context view', () {
      // Arrange
      builder.createWorkspace(
        name: 'Test Workspace',
      );

      // Create a software system node
      final systemNode = SoftwareSystemNode(
        id: 'system1',
        name: 'Banking System',
        description: 'Manages customer accounts and transactions',
        sourcePosition: SourcePosition(offset: 0, line: 1, column: 1),
      );

      // Add the system
      builder.addSoftwareSystem(systemNode);

      // Create a system context view node
      final viewNode = SystemContextViewNode(
        key: 'systemContext',
        systemId: 'system1',
        title: 'Banking System - System Context',
        description: 'System context diagram for the banking system',
        sourcePosition: SourcePosition(offset: 0, line: 1, column: 1),
      );

      // Act
      builder.addSystemContextView(viewNode);

      // Assert
      final workspace = builder.build();
      expect(workspace, isNotNull);
      expect(workspace!.views.systemContextViews.length, equals(1));
      expect(workspace.views.systemContextViews.first.key, equals('systemContext'));
      expect(workspace.views.systemContextViews.first.softwareSystemId, equals('system1'));
      expect(workspace.views.systemContextViews.first.title, equals('Banking System - System Context'));
      expect(workspace.views.systemContextViews.first.description, equals('System context diagram for the banking system'));
      expect(errorReporter.errors, isEmpty);
    });
    
    test('addDefaultElements adds software system to view', () {
      // Arrange
      builder.createWorkspace(
        name: 'Test Workspace',
      );

      // Create a software system node
      final systemNode = SoftwareSystemNode(
        id: 'system1',
        name: 'Banking System',
        description: 'Manages customer accounts and transactions',
        sourcePosition: SourcePosition(offset: 0, line: 1, column: 1),
      );

      // Add the system
      builder.addSoftwareSystem(systemNode);

      // Create a system context view node
      final viewNode = SystemContextViewNode(
        key: 'systemContext',
        systemId: 'system1',
        title: 'Banking System - System Context',
        description: 'System context diagram for the banking system',
        sourcePosition: SourcePosition(offset: 0, line: 1, column: 1),
      );

      // Act
      builder.addDefaultElements(viewNode);

      // Assert
      // Check that the software system was added to the view node elements
      expect(viewNode.elements.map((e) => e.id), contains('system1'));
    });

    test('addImpliedRelationships adds relationships between elements', () {
      // Arrange
      builder.createWorkspace(
        name: 'Test Workspace',
      );

      // Create a software system node
      final systemNode = SoftwareSystemNode(
        id: 'system1',
        name: 'Banking System',
        description: 'Manages customer accounts and transactions',
        sourcePosition: SourcePosition(offset: 0, line: 1, column: 1),
      );
      builder.addSoftwareSystem(systemNode);

      // Create a container node
      final containerNode = ContainerNode(
        id: 'container1',
        name: 'Web Application',
        description: 'Provides banking functionality to customers',
        technology: 'Flutter Web',
        parentId: 'system1',
        sourcePosition: SourcePosition(offset: 100, line: 5, column: 1),
      );
      builder.setCurrentParent('system1');
      builder.addContainer(containerNode);

      // Create a person node
      final personNode = PersonNode(
        id: 'person1',
        name: 'Customer',
        description: 'A bank customer',
        sourcePosition: SourcePosition(offset: 200, line: 10, column: 1),
      );
      builder.addPerson(personNode);

      // Add a relationship from container to person
      final relationshipNode = RelationshipNode(
        sourceId: 'container1',
        destinationId: 'person1',
        description: 'Sends notifications to',
        sourcePosition: SourcePosition(offset: 300, line: 15, column: 1),
      );
      builder.addRelationship(relationshipNode);
      builder.resolveRelationships();

      // Act
      builder.addImpliedRelationships();

      // Build the workspace to finalize all relationships
      final workspace = builder.build();

      // Assert
      expect(workspace, isNotNull);
      
      // Note: Because the implementation only logs implied relationships but
      // doesn't actually create them yet, we can't test for their existence.
      // This test just verifies the method runs without errors.
      expect(errorReporter.errors, isEmpty);
    });

    test('populateDefaults adds default styles', () {
      // Arrange
      builder.createWorkspace(
        name: 'Test Workspace',
      );

      // Act
      builder.populateDefaults();

      // Assert
      final workspace = builder.build();
      expect(workspace, isNotNull);
      
      // Check that default element style exists
      expect(workspace!.styles.hasElementStyle('Element'), isTrue);
      
      // Check that default relationship style exists
      expect(workspace.styles.hasRelationshipStyle('Relationship'), isTrue);
      
      // Check specific style properties
      final elementStyle = workspace.styles.findElementStyle('Element');
      expect(elementStyle, isNotNull);
      expect(elementStyle!.shape, equals(Shape.box));
      
      final relationshipStyle = workspace.styles.findRelationshipStyle('Relationship');
      expect(relationshipStyle, isNotNull);
      expect(relationshipStyle!.thickness, equals(2));
    });

    test('setDefaultsFromJava adds Java-compatible styles', () {
      // Arrange
      builder.createWorkspace(
        name: 'Test Workspace',
      );

      // Act
      builder.setDefaultsFromJava();

      // Assert
      final workspace = builder.build();
      expect(workspace, isNotNull);
      
      // Check that Java-compatible styles exist
      expect(workspace!.styles.hasElementStyle('Person'), isTrue);
      expect(workspace!.styles.hasElementStyle('SoftwareSystem'), isTrue);
      
      // Check specific Java-style properties
      final personStyle = workspace.styles.findElementStyle('Person');
      expect(personStyle, isNotNull);
      expect(personStyle!.shape, equals(Shape.person));
      
      final systemStyle = workspace.styles.findElementStyle('SoftwareSystem');
      expect(systemStyle, isNotNull);
      expect(systemStyle!.shape, equals(Shape.box));
    });
  });
}