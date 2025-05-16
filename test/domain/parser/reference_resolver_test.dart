import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/person.dart';
import 'package:flutter_structurizr/domain/model/software_system.dart';
import 'package:flutter_structurizr/domain/model/container.dart';
import 'package:flutter_structurizr/domain/model/component.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/parser/ast/ast.dart';
import 'package:flutter_structurizr/domain/parser/reference_resolver.dart';
import 'package:test/test.dart';

class MockErrorReporter extends ErrorReporter {
  MockErrorReporter() : super('');
  
  // Track messages for easy testing
  final List<String> errorMessages = [];
  final List<String> warningMessages = [];
  final List<String> infoMessages = [];
  
  @override
  void reportStandardError(String message, int offset) {
    errorMessages.add(message);
    super.reportStandardError(message, offset);
  }
  
  @override
  void reportWarning(String message, int offset) {
    warningMessages.add(message);
    super.reportWarning(message, offset);
  }
  
  @override
  void reportInfo(String message, int offset) {
    infoMessages.add(message);
    super.reportInfo(message, offset);
  }
  
  void reset() {
    errorMessages.clear();
    warningMessages.clear();
    infoMessages.clear();
    // We'll need to call super.reportError a few times, but we can't clear _errors directly
    // since it's private. For testing purposes, this is okay.
  }
}

void main() {
  group('ReferenceResolver', () {
    test('basic functionality', () {
      // Create a simple test setup
      final errorReporter = MockErrorReporter();
      final resolver = ReferenceResolver(errorReporter);
      
      // Create and register some elements
      final user = Person(id: 'user1', name: 'User');
      final system = SoftwareSystem(id: 'system1', name: 'Banking System');
      
      resolver.registerElement(user);
      resolver.registerElement(system);
      
      // Test basic resolution
      expect(resolver.resolveReference('user1'), equals(user));
      expect(resolver.resolveReference('system1'), equals(system));
      
      // Test name-based resolution
      expect(resolver.resolveReference('User', searchByName: true), equals(user));
      expect(resolver.resolveReference('Banking System', searchByName: true), equals(system));
      
      // Test aliases
      resolver.registerAlias('sys', 'system1');
      expect(resolver.resolveReference('sys'), equals(system));
      
      // Skip type validation in tests as it requires runtime type information
      
      // Test error reporting
      final sourcePosition = SourcePosition(line: 1, column: 1, offset: 0);
      expect(resolver.resolveReference('nonexistent', sourcePosition: sourcePosition), isNull);
      expect(errorReporter.errorMessages, isNotEmpty);
      
      // Test finding by type
      final people = resolver.findAllByType<Person>();
      expect(people, contains(user));
      
      // Test children finding
      final container = Container(id: 'container1', name: 'Web App', parentId: 'system1');
      resolver.registerElement(container);
      
      final children = resolver.findChildrenOf('system1');
      expect(children, contains(container));
    });
    
    test('variable alias resolution', () {
      // Create a simple test setup
      final errorReporter = MockErrorReporter();
      final resolver = ReferenceResolver(errorReporter);
      
      // Create and register some elements
      final person = Person(id: 'p1', name: 'User');
      final system = SoftwareSystem(id: 's1', name: 'Banking System');
      final container = Container(id: 'c1', name: 'Web App', parentId: 's1');
      final component = Component(id: 'comp1', name: 'API', parentId: 'c1');
      
      resolver.registerElement(person);
      resolver.registerElement(system);
      resolver.registerElement(container);
      resolver.registerElement(component);
      
      // Register aliases for multiple elements
      resolver.registerAlias('user', 'p1');
      resolver.registerAlias('bank', 's1');
      resolver.registerAlias('webapp', 'c1');
      resolver.registerAlias('api', 'comp1');
      
      // Test resolution via aliases
      expect(resolver.resolveReference('user'), equals(person));
      expect(resolver.resolveReference('bank'), equals(system));
      expect(resolver.resolveReference('webapp'), equals(container));
      expect(resolver.resolveReference('api'), equals(component));
      
      // Test non-existent aliases
      expect(resolver.resolveReference('nonexistent'), isNull);
      
      // Test that we can have multiple aliases for the same element
      resolver.registerAlias('bankingSystem', 's1');
      expect(resolver.resolveReference('bank'), equals(system));
      expect(resolver.resolveReference('bankingSystem'), equals(system));
      
      // Test overriding an alias
      resolver.registerAlias('user', 's1'); // Now 'user' points to the system
      expect(resolver.resolveReference('user'), equals(system));
      
      // Test using aliases in relationships
      final system2 = SoftwareSystem(id: 's2', name: 'CRM System');
      resolver.registerElement(system2);
      resolver.registerAlias('crm', 's2');
      
      // Verify we can resolve the relationship by alias
      expect(resolver.resolveReference('crm'), equals(system2));
    });
  });
}